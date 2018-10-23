#!/bin/bash

set -e
set -x

mkdir -p tmp

if ! [ -f tmp/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm ] || ! [ -f tmp/pkg1-1.2.0-1.fc28.src.rpm ] ; then
	rpmbuild -ba -D 'dist .fc28' -D "_sourcedir $(pwd)/tests/pkg1" -D "_srcrpmdir $(pwd)/tmp" -D "_rpmdir $(pwd)/tmp" tests/pkg1/pkg1-1.2.0.spec
fi
if ! [ -f tmp/x86_64/pkg1-1.3.0-1.fc28.x86_64.rpm ] || ! [ -f tmp/pkg1-1.3.0-1.fc28.src.rpm ] ; then
	rpmbuild -ba -D 'dist .fc28' -D "_sourcedir $(pwd)/tests/pkg1" -D "_srcrpmdir $(pwd)/tmp" -D "_rpmdir $(pwd)/tmp" tests/pkg1/pkg1-1.3.0.spec
	rpmsign --addsign --key-id=19D5C7DD -D '_gpg_path tests/gnupg' ./tmp/x86_64/pkg1-1.3.0-1.fc28.x86_64.rpm
fi
if ! [ -f tmp/x86_64/pkg2-0.0.1-1.git0f5628a6.fc28.x86_64.rpm ] || ! [ -f tmp/pkg2-0.0.1-1.git0f5628a6.fc28.src.rpm ] ; then
	rpmbuild -ba -D 'dist .fc28' -D "_srcrpmdir $(pwd)/tmp" -D "_rpmdir $(pwd)/tmp" tests/pkg2/pkg2.spec
fi

function normalize() {
	sed 's/<Evidence date="[^"]*Z" deviceId="[^"]*"/<Evidence date="2018-01-01T12:13:14Z" deviceId="machine.example.test"/'
}
function normalize_i() {
	sed -i 's/<Evidence date="[^"]*Z" deviceId="[^"]*"/<Evidence date="2018-01-01T12:13:14Z" deviceId="machine.example.test"/' "$*"
}

export PYTHONPATH=lib

# Testing rpm2swidtag
# For testing, let's default the data location to the current directory
bin/rpm2swidtag --config=tests/rpm2swidtag.conf -p tmp/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm | normalize > tmp/pkg-generated.swidtag
diff tests/pkg1/pkg1-1.2.0-1.fc28.x86_64.swidtag tmp/pkg-generated.swidtag

bin/rpm2swidtag --config=$(pwd)/tests/rpm2swidtag.conf --authoritative -p tmp/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm > tmp/pkg-generated.swidtag
diff tests/pkg1/pkg1-1.2.0-1.fc28.x86_64.auth.swidtag tmp/pkg-generated.swidtag

bin/rpm2swidtag --config=./tests/rpm2swidtag.conf --evidence-deviceid specific.machine.example.test -p tmp/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm | sed 's/<Evidence date="[^"]*Z"/<Evidence date="2018-01-01T12:13:14Z"/' > tmp/pkg-generated.swidtag
diff tests/pkg1/pkg1-1.2.0-1.fc28.x86_64.deviceid.swidtag tmp/pkg-generated.swidtag

bin/rpm2swidtag --config=tests/rpm2swidtag.conf -p --regid=example.test tmp/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm | normalize > tmp/pkg-generated-regid.swidtag
diff tests/pkg1/pkg1-1.2.0-1.fc28.x86_64.swidtag.regid tmp/pkg-generated-regid.swidtag

bin/rpm2swidtag --config=tests/rpm2swidtag.conf -p tmp/pkg1-1.2.0-1.fc28.src.rpm | normalize > tmp/pkg-generated-src.swidtag
diff tests/pkg1/pkg1-1.2.0-1.fc28.src.swidtag tmp/pkg-generated-src.swidtag

bin/rpm2swidtag --config=tests/rpm2swidtag.conf -p tests/hello-rpm/hello-1.0-1.i386.rpm | normalize > tmp/pkg-generated-src.swidtag
diff tests/hello-rpm/hello-1.0-1.i386.swidtag tmp/pkg-generated-src.swidtag

