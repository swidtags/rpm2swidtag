
from lxml import etree
from sys import stderr

class Error(Exception):
	def __init__(self, strerror):
		self.strerror = strerror

from rpm2swidtag import rpm
from rpm2swidtag import payload

def _parse_xml(file, msg):
	x = None
	try:
		x = etree.parse(file)
	except OSError as e:
		raise Error("Error reading %s [%s]: %s" % (msg, file, str(e))) from None
	except etree.XMLSyntaxError as e:
		raise Error("Error parsing %s [%s]: %s" % (msg, file, str(e))) from None
	return x

def _pass_in_hdr(ih):
	def tag_from_header(c, tag):
		if tag == 'arch' and rpm.is_source_package(ih):
			return b'src.rpm'
		try:
			return ih[tag]
		except ValueError as e:
			raise Error("Unknown header tag [%s] requested by XSLT stylesheet: %s" % (tag, str(e))) from None
		return ''
	return tag_from_header

class Tag:
	def __init__(self, xml, encoding):
		self.xml = xml
		self.encoding = encoding

	def tostring(self):
		return etree.tostring(self.xml, pretty_print=True, xml_declaration=True, encoding=self.encoding)

XMLNS = 'http://adelton.fedorapeople.org/rpm2swidtag'
class Template:
	def __init__(self, xml_template, xslt):
		self.xml_template = _parse_xml(xml_template, "SWID template file")
		self.xslt_stylesheet = _parse_xml(xslt, "processing XSLT file")

	def generate_tag_for_header(self, rpm_header):
		ns = etree.FunctionNamespace(XMLNS)
		ns['package_tag'] = _pass_in_hdr(rpm_header)

		generate_payload = payload.SWIDPayloadExtension(rpm_header)

		transform = etree.XSLT(self.xslt_stylesheet.getroot(),
			extensions = { (XMLNS, 'generate-payload') : generate_payload })
		return Tag(transform(self.xml_template), self.xml_template.docinfo.encoding)

