# JACK control panel element for monitoring the sampling rate.

set jack_sampling_rate_string {?}

proc set_samplerate_visibility {enabled} {
	if {$enabled} {
		show_samplerate
	} else {
		hide_samplerate
	}
}

proc show_samplerate {} {
	pack [menubutton .samplerate  -textvariable jack_sampling_rate_string  -font font_mono  -relief flat]  -side left
	# Lastly, start its updates running:
	every 1000 {set ::jack_sampling_rate_string "[jack samplerate] Hz"}

}

proc hide_samplerate {} {
	destroy .samplerate
}

