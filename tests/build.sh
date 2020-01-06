#!/bin/bash

set -e
set -x

DNF=dnf
$DNF install -y rpm-build make "$DNF-command(builddep)"
# Workaround 1788084
grep 'Fedora release 31' /etc/fedora-release && $DNF install -y 'python3-astroid <> 2.3.3-2.gitace7b29.fc31'
make spec
$DNF builddep -y dist/rpm2swidtag.spec
make rpm
$DNF install -y dist/rpm2swidtag-*.noarch.rpm
