#!/usr/bin/env python

try:
	from setuptools import setup
except ImportError:
	from distutils.core import setup

setup(
	name = 'rpm2swidtag',
	version = '0.5.4',
	description = 'Tools for producing SWID tags from rpm package headers and inspecting the SWID tags',
	author = 'Jan Pazdziora',
	license = 'Apache License 2.0',
	package_dir = {'': 'lib'},
	packages = ['rpm2swidtag', 'swidq'],
	scripts = ['bin/rpm2swidtag', 'bin/swidq'],
	data_files = [
		('/etc/rpm2swidtag', ['rpm2swidtag.conf', 'template.swidtag', 'swidtag.xslt', 'rpm2swidtag.xslt', 'rpm2swidtag-tagid.xslt']),
		('/etc/swid', ['swidq.conf']),
		('/etc/swid/swidtags.d', []),
		('/usr/share/swidq/stylesheets', ['swidq-info.xslt', 'swidq-dump.xslt', 'swidq-files.xslt']),
	],
	install_requires = ['rpm', 'lxml'],
)
