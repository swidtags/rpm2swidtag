
from lxml import etree
from collections import OrderedDict

SWID_XMLNS = 'http://standards.iso.org/iso/19770/-2/2015/schema.xsd'

class XSLT:
	def __init__(self, file):
		xml = etree.parse(file)
		self.xslt = etree.XSLT(xml.getroot())

	def process(self, swidtag):
		return self.xslt(swidtag.get_xml(), **{ "file": etree.XSLT.strparam(swidtag.get_path()) })

class SWIDTag:
	def __init__(self, file):
		self.path = file
		self.xml = None
		self.errors = None
		self.supplemental = False
		self.supplemental_for = None
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

		si = self.xml.getroot()
		roottag = si.tag
		if roottag != "{%s}SoftwareIdentity" % SWID_XMLNS:
			self.errors = [ "file [%s] does not have SoftwareIdentity in the SWID 2015 namespace, found [%s]" % (file, roottag) ]
			return

		tagid = si.get("tagId")
		if tagid is None:
			self.errors = [ "file [%s] does not have SoftwareIdentity/@tagId" % file ]
			return
		name = si.get("name")
		if name is None:
			self.errors = [ "file [%s] does not have SoftwareIdentity/@name" % file ]
			return

		self.tagid = tagid
		self.name = name

		if si.get("supplemental", "false") == "true":
			self.supplemental = True

		errors = []
		supplemental_for = []

		for link in si.iterfind("{%s}Link" % SWID_XMLNS):
			rel = link.get("rel")
			if rel is None or rel != 'supplemental':
				continue
			if not self.supplemental:
				errors.append("file [%s] has Link with @rel='supplemental' but not @supplemental='true'" % file)
				break
			href = link.get("href")
			if href is None:
				errors.append("file [%s] has Link with @rel='supplemental' but no @href" % file)
				break
			if not href.startswith("swid:"):
				errors.append("file [%s] supplemental Link @href [%s] is not supported" % (file, href))
				break
			supplemental_for.append(href)

		if self.supplemental:
			if len(supplemental_for) > 0:
				self.supplemental_for = supplemental_for
			else:
				errors.append("file [%s] is supplemental but does not have any supplemental Link" % file)

		if len(errors) > 0:
			self.errors = errors

	def get_xml(self):
		return self.xml

	def get_path(self):
		return self.path

	def get_tagid(self):
		return self.tagid

	def get_tagversion(self):
		return int(self.xml.getroot().get("tagVersion", 0))

	def get_name(self):
		return self.name

	def get_errors(self):
		return self.errors

	def get_info(self):
		return "file [%s] tagId [%s] tagVersion [%s]" % (self.path, self.get_tagid(), self.get_tagversion())

	def get_supplemental_for(self):
		return self.supplemental_for

	def is_supplemental(self):
		return self.supplemental

	def get_rpm_resources(self):
		res = []
		for rpm in self.xml.xpath("/swid:SoftwareIdentity/swid:*[name() = 'Evidence' or name() = 'Payload']/swid:Resource[@type = 'rpm']/@rpm", namespaces = { 'swid': SWID_XMLNS }):
			res.append(rpm)
		return res

class SWIDTagCollection:
	def __init__(self):
		self.by_tags = {}
		self.by_filenames = OrderedDict()
		self._cache_supplemental = None

	def get_by_tagid(self, tagid):
		return self.by_tags.get(tagid)

	def load_swidtag_file(self, file):
		swidtag = SWIDTag(file)
		if swidtag.get_errors():
			return((None, True, swidtag.get_errors()))
		file = swidtag.get_path()
		self.by_filenames[file] = swidtag
		tagid = swidtag.get_tagid()
		if tagid in self.by_tags:
			self.by_tags[tagid].append(file)
		else:
			self.by_tags[tagid] = [ file ]
		self._cache_supplemental = None
		return((swidtag, False, None))

	def compute_supplemental(self, stderr=None, prefix="", debug=False, silent=True):
		self._cache_supplemental = {}
		for tag in self.by_filenames.values():
			supplemental_for = tag.get_supplemental_for()
			if not supplemental_for:
				continue
			for href in supplemental_for:
				if not href.startswith("swid:"):
					continue
				if debug:
					stderr.write("%smarking [%s] supplemented by [%s]\n" % (prefix, href, tag.get_tagid()))
				if href[5:] not in self.by_tags:
					if not silent:
						stderr.write("%s[%s] supplements [%s] which we do not know\n" % (prefix, tag.get_tagid(), href))
					continue
				if href[5:] not in self._cache_supplemental:
					self._cache_supplemental[href[5:]] = [ tag ]
				else:
					self._cache_supplemental[href[5:]].append(tag)
		return self

	def supplemental_for(self, tag):
		if not self._cache_supplemental:
			self.compute_supplemental()
		if tag.get_tagid() in self._cache_supplemental:
			return self._cache_supplemental[tag.get_tagid()]
		return []

	def __iter__(self):
		for tag in self.by_filenames.values():
			if not tag.is_supplemental():
				yield tag
		for tag in self.by_filenames.values():
			if tag.is_supplemental():
				yield tag
