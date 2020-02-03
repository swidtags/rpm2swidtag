#!/bin/bash

set -e
set -x

DNF=dnf
$DNF install -y rpm-build make "$DNF-command(builddep)"
test -f /etc/centos-release && $DNF install -y python3 epel-release
test -f /etc/centos-release && $DNF install -y --enablerepo=epel-testing fakechroot

make spec
$DNF builddep -y dist/rpm2swidtag.spec
make rpm
$DNF install -y dist/rpm2swidtag-*.noarch.rpm
