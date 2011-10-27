# From: Jeffrey Hobbs <jeffrey.ho...@scriptics.com>
# Subject: Re: Timeouts functions
# Date: 1999/08/19
# Message-ID: <37BC45C8.72F9509B@scriptics.com>#1/1
# Newsgroups: comp.lang.tcl


# every --
#   Cheap rescheduler
# every <time> cmd;       # cmd is a one arg (cmd as list)
#       schedules $cmd to be run every <time> 1000ths of a sec
#       IOW, [every 1000 "puts hello"] prints hello every sec
# every cancel cmd
#       cancels a cmd if it was specified
# every info ?pattern?
#       returns info about commands in pairs of "time cmd time cmd ..."
#
proc every {time {cmd {}}} {
    global EVERY
    if {[regexp {^[0-9]+$} $time]} {
        # A time was given, so schedule a command to run every $time msecs
        if {[string compare {} $cmd]} {
            set EVERY(TIME,$cmd) $time
            set EVERY(CMD,$cmd) [after $time [list every eval $cmd]]
        } else {
            return -code error "wrong \# args: should be \"[lindex [info level 0]
0] <number> command"
        }
        return
    }
    switch $time {
        eval {
            if {[info exists EVERY(TIME,$cmd)]} {
                uplevel \#0 $cmd
                set EVERY(CMD,$cmd) [after $EVERY(TIME,$cmd) \
                        [list every eval $cmd]]
            }
        }
        cancel {
            if {[string match "all" $cmd]} {
                foreach i [array names EVERY CMD,*] {
                    after cancel $EVERY($i)
                    unset EVERY($i) EVERY(TIME,[string range $i 4 end])
                }
            } elseif {[info exists EVERY(CMD,$cmd)]} {
                after cancel $EVERY(CMD,$cmd)
                unset EVERY(CMD,$cmd) EVERY(TIME,$cmd)
            }
        }
        info {
            set result {}
            foreach i [array names EVERY TIME,$cmd*] {
                set cmd [string range $i 5 end]
                lappend result $EVERY($i) $cmd
            }
            return $result
        }
        default {
            return -code error "bad option \"$time\": must be cancel, info or a
number"
        }
    }
    return

} 
