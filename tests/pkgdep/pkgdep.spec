Summary: Example dependency package
Name: pkgdep
Version: 1.0.0
Release: 1%{?dist}
License: ASL 2.0
Group: System Environment/Daemons
URL: https://www.example.com/
BuildArch: noarch

BuildRequires: bash

%description
This is an example rpm package to test generating SWID tags.

%prep
%build
%install
mkdir -p %{buildroot}/usr/share/testdirdep
echo testdep > %{buildroot}/usr/share/testdirdep/testfile

%files
/usr/share/testdirdep/testfile
