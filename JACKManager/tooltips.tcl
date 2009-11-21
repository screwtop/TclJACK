# Tooltips implementation from http://wiki.tcl.tk/1954

# Modified so that if pointer is in lower half of screen, tooltip is drawn above instead of below.

# TODO: consider aligning tooltips to be centred on the mouse pointer instead of left-aligned.
# TODO: try and prevent tooltips from appearing on top of menus when they're clicked before the tooltip has a chance to appear.


proc setTooltip {widget text} {
	if { $text != "" } {
		# 2) Adjusted timings and added key and button bindings. These seem to
		# make artifacts tolerably rare.
		bind $widget <Any-Enter>    [list after 500 [list showTooltip %W $text]]
		bind $widget <Any-Leave>    [list after 500 [list destroy %W.tooltip]]
		bind $widget <Any-KeyPress> [list after 500 [list destroy %W.tooltip]]
		bind $widget <Any-Button>   [list after 500 [list destroy %W.tooltip]]
	}
}

proc showTooltip {widget text} {
	global tcl_platform
	if { [string match $widget* [winfo containing  [winfo pointerx .] [winfo pointery .]] ] == 0  } {
	return
	}
	
	catch { destroy $widget.tooltip }
	
	set scrh [winfo screenheight $widget]    ; # 1) flashing window fix
	set scrw [winfo screenwidth $widget]     ; # 1) flashing window fix
	set tooltip [toplevel $widget.tooltip -bd 1 -bg black]
	wm geometry $tooltip +$scrh+$scrw        ; # 1) flashing window fix
	wm overrideredirect $tooltip 1
	
	if {$tcl_platform(platform) == {windows}} { ; # 3) wm attributes...
		wm attributes $tooltip -topmost 1   ; # 3) assumes...
	}                                           ; # 3) Windows
	pack [label $tooltip.label -bg lightyellow -fg black -text $text -justify left]
	
	set width [winfo reqwidth $tooltip.label]
	set height [winfo reqheight $tooltip.label]
	
	set pointer_below_midline [expr {[winfo pointery .] > [expr {[winfo screenheight .] / 2.0}]}]	;# Is the pointer in the bottom half of the screen?
	
	set positionX [expr {[winfo pointerx .] - round($width / 2.0)}]	;# Tooltip is centred horizontally on pointer.
	set positionY [expr [winfo pointery .] + 35 * ($pointer_below_midline * -2 + 1) - round($height / 2.0)]	;# Tooltip is displayed above or below depending on pointer Y position.
	
	# a.) Ad-hockery: Set positionX so the entire tooltip widget will be displayed.
	# Modified to handle horizontally-centred tooltips and left screen edge.
	if  {[expr {$positionX + $width}] > [winfo screenwidth .]} {
		set positionX [expr [winfo screenwidth .] - $width]
	} elseif {$positionX < 0} {
		set positionX 0
	}
	
	wm geometry $tooltip [join  "$width x $height + $positionX + $positionY" {}]
	raise $tooltip
	
	# 2) Kludge: defeat rare artifact by passing mouse over a tooltip to destroy it.
	bind $widget.tooltip <Any-Enter> {destroy %W}
	bind $widget.tooltip <Any-Leave> {destroy %W}
}


# Example use:
#pack [button .b -text hello]
#setTooltip .b "Hello World!"

