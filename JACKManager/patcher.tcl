# Matrix patchbay component for the TclJACK JACKManager utility.


# TODO:
# [ ] Distinguish various port types, e.g. hardware/software, inputs/outputs, etc. clearly separated, maybe in a different colour.  Hardware I/Os first in the list, perhaps with a gap separating them from the others.  Perhaps a red/orange warning colour for the cell that would connect a client's outputs to its own inputs (feedback warning).  Also, clients with no output and/or input ports could be greyed out somewhat/somehow.
# [Y] Tooltips
# [ ] Integrate into TclJACK (use button on main panel or menu?)
# [ ] Column labels
# [ ] Grouping (and expand/contract) by client
# [ ] Separate section for MIDI ports?
# [ ] Icons for ports (indicate type)




# Bah, initial uppercase letter is not valid as a Tk window (widget) identifier.
# I guess dashes are also disallowed...

proc sanitise {identifier} {
	return [string map {{ } _  - _  . _ [ _ ] _} [string tolower $identifier]]
}



# Set up port-to-port connection toggling for the specified button and ports:
# Maybe this should even create the button?
proc create_toggle {button source_port target_port} {
	set ::source_port($button) $source_port
	set ::target_port($button) $target_port
	set ::state($button) 0	;# TODO: initialise the state correctly!
	$button configure -command "toggle $button"
	$button configure -cursor dotbox
}


# Potential problems here:
#  - Connection could already exist, but we don't know it.  At least try to set the initial state of a port-to-port connection correctly (in create_toggle, probably).
#  - State of a connection could have been changed by another program.  We should watch these (JACK callback) and update accordingly
proc toggle {button} {
	if {$::state($button) == 0} {
	#	puts "$button: $::source_port($button) -> $::target_port($button)"
		if {![catch {jack connect $::source_port($button) $::target_port($button)}]} {
			$button configure -relief sunken -background blue
		}
	} else {
	#	puts "$button: $::source_port($button) X> $::target_port($button)"
		if {![catch {jack disconnect $::source_port($button) $::target_port($button)}]} {
			$button configure -relief raised -background gray
		}
	}
	set ::state($button) [expr {!$::state($button)}]
}


# Same create/show/hide/destroy life cycle as for the panel components?
# wm withdraw .patcher
# wm deiconify .patcher



# TODO: maybe rename this (et al.) create_patcher_window

proc create_patcher_window {} {
	toplevel .patcher

	set capture_ports [list]
	foreach port [jack ports] {
		if {[lsearch [jack portflags $port] output] == 0} {
			lappend capture_ports $port
		}
	}


	set playback_ports [list]
	foreach port [jack ports] {
		if {[lsearch [jack portflags $port] input] == 0} {
			lappend playback_ports $port
		}
	}


	# TODO: column heading labels

	set row 1
	foreach capture_port $capture_ports {
	#	set capture_port [sanitise $capture_port]
	#	puts $capture_port
		set column 1

		label ".patcher.[sanitise $capture_port]" -text "$capture_port"
		grid ".patcher.[sanitise $capture_port]" -row $row -column $column
		incr column

		foreach playback_port $playback_ports {
		#	set playback_port [sanitise $playback_port]
		#	puts " -> $playback_port"

			# Yay, this doesn't make for invalid widget identifiers!
			set button_name ".patcher.[sanitise ${capture_port}]->[sanitise ${playback_port}]"

			# Set up functionality for each button in the matrix.
			# TODO: set up initial button state according to existing connections.
			button $button_name -command "jack connect $capture_port $playback_port"
			setTooltip $button_name "$capture_port -> $playback_port"
			create_toggle $button_name $capture_port $playback_port
			grid $button_name -row $row -column $column
			incr column
		}
		incr row
	}

}

proc destroy_patcher_window {} {destroy .patcher}



# Routines for setting up the button to toggle the patchbay window:

proc create_patcher {} {
	set ::patcher_window_enabled 0
	button .patcher_button -text Patch -relief flat -borderwidth 0 -command {
		set ::patcher_window_enabled [expr {!$::patcher_window_enabled}]	;# i.e. toggle
		if {$::patcher_window_enabled == 1} {
			create_patcher_window
		} else {
			destroy_patcher_window
		}
	}

	# Not sure whether to use a checkbutton or a customised plain button.
#	checkbutton .patcher_button -text Patch -command {
#		if {$patcher_button == 1} {
#			create_patcher_window
#		} else {
#			destroy_patcher_window
#		}
#	}
	setTooltip .patcher_button {Toggle matrix patchbay window}
}

proc show_patcher {} {grid .patcher_button -row 0 -column 4}

proc hide_patcher {} {grid forget .patcher_button}

proc destroy_patcher {} {destroy .patcher_button}


proc set_patcher_visibility {enabled} {
	if {$enabled} {
		show_patcher
	} else {
		hide_patcher
	}
}

