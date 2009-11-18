#!wish
#!/usr/bin/wish
# Basic test using TclJACK to produce a Stevens loudness meter (single channel).

load ./libtcljack.so
jack register
puts "JACK sampling rate = [jack samplerate] Hz"

set indicator_width 16
set indicator_height 600


# Container frame:
pack [frame .sound_gauge  -width $indicator_width  -height $indicator_height  -relief sunken  -borderwidth 1 -background black] -side left
        
# Meter gauge is also simply done as a frame:
place [frame .sound_gauge.meter     -width [expr {$indicator_width-2}] -height 0  -relief flat -borderwidth 0 -background green] -anchor sw -x 0 -y [expr {$indicator_height-2}]


# Could probably take raw data in and do the computation of dB and Stevens in here.
# {peak trough rms} would be enough, I think.
# Maybe also meter type settings: dB FS, K-System, Stevens, raw numeric.
proc sound_gauge_update {raw_level} {
        global indicator_height .sound_gauge.meter
	# Various choices for k, the proportionality constant here:
#	set k [expr {1 / (pow(1 / sqrt(2), 0.67))}]	;# Full-scale sine wave = 1.0; probably the loudest reasonable singal you'd expect to see.  k ~ 1.26.  Too big a range for most music, but does clip at 0 dB FS.
	# Various K-System equivalent points:
#	set k [expr {0.5 / (pow(pow(10, (-14 - 10*log10(2)) / 20.0), 0.67))}]	;# K-14 "0 dB" = 0.5 Stevens. k ~ 1.86. 1.0 Stevens ~ -5 dB FS.  Generally a good choice?
#	set k [expr {1.0 / (pow(pow(10, (-14 - 10*log10(2)) / 20.0), 0.67))}]	;# K-14 "0 dB" = 1.0 Stevens. k ~ 3.7.  Probably a bit big.
#	set k [expr {0.5 / (pow(pow(10, (-20 - 10*log10(2)) / 20.0), 0.67))}]	;# K-20 "0 dB" = 0.5 Stevens. k ~ 3. 1.0 Stevens ~ -11 dB FS.  Not bad.
#	set k [expr {1.0 / (pow(pow(10, (-20 - 10*log10(2)) / 20.0), 0.67))}]	;# K-20 "0 dB" = 1.0 Stevens. k ~ 5.9.  Overpowered much too easily.

#	set k 1.6	;# Empirical; for hot, peak-limited commercial music, RMS reaching 0.5 raw numeric RMS.
	set k 2.5	;# Empirical; more suitable for Replay Gained or moderately mastered music, RMS reaching no higher than about 0.25; 0.5 Stevens is about 0.1 RMS numeric.  1.0 Stevens here corresponds very well with the point at which peak clipping is likely on music, and 0.5 is about "nominal" for pop/rock music.  Perfect! :)

	set gauge_value [expr {$k * pow($raw_level, 0.67)}]
#	puts "k = $k ;  $raw_level raw -> $gauge_value Stevens"
        
	.sound_gauge.meter configure -height [expr {$gauge_value * ($indicator_height-2)}]
}

# Procedure for timed execution of arbitrary code:
proc every {ms body} {eval $body; after $ms [info level 0]}

set nmax 10
every 50 {sound_gauge_update [jack meter]}; if {[incr ::nmax -1]<=0} return}
# Hmm, that seems to keep going indefinitely instead of stopping after 10 reps.

# jack deregister