bin/rpm2swidtag --config=tests/rpm2swidtag.conf -p tests/hello-rpm/hello-2.0-1.x86_64-signed.rpm | normalize > tmp/pkg-generated-src.swidtag
diff tests/hello-rpm/hello-2.0-1.x86_64-signed.swidtag tmp/pkg-generated-src.swidtag

bin/rpm2swidtag --config=tests/rpm2swidtag.conf -p tmp/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm --software-creator-from tests/swiddata1/a.test/distro.swidtag | normalize > tmp/pkg-generated.swidtag
diff tests/pkg1/pkg1-1.2.0-1.fc28.x86_64.swidtag.software-creator-from tmp/pkg-generated.swidtag

RPM2SWIDTAG_TEMPLATE=template-minimal.swidtag bin/rpm2swidtag --config=tests/rpm2swidtag.conf -p tmp/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm | normalize > tmp/pkg-from-minimal.swidtag
diff tests/pkg1/pkg1-1.2.0-1.fc28.x86_64.swidtag.minimal tmp/pkg-from-minimal.swidtag

RPM2SWIDTAG_XSLT=tests/xslt/swidtag.xslt bin/rpm2swidtag --config=tests/rpm2swidtag.conf -p tmp/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm | normalize > tmp/pkg-custom-tagid.swidtag
diff tests/pkg1/pkg1-1.2.0-1.fc28.x86_64.swidtag.custom-tagid tmp/pkg-custom-tagid.swidtag

bin/rpm2swidtag --config=tests/rpm2swidtag.conf -p tmp/x86_64/pkg2-0.0.1-1.git0f5628a6.fc28.x86_64.rpm | normalize > tmp/pkg-generated-epoch.swidtag
diff tests/pkg2/pkg2-13:0.0.1-1.git0f5628a6.fc28.x86_64.swidtag tmp/pkg-generated-epoch.swidtag

rm -rf tmp/rpmdb
rpm --dbpath $(pwd)/tmp/rpmdb --justdb --nodeps -iv tmp/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm
rpm --dbpath $(pwd)/tmp/rpmdb --justdb --nodeps -iv tmp/x86_64/pkg1-1.3.0-1.fc28.x86_64.rpm
rpm --dbpath $(pwd)/tmp/rpmdb --justdb --nodeps -iv tmp/x86_64/pkg2-0.0.1-1.git0f5628a6.fc28.x86_64.rpm
rpm --dbpath $(pwd)/tmp/rpmdb -qa

_RPM2SWIDTAG_RPMDBPATH=$(pwd)/tmp/rpmdb bin/rpm2swidtag --config=tests/rpm2swidtag.conf pkg1-1.3.0 | normalize > tmp/pkg-generated.swidtag
cat tests/pkg1/pkg1-1.3.0-1.fc28.x86_64.swidtag tests/pkg1/pkg1-1.3.0-1.fc28.x86_64.swidtag.supplemental-component-of-distro > tmp/pkg1-1.3.0.swidtag.with-supplemental
diff tmp/pkg1-1.3.0.swidtag.with-supplemental tmp/pkg-generated.swidtag

_RPM2SWIDTAG_RPMDBPATH=$(pwd)/tmp/rpmdb bin/rpm2swidtag --config=tests/rpm2swidtag.conf --primary-only pkg1-1.3.0 | normalize > tmp/pkg-generated.swidtag
diff tests/pkg1/pkg1-1.3.0-1.fc28.x86_64.swidtag tmp/pkg-generated.swidtag

_RPM2SWIDTAG_RPMDBPATH=$(pwd)/tmp/rpmdb bin/rpm2swidtag --config=tests/rpm2swidtag.conf pkg1 | normalize > tmp/pkg-generated.swidtag
cat tests/pkg1/pkg1-1.2.0-1.fc28.x86_64.swidtag tests/pkg1/pkg1-1.3.0-1.fc28.x86_64.swidtag tests/pkg1/pkg1-1.3.0-1.fc28.x86_64.swidtag.supplemental-component-of-distro > tmp/pkg1-1.2.0-and-1.3.0.swidtag
diff tmp/pkg1-1.2.0-and-1.3.0.swidtag tmp/pkg-generated.swidtag

