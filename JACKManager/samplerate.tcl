# JACKManager control panel element for monitoring the sampling rate.

set jack_sampling_rate_string {?}

proc set_samplerate_visibility {enabled} {
	if {$enabled} {
		show_samplerate
	} else {
		hide_samplerate
	}
}

proc create_samplerate {} {
	menubutton .samplerate  -textvariable jack_sampling_rate_string  -font font_mono  -relief flat
	# Lastly, start its updates running:
	every 1000 {set ::jack_sampling_rate_string "[jack samplerate] Hz"}

}

proc destroy_samplerate {} {destroy .samplerate}

proc show_samplerate {} {grid .samplerate -row 0 -column 3}

proc hide_samplerate {} {grid forget .samplerate}


