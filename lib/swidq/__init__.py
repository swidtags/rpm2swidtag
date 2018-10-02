
from lxml import etree
from collections import OrderedDict

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

class SWIDTagCollection:
	def __init__(self):
		self.by_tags = OrderedDict()
		self.by_filenames = {}

	def get_by_tagid(self, tagid):
		if tagid in self.by_tags:
			return self.by_tags[tagid]
		return None

	def load_swidtag_file(self, file):
		swidtag = SWIDTag(file)
		if swidtag.get_errors():
			return((None, True, swidtag.get_errors()))
		tagid = swidtag.get_tagid()
		previous = self.get_by_tagid(tagid)
		msgs = None
		if previous:
			prev_tagversion = previous.get_tagversion()
			prev_path = previous.get_path()
			if prev_tagversion >= swidtag.get_tagversion():
				return((None, False, [ "skipping [%s] as existing file [%s] has already tagVersion [%s]" % (swidtag.get_path(), prev_path, prev_tagversion) ]))
			msgs = [ "[%s] overriding previous file [%s] which had lower tagVersion [%s]" % (swidtag.get_path(), prev_path, prev_tagversion) ]
			del self.by_filenames[prev_path]
		file = swidtag.get_path()
		self.by_filenames[file] = tagid
		self.by_tags[tagid] = swidtag
		return((swidtag, False, msgs))

	def __iter__(self):
		self._iter = iter(self.by_tags)
		return self

	def __next__(self):
		n = next(self._iter)
		if n:
			return self.by_tags[n]
		raise StopIteration()
