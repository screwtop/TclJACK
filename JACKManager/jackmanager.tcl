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

# TODO: monospaced font for transport button glyphs and time display.
#font create font_mono -family fixed -size 6
#font create font_mono -family lucy -size 8
#font create font_mono -family lucidatypewriter -size -19
#font create font_sans -family Helvetica -size -12
#font create font_sans -family cure -size -10	;# About as small as it gets.
#option add *font font_sans


# Might as well actually connect to JACK, since we can...
load ../libtcljack.so
jack register

# Hmm, should probably define in one place what the external and internal names for the various components should be:
# set panel_components {{"Transport Controls" transport} {Timecode timecode} {"Sampling Rate" samplerate} {"CPU DSP Load" [cpu]load} {"Audio Meters" meters}}


# Initial config for which items should be available.
# TODO: some kind of persistence mechanism for these?  Or put them in Preferences.tcl?
# Perhaps just all on by default, so foreach $panel_components ...
set transport_component_enabled 1
set timecode_component_enabled 1
set cpuload_component_enabled 1
set samplerate_component_enabled 0

# Should these all be called X_frame?

# TODO: foreach $panel_components ...

# For the JACK control menu button:
# Actually, no need for a frame for this.
#frame .menubutton -bg white

# For the transport control panel buttons:
#frame .transport -bg black

# Actually, don't need frames for these either:
# For the timecode display:
#frame .timecode -bg blue

# For sampling rate display:
#frame .samplerate -bg yellow

# For CPU DSP % utilisation (load) display:
#frame .cpuload -bg red

# For audio signal level indicator meter gauges:
#frame .meters -bg black

proc every {ms body} {eval $body; after $ms [info level 0]}


# Main menu button:
pack [menubutton .menubutton  -text "JACK"  -menu .menubutton.menu  -relief groove] -side left
menu .menubutton.menu
	.menubutton.menu add command -label $application_name -background grey
	.menubutton.menu add separator
	# ... TODO: copy from DeskNerd's jack.tcl


# Get functionality for the various control panel components:
source transport.tcl
source timecode.tcl
source samplerate.tcl
source cpuload.tcl

# Set them up according to the initial settings (or (TODO) user settings from last time):
set_transport_visibility $transport_component_enabled

# Place main UI frame elements on window:
# I think this is a logical order:
#pack .menubutton .transport .timecode .samplerate .cpuload .meters -side left
# TODO: figure out a way to 

# Hmm, we'll be wanting a timecode display as well (hh:mm:ss, bars and beats, etc.)
# ...and tempo controls?


# Maybe this should be a label, if there's no actual menu attached.  Then we can use a textvariable.  No, can use with menubutton.  Plus using menubutton ensures consistent widget heights.
#pack [menubutton .cpuload.displaybutton  -text " 2.35%"  -font font_mono  -relief flat]
#set jack_cpu_load_string {?}
# Can we set a format property to control how the textvariable is displayed?
#pack [menubutton .cpuload  -textvariable jack_cpu_load_string  -font font_mono  -relief flat]


# Sampling rate display:
#set jack_sampling_rate {?}
#pack [menubutton .samplerate.display  -textvariable jack_sampling_rate  -font font_mono  -relief flat]


# OK, now how about the context menu, with the ability to turn the various panel items on and off (use checkbox-menuitems).
# Can we attach event handlers to variables?  Kinda like database triggers?  So if $display_timecode_component is set to false, it just disappears?  menu checkbuttons can have -command and -variable specifiec; does the variable get set first, so the command can reliabliy use it its body?

menu .application_menu
	# TODO: foreach ... $panel_components ... {.application_menu add checkbutton ...}
	.application_menu add checkbutton -label {Transport Controls} -variable transport_component_enabled  -command {set_transport_visibility $transport_component_enabled}
	.application_menu add checkbutton -label {Timecode Display} -variable timecode_component_enabled  -command {set_timecode_visibility $timecode_component_enabled}	;# Or "Timecode Clock" or "Clock" or "Clock Display"?
	.application_menu add checkbutton -label {Sampling Rate} -variable samplerate_component_enabled  -command {set_samplerate_visibility $samplerate_component_enabled}
	.application_menu add checkbutton -label {CPU DSP Load} -variable cpuload_component_enabled  -command {set_cpuload_visibility $cpuload_component_enabled}
	.application_menu add checkbutton -label {Audio Meters} -variable display_meters_component  -command {puts {Audio Meters element toggled}}
	# +Connect to/disconnect from JACK server
	#.application_menu add separator
	# ...
	# +Change JACK server (can we discover names of multiple JACK servers?)
	.application_menu add separator
	.application_menu add command -label {Close} -background orange -command {exit}
bind . <3> "tk_popup .application_menu %X %Y"


# Set the displayed items updating:

# NOTE: If we use Jeff Hobbs's "every" package, we can start and stop these updating for efficiency (e.g. if not being displayed and if the information is otherwise not needed by this program).  TODO: implement.

# Simple procedure for timed execution of arbitrary code:
#proc every {ms body} {eval $body; after $ms [info level 0]}


# Now now done inside the show procs for the respective components:
#every 1000 {set ::jack_cpu_load_string [format {%5.1f} [jack cpuload]]%}
#every 1000 {set ::jack_sampling_rate [jack samplerate]}

