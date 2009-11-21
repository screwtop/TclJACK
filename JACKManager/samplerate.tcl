# JACKManager control panel element for monitoring the sampling rate.

set jack_sampling_rate_string {     ? Hz}

proc set_samplerate_visibility {enabled} {
	if {$enabled} {
		show_samplerate
	} else {
		hide_samplerate
	}
}

proc create_samplerate {} {
	menubutton .samplerate  -textvariable jack_sampling_rate_string  -font font_mono  -relief flat
	setTooltip .samplerate {Hardware sampling frequency}
	# Lastly, start its updates running:
	every 1000 {set ::jack_sampling_rate_string "[format {%6d} [jack samplerate]] Hz"}
}

proc destroy_samplerate {} {destroy .samplerate}

proc show_samplerate {} {grid .samplerate -row 0 -column 3}

proc hide_samplerate {} {grid forget .samplerate}


