
from lxml import etree
from os import path, stat, rename, unlink, umask, chmod
from hashlib import sha256
from io import BytesIO
from gzip import GzipFile
from rpm2swidtag import Error, SWID_XMLNS, Tag
from tempfile import NamedTemporaryFile
from glob import iglob

REPO_XMLNS = "http://linux.duke.edu/metadata/repo"
COMMON_XMLNS = "http://linux.duke.edu/metadata/common"
SWIDTAGLIST_XMLNS = "http://rpm.org/metadata/swidtags.xsd"

class Repodata:
	def __init__(self, repo):
		self.path = repo
		if not path.isdir(repo):
			raise Error("%s is not directory" % repo) from None
		self.__repomd = None

	@property
	def repomd(self):
		if not self.__repomd:
			self.__repomd = Repomd(self)
		return self.__repomd

class Repomd:
	def __init__(self, repo):
		self.repo = repo
		self.href = "repodata/repomd.xml"
		self.path = path.join(self.repo.path, self.href)
		if not path.isfile(self.path):
			raise Error("file %s does not exist" % self.path) from None
		self.xml = etree.parse(self.path, etree.XMLParser(remove_blank_text = True))
		for href in self.xml.xpath("/repo:repomd/repo:data[@type = 'primary']/repo:location/@href", namespaces = { 'repo': REPO_XMLNS }):
			self.primary_path = href
			break
		if not self.primary_path:
			raise Error("%s does not have primary data" % self.path) from None
		self.__primary = None

	@property
	def primary(self):
		if not self.__primary:
			self.__primary = Primary(self.repo, self.primary_path)
		return self.__primary

	def save(self):
		outpath = NamedTemporaryFile(dir=path.dirname(self.path), prefix="." + path.basename(self.path), delete=False)
		self.xml.write(outpath.file, xml_declaration=True, encoding="utf-8", pretty_print=True)
		orig_umask = umask(0)
		umask(orig_umask)
		chmod(outpath.name, 0o666 & ~orig_umask)
		rename(outpath.name, self.path)

class Primary:
	def __init__(self, repo, primary):
		self.repo = repo
		self.href = primary
		self.path = path.join(self.repo.path, self.href)
		self.zst = False
		if path.splitext(self.path)[1] == '.zst':
			self.zst = True
			import zstandard
			with zstandard.open(self.path, 'rb') as fh:
				self.xml = etree.parse(fh)
				print(self.xml)
		else:
			self.xml = etree.parse(self.path)
		self.list = None
		self.index = -1

	def __iter__(self):
		return self

	def __next__(self):
		if self.index == -1:
			self.list = self.xml.xpath("/common:metadata/common:package[@type = 'rpm']", namespaces = { 'common': COMMON_XMLNS })
			self.index = 0
		self.index += 1
		if self.index > len(self.list):
			raise StopIteration
		return Package(self, self.list[self.index - 1])

class Package:
	def __init__(self, primary, element):
		self.primary = primary
		self.element = element
		self.location_fn = None
		self.href_fn = None
		self.pkgid_fn = None

	@property
	def href(self):
		if not self.location_fn:
			self.location_fn = etree.XPath("common:location", namespaces = { 'common': COMMON_XMLNS })
			self.href_fn = etree.XPath("common:location/@href", namespaces = { 'common': COMMON_XMLNS })
		location = self.location_fn(self.element)[0]
		href = location.get("href")
		base = location.base
		if base is None or base == self.primary.path:
			return href
		if base.startswith("file:///"):
			base = base[7:]
		elif base.startswith("file:/") and not base.startswith("file://"):
			base = base[5:]
		else:
			raise Error("xml:base %s does not look local for %s" % (base, href)) from None
		return base + "/" + href

	@property
	def pkgid(self):
		if not self.pkgid_fn:
			self.pkgid_fn = etree.XPath("common:checksum[@pkgid = 'YES']/text()", namespaces = { 'common': COMMON_XMLNS })
		return str(self.pkgid_fn(self.element)[0])

