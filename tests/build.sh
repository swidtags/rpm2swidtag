#!/bin/bash

set -e
set -x

DNF=dnf
$DNF install -y rpm-build gcc make python3-lxml
make rpm
$DNF install -y dist/rpm2swidtag-*.noarch.rpm
