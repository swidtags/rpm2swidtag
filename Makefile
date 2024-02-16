
NAME = $(shell eval echo $$( awk '/^name/ { print $$NF }' pyproject.toml))
VERSION = $(shell eval echo $$( awk '/^version/ { print $$NF }' pyproject.toml))
DIST = dist
SPECFILE = dist/$(NAME).spec

spec:
	mkdir -p $(DIST)
	rpm -D "version $(VERSION)" --eval "$$( cat rpm2swidtag.spec.in )" > $(SPECFILE)
	ls -l $(DIST)/*.spec

tar-gz:
	rm -rf $(DIST)/$(NAME)-$(VERSION)
	mkdir -p $(DIST)/$(NAME)-$(VERSION)
	cp -rp -t dist/$(NAME)-$(VERSION) $(shell ls | grep -v dist)
	for i in $(shell cat .gitignore) ; do rm -rf $(DIST)/$$i ; done
	tar -C $(DIST) -cvzf $(DIST)/$(NAME)-$(VERSION).tar.gz $(NAME)-$(VERSION)
	rm -rf $(DIST)/$(NAME)-$(VERSION)
	ls -l $(DIST)/*.tar.gz

srpm: spec tar-gz
	rpmbuild -D '_srcrpmdir $(DIST)' -D '_sourcedir $(DIST)' -bs $(SPECFILE)
	ls -l $(DIST)/*.src.rpm

rpm: spec tar-gz
	rpmbuild -D '_rpmdir $(DIST)' -D '_sourcedir $(PWD)/$(DIST)' -bb $(SPECFILE)
	mv $(DIST)/noarch/*.noarch.rpm $(DIST)
	ls -l $(DIST)/*.noarch.rpm

test:
	./test.sh

test-pylint:
	pylint-3 --disable=R --disable=C --indent-string="\t" --extension-pkg-whitelist=rpm,lxml lib/*/*.py

clean:
	rm -rf $(shell cat .gitignore)

.PHONY: spec tar-gz srpm rpm test test-pylint clean

