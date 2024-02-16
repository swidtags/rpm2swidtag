#!/bin/bash

set -e
set -x

export LC_ALL=C.utf8

DNF=dnf
$DNF install -y rpm-build make "$DNF-command(builddep)"

make spec
$DNF builddep -y dist/rpm2swidtag.spec
make rpm
$DNF install -y dist/rpm2swidtag-*.noarch.rpm
