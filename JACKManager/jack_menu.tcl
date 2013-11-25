#!/usr/bin/expectk

# A basic JACK Audio Connection Kit control systray utility for DeskNerd.
# Will provide a popup menu (or menus) for managing port connections, viewing JACK process status info, etc.  See Documentation/Development/JACK.txt for design details.
# Actually, it might be easier to make calls to jacklib directly.  Not something I've set up for Tcl before, but AFAICT it should be fairly straightforward.  See the separate TclJACK project.

# TODO: having Tcl's pattern matching and list handling will enable some nice features, I think:
# [ ] Connecting all ports for a client to another client (mapping 1:1).
# [ ] Disconnecting all MPlayer instances (mplayer includes the PID in its JACK client name, but we can do a pattern match).
# [ ] Disconnecting all output ports for a client.
# ...
# [ ] Perhaps most significantly, we can choose a playback port that we want to monitor (e.g. system:playback_1 and 2 for the main soundcard outputs), query to find all JACK output ports that connect to it, and connect those to this program, so it will display the effective output signal of the entire system!  I'd wondered how I was going to do that.


# We're going to be using expect features, to run expectk, not wish.
# Note also that expect ofter lags a bit; we have Tcl 8.4 for expect ATM, but 8.5 otherwise.

# TODO: implement a timer loop to keep the stats up-to-date (once a second?), and another (once every 1/n s) for updating the level meter gauge.  Could adapt the following:
#proc every {ms body} {eval $body; after $ms [info level 0]}
#set nmax 3
#every 1000 {puts hello; if {[incr ::nmax -1]<=0} return}


wm title . {DeskNerd_JACK}
set application_name {DeskNerd JACK Audio Manager}

# Woohoo, we now have some (very basic) functionality in TclJACK!
load /home/cedwards/Documents/Projects/TclJACK/libtcljack.so
jack_register

source {Preferences.tcl}
option add *TearOff 1	;# Could be useful to put menus for certain frequency-accessed ports in a tear-off window (probably only if we have a submenu for each client).  Would need to name the tear-offs sensibly.
. configure -background $statusbar_background_colour



# The main popup menu:
pack [menubutton .jack  -text "JACK"  -menu .jack.menu  -relief groove]

# Program management menu on right-click:
menu .popup_menu
	# TODO: $application_name
	.popup_menu add command -label {Connect to JACK}       -command {jack_register}
	.popup_menu add command -label {Disconnect from JACK}  -command {jack_deregister}
	.popup_menu add command -label {Close}                 -command {jack_deregister; exit}
bind . <3> "tk_popup .popup_menu %X %Y"



# Main menu:
# Much of this is just mock-up at present.
# Would be kinda nice to be able to use textvariable with menu items, but I don't think it's supported.
# TODO: Will need some kind of timer to update the info/status items while the menu is open.
# TODO: add menu items to allow choosing which ports to monitor.  Could even be output ports (we'd look for all the source ports connected to the output port and attach those to the monitor).
menu .jack.menu
	# Program label menu item first:
	.jack.menu add command -label $application_name -background grey
	.jack.menu add separator
	# Then any info/status non-interactive items:
	.jack.menu add command -label "CPU DSP load: [jack_cpuload] %" -command {.jack.menu entryconfigure 3 -label "CPU DSP load: [jack_cpuload] %"}
	.jack.menu add command -label "Sampling Rate: [jack_samplerate] Hz"
	.jack.menu add command -label {Period Size: ?? frames}
	.jack.menu add command -label {Periods/Buffer: ??}
	# Normal commands:
	.jack.menu add separator
	.jack.menu add command -label {Refresh Ports}
	.jack.menu add separator
	# Output (source) ports first, I think:
	# TODO: gonna hafta figure out some port name munging to enable them to be used as Tk widget names.
	.jack.menu add cascade -label {system:capture_1 ->}  -menu .jack.menu.sink_ports
	.jack.menu add cascade -label {system:capture_2 ->}  -menu .jack.menu.sink_ports
	# TODO: Separator after system ports, perhaps?
	.jack.menu add cascade -label {MPlayer [32479]:out_0 ->}  -menu .jack.menu.sink_ports 
	.jack.menu add cascade -label {MPlayer [32479]:out_1 ->}  -menu .jack.menu.sink_ports 
	# Input (sink/target) ports:
	# NOTE: terminal sink ports (which are usually also physical) should not appear in this menu (or at least should not have submenus).
	.jack.menu add separator
	.jack.menu add cascade -label {system:playback_1 <-}  -menu .jack.menu.source_ports
	.jack.menu add cascade -label {system:playback_2 <-}  -menu .jack.menu.source_ports
