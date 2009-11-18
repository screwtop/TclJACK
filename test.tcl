#!/usr/bin/rlwrap tclsh8.5

puts [load ./libtcljack.so]

#puts [jack]

puts [jack_counter]
puts [jack_counter]
puts [jack_counter]
puts [jack_counter]

if {[catch {puts [jack samplerate]} result]} {puts stderr $result}
jack register
puts [jack samplerate]
puts [jack cpuload]
if {[catch {puts [jack register]} result]} {puts stderr $result}
jack deregister
if {[catch {puts [jack samplerate]} result]} {puts stderr $result}
if {[catch {puts [jack deregister]} result]} {puts stderr $result}

exit

