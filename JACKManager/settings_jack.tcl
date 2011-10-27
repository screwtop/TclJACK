# (Initially a mockup of the) JACK settings dialog/window.

# What to store here: jackd short and long options, use long option name as widget and variable identifiers in tcl, tooltip text, type of control?
# With the different args for different widget types, it might be difficult to store the whole thing in a table.  However, the widget names, variable names, and tooltip text could be done, I think.

set jackd_main_options {
	{}
}

set sampling_rates {
	  8000
	 11025
	 22050
	 32000
	 44100
	 48000
	 88200
	 96000
	192000
}

set period_sizes {
	  16
	  32
	  64
	 128
	 256
	 512
	1024
	2048
	4096
}

set driver_types {
	{alsa         {Linux}	{ALSA, the Advanced Linux Sound Architecture}}
	{coreaudio    {Mac OS X}	{Core Audio}}
	{dummy        {}	{}}
	{freebob      {}	{}}
	{oss          {}	{}}
	{sun          {}	{}}
	{portaudio    {}	{}}
}

set dither_types {
	rectangular
	triangular
	shaped
	none
}

set clocksource_types {
	{c	cycle}
	{h	hpet}
	{s	system}
}

grid [checkbutton .realtime -text {Realtime} -variable {realtime} -anchor w]
grid [checkbutton .no-mlock -text {No Memory Lock} -variable {no-mlock} -anchor w]
grid [checkbutton .silent -text {Silent (no JACK messages)} -variable {silent} -anchor w]

spinbox .spinbox -values {one two three} -textvariable {spinbox}
grid [spinbox .period -values $period_sizes -textvariable period]
grid [spinbox .rate -values $sampling_rates -textvariable rate]

foreach widget $widgets {
	setTooltip .$widget tooltip???
}

