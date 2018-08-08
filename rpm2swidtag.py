#!/usr/bin/python3

from sys import argv, exit, stderr
from os import open, O_RDONLY, close
import rpm

if len(argv) < 2:
	stderr.write("Usage: %s file.rpm\n" % (argv[0]))
	exit(2)

try:
	fdno = open(argv[1], O_RDONLY)
except FileNotFoundError as e:
	stderr.write("%s: Error reading [%s]: %s\n" % (argv[0], argv[1], e.strerror))
	exit(3)

ts = rpm.TransactionSet()
try:
	h = ts.hdrFromFdno(fdno)
except rpm.error as e:
	stderr.write("%s: Error parsing rpm file [%s]: %s\n" % (argv[0], argv[1], str(e)))
	exit(4)

close(fdno)

print("{0}-{1}-{2}.{3}".format(*map(lambda x: x.decode(), (h['name'], h['version'], h['release'], h['arch']))))

