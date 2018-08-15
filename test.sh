#!/bin/bash

set -e
set -x

mkdir -p tmp

if ! [ -f tmp/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm ] || ! [ -f tmp/pkg1-1.2.0-1.fc28.src.rpm ] ; then
	rpmbuild -ba -D 'dist .fc28' -D "_sourcedir $(pwd)/tests/pkg1" -D "_srcrpmdir $(pwd)/tmp" -D "_rpmdir $(pwd)/tmp" tests/pkg1/pkg1.spec
fi
if ! [ -f tmp/x86_64/pkg2-0.0.1-1.git0f5628a6.fc28.x86_64.rpm ] || ! [ -f tmp/pkg2-0.0.1-1.git0f5628a6.fc28.src.rpm ] ; then
	rpmbuild -ba -D 'dist .fc28' -D "_srcrpmdir $(pwd)/tmp" -D "_rpmdir $(pwd)/tmp" tests/pkg2/pkg2.spec
fi

export PYTHONPATH=lib
# For testing, let's default the data location to the current directory
export RPM2SWIDTAG_TEMPLATE_DIR=.
bin/rpm2swidtag -p tmp/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm > tmp/pkg-generated.swidtag
diff tests/pkg1/pkg1-1.2.0-1.fc28.x86_64.swidtag tmp/pkg-generated.swidtag

bin/rpm2swidtag -p tmp/pkg1-1.2.0-1.fc28.src.rpm > tmp/pkg-generated-src.swidtag
diff tests/pkg1/pkg1-1.2.0-1.fc28.src.swidtag tmp/pkg-generated-src.swidtag

RPM2SWIDTAG_TEMPLATE=template-minimal.swidtag bin/rpm2swidtag -p tmp/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm > tmp/pkg-from-minimal.swidtag
diff tests/pkg1/pkg1-1.2.0-1.fc28.x86_64.swidtag.minimal tmp/pkg-from-minimal.swidtag

RPM2SWIDTAG_XSLT=tests/xslt/swidtag.xslt bin/rpm2swidtag -p tmp/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm > tmp/pkg-custom-tagid.swidtag
diff tests/pkg1/pkg1-1.2.0-1.fc28.x86_64.swidtag.custom-tagid tmp/pkg-custom-tagid.swidtag

bin/rpm2swidtag -p tmp/x86_64/pkg2-0.0.1-1.git0f5628a6.fc28.x86_64.rpm > tmp/pkg-generated-epoch.swidtag
diff tests/pkg2/pkg2-0.0.1-1.git0f5628a6.fc28.x86_64.swidtag tmp/pkg-generated-epoch.swidtag

rm -rf tmp/rpmdb
rpm --dbpath $(pwd)/tmp/rpmdb --justdb --nodeps -Uvh tmp/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm
rpm --dbpath $(pwd)/tmp/rpmdb -qa

_RPM2SWIDTAG_RPMDBPATH=$(pwd)/tmp/rpmdb bin/rpm2swidtag pkg1 > tmp/pkg-generated.swidtag
diff tests/pkg1/pkg1-1.2.0-1.fc28.x86_64.swidtag tmp/pkg-generated.swidtag

# Testing errors
set +e
OUT=$( bin/rpm2swidtag -p nonexistent 2>&1 )
ERR=$?
set -e
test "$ERR" -eq 3
test "$OUT" == 'bin/rpm2swidtag: Error reading rpm file [nonexistent]: No such file or directory'

set +e
OUT=$( bin/rpm2swidtag -p /dev/null 2>&1 )
ERR=$?
set -e
test "$ERR" -eq 3
test "$OUT" == 'bin/rpm2swidtag: Error reading rpm file [/dev/null]: error reading package header'

set +e
OUT=$( RPM2SWIDTAG_XSLT=nonexistent bin/rpm2swidtag -p tmp/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm 2>&1 )
ERR=$?
set -e
test "$ERR" -eq 5
test "$OUT" == 'bin/rpm2swidtag: Error reading processing XSLT file [nonexistent]: Error reading file '\''nonexistent'\'': failed to load external entity "nonexistent"'

set +e
OUT=$( RPM2SWIDTAG_XSLT=tests/xslt/swidtag-fail.xslt bin/rpm2swidtag -p tmp/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm 2>&1 )
ERR=$?
set -e
test "$ERR" -eq 6
test "$OUT" == 'bin/rpm2swidtag: Error generating SWID tag for file [tmp/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm]: Unknown header tag [broken] requested by XSLT stylesheet: unknown header tag'
