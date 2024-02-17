FROM registry.fedoraproject.org/fedora
COPY . /src/
WORKDIR /src
RUN if test -f /etc/centos-release ; then dnf install -y epel-release ; fi
