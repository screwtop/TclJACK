# JACKManager control panel element for monitoring the CPU DSP load percentage.

# Timecode display could be a menu-button, with menu items showing the time (live) in the other measurements.  Selecting one would then change the main display's measurement!  Nifty.  Provided there's enough difference in the displays to tell which is which (although we could add extra label text after it to clarify if necessary).

#pack [menubutton .timecode_frame.timecode  -text "00:00:00.000"  -menu .timecode_frame.timecode.menu  -font font_mono  -relief groove] -side left


# TODO: handle user preference for timecode clock display format (i.e. remembering, not a whole custom format model implementation).


set jack_timecode_string {  ?:??:??.???}

proc set_timecode_visibility {enabled} {
	if {$enabled} {
		show_timecode
	} else {
		hide_timecode
		# Might be good to turn off the "every" as well if not enabled, for efficiency.
	}
}

proc create_timecode {} {
	# Can we set a format property to control how the textvariable is displayed?
	menubutton .timecode  -textvariable jack_timecode_string  -menu .timecode.menu  -font $::tcljack::font_mono  -relief flat -cursor {arrow}
	setTooltip .timecode {JACK transport timecode}

	# Set up its context menu:
	menu .timecode.menu
		.timecode.menu add command -label {00:00:00.000}	;# entry #1 (0 is the menu tear-off tab)
		.timecode.menu add command -label {[TODO: Bars:Beats]}
		.timecode.menu add command -label {Frames (Samples)}
		.timecode.menu add command -label {[TODO: SMPTE]}
	#	.timecode.menu add separator

	# Lastly, start its updates running:
	# What update interval to use?  Many displays run at 60 Hz, so ~16 ms would match the refresh period.
	# The timecode strings are currently formatted to (somewhat arbitrarily) millisecond precision.  At 96 kHz, a frame is only about 10 microseconds.
	# TODO: pause refreshing if we disconnect from JACK!
	every 16 {
		set time_in_frames [jack timecode]
		set ::jack_timecode_string [frames_to_hhmmss $time_in_frames [jack samplerate]]
		.timecode.menu entryconfigure 1 -label $::jack_timecode_string
		.timecode.menu entryconfigure 3 -label $time_in_frames
	}	;# "hhh:mm:ss.mss"
#	every 50 {set ::jack_timecode_string [jack timecode]}	;# For raw frames
}

proc destroy_timecode {} {destroy .timecode}

proc show_timecode {} {grid .timecode -row 0 -column 2}

proc hide_timecode {} {grid forget .timecode}


# Here's a procedure for converting raw frame count into nicely formatted hh:mm:ss type display (actually "hhh:mm:ss.mss").
# Do we want to pass in the sampling rate as well?  Would be more modular that way...
# Will likely be called as [frames_to_hhmmss [jack timecode] [jack samplerate]].
# I think JACK itself can only manage 13 and a half hours before it wraps around, so let's only use 2 hour digits.  I prefer no leading padding 0 for the hours (it makes it more obvious that it's the hours field).
proc frames_to_hhmmss {frame_count sampling_rate} {
	set remainder_in_seconds [expr double($frame_count) / $sampling_rate]

	set timecode_hours [expr {floor($remainder_in_seconds / 3600.0)}]
	set timecode_hours_string [format {%2.0f} $timecode_hours]

	set remainder_in_seconds [expr {$remainder_in_seconds - $timecode_hours * 3600.0}]

	set timecode_minutes [expr {floor($remainder_in_seconds / 60.0)}]
	set timecode_minutes_string [format {%02.0f} $timecode_minutes]

	set remainder_in_seconds [expr {$remainder_in_seconds - $timecode_minutes * 60.0}]

	set timecode_seconds $remainder_in_seconds
	set timecode_seconds_string [format {%06.3f} $timecode_seconds]

	return "$timecode_hours_string:$timecode_minutes_string:$timecode_seconds_string"		
}

# Test case: 15 hours 27 minutes 59.345 seconds
#
# >>> 15 * 3600 * 44100 + 27 * 60 * 44100 + 59.345 * 44100
# 2455459114.5
#
# % frames_to_hhmmss 2455459114.5 44100
# 15:27:59.345
#
# Good. :)