_RPM2SWIDTAG_RPMDBPATH=$(pwd)/tmp/rpmdb bin/rpm2swidtag --config=tests/rpm2swidtag.conf -a 'pkg*' | normalize > tmp/pkg-generated.swidtag
cat tmp/pkg1-1.2.0-and-1.3.0.swidtag tests/pkg2/pkg2-13:0.0.1-1.git0f5628a6.fc28.x86_64.swidtag > tmp/pkg1-and-pkg2.swidtag
diff tmp/pkg1-and-pkg2.swidtag tmp/pkg-generated.swidtag

_RPM2SWIDTAG_RPMDBPATH=$(pwd)/tmp/rpmdb bin/rpm2swidtag --config=tests/rpm2swidtag.conf -a | normalize > tmp/pkg-generated.swidtag
diff tmp/pkg1-and-pkg2.swidtag tmp/pkg-generated.swidtag

rm -rf tmp/output-dir tmp/compare-dir
_RPM2SWIDTAG_RPMDBPATH=$(pwd)/tmp/rpmdb bin/rpm2swidtag --config=tests/rpm2swidtag.conf --regid=example.test --output-dir=tmp/output-dir -a
find tmp/output-dir -type f | while read f ; do normalize_i $f ; done
mkdir -p tmp/compare-dir/example.test
for i in pkg1-1.2.0-1.fc28.x86_64 pkg1-1.3.0-1.fc28.x86_64 pkg2-13:0.0.1-1.git0f5628a6.fc28.x86_64 ; do
	sed 's/unavailable.invalid/test.example/;s/invalid.unavailable/example.test/' tests/${i%%-*}/$i.swidtag > tmp/compare-dir/example.test/test.example.$i.swidtag
done
sed 's/unavailable.invalid/test.example/;s/invalid.unavailable/example.test/' tests/pkg1/pkg1-1.3.0-1.fc28.x86_64.swidtag.supplemental-component-of-distro > tmp/compare-dir/example.test/test.example.pkg1-1.3.0-1.fc28.x86_64-component-of-test.a.Example-OS-Distro-3.x86_64.swidtag
diff -ru tmp/output-dir tmp/compare-dir

