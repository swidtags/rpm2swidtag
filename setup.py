#!/usr/bin/env python

try:
	from setuptools import setup
except ImportError:
	from distutils.core import setup

setup(
	name = 'rpm2swidtag',
	version = '0.4.0',
	description = 'Exploring the rpm header information and producing SWID tag out of it',
	author = 'Jan Pazdziora',
	license = 'Apache License 2.0',
	package_dir = {'': 'lib'},
	packages = ['rpm2swidtag'],
	scripts = ['bin/rpm2swidtag'],
	data_files = [('/etc/rpm2swidtag', ['template.swidtag', 'swidtag.xslt', 'rpm2swidtag.xslt', 'rpm2swidtag-tagid.xslt'])],
	install_requires = ['rpm', 'lxml'],
)
