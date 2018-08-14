#!/usr/bin/python3

from sys import argv, exit, stderr, stdout
from os import open, O_RDONLY, close, getenv
import rpm
from lxml import etree
import argparse

parser = argparse.ArgumentParser(description='SWID tag parameters.')
parser.add_argument('-p', '--package', dest='rpmfile', action='store_true', help='process rpm package file')
parser.add_argument('package', type=str, help='package or file name')
opts = parser.parse_args()

h = None

# We only assume the use of _RPM2SWIDTAG_RPMDBPATH for testing, really
rpmdb_path = getenv('_RPM2SWIDTAG_RPMDBPATH')
if rpmdb_path is not None:
	rpm.addMacro('_dbpath', rpmdb_path)
ts = rpm.TransactionSet()
ts.openDB()
if rpmdb_path is not None:
	rpm.delMacro('_dbpath')
if opts.rpmfile:
	try:
		fdno = open(opts.package, O_RDONLY)
	except FileNotFoundError as e:
		stderr.write("%s: Error reading [%s]: %s\n" % (argv[0], opts.package, e.strerror))
		exit(3)
	try:
		h = ts.hdrFromFdno(fdno)
		close(fdno)
	except rpm.error as e:
		stderr.write("%s: Error parsing rpm file [%s]: %s\n" % (argv[0], opts.package, str(e)))
		exit(4)
else:
	l = ts.dbMatch('name', opts.package)
	if len(l) < 1:
		stderr.write("%s: No package [%s] found in database\n" % (argv[0], opts.package))
		exit(7)
	if len(l) > 1:
		stderr.write("%s: Multiple packages matching [%s] found in database\n" % (argv[0], opts.package))
		exit(8)
	for h in l:
		break

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
xslt_file = getenv('RPM2SWIDTAG_XSLT', data_dir + "/rpm2swidtag.xslt")

x = parse_xml(xml_template, "SWID template file")

def pass_in_hdr(ih):
	def tag_from_header(c, tag):
		if tag == 'arch':
			return arch
		try:
			return ih[tag]
		except ValueError as e:
			stderr.write("Unknown header tag [%s]: %s\n" % (tag, e))
		return ''
	return tag_from_header

ns = etree.FunctionNamespace("http://adelton.fedorapeople.org/rpm2swidtag")
ns.prefix = 'x'
ns['package_tag'] = pass_in_hdr(h)

s = parse_xml(xslt_file, "processing XSLT file")

t = etree.XSLT(s.getroot())
o = t(x)

os = etree.tostring(o, pretty_print=True, xml_declaration=True, encoding=x.docinfo.encoding)

stdout.write(os.decode())

