#!/usr/bin/env python

from setuptools import setup

setup(
	name = 'rpm2swidtag',
	version = '0.8.16',
	description = 'Tools for producing SWID tags from rpm package headers and inspecting the SWID tags',
	author = 'Jan Pazdziora',
	author_email = 'jpazdziora@redhat.com',
	license = 'ASL 2.0',
	classifiers=[
		'Development Status :: 4 - Beta',
		'Environment :: Console',
		'Environment :: Plugins',
		'Intended Audience :: System Administrators',
		'Intended Audience :: Developers',
		'Intended Audience :: Information Technology',
		'License :: OSI Approved :: Apache Software License',
		'Operating System :: POSIX',
		'Operating System :: POSIX :: Linux',
		'Programming Language :: Python :: 3',
		'Topic :: Security',
		'Topic :: Software Development :: Build Tools',
		'Topic :: System :: Systems Administration',
	],
	package_dir = {'': 'lib'},
	packages = ['rpm2swidtag', 'swidq'],
	py_modules = ['dnf-plugins.swidtags'],
	scripts = ['bin/rpm2swidtag', 'bin/dnf-plugin-swidtags-update-from-0.7', 'bin/swidq'],
	data_files = [
		('/etc/rpm2swidtag', ['rpm2swidtag.conf', 'swidtag-template.xml', 'swidtag.xslt', 'rpm2swidtag.xslt', 'rpm2swidtag-tagid.xslt']),
		('/etc/rpm2swidtag/rpm2swidtag.conf.d', ['rpm2swidtag.conf.d/fedora-rawhide.conf', 'rpm2swidtag.conf.d/fedora-37.conf', 'rpm2swidtag.conf.d/fedora-36.conf', 'rpm2swidtag.conf.d/fedora-35.conf', 'rpm2swidtag.conf.d/fedora-34.conf']),
		('/etc/swid', ['swidq.conf']),
		('/etc/swid/swidtags.d', []),
		('/usr/share/swidq/stylesheets', ['swidq-info.xslt', 'swidq-dump.xslt', 'swidq-files.xslt', 'swidq-xml.xslt']),
		('/etc/dnf/plugins', ['dnf/plugins/swidtags.conf']),
	],
	install_requires = ['rpm', 'lxml'],
)
