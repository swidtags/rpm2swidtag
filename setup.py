#!/usr/bin/env python

try:
	from setuptools import setup
except ImportError:
	from distutils.core import setup

setup(
	name = 'rpm2swidtag',
	version = '0.6.1',
	description = 'Tools for producing SWID tags from rpm package headers and inspecting the SWID tags',
	author = 'Jan Pazdziora',
	author_email = 'jpazdziora@redhat.com',
	license = 'Apache License 2.0',
	package_dir = {'': 'lib'},
	packages = ['rpm2swidtag', 'swidq'],
	py_modules = ['dnf-plugins.rpm2swidtag'],
	scripts = ['bin/rpm2swidtag', 'bin/swidq'],
	data_files = [
		('/etc/rpm2swidtag', ['rpm2swidtag.conf', 'swidtag-template.xml', 'swidtag.xslt', 'rpm2swidtag.xslt', 'rpm2swidtag-tagid.xslt']),
		('/etc/rpm2swidtag/rpm2swidtag.conf.d', ['rpm2swidtag.conf.d/fedora-rawhide.conf', 'rpm2swidtag.conf.d/fedora-29.conf', 'rpm2swidtag.conf.d/fedora-28.conf']),
		('/etc/swid', ['swidq.conf']),
		('/etc/swid/swidtags.d', []),
		('/usr/share/swidq/stylesheets', ['swidq-info.xslt', 'swidq-dump.xslt', 'swidq-files.xslt', 'swidq-xml.xslt']),
		('/etc/dnf/plugins', ['dnf/plugins/rpm2swidtag.conf']),
	],
	install_requires = ['rpm', 'lxml'],
)
