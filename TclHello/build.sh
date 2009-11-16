#!/bin/sh

# Demo "Hello World" Tcl extension from
# http://wiki.tcl.tk/11153

TCLINC=/usr/include
TCLLIB=/usr/lib64
gcc -fPIC -shared -o libhello.so -DUSE_TCL_STUBS -I$TCLINC hello.c -L$TCLLIB -ltclstub8.4
