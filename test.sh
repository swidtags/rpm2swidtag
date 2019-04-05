#!/bin/bash

set -e
set -x

# Content packaged to .tar.gz via MANIFEST.in does not preserve symlinks
if ! [ -L tests/swiddata1/symlinked ] ; then
	rm -rf tests/swiddata1/symlinked
	ln -s ../swiddata3/b.test tests/swiddata1/symlinked
fi

mkdir -p tmp

function normalize() {
	sed 's/<Evidence date="[^"]*Z" deviceId="[^"]*"/<Evidence date="2018-01-01T12:13:14Z" deviceId="machine.example.test"/'
}
function normalize_i() {
	sed -i 's/<Evidence date="[^"]*Z" deviceId="[^"]*"/<Evidence date="2018-01-01T12:13:14Z" deviceId="machine.example.test"/' "$*"
}

if [ "$TEST_INSTALLED" = true ] ; then
	BIN=/usr/bin
	RPM2SWIDTAG_OPTS2=--config=/etc/rpm2swidtag/rpm2swidtag.conf
	RPM2SWIDTAG_OPTS3="--config /usr/../etc/rpm2swidtag/rpm2swidtag.conf"
	RPM2SWIDTAG_XSLT1=tests/xslt/swidtag-inst.xslt
	RPM2SWIDTAG_XSLT2=tests/xslt/swidtag-fail-inst.xslt
	DNF_OPTS=--nogpgcheck
	cp tests/rpm2swidtag.conf.d/*.conf /etc/rpm2swidtag/rpm2swidtag.conf.d/
	SWIDQ_STYLESHEET_DIR2=/usr/share/swidq/stylesheets
	SWIDQ_OPTS2="-c tests/swidq-inst.conf"
	SWIDQ_OPTS3="-c /etc/swidq/swidq.conf"
	SWIDQ_STYLESHEET_SUP="tests/swidq-xml-supplemental-structure-inst.xslt"
else
	export PYTHONPATH=lib
	BIN=./bin
	RPM2SWIDTAG_OPTS=--config=tests/rpm2swidtag.conf
	RPM2SWIDTAG_OPTS2=--config=$(pwd)/tests/rpm2swidtag.conf
	RPM2SWIDTAG_OPTS3="--config ./tests/rpm2swidtag.conf"
	DNF_ROOT=tmp/dnfroot
	DNF_OPTS="--installroot $(pwd)/$DNF_ROOT --config=tests/dnf.conf"
	RPM2SWIDTAG_XSLT1=tests/xslt/swidtag.xslt
	RPM2SWIDTAG_XSLT2=tests/xslt/swidtag-fail.xslt
	SWIDQ_STYLESHEET_DIR1=.
	SWIDQ_STYLESHEET_DIR2=$(pwd)
	SWIDQ_OPTS="-c tests/swidq.conf"
	SWIDQ_OPTS2=$SWIDQ_OPTS
	SWIDQ_OPTS3="-c $(pwd)/tests/swidq.conf"
	SWIDQ_STYLESHEET_SUP="tests/swidq-xml-supplemental-structure.xslt"
	if [ "$UID" != 0 ] ; then
		FAKEROOT=fakeroot
		FAKECHROOT=fakechroot
	fi
fi

# Testing rpm2swidtag
# For testing, let's default the data location to the current directory
$BIN/rpm2swidtag $RPM2SWIDTAG_OPTS -p tests/rpms/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm | normalize > tmp/pkg-generated.swidtag
diff tests/pkg1/pkg1-1.2.0-1.fc28.x86_64.swidtag tmp/pkg-generated.swidtag

$BIN/rpm2swidtag $RPM2SWIDTAG_OPTS2 --authoritative -p tests/rpms/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm > tmp/pkg-generated.swidtag
diff tests/pkg1/pkg1-1.2.0-1.fc28.x86_64.auth.swidtag tmp/pkg-generated.swidtag

$BIN/rpm2swidtag $RPM2SWIDTAG_OPTS3 --evidence-deviceid specific.machine.example.test -p tests/rpms/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm | sed 's/<Evidence date="[^"]*Z"/<Evidence date="2018-01-01T12:13:14Z"/' > tmp/pkg-generated.swidtag
diff tests/pkg1/pkg1-1.2.0-1.fc28.x86_64.deviceid.swidtag tmp/pkg-generated.swidtag

$BIN/rpm2swidtag $RPM2SWIDTAG_OPTS -p --tag-creator=example.test tests/rpms/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm | normalize > tmp/pkg-generated-regid.swidtag
diff tests/pkg1/pkg1-1.2.0-1.fc28.x86_64.swidtag.regid tmp/pkg-generated-regid.swidtag

$BIN/rpm2swidtag $RPM2SWIDTAG_OPTS -p --tag-creator="example.test Example Corp." tests/rpms/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm | normalize > tmp/pkg-generated-regid.swidtag
diff tests/pkg1/pkg1-1.2.0-1.fc28.x86_64.swidtag.regid-name tmp/pkg-generated-regid.swidtag

$BIN/rpm2swidtag $RPM2SWIDTAG_OPTS -p --tag-creator=./tests/swiddata1/sup/p1.swidtag tests/rpms/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm | normalize > tmp/pkg-generated-regid.swidtag
diff tests/pkg1/pkg1-1.2.0-1.fc28.x86_64.swidtag.regid-name-ref tmp/pkg-generated-regid.swidtag

$BIN/rpm2swidtag $RPM2SWIDTAG_OPTS -p --software-creator=./tests/swiddata1/sup/p1.swidtag tests/rpms/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm | normalize > tmp/pkg-generated-regid.swidtag
diff tests/pkg1/pkg1-1.2.0-1.fc28.x86_64.swidtag.software-regid-name-ref tmp/pkg-generated-regid.swidtag

$BIN/rpm2swidtag $RPM2SWIDTAG_OPTS -p tests/rpms/src/pkg1-1.2.0-1.fc28.src.rpm | normalize > tmp/pkg-generated-src.swidtag
diff tests/pkg1/pkg1-1.2.0-1.fc28.src.swidtag tmp/pkg-generated-src.swidtag

$BIN/rpm2swidtag $RPM2SWIDTAG_OPTS -p tests/hello-rpm/hello-1.0-1.i386.rpm | normalize > tmp/pkg-generated-src.swidtag
diff tests/hello-rpm/hello-1.0-1.i386.swidtag tmp/pkg-generated-src.swidtag

$BIN/rpm2swidtag $RPM2SWIDTAG_OPTS -p tests/hello-rpm/hello-2.0-1.x86_64-signed.rpm | normalize > tmp/pkg-generated-src.swidtag
diff tests/hello-rpm/hello-2.0-1.x86_64-signed.swidtag tmp/pkg-generated-src.swidtag

$BIN/rpm2swidtag $RPM2SWIDTAG_OPTS -p tests/rpms/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm --software-creator a.test | normalize > tmp/pkg-generated.swidtag
diff tests/pkg1/pkg1-1.2.0-1.fc28.x86_64.swidtag.software-creator-regid tmp/pkg-generated.swidtag

RPM2SWIDTAG_TEMPLATE=tests/swidtag-template-minimal.xml $BIN/rpm2swidtag $RPM2SWIDTAG_OPTS -p tests/rpms/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm | normalize > tmp/pkg-from-minimal.swidtag
diff tests/pkg1/pkg1-1.2.0-1.fc28.x86_64.swidtag.minimal tmp/pkg-from-minimal.swidtag

RPM2SWIDTAG_TEMPLATE=tests/swidtag-template-extra.xml $BIN/rpm2swidtag --tag-creator="z.test Example Z" $RPM2SWIDTAG_OPTS -p tests/rpms/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm | normalize > tmp/pkg-from-extra.swidtag
diff tests/pkg1/pkg1-1.2.0-1.fc28.x86_64.swidtag.extra tmp/pkg-from-extra.swidtag

RPM2SWIDTAG_XSLT=$RPM2SWIDTAG_XSLT1 $BIN/rpm2swidtag $RPM2SWIDTAG_OPTS -p tests/rpms/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm | normalize > tmp/pkg-custom-tagid.swidtag
diff tests/pkg1/pkg1-1.2.0-1.fc28.x86_64.swidtag.custom-tagid tmp/pkg-custom-tagid.swidtag

$BIN/rpm2swidtag $RPM2SWIDTAG_OPTS -p tests/rpms/x86_64/pkg2-0.0.1-1.git0f5628a6.fc28.x86_64.rpm | normalize > tmp/pkg-generated-epoch.swidtag
diff tests/pkg2/pkg2-13:0.0.1-1.git0f5628a6.fc28.x86_64.swidtag tmp/pkg-generated-epoch.swidtag

rm -rf tmp/rpmdb
rpm --ignorearch --dbpath $(pwd)/tmp/rpmdb --justdb --nodeps -iv tests/rpms/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm
rpm --ignorearch --dbpath $(pwd)/tmp/rpmdb --justdb --nodeps -iv tests/rpms/x86_64/pkg1-1.3.0-1.fc28.x86_64.rpm
rpm --ignorearch --dbpath $(pwd)/tmp/rpmdb --justdb --nodeps -iv tests/rpms/x86_64/pkg2-0.0.1-1.git0f5628a6.fc28.x86_64.rpm
rpm --dbpath $(pwd)/tmp/rpmdb -qa

rm -rf tmp/gnupg
cp -rp tests/gnupg tmp/gnupg
gpg2 --homedir=tmp/gnupg --list-secret-keys
gpg2 --homedir=tmp/gnupg --export --armor 19D5C7DD > tmp/key-19D5C7DD.gpg
### rpm --dbpath $(pwd)/tmp/rpmdb --import tmp/key-19D5C7DD.gpg

_RPM2SWIDTAG_RPMDBPATH=$(pwd)/tmp/rpmdb $BIN/rpm2swidtag $RPM2SWIDTAG_OPTS pkg1-1.3.0 | normalize > tmp/pkg-generated.swidtag
cat tests/pkg1/pkg1-1.3.0-1.fc28.x86_64.swidtag tests/pkg1/pkg1-1.3.0-1.fc28.x86_64.swidtag.supplemental-component-of-distro > tmp/pkg1-1.3.0.swidtag.with-supplemental
diff tmp/pkg1-1.3.0.swidtag.with-supplemental tmp/pkg-generated.swidtag

_RPM2SWIDTAG_RPMDBPATH=$(pwd)/tmp/rpmdb $BIN/rpm2swidtag $RPM2SWIDTAG_OPTS --primary-only pkg1-1.3.0 | normalize > tmp/pkg-generated.swidtag
diff tests/pkg1/pkg1-1.3.0-1.fc28.x86_64.swidtag tmp/pkg-generated.swidtag

_RPM2SWIDTAG_RPMDBPATH=$(pwd)/tmp/rpmdb $BIN/rpm2swidtag $RPM2SWIDTAG_OPTS pkg1 | normalize > tmp/pkg-generated.swidtag
cat tests/pkg1/pkg1-1.2.0-1.fc28.x86_64.swidtag tests/pkg1/pkg1-1.3.0-1.fc28.x86_64.swidtag tests/pkg1/pkg1-1.3.0-1.fc28.x86_64.swidtag.supplemental-component-of-distro > tmp/pkg1-1.2.0-and-1.3.0.swidtag
diff tmp/pkg1-1.2.0-and-1.3.0.swidtag tmp/pkg-generated.swidtag

_RPM2SWIDTAG_RPMDBPATH=$(pwd)/tmp/rpmdb $BIN/rpm2swidtag $RPM2SWIDTAG_OPTS -a 'pkg*' | normalize > tmp/pkg-generated.swidtag
cat tmp/pkg1-1.2.0-and-1.3.0.swidtag tests/pkg2/pkg2-13:0.0.1-1.git0f5628a6.fc28.x86_64.swidtag > tmp/pkg1-and-pkg2.swidtag
diff tmp/pkg1-and-pkg2.swidtag tmp/pkg-generated.swidtag

_RPM2SWIDTAG_RPMDBPATH=$(pwd)/tmp/rpmdb $BIN/rpm2swidtag $RPM2SWIDTAG_OPTS -a | normalize > tmp/pkg-generated.swidtag
diff tmp/pkg1-and-pkg2.swidtag tmp/pkg-generated.swidtag

rm -rf tmp/output-dir tmp/compare-dir
_RPM2SWIDTAG_RPMDBPATH=$(pwd)/tmp/rpmdb $BIN/rpm2swidtag $RPM2SWIDTAG_OPTS --tag-creator=example.test --output-dir=tmp/output-dir -a
find tmp/output-dir -type f | while read f ; do normalize_i $f ; done
mkdir -p tmp/compare-dir/example.test
for i in pkg1-1.2.0-1.fc28.x86_64 pkg1-1.3.0-1.fc28.x86_64 pkg2-13:0.0.1-1.git0f5628a6.fc28.x86_64 ; do
	sed 's/unavailable.invalid/test.example/;s/invalid.unavailable/example.test/' tests/${i%%-*}/$i.swidtag > tmp/compare-dir/example.test/test.example.$i.swidtag
done
sed 's/unavailable.invalid/test.example/;s/invalid.unavailable/example.test/' tests/pkg1/pkg1-1.3.0-1.fc28.x86_64.swidtag.supplemental-component-of-distro > tmp/compare-dir/example.test/test.example.pkg1-1.3.0-1.fc28.x86_64-component-of-test.a.Example-OS-Distro-3.x86_64.swidtag
diff -ru tmp/output-dir tmp/compare-dir

rm -rf tmp/output-dir
_RPM2SWIDTAG_RPMDBPATH=$(pwd)/tmp/rpmdb $BIN/rpm2swidtag $RPM2SWIDTAG_OPTS --tag-creator=example.test --output-dir=tmp/output-dir/. -a
find tmp/output-dir -type f | while read f ; do normalize_i $f ; done
mv tmp/compare-dir/example.test/* tmp/compare-dir
rmdir tmp/compare-dir/example.test
diff -ru tmp/output-dir tmp/compare-dir

rm -rf tmp/output-dir tmp/compare-dir
_RPM2SWIDTAG_RPMDBPATH=$(pwd)/tmp/rpmdb $BIN/rpm2swidtag $RPM2SWIDTAG_OPTS --tag-creator=regid/with/slashes --output-dir=tmp/output-dir -a
find tmp/output-dir -type f | while read f ; do normalize_i $f ; done
mkdir -p tmp/compare-dir/regid^2fwith^2fslashes
for i in pkg1-1.2.0-1.fc28.x86_64 pkg1-1.3.0-1.fc28.x86_64 pkg2-13:0.0.1-1.git0f5628a6.fc28.x86_64 ; do
	sed 's#unavailable.invalid#regid/with/slashes#;s#invalid.unavailable#regid/with/slashes#' tests/${i%%-*}/$i.swidtag > tmp/compare-dir/regid^2fwith^2fslashes/regid^2fwith^2fslashes.$i.swidtag
done
sed 's#unavailable.invalid#regid/with/slashes#;s#invalid.unavailable#regid/with/slashes#' tests/pkg1/pkg1-1.3.0-1.fc28.x86_64.swidtag.supplemental-component-of-distro > tmp/compare-dir/regid^2fwith^2fslashes/regid^2fwith^2fslashes.pkg1-1.3.0-1.fc28.x86_64-component-of-test.a.Example-OS-Distro-3.x86_64.swidtag
diff -ru tmp/output-dir tmp/compare-dir

rm -rf tmp/output-dir tmp/compare-dir
_RPM2SWIDTAG_RPMDBPATH=$(pwd)/tmp/rpmdb $BIN/rpm2swidtag $RPM2SWIDTAG_OPTS --tag-creator=. --output-dir=tmp/output-dir -a
find tmp/output-dir -type f | while read f ; do normalize_i $f ; done
mkdir -p tmp/compare-dir/^2e
for i in pkg1-1.2.0-1.fc28.x86_64 pkg1-1.3.0-1.fc28.x86_64 pkg2-13:0.0.1-1.git0f5628a6.fc28.x86_64 ; do
	sed 's/unavailable.invalid.//;s/invalid.unavailable/./' tests/${i%%-*}/$i.swidtag > tmp/compare-dir/^2e/$i.swidtag
done
sed 's/unavailable.invalid.//;s/invalid.unavailable/./' tests/pkg1/pkg1-1.3.0-1.fc28.x86_64.swidtag.supplemental-component-of-distro > tmp/compare-dir/^2e/pkg1-1.3.0-1.fc28.x86_64-component-of-test.a.Example-OS-Distro-3.x86_64.swidtag
diff -ru tmp/output-dir tmp/compare-dir


SIGNDIR=tests/signing
_RPM2SWIDTAG_RPMDBPATH=$(pwd)/tmp/rpmdb $BIN/rpm2swidtag $RPM2SWIDTAG_OPTS --tag-creator=example.test --output-dir=tmp/output-dir/signed-internal/. -a --sign-pem=$SIGNDIR/test.key,$SIGNDIR/test-ca.crt,$SIGNDIR/test.crt --authoritative
# XML declaration produced by XSLT output is different than the XML write gives us
sed -i 's#^<?xml version='"'"'1\.0'"'"' encoding='"'"'UTF-8'"'"'?>$#<?xml version="1.0" encoding="utf-8"?>#' tmp/output-dir/signed-internal/*

_RPM2SWIDTAG_RPMDBPATH=$(pwd)/tmp/rpmdb $BIN/rpm2swidtag $RPM2SWIDTAG_OPTS --tag-creator=example.test --output-dir=tmp/output-dir/sign-input/. -a --preserve-signing-template --authoritative
mkdir tmp/output-dir/signed-pkcs12 tmp/output-dir/signed-pem
( cd tmp/output-dir/sign-input && ls ) | while read i ; do
	xmlsec1 --sign --pkcs12 $SIGNDIR/test.pkcs12 --pwd password8263 --enabled-reference-uris empty tmp/output-dir/sign-input/$i | xmllint --format - > tmp/output-dir/signed-pkcs12/$i
	xmlsec1 --sign --privkey-pem $SIGNDIR/test.key,$SIGNDIR/test-ca.crt,$SIGNDIR/test.crt --enabled-reference-uris empty tmp/output-dir/sign-input/$i | xmllint --format - > tmp/output-dir/signed-pem/$i
done
for i in tmp/output-dir/signed-internal/* ; do
	xmlsec1 --verify --trusted-pem $SIGNDIR/test-ca.crt $i
done
diff -ru tmp/output-dir/signed-internal tests/pkg-signed
diff -ru tmp/output-dir/signed-pkcs12 tests/pkg-signed
diff -ru tmp/output-dir/signed-pem tests/pkg-signed

OUT=$( _RPM2SWIDTAG_RPMDBPATH=$(pwd)/tmp/rpmdb $BIN/rpm2swidtag $RPM2SWIDTAG_OPTS --print-tagid pkg1 )
test "$OUT" == "$( echo -e 'unavailable.invalid.pkg1-1.2.0-1.fc28.x86_64\nunavailable.invalid.pkg1-1.3.0-1.fc28.x86_64\n+ unavailable.invalid.pkg1-1.3.0-1.fc28.x86_64-component-of-test.a.Example-OS-Distro-3.x86_64' )"

# Testing errors
set +e
OUT=$( $BIN/rpm2swidtag $RPM2SWIDTAG_OPTS -p nonexistent 2>&1 )
ERR=$?
set -e
test "$ERR" -eq 3
test "$OUT" == "$BIN/rpm2swidtag: Error reading rpm file [nonexistent]: No such file or directory"

set +e
OUT=$( $BIN/rpm2swidtag $RPM2SWIDTAG_OPTS -p /dev/null 2>&1 )
ERR=$?
set -e
test "$ERR" -eq 3
test "$OUT" == "$BIN/rpm2swidtag: Error reading rpm file [/dev/null]: error reading package header"

set +e
OUT=$( RPM2SWIDTAG_XSLT=nonexistent $BIN/rpm2swidtag $RPM2SWIDTAG_OPTS -p tests/rpms/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm 2>&1 )
ERR=$?
set -e
test "$ERR" -eq 5
test "$OUT" == "$BIN/rpm2swidtag: Error reading processing XSLT file [nonexistent]: Error reading file 'nonexistent': failed to load external entity \"nonexistent\""

set +e
OUT=$( RPM2SWIDTAG_XSLT=$RPM2SWIDTAG_XSLT2 $BIN/rpm2swidtag $RPM2SWIDTAG_OPTS -p tests/rpms/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm 2>&1 )
ERR=$?
set -e
test "$ERR" -eq 6
test "$OUT" == "$BIN/rpm2swidtag: Error generating SWID tag for file [tests/rpms/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm]: Unknown header tag [broken] requested by XSLT stylesheet: unknown header tag"

set +e
OUT=$( _RPM2SWIDTAG_RPMDBPATH=$(pwd)/tmp/rpmdb $BIN/rpm2swidtag $RPM2SWIDTAG_OPTS x 2>&1 )
ERR=$?
set -e
test "$ERR" -eq 7
test "$OUT" == "$BIN/rpm2swidtag: No package [x] found in database"

set +e
OUT=$( _RPM2SWIDTAG_RPMDBPATH=$(pwd)/tmp/rpmdb $BIN/rpm2swidtag $RPM2SWIDTAG_OPTS 'pkg*' 2>&1 )
ERR=$?
set -e
test "$ERR" -eq 7
test "$OUT" == "$BIN/rpm2swidtag: No package [pkg*] found in database"

set +e
OUT=$( _RPM2SWIDTAG_RPMDBPATH=$(pwd)/tmp/rpmdb $BIN/rpm2swidtag $RPM2SWIDTAG_OPTS -a 'x*' 2>&1 )
ERR=$?
set -e
test "$ERR" -eq 7
test "$OUT" == "$BIN/rpm2swidtag: No package [x*] found in database"

set +e
OUT=$( _RPM2SWIDTAG_RPMDBPATH=$(pwd)/tmp/rpmdb $BIN/rpm2swidtag $RPM2SWIDTAG_OPTS pkg1 x pkg2 2>&1 > /tmp/pkg-generated.swidtag )
ERR=$?
set -e
test "$ERR" -eq 7
normalize_i /tmp/pkg-generated.swidtag
test "$OUT" == "$BIN/rpm2swidtag: No package [x] found in database"
diff tmp/pkg1-and-pkg2.swidtag /tmp/pkg-generated.swidtag

# Test that README has up-to-date usage section
diff -u <( $BIN/rpm2swidtag -h ) <( sed -n '/^usage: rpm2swidtag/,/```/{/```/T;p}' README.md )


# Testing swidq
$BIN/swidq -p tests/swiddata1/a.test/pkg1-1.2.0-1.fc28.x86_64.swidtag > tmp/swidq.out 2> tmp/swidq.err
diff /dev/null tmp/swidq.err
diff <( echo 'unavailable.invalid.pkg1-1.2.0-1.fc28.x86_64 tests/swiddata1/a.test/pkg1-1.2.0-1.fc28.x86_64.swidtag' ) tmp/swidq.out

$BIN/swidq -c swidq.conf -p tests/swiddata1/a.test/pkg1-1.2.0-1.fc28.x86_64.swidtag --debug > tmp/swidq.out 2> tmp/swidq.err
diff <( sed "s#^bin#$BIN#" tests/swiddata1/a.test/pkg1-1.2.0-1.fc28.x86_64.debug ) tmp/swidq.err
diff <( echo 'unavailable.invalid.pkg1-1.2.0-1.fc28.x86_64 tests/swiddata1/a.test/pkg1-1.2.0-1.fc28.x86_64.swidtag' ) tmp/swidq.out

$BIN/swidq --silent -p - < tests/swiddata1/a.test/pkg1-1.2.0-1.fc28.x86_64.swidtag > tmp/swidq.out 2> tmp/swidq.err
diff /dev/null tmp/swidq.err
diff <( echo 'unavailable.invalid.pkg1-1.2.0-1.fc28.x86_64 -' ) tmp/swidq.out

$BIN/swidq -p tests/swiddata1/*/*.swidtag > tmp/swidq.out 2> tmp/swidq.err
diff /dev/null tmp/swidq.err
diff tests/swidq-swiddata1.out tmp/swidq.out

