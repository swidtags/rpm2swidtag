
from lxml import etree
from os import path, stat
from hashlib import sha256
from io import BytesIO
from gzip import GzipFile
from rpm2swidtag import Error

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

	@property
	def packages(self):
		return self.xml.xpath("/common:metadata/common:package[@type = 'rpm']/common:location/@href", namespaces = { 'common': COMMON_XMLNS })

class Swidtags:
	def __init__(self, repo):
		self.repo = repo
		self.href = None
		self.xml = etree.Element("{%s}metadata" % SWIDTAGLIST_XMLNS, nsmap={ None: SWIDTAGLIST_XMLNS })

	def add(self, package, swidtags):
		pxml = etree.Element("{%s}package" % SWIDTAGLIST_XMLNS)
		pxml.set("href", package)
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
		timestamp = int(stat(self.path).st_mtime)

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
		etree.SubElement(self.repomd_xml, "{%s}timestamp" % REPO_XMLNS).text = str(timestamp)
		etree.SubElement(self.repomd_xml, "{%s}size" % REPO_XMLNS).text = str(len(value_gz))
		etree.SubElement(self.repomd_xml, "{%s}open-size" % REPO_XMLNS).text = str(len(value))

		repomd = self.repo.repomd
		for s in repomd.xml.xpath("/repo:repomd/repo:data[@type = 'swidtags']", namespaces = { 'repo': REPO_XMLNS }):
			s.getparent().remove(s)
		for t in repomd.xml.xpath("/repo:repomd", namespaces = { 'repo': REPO_XMLNS }):
			t.append(self.repomd_xml)
		repomd.save()

