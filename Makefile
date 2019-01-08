
srpm:
	python3 setup.py bdist_rpm --source-only --install-script=bdist_rpm/install_script
	ls -l dist/*.src.rpm

rpm:
	python3 setup.py bdist_rpm --binary-only --install-script=bdist_rpm/install_script
	ls -l dist/*.noarch.rpm

spec:
	python3 setup.py bdist_rpm --spec-only --install-script=bdist_rpm/install_script
	ls -l dist/*.spec

test:
	./test.sh

clean:
	rm -rf $(shell cat .gitignore)

