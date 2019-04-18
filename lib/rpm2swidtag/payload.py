
from rpm import fi, RPMFILE_CONFIG, RPMFILE_DOC, RPMFILE_MISSINGOK, RPMFILE_GHOST, \
	RPMFILE_LICENSE, RPMFILE_README, RPMVERIFY_FILEDIGEST, RPMVERIFY_FILESIZE
from lxml import etree
import re
from stat import S_ISDIR
from rpm2swidtag import XMLNS, SWID_XMLNS

class SWIDPayloadExtension(etree.XSLTExtension):
	def __init__(self, rpm_header):
		super().__init__()
		self.rpm_header = rpm_header

	def execute(self, _context, _self_node, _input_node, output_parent):
		NSMAP = {
			None: SWID_XMLNS,
			'sha256': 'http://www.w3.org/2001/04/xmlenc#sha256',
			'md5': 'http://www.w3.org/2001/04/xmldsig-more#md5',
			'n8060': 'http://csrc.nist.gov/ns/swid/2015-extensions/1.0',
			'payload-generated-42': XMLNS,
		}

		output = []
		last_dir = None
		for f in fi(self.rpm_header):
			append_to = None

			name = f[0]
			location = None
			m = re.search(r'^(.*/)(.+)$', name)
			if m is not None:
				location = m.group(1)
				name = m.group(2)

				while location is not None and last_dir is not None:
					last_dir_path = last_dir.get('fullname') + '/'
					if location.startswith(last_dir_path):
						location = location[len(last_dir_path):]
						append_to = last_dir
						break
					last_dir = last_dir.getparent()

			if S_ISDIR(f[2]):
				e = etree.Element("Directory", nsmap=NSMAP)
				last_dir = e
			else:
				e = etree.Element("File", size=str(f[1]), nsmap=NSMAP)

			e.set("fullname", f[0])
			e.set("name", name)
			if location:
				location = re.sub(r'^(.+)/$', r'\g<1>', location)
				e.set("location", location)
			if f[12]:
				if len(f[12]) == 64 and f[12] != "0" * 64:
					e.set("{%s}hash" % NSMAP['sha256'], f[12])
				if len(f[12]) == 32 and f[12] != "0" * 32:
					e.set("{%s}hash" % NSMAP['md5'], f[12])
			if not S_ISDIR(f[2]):
				if (f[4] & (RPMFILE_CONFIG | RPMFILE_GHOST)) \
					or (f[9] & RPMVERIFY_FILEDIGEST) == 0 \
					or (f[9] & RPMVERIFY_FILESIZE) == 0:
					e.set("{%s}mutable" % NSMAP['n8060'], "true")
				if not (f[4] & (RPMFILE_DOC | RPMFILE_MISSINGOK | RPMFILE_GHOST | RPMFILE_LICENSE | RPMFILE_README)):
					e.set("key", "true")

			if append_to is None:
				append_to = output
			append_to.append(e)
		self._cleanup_fullname(output)
		for e in output:
			output_parent.append(e)

	def cleanup_namespaces(self, e):
		if e is None:
			return
		for i in e:
			if 'payload-generated-42' in i.nsmap:
				etree.cleanup_namespaces(i, top_nsmap=i.getparent().nsmap)
			else:
				self.cleanup_namespaces(i)

	@staticmethod
	def _cleanup_fullname(l):
		for i in l:
			del i.attrib["fullname"]
			#pylint: disable=protected-access
			__class__._cleanup_fullname(i)

