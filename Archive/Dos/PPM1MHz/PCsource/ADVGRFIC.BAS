'=============================================================================
'*Author:  Jonathan Weaver
'*Date:    5/21/2001
'*Version: 1.1 build #3
'*Filename:  advgrfic.bas
'*Description:  A collection of subroutines used to do common graphics procedures.
'
'Copyright (C) 2001 Jonathan Weaver
'
'This program is free software; you can redistribute it and/or modify it under 
'the terms of the GNU General Public License as published by the Free Software 
'Foundation; either version 2 of the License, or (at your option) any later 
'version.
'
'This program is distributed in the hope that it will be useful, but WITHOUT 
'ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
'FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more 
'details.
'
'You should have received a copy of the GNU General Public License along with 
'this program; if not, write to the Free Software Foundation, Inc., 
'51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
'
'=============================================================================

$compile unit "advgrfic.pbu"

'=============================================================================
' B U I L D   F U N C T I O N
'=============================================================================

'*Returns the build and version number of this unit library
'*RETURN: the number of the build
function verAdvgrfic$() public
verAdvgrfic$ = "Advanced graphics Ver 1.1, build #3:  advgrfic.pbu"
end function

'=============================================================================
' P U B L I C   S U B R O U T I N E S
'=============================================================================

'*Gets the palette value of a specified color attribute and saves it in RGB values.  All palette values are between 0 and 63.
'*Colour%: the color attribute, 0 thru 16
'*Red%: red value
'*Green%: green value
'*Blue%: blue value
sub colorGet(ByVal Colour%, Red%, Green%, Blue%) public
PaletteGet 20 + Colour%, Red%, Green%, Blue%
end sub

'*Sets the palette value of a specified color attribute.  All palette values are between 0 and 63.
'*Colour%: the color attribute, 0 thru 16
'*Red%: red value
'*Green%: green value
'*Blue%: blue value
sub colorSet(ByVal Colour%, Red%, Green%, Blue%) public
PaletteSet 20 + Colour%, Red%, Green%, Blue%
palette Colour%, 20 + Colour%
end sub

'*Gets the palette value of a specified palette color and saves it in RGB values.  All palette values are between 0 and 63.
'*Colour%: the palette, 16 thru 63
'*Red%: red value
'*Green%: green value
'*Blue%: blue value
SUB PaletteGet(ByVal Colour%, Red%, Green%, Blue%) PUBLIC
OUT &h03C7, Colour%
Red%   = INP(&h03C9)
Green% = INP(&h03C9)
Blue%  = INP(&h03C9)
END SUB

'*Sets the palette value of a specified palette color.  All palette values are between 0 and 63.
'*Colour%: the palette, 16 thru 63
'*Red%: red value
'*Green%: green value
'*Blue%: blue value
SUB PaletteSet(ByVal Colour%, ByVal Red%, ByVal Green%, ByVal Blue%) PUBLIC
OUT &h03C8, Colour%
OUT &h03C9, Red%
OUT &h03C9, Green%
OUT &h03C9, Blue%
end sub

'*Places a screen capture, saved in filename, on the screen based on the coordinates of the upper left corner.
'*x%: the x-coordinate of the upper left corner
'*y%: the y-coordinate of the upper left corner
'*filename$: the base-filename to extract the screen from.
sub putScreen(ByVal x%, ByVal y%, ByVal filename$) public
fileNo% = freefile
open filename$+".tmp" for binary as fileNo%
get fileNo%, , size%
get fileNo%, , i%
get fileNo%, , heightcut%
DIM graph(size%) AS INTEGER
dEF SEG = VARSEG( graph(0) )
FOR b% = 0 TO i% - 1
bLOAD filename$+"."+ltrim$(str$(b%)), VARPTR( graph(0) )
PUT (x%,y%+heightcut%*b%), graph,pset
NEXT
close fileNo%
erase graph
end sub

'*Deletes a screen capture file-set based on filename.
'*filename$: the basename of the files to be deleted.  Actual files deleted include <filename>.tmp, <filename>.0, <filename>.1, etc.
sub killScreen(ByVal filename$) public
fileNo% = freefile
open filename$+".tmp" for binary as fileNo%
get fileNo%, 2, i%
close fileNo%
kill filename$+".tmp"
for b% = 0 to i% - 1
kill filename$+"."+ltrim$(str$(b%))
next
end sub

'*Captures the screen whose given the upper left coordinates and the box width and length and stores it to files based on filename.  The method used is fast, but not space saving.
'*x%: the x-coordinate of the upper left corner
'*y%: the y-coordinate of the upper left corner
'*l%: the length of the area to be captured
'*h%: the height of the area to be captured
'*filename$: the base-filename to save the screen to.  A <filename>.tmp will be created, followed by <filename>.0, <filename>.1, etc. as required by memory
sub getScreen(ByVal x%, ByVal y%, ByVal l%, ByVal h%, ByVal filename$) public
fileNo% = freefile
open filename$+".tmp" for binary as fileNo%
i% = graphsize(l%,h%)/7500
heightcut% = h%/i%
size% = graphsize(l%,heightcut%)
PUT fileNo%, , size%
PUT fileNo%, , i%
PUT fileNo%, , heightcut%
DIM graph(size%) AS INTEGER
Segm   = VARSEG(graph(0))
Offs   = VARPTR(graph(0))
Length = (size% + 1) * 2   'integers are two bytes long
DEF SEG = Segm
FOR b% = 0 TO i% - 2
GET (x%, y%+heightcut% * b%)-(x%+l%, y%+heightcut% * (b% + 1)), graph
BSAVE filename$+"."+ltrim$(str$(b%)), Offs, Length
NEXT
get(x%,y%+heightcut%*(i%-1))-(x%+l%,y%+h%),graph
BSAVE filename$+"."+ltrim$(str$(i%-1)), Offs, Length
close fileNo%
erase graph
end sub

'*This function gives the size for the array needed to capture a section of the screen
'*l%:the width of the screen capture
'*h%:  the height of the screen capture
'*return:  the size of an integer array used to capture a section of the screen
function graphsize( l%, h%) public
graphsize = 4 + CEIL(l% / 8) * 4 * h%
end function


