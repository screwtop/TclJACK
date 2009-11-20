# Trying to make a window that's floating by default but which can be made into a normal window if required
# and also with minsize set

#proc float {} {

# Might be nice to add a grip-tab thingy to provide a more obvious and less fiddly way of grabbing the window.

# Bevelled top-level might also be appropriate, since we have to window decorations in this mode.
. configure -background darkgrey -cursor fleur -relief raised -border 1 -padx 2 -pady 2

#pack [button .b -text "The Button" -command exit]
wm overrideredirect . 1

bind . <1> {
	set iX0 [expr %X-[winfo rootx .]]
	set iY0 [expr %Y-[winfo rooty .]]
	set bMoved 0
}

bind . <B1-Motion> {
	wm geometry . +[expr %X-$iX0]+[expr %Y-$iY0]
	set bMoved 1
}

bind . <ButtonRelease-1> {
	if { $bMoved } break
}

