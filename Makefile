
srpm:
	python3 setup.py bdist_rpm --source-only --install-script=bdist_rpm/install_script
	ls -l dist/*.src.rpm

rpm:
	python3 setup.py bdist_rpm --binary-only --install-script=bdist_rpm/install_script
	ls -l dist/*.noarch.rpm

test:
	./test.sh

clean:
	rm -rf $(shell cat .gitignore)

