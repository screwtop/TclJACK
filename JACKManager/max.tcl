proc max {list} {
	set maximum {-inf}
	foreach value $list {
		if {$value > $maximum} {
			set maximum $value
		}
	}
	return $maximum
}