$BIN/swidq -p 'tests/swiddata1/*' > tmp/swidq.out 2> tmp/swidq.err
diff /dev/null tmp/swidq.err
diff tests/swidq-swiddata1.out tmp/swidq.out

$BIN/swidq -p tests/swiddata1/*/*.swidtag tests/swiddata1/*/*.swidtag --silent > tmp/swidq.out 2> tmp/swidq.err
diff /dev/null tmp/swidq.err
diff <( cat tests/swidq-swiddata1.out ) tmp/swidq.out

$BIN/swidq $SWIDQ_OPTS --silent > tmp/swidq.out 2> tmp/swidq.err
diff /dev/null tmp/swidq.err
diff /dev/null tmp/swidq.out

$BIN/swidq --silent $SWIDQ_OPTS2 -a > tmp/swidq.out 2> tmp/swidq.err
diff /dev/null tmp/swidq.err
diff tests/swidq-swiddata1-swiddata2.out tmp/swidq.out

$BIN/swidq $SWIDQ_OPTS2 unavailable.invalid.pkg1-1.2.0-1.fc28.x86_64 --silent > tmp/swidq.out 2> tmp/swidq.err
diff /dev/null tmp/swidq.err
diff <( echo 'unavailable.invalid.pkg1-1.2.0-1.fc28.x86_64 tests/swiddata1/a.test/pkg1-1.2.0-1.fc28.x86_64.swidtag' ) tmp/swidq.out

