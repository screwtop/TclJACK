This is just a copy of the Hello World Tcl C extension example from the Tcl wiki at
http://wiki.tcl.tk/11153

To run (build.sh works on my Linux test system; no other promises!):

# ./build.sh
# wish
% load ./libhello[info sharedlibextension]
% hello
Hello, World!

