# JACKManager control panel element for monitoring the sampling rate.
# TODO: maybe use kHz in general?

set jack_sampling_rate_string {     ? Hz}

proc set_samplerate_visibility {enabled} {
	if {$enabled} {
		show_samplerate
	} else {
		hide_samplerate
	}
}

proc create_samplerate {} {
	menubutton .samplerate  -textvariable jack_sampling_rate_string  -font $::tcljack::font_mono  -relief flat
	setTooltip .samplerate {Hardware sampling frequency}
	# Lastly, start its updates running:
	every 1000 {set ::jack_sampling_rate_string "[format {%3d} [expr {[jack samplerate] / 1000}]] kHz"}	;# Full raw digits in Hz
#	every 1000 {set ::jack_sampling_rate_string "[format {%6d} [jack samplerate]] Hz"}	;# Full raw digits in Hz
}

proc destroy_samplerate {} {destroy .samplerate}

proc show_samplerate {} {grid .samplerate -row 0 -column 3}

proc hide_samplerate {} {grid forget .samplerate}


