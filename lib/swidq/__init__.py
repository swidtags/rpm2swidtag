
from lxml import etree
from collections import OrderedDict
from os.path import dirname, join, normpath
import re
from copy import deepcopy

XML_XMLNS = 'http://www.w3.org/XML/1998/namespace'
XMLSI_XMLNS = 'http://www.w3.org/2001/XMLSchema-instance'
SWID_XMLNS = 'http://standards.iso.org/iso/19770/-2/2015/schema.xsd'
SWIDQ_XMLNS = 'http://adelton.fedorapeople.org/swidq'

def resolve_path(base, target):
	return normpath(join(dirname(base), target))

def _push_to_dict_array(d, key, subkey, value):
	if key:
		if key not in d:
			d[key] = OrderedDict()
		d = d[key]
	if subkey not in d:
		d[subkey] = OrderedDict()
	d[subkey][value] = True

class XSLT:
	def __init__(self, file):
		xml = etree.parse(file)
		self.xslt = etree.XSLT(xml.getroot())

	def process(self, swidtag):
		return self.xslt(swidtag.get_xml(), **{ "file": etree.XSLT.strparam(swidtag.get_path()) })

class SWIDTag:
	def __init__(self, file=None, copy_from=None):
		if copy_from:
			self.__dict__ = deepcopy(copy_from.__dict__)
		else:
			return self._load_from_file( file)

	def _load_from_file(self, file):
		self.path = file
		self.xml = None
		self.errors = None
		self.supplemental = False
		self.supplemental_for = []
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
				continue
			m = re.search(r'^((swidpath|swid|file):|[a-z+.]+:)(.+)', href)
			if m:
				if m.group(2) != '':
					self.supplemental_for.append(( m.group(2), m.group(3), href ))
					continue
			else:
				self.supplemental_for.append(( 'file', href, href ))
				continue
			errors.append("file [%s] supplemental Link @href [%s] is not supported" % (file, href))

		if self.supplemental and len(self.supplemental_for) < 1:
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

	@staticmethod
	def _attribs_into_dict(target, element, from_file, value_source):
		root = element.xml.getroot()
		for t in target.keys():
			for e in root.iterfind(t):
				for a in e.keys():
					value = e.get(a)
					if value is not None and not from_file:
						target[t][a] = value
						try:
							del value_source[t][a]
						except KeyError:
							pass
						continue

					if a in target[t] and target[t][a] != value:
						target[t][a] = None
						continue
					target[t][a] = value

					if from_file:
						for ew in e.iterfind("{%s}attr-source" % SWIDQ_XMLNS):
							if ew.get("name") == a:
								_push_to_dict_array(value_source, t, a, ew.get("path"))
								break
						else:
							_push_to_dict_array(value_source, t, a, from_file)

	@staticmethod
	def _dict_into_attribs(element, source, value_source, last_child):
		root = element.xml.getroot()
		for t in source.keys():
			e = root.find(t)
			position = 0
			for a in source[t].keys():
				if source[t][a]:
					if e is None:
						e = etree.SubElement(root, t)
						if last_child is not None:
							last_child.addnext(e)
					if e.get(a) != source[t][a]:
						e.set(a, source[t][a])
						for i in value_source[t][a]:
							rs = etree.SubElement(e, "{%s}attr-source" % SWIDQ_XMLNS)
							rs.set("name", a)
							rs.set("path", i)
							rs.tail = "\n"
							e.insert(position, rs)
							position = position + 1

	@staticmethod
	def _children_without_swidq(e):
		x = []
		for i in e:
			if i.nsmap[i.prefix] != SWIDQ_XMLNS:
				x.append(i)
		return x

	@staticmethod
	def _elements_match(e1, e2):
		if e1.tag != e2.tag \
			or e1.text != e2.text \
			or e1.attrib != e2.attrib:
			return False
		if __class__._children_without_swidq(e1) != __class__._children_without_swidq(e2):
			return False
		return True

	@staticmethod
	def _add_element_source(e, path, to_existing=False):
		if e.find("{%s}element-source" % SWIDQ_XMLNS) is None:
			if to_existing:
				return
		elif not to_existing:
			return
		es = etree.SubElement(e, "{%s}element-source" % SWIDQ_XMLNS)
		es.set("path", path)
		es.tail = "\n"

	def with_supplemented(self, collection, seen=None):
		if len(collection.supplemental_for(self)) < 1:
			return self

		attrib_merge = {
			".": {
				"tagId": None,
				"tagVersion": None,
				"supplemental": None,
				"{%s}lang" % XML_XMLNS: None,
				"{%s}schemaLocation" % XMLSI_XMLNS: None,
			},
			"{%s}Meta" % SWID_XMLNS: {}
		}
		value_source = {}

		self = SWIDTag(copy_from=self)
		last_child = list(self.xml.getroot())[-1]

		supplementals = []
		for s in collection.supplemental_for(self):
			spath = s.get_path()
			if seen and spath in seen:
				break_loop = etree.SubElement(self.xml.getroot(), "{%s}supplemental" % SWIDQ_XMLNS)
				break_loop.set("path", spath)
				break_loop.set("break-loop", "true")
				break_loop.tail = "\n"
				continue

			if seen:
				local_seen = deepcopy(seen)
			else:
				local_seen = set()
			local_seen.add(spath)
			s = s.with_supplemented(collection, seen=local_seen)
			__class__._attribs_into_dict(attrib_merge, s, spath, value_source)

			for e in s.xml.getroot().iterfind("{%s}Entity" % SWID_XMLNS):
				roles = e.get("role")
				if not roles:
					continue
				for r in roles.split():
					if r == "tagCreator":
						continue
					ne = deepcopy(e)
					ne.set("role", r)
					for t in self.xml.getroot().iterfind("{%s}Entity" % SWID_XMLNS):
						if __class__._elements_match(ne, t):
							__class__._add_element_source(t, spath, to_existing=True)
							break
						te = deepcopy(t)
						te.set("role", r)
						if __class__._elements_match(ne, te) \
							and t.find("{%s}element-source" % SWIDQ_XMLNS) is None:
							__class__._add_element_source(t, spath, to_existing=True)
							break
					else:
						__class__._add_element_source(ne, spath)
						self.xml.getroot().append(ne)

			for e in s.xml.getroot().iterfind("{%s}Link" % SWID_XMLNS):
				rel = e.get("rel")
				if not rel or rel == "supplemental":
					continue
				for t in self.xml.getroot().iterfind("{%s}Link" % SWID_XMLNS):
					if __class__._elements_match(e, t):
						__class__._add_element_source(t, spath, to_existing=True)
						break
				else:
					ne = deepcopy(e)
					__class__._add_element_source(ne, spath)
					self.xml.getroot().append(ne)

			rs = etree.Element("{%s}supplemental" % SWIDQ_XMLNS)
			rs.set("path", spath)
			rs.tail = "\n"
			rs.append(s.get_xml().getroot())
			supplementals.append(rs)

		__class__._attribs_into_dict(attrib_merge, self, None, value_source)
		__class__._dict_into_attribs(self, attrib_merge, value_source, last_child)

		for e in supplementals:
			self.get_xml().getroot().append(e)

		return self

