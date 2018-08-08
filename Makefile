
srpm:
	python3 setup.py bdist_rpm --source-only
	ls -l dist/*.src.rpm

rpm:
	python3 setup.py bdist_rpm --binary-only
	ls -l dist/*.noarch.rpm

test:
	./test.sh

clean:
	rm -rf $(shell cat .gitignore)

