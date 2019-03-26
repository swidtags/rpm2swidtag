
from lxml import etree
from sys import stderr
import re
import sys
import io
import subprocess

XMLNS = 'http://adelton.fedorapeople.org/rpm2swidtag'
SWID_XMLNS = 'http://standards.iso.org/iso/19770/-2/2015/schema.xsd'

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

def _escape_char(m):
	return "".join(map(lambda x : "^%x" % ord(x), list(m.group(0))))

def escape_path(x):
	return re.sub(r"^\.+", _escape_char, re.sub(r"[^a-zA-Z0-9._:-]+", _escape_char, x), 1)

class Tag:
	def __init__(self, xml):
		self.xml = xml

	def write_output(self, file):
		self.xml.write_output(file)

	def get_tagid(self):
		r = self.xml.xpath('/swid:SoftwareIdentity/@tagId', namespaces = { 'swid': SWID_XMLNS })
		return escape_path(r[0])

	def get_tagcreator_regid(self):
		r = self.xml.xpath("/swid:SoftwareIdentity/swid:Entity[contains(concat(' ', @role, ' '), ' tagCreator ')]/@regid",
			namespaces = { 'swid': SWID_XMLNS })
		return escape_path(r[0])

	def sign_pem(self, pem_opt):
		return SignedTag(self, pem_opt)

class SignedTag(Tag):
	def __init__(self, tag, pem_opt):
		in_data = io.BytesIO()
		tag.write_output(in_data)
		result = subprocess.run(['xmlsec1', '--sign',
			'--enabled-reference-uris', 'empty',
			'--privkey-pem', pem_opt, '-'],
			input=in_data.getvalue(),
			stdout=subprocess.PIPE, stderr=subprocess.PIPE, close_fds=False)
		if result.returncode != 0:
			raise Error("Error signing using [%s]: %s" % (pem_opt, result.stderr))
		self.xml = etree.parse(io.BytesIO(result.stdout), etree.XMLParser(remove_blank_text = True))

	def write_output(self, file):
		self.xml.write(file, xml_declaration=True, encoding="utf-8", pretty_print=True)

class Template:
	def __init__(self, xml_template, xslt):
		self.xml_template = _parse_xml(xml_template, "SWID template file")
		self.xslt_stylesheet = _parse_xml(xslt, "processing XSLT file")

	def generate_tag_for_header(self, rpm_header, params={}):
		ns = etree.FunctionNamespace(XMLNS)
		ns['package_tag'] = _pass_in_hdr(rpm_header)

		generate_payload = payload.SWIDPayloadExtension(rpm_header)

		try:
			transform = etree.XSLT(self.xslt_stylesheet.getroot(),
				extensions = { (XMLNS, 'generate-payload') : generate_payload })

			str_params = {}
			for i in params:
				str_params[i] = etree.XSLT.strparam(params[i])
			tag = Tag(transform(self.xml_template, **str_params))
			generate_payload.cleanup_namespaces(tag.xml.getroot())
			return tag
		# except etree.XSLTApplyError as e:
		except TypeError as e:
			raise Error("Error processing SWID tag: %s" % str(e))