rm -rf tmp/output-dir
_RPM2SWIDTAG_RPMDBPATH=$(pwd)/tmp/rpmdb bin/rpm2swidtag --config=tests/rpm2swidtag.conf --regid=example.test --output-dir=tmp/output-dir/. -a
find tmp/output-dir -type f | while read f ; do normalize_i $f ; done
mv tmp/compare-dir/example.test/* tmp/compare-dir
rmdir tmp/compare-dir/example.test
diff -ru tmp/output-dir tmp/compare-dir

OUT=$( _RPM2SWIDTAG_RPMDBPATH=$(pwd)/tmp/rpmdb bin/rpm2swidtag --config=tests/rpm2swidtag.conf --print-tagid pkg1 )
test "$OUT" == "$( echo -e 'unavailable.invalid.pkg1-1.2.0-1.fc28.x86_64\nunavailable.invalid.pkg1-1.3.0-1.fc28.x86_64\n+ unavailable.invalid.pkg1-1.3.0-1.fc28.x86_64-component-of-test.a.Example-OS-Distro-3.x86_64' )"

# Testing errors
set +e
OUT=$( bin/rpm2swidtag --config=tests/rpm2swidtag.conf -p nonexistent 2>&1 )
ERR=$?
set -e
test "$ERR" -eq 3
test "$OUT" == 'bin/rpm2swidtag: Error reading rpm file [nonexistent]: No such file or directory'

set +e
OUT=$( bin/rpm2swidtag --config=tests/rpm2swidtag.conf -p /dev/null 2>&1 )
ERR=$?
set -e
test "$ERR" -eq 3
test "$OUT" == 'bin/rpm2swidtag: Error reading rpm file [/dev/null]: error reading package header'

set +e
OUT=$( RPM2SWIDTAG_XSLT=nonexistent bin/rpm2swidtag --config=tests/rpm2swidtag.conf -p tmp/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm 2>&1 )
ERR=$?
set -e
test "$ERR" -eq 5
test "$OUT" == 'bin/rpm2swidtag: Error reading processing XSLT file [nonexistent]: Error reading file '\''nonexistent'\'': failed to load external entity "nonexistent"'

set +e
OUT=$( RPM2SWIDTAG_XSLT=tests/xslt/swidtag-fail.xslt bin/rpm2swidtag --config=tests/rpm2swidtag.conf -p tmp/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm 2>&1 )
ERR=$?
set -e
test "$ERR" -eq 6
test "$OUT" == 'bin/rpm2swidtag: Error generating SWID tag for file [tmp/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm]: Unknown header tag [broken] requested by XSLT stylesheet: unknown header tag'

set +e
OUT=$( _RPM2SWIDTAG_RPMDBPATH=$(pwd)/tmp/rpmdb bin/rpm2swidtag --config=tests/rpm2swidtag.conf x 2>&1 )
ERR=$?
set -e
test "$ERR" -eq 7
test "$OUT" == 'bin/rpm2swidtag: No package [x] found in database'

set +e
OUT=$( _RPM2SWIDTAG_RPMDBPATH=$(pwd)/tmp/rpmdb bin/rpm2swidtag --config=tests/rpm2swidtag.conf 'pkg*' 2>&1 )
ERR=$?
set -e
test "$ERR" -eq 7
test "$OUT" == 'bin/rpm2swidtag: No package [pkg*] found in database'

set +e
OUT=$( _RPM2SWIDTAG_RPMDBPATH=$(pwd)/tmp/rpmdb bin/rpm2swidtag --config=tests/rpm2swidtag.conf -a 'x*' 2>&1 )
ERR=$?
set -e
test "$ERR" -eq 7
test "$OUT" == 'bin/rpm2swidtag: No package [x*] found in database'

set +e
OUT=$( _RPM2SWIDTAG_RPMDBPATH=$(pwd)/tmp/rpmdb bin/rpm2swidtag --config=tests/rpm2swidtag.conf pkg1 x pkg2 2>&1 > /tmp/pkg-generated.swidtag )
ERR=$?
set -e
test "$ERR" -eq 7
normalize_i /tmp/pkg-generated.swidtag
test "$OUT" == 'bin/rpm2swidtag: No package [x] found in database'
diff tmp/pkg1-and-pkg2.swidtag /tmp/pkg-generated.swidtag

# Test that README has up-to-date usage section
diff -u <( bin/rpm2swidtag -h ) <( sed -n '/^usage: rpm2swidtag/,/```/{/```/T;p}' README.md )


# Testing swidq
bin/swidq -p tests/swiddata1/a.test/pkg1-1.2.0-1.fc28.x86_64.swidtag > tmp/swidq.out 2> tmp/swidq.err
diff <( echo 'unavailable.invalid.pkg1-1.2.0-1.fc28.x86_64 tests/swiddata1/a.test/pkg1-1.2.0-1.fc28.x86_64.swidtag' ) tmp/swidq.out
diff /dev/null tmp/swidq.err

bin/swidq -c swidq.conf -p tests/swiddata1/a.test/pkg1-1.2.0-1.fc28.x86_64.swidtag --debug > tmp/swidq.out 2> tmp/swidq.err
diff <( echo 'unavailable.invalid.pkg1-1.2.0-1.fc28.x86_64 tests/swiddata1/a.test/pkg1-1.2.0-1.fc28.x86_64.swidtag' ) tmp/swidq.out
diff tests/swiddata1/a.test/pkg1-1.2.0-1.fc28.x86_64.debug tmp/swidq.err

bin/swidq --silent -p - < tests/swiddata1/a.test/pkg1-1.2.0-1.fc28.x86_64.swidtag > tmp/swidq.out 2> tmp/swidq.err
diff <( echo 'unavailable.invalid.pkg1-1.2.0-1.fc28.x86_64 -' ) tmp/swidq.out
diff /dev/null tmp/swidq.err

bin/swidq -p tests/swiddata1/*/*.swidtag > tmp/swidq.out 2> tmp/swidq.err
diff tests/swidq-swiddata1.out tmp/swidq.out
diff /dev/null tmp/swidq.err

