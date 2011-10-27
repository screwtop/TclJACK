# Some routines for managing JACK port-to-port connections.

# Would ports be identified simply by name, or by a <client_name, port_name> tuple?
# Since we can only connect ports of clients of the same JACK server, we don't need to worry about qualifying the names further with the server name (I think).
# TODO: switch to using TclJACK functionality (when implemented) instead of relying on the external jack_connect system command.
# TODO: figure out quoting issues.  JACK port names may contain spaces, colons, square brackets, ...  What kind of quotation marks to use in the [open] command?
# Literal port names containing "[]$" etc will obviously need to be escaped or written in curly braces for Tcl.
# TODO: error handling?
# <<ERROR b not a valid port>>
# <<child process exited abnormally>>
# Also, watch for naming conflicts here if in a Tcl environment that will try to call system command as well ("jack_connect" == "jack_connect"!).
proc jack_connect {source_port sink_port} {
	set input [open "|jack_connect \"$source_port\" \"$sink_port\"" r]
	set content [split [read $input] \n]
	close $input
	puts $content
	# TODO: return something useful?
}


# And similarly for disconnecting:
proc jack_disconnect {source_port sink_port} {
	set input [open "|jack_disconnect \"$source_port\" \"$sink_port\"" r]
	set content [split [read $input] \n]
	close $input
	puts $content
	# TODO: return something useful?
}
# Could imagine doing jack_disconnect with pattern matching to avoid having to look up and list the sink port name(s) for example.

