# Variables you might need to change:
# To make/install for a specific Tcl version (if you have several installed), pass TCL_VERSION like so:
# make TCL_VERSION=8.6

TCL_VERSION=$(shell echo "puts [info tclversion]" | /usr/bin/env tclsh)
#TCL_VERSION=8.6
CC=gcc
TCLSH=tclsh$(TCL_VERSION)
# Not sure how to reliably determine this:
TCLINC=/usr/include/tcl$(TCL_VERSION)
TCLLIB=/usr/lib -ltclstub$(TCL_VERSION)
TCL_LIB_PATH=$(shell echo "puts [info library]" | /usr/bin/env tclsh$(TCL_VERSION))
INSTALL_PATH=$(TCL_LIB_PATH)/tcljack
CFLAGS=-fPIC -shared -DUSE_TCL_STUBS


# You shouldn't need to change anything below here.

all: libtcljack.so pkgIndex.tcl

libtcljack.so: tcljack.c
	${CC} ${CFLAGS} -o libtcljack.so -I${TCLINC} tcljack.c -L${TCLLIB} -ljack

pkgIndex.tcl: libtcljack.so
	echo 'pkg_mkIndex . libtcljack.so' | $(TCLSH)

install:
	mkdir -p ${INSTALL_PATH}
	cp libtcljack.so pkgIndex.tcl ${INSTALL_PATH}

.PHONY: clean
clean:
	rm -f libtcljack.so pkgIndex.tcl

