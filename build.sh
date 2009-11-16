#!/bin/sh

#gcc -o jack_test jack_test.c -ljack


# Hmm, expect lags in Tcl version; have 8.4 rather than 8.5 which this gets built with.  Can we define/override TCL_VERSION?  Seems not.
TCLINC=/usr/include
TCLLIB=/usr/lib64
gcc -fPIC -shared -o libtcljack.so -DUSE_TCL_STUBS -I$TCLINC tcljack.c -L$TCLLIB -DTCL_VERSION=8.4-ltclstub8.4 -ljack
#gcc -fPIC -shared -o libtcljack.so -DUSE_TCL_STUBS -I$TCLINC tcljack.c -L$TCLLIB -ltclstub8.5 -ljack

