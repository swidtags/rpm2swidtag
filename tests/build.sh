#!/bin/bash

set -e
set -x

DNF=dnf
$DNF install -y rpm-build make "$DNF-command(builddep)"
test -f /etc/centos-release && $DNF install -y python3 epel-release https://kojipkgs.fedoraproject.org//packages/fakechroot/2.20.1/2.el8/x86_64/fakechroot-{,libs-}2.20.1-2.el8.x86_64.rpm
test -f /etc/centos-release && $DNF install -y --enablerepo=epel-testing python3-astroid

make spec
$DNF builddep -y dist/rpm2swidtag.spec
make rpm
$DNF install -y dist/rpm2swidtag-*.noarch.rpm
