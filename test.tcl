#!/usr/bin/rlwrap tclsh8.5

puts [load ./libtcljack.so]

puts [jack]

puts [jack_counter]
puts [jack_counter]
puts [jack_counter]
puts [jack_counter]

if {[catch {puts [jack_samplerate]} result]} {puts stderr $result}
jack_register
puts [jack_samplerate]
puts [jack_cpuload]
if {[catch {puts [jack_register]} result]} {puts stderr $result}
jack_deregister
if {[catch {puts [jack_samplerate]} result]} {puts stderr $result}
if {[catch {puts [jack_deregister]} result]} {puts stderr $result}

exit

