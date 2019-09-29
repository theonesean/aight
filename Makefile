.PHONY: all install build test run clean

ifdef USEINSTALL
INSTALLEXEC := install -Dm755
INSTALL := install -Dm644
else
INSTALLEXEC := sudo cp -f
INSTALL := sudo cp -f
endif

UNAME := $(shell uname)

ifeq ($(UNAME),Darwin)
	OS_FLAG := OSX
endif

all: build test

DESTDIR?=
install: build
ifeq ($(OS_FLAG),OSX)
	$(INSTALLEXEC) "./aight" "${DESTDIR}/usr/local/bin/aight"
else
	$(INSTALLEXEC) "./aight" "${DESTDIR}/usr/bin/aight"
	$(INSTALL) "./LICENSE" "${DESTDIR}/usr/share/licenses/aight/LICENSE"
endif

build:
	dub build

test:
	dub test

run: aight
	./aight

clean:
	rm -rf pkg/
	rm -rf src/
	rm -rf AIGHT/
	rm -f aight-*.pkg.tar
	rm -f aight-test-library
	rm -f aight
