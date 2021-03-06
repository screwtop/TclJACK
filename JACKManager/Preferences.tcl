# Some kind of centralised preferences script fragment for DeskNerd.
# Obviously, this should all propery be stored in a database somewhere, eventually!
# NOTE: see also ~/.Xdefaults (Tk honours this file).  

# TODO: figure out differences in font metrics or whatever between Tk 8.4 and 8.5 (things appear much bigger in 8.5 for some reason).

# What sort of font settings?  Mono/Sans/Serif?  Or maybe more specific function-based ones, depending on where it'll appear?  Bold in places?
# Font stuff across Tk versions could get complicated (8.5 supports TrueType and antialiasing).

# New attempt using namespace for global preference-oriented variables:
namespace eval ::tcljack {
	set font_mono_face {LucidaTypewriter}
	set font_mono_size -10
	set font_mono "$font_mono_face $font_mono_size"
#	puts [font metrics $font_mono]
	# Actually, maybe I should be using (or rather deriving from) "-font TkFixedFont" instead...
	# set font_string_mono {TkFixedFont}

#	set font_string_sans {Helvetica 12}

#	font create font_mono -family $font_mono_face -size $font_mono_size
}

#font create font_mono -family LucidaTypewriter -size -12

#{-*-cure-*-*-*-*-11-*-*-*-*-*-*-*}	;# Tiny!
#set font_mono  {Letter Gothic 12 Pitch}
#set ::tcljack::font_mono {LucidaTypewriter 8}
# Letter Gothic 12 Pitch, Lucida Sans Typewriter, LucidaTypewriter, Orator, Prestige
# Remember, negative numbers for bitmap (pixel) sizes, positive for points.
font create font_mono -family lucidatypewriter -size -10	;# was -12
#font create font_mono -family fixed -size 6
#font create font_mono -family lucidatypewriter -size -12
# "fixed" should be available on any X11 installation, right?
# -size 6 was about right for Tk 8.4, but too big on 8.6 
#font create font_mono -family fixed -size -50

#set font_sans  {-*-helvetica-medium-r-*-*-11-*-*-*-*-*-*-*}
#font create font_sans -family TradeGothic -size -14
font create font_sans -family Helvetica -size -12	;# -size is in what units?  Ah, if negative, pixels.
#font create font_sans -family cure -size -10	;# About as small as it gets.
#{-*-helvetica-bold-r-*-*-11-*-*-*-*-*-*-*}
# Optima

#set font_serif {}
# Stempel Garamond, Trajan

#set font_menu $font_sans
#set font_default $font_sans

# TODO: colours, e.g. statusbar background and foreground?
# ion3 statusbar: 0x50 background, 0xa0 text
# Should perhaps be using a namespace for these...
set statusbar_background_colour {#505050}
set statusbar_foreground_colour {#a0a0a0}
. configure -background $statusbar_background_colour

option add *TearOff 1
option add *font font_sans	;# Actually, maybe better to respect the user's general font preferences.

# You wouldn't be running DeskNerd without X, so we don't have to worry about distinguishing between say preferred console editor and preferred graphical editor.
set file_manager thunar
set terminal {urxvt -e bash -l}
set editor gvim


# Tone down the bevelling a little (hard to tell which of these do anything much, although the hand2 thing works):
option add *Menu.relief raised widgetDefault	;# This definitely works (try "sunken" and see).
option add *MenuButton.background red
#option add *Thickness 32 widgetDefault
#option add *Menubutton.Pad 32 widgetDefault
#option add *Cursor hand2 widgetDefault

# Here's some stuff from http://wiki.tcl.tk/10569 that might/should work:
#   option add *Menu.activeBackground #4a6984
#   option add *Menu.activeForeground white
   option add *Menu.activeBorderWidth 0
   option add *Menu.highlightThickness 0
   option add *Menu.borderWidth 1
#	option add *Menu.padX 16
#	option add *Menu.padY 16

#   option add *MenuButton.activeBackground #4a6984
#   option add *MenuButton.activeForeground white
   option add *MenuButton.activeBorderWidth 0
	option add *MenuButton.activeRelief sunken
   option add *MenuButton.highlightThickness 0
   option add *MenuButton.borderWidth 0

   option add *highlightThickness 0

