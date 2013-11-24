# Built-in audio meters for JACKManager.  How many?  Currently, the input ports in TclJACK are hard-coded (at 1!).
# TODO: set the height of the meter appropriately, perhaps using font metrics.
# TODO: some way of adding/removing meters
# TODO: some way of connecting a meter to an audio source.  Will require functionality being added to TclJACK library first!


namespace eval ::meters {}


# Some dimensions and meter settings:
#set ::meters::meter_height 23
set ::meters::meter_height [expr {[dict get [font metrics $::tcljack::font_mono] -linespace] + 10 - 2}]
#puts $::meters::meter_height
#set ::meters::meter_width [expr {$::meters::meter_height / 4}]
set ::meters::meter_width [expr {round($::meters::meter_height / 3.0)}]
#set ::meters::meter_width [expr {round($::meters::meter_height * (2.0 / (1.0 + sqrt(5.0))))}]

# Meter height working:
# size: -12:	-ascent 11 -descent 2 -linespace 13 -fixed 1	meter_height: 23
# size: -10:	-ascent 9 -descent 2 -linespace 11 -fixed 1	meter_height: 21
# size:  -8:	-ascent 8 -descent 2 -linespace 10 -fixed 1	meter_height: 20



set ::meters::meter_clipping_threshold [expr {1 - 1 / pow(2,15)}]	;# 1 bit below full-scale for 16-bit precision.  This could probably be global.


proc clip {value lower_bound upper_bound} {
	if {$value < $lower_bound} {return $lower_bound}
	if {$value > $upper_bound} {return $upper_bound}
	return $value
}

proc set_meters_visibility {enabled} {
	if {$enabled} {
		show_meters
		# TODO: and turn on the updater "every" as well?  "every" would need a "pause" subcommand, I think.
	} else {
		hide_meters
		# Might be good to turn off the "every" as well if not enabled, for efficiency (provided we can turn it back on again!).
	}
}



proc update_meters {} {
	# Take a single reading from the current JACK audio buffers and update the meter displays
	global meter_width meter_height meter_clipping_point

	# How expensive is all this stuff...?

	# Peak level is useful for clipping indicator; RMS for overall level.
	set meter_readings [jack meter]

	foreach meter_num {0 1} {
		set meter_reading [lindex $meter_readings $meter_num]
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
		if {$raw_peak_level > $::meters::meter_clipping_threshold} then {set gauge_colour red}
	
		set gauge_value [clip [expr {2.5 * pow($raw_rms_level, 0.67)}] 0 1]
		.meters.meter${meter_num}.meter configure -height [expr {$gauge_value * ($::meters::meter_height-2)}] -background $gauge_colour
	}
}


# Old proc, which updated only a single meter one at a time (and would call [jack meter] separately each time, which is probably rather inefficient and would result in the left and right measurements being from different points in time)
proc update_meter {meter_num} {
	global meter_width meter_height meter_clipping_point

	# How expensive is all this stuff...?

	# Peak level is useful for clipping indicator; RMS for overall level.
	set meter_reading [lindex [jack meter] $meter_num]
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
	if {$raw_peak_level > $::meters::meter_clipping_threshold} then {set gauge_colour red}

	set gauge_value [clip [expr {2.5 * pow($raw_rms_level, 0.67)}] 0 1]
	.meters.meter${meter_num}.meter configure -height [expr {$gauge_value * ($::meters::meter_height-2)}] -background $gauge_colour
}


proc create_meters {} {
	# Probably want a frame around the whole meter set, as we don't know how many we'll have.
	frame .meters -borderwidth 1
	setTooltip .meters {Audio signal level}

	# Create meters.  Probably at least two, for stereo use...
	foreach meter_num {0 1} {

		grid [frame .meters.meter${meter_num}  -width $::meters::meter_width  -height $::meters::meter_height  -relief sunken  -borderwidth 1 -background black] -row 0 -column $meter_num

		# Meter gauge is also simply done as a frame:
		place [frame .meters.meter${meter_num}.meter     -width [expr {$::meters::meter_width-2}] -height 0  -relief flat -borderwidth 0 -background green] -anchor sw -x 0 -y [expr {$::meters::meter_height-2}]

		# Start the meter updating in the background:
		# TODO: properly figure out how often to update.  Every 16 ms might be reasonable assuming a 60 Hz display refresh rate.  Or, we could try to update when the JACK process() happens...might be more often than necessary?
		# TODO: have a single "every" to update all the meters!  For both efficiency and to have the meters updated from the same analysis slice (if it's possible to ensure that...?!).  Where to store the meter IDs?
		set ::meters::updater [every 50 update_meters]
	#	set ::meters::updater($meter_num) [every 50 [list update_meter $meter_num]]	;# Old one-at-a-time approach
	}
}

proc destroy_meters {} {
	destroy .meters
	every cancel $::meters::updater
#	foreach meter_num {0 1} {
#		every cancel $::meters::updater($meter_num)
#	}
}

proc show_meters {} {grid .meters -row 0 -column 6}

proc hide_meters {} {grid forget .meters}