$BIN/swidq $SWIDQ_OPTS2 -a unavailable.invalid.pkg1-1.2.0-1.fc28.x86_64 --silent > tmp/swidq.out 2> tmp/swidq.err
diff /dev/null tmp/swidq.err
diff <( echo 'unavailable.invalid.pkg1-1.2.0-1.fc28.x86_64 tests/swiddata1/a.test/pkg1-1.2.0-1.fc28.x86_64.swidtag' ) tmp/swidq.out

$BIN/swidq --silent $SWIDQ_OPTS2 -a '*pkg1*' > tmp/swidq.out 2> tmp/swidq.err
diff /dev/null tmp/swidq.err
diff <( echo 'unavailable.invalid.pkg1-1.2.0-1.fc28.x86_64 tests/swiddata1/a.test/pkg1-1.2.0-1.fc28.x86_64.swidtag' ) tmp/swidq.out

$BIN/swidq --silent $SWIDQ_OPTS2 -a '*pkg1*' '*pkg5*' > tmp/swidq.out 2> tmp/swidq.err
diff /dev/null tmp/swidq.err
diff <( echo 'unavailable.invalid.pkg1-1.2.0-1.fc28.x86_64 tests/swiddata1/a.test/pkg1-1.2.0-1.fc28.x86_64.swidtag' ) tmp/swidq.out

