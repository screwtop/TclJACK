# JACK control panel element for monitoring the CPU DSP load percentage.

# Timecode display could be a menu-button, with menu items showing the time (live) in the other measurements.  Selecting one would then change the main display's measurement!  Nifty.  Provided there's enough difference in the displays to tell which is which (although we could add extra label text after it to clarify if necessary).

#pack [menubutton .timecode_frame.timecode  -text "00:00:00.000"  -menu .timecode_frame.timecode.menu  -font font_mono  -relief groove] -side left


# TODO: implement actual functionality!
# TODO: handle user preference for timecode clock display format.


set jack_timecode_string {00:00:00.000}

proc set_timecode_visibility {enabled} {
	if {$enabled} {
		show_timecode
	} else {
		hide_timecode
	}
}

proc create_timecode {} {
	# Can we set a format property to control how the textvariable is displayed?
	menubutton .timecode  -textvariable jack_timecode_string  -menu .timecode.menu  -font font_mono  -relief flat

	# Set up its context menu:
	menu .timecode.menu
		.timecode.menu add command -label {00:00:00.000}
		.timecode.menu add command -label {Bars and Beats}
		.timecode.menu add command -label {Frames (Samples)}
		.timecode.menu add command -label {SMPTE}
	#	.timecode.menu add separator

	# Lastly, start its updates running:
#	every 50 {set ::jack_timecode_string [jack timecode]}
}

proc destroy_timecode {} {destroy .timecode}

proc show_timecode {} {grid .timecode -row 0 -column 2}

proc hide_timecode {} {grid forget .timecode}

