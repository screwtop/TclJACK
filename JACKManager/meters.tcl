# Built-in audio meters.  How many?  Currently, the input ports in TclJACK are hard-coded (at 1!).


# TODO: declare these variables the correct way.
set meter_width 6
set meter_height 21
set meter_clipping_point [expr {1 - 1 / pow(2,15)}]	;# 1 bit below full-scale for 16-bit precision.


proc clip {value lower_bound upper_bound} {
	if {$value < $lower_bound} {return $lower_bound}
	if {$value > $upper_bound} {return $upper_bound}
	return $value
}

proc set_meters_visibility {enabled} {
	if {$enabled} {
		show_meters
	} else {
		hide_meters
		# Might be good to turn off the "every" as well if not enabled, for efficiency.
	}
}

proc create_meters {} {
	global meter_width meter_height

	# Probably want a frame around the whole meter set, as we don't know how many we'll have.
	frame .meters -borderwidth 1

	grid [frame .meters.sound_gauge  -width $meter_width  -height $meter_height  -relief sunken  -borderwidth 1 -background black] -row 0 -column 0
	
	# Meter gauge is also simply done as a frame:
	place [frame .meters.sound_gauge.meter     -width [expr {$meter_width-2}] -height 0  -relief flat -borderwidth 0 -background green] -anchor sw -x 0 -y [expr {$meter_height-2}]

	setTooltip .meters {Audio signal level(s)}

	every 50 {
		global meter_width meter_height meter_clipping_point

		# How expensive is all this stuff...?

		# Peak level is useful for clipping indicator; RMS for overall level.
		set meter_reading [jack meter]
		set raw_peak_level [lindex $meter_reading 0]
		set raw_rms_level [lindex $meter_reading 1]
		set raw_trough_level [lindex $meter_reading 2]
		set raw_dc_offset [lindex $meter_reading 3]

		set gauge_colour green	;# Default, everything-is-OK gauge colour.
		# Cheating to get the meter to appear invisible with silence:
		if {$raw_peak_level == 0} then {set gauge_colour black}	;# Ha!
		# For colouring the meter, first check the RMS level and if it's above -14 dB FS (-17 dB numeric), colour the gauge orange or yellow.
		if {$raw_rms_level > 0.14} then {set gauge_colour yellow}
		# Or could we base it on peak level?  0.5 or 0.3 threshold?
	#	if {$raw_peak_level > 0.3} then {set gauge_colour yellow}
		# Then, check the peak level for clipping, and colour it red if clipping occurred.
		if {$raw_peak_level > $meter_clipping_point} then {set gauge_colour red}

		set gauge_value [clip [expr {2.5 * pow($raw_rms_level, 0.67)}] 0 1]
		.meters.sound_gauge.meter configure -height [expr {$gauge_value * ($meter_height-2)}] -background $gauge_colour
	}
}

proc destroy_meters {} {destroy .meters}

proc show_meters {} {grid .meters -row 0 -column 5}

proc hide_meters {} {grid forget .meters}