$BIN/swidq --silent $SWIDQ_OPTS unknown.tagid > tmp/swidq.out 2> tmp/swidq.err
diff /dev/null tmp/swidq.err
diff /dev/null tmp/swidq.out

$BIN/swidq --silent $SWIDQ_OPTS2 -n 'qkg1' > tmp/swidq.out 2> tmp/swidq.err
diff /dev/null tmp/swidq.err
diff <( echo 'test.a.qkg1-1.0.0-1.x86_64 tests/swiddata1/a.test/qkg1.swidtag' ; echo 'test.a.qkg1-1.0.0-1.x86_64 tests/swiddata2/qkg1.swidtag' ) tmp/swidq.out

$BIN/swidq --silent $SWIDQ_OPTS2 -n 'qkg1' pkg1 > tmp/swidq.out 2> tmp/swidq.err
diff /dev/null tmp/swidq.err
diff <( echo 'unavailable.invalid.pkg1-1.2.0-1.fc28.x86_64 tests/swiddata1/a.test/pkg1-1.2.0-1.fc28.x86_64.swidtag' ; echo 'test.a.qkg1-1.0.0-1.x86_64 tests/swiddata1/a.test/qkg1.swidtag' ; echo 'test.a.qkg1-1.0.0-1.x86_64 tests/swiddata2/qkg1.swidtag' ) tmp/swidq.out

