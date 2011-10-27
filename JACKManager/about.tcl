proc about {} {
	# TODO: store version number somewhere separately and slurp it in.
	set about_message "$::application_name version $::major_version.$::minor_version ($::last_modified)\nA utility for the JACK Audio Connection Kit on Linux\nPart of TclJACK\n(C) 2009 Chris Edwards"
	puts $about_message
	tk_messageBox -title {About JACKManager} -message $about_message -icon info -type ok
	# -detail {blah blah blah} ... may be a recent addition to Tk.
	# If the message box has no (known) path, how do we go about setting its minimum size?
}