class SWIDTagCollection:
	def __init__(self):
		self.by_tags = {}
		self.by_filenames = OrderedDict()
		self._cache_supplemental = None

	def get_by_tagid(self, tagid):
		return self.by_tags.get(tagid)

	def load_swidtag_file(self, file):
		if file in self.by_filenames:
			return(( self.by_filenames[file], False, None ))
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

	def _add_to_cache_supplemental(self, supplemented, supplemental, href, stderr=None, debug=False, prefix=""):
		_push_to_dict_array(self._cache_supplemental, None, supplemented, supplemental)
		if debug and stderr:
			stderr.write("%smarking [%s] supplemented by [%s] via [%s]\n" % (prefix, supplemented, supplemental.get_path(), href))

	def compute_supplemental(self, stderr=None, prefix="", debug=False, silent=True):
		self._cache_supplemental = {}
		for tag in self.by_filenames.values():
			for s in tag.get_supplemental_for():
				if s[0] == 'swid':
					if s[1] in self.by_tags:
						for f in self.by_tags[s[1]]:
							self._add_to_cache_supplemental(f, tag, s[2], stderr=stderr, prefix=prefix, debug=debug)
						continue
				elif s[0] == 'file':
					t = resolve_path(tag.get_path(), s[1])
					if t in self.by_filenames:
						self._add_to_cache_supplemental(t, tag, s[2], stderr=stderr, prefix=prefix, debug=debug)
						continue
				elif s[0] == 'swidpath':
					for p in self.by_filenames.values():
						for si in p.xml.xpath(s[1], namespaces = { 'swid': SWID_XMLNS }):
							if not si.getparent():
								self._add_to_cache_supplemental(p.get_path(), tag, s[2], stderr=stderr, prefix=prefix, debug=debug)
								break
					else:
						continue
				if not silent:
					stderr.write("%s[%s] supplements [%s] which we do not know\n" % (prefix, tag.get_tagid(), s[2]))
		return self

	def supplemental_for(self, tag):
		if not self._cache_supplemental:
			self.compute_supplemental()
		if tag.get_path() in self._cache_supplemental:
			return self._cache_supplemental[tag.get_path()]
		return []

	def __iter__(self):
		for tag in self.by_filenames.values():
			if not tag.is_supplemental():
				yield tag
		for tag in self.by_filenames.values():
			if tag.is_supplemental():
				yield tag