$BIN/swidq --silent $SWIDQ_OPTS2 -a -n 'qkg*' 'p?g1' > tmp/swidq.out 2> tmp/swidq.err
diff /dev/null tmp/swidq.err
diff <( echo 'unavailable.invalid.pkg1-1.2.0-1.fc28.x86_64 tests/swiddata1/a.test/pkg1-1.2.0-1.fc28.x86_64.swidtag' ; echo 'test.a.qkg1-1.0.0-1.x86_64 tests/swiddata1/a.test/qkg1.swidtag' ; echo 'test.a.qkg1-1.0.0-1.x86_64 tests/swiddata2/qkg1.swidtag' ) tmp/swidq.out

$BIN/swidq --silent $SWIDQ_OPTS -n qkg2 > tmp/swidq.out 2> tmp/swidq.err
diff /dev/null tmp/swidq.err
diff /dev/null tmp/swidq.out

$BIN/swidq -p tests/swiddata1/a.test/pkg3.swidtag tests/swiddata2/pkg3.swidtag > tmp/swidq.out 2> tmp/swidq.err
diff /dev/null tmp/swidq.err
diff <( echo 'test.a.pkg3-1.0.0-1.x86_64 tests/swiddata1/a.test/pkg3.swidtag' ; echo 'test.a.pkg3-1.0.0-1.x86_64 tests/swiddata2/pkg3.swidtag' ) tmp/swidq.out

$BIN/swidq -p tests/swiddata2/pkg3.swidtag tests/swiddata1/a.test/pkg3.swidtag > tmp/swidq.out 2> tmp/swidq.err
diff /dev/null tmp/swidq.err
diff <( echo 'test.a.pkg3-1.0.0-1.x86_64 tests/swiddata2/pkg3.swidtag' ; echo 'test.a.pkg3-1.0.0-1.x86_64 tests/swiddata1/a.test/pkg3.swidtag' ) tmp/swidq.out

$BIN/swidq -p $( find tests/swiddata[12] -name '*distro*.swidtag' ) tests/swiddata2/missing-tag-supplemental.swidtag > tmp/swidq.out 2> tmp/swidq.err
diff <( echo "$BIN/swidq: [test.a.Example-OS-Distro-3.15.x86_64] supplements [swid:test.example.missing.Example-OS-Distro-3.x86_64] which we do not know" ) tmp/swidq.err
diff <( echo 'test.a.Example-OS-Distro-3.x86_64 tests/swiddata1/a.test/distro.swidtag' ;
	echo '+ test.a.Example-OS-Distro-3.14.x86_64 tests/swiddata2/distro-minor-supplemental.swidtag' ;
	echo '  + test.a.Example-OS-Distro-3.14.x86_64-sup2 tests/swiddata2/distro-minor-supplemental-2.swidtag' ;
	echo '- test.a.Example-OS-Distro-3.15.x86_64 tests/swiddata2/missing-tag-supplemental.swidtag' ) tmp/swidq.out

$BIN/swidq -p tests/swiddata2/distro-minor-supplemental.swidtag > tmp/swidq.out 2> tmp/swidq.err
diff <( echo "$BIN/swidq: [test.a.Example-OS-Distro-3.14.x86_64] supplements [swid:test.a.Example-OS-Distro-3.x86_64] which we do not know" ) tmp/swidq.err
diff <( echo '- test.a.Example-OS-Distro-3.14.x86_64 tests/swiddata2/distro-minor-supplemental.swidtag' ) tmp/swidq.out

SWIDQ_STYLESHEET_DIR=$SWIDQ_STYLESHEET_DIR1 $BIN/swidq --dump -p tests/swiddata1/a.test/pkg1-1.2.0-1.fc28.x86_64.swidtag > tmp/swidq.out 2> tmp/swidq.err
diff /dev/null tmp/swidq.err
diff tests/swiddata1/a.test/pkg1-1.2.0-1.fc28.x86_64.dump tmp/swidq.out

$BIN/swidq --dump $SWIDQ_OPTS -p tests/swiddata1/a.test/minimal.swidtag > tmp/swidq.out 2> tmp/swidq.err
diff /dev/null tmp/swidq.err
diff tests/swiddata1/a.test/minimal.dump tmp/swidq.out

SWIDQ_STYLESHEET_DIR=$SWIDQ_STYLESHEET_DIR2 $BIN/swidq --info -p tests/swiddata1/a.test/minimal.swidtag > tmp/swidq.out 2> tmp/swidq.err
diff /dev/null tmp/swidq.err
diff tests/swiddata1/a.test/minimal.info tmp/swidq.out