bin/swidq -p 'tests/swiddata1/*' > tmp/swidq.out 2> tmp/swidq.err
diff tests/swidq-swiddata1.out tmp/swidq.out
diff /dev/null tmp/swidq.err

bin/swidq -p tests/swiddata1/*/*.swidtag tests/swiddata1/*/*.swidtag --silent > tmp/swidq.out 2> tmp/swidq.err
diff <( cat tests/swidq-swiddata1.out ) tmp/swidq.out
diff /dev/null tmp/swidq.err

bin/swidq -c tests/swidq.conf --silent > tmp/swidq.out 2> tmp/swidq.err
diff /dev/null tmp/swidq.out
diff /dev/null tmp/swidq.err

bin/swidq --silent -c tests/swidq.conf -a > tmp/swidq.out 2> tmp/swidq.err
diff tests/swidq-swiddata1-swiddata2.out tmp/swidq.out
diff /dev/null tmp/swidq.err

bin/swidq -c tests/swidq.conf unavailable.invalid.pkg1-1.2.0-1.fc28.x86_64 --silent > tmp/swidq.out 2> tmp/swidq.err
diff <( echo 'unavailable.invalid.pkg1-1.2.0-1.fc28.x86_64 tests/swiddata1/a.test/pkg1-1.2.0-1.fc28.x86_64.swidtag' ) tmp/swidq.out
diff /dev/null tmp/swidq.err

bin/swidq -c tests/swidq.conf -a unavailable.invalid.pkg1-1.2.0-1.fc28.x86_64 --silent > tmp/swidq.out 2> tmp/swidq.err
diff <( echo 'unavailable.invalid.pkg1-1.2.0-1.fc28.x86_64 tests/swiddata1/a.test/pkg1-1.2.0-1.fc28.x86_64.swidtag' ) tmp/swidq.out
diff /dev/null tmp/swidq.err

bin/swidq --silent -c tests/swidq.conf -a '*pkg1*' > tmp/swidq.out 2> tmp/swidq.err
diff <( echo 'unavailable.invalid.pkg1-1.2.0-1.fc28.x86_64 tests/swiddata1/a.test/pkg1-1.2.0-1.fc28.x86_64.swidtag' ) tmp/swidq.out
diff /dev/null tmp/swidq.err

bin/swidq --silent -c tests/swidq.conf -a '*pkg1*' '*pkg5*' > tmp/swidq.out 2> tmp/swidq.err
diff <( echo 'unavailable.invalid.pkg1-1.2.0-1.fc28.x86_64 tests/swiddata1/a.test/pkg1-1.2.0-1.fc28.x86_64.swidtag' ) tmp/swidq.out
diff /dev/null tmp/swidq.err

bin/swidq --silent -c tests/swidq.conf unknown.tagid > tmp/swidq.out 2> tmp/swidq.err
diff /dev/null tmp/swidq.out
diff /dev/null tmp/swidq.err

bin/swidq --silent -c tests/swidq.conf -n 'qkg1' > tmp/swidq.out 2> tmp/swidq.err
diff <( echo 'test.a.qkg1-1.0.0-1.x86_64 tests/swiddata1/a.test/qkg1.swidtag' ) tmp/swidq.out
diff /dev/null tmp/swidq.err

bin/swidq --silent -c tests/swidq.conf -n 'qkg1' pkg1 > tmp/swidq.out 2> tmp/swidq.err
diff <( echo 'unavailable.invalid.pkg1-1.2.0-1.fc28.x86_64 tests/swiddata1/a.test/pkg1-1.2.0-1.fc28.x86_64.swidtag' ; echo 'test.a.qkg1-1.0.0-1.x86_64 tests/swiddata1/a.test/qkg1.swidtag' ) tmp/swidq.out
diff /dev/null tmp/swidq.err

bin/swidq --silent -c tests/swidq.conf -a -n 'qkg*' 'p?g1' > tmp/swidq.out 2> tmp/swidq.err
diff <( echo 'unavailable.invalid.pkg1-1.2.0-1.fc28.x86_64 tests/swiddata1/a.test/pkg1-1.2.0-1.fc28.x86_64.swidtag' ; echo 'test.a.qkg1-1.0.0-1.x86_64 tests/swiddata1/a.test/qkg1.swidtag' ) tmp/swidq.out
diff /dev/null tmp/swidq.err

