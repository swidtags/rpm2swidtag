#!/usr/bin/python3

from sys import argv, exit, stderr, stdout
from os import open, O_RDONLY, close, getenv
import rpm
from lxml import etree

if len(argv) < 2:
	stderr.write("Usage: %s file.rpm\n" % (argv[0]))
	exit(2)

try:
	fdno = open(argv[1], O_RDONLY)
except FileNotFoundError as e:
	stderr.write("%s: Error reading [%s]: %s\n" % (argv[0], argv[1], e.strerror))
	exit(3)

ts = rpm.TransactionSet()
try:
	h = ts.hdrFromFdno(fdno)
except rpm.error as e:
	stderr.write("%s: Error parsing rpm file [%s]: %s\n" % (argv[0], argv[1], str(e)))
	exit(4)

close(fdno)

arch = h['arch']
if h[rpm.RPMTAG_SOURCEPACKAGE]:
	arch = b'src.rpm'

def parse_xml(file, msg):
	x = None
	try:
		x = etree.parse(file)
	except OSError as e:
		stderr.write("%s: Error reading %s [%s]: %s\n" % (argv[0], msg, file, e.strerror))
		exit(5)
	except etree.XMLSyntaxError as e:
		stderr.write("%s: Error parsing %s [%s]: %s\n" % (argv[0], msg, file, str(e)))
		exit(6)
	return x

DATA_DIR = "/etc/rpm2swidtag"
data_dir = getenv('RPM2SWIDTAG_TEMPLATE_DIR', DATA_DIR)
xml_template = getenv('RPM2SWIDTAG_TEMPLATE', data_dir + "/template.swidtag")
xslt_file = getenv('RPM2SWIDTAG_XSLT', data_dir + "/swidtag.xslt")

x = parse_xml(xml_template, "SWID template file")
s = parse_xml(xslt_file, "processing XSLT file")

params = {
	'name': etree.XSLT.strparam(h['name']),
	'version': etree.XSLT.strparam(h['version']),
	'release': etree.XSLT.strparam(h['release']),
	'arch': etree.XSLT.strparam(arch)
}

t = etree.XSLT(s.getroot())
o = t(x, **params)

os = etree.tostring(o, pretty_print=True)

stdout.write(os.decode())

