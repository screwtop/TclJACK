proc messagebox {title message} {
	# TODO: actually create new toplevel window!

	toplevel .dialog
	wm title .dialog $title

	pack [label .dialog.message -text $message] -side top -expand true -fill both -padx 8 -pady 8

	pack [button .dialog.ok_button -text OK -command {destroy .dialog}] -side bottom -expand false -fill x -padx 8 -pady 8
	pack [frame .dialog.separator -height 2 -relief sunken] -side bottom -fill x

	puts "<<\n$message\n>>"

	focus .dialog.ok_button

	wm protocol .dialog WM_DELETE_WINDOW {destroy .dialog}
}




proc about {} {
	# TODO: store version number somewhere separately and slurp it in.
	set about_message "$::application_name version $::major_version.$::minor_version\n($::last_modified)\n\nA utility for the JACK Audio Connection Kit on Linux\nPart of TclJACK\n\n(C) 2009 Chris Edwards"
#	puts $about_message
	messagebox {About JACKManager} $about_message
#	tk_messageBox -title {About JACKManager} -message $about_message -icon info -type ok
	# -detail {blah blah blah} ... may be a recent addition to Tk.
	# If the message box has no (known) path, how do we go about setting its minimum size?
}

