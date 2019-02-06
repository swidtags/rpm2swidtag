#!/bin/bash

set -e
set -x

rm -rf tmp/gnupg
cp -rp tests/gnupg tmp/gnupg

export SOURCE_DATE_EPOCH=1540000000
rpmbuild -ba -D 'dist .fc28' -D "_sourcedir $(pwd)/tests/pkg1" -D "_srcrpmdir $(pwd)/tests/rpms/src" -D "_rpmdir $(pwd)/tests/rpms" -D "_rpmfilename %{_build_name_fmt}" -D '_buildhost test.example.com' -D 'clamp_mtime_to_source_date_epoch 1' tests/pkg1/pkg1-1.2.0.spec
rpmbuild -ba -D 'dist .fc28' -D "_sourcedir $(pwd)/tests/pkg1" -D "_srcrpmdir $(pwd)/tests/rpms/src" -D "_rpmdir $(pwd)/tests/rpms" -D "_rpmfilename %{_build_name_fmt}" -D '_buildhost test.example.com' -D 'clamp_mtime_to_source_date_epoch 1' tests/pkg1/pkg1-1.3.0.spec
rpmsign --addsign --key-id=19D5C7DD -D '_gpg_path tmp/gnupg' -D '_gpg_sign_cmd_extra_args --faked-system-time=1540000005' ./tests/rpms/x86_64/pkg1-1.3.0-1.fc28.x86_64.rpm
rpmbuild -ba -D 'dist .fc28' -D "_srcrpmdir $(pwd)/tests/rpms/src" -D "_rpmdir $(pwd)/tests/rpms" -D "_rpmfilename %{_build_name_fmt}" -D '_buildhost test.example.com' -D 'clamp_mtime_to_source_date_epoch 1' tests/pkg2/pkg2.spec
rpmbuild -ba -D 'dist .fc28' -D "_srcrpmdir $(pwd)/tests/rpms/src" -D "_rpmdir $(pwd)/tests/rpms" -D "_rpmfilename %{_build_name_fmt}" -D '_buildhost test.example.com' -D 'clamp_mtime_to_source_date_epoch 1' tests/pkgdep/pkgdep.spec
rpmsign --addsign --key-id=19D5C7DD -D '_gpg_path tmp/gnupg' -D '_gpg_sign_cmd_extra_args --faked-system-time=1540000005' ./tests/rpms/noarch/pkgdep-1.0.0-1.fc28.noarch.rpm

echo OK $0.
