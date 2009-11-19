#!/usr/bin/wish

# General JACK manager/control panel utility, suitable for popping in the desktop systray.
# (Started out as transport_mockup.tcl)

# Basic elements:
# - A button to invoke the JACK control menu, with port connection management, status info, etc.
# - Transport controls (play, stop, rewind, etc.)
# - JACK timecode display
# - Current sampling rate
# - Current CPU DSP load
# - Audio level meters (1, 2, or n?)
# - Tempo and time signature
# - XRUN count/alert

# Changing the colours of the transport buttons to indicate current state might be nice.
# Right-click menu to toggle the main UI elements in case of limited space (esp. likely when docked in systray).
# What sort of update rate for the timecode?  And meters?  10, 15, 30, 60 FPS?
# Sampling rate display also?  Could be useful if you tend to switch around a lot.
# Perhaps we could just have one JACK info panel, which could be set to display one of sampling rate, CPU load, server name, buffer configuration.  Are you likely to need to see more than one of these at a time?  Certainly having all displayed would take up a lot of space.

# TODO: figure out how to get Ion's systray layout to refresh when adding (and I guess removing) components.
# TODO: get the components to go back in the same order when showing/hiding!  Might have to switch to grid layout?
# TODO: merge in existing stuff from the DeskNerd JACK component (I think it belongs here more) in working towards the proper version of this.
# TODO: add an xrun counter or alert; perhaps another menubutton, showing the total xrun count, with popup menu items showing the log of recent xruns.  The button could flash red whenever an xrun occurs to alert the user.

set application_name {JACKManager}
wm title . $application_name

source Preferences.tcl

# Might as well actually connect to JACK, since we can...
load ../libtcljack.so
jack register

# Hmm, should probably define in one place what the external and internal names for the various components should be:
set panel_components {{"JACKManager" menubutton} {"Transport Controls" transport} {"Timecode Display" timecode} {"Sampling Rate" samplerate} {"CPU DSP Load" cpuload} {"Audio Meters" meters}}



# Initial config for which items should be available.
# TODO: some kind of persistence mechanism for these?  Or put them in Preferences.tcl?
# Perhaps just all on by default, so foreach $panel_components ...
set menubutton_component_enabled 1	;# Probably always want this!
set transport_component_enabled 1
set timecode_component_enabled 1
set cpuload_component_enabled 1
set samplerate_component_enabled 0
set meters_component_enabled 0


# Routine fro timed execution of specific code (used in updating the timecode display, CPU load, etc.).
# NOTE: If we use Jeff Hobbs's "every" package instead of the simple "every" proc below, we can start and stop these updating for efficiency (e.g. if not being displayed and if the information is otherwise not needed by this program).  TODO: implement.

proc every {ms body} {eval $body; after $ms [info level 0]}


# Set up the various control panel components according to the initial settings (or (TODO) user settings from last time):
foreach component $panel_components {
	set component_id [lindex $component 1]
	source ${component_id}.tcl
	create_${component_id}
	set_${component_id}_visibility [set ${component_id}_component_enabled]
}


# OK, now how about the context menu, with the ability to turn the various panel items on and off (use checkbox-menuitems).
# Can we attach event handlers to variables?  Kinda like database triggers?  So if $display_timecode_component is set to false, it just disappears?  menu checkbuttons can have -command and -variable specifiec; does the variable get set first, so the command can reliabliy use it its body?

destroy .application_menu
menu .application_menu
	# Set up a toggle menu item for each panel component:
	foreach component $panel_components {
		set component_label [lindex $component 0]
		set component_id [lindex $component 1]
		puts "$component_label -> $component_id"
		.application_menu add checkbutton -label $component_label -variable ${component_id}_component_enabled  -command "set_${component_id}_visibility \$${component_id}_component_enabled"
	}

	# The following is for troubleshooting resizing behaviour when showing/hiding items in the layout grid inside Ion3's statusbar systray:
	.application_menu add separator
	.application_menu add command -label {Query Window Geometry} -command {puts [wm geometry .]}

	# +Connect to/disconnect from JACK server
	#.application_menu add separator
	# ...

	# +Change JACK server (can we discover names of multiple JACK servers?)

	.application_menu add separator
	.application_menu add command -label {Close} -background orange -command {exit}
bind . <3> "tk_popup .application_menu %X %Y"


# Now onward to the event loop...

