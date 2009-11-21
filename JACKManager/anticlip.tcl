# The opposite of clipping: make sure a value lies outside specified bounds.
# TODO: make {min max} order not matter (by looking at which is greater).
proc anticlip {value min max} {
	if {$value < $min} {return $value}
	if {$value > $max} {return $value}
	set threshold [expr {($max + $min) / 2.0}]
	if {$value < $threshold} {return $min}
	if {$value >= $threshold} {return $max}
}

