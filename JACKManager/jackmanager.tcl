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

# Does ~/.wishrc not get sourced when executing the script directly?
set auto_path [lappend auto_path /usr/local/lib/tcl8.5/tcljack]

#wm withdraw .	;# Hide the window initially, until everything is set up

set application_name {JACKManager}
set about_text "JACKManager, a Tcl/Tk-based control panel for the JACK Audio Connection Kit\n©2009, 2010 Chris Edwards"

wm title . $application_name

# Temporarily remove the window from being managed by the WM, so that the initial window geometry will be unaffected by the window manager (e.g. Ion).
wm overrideredirect . 1
#wm transient .

# TODO: move standard location to ~/.jackmanager/Preferences.tcl or somewhere.  Maybe have a split system/user preferences scheme.
source Preferences.tcl

# Routine for timed execution of specific code (used in updating the timecode display, CPU load, etc.).
# NOTE: If we use Jeff Hobbs's "every" package instead of the simple "every" proc below, we can start and stop these updating for efficiency (e.g. if not being displayed and if the information is otherwise not needed by this program).  NOTE: even if you destroy the component being updated with destroy_<component>, the [every] persists!  TODO: implement.
# proc every {ms body} {eval $body; after $ms [info level 0]}
# Now using DKF's one, which returns an "every ID" so you can cancel them at will (needed for FFW/REW transport functionality).
source every.tcl
source anticlip.tcl	;# Used in transport.tcl
source tooltips.tcl	;# Tooltips/balloon-help implementation.

# JACKManager components split into separate files:
source version.tcl
#source settings_jack.tcl	;# Not ready yet.
source about.tcl


puts $about_text
puts "\nRunning on Tcl/Tk version [info tclversion]"


# Might as well actually connect to JACK, since we can...
# TODO: implement a proper Tcl package wrapper for the binary, and change this to use [package require].
#load ../libtcljack.so
package require TclJACK
jack register

# Hmm, should probably define in one place what the external and internal names for the various components should be:
# TODO: make the ordering here and the grid -column specifiers in the individual component files less fragile.  Perhaps a third "attribute" for which column of the grid the component should be in?  Do we want to allow them to be rearranged?
set panel_components {
	{"Main Menu Button"   menubutton}
	{"Transport Controls" transport}
	{"Timecode Display"   timecode}
	{"Sampling Rate"      samplerate}
	{"CPU DSP Load"       cpuload}
	{"Audio Meters"       meters}
	{"MIDI Activity Indicator"	midi_activity_indicator}
}
# Maybe put the audio meters after the timecode?  It's more important than Fs and CPU meters.


# Initial config for which items should be available.
# TODO: some kind of persistence mechanism for these?  Or put them in Preferences.tcl?
# Perhaps just all on by default, so foreach $panel_components ...
set menubutton_component_enabled 1	;# Probably always want this!
set transport_component_enabled 1
set timecode_component_enabled 1
set cpuload_component_enabled 1
set samplerate_component_enabled 1
set meters_component_enabled 1
set midi_activity_indicator_component_enabled 1



# Set up the various control panel components according to the initial settings (or (TODO) user settings from last time):
foreach component $panel_components {
	set component_id [lindex $component 1]
	source ${component_id}.tcl
	create_${component_id}
	set_${component_id}_visibility [set ${component_id}_component_enabled]
}



# OK, now how about the context menu, with the ability to turn the various panel items on and off (use checkbox-menuitems).
# Can we attach event handlers to variables?  Kinda like database triggers?  So if $display_timecode_component is set to false, it just disappears?  menu checkbuttons can have -command and -variable specifiec; does the variable get set first, so the command can reliabliy use it its body?

menu .application_menu
	# Set up a toggle menu item for each panel component:
	foreach component $panel_components {
		set component_label [lindex $component 0]
		set component_id [lindex $component 1]
		.application_menu add checkbutton -label $component_label -variable ${component_id}_component_enabled  -command "set_${component_id}_visibility \$${component_id}_component_enabled"
	}

	# +Connect to/disconnect from JACK server
	#.application_menu add separator
	# ...

	# +Change JACK server (can we discover names of multiple JACK servers?)

	# Optional debugging menu:
	source debugging_menu.tcl

	.application_menu add separator
	.application_menu add command -label {Close} -background orange -command {jack deregister; exit}
bind . <3> "tk_popup .application_menu %X %Y"



# For floating window mode, give the background a suitable cursor
source floating.tcl
float


# In order to get proper layout inside Ion's statusbar, we have to set the minimum window size.
# Ideally we would somehow use winfo to figure out what the size should be; normally Tk would do this itself but the initial window geometry is constrained by Ion's tiling.  I'm not sure if you can remove the window from the wm management early enough to avoid this.
#puts [wm geometry .]
#wm minsize . 300 32
# Depending on the timing, it may be necessary to toggle the window's visibility to get Ion to recognise and grab it into the systray.
#wm withdraw .	;# Maybe this could go at the beginning of this script.
#wm deiconify .
#puts [wm geometry .]
# Ah, need a delay (not sure how much or how reliable this is) to allow Tk to enter event loop and have window set up before querying window geometry.

#after 10 {
#	puts [wm geometry .]
#	wm minsize . [winfo width .] [winfo height .]
#	puts [wm minsize .]
#	wm overrideredirect . 0
#	wm withdraw .; wm deiconify .
#}

# I suspect we'll need to do something like that after every show/hide of a panel component, to get Ion to register the window size change.  Not sure if it'll take over the window sizing itself also!


# Now onward to the event loop...

