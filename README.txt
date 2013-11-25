TclJACK is a Tcl extension for the JACK Audio Connection Kit server library (essentially a wrapper around the libjack functions).

The core is a C library (tcljack.c, libtcljack.so), but additional high-level functionality is provided by some Tcl routines ().

The main reason for writing the library was to make it easy to build a simple GUI for controlling a JACK server

It could also be used in building a simple DAW, MIDI sequencer, algorithmic MIDI composer, etc.
