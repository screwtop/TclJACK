#!/usr/bin/wish

# Just a scratchpad/mock-up JACK transport control panel to go in the systray.
# Basic elements:
# - A button to invoke the JACK control menu, with port connection management, status info, etc.
# - Transport controls (play, stop, rewind, etc.)
# - JACK timecode display
# - Audio level meters (1, 2, or n?)

# Changing the colours of the transport buttons to indicate current state might be nice.
# Right-click menu to toggle the main UI elements in case of limited space (esp. likely when docked in systray).
# What sort of update rate for the timecode?  And meters?  10, 15, 30, 60 FPS?
# Sampling rate display also?  Could be useful if you tend to switch around a lot.


# TODO: monospaced font for transport button glyphs and time display.
font create font_mono -family lucidatypewriter -size -11
#font create font_sans -family Helvetica -size -12
font create font_sans -family cure -size -10	;# About as small as it gets.
#option add *font font_sans


. config -bg darkgrey

# Should these all be called X_frame?

# For the JACK control menu button:
frame .menubutton -bg white

# For the transport control panel buttons:
frame .transport -bg grey

# For the timecode display:
frame .timecode -bg blue

# For sampling rate display:
frame .samplerate -bg yellow

# For CPU DSP % utilisation (load) display:
frame .load -bg red

# For audio signal level indicator meter gauges:
frame .meters -bg green



# Play, Stop, Pause (Stop is really Pause), Record? (only applicable to clients that do recording; not global), Start, End ?? (special cases of Locate)
button .transport.start -text {|<} -command {puts start} -font font_mono
button .transport.rew   -text {<<} -command {puts rew}   -font font_mono
#button .transport.stop  -text {*} -command {puts stop}  -font font_mono
#button .transport.play  -text {>}  -command {puts play}  -font font_mono
button .transport.stop  -text {▪} -command {puts stop}  -font font_mono
button .transport.play  -text {▸}  -command {puts play}  -font font_mono
button .transport.pause -text {||} -command {puts pause} -font font_mono
button .transport.ffw   -text {>>} -command {puts ffw}   -font font_mono
button .transport.end   -text {>|} -command {puts end}   -font font_mono


# Place main UI frame elements on window:
# I think this is a logical order:
pack .menubutton .transport .timecode .samplerate .load .meters -side left

# Pack transport control buttons in their frame:
pack .transport.start .transport.rew .transport.stop .transport.play .transport.pause .transport.ffw .transport.end -side left

# Hmm, we'll be wanting a timecode display as well (hh:mm:ss, bars and beats, etc.)
# ...and tempo controls?

# Timecode display could be menu-button, with menu items showing the time in the other measurements.  Selecting one would then change the main display's measurement!  Nifty.
pack [menubutton .timecode.displaybutton  -text "00:00:00.000"  -menu .timecode.displaybutton.menu  -font font_mono  -relief groove]

menu .timecode.displaybutton.menu
	.timecode.displaybutton.menu add command -label {00:00:00.000}
	.timecode.displaybutton.menu add command -label {Bars and Beats}
	.timecode.displaybutton.menu add command -label {Frames (Samples)}
	.timecode.displaybutton.menu add command -label {SMPTE}
#	.timecode.menu add separator

# Maybe this should be a label, if there's no actual menu attached.
pack [menubutton .load.displaybutton  -text " 2.35%"  -font font_mono  -relief flat]

