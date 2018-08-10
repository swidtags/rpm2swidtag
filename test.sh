#!/bin/bash

set -e
set -x

mkdir -p tmp

if ! [ -f tmp/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm ] || ! [ -f tmp/pkg1-1.2.0-1.fc28.src.rpm ] ; then
	rpmbuild -ba -D 'dist .fc28' -D "_sourcedir $(pwd)/tests/pkg1" -D "_srcrpmdir $(pwd)/tmp" -D "_rpmdir $(pwd)/tmp" tests/pkg1/pkg1.spec
fi

RPM2SWIDTAG_TEMPLATE_DIR=. ./rpm2swidtag.py -p tmp/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm > tmp/pkg-generated.swidtag
diff tests/pkg1/pkg1-1.2.0-1.fc28.x86_64.swidtag tmp/pkg-generated.swidtag

RPM2SWIDTAG_TEMPLATE_DIR=. ./rpm2swidtag.py -p tmp/pkg1-1.2.0-1.fc28.src.rpm > tmp/pkg-generated-src.swidtag
diff tests/pkg1/pkg1-1.2.0-1.fc28.src.swidtag tmp/pkg-generated-src.swidtag

RPM2SWIDTAG_TEMPLATE_DIR=. RPM2SWIDTAG_TEMPLATE=template-minimal.swidtag ./rpm2swidtag.py -p tmp/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm > tmp/pkg-from-minimal.swidtag
diff tests/pkg1/pkg1-1.2.0-1.fc28.x86_64.swidtag.minimal tmp/pkg-from-minimal.swidtag

rm -rf tmp/rpmdb
rpm --dbpath $(pwd)/tmp/rpmdb --justdb --nodeps -Uvh tmp/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm
rpm --dbpath $(pwd)/tmp/rpmdb -qa

RPM2SWIDTAG_TEMPLATE_DIR=. _RPM2SWIDTAG_RPMDBPATH=$(pwd)/tmp/rpmdb ./rpm2swidtag.py pkg1 > tmp/pkg-generated.swidtag
diff tests/pkg1/pkg1-1.2.0-1.fc28.x86_64.swidtag tmp/pkg-generated.swidtag
