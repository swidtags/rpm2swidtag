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

# For testing, let's default the data location to the current directory
export RPM2SWIDTAG_TEMPLATE_DIR=.
./rpm2swidtag.py -p tmp/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm > tmp/pkg-generated.swidtag
diff tests/pkg1/pkg1-1.2.0-1.fc28.x86_64.swidtag tmp/pkg-generated.swidtag

./rpm2swidtag.py -p tmp/pkg1-1.2.0-1.fc28.src.rpm > tmp/pkg-generated-src.swidtag
diff tests/pkg1/pkg1-1.2.0-1.fc28.src.swidtag tmp/pkg-generated-src.swidtag

RPM2SWIDTAG_TEMPLATE=template-minimal.swidtag ./rpm2swidtag.py -p tmp/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm > tmp/pkg-from-minimal.swidtag
diff tests/pkg1/pkg1-1.2.0-1.fc28.x86_64.swidtag.minimal tmp/pkg-from-minimal.swidtag

RPM2SWIDTAG_XSLT=tests/xslt/swidtag.xslt ./rpm2swidtag.py -p tmp/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm > tmp/pkg-custom-tagid.swidtag
diff tests/pkg1/pkg1-1.2.0-1.fc28.x86_64.swidtag.custom-tagid tmp/pkg-custom-tagid.swidtag

./rpm2swidtag.py -p tmp/x86_64/pkg2-0.0.1-1.git0f5628a6.fc28.x86_64.rpm > tmp/pkg-generated-epoch.swidtag
diff tests/pkg2/pkg2-0.0.1-1.git0f5628a6.fc28.x86_64.swidtag tmp/pkg-generated-epoch.swidtag

rm -rf tmp/rpmdb
rpm --dbpath $(pwd)/tmp/rpmdb --justdb --nodeps -Uvh tmp/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm
rpm --dbpath $(pwd)/tmp/rpmdb -qa

_RPM2SWIDTAG_RPMDBPATH=$(pwd)/tmp/rpmdb ./rpm2swidtag.py pkg1 > tmp/pkg-generated.swidtag
diff tests/pkg1/pkg1-1.2.0-1.fc28.x86_64.swidtag tmp/pkg-generated.swidtag

# Testing errors
set +e
OUT=$( ./rpm2swidtag.py -p nonexistent 2>&1 )
ERR=$?
set -e
test "$ERR" -eq 3
test "$OUT" == './rpm2swidtag.py: Error reading [nonexistent]: No such file or directory'

set +e
OUT=$( ./rpm2swidtag.py -p /dev/null 2>&1 )
ERR=$?
set -e
test "$ERR" -eq 4
test "$OUT" == './rpm2swidtag.py: Error parsing rpm file [/dev/null]: error reading package header'

set +e
OUT=$( RPM2SWIDTAG_XSLT=nonexistent ./rpm2swidtag.py -p tmp/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm 2>&1 )
ERR=$?
set -e
test "$ERR" -eq 5
test "$OUT" == './rpm2swidtag.py: Error reading file '\''nonexistent'\'': failed to load external entity "nonexistent"'

set +e
OUT=$( RPM2SWIDTAG_XSLT=tests/xslt/swidtag-fail.xslt ./rpm2swidtag.py -p tmp/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm 2>&1 )
ERR=$?
set -e
test "$ERR" -eq 9
test "$OUT" == './rpm2swidtag.py: Error generating SWID tag: Unknown header tag [broken] requested by XSLT stylesheet: unknown header tag'