bin/swidq --silent -c tests/swidq.conf -n qkg2 > tmp/swidq.out 2> tmp/swidq.err
diff /dev/null tmp/swidq.out
diff /dev/null tmp/swidq.err

bin/swidq -p tests/swiddata1/a.test/pkg3.swidtag tests/swiddata2/pkg3.swidtag > tmp/swidq.out 2> tmp/swidq.err
diff <( echo 'test.a.pkg3-1.0.0-1.x86_64 tests/swiddata2/pkg3.swidtag' ) tmp/swidq.out
diff <( echo 'bin/swidq: [tests/swiddata2/pkg3.swidtag] overriding previous file [tests/swiddata1/a.test/pkg3.swidtag] which had lower tagVersion [0]' ) tmp/swidq.err

bin/swidq -p tests/swiddata2/pkg3.swidtag tests/swiddata1/a.test/pkg3.swidtag > tmp/swidq.out 2> tmp/swidq.err
diff <( echo 'test.a.pkg3-1.0.0-1.x86_64 tests/swiddata2/pkg3.swidtag' ) tmp/swidq.out
diff <( echo 'bin/swidq: skipping [tests/swiddata1/a.test/pkg3.swidtag] as existing file [tests/swiddata2/pkg3.swidtag] has already tagVersion [10]' ) tmp/swidq.err

bin/swidq -p $( find tests/swiddata[12] -name '*distro*.swidtag' ) tests/swiddata2/missing-tag-supplemental.swidtag > tmp/swidq.out 2> tmp/swidq.err
diff <( echo 'test.a.Example-OS-Distro-3.x86_64 tests/swiddata1/a.test/distro.swidtag' ;
	echo '+ test.a.Example-OS-Distro-3.14.x86_64 tests/swiddata2/distro-minor-supplemental.swidtag' ;
	echo '! test.a.Example-OS-Distro-3.14.x86_64-sup2 tests/swiddata2/distro-minor-supplemental-2.swidtag' ;
	echo '- test.a.Example-OS-Distro-3.15.x86_64 tests/swiddata2/missing-tag-supplemental.swidtag' ) tmp/swidq.out
diff <( echo 'bin/swidq: [test.a.Example-OS-Distro-3.15.x86_64] supplements [swid:test.example.missing.Example-OS-Distro-3.x86_64] which we do not know' ) tmp/swidq.err

bin/swidq -p tests/swiddata2/distro-minor-supplemental.swidtag > tmp/swidq.out 2> tmp/swidq.err
diff <( echo '- test.a.Example-OS-Distro-3.14.x86_64 tests/swiddata2/distro-minor-supplemental.swidtag' ) tmp/swidq.out
diff <( echo 'bin/swidq: [test.a.Example-OS-Distro-3.14.x86_64] supplements [swid:test.a.Example-OS-Distro-3.x86_64] which we do not know' ) tmp/swidq.err

export SWIDQ_STYLESHEET_DIR=.
bin/swidq --dump -p tests/swiddata1/a.test/pkg1-1.2.0-1.fc28.x86_64.swidtag > tmp/swidq.out 2> tmp/swidq.err
diff tests/swiddata1/a.test/pkg1-1.2.0-1.fc28.x86_64.dump tmp/swidq.out
diff /dev/null tmp/swidq.err

bin/swidq -i -p tests/swiddata1/a.test/pkg1-1.2.0-1.fc28.x86_64.swidtag > tmp/swidq.out 2> tmp/swidq.err
diff tests/swiddata1/a.test/pkg1-1.2.0-1.fc28.x86_64.info tmp/swidq.out
diff /dev/null tmp/swidq.err

bin/swidq -il -p tests/swiddata1/a.test/pkg1-1.2.0-1.fc28.x86_64.swidtag > tmp/swidq.out 2> tmp/swidq.err
diff <( cat tests/swiddata1/a.test/pkg1-1.2.0-1.fc28.x86_64.{info,files} ) tmp/swidq.out
diff /dev/null tmp/swidq.err

