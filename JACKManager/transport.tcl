# Control panel for JACK transport buttons.

# If the entire panel has to be able to be turned on and off (the closest I can find to toggling visibility), I guess we need to create the parent frame (containing all the buttons) here as well.

# "show" and "hide", or "create" and "destroy"?


# We don't just blindly toggle the component display; we have a display_transport_component variable which is set by the menu-checkbox-item which we can read and act accordingly.
proc set_transport_visibility {enabled} {
#	global display_transport_component
	if {$enabled} {
		show_transport_frame
	} else {
		hide_transport_frame	
	}
}


# Should this be parameterised for parent frame, or do we just hard-code it and always assume the transport buttons frame will be at a particular path in the widget tree?  For destroying, it would be easier to just hard-code the location.

proc show_transport_frame {} {
	# First create the frame for the button panel:
	pack [frame .transport -bg black] -side left
	
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



proc hide_transport_frame {} {
	destroy .transport
}

# REW and FFW buttons are special, in that they need to start responding on button down, and keep going while the button is held down.
# It may be worth considering having the others respond to press rather than release, as IIRC Ardour's transport buttons do.  This is for faster response, I presume.



# -------


proc UNUSED_PARAMETERISED_show_transport_frame {parent_frame} {
	# First create the frame for the button panel:
	pack [frame ${parent_frame}.transport -bg black] -side left
	
	if {$parent_frame == "."} {set parent_frame ""}

	# Now the buttons themselves:

	# Play, Stop, Pause (Stop is really Pause), Record? (only applicable to clients that do recording; not global), Start, End ?? (special cases of Locate)
	# Unicode characters for button labels?  Uniform spacing might be more important (plus Unicode has a conspicuous lack of these common characters, AFAICT).
	button ${parent_frame}.transport.start -text {|<} -command {puts start} -font font_mono
	button ${parent_frame}.transport.rew   -text {<<} -command {puts rew}   -font font_mono
	button ${parent_frame}.transport.stop  -text {[]} -command {puts stop}  -font font_mono
	button ${parent_frame}.transport.play  -text { >}  -command {puts play}  -font font_mono
	#button ${parent_frame}.transport.stop  -text {▪} -command {puts stop}  -font font_mono
	#button ${parent_frame}.transport.play  -text {▸}  -command {puts play}  -font font_mono
	button ${parent_frame}.transport.pause -text {||} -command {puts pause} -font font_mono
	button ${parent_frame}.transport.ffw   -text {>>} -command {puts ffw}   -font font_mono
	button ${parent_frame}.transport.end   -text {>|} -command {puts end}   -font font_mono
	
	# Pack transport control buttons in their frame:
	pack ${parent_frame}.transport.start ${parent_frame}.transport.rew ${parent_frame}.transport.stop ${parent_frame}.transport.play ${parent_frame}.transport.pause ${parent_frame}.transport.ffw ${parent_frame}.transport.end -side left
}
