
from rpm import fi
from lxml import etree
import re
from stat import S_ISDIR

class SWIDPayloadExtension(etree.XSLTExtension):
	def __init__(self, rpm_header):
		self.rpm_header = rpm_header

	def execute(self, context, self_node, input_node, output_parent):
		indent = self._get_indent(input_node)
		indent_parent = self._get_indent(input_node.getparent())

		indent_level = '  '
		if indent and indent_parent and indent.startswith(indent_parent) and indent != indent_parent:
			indent_level = indent[length(indent_parent):]

		output = []
		for f in fi(self.rpm_header):
			name = f[0]
			location = None
			m = re.search(r'^(.*/)(.+)$', name)
			if m is not None:
				location = m.group(1)
				name = m.group(2)

			if S_ISDIR(f[2]):
				e = etree.Element("Directory")
			else:
				e = etree.Element("File", size=str(f[1]))
			e.set("name", name)
			if location:
				e.set("location", location)
			output.append(e)
		if len(output) > 0 and indent is not None:
			output_parent.text = "\n" + indent + indent_level
			for e in output:
				e.tail = "\n" + indent + indent_level
			output[-1].tail = "\n" + indent
		for e in output:
			output_parent.append(e)

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

