# JACK control panel element for monitoring the CPU DSP load percentage.

set jack_cpu_load_string {?}

proc set_cpuload_visibility {enabled} {
	if {$enabled} {
		show_cpuload
	} else {
		hide_cpuload
	}
}

proc show_cpuload {} {
	# Can we set a format property to control how the textvariable is displayed?
	pack [menubutton .cpuload  -textvariable jack_cpu_load_string  -font font_mono  -relief flat]  -side left
	# Lastly, start its updates running:
	every 1000 {set ::jack_cpu_load_string "[format {%5.1f} [jack cpuload]]%"}

}

proc hide_cpuload {} {
	destroy .cpuload
}

