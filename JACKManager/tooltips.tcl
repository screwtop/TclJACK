proc setTooltip {widget text} {
        if { $text != "" } {
                # 2) Adjusted timings and added key and button bindings. These seem to
                # make artifacts tolerably rare.
                bind $widget &lt;Any-Enter&gt;    [list after 500 [list showTooltip %W $text]]
                bind $widget &lt;Any-Leave&gt;    [list after 500 [list destroy %W.tooltip]]
                bind $widget &lt;Any-KeyPress&gt; [list after 500 [list destroy %W.tooltip]]
                bind $widget &lt;Any-Button&gt;   [list after 500 [list destroy %W.tooltip]]
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

        set positionX [winfo pointerx .]
        set positionY [expr [winfo pointery .] + 25]

        # a.) Ad-hockery: Set positionX so the entire tooltip widget will be displayed.
        if  {[expr $positionX + $width] &gt; [winfo screenwidth .]} {
                set positionX [expr ($positionX - (($positionX + $width) - [winfo screenwidth .]))]
        }

        wm geometry $tooltip [join  "$width x $height + $positionX + $positionY" {}]
        raise $tooltip

        # 2) Kludge: defeat rare artifact by passing mouse over a tooltip to destroy it.
        bind $widget.tooltip &lt;Any-Enter&gt; {destroy %W}
        bind $widget.tooltip &lt;Any-Leave&gt; {destroy %W}
 }

 pack [button .b -text hello]
 setTooltip .b "Hello World!"
