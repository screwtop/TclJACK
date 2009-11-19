# Control panel for JACKManager transport buttons.

# (This was the first of the components that I separated off into another source file, so there are some comments here which are useful from an historical perspective.)


# We don't just blindly toggle the component display; we have a display_transport_component variable which is set by the menu-checkbox-item which we can read and act accordingly.
proc set_transport_visibility {enabled} {
#	global display_transport_component
	if {$enabled} {
		show_transport
	} else {
		hide_transport	
	}
}


# Should this be parameterised for parent frame, or do we just hard-code it and always assume the transport buttons frame will be at a particular path in the widget tree?  For destroying, it would be easier to just hard-code the location.

proc create_transport {} {
	# First create the frame for the button panel:
	frame .transport -bg black
#	pack [frame .transport -bg black] -side left
	
	# Now the buttons themselves:

	# Play, Stop, Pause (Stop is really Pause), Record? (only applicable to clients that do recording; not global), Start, End ?? (special cases of Locate)
	# Unicode characters for button labels?  Uniform spacing might be more important (plus Unicode has a conspicuous lack of these common characters, AFAICT).
	button .transport.start -text {|<} -command {puts start} -font font_mono
	button .transport.rew   -text {<<} -command {puts rew}   -font font_mono
	button .transport.stop  -text {[]} -command {puts stop}  -font font_mono
	button .transport.play  -text { >}  -command {puts play}  -font font_mono
	#button .transport.stop  -text {▪} -command {puts stop}  -font font_mono
	#button .transport.play  -text {▸}  -command {puts play}  -font font_mono
	button .transport.pause -text {||} -command {puts pause} -font font_mono
	button .transport.ffw   -text {>>} -command {puts ffw}   -font font_mono
	button .transport.end   -text {>|} -command {puts end}   -font font_mono
	
	# Pack transport control buttons in their frame:
	pack .transport.start .transport.rew .transport.stop .transport.play .transport.pause .transport.ffw .transport.end -side left
}

proc destroy_transport {} {destroy .transport}

proc show_transport {} {grid .transport -row 0 -column 1}

proc hide_transport {} {grid forget .transport}


# REW and FFW buttons are special, in that they need to start responding on button down, and keep going while the button is held down.
# It may be worth considering having the others respond to press rather than release, as IIRC Ardour's transport buttons do.  This is for faster response, I presume.


