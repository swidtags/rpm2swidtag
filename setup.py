#!/usr/bin/env python

from distutils.core import setup

setup(
	name = 'rpm2swidtag',
	version = '0.1.0',
	description = 'Exploring the rpm header information and producing SWID tag out of it',
	author = 'Jan Pazdziora',
	license = 'Apache License 2.0',
	py_modules = ['rpm2swidtag'],
	data_files = [('/etc/rpm2swidtag', ['template.swidtag', 'swidtag.xslt'])],
)