$BIN/swidq -i $SWIDQ_OPTS -p tests/swiddata1/a.test/pkg1-1.2.0-1.fc28.x86_64.swidtag > tmp/swidq.out 2> tmp/swidq.err
diff /dev/null tmp/swidq.err
diff tests/swiddata1/a.test/pkg1-1.2.0-1.fc28.x86_64.info tmp/swidq.out

SWIDQ_STYLESHEET_DIR=$SWIDQ_STYLESHEET_DIR1 $BIN/swidq -il -p tests/swiddata1/a.test/pkg1-1.2.0-1.fc28.x86_64.swidtag > tmp/swidq.out 2> tmp/swidq.err
diff /dev/null tmp/swidq.err
diff <( cat tests/swiddata1/a.test/pkg1-1.2.0-1.fc28.x86_64.{info,files} ) tmp/swidq.out

$BIN/swidq --silent $SWIDQ_OPTS2 -l -n pkg1 > tmp/swidq.out 2> tmp/swidq.err
diff /dev/null tmp/swidq.err
diff tests/swiddata1/a.test/pkg1-1.2.0-1.fc28.x86_64.files tmp/swidq.out

SWIDQ_STYLESHEET_DIR=$SWIDQ_STYLESHEET_DIR1 $BIN/swidq -i -p tests/swiddata1/a.test/distro.swidtag > tmp/swidq.out 2> tmp/swidq.err
diff /dev/null tmp/swidq.err
diff tests/swiddata1/a.test/distro.info tmp/swidq.out

SWIDQ_STYLESHEET_DIR=$SWIDQ_STYLESHEET_DIR2 $BIN/swidq -i -p tests/swiddata2/distro-minor-supplemental.swidtag > tmp/swidq.out 2> tmp/swidq.err
diff <( echo "$BIN/swidq: [test.a.Example-OS-Distro-3.14.x86_64] supplements [swid:test.a.Example-OS-Distro-3.x86_64] which we do not know" ) tmp/swidq.err
diff tests/swiddata2/distro-minor-supplemental.info tmp/swidq.out

$BIN/swidq -p tests/swiddata1/sup --info $SWIDQ_OPTS3 > tmp/swidq.out 2> tmp/swidq.err
diff /dev/null tmp/swidq.err
diff tests/swiddata1/sup/sup.info tmp/swidq.out

$BIN/swidq -p tests/swiddata1/sup --output-stylesheet=$SWIDQ_STYLESHEET_SUP > tmp/swidq.out 2> tmp/swidq.err
diff /dev/null tmp/swidq.err
diff tests/swiddata1/sup/sup.xml tmp/swidq.out

SWIDQ_STYLESHEET_DIR=$SWIDQ_STYLESHEET_DIR1 $BIN/swidq -p tests/swiddata1/sup --dump > tmp/swidq.out 2> tmp/swidq.err
diff /dev/null tmp/swidq.err
diff tests/swiddata1/sup/sup.dump tmp/swidq.out

$BIN/swidq --silent $SWIDQ_OPTS2 --rpm pkg3-1.0.0-1.x86_64 > tmp/swidq.out 2> tmp/swidq.err
diff /dev/null tmp/swidq.err
diff <( echo 'test.a.pkg3-1.0.0-1.x86_64 tests/swiddata1/a.test/pkg3.swidtag' ;
	echo 'test.b.pkg3-1.0.0-1.x86_64 tests/swiddata3/b.test/pkg3.swidtag' ;
	echo 'test.a.pkg3-1.0.0-1.x86_64 tests/swiddata2/pkg3.swidtag' ) tmp/swidq.out

$BIN/swidq --silent $SWIDQ_OPTS2 --rpm -a > tmp/swidq.out 2> tmp/swidq.err
diff /dev/null tmp/swidq.err
diff <( echo 'unavailable.invalid.pkg1-1.2.0-1.fc28.x86_64 tests/swiddata1/a.test/pkg1-1.2.0-1.fc28.x86_64.swidtag' ;
	echo 'test.a.pkg3-1.0.0-1.x86_64 tests/swiddata1/a.test/pkg3.swidtag' ;
	echo 'test.b.pkg3-1.0.0-1.x86_64 tests/swiddata3/b.test/pkg3.swidtag' ;
	echo 'test.a.pkg3-1.0.0-1.x86_64 tests/swiddata2/pkg3.swidtag' ) tmp/swidq.out

SWIDQ_STYLESHEET_DIR=$SWIDQ_STYLESHEET_DIR2 $BIN/swidq --xml -p tests/pkg1/pkg1-1.2.0-1.fc28.x86_64.auth.xmlns.swidtag > tmp/swidq.out 2> tmp/swidq.err
diff /dev/null tmp/swidq.err
diff tests/pkg1/pkg1-1.2.0-1.fc28.x86_64.auth.swidtag tmp/swidq.out

rm -f tmp/stylesheet.xslt
if [ "$TEST_INSTALLED" = true ] ; then
	ln -s /usr/share/swidq/stylesheets/swidq-dump.xslt tmp/stylesheet.xslt
else
	ln -s ../swidq-dump.xslt tmp/stylesheet.xslt
fi
(
unset SWIDQ_STYLESHEET_DIR
$BIN/swidq --output-stylesheet=tmp/stylesheet.xslt -p tests/swiddata1/a.test/pkg1-1.2.0-1.fc28.x86_64.swidtag > tmp/swidq.out 2> tmp/swidq.err
diff /dev/null tmp/swidq.err
diff tests/swiddata1/a.test/pkg1-1.2.0-1.fc28.x86_64.dump tmp/swidq.out
)

# Testing errors
set +e
OUT=$( $BIN/swidq -p nonexistent 2>&1 )
ERR=$?
set -e
test "$ERR" -eq 1
test "$OUT" == "$BIN/swidq: no file matching [nonexistent]"

$BIN/swidq -p tests/swiddata-wrong/SoftwareIdentity-in-SoftwareIdentity.swidtag > tmp/swidq.out 2> tmp/swidq.err
diff /dev/null tmp/swidq.err
diff <( echo 'test.a.Example-OS-Distro-3.x86_64 tests/swiddata-wrong/SoftwareIdentity-in-SoftwareIdentity.swidtag' ) tmp/swidq.out

$BIN/swidq -p tests/swiddata-wrong/wrong-schema.xml > tmp/swidq.out 2> tmp/swidq.err
diff <( echo "$BIN/swidq: file [tests/swiddata-wrong/wrong-schema.xml] does not have SoftwareIdentity in the SWID 2015 namespace, found [{http://standards.iso.org/iso/19770/-2/2013-error/schema.xsd}SoftwareIdentity]" ) tmp/swidq.err
diff /dev/null tmp/swidq.out

