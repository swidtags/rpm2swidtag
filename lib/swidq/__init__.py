
from lxml import etree

SWID_XMLNS = 'http://standards.iso.org/iso/19770/-2/2015/schema.xsd'

class SWIDTag:
	def __init__(self, file):
		self.path = file
		self.xml = None
		self.errors = None
		self.tagid = None
		self.tagversion = None

		try:
			self.xml = etree.parse(file)
		except OSError as e:
			self.errors = [ "error reading file [%s]: %s" % (file, str(e)) ]
			return
		except etree.XMLSyntaxError as e:
			self.errors = [ "error parsing file [%s]: %s" % (file, str(e)) ]
			return

		errors = []
		for si in self.xml.iter("{%s}SoftwareIdentity" % SWID_XMLNS):
			tagid = si.get("tagId")
			if tagid is None:
				errors.append("file [%s] does not have SoftwareIdentity/@tagId" % file)
				break
			self.tagid = tagid
			self.tagversion = int(si.get("tagVersion", 0))
			self.name = si.get("name")

		if len(errors) > 0:
			self.errors = errors

	def get_path(self):
		return self.path

	def get_tagid(self):
		return self.tagid

	def get_tagversion(self):
		return self.tagversion

	def get_name(self):
		return self.name

	def get_errors(self):
		return self.errors

	def get_info(self):
		return "file [%s] tagId [%s] tagVersion [%s]" % (self.path, self.get_tagid(), self.get_tagversion())
