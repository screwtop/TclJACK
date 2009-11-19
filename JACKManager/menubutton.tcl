# JACKManager control panel element for monitoring the main JACK menu (as a menubutton).
# We probably don't really need this to be hideable, but for completeness...

proc set_menubutton_visibility {enabled} {
	if {$enabled} {
		show_menubutton
	} else {
		hide_menubutton
	}
}

proc create_menubutton {} {
	global application_name
	# Main menu button:
	menubutton .menubutton  -text "JACK"  -menu .menubutton.menu  -relief groove
	setTooltip .menubutton {JACKManager menu button}
	menu .menubutton.menu
		.menubutton.menu add command -label $application_name -background grey
		.menubutton.menu add separator
		# ... TODO: copy other stuff from DeskNerd's jack.tcl
}

proc destroy_menubutton {} {destroy .menubutton}

proc show_menubutton {} {grid .menubutton -row 0 -column 0}

proc hide_menubutton {} {grid forget .menubutton}

