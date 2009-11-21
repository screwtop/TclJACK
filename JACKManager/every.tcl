## ****************************************************************
 ## Name:
 ##     every
 ## Description:
 ##     Schedules a script for being regularly executed, returning
 ##     a token that allows the scheduling to be halted at some
 ##     future point.
 ## Usage:
 ##     every ms script...
 ##     every cancel token
 ##     every cancel script...
 ## Notes:
 ##     The script is executed at the global level, and any errors
 ##     generated by the script will NOT cause a cessation of future
 ##     schedulings.  Thus, any script that always causes an error
 ##     will cause many user-interface problems when used with a
 ##     short delay.
 ##     While differently scheduled scripts do not need to be
 ##     distinct from each other, it is not determined which one
 ##     will be cancelled if you use the cancelling form with the
 ##     script as opposed to the token.
 ## Example:
 ##     set foo [every 500 {puts [clock format [clock seconds]]}]
 ##     every 10000 puts Howdy!
 ##     # ...
 ##     after cancel $foo
 ##     after cancel puts Howdy!
 ## ****************************************************************
 proc every {option args} {
     global everyPriv every:UID
     if {[string equal -length [string length $option] $option cancel]} {
         set id {}
         if {[llength $args] == 1 && [string match every#* [lindex $args 0]]} {
             set id [lindex $args 0]
         } else {
             set script [eval [list concat] $args]
             # Yuck, a linear search.  A reverse hash would be faster...
             foreach {key value} [array get everyPriv] {
                 if {[string equal $script [lindex $value 1]]} {
                     set id $key
                     break
                 }
             }
         }
         if {[string length $id]} {
             after cancel [lindex $everyPriv($id) 2]
             unset everyPriv($id)
         }
     } else {
         set id [format "every#%d" [incr every:UID]]
         set script [eval [list concat] $args]
         set delay $option
         set aid [after $delay [list every:afterHandler $id]]
         set everyPriv($id) [list $delay $script $aid]
         return $id
     }
 }
 ## Internal stuff - I could do this with a namespace, I suppose...
 array set everyPriv {}
 set every:UID 0
 proc every:afterHandler {id} {
     global everyPriv
     foreach {delay script oldaid} $everyPriv($id) {}
     set aid [after $delay [info level 0]]
     set everyPriv($id) [list $delay $script $aid]
     uplevel #0 $script
 }
