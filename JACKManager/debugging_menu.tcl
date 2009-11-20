	# Optional debugging menu (trying to suss out some WM interactions)

	.application_menu add separator
	.application_menu add cascade -menu [menu .application_menu.debugging_menu] -label {Debugging}
		# The following is for troubleshooting resizing behaviour when showing/hiding items in the layout grid inside Ion3's statusbar systray:
		.application_menu.debugging_menu add command -label {Query Window Geometry} -command {puts [wm geometry .]}
		.application_menu.debugging_menu add command -label {Query Window minsize} -command {puts [wm minsize .]}
		.application_menu.debugging_menu add command -label {Set Window minsize} -command {wm minsize . [winfo width .] [winfo height .]}
		.application_menu.debugging_menu add command -label {Reinit Window} -command {wm withdraw .; wm deiconify .}
		.application_menu.debugging_menu add command -label {Reset Window Title} -command {wm title . {JACKManager}}
		.application_menu.debugging_menu add command -label {Disengage overrideredirect} -command {wm overrideredirect . 0}
		.application_menu.debugging_menu add command -label {Deiconify} -command {wm deiconify .}