bin/swidq --silent -c tests/swidq.conf -l -n pkg1 > tmp/swidq.out 2> tmp/swidq.err
diff tests/swiddata1/a.test/pkg1-1.2.0-1.fc28.x86_64.files tmp/swidq.out
diff /dev/null tmp/swidq.err

bin/swidq -p -i tests/swiddata1/a.test/distro.swidtag > tmp/swidq.out 2> tmp/swidq.err
diff tests/swiddata1/a.test/distro.info tmp/swidq.out
diff /dev/null tmp/swidq.err

bin/swidq -p -i tests/swiddata2/distro-minor-supplemental.swidtag > tmp/swidq.out 2> tmp/swidq.err
diff tests/swiddata2/distro-minor-supplemental.info tmp/swidq.out
diff <( echo 'bin/swidq: [test.a.Example-OS-Distro-3.14.x86_64] supplements [swid:test.a.Example-OS-Distro-3.x86_64] which we do not know' ) tmp/swidq.err

bin/swidq --silent -c tests/swidq.conf --rpm pkg3-1.0.0-1.x86_64 > tmp/swidq.out 2> tmp/swidq.err
diff <( echo 'test.a.pkg3-1.0.0-1.x86_64 tests/swiddata2/pkg3.swidtag' ;
	echo "test.b.pkg3-1.0.0-1.x86_64 tests/swiddata3/b.test/pkg3.swidtag" ) tmp/swidq.out
diff /dev/null tmp/swidq.err

bin/swidq --silent -c tests/swidq.conf --rpm -a > tmp/swidq.out 2> tmp/swidq.err
diff <( echo 'unavailable.invalid.pkg1-1.2.0-1.fc28.x86_64 tests/swiddata1/a.test/pkg1-1.2.0-1.fc28.x86_64.swidtag' ;
	echo 'test.a.pkg3-1.0.0-1.x86_64 tests/swiddata2/pkg3.swidtag' ;
	echo "test.b.pkg3-1.0.0-1.x86_64 tests/swiddata3/b.test/pkg3.swidtag" ) tmp/swidq.out
diff /dev/null tmp/swidq.err

bin/swidq --xml -p tests/pkg1/pkg1-1.2.0-1.fc28.x86_64.auth.xmlns.swidtag > tmp/swidq.out 2> tmp/swidq.err
diff tests/pkg1/pkg1-1.2.0-1.fc28.x86_64.auth.swidtag tmp/swidq.out
diff /dev/null tmp/swidq.err

rm -f tmp/stylesheet.xslt
ln -s ../swidq-dump.xslt tmp/stylesheet.xslt
(
unset SWIDQ_STYLESHEET_DIR
bin/swidq --output-stylesheet=tmp/stylesheet.xslt -p tests/swiddata1/a.test/pkg1-1.2.0-1.fc28.x86_64.swidtag > tmp/swidq.out 2> tmp/swidq.err
diff tests/swiddata1/a.test/pkg1-1.2.0-1.fc28.x86_64.dump tmp/swidq.out
diff /dev/null tmp/swidq.err
)

# Testing errors
set +e
OUT=$( bin/swidq -p nonexistent 2>&1 )
ERR=$?
set -e
test "$ERR" -eq 1
test "$OUT" == 'bin/swidq: no file matching [nonexistent]'

# Test that README has up-to-date usage section
diff -u <( bin/swidq -h ) <( sed -n '/^usage: swidq/,/```/{/```/T;p}' README.md )


# rpm2swidtag to swidq
find . -name '*.rpm' | while read f ; do
	diff -u <( rpm -qlp $f | grep -v '^(contains no files)' ) <( bin/rpm2swidtag --config=tests/rpm2swidtag.conf --primary-only -p $f | bin/swidq -p - -l )
done

if rpm -q bash ; then
	diff -u <( rpm -ql bash ) <( bin/rpm2swidtag --config=tests/rpm2swidtag.conf bash | bin/swidq -p - -l )
fi

for f in tests/swid_generator/*.swidtag ; do
	diff -u ${f/.swidtag/.files} <( bin/swidq -p $f -l )
done

echo OK.