$BIN/swidq -p tests/swiddata-wrong/wrong-root.xml > tmp/swidq.out 2> tmp/swidq.err
diff <( echo "$BIN/swidq: file [tests/swiddata-wrong/wrong-root.xml] does not have SoftwareIdentity in the SWID 2015 namespace, found [{http://standards.iso.org/iso/19770/-2/2015/schema.xsd}Entity]" ) tmp/swidq.err
diff /dev/null tmp/swidq.out

$BIN/swidq -p tests/swiddata-wrong/missing-tagId.xml > tmp/swidq.out 2> tmp/swidq.err
diff <( echo "$BIN/swidq: file [tests/swiddata-wrong/missing-tagId.xml] does not have SoftwareIdentity/@tagId" ) tmp/swidq.err
diff /dev/null tmp/swidq.out

$BIN/swidq -p tests/swiddata-wrong/missing-name.xml > tmp/swidq.out 2> tmp/swidq.err
diff <( echo "$BIN/swidq: file [tests/swiddata-wrong/missing-name.xml] does not have SoftwareIdentity/@name" ) tmp/swidq.err
diff /dev/null tmp/swidq.out

$BIN/swidq -p tests/swiddata-wrong/supplemental-without-link.swidtag > tmp/swidq.out 2> tmp/swidq.err
diff <( echo "$BIN/swidq: file [tests/swiddata-wrong/supplemental-without-link.swidtag] is supplemental but does not have any supplemental Link" ) tmp/swidq.err
diff /dev/null tmp/swidq.out

$BIN/swidq -p tests/swiddata-wrong/supplemental-without-attribute.swidtag > tmp/swidq.out 2> tmp/swidq.err
diff <( echo "$BIN/swidq: file [tests/swiddata-wrong/supplemental-without-attribute.swidtag] has Link with @rel='supplemental' but not @supplemental='true'") tmp/swidq.err
diff /dev/null tmp/swidq.out

# Test that README has up-to-date usage section
diff -u <( $BIN/swidq -h ) <( sed -n '/^usage: swidq/,/```/{/```/T;p}' README.md )


# rpm2swidtag to swidq
find . -name '*.rpm' | while read f ; do
	diff -u <( rpm -qlp $f | grep -v '^(contains no files)' ) <( $BIN/rpm2swidtag $RPM2SWIDTAG_OPTS --primary-only -p $f | $BIN/swidq -p - $SWIDQ_OPTS -l )
done

if rpm -q bash ; then
	diff -u <( rpm -ql bash ) <( $BIN/rpm2swidtag --primary-only $RPM2SWIDTAG_OPTS bash | $BIN/swidq $SWIDQ_OPTS -p - -l )
fi

if rpm -q filesystem ; then
	diff -u <( rpm -ql filesystem ) <( $BIN/rpm2swidtag --primary-only $RPM2SWIDTAG_OPTS filesystem | $BIN/swidq -p - -l $SWIDQ_OPTS )
fi

