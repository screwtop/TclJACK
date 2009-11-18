# Create and arrange the dialog contents.
toplevel .msg
wm withdraw .msg

label  .msg.l  -text "This is a very simple dialog demo."
button .msg.ok -text OK -default active -command {destroy .msg}
pack .msg.ok -side bottom -fill x
pack .msg.l  -expand 1    -fill both

# Now set the widget up as a centred dialog.

# But first, we need the geometry managers to finish setting
# up the interior of the dialog, for which we need to run the
# event loop with the widget hidden completely...
#wm withdraw .msg
update
#set x [expr {([winfo screenwidth .]-[winfo width .msg])/2}]
#set y [expr {([winfo screenheight .]-[winfo height .msg])/2}]
#wm geometry  .msg +$x+$y
wm transient .msg .
wm title     .msg "Dialog demo"
wm deiconify .msg

