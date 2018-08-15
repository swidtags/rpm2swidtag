
from rpm import fi
from lxml import etree
import re
from stat import S_ISDIR

class SWIDPayloadExtension(etree.XSLTExtension):
	def __init__(self, rpm_header):
		self.rpm_header = rpm_header

	def execute(self, context, self_node, input_node, output_parent):
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
			output_parent.append(e)

