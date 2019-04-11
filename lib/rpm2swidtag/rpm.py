
from os import open, O_RDONLY, close
import rpm, re
from rpm2swidtag import Error

def read_from_file(file):
	fdno = None
	try:
		fdno = open(file, O_RDONLY)
		ts = rpm.TransactionSet('', rpm._RPMVSF_NOSIGNATURES)
		h = ts.hdrFromFdno(fdno)
		return h
	except FileNotFoundError as e:
		raise Error("Error reading rpm file [%s]: %s" % (file, e.strerror))
	except rpm.error as e:
		raise Error("Error reading rpm file [%s]: %s" % (file, str(e)))
	finally:
		if fdno:
			close(fdno)

def read_from_db(package, rpmdb_path=None, glob=False):
	if rpmdb_path is not None:
		rpm.addMacro('_dbpath', rpmdb_path)
	ts = rpm.TransactionSet()
	ts.openDB()
	if rpmdb_path is not None:
		rpm.delMacro('_dbpath')
	try:
		if glob:
			l = ts.dbMatch(rpm.RPMDBI_LABEL)
			if package != '*':
				l.pattern('name', rpm.RPMMIRE_GLOB, package)
		else:
			l = ts.dbMatch(rpm.RPMDBI_LABEL, package)
		return l
	except rpm.error as e:
		raise Error(str(e))

def is_source_package(h):
	if h[rpm.RPMTAG_SOURCEPACKAGE]:
		return True
	return False

def get_signature_key_id(h):
	key = h.format('%|DSAHEADER?{%{DSAHEADER:pgpsig}}:{%|RSAHEADER?{%{RSAHEADER:pgpsig}}:{%|SIGGPG?{%{SIGGPG:pgpsig}}:{%|SIGPGP?{%{SIGPGP:pgpsig}}:{}|}|}|}|')
	return re.sub(r'^.*Key ID \S{8}(\S{8})$', '\g<1>', key)

def get_nevra(h):
	if isinstance(h["name"], str):
		return "%s-%s-%s.%s" % (h["name"], h["version"], h["release"], h["arch"])
	else:
		nevra = b"%s-%s-%s.%s" % (h["name"], h["version"], h["release"], h["arch"])
		return nevra.decode("utf-8")

def get_checksum(h):
	checksum = h["SHA256HEADER"]
	if not checksum:
		checksum = h["SHA1HEADER"]
	if not checksum:
		return None
	if isinstance(checksum, str):
		return checksum
	else:
		return checksum.decode("utf-8")