class Swidtags:
	def __init__(self, repo, file=None):
		self.repo = repo
		self.href = None
		self.file = file
		if self.file:
			self.iterparse = None
			self.root_element = None
			self.prev_element = None
		else:
			self.xml = etree.Element("{%s}swidtags" % SWIDTAGLIST_XMLNS, nsmap={ None: SWIDTAGLIST_XMLNS })
			self.xml.set("packages", "0")

	def add(self, package, swidtags):
		pxml = etree.Element("{%s}package" % SWIDTAGLIST_XMLNS)
		pxml.set("pkgid", package.pkgid)
		for s in swidtags:
			pxml.append(s.xml.getroot())
		self.xml.append(pxml)
		self.xml.set("packages", str(len(self.xml.getchildren())))

	def save(self, retain_old_md=None):
		data = BytesIO()
		etree.ElementTree(self.xml).write(data, xml_declaration=True, encoding="utf-8", pretty_print=True)
		data_gz = BytesIO()
		with GzipFile(fileobj=data_gz, mode="wb", mtime=0) as f:
			f.write(data.getvalue())
		value_gz = data_gz.getvalue()
		checksum = sha256(value_gz).hexdigest()
		self.href = "repodata/%s-swidtags.xml.gz" % checksum
		filename = path.join(self.repo.path, self.href)
		with open(filename, "wb") as f:
			f.write(value_gz)
		timestamp = str(int(stat(filename).st_mtime))

		repomd_xml = etree.Element("{%s}data" % REPO_XMLNS)
		repomd_xml.set("type", "swidtags")
		c = etree.SubElement(repomd_xml, "{%s}checksum" % REPO_XMLNS)
		c.set("type", "sha256")
		c.text = checksum
		value = data.getvalue()
		oc = etree.SubElement(repomd_xml, "{%s}open-checksum" % REPO_XMLNS)
		oc.set("type", "sha256")
		oc.text = sha256(value).hexdigest()
		etree.SubElement(repomd_xml, "{%s}location" % REPO_XMLNS).set("href", self.href)
		etree.SubElement(repomd_xml, "{%s}timestamp" % REPO_XMLNS).text = timestamp
		etree.SubElement(repomd_xml, "{%s}size" % REPO_XMLNS).text = str(len(value_gz))
		etree.SubElement(repomd_xml, "{%s}open-size" % REPO_XMLNS).text = str(len(value))

		repomd = self.repo.repomd
		for s in repomd.xml.xpath("/repo:repomd/repo:data[@type = 'swidtags']", namespaces = { 'repo': REPO_XMLNS }):
			s.getparent().remove(s)
		for t in repomd.xml.xpath("/repo:repomd", namespaces = { 'repo': REPO_XMLNS }):
			t.append(repomd_xml)
		for t in repomd.xml.xpath("/repo:repomd/repo:revision", namespaces = { 'repo': REPO_XMLNS }):
			t.text = timestamp
		repomd.save()

		swidtags = sorted(iglob(path.join(self.repo.path, "repodata/*-swidtags.xml.gz")), key=path.getmtime)
		remaining = len(swidtags)
		if not retain_old_md:
			retain_old_md = 0
		for f in swidtags:
			if f == filename:
				continue
			if remaining > retain_old_md + 1:
				unlink(f)
				remaining -= 1

	def __iter__(self):
		f = self.file
		if f.endswith(".gz"):
			f = GzipFile(f, "rb")
		self.iterparse = etree.iterparse(f, events=("end",), tag=("{%s}package" % SWIDTAGLIST_XMLNS),
			remove_blank_text=True)
		self.root_element = None
		return self

	def __next__(self):
		if self.prev_element is not None:
			self.prev_element.clear()
			self.prev_element = None

		for _, element in self.iterparse:
			if self.root_element is None:
				root = element.getparent()
				if root is not None \
					and root.getparent() is None \
					and root.tag == "{%s}swidtags" % SWIDTAGLIST_XMLNS:
					self.root_element = root
				else:
					element.clear()
					continue
			elif element.getparent() != self.root_element:
				element.clear()
				continue

			self.prev_element = element
			return self.prev_element

		raise StopIteration

	def tags_for_repo_packages(self, pkgs):
		pkgids = {}
		for p in pkgs:
			pkgids[p[0].chksum[1].hex()] = [p, p[1]]
		tags = {}
		for e in self:
			pkgid = e.get("pkgid")
			if pkgid not in pkgids:
				continue
			tp = pkgids[pkgid]
			tags[tp[0]] = []
			for p in e:
				tags[tp[0]].append(Tag(etree.ElementTree(p), tp[1]))
		return tags

	def tags_for_rpm_packages(self, pkgs):
		pkg256headers = {}
		for p in pkgs:
			if p["SHA256HEADER"]:
				if isinstance(p["name"], str):
					pkg256headers[( p["name"], p["SHA256HEADER"] )] = p
				else:
					pkg256headers[( p["name"].decode("utf-8"), p["SHA256HEADER"].decode("utf-8") )] = p
		tags = {}
		for e in self:
			found = None
			for rs in e.xpath("swid:SoftwareIdentity/swid:Payload/swid:Resource[@type = 'rpm'] | swid:SoftwareIdentity/swid:Evidence/swid:Resource[@type = 'rpm']", namespaces = { 'swid': SWID_XMLNS }):
				h = rs.get("sha256header")
				if h:
					found = (rs.getparent().getparent().get("name"), h)
					break
			if not found or found not in pkg256headers:
				continue
			tp = pkg256headers[found]
			tags[tp] = []
			for p in e:
				tags[tp].append(Tag(etree.ElementTree(p), found[1]))
		return tags

