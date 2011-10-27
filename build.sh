#!/bin/sh

# TODO: replace this with a Makefile!
# TODO: tidy up hard-coded bits and pieces to work on other systems

#gcc -o jack_test jack_test.c -ljack


# Hmm, expect lags in Tcl version; have 8.4 rather than 8.5 which this gets built with.  Can we define/override TCL_VERSION?  Seems not.
TCLINC=/usr/include/tcl8.5
#TCLLIB=/usr/lib64
TCLLIB=/usr/lib
#gcc -fPIC -shared -o libtcljack.so -DUSE_TCL_STUBS -I$TCLINC tcljack.c -L$TCLLIB -DTCL_VERSION=8.4-ltclstub8.4 -ljack
gcc -fPIC -shared -o libtcljack.so -DUSE_TCL_STUBS -I$TCLINC tcljack.c -L$TCLLIB -ltclstub8.5 -ljack

# Also (re-)generate the pkgIndex.tcl file for the library and install:
echo 'pkg_mkIndex . libtcljack.so' | tclsh
mkdir -p /usr/local/lib/tcl8.5/tcljack
cp libtcljack.so pkgIndex.tcl /usr/local/lib/tcl8.5/tcljack/
