Summary: Example rpm package
Name: pkg1
Version: 1.2.0
Release: 1%{?dist}
License: ASL 2.0
Group: System Environment/Daemons
URL: https://www.example.com/
Source0: testfile

BuildRequires: gcc
Requires: glibc

%description
This is an example rpm package to test generating SWID tags.

%prep
%build
%install
mkdir -p %{buildroot}/usr/share
install -m 644 %{SOURCE0} %{buildroot}/usr/share/testfile
touch %{buildroot}/usr/share/emptyfile
mkdir -p %{buildroot}/usr/share/testdir
ln -s testfile %{buildroot}/usr/share/testsymlink
ln -s testdir %{buildroot}/usr/share/testsymlink-to-dir
ln -s missing %{buildroot}/usr/share/testsymlink-to-missing
mkdir -p %{buildroot}/etc
echo "[config]" > %{buildroot}/etc/testconfig.conf

%files
/usr/share/testfile
/usr/share/emptyfile
/usr/share/testdir
%config /etc/testconfig.conf
/usr/share/testsymlink*
