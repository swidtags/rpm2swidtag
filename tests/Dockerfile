FROM registry.fedoraproject.org/fedora
RUN dnf upgrade -y dnf python3-libdnf
COPY . /src/
WORKDIR /src
RUN tests/build.sh
