proc min {list} {
	set minimum {inf}
	foreach value $list {
		if {$value < $minimum} {
			set minimum $value
		}
	}
	return $minimum
}

