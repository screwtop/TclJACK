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
	frame .transport -relief groove -bg black -border 2 -padx 1 -pady 1
	
	# Now the buttons themselves:

	# Play, Stop, Pause (Stop is really Pause), Record? (only applicable to clients that do recording; not global), Start, End ?? (special cases of Locate)
	# Unicode characters for button labels?  Uniform spacing might be more important (plus Unicode has a conspicuous lack of these common characters, AFAICT).
	# If we're rolling, should hitting "|<" stop the transport or leave it rolling?
	# TODO: have play and pause buttons change colour to indicate transport state.
	# Alternative chars: ▪ ▸
	set transport_buttons {
		{start {|<} {Return to Start}          {jack transport locate 0}}
		{rew   {<<} {Rewind}                   {puts rew}}
		{stop  {[]} {Stop and Return to Start} {jack transport stop; jack transport locate 0}}
		{play  { >} {Play}                     {jack transport start}}
		{pause {||} {Pause/Stop}               {jack transport stop}}
		{ffw   {>>} {Fast Forward}             {puts ffw}}
	}

	foreach button $transport_buttons {
		set name [lindex $button 0]
		set caption [lindex $button 1]
		set tooltip [lindex $button 2]
		set command [lindex $button 3]
		button .transport.$name -text $caption -command $command -font font_mono -padx 1m -pady 1m -cursor hand1
		setTooltip .transport.$name $tooltip
		pack .transport.$name -side left
	}
}

proc destroy_transport {} {destroy .transport}

proc show_transport {} {grid .transport -row 0 -column 1}

proc hide_transport {} {grid forget .transport}


# REW and FFW buttons are special, in that they need to start responding on button down, and keep going while the button is held down.
# It may be worth considering having the others respond to press rather than release, as IIRC Ardour's transport buttons do.  This is for faster response, I presume.