#	.jack.menu add separator
	.jack.menu add cascade -label {jkmeter:in-1 <-}  -menu .jack.menu.source_ports
	.jack.menu add cascade -label {jkmeter:in-2 <-}  -menu .jack.menu.source_ports
	# Some testing items:
	.jack.menu add separator
	.jack.menu add command -label "List Ports to Console" -command {puts [get_jack_port_list]}



# Preliminary mocked-up submenus for making/checking JACK port connections.
# Submenu for output (source/out) ports:
# TODO: this will have to be programmatically generated.
# It will be interesting to see how unwiendly this becomes with clients with many ports (such as Ardour) connected.  I think we'll have to add another level of menus, so you'd have client_x:source_ports:sink_ports and client_x:sink_ports:source_ports.
# Maybe we don't even need both ways of looking at it: ergonomically, you'd usually have a source, which you find, and then go looking for where you want to send it.  But there may be situations where you'd start with the sink port and then go looking for a source (for setting up a track for recording in Ardour, for example).
# TODO: try using checkbutton instead of plain command for these (perhaps use colour and bold as well).
menu .jack.menu.source_ports
	.jack.menu.source_ports add command -label {system:capture_1}
	.jack.menu.source_ports add command -label {system:capture_2}
	# TODO: Separator after system ports, perhaps?
	.jack.menu.source_ports add separator
	.jack.menu.source_ports add command -label {MPlayer [32479]:out_0}
	.jack.menu.source_ports add command -label {MPlayer [32479]:out_1}
	.jack.menu.source_ports add separator
	.jack.menu.source_ports add command -label {Disconnect All}

menu .jack.menu.sink_ports
	.jack.menu.sink_ports add command -label {system:playback_1}
	.jack.menu.sink_ports add command -label {system:playback_2}
	.jack.menu.sink_ports add separator
	.jack.menu.sink_ports add command -label {jkmeter:in-1}
	.jack.menu.sink_ports add command -label {jkmeter:in-2}
	.jack.menu.sink_ports add separator
	.jack.menu.sink_ports add command -label {Disconnect All}




# Various procedures to gather JACK state data through the jack_* commands.

# Get a list of JACK ports.  All ports, or have separate procs for playback and capture ports?  Might be nice to only call jack_lsp once and gather as much information as possible, for efficiency (assuming starting new process is more expensive than piping and processing a little more text).
# TODO: decommission this, as it should be provided by the TclJACK C library.  Ditto for jack_connect and jack_disconnect.
proc get_jack_port_list {} {
	# Run the jack_lsp command to get port information...
	# Might as well use expect for this, I think.
	log_user 0
#	spawn jack_lsp
	spawn jack_lsp -A -L -l -p -c
	while true {
		# On naming of JACK ports:
		# I assume colons are not allowed in JACK client or port names (only as the separator between these).
		# Spaces are allowed (mplayer uses them by default).  Are leading or trailing spaces permitted?  I'll assume not.
		# Are tabs permitted in client/port names?
		# Are leading digits permitted in client/port names?

		# Expect will of course slurp in as much text as possible, so we need to explicitly match line-break characters here.
		expect {
			# Whooph, regular expressions!
			# Hmm, the very first port listed will not be preceded by a newline, but every other one will.  Pain.
			-re {[\r\n]*([^\t \r\n][^:]+):([^\r\n]+)} {
			#	puts "<<$expect_out(0,string)>>"	;# For debugging the pattern matching.
				set jack_subsystem_name $expect_out(1,string)
				set jack_port_name $expect_out(2,string)
				puts "Found port '$jack_subsystem_name' '$jack_port_name'"
				# The port may have additional data, so do another expect here:
				# Boh, it might be easier to do all the pattern matching at the same level.  Maybe line-based processing would be easier after all...
			}
					-re {[\r\n]+   ([^\r\n:]+):([^\r\n]+)} {puts " -> alias: '$expect_out(1,string)' '$expect_out(2,string)'"}
					-re {	port latency = ([0-9]+) frames} {puts " -> port latency: $expect_out(1,string)"}
					-re {	total latency = ([0-9]+) frames} {puts " -> total latency: $expect_out(1,string)"}
					# Is it possible for a port to have no properties?  If so, would jack_lsp emit a "properties:" line at all?
					-re {	properties: ([^\r\n]+)} {puts " -> total latency: $expect_out(1,string)"}



				#	-re {[\r\n]+	([^\r\n:]+):([^\r\n]+)} {
				#		puts " -> other property: $expect_out(0,string)"
						# And if we found a "properties" list, gather the individual property values:
				#	}
			eof {break}
		}

	}
	# Return a list?
}


# Maybe an easier one would be for connecting two JACK ports.
# Would ports be identified simply by name, or by a <client_name, port_name> tuple?
# Since we can only connect ports of clients of the same JACK server, we don't need to worry about qualifying the names further with the server name (I think).
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

