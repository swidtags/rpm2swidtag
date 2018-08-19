
outdir := $(CURDIR)
spec := rpm2swidtag.spec

spec_dir := .
ifeq ($(shell test -d $(spec) && echo true),true)
	spec_dir = $(spec)
	spec_file = $(spec)/rpm2swidtag.spec
else
	spec_dir = $(dir $(spec))
	spec_file = $(spec)
endif

srpm:
	cd $(spec_dir) && make srpm && cp dist/*.src.rpm $(outdir)

