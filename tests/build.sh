#!/bin/bash

set -e
set -x

export LC_ALL=C.utf8

DNF=dnf
test -f /etc/centos-release && $DNF install -y python3 epel-release
$DNF install -y rpm-build make "$DNF-command(builddep)" python3-setuptools

if grep -q 'CentOS Stream release 9' /etc/centos-release ; then
	rpm -Uvh https://kojipkgs.fedoraproject.org//packages/fakechroot/2.20.1/11.fc37/src/fakechroot-2.20.1-11.fc37.src.rpm
	$DNF builddep -y ~/rpmbuild/SPECS/fakechroot.spec
	rpmbuild -ba --nocheck ~/rpmbuild/SPECS/fakechroot.spec
	rpm -Uvh /root/rpmbuild/RPMS/*/fakechroot{,-libs}-2.20.1-11.el9.*.rpm
fi

make spec
$DNF builddep -y dist/rpm2swidtag.spec
make rpm
$DNF install -y dist/rpm2swidtag-*.noarch.rpm
