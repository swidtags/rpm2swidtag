
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

test-pylint:
	if pylint-3 --version | grep 'astroid 2\.3\.0' ; then echo "Skipping pylint due to https://github.com/PyCQA/pylint/issues/3090." >&2 ; \
	else pylint-3 --disable=R --disable=C --indent-string="\t" lib/*/*.py setup.py ; \
	fi

clean:
	rm -rf $(shell cat .gitignore)

