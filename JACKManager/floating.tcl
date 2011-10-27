# Trying to make a window that's floating by default but which can be made into a normal window if required
# and also with minsize set

#proc float {} {...}
#proc dock/unfloat {} {...}

# Might be nice to add a grip-tab thingy to provide a more obvious and less fiddly way of grabbing the window.


proc float {} {
	# Bevelled top-level might also be appropriate, since we have to window decorations in this mode.
	# Colours probably should't be set here, though.
	. configure -background darkgrey -cursor fleur -relief raised -border 1 -padx 2 -pady 2

	wm overrideredirect . 1

	# If was previously docked, need to withdraw to escape Ion's statusbar frame.
	wm withdraw .
	wm deiconify .
	
	# Set default window position to something reasonable?
	# [winfo screenwidth .] / 2.0 ... ?
	wm geometry . +0+0
	
	# Ensure we stay on top?:
	raise .

	# Where are we?
#	puts [wm geometry .]

	# Make the window draggable:
	bind . <1> {
#		raise .
#		puts [wm geometry .]
		set iX0 [expr %X-[winfo rootx .]]
		set iY0 [expr %Y-[winfo rooty .]]
		set bMoved 0
	}
	
	bind . <B1-Motion> {
#		raise .
#		puts [wm geometry .]
		wm geometry . +[expr %X-$iX0]+[expr %Y-$iY0]
		set bMoved 1
	}
	
	bind . <ButtonRelease-1> {
		if { $bMoved } break
	}
}


# dock/unfloat procedure:
proc dock {} {
	# First remember what the original parent frame was (typ. root window):
	set ::frame [wm frame]

	# Remove bindings from "."!
	bind . <1> {}
	bind . <B1-Motion> {}
	bind . <ButtonRelease-1> {}

	wm minsize . [winfo width .] [winfo height .]

	. configure -cursor {} -relief sunken -border 1 -padx 0 -pady 0
	# Return control to the window manager:
	wm overrideredirect . 0

	# Toggle the window status to let it know we're here:
	wm withdraw .
	wm deiconify .
}


# And a procedure to reset the window position to something reasonable?  I guess if it disappears you can't invoke the menu to bring it back anyway...

