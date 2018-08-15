
from rpm import fi
from lxml import etree
import re
from stat import S_ISDIR
from rpm2swidtag import XMLNS

class SWIDPayloadExtension(etree.XSLTExtension):
	def __init__(self, rpm_header):
		self.rpm_header = rpm_header

	def execute(self, context, self_node, input_node, output_parent):
		indent = self._get_indent(input_node)
		indent_parent = self._get_indent(input_node.getparent())

		indent_level = '  '
		if indent and indent_parent and indent.startswith(indent_parent) and indent != indent_parent:
			indent_level = indent[length(indent_parent):]

		NSMAP = {
			None: 'http://standards.iso.org/iso/19770/-2/2015/schema.xsd',
			'sha256': 'http://www.w3.org/2001/04/xmlenc#sha256',
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
				location = re.sub(r'^(.+)/$', '\g<1>', location)
				e.set("location", location)
			if f[12] and f[12] != "0" * 64:
				e.set("{%s}hash" % NSMAP['sha256'], f[12])
			if append_to is None:
				append_to = output
			append_to.append(e)
		if len(output) > 0 and indent is not None:
			output_parent.text = "\n" + indent + indent_level
			self._set_indent(output, None, indent, indent_level)
		for e in output:
			output_parent.append(e)

	def cleanup_namespaces(self, e):
		for i in e:
			if 'payload-generated-42' in i.nsmap:
				etree.cleanup_namespaces(i, top_nsmap=i.getparent().nsmap)
			else:
				self.cleanup_namespaces(i)

	@staticmethod
	def _get_indent(e):
		if e is None:
			return None
		indent = ''
		if e.getprevious():
			indent = e.getprevious().tail
		elif e.getparent():
			indent = e.getparent().text
		if indent is None:
			return None
		m = re.search(r'.*\n([ \t]*)', indent)
		if m is not None:
			return m.group(1)
		return None

	@staticmethod
	def _set_indent(l, parent, indent, indent_level, level = 0):
		if len(l) > 0:
			if parent is not None:
				parent.text = "\n" + indent + indent_level * (level + 1)
			for i in l:
				i.tail = "\n" + indent + indent_level * (level + 1)
				if len(i) > 0:
					__class__._set_indent(i, i, indent, indent_level, level + 1)
				del i.attrib["fullname"]
			l[-1].tail = "\n" + indent + indent_level * level

