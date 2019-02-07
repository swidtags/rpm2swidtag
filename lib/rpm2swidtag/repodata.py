
from lxml import etree
from os import path, stat
from hashlib import sha256
from io import BytesIO
from gzip import GzipFile
from rpm2swidtag import Error, SWID_XMLNS

REPO_XMLNS = "http://linux.duke.edu/metadata/repo"
COMMON_XMLNS = "http://linux.duke.edu/metadata/common"
SWIDTAGLIST_XMLNS = "http://adelton.fedorapeople.org/rpm2swidtag/metadata-fixme"

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

class Repomd(Repodata):
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
		self.xml.write(self.path, xml_declaration=True, encoding="utf-8", pretty_print=True)

class Primary:
	def __init__(self, repo, primary):
		self.repo = repo
		self.href = primary
		self.path = path.join(self.repo.path, self.href)
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
		return Package(self.list[self.index - 1])

class Package:
	def __init__(self, element):
		self.element = element
		self.href_fn = None
		self.pkgid_fn = None

	@property
	def href(self):
		if not self.href_fn:
			self.href_fn = etree.XPath("common:location/@href", namespaces = { 'common': COMMON_XMLNS })
		return self.href_fn(self.element)[0]

	@property
	def pkgid(self):
		if not self.pkgid_fn:
			self.pkgid_fn = etree.XPath("common:checksum[@pkgid = 'YES']/text()", namespaces = { 'common': COMMON_XMLNS })
		return str(self.pkgid_fn(self.element)[0])

class Swidtags:
	def __init__(self, repo, file=None):
		self.repo = repo
		self.href = None
		self.location_index = None
		self.file = file
		if self.file:
			self.xml = etree.parse(self.file)
		else:
			self.xml = etree.Element("{%s}metadata" % SWIDTAGLIST_XMLNS, nsmap={ None: SWIDTAGLIST_XMLNS })

	def add(self, package, swidtags):
		pxml = etree.Element("{%s}package" % SWIDTAGLIST_XMLNS)
		pxml.set("pkgid", package.pkgid)
		for s in swidtags:
			pxml.append(s.xml.getroot())
		self.xml.append(pxml)

	def save(self):
		data = BytesIO()
		etree.ElementTree(self.xml).write(data, xml_declaration=True, encoding="utf-8", pretty_print=True)
		data_gz = BytesIO()
		with GzipFile(fileobj=data_gz, mode="wb", mtime=0) as f:
			f.write(data.getvalue())
		value_gz = data_gz.getvalue()
		checksum = sha256(value_gz).hexdigest()
		self.href = "repodata/%s-swidtags.xml.gz" % checksum
		self.path = path.join(self.repo.path, self.href)
		with open(self.path, "wb") as f:
			f.write(value_gz)
		timestamp = str(int(stat(self.path).st_mtime))

		self.repomd_xml = etree.Element("{%s}data" % REPO_XMLNS)
		self.repomd_xml.set("type", "swidtags")
		c = etree.SubElement(self.repomd_xml, "{%s}checksum" % REPO_XMLNS)
		c.set("type", "sha256")
		c.text = checksum
		value = data.getvalue()
		oc = etree.SubElement(self.repomd_xml, "{%s}open-checksum" % REPO_XMLNS)
		oc.set("type", "sha256")
		oc.text = sha256(value).hexdigest()
		etree.SubElement(self.repomd_xml, "{%s}location" % REPO_XMLNS).set("href", self.href)
		etree.SubElement(self.repomd_xml, "{%s}timestamp" % REPO_XMLNS).text = timestamp
		etree.SubElement(self.repomd_xml, "{%s}size" % REPO_XMLNS).text = str(len(value_gz))
		etree.SubElement(self.repomd_xml, "{%s}open-size" % REPO_XMLNS).text = str(len(value))

		repomd = self.repo.repomd
		for s in repomd.xml.xpath("/repo:repomd/repo:data[@type = 'swidtags']", namespaces = { 'repo': REPO_XMLNS }):
			s.getparent().remove(s)
		for t in repomd.xml.xpath("/repo:repomd", namespaces = { 'repo': REPO_XMLNS }):
			t.append(self.repomd_xml)
		for t in repomd.xml.xpath("/repo:repomd/repo:revision", namespaces = { 'repo': REPO_XMLNS }):
			t.text = timestamp
		repomd.save()

	def tags_for_repo_packages(self, pkgs):
		pkgids = {}
		for p in pkgs:
			pkgids[p.chksum[1].hex()] = p
		tags = {}
		for e in self.xml.xpath("/swidtags:metadata/swidtags:package", namespaces = { "swidtags": SWIDTAGLIST_XMLNS }):
			pkgid = e.get("pkgid")
			if pkgid not in pkgids:
				continue
			tp = pkgids[pkgid]
			tags[tp] = {}
			for p in e:
				for r in p.xpath("./swid:Entity[contains(concat(' ', @role, ' '), ' tagCreator ')]/@regid", namespaces = { 'swid': SWID_XMLNS }):
					if r not in tags[tp]:
						tags[tp][r] = {}
					tags[tp][r][p.get("tagId")] = etree.parse(BytesIO(etree.tostring(p)), etree.XMLParser(remove_blank_text = True))
		return tags

	def tags_for_rpm_packages(self, pkgs):
		pkg256headers = {}
		for p in pkgs:
			if p["SHA256HEADER"]:
				pkg256headers[( p["name"].decode("utf-8"), p["SHA256HEADER"].decode("utf-8") )] = p
		tags = {}
		for e in self.xml.xpath("/swidtags:metadata/swidtags:package", namespaces = { "swidtags": SWIDTAGLIST_XMLNS }):
			found = None
			for rs in e.xpath("swid:SoftwareIdentity/swid:Payload/swid:Resource[@type = 'rpm'] | swid:SoftwareIdentity/swid:Evidence/swid:Resource[@type = 'rpm']", namespaces = { 'swid': SWID_XMLNS }):
				h = rs.get("sha256header")
				if h:
					found = (rs.getparent().getparent().get("name"), h)
					break
			if not found or found not in pkg256headers:
				continue
			tp = pkg256headers[found]
			tags[tp] = {}
			for p in e:
				for r in p.xpath("./swid:Entity[contains(concat(' ', @role, ' '), ' tagCreator ')]/@regid", namespaces = { 'swid': SWID_XMLNS }):
					if r not in tags[tp]:
						tags[tp][r] = {}
					tags[tp][r][p.get("tagId")] = etree.parse(BytesIO(etree.tostring(p)), etree.XMLParser(remove_blank_text = True))
		return tags

