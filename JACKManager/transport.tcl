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


# Support procedure for seeking forward or backward by a particular interval:
# Use negative seconds to go back ("retreat"?).
# Should this functionality be provided in TclJACK?
proc advance {seconds} {
	jack transport locate [expr {[jack timecode] + $seconds * [jack samplerate]}]
}

# Support function defining how the FFW/REW seek step increases with number of steps taken.
proc new_advance_interval {} {
	if {![info exists ::advance_interval]} {
		# Are we going forwards or backwards?
		if {[info exists ::ffw]} {
			puts "new FFW"
			set ::advance_interval 0.5
		} else {
			puts "new REW"
			set ::advance_interval -0.5
		}
	} else {
		# We're continuing: increase the step size somewhat:
		# Since this can also be used to step forward and back, round the time to the nearest x/y seconds, to avoid messing up the timecode with fractional parts of a second.  This has the nice side-effect that it can seek uniformly by seconds for the first few steps (provided we map any 0s to 1s).
		set ::advance_interval [expr {$::advance_interval * 1.1}]
	}
	puts $::advance_interval
	puts [expr round([anticlip $::advance_interval -1 1])]
	return [expr round([anticlip $::advance_interval -0.5 0.5])]	;# Apply minimum step size
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
	# FFW, REW generate a single 1-second seek if tapped, but also have separate press and release bindings (defined below) for continuous seeking.
	set transport_buttons {
		{start {|<} {Return to Start}          {jack transport locate 0}}
		{rew   {<<} {Rewind}                   {advance -1}}
		{stop  {[]} {Stop and Return to Start} {jack transport stop; jack transport locate 0}}
		{play  { >} {Play}                     {jack transport start}}
		{pause {||} {Pause/Stop}               {jack transport stop}}
		{ffw   {>>} {Fast Forward}             {advance 1}}
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

	# REW and FFW buttons are special, in that they need to start responding on button down, and keep going while the button is held down.
	# It may be worth considering having the others respond to press rather than release, as IIRC Ardour's transport buttons do.  This is for faster response, I presume.

	# There seems to be a problem when using these (with Ardour 2.8.4 at least), that after a (variable) number of transport repositions, the transport stops rolling.  For now, we'll ask JACK to start the transport again after each step.  Of course, this would cause the transport to start using FFW/REW while the transport is stopped, which isn't correct behaviour.

	# Will need separate bindings for press and release:

	# Note: the catch {unset ...} here is in case the button is released before the advance has actually had a chance to run.

	bind .transport.ffw <ButtonPress-1> {set ::ffw [every 150 {advance [new_advance_interval]}]}
	bind .transport.ffw <ButtonRelease-1> {every cancel $::ffw; unset ::ffw; catch {unset ::advance_interval}}
	
	bind .transport.rew <ButtonPress-1> {set ::rew [every 150 {advance [new_advance_interval]}]}
	bind .transport.rew <ButtonRelease-1> {every cancel $::rew; unset ::rew; catch {unset ::advance_interval}}
}


proc destroy_transport {} {destroy .transport}

proc show_transport {} {grid .transport -row 0 -column 1}

proc hide_transport {} {grid forget .transport}




