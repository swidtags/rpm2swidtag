
from os import open, O_RDONLY, close
import rpm
from rpm2swidtag import Error

def read_from_file(file):
	fdno = None
	try:
		fdno = open(file, O_RDONLY)
		ts = rpm.TransactionSet()
		h = ts.hdrFromFdno(fdno)
		return h
	except FileNotFoundError as e:
		raise Error("Error reading rpm file [%s]: %s" % (file, e.strerror))
	except rpm.error as e:
		raise Error("Error reading rpm file [%s]: %s" % (file, str(e)))
	finally:
		if fdno:
			close(fdno)

def read_from_db(package, rpmdb_path=None):
	if rpmdb_path is not None:
		rpm.addMacro('_dbpath', rpmdb_path)
	ts = rpm.TransactionSet()
	ts.openDB()
	if rpmdb_path is not None:
		rpm.delMacro('_dbpath')
	try:
		l = ts.dbMatch('name', package)
		return l
	except rpm.error as e:
		raise Error(str(e))

def is_source_package(h):
	if h[rpm.RPMTAG_SOURCEPACKAGE]:
		return True
	return False
