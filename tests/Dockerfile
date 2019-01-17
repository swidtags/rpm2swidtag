FROM registry.fedoraproject.org/fedora
RUN dnf upgrade -y dnf
COPY . /src/
WORKDIR /src
RUN tests/build.sh
