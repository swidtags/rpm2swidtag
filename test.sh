#!/bin/bash

set -e
set -x

mkdir -p tmp
rpmbuild -ba -D "_sourcedir $(pwd)/tests/pkg1" -D "_srcrpmdir $(pwd)/tmp" -D "_rpmdir $(pwd)/tmp" tests/pkg1/pkg1.spec
RPM2SWIDTAG_TEMPLATE_DIR=. ./rpm2swidtag.py tmp/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm > tmp/pkg-generated.swidtag
diff tests/pkg1/pkg1-1.2.0-1.fc28.x86_64.swidtag tmp/pkg-generated.swidtag

RPM2SWIDTAG_TEMPLATE_DIR=. ./rpm2swidtag.py tmp/pkg1-1.2.0-1.fc28.src.rpm > tmp/pkg-generated-src.swidtag
diff tests/pkg1/pkg1-1.2.0-1.fc28.src.swidtag tmp/pkg-generated-src.swidtag

RPM2SWIDTAG_TEMPLATE_DIR=. RPM2SWIDTAG_TEMPLATE=template-minimal.swidtag ./rpm2swidtag.py tmp/x86_64/pkg1-1.2.0-1.fc28.x86_64.rpm > tmp/pkg-from-minimal.swidtag
diff tests/pkg1/pkg1-1.2.0-1.fc28.x86_64.swidtag.minimal tmp/pkg-from-minimal.swidtag

