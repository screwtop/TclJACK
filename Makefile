# Variables you might need to change:

CC=gcc
TCLSH=tclsh8.5
TCLINC=/usr/include/tcl8.5
TCLLIB=/usr/lib -ltclstub8.5
INSTALL_PATH=/usr/local/lib/tcl8.5/tcljack
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

