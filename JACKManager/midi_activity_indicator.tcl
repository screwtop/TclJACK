# MIDI activity indicator (I might do a full MIDI actvity/event monitor later) component for JACKManager
# CME 2011-10-28 (now that TclJACK provides a means of finding out how many MIDI events occurred since the last time we checked)

namespace eval ::midi_activity_indicator {}

# Hmm, meter size compared to font size may still be a bit fudgy...
set ::midi_activity_indicator::meter_height [expr {[dict get [font metrics $::tcljack::font_mono] -linespace] + 10 - 4}]
set ::midi_activity_indicator::meter_width $::midi_activity_indicator::meter_height



proc set_midi_activity_indicator_visibility {enabled} {
	if {$enabled} {
		show_midi_activity_indicator
		# TODO: and turn on the updater "every" as well?  "every" would need a "pause" subcommand, I think.
	} else {
		hide_midi_activity_indicator
		# Might be good to turn off the "every" as well if not enabled, for efficiency (provided we can turn it back on again!).
	}
}


proc create_midi_activity_indicator {} {
#	grid [frame .midi_activity_indicator  -width $::midi_activity_indicator::meter_width  -height $::midi_activity_indicator::meter_height  -relief sunken  -borderwidth 1 -background black] -row 0 -column 0

	# Or should I have a hollow frame that's always recessed, with a plain black/green rectangle for the actual indicator?
	frame .midi_activity_indicator -borderwidth 1	;# Decorative plain light grey frame to blend in with the text strip
	grid [frame .midi_activity_indicator.bevel -borderwidth 1 -relief sunken -background black] -row 0 -column 0	;# Dark recessed border
	grid [frame .midi_activity_indicator.bevel.indicator  -width $::midi_activity_indicator::meter_width  -height $::midi_activity_indicator::meter_height -background black  -relief flat] -row 0 -column 0


	setTooltip .midi_activity_indicator {MIDI activity}

	# Schedule background indicator updating (every 50 ms is probably about right for being able to see individual events without excessive busyness/CPU use):
	set ::midi_activity_indicator::updater [every 50 {

		# Get JACK MIDI input event count.  If it's greater than 0, turn the indicator green for the next interval, otherwise set it to black.
		# If we wanted to get fancy, some kind of colour change as we approach the maximum number of MIDI events per JACK period might be appropriate/useful.
		if {[jack midieventcount] > 0} {
			set indicator_colour green
		#	set indicator_relief raised
		} else {
			set indicator_colour black
		#	set indicator_relief sunken
		}
		
		.midi_activity_indicator.bevel.indicator  configure  -background $indicator_colour
	#	.midi_activity_indicator.indicator  configure  -background $indicator_colour  -relief $indicator_relief
	}]


}


proc destroy_midi_activity_indicator {} {destroy .midi_activity_indicator; every cancel $::midi_activity_indicator::updater}

# TODO: uh, hard-coded column index?! Fix.
proc show_midi_activity_indicator {} {grid .midi_activity_indicator -row 0 -column 6}

proc hide_midi_activity_indicator {} {grid forget .midi_activity_indicator}


