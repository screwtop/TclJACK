# JACKManager control panel element for monitoring the CPU DSP load percentage.

set jack_cpu_load_string {?}

proc set_cpuload_visibility {enabled} {
	if {$enabled} {
		show_cpuload
	} else {
		hide_cpuload
	}
}

proc create_cpuload {} {
	# Can we set a format property to control how the textvariable is displayed?
	menubutton .cpuload  -textvariable jack_cpu_load_string  -font font_mono  -relief flat

	# Lastly, start its updates running:
	every 1000 {set ::jack_cpu_load_string "[format {%5.1f} [jack cpuload]]%"}
}

proc destroy_cpuload {} {destroy .cpuload}

proc show_cpuload {} {grid .cpuload -row 0 -column 4}

proc hide_cpuload {} {grid forget .cpuload}

