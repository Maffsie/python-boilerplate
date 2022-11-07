define HELP

This Makefile contains build, test and setup commands for the current project.

Usage:

make help:				Shows this text

make clean:				Removes all build and dist artefacts and any cache or bytecode

make lint:				Runs flake8 against the project
make check-format:		Runs black and isort against the project, in check mode. Useful for CI.
make format:			Runs black and isort against the project.

make venv:				Creates the Python virtual environment
make clean-venv:		Removes the Python virtual environment

make setup:				Installs the project.

endef
export HELP

PROJECTNAME=

SRCPATH := src
PKGPATH := $(SRCPATH)/$(PROJECTNAME)
VENVPATH := venv
BUILDPATH := _build
PYBUILDPATH := build
PYDISTPATH := dist
COVERAGEPATH := $(BUILDPATH)/coverage
REQUIREMENTS_RESULT := $(BUILDPATH)/requirements.txt

.PHONY: help
help:
	@echo "$$HELP"

.PHONY: clean
clean:
	rm -rf $(BUILDPATH) $(PYBUILDPATH) $(PYDISTPATH)
	find $(SRCPATH) -name '*.pyc' -delete
	find $(SRCPATH) -type d -name __pycache__ -delete

.PHONY: venv
venv:
	python -m venv $(VENVPATH)

.PHONY: clean-venv
clean-venv:
	rm -rf $(VENVPATH)

.PHONY: build_dirs
build_dirs: $(BUILDPATH)

$(BUILDPATH):
	mkdir -p $(BUILDPATH) $(COVERAGEPATH)

base-requirements:
	python -m pip --require-virtualenv install -U pip wheel setuptools

build-requirements: base-requirements
	pip --require-virtualenv install -Ur $(SRCPATH)/requirements/build.txt

package-requirements: base-requirements
	pip --require-virtualenv install -Ur $(SRCPATH)/requirements/package.txt

requirements.txt: build_dirs
	pip --require-virtualenv install -Ur $(SRCPATH)/requirements/package.txt
	pip --require-virtualenv freeze \
		--exclude black \
		--exclude click \
		--exclude flake8 \
		--exclude isort \
		--exclude mccabe \
		--exclude mypy-extensions \
		--exclude pathspec \
		--exclude pep517 \
		--exclude platformdirs \
		--exclude pycodestyle \
		--exclude pyflakes \
		--exclude tomli \
		--exclude typing_extensions \
		> $(BUILDPATH)/$@

.PHONY: requirements
requirements: build-requirements package-requirements

py_pep517_setup: build-requirements requirements
	python -m pep517.build $(SRCPATH)

.PHONY: setup
setup: clean requirements py_pep517_setup

.PHONY: lint
lint: requirements
	flake8 $(SRCPATH) | tee $(BUILDPATH)/lint.txt

.PHONY: check-format
check-format: requirements
	isort -rc -c $(SRCPATH)
	black --check $(SRCPATH)

.PHONY: format
format: requirements
	isort -rc $(SRCPATH)
	black $(SRCPATH)

.PHONY: unittest
unittest: requirements
	pytest $(SRCPATH) --cov $(ARGS)

.PHONY: test
test: unittest lint check-format
