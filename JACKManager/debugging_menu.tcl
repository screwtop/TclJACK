	# Optional debugging menu (mainly trying to suss out some WM interactions)

	.application_menu add separator
	.application_menu add cascade -menu [menu .application_menu.debugging_menu] -label {Debugging}
		.application_menu.debugging_menu add command -label {JACK port list} -command {
			foreach port [jack ports] {
				puts $port
				puts "\t[jack portflags $port]"
				puts "\t[jack porttype $port]"
			}
		}
		# TODO: make disconnecting halt the display updates (which will fail if not connected, of course).
		.application_menu.debugging_menu add command -label {JACK Disconnect} -command {jack deregister}
		.application_menu.debugging_menu add command -label {JACK Reconnect} -command {jack register}

		.application_menu.debugging_menu add command -label {info procs} -command {puts [info procs]}
		.application_menu.debugging_menu add command -label {info vars} -command {puts [info vars]}
		.application_menu.debugging_menu add command -label {info patchlevel} -command {puts [info patchlevel]}

		# The following is for troubleshooting resizing behaviour when showing/hiding items in the layout grid inside Ion3's statusbar systray:
		.application_menu.debugging_menu add command -label {Query Window Geometry} -command {puts [wm geometry .]}
		.application_menu.debugging_menu add command -label {Query Window minsize} -command {puts [wm minsize .]}
		.application_menu.debugging_menu add command -label {Set Window minsize} -command {puts [wm minsize . [winfo width .] [winfo height .]]}
		.application_menu.debugging_menu add command -label {Reinit Window} -command {wm withdraw .; wm deiconify .}
		.application_menu.debugging_menu add command -label {Reset Window Title} -command {puts [wm title . {JACKManager}]}
		.application_menu.debugging_menu add command -label {overrideredirect on} -command {wm overrideredirect . 1}
		.application_menu.debugging_menu add command -label {overrideredirect off} -command {wm overrideredirect . 0}

		.application_menu.debugging_menu add command -label {Deiconify} -command {wm deiconify .}
		.application_menu.debugging_menu add command -label {Float Window} -command {float}
		.application_menu.debugging_menu add command -label {Dock Window} -command {dock}
		.application_menu.debugging_menu add command -label {wm frame .} -command {puts [wm frame .]}



