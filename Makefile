.PHONY: all install build test run

all: build test

install: build
	sudo cp ./aight /usr/local/bin/git-aight
	sudo ln -sf /usr/local/bin/git-aight /usr/local/bin/aight

build:
	dub build

test:
	dub test

run:
	dub run