for f in tests/swid_generator/*.swidtag ; do
	diff -u ${f/.swidtag/.files} <( SWIDQ_STYLESHEET_DIR=$SWIDQ_STYLESHEET_DIR1 $BIN/swidq -p $f -l )
done


# Test dnf plugin
mkdir -p tmp/repo tmp/repo-base
cp -p tests/rpms/x86_64/* tests/rpms/noarch/* ./tests/hello-rpm/*.rpm tmp/repo-base
if [ "$(($RANDOM % 2))" == "0" ] ; then
	createrepo_c -u file://$(pwd)/tmp/repo-base tmp/repo-base -o tmp/repo
else
	( cd tmp/repo-base && for i in *.rpm ; do ln ../repo-base/$i ../repo/$i ; done )
	createrepo_c tmp/repo
fi
if [ -n "$DNF_ROOT" ] ; then
	rm -rf $DNF_ROOT
fi
$FAKEROOT dnf --setopt=reposdir=/dev/null $DNF_OPTS list installed
### rpm --dbpath $(pwd)/tmp/dnfroot/var/lib/rpm --import $(pwd)/tmp/key-19D5C7DD.gpg
$FAKEROOT dnf --setopt=reposdir=/dev/null $DNF_OPTS swidtags regen
! test -L $DNF_ROOT/etc/swid/swidtags.d/rpm2swidtag-generated
! test -d $DNF_ROOT/etc/swid/swidtags.d/rpm2swidtag-generated
$FAKECHROOT $FAKEROOT dnf --forcearch=x86_64 --setopt=reposdir=/dev/null $DNF_OPTS --repofrompath local,tmp/repo install -y pkg1-1.2.0

echo "f2ca1bb6c7e907d06dafe4687e579fce76b37e4e93b7605022da52e6ccc26fd2 $DNF_ROOT/usr/share/testdir/testfile" | sha256sum -c
test -f $DNF_ROOT/var/lib/swidtag/rpm2swidtag-generated/*.pkg1-1.2.0-1.fc28.x86_64.swidtag
test -f $DNF_ROOT/var/lib/swidtag/rpm2swidtag-generated/*.pkgdep-1.0.0-1.fc28.noarch.swidtag
test -f $DNF_ROOT/var/lib/swidtag/rpm2swidtag-generated/*.pkgdep-1.0.0-1.fc28.noarch-component-of-test.a.Example-OS-Distro-3.x86_64.swidtag

$FAKEROOT dnf --setopt=reposdir=/dev/null $DNF_OPTS swidtags purge
! test -L $DNF_ROOT/etc/swid/swidtags.d/rpm2swidtag-generated
! test -d $DNF_ROOT/var/lib/swidtag/rpm2swidtag-generated
! $FAKEROOT dnf --setopt=reposdir=/dev/null $DNF_OPTS swidtags purge 2>&1 | grep Failed || false
$FAKEROOT dnf --setopt=reposdir=/dev/null $DNF_OPTS swidtags regen
test -L $DNF_ROOT/etc/swid/swidtags.d/rpm2swidtag-generated
test -f $DNF_ROOT/var/lib/swidtag/rpm2swidtag-generated/*.pkg1-1.2.0-1.fc28.x86_64.swidtag
test -f $DNF_ROOT/var/lib/swidtag/rpm2swidtag-generated/*.pkgdep-1.0.0-1.fc28.noarch.swidtag
test -f $DNF_ROOT/var/lib/swidtag/rpm2swidtag-generated/*.pkgdep-1.0.0-1.fc28.noarch-component-of-test.a.Example-OS-Distro-3.x86_64.swidtag

$BIN/rpm2swidtag --repo=tmp/repo $RPM2SWIDTAG_OPTS --authoritative --tag-creator "example/test Example Org." --software-creator "other.test Other Org." --sign-pem=$SIGNDIR/test.key,$SIGNDIR/test-ca.crt,$SIGNDIR/test.crt
zcat tmp/repo/repodata/*-swidtags.xml.gz > tmp/repo/swidtags.xml
diff tests/repodata-swidtags.xml tmp/repo/swidtags.xml

$FAKECHROOT $FAKEROOT dnf --setopt=reposdir=/dev/null $DNF_OPTS clean expire-cache

$FAKECHROOT $FAKEROOT dnf --forcearch=x86_64 --setopt=reposdir=/dev/null $DNF_OPTS --repofrompath local,tmp/repo upgrade -y
test -f $DNF_ROOT/var/lib/swidtag/rpm2swidtag-generated/*.pkgdep-1.0.0-1.fc28.noarch.swidtag
test -f $DNF_ROOT/var/lib/swidtag/rpm2swidtag-generated/*.pkgdep-1.0.0-1.fc28.noarch-component-of-test.a.Example-OS-Distro-3.x86_64.swidtag
! test -f $DNF_ROOT/var/lib/swidtag/rpm2swidtag-generated/*.pkg1-1.2.0-1.fc28.x86_64.swidtag
! test -f $DNF_ROOT/var/lib/swidtag/rpm2swidtag-generated/*.pkg1-1.3.0-1.fc28.x86_64.swidtag
! test -f $DNF_ROOT/var/lib/swidtag/rpm2swidtag-generated/*.pkg1-1.3.0-1.fc28.x86_64-component-of-test.a.Example-OS-Distro-3.x86_64.swidtag
! test -d $DNF_ROOT/var/lib/swidtag/example^2ftest
ls -l $DNF_ROOT/usr/lib/swidtag/example^2ftest/* | tee /dev/stderr | wc -l | grep '^2$'
test -f $DNF_ROOT/usr/lib/swidtag/example^2ftest/example^2ftest.pkg1-1.3.0-1.fc28.x86_64.swidtag
test -f $DNF_ROOT/usr/lib/swidtag/example^2ftest/example^2ftest.pkg1-1.3.0-1.fc28.x86_64-component-of-test.a.Example-OS-Distro-3.x86_64.swidtag
for i in $DNF_ROOT/usr/lib/swidtag/example^2ftest/* ; do
	xmlsec1 --verify --trusted-pem $SIGNDIR/test-ca.crt $i
done

$FAKECHROOT $FAKEROOT dnf --forcearch=x86_64 --setopt=reposdir=/dev/null $DNF_OPTS install -y tmp/repo-base/pkg2-0.0.1-1.git0f5628a6.fc28.x86_64.rpm
test -f $DNF_ROOT/var/lib/swidtag/rpm2swidtag-generated/*.pkg2-13:0.0.1-1.git0f5628a6.fc28.x86_64.swidtag
ls -l $DNF_ROOT/usr/lib/swidtag/example^2ftest/* | tee /dev/stderr | wc -l | grep '^2$'

$FAKECHROOT $FAKEROOT dnf --forcearch=x86_64 --setopt=reposdir=/dev/null $DNF_OPTS --repofrompath local,tmp/repo reinstall -y pkg2
! test -f $DNF_ROOT/var/lib/swidtag/rpm2swidtag-generated/*.pkg2-13:0.0.1-1.git0f5628a6.fc28.x86_64.swidtag
ls -l $DNF_ROOT/usr/lib/swidtag/example^2ftest/* | tee /dev/stderr | wc -l | grep '^3$'
test -f $DNF_ROOT/usr/lib/swidtag/example^2ftest/example^2ftest.pkg2-13:0.0.1-1.git0f5628a6.fc28.x86_64.swidtag

$FAKECHROOT $FAKEROOT dnf --setopt=reposdir=/dev/null $DNF_OPTS remove -y pkg1
test -f $DNF_ROOT/var/lib/swidtag/rpm2swidtag-generated/*.pkgdep-1.0.0-1.fc28.noarch.swidtag
test -f $DNF_ROOT/var/lib/swidtag/rpm2swidtag-generated/*.pkgdep-1.0.0-1.fc28.noarch-component-of-test.a.Example-OS-Distro-3.x86_64.swidtag
ls -l $DNF_ROOT/usr/lib/swidtag/example^2ftest/* | tee /dev/stderr | wc -l | grep '^1$'

! test -f $DNF_ROOT/usr/lib/swidtag/example^2ftest/example^2ftest.pkg1-1.3.0-1.fc28.x86_64.swidtag
! test -f $DNF_ROOT/usr/lib/swidtag/example^2ftest/example^2ftest.pkg1-1.3.0-1.fc28.x86_64-component-of-test.a.Example-OS-Distro-3.x86_64.swidtag
test -f $DNF_ROOT/usr/lib/swidtag/example^2ftest/example^2ftest.pkg2-13:0.0.1-1.git0f5628a6.fc28.x86_64.swidtag
test -f $DNF_ROOT/var/lib/swidtag/rpm2swidtag-generated/*.pkgdep-1.0.0-1.fc28.noarch.swidtag
test -f $DNF_ROOT/var/lib/swidtag/rpm2swidtag-generated/*.pkgdep-1.0.0-1.fc28.noarch-component-of-test.a.Example-OS-Distro-3.x86_64.swidtag

echo "need-regen" > $DNF_ROOT/usr/lib/swidtag/example^2ftest/example^2ftest.pkg2-13:0.0.1-1.git0f5628a6.fc28.x86_64.swidtag
grep -r need-regen $DNF_ROOT/usr/lib/swidtag/example^2ftest

$FAKEROOT dnf --setopt=reposdir=/dev/null $DNF_OPTS --repofrompath local,tmp/repo swidtags regen
test -L $DNF_ROOT/etc/swid/swidtags.d/rpm2swidtag-generated
! test -f $DNF_ROOT/var/lib/swidtag/rpm2swidtag-generated/*.pkgdep-1.0.0-1.fc28.noarch.swidtag
! test -f $DNF_ROOT/var/lib/swidtag/rpm2swidtag-generated/*.pkgdep-1.0.0-1.fc28.noarch-component-of-test.a.Example-OS-Distro-3.x86_64.swidtag
ls -l $DNF_ROOT/usr/lib/swidtag/example^2ftest/* | tee /dev/stderr | wc -l | grep '^3$'
! grep -r need-regen $DNF_ROOT/usr/lib/swidtag/example^2ftest

# Test that README has up-to-date usage section
diff -u <( $BIN/swidq -h ) <( sed -n '/^usage: swidq/,/```/{/```/T;p}' README.md )

diff -u <(PYTHONPATH=lib dnf --setopt=reposdir=/dev/null $DNF_OPTS swidtags --help | sed -n '/SWID/,/^optional/!b;/^optional/b;p') <(sed -n '/^Generate/,/```/{/```/T;p}' README.md )


echo OK.
