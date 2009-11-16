#!/bin/sh

#gcc -o jack_test jack_test.c -ljack



TCLINC=/usr/include
TCLLIB=/usr/lib64
gcc -fPIC -shared -o libtcljack.so -DUSE_TCL_STUBS -I$TCLINC tcljack.c -L$TCLLIB -ltclstub8.4 -ljack

