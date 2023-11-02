'============================================================================
'*Author:  Jonathan Weaver
'*Date:    4/27/2005
'*Version: 2.03 build #1
'*Filename:  gui2.bas
'*Description:  A collection of graphical interface routines
'
'Versions: 2.0 build #2
'          2.01 build #3
'          2.01 build #4 - 2/21/2005 - Bug fix in clkTextButton
'          2.02 build #1 - 3/2/2005 - Added textbox and related routines
'          2.02 build #2 - 4/14/2005 - Bug fix in mouseOn/mouseOff
'          2.03 build #1 - 4/27/2005 - Added timerOn and timerStop
'
'Copyright (C) 2005 Jonathan Weaver
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
'============================================================================

'============================================================================
' C O M P I L E R   D I R E C T I V E S
'============================================================================

$compile unit "gui2.pbu"
$dynamic

'============================================================================
' S H A R E D   A N D   E X T E R N A L  D E C L A R A T I O N S
'============================================================================

'Input Handling variables & variables for font and mouse stuff
DIM static a(9) as integer
dim static mouseimg(244) as integer
dim header(0) as integer
dim fontStyle as byte, fcolor as byte, bcolor as byte, keyStatus as byte
dim dcolor as byte, hfcolor as byte, hbcolor as byte

shared mcursor$, mouseimg(), mxold%,myold%, place&, xoffset?, yoffset?
shared header(),alpha$,fontfile%, fontfile$,a()
shared ma_count%, fontheight%, fontbaseline%
shared scrollActive%
shared statusX%,statusY%, statusW%

shared timerStatus?

'*The disabled color, highlight foreground color, and highlight background color
external dcolor, hfcolor, hbcolor

'*The foreground and background colors to draw with.
external fcolor, bcolor

'*The fontStyle to use
external fontStyle

'*The x, y, and mouse button pressed
external xpos%,ypos%,but%

'*The keyboard and keystatus bit pressed
external kbd$, keystatus

'Screen area declaration
dim EXPAMT as word
shared EXPAMT
dim SA_UB as integer
shared SA_UB
dim SA_x1(0) as integer, SA_x2(0) as integer
dim SA_y1(0) as integer, SA_y2(0) as integer
dim SA_hndl(0) as integer, SA_opt(0) as integer
shared SA_x1(), SA_x2(), SA_y1(), SA_y2(), SA_hndl(), SA_opt()

'Textbox shared variables
dim cursorState as shared byte
shared curx%, cury%
shared ch$
shared bc?

'<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
'Input Handling

'Assistant to waitCursor
chgCursor:
if cursorState = 0 then
    if (keystatus and 128) then
        curxb% = curx% + fontLength(ch$)
        smartMouseOff curx%, cury%, curxb%, cury% + fontH
        bc? = point(curx%+1, cury%)
        line (curx%+1, cury%)-(curxb%, cury% + fontH), fcolor, bf
        tcolor = fcolor
        fcolor = bcolor
        fontput curx%+1, cury%, ch$
        fcolor = tcolor
        mouseOn
        cursorState = 2
    else
        smartMouseOff curx%, cury%, curx% + 4, cury% + fontH
        line (curx%, cury%)-(curx%, cury% + fontH), fcolor
        mouseOn
        cursorState = 1
    end if
elseif cursorState = 1 then
    smartMouseOff curx%, cury%, curx% + 4, cury% + fontH
    line (curx%, cury%)-(curx%, cury% + fontH), bcolor
    mouseOn
    cursorState = 0
else
    curxb% = curx% + fontLength(ch$)
    smartMouseOff curx%, cury%, curxb%, cury% + fontH
    line (curx%+1, cury%)-(curxb%, cury% + fontH), bc?, bf
    if bc? = hbcolor then
        tcolor = fcolor
        fcolor = hfcolor
        fontput curx%+1, cury%, ch$
        fcolor = tcolor
    else
        fontput curx%+1, cury%, ch$
    end if
    mouseOn
    cursorState = 0
end if
return

'*Checks the keyboard and mouse, loading the x and y-coordinates, button status, and keyboard status.  Also redraws the cursor if necessary
sub checkInput public
def seg = 0
keystatus = peek(&H417)             'You can also read more keyboad status information from &H418
kbd$ = inkey$
mouse
if mxold% <> xpos% - xoffset? or myold% <> ypos% - yoffset? then
    if mcursor$ <> "DEFAULT" then drawMCursor
end if
end sub

'*Waits for input from the keyboard or a mouse click
sub waitinput public
mouse
x% = xpos%:y% = ypos%:b% = but%
kbd$ = ""
while kbd$ = "" and b% = but% and y% = ypos% and x% = xpos%
    def seg = 0
    keystatus = peek(&H417)
    kbd$ = inkey$
    mouse
wend
if mcursor$ <> "DEFAULT" then drawMCursor
end sub

'End Input Handling
'<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
'Mouse

sub timerStop public
if timerStatus? = 0 then
    timer Stop
end if
incr timerStatus?
end sub

sub timerOn public
if timerStatus? > 0 then decr timerStatus?
if timerStatus? = 0 then
    timer On
end if
end sub

'*Returns the status of the mouse into xpos%, ypos%, and but%
SUB Mouse public
timerStop
DEF SEG = VARSEG(a(0))
POKE VARPTR(a(4)), &H92
ex% = varptr(a(0))
cb% = ypos%
CALL absolute place& (cb%, ex%)
ypos% = ex%
POKE VARPTR(a(4)), &H91
cb%=xpos%
CALL absolute place& (cb%, ex%)
xpos% = ex%
POKE VARPTR(a(4)), &H93
cb%=but%
'======================================
'Note:  Right button = 2
'       Left button = 1
'======================================
CALL absolute place& (cb%, ex%)
but% = ex%
timerOn
end SUB

'*Sets the mouse cursor, based on cursorfile$ and cursorno%
'*cursorfile$: the file containing the mouse cursor
'*mcursor%: the sequence of the cursor in the file
sub setMCursor(byVal cursorfile$, byVal mcursor%) public
timerStop
mfile% = freefile
open cursorfile$ for binary as mfile%
get mfile%, mcursor%*6, loca%
get mfile%, mcursor%*6+2, leng%
get mfile%, mcursor%*6+4, xoffset?
get mfile%, mcursor%*6+5, yoffset?
a$ = string$(leng%, " ")
get mfile%, loca%, a$
close mfile%
mouseOff
mcursor$ = a$
mouseOn
timerOn
end sub

'*Draws the current mouse cursor at the mouse location
sub drawMCursor public
timerStop
oldx% = mxold%
oldy% = myold%
mxold% = xpos%-xoffset?
myold% = ypos%-yoffset?
xb% = mxold%+20
yb% = myold%+20
if 0 > mxold% then
mxold% = 0
elseif 639 < xb% then
xb% = 639
end if
if 0 > myold% then
myold% = 0
elseif 479 < yb% then
yb% = 479
end if
put(oldx%,oldy%),mouseimg,pset
get(mxold%,myold%)-(xb%,yb%),mouseimg
draw "BM"+ltrim$(rtrim$(str$(xpos%)))+","+ltrim$(rtrim$(str$(ypos%)))
draw mcursor$
timerOn
end sub

'*Turns the mousecursor off if the mouse is over the area specified
'*x1%: The left x-pos
'*y1%: The upper y-pos
'*x2%: The right x-pos
'*y2%: The lower y-pos
sub SmartMouseOff(byVal x1%, byVal y1%, byVal x2%, byVal y2%) public
'mouse
xp% = xpos% - xoffset?
yp% = ypos% - yoffset?
if (xp% + 20 >= x1%) and (xp% =< x2%) and (yp% + 20 >= y1%) and (yp% =< y2%) then mouseOff
end sub

'*Turns the mouse cursor on if it is off
sub mouseOn public
timerStop
DEF SEG = VARSEG(a(0))
sw% = peek(VARPTR(a(0)) + 1)
if sw% <> 3 then 'if mouse is not on
    if mxold% > -1 then                 'If the last time mouseoff was called, the mouse was off
        if mcursor$ = "DEFAULT" then
            mousedrv 1
            mousedrv 3
        else
            mousedrv 3
            mouse
            get(0, 0)-(0, 0),mouseimg
            mxold% = 0
            myold% = 0
            drawMCursor
        end if
    else
        mxold% = 0
    end if
end if
timerOn
end sub

'*Turns the mouse cursor off
sub mouseOff public
timerStop
DEF SEG = VARSEG(a(0))
sw% = peek(VARPTR(a(0)) + 1)
if sw% = 3 then  'if mouse is on
    if mcursor$ <> "DEFAULT" then
        put(mxold%, myold%),mouseimg,pset
        mousedrv 1
    end if
    mousedrv 2
else
    mxold% = -1     'Indicates that the mouse was off and the next mouse on should do nothing
end if
timerOn
end sub

'*Initializes the mouse.  Must be called before any other calls to the mouse.
sub mouseInitialize public
DEF SEG = VARSEG(a(0))
POKE VARPTR(a(0)) + 0,&HB8:     POKE VARPTR(a(0)) + 1,&H00
POKE VARPTR(a(0)) + 2,&H00:     POKE VARPTR(a(0)) + 3,&H55
POKE VARPTR(a(0)) + 4,&H8B:     POKE VARPTR(a(0)) + 5,&HEC
POKE VARPTR(a(0)) + 6,&HCD:     POKE VARPTR(a(0)) + 7,&H33
POKE VARPTR(a(0)) + 8,&H92:     POKE VARPTR(a(0)) + 9,&H8B
POKE VARPTR(a(0)) + 10,&H5E:    POKE VARPTR(a(0)) + 11,&H06
POKE VARPTR(a(0)) + 12,&H89:    POKE VARPTR(a(0)) + 13,&H07
POKE VARPTR(a(0)) + 14,&H5D:    POKE VARPTR(a(0)) + 15,&HCA
POKE VARPTR(a(0)) + 16,&H02:    POKE VARPTR(a(0)) + 17,&H00
mousedrv 0
mcursor$ = "DEFAULT"
end sub


'This sub changes the settings for the mouse driver
'Note:
'SW = 0-reset, 1-on, 2-off, 3-coordinate
SUB Mousedrv (SW?)
DEF SEG = VARSEG(a(0))
POKE VARPTR(a(0)) + 1, SW?         'Swap code,Set AX = (SW)
ex% = varptr(a(0))
CALL absolute place& (c%, ex%)     'Run Code
END SUB

'end mouse
'<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
'ScreenArea data Structure

'*Initializes the screen areas
sub SA_initialize() public
redim SA_x1(10) as integer, SA_x2(10) as integer, SA_y1(10) as integer, SA_y2(10) as integer, SA_hndl(10) as integer, SA_opt(10) as integer
EXPAMT = 10
end sub

'Returns the next handle in the sequence for a screen area
function SA_getHndl()
mx% = -1
for i% = 0 to SA_UB - 1
    if SA_hndl(i%) > mx% then
        mx% = SA_hndl(i%)
    end if
next
SA_getHndl = mx% + 1
end function

'*Returns the index, given the handle of a screen area
'*hndl%: the handle of a screen area
'*return: the index of the screen area
function SA_getIndex(hndl%) public
while i% < SA_UB and SA_hndl(i%) <> hndl%
    incr i%
wend
SA_getIndex = i%
end function

'*Moves a Screen area
'*chk%: the index of the screen area
'*newX1%: the new x-cordinate for the upper-left corner
'*newY1%: the new y-cordinate for the upper-left corner
sub SA_move(chk%,newX1%,newY1%) public
SA_change chk%,newX1%,newY1%,SA_x2(chk%)-SA_x1(chk%)+newX1%,SA_y2(chk%)-SA_y1(chk%)+newY1%
end sub

'*Resizes a Screen Area
'*chk%: the index of the screen area
'*newWidth%: the new width of the screen area
'*newHeight%: the new height of the screen area
sub SA_resize(chk%,newWidth%,newHeight%) public
SA_change chk%,SA_x1(chk%),SA_y1(chk%),SA_x1(chk%)+newWidth%,SA_y1(chk%)+newHeight%
end sub

'*Changes the cordinates of a Screen area
'*chk%: the index of the screen area
'*x1%: the x-coordinate for the upper-left corner
'*y1%: the y-coordinate for the upper-left corner
'*x2%: the x-coordinate for the lower-right corner
'*y2%: the y-coordinate for the lower-right corner
sub SA_change(chk%,x1%,y1%,x2%,y2%) public
SA_x1(chk%) = x1%
SA_x2(chk%) = x2%
SA_y1(chk%) = y1%
SA_y2(chk%) = y2%
end sub

'*Deletes a Screen area
'*chk%: the index of the screen area to delete
sub SA_delete(chk%) public
I_delArr SA_x1(), chk%, SA_UB: incr SA_UB
I_delArr SA_x2(), chk%, SA_UB: incr SA_UB
I_delArr SA_y1(), chk%, SA_UB: incr SA_UB
I_delArr SA_y2(), chk%, SA_UB: incr SA_UB
I_delArr SA_opt(), chk%, SA_UB: incr SA_UB
I_delArr SA_hndl(), chk%, SA_UB
end sub

'*Adds an Screen Area to the top layer of the screen
'*x1%: the x-coordinate for the upper-left corner
'*y1%: the y-coordinate for the upper-left corner
'*x2%: the x-coordinate for the lower-right corner
'*y2%: the y-coordinate for the lower-right corner
'*returns: the handle created for the screen area
function SA_addTop(byVal x1%, byVal y1%, byVal x2%, byVal y2%) public
SA_addTop = SA_add(x1%,y1%,x2%,y2%,SA_UB)
end function

'*Adds a Screen Area to the bottom layer of the screen
'*x1%: the x-coordinate for the upper-left corner
'*y1%: the y-coordinate for the upper-left corner
'*x2%: the x-coordinate for the lower-right corner
'*y2%: the y-coordinate for the lower-right corner
'*returns: the handle created for the screen area
function SA_addBottom(byVal x1%, byVal y1%, byVal x2%, byVal y2%) public
SA_addBottom = SA_add(x1%,y1%,x2%,y2%,0)
end function

'Adds a Screen Area to the specified screen layer
function SA_add(byVal x1%,byVal y1%, byVal x2%, byVal y2%,byVal p%)
I_insArr SA_x1(), p%, SA_UB, x1%: decr SA_UB
I_insArr SA_x2(), p%, SA_UB, x2%: decr SA_UB
I_insArr SA_y1(), p%, SA_UB, y1%: decr SA_UB
I_insArr SA_y2(), p%, SA_UB, y2%: decr SA_UB
I_insArr SA_opt(), p%, SA_UB, 0 : decr SA_UB
a% = SA_getHndl()
I_insArr SA_hndl(), p%, SA_UB, a%
SA_add = a%
end function

'*Returns the highest layered screen area that the mouse is over
'*returns: the handle of the screen area that the mouse if over or a -1 if not over a ScreenArea
function SA_MouseOver public
SA_MouseOver = SA_Over(xpos%,ypos%)
end function

'*Returns the highest layered screen area that was clicked by the appropriate mouse button
'*x%: the x-coordinate to check
'*y%: the y-coordinate to check
'*returns: the handle of the screen area that the point (x%, y%) if over or a -1 if not over a ScreenArea
function SA_MouseClick public
cnt% = SA_UB
done = FALSE
while cnt% > 0 and NOT(done)
   decr cnt%
   done = isOver(xpos%, ypos%, cnt%) and (but% = SA_opt(cnt%) xor SA_opt(cnt%) = 0)
wend
if NOT(done) then
    toRet% = -1
else
    toRet% = SA_hndl(cnt%)
end if
SA_MouseClick = toRet%
end function

'*Sets the mouse button for a Screen Area
'*cnt%: the handle of the screen area
'*buttn%: the right (2) or left (1) mouse button or both (0).  Any other value will render the SA unresponsive to mouse clicks
sub SA_setMButton(cnt%, buttn%) public
SA_Opt(SA_getIndex(cnt%)) = buttn%
end sub

'*Gets the mouse button for a Screen Area
'*cnt%: the handle of the screen area
'*buttn%: the right (2) or left (1) mouse button or both (0).  Any other value will render the SA unresponsive to mouse clicks
function SA_getMButton(cnt%) public
SA_getMButton = SA_Opt(SA_getIndex(cnt%))
end function

'*Returns the TRUE if the coordinate x%, y% is over the screen area with index cnt%, FALSE otherwise
'*x%: the x-coordinate to check
'*y%: the y-coordinate to check
'*cnt%: the index of the screen area to check
'*returns: TRUE if x%, y% are contained in the screen area, otherwise FALSE
function isOver(x%,y%,cnt%) public
toRet = FALSE
if x% > SA_x1(cnt%) and x% < SA_x2(cnt%) then
    if y% > SA_y1(cnt%) and y% < SA_y2(cnt%) then toRet = TRUE
end if
isOver = toRet
end function

'*Returns the highest layered screen area that is over the point (x%, y%)
'*x%: the x-coordinate to check
'*y%: the y-coordinate to check
'*returns: the handle of the screen area that the point (x%, y%) if over or a -1 if not over a ScreenArea
function SA_Over(x%,y%) public
cnt% = SA_UB
done = FALSE
while cnt% > 0 and NOT(done)
   decr cnt%
   done = isOver(x%, y%, cnt%)
wend
if NOT(done) then
    toRet% = -1
else
    toRet% = SA_hndl(cnt%)
end if
SA_Over = toRet%
end function

sub SA_getNoOverlap(chk%,x1%,y1%,x2%,y2%,ov_x1%,ov_y1%,ov_x2%,ov_y2%,where?) public
getNoOverlap SA_x1(chk%),SA_y1(chk%),SA_x2(chk%),SA_y2(chk%),x1%,y1%,x2%,y2%,ov_x1%,ov_y1%,ov_x2%,ov_y2%,where?
end sub

'*Returns the value for TOP to use with the getNoOverlap subroutines
'*returns: the value for TOP or 0
function SA_TOP() public
SA_TOP = 0
end function

'*Returns the value for BOTTOM to use with the getNoOverlap subroutines
'*returns: the value for BOTTOM or 3
function SA_BOTTOM() public
SA_BOTTOM = 3
end function

'*Returns the value for LEFT to use with the getNoOverlap subroutines
'*returns: the value for LEFT or 1
function SA_LEFT() public
SA_LEFT = 1
end function

'*Returns the value for RIGHT to use with the getNoOverlap subroutines
'*returns: the value for RIGHT or 2
function SA_RIGHT() public
SA_RIGHT = 2
end function

'*Finds the nonoverlaping area in the second set of points, relative to the first.  Sets ov_x1% to -1 if noOverlapArea doesn't exist
'*x1_a%: the x-coordinate of the upper-left corner
'*y1_a%: the y-coordinate of the upper-left corner
'*x2_a%: the x-coordinate of the lower-right corner
'*y2_a%: the y-coordinate of the lower-right corner
'*x1_b%: the x-coordinate of the upper-left corner
'*y1_b%: the y-coordinate of the upper-left corner
'*x2_b%: the x-coordinate of the lower-right corner
'*y2_b%: the y-coordinate of the lower-right corner
'*ov_x1%: the x-coordinate of the upper-left corner of the non-overlap, returned
'*ov_y1%: the y-coordinate of the upper-left corner of the non-overlap, returned
'*ov_x2%: the x-coordinate of the lower-right corner of the non-overlap, returned
'*ov_y2%: the y-coordinate of the lower-right corner of the non-overlap, returned
'*where?:  0 = top, 3=bottom, 1=left, 2=right
sub getNoOverlap(byVal x1_a%, byVal y1_a%, byVal x2_a%, byVal y2_a%, byVal x1_b%, byVal y1_b%, byVal x2_b%, byVal y2_b%,ov_x1%,ov_y1%,ov_x2%,ov_y2%, byVal where?) public
select case where?
case 0 'top
ov_x1% = x1_b%
ov_x2% = x2_b%
ov_y1% = min(y1_a%, y1_b%)
ov_y2% = min(y1_a% - 1, y2_b%)
if ov_y1% = ov_y2% then decr ov_y1%
case 1 'left
ov_x1% = min(x1_a%,x1_b%)
ov_x2% = min(x1_a% - 1, x2_b%)
ov_y1% = max(y1_a%,y1_b%)
ov_y2% = min(y2_a%,y2_b%)
if ov_x1% = ov_x2% then decr ov_x1%
case 2 'right
ov_x1% = max(x2_a% + 1, x1_b%)
ov_x2% = max(x2_a%,x2_b%)
ov_y1% = max(y1_a%,y1_b%)
ov_y2% = min(y2_a%,y2_b%)
if ov_x1% = ov_x2% then incr ov_x2%
case 3 'bottom
ov_x1% = x1_b%
ov_x2% = x2_b%
ov_y1% = max(y2_a% + 1, y1_b%)
ov_y2% = max(y2_a%, y2_b%)
if ov_y1% = ov_y2% then incr ov_y2%
end select
if ov_x1% >= ov_x2% or ov_y1% >= ov_y2% then ov_x1% = -1
end sub

'*Finds the overlaping area in the second set of points, relative to the screen area.
'*ov_x1%: the x-coordinate of the upper-left corner of the overlap, returned
'*ov_y1%: the y-coordinate of the upper-left corner of the overlap, returned
'*ov_x2%: the x-coordinate of the lower-right corner of the overlap, returned
'*ov_y2%: the y-coordinate of the lower-right corner of the overlap, returned
sub SA_getOverlap(chk_1%,x1%,y1%,x2%,y2%,ov_x1%,ov_y1%,ov_x2%,ov_y2%) public
getOverlap SA_x1(chk_1%),SA_y1(chk_1%),SA_x2(chk_1%),SA_y2(chk_1%),x1%,y1%,x2%,y2%,ov_x1%,ov_y1%,ov_x2%,ov_y2%
end sub

'*Finds the overlaping area in the second set of points, relative to the first.
'*ov_x1%: the x-coordinate of the upper-left corner of the overlap, returned
'*ov_y1%: the y-coordinate of the upper-left corner of the overlap, returned
'*ov_x2%: the x-coordinate of the lower-right corner of the overlap, returned
'*ov_y2%: the y-coordinate of the lower-right corner of the overlap, returned
sub getOverlap(x1_a%,y1_a%,x2_a%,y2_a%,x1_b%,y1_b%,x2_b%,y2_b%,ov_x1%,ov_y1%,ov_x2%,ov_y2%) public
ov_x1% = max(x1_a%, x1_b%)
ov_x2% = min(x2_a%, x2_b%)
ov_y1% = max(y1_a%, y1_b%)
ov_y2% = min(y2_a%, y2_b%)
end sub

'*Gets the coordinates of a screen area based on its index
'*chk%: the index of the screen area
'*x1%: the x-coordinate of the upper-left corner, returned
'*y1%: the y-coordinate of the upper-left corner, returned
'*x2%: the x-coordinate of the lower-right corner, returned
'*y2%: the y-coordinate of the lower-right corner, returned
sub SA_getCoord(chk%,x1%,y1%,x2%,y2%) public
x1% = SA_x1(chk%)
x2% = SA_x2(chk%)
y1% = SA_y1(chk%)
y2% = SA_y2(chk%)
end sub

'*Move the screen area specified by the index to the top layer of the screen
'*chk%: the index of the screen area to move
sub SA_moveToTop(chk%) public
tempX1% = SA_x1(chk%)
tempX2% = SA_x2(chk%)
tempY1% = SA_y1(chk%)
tempY2% = SA_y2(chk%)
tempHndl% = SA_hndl(chk%)
array delete SA_x1(chk%)
array delete SA_x2(chk%)
array delete SA_y1(chk%)
array delete SA_y2(chk%)
array delete SA_hndl(chk%)
a% = SA_UB - 1
SA_x1(a%) = tempX1%
SA_x2(a%) = tempX2%
SA_y1(a%) = tempY1%
SA_y2(a%) = tempY2%
SA_hndl(a%) = tempHndl%
end sub

'End ScreenArea data Structure
'<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
'Fonts

'*Centers a string in an area
'*x%: x-position for left side to center text over
'*y%: y-position
'*xb%: x-position for right side to center text over
'*printStr$: text to print in center
sub fontcent(byval x%, byVal y%, byVal xb%, byVal printStr$) public
view screen (x%, y%)-(xb%, y% + fontheight%)
fontput center(x%, xb%, fontlength(printStr$)), y%, printStr$
view screen
end sub

'*Prints a font to the screen, but constrains the right boundrary of the font drawing
'*x%: x-position for left side
'*y%: y-position
'*xb%: x-position for right side
'*printStr$: text to print
sub fontPutconstr(byVal x%, byVal y%, byVal xb%, byVal printStr$) public
view screen (x%, y%)-(xb%, y% + fontheight%)
fontput x%, y%, printStr$
view screen
end sub

'*Loads a font from a font file
'*file$: the full file name of the file to load from
sub loadfont(byVal file$) public
alpha$ = "'"+chr$(34)+"-\/AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz0123456789[]:;<>,.?~!@#$%^&*()_+={}|` "
fontfile$ = file$
fontfile% = freefile
open file$ for binary as fontfile%
'load header of file
redim header(284) as integer
for i% = 0 to 284
get fontfile%,,header(i%)
next
get fontfile%, 576, fontheight%
get fontfile%, 578, fontbaseline%
end sub

'*Unloads a font from memory.
sub unloadfont public
erase header
erase alpha$
close fontfile%
end sub

'*Uses the font file determine the length in pixels of the text
'*printStr$: the string whose length to return
'*returns: the length the string will be in pixels using the current font
function fontlength% (byVal printStr$) public
for i% = 1 to len(printStr$)
headerPos% = 3*(instr(alpha$, mid$(printStr$,i%,1))-1)+2
l% = l%+header(headerPos%)
next
select case fontStyle
case 0,2,4,6 'normal or italic
case 1,3,5,7 'bold or italic w/ bold
l% = l%+1*len(printStr$)
end select
fontlength% = l%
end function

'*Uses a font file to print text to the screen
'*la%: x-position on the screen to print the font
'*h%: y-position on the screen to print the font
'*printStr$: the string to print
sub fontput (byVal la%, byVal h%, ByVal printStr$) public
l% = la%
def seg = strseg(printStr$)
for i% = 0 to len(printStr$) - 1
prnPtr& = strptr(printStr$) + i%
headerPos% = 3*(instr(alpha$,peek$(prnPtr&,1)) - 1)
charFlen% = header(headerPos%+1)
abc$ = string$(charFlen%," ")
get fontfile%,header(headerPos%),abc$
abcPtr& = strptr(abc$)
finPtr& = abcPtr& + charFlen% - 4
while abcPtr& < finPtr&
    x1% = peek(abcPtr&)+l% : incr abcPtr&
    y1% = peek(abcPtr&)+h% : incr abcPtr&
    x2% = peek(abcPtr&)+l% : incr abcPtr&
    y2% = peek(abcPtr&)+h% : incr abcPtr&
    select case fontStyle
    case 0,4 'normal
        line(x1%,y1%)-(x2%,y2%),fcolor
    case 1,5 'bold
        line(x1%,y1%)-(x2%,y2%),fcolor
        line(x1%+1,y1%)-(x2%+1,y2%),fcolor
    case 2,6 'italic
        line(x1%-.2*(y1%-h%)+3,y1%)-(x2%-.2*(y2%-h%)+3,y2%),fcolor
    case 3,7 'bold+italic
        xa% = x1%-.2*(y1%-h%):xb% = x2%-.2*(y2%-h%)
        line(xa%+3,y1%)-(xb%+3,y2%),fcolor
        line(xa%+4,y1%)-(xb%+4,y2%),fcolor
    end select
wend
select case fontStyle
case 0,2,4,6 'normal or italic
l% = l%+header(headerPos%+2)
case 1,3,5,7 'bold or italic
l% = l%+header(headerPos%+2)+1
end select
next
if fontStyle >= 4 then line(la%,h%+fontbaseline%+1)-(l%,h%+fontbaseline%+1),fcolor
end sub

'*Returns the font baseline
function fontBL() public
fontBL = fontbaseline%
end function

'*Returns the font height
function fontH() public
fontH = fontheight%
end function

'*Returns a constant representing the BOLD property of a font.  To make the font bold, use fontStyle = BOLD.  To make the font BOLD and ITALIC use fontstyle = BOLD + ITALIC
function BOLD() public
BOLD = 1
end function

'*Returns a constant representing the BOLD property of a font.  To make the font italic, use fontStyle = ITALIC.
function ITALIC() public
ITALIC = 2
end function

'*Returns a constant representing the UNDERLINE property of a font.
function UNDERLINE() public
UNDERLINE = 4
end function

'End fonts
'<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
'General Draw Stuff

'*Draw a box using the x and y locations, width and height and style
'*x%: the x-position for the upper left corner of the box
'*y%: the y-position for the upper left corner of the box
'*l%: the outer width of the box in pixels
'*h%: the outer height of the box in pixels
'*style%: the style to use on the box (see FLAT, RAISED, LOWERED, ETCHEDR, ETCHEDL, and NOFILL)
SUB box (byVal x%,  byVal y%, byVal l%, byVal h%, byVal style%) public
xb% = x% + l%
yb% = y% + h%
IF style% < 5 THEN
sty% = style%
LINE (x% + 1, y% + 1)-(xb% - 1, yb% - 1), bcolor, BF
ELSE
sty% = style% - 5
END IF
SELECT CASE sty%
CASE 0: 'flat
LINE (x%, y%)-(xb%, yb%), bcolor, B
CASE 1: 'raised
LINE (x%, y%)-(xb%, y%), 15
LINE (x%, y%)-(x%, yb%), 15
LINE (xb%, y%)-(xb%, yb%), 0
LINE (x%, yb%)-(xb%, yb%), 0
CASE 2: 'lowered
LINE (x%, y%)-(xb%, y%), 0
LINE (x%, y%)-(x%, yb%), 0
LINE (xb%, y%)-(xb%, yb%), 15
LINE (x%, yb%)-(xb%, yb%), 15
CASE 3: 'etched raised
LINE (x%, y%)-(xb%, y%), 15
LINE (x%, y%)-(x%, yb%), 15
LINE (xb%, y%)-(xb%, yb%), 0
LINE (x%, yb%)-(xb%, yb%), 0
xa% = x% + 1: ya% = y% + 1
xb% = xb% - 1: yb% = yb% - 1
LINE (xa%, ya%)-(xb%, ya%), 0
LINE (xa%, ya%)-(xa%, yb%), 0
LINE (xb%, ya%)-(xb%, yb%), 15
LINE (xa%, yb%)-(xb%, yb%), 15
CASE 4: 'etched lowered
LINE (x%, y%)-(xb%, y%), 0
LINE (x%, y%)-(x%, yb%), 0
LINE (xb%, y%)-(xb%, yb%), 15
LINE (x%, yb%)-(xb%, yb%), 15
xa% = x% + 1: ya% = y% + 1
xb% = xb% - 1: yb% = yb% - 1
LINE (xb%, ya%)-(xb%, yb%), 0
LINE (xa%, yb%)-(xb%, yb%), 0
LINE (xa%, ya%)-(xb%, ya%), 15
LINE (xa%, ya%)-(xa%, yb%), 15
END SELECT
END SUB

'*Returns the flat style for a box.
function FLAT() public
FLAT = 0
end function

'*Returns the raised style for a box.
function RAISED() public
RAISED = 1
end function

'*Returns the lowered style for a box.
function LOWERED() public
LOWERED = 2
end function

'*Returns the raised etch style for a box.
function ETCHEDR() public
ETCHEDR = 3
end function

'*Returns the lowered etch style for a box.
function ETCHEDL() public
ETCHEDL = 4
end function

'*Will prevent the box from being filled when drawn by box, if added to any other box style.  For instance to get a lowered unfilled box, use box x%, y%, l%, h%, LOWERED + NOFILL
function NOFILL() public
NOFILL = 5
end function

'*Calculates the x and y position necessary to center an object of length l% between x% and xb%
'*x%: x-position for left side to center over
'*xb%: x-position for right side to center over
'*l%: length of something to center
function center(byVal x%, byVal xb%, byVal l%) public
center = x% + (xb% - x% - l%) / 2
end function

'*Draws a line 3d line
'*x%: the x-position for the start of the line
'*y%: the y-position for the start of the line
'*xd%: the horizontal distance the line traverses
'*yd%: the vertical distance the line traverses
SUB dialine (byVal x%, byVal y%, byVal xd%, byVal yd%) public
LINE (x%, y%)-(x% + xd%, y% + yd%), 8
LINE (x% + 1, y% + 1)-(x% + xd% + 1, y% + yd% + 1), 15
END SUB

'*Draws an arrow, like for a scrollbar.
'*x%: the x-position of the arrow
'*y%: the y-position of the arrow
'*typ%: the type of direction to point the arrow to draw
sub drawArrow(byVal x%, byVal y%, byVal l%, byVal typ%) public
wid% = .75*l%
hei% = wid%*.5
select case typ%
case 0
xa% = center(x%, x% + l%, 0):ya% = center(y%, y% + l%, hei%):xb% = center(x%, x% + l%, wid%):yb% = ya% + hei%:xc% = xb% + wid%:yc% = yb%
case 1
xa% = center(x%, x% + l%, 0):yb% = center(y%, y% + l%, hei%):ya% = yb% + hei%:xb% = center(x%, x% + l%, wid%):xc% = xb% + wid%:yc% = yb%
case 2
ya% = center(y%, y% + l%, 0):xa% = center(x%, x% + l%, hei%):yb% = center(y%, y% + l%, wid%):xb% = xa% + hei%:yc% = yb% + wid%:xc% = xb%
case 3
ya% = center(y%, y% + l%, 0):xb% = center(x%, x% + l%, hei%):xa% = xb% + hei%:yb% = center(y%, y% + l%, wid%):yc% = yb% + wid%:xc% = xb%
end select
line(xa%,ya%)-(xb%,yb%),fcolor
line(xb%,yb%)-(xc%,yc%),fcolor
line(xc%,yc%)-(xa%,ya%),fcolor
paint(x%+l%/2,y%+l%/2),fcolor,fcolor
end sub

'*Draws a check mark, like for a check box
'*x%: the x-position
'*y%: the y-position
sub drawCheck(byVal x%, byVal y%) public
line(x%+2,y%+5)-(x%+4,y%+7),fcolor
line(x%+4,y%+7)-(x%+8,y%+3),fcolor
line(x%+2,y%+6)-(x%+4,y%+8),fcolor
line(x%+4,y%+8)-(x%+8,y%+4),fcolor
end sub

'End General Draw Stuff
'<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
'upperlevel gui library

function graphsize!( l%, h%)
'=========================================================
'This function gives the size for the array needed to
'capture a section of the screen
'=========================================================
graphsize! = 4 + CEIL(l% / 8) * 4 * h%
end function

'--------------------------------------------------------------------------------------------------------------------------------
'Drag dialog code

'*Drags a dotted outline of a dialog box with the mouse cursor
'*xps%: x-position of the upper left corner of the dialog box
'*yps%: y-position of the upper left corner of the dialog box
'*l%: dialog box width
'*h%: dialog box height
sub dragDialog(xps%,yps%, l%, h%) public
'do the move stuff here
deltaX% = xpos% - xps%
deltaY% = ypos% - yps%
oldXPos% = xps%
oldYPos% = yps%
size% = graphsize(2,h%)
dim lside(size%),rside(size%)
size% = graphsize(l%,2)
dim top(size%),bottom(size%)
while but% <> 0
mouseOff
get(xps%,yps%)-(xps%+l%,yps%+1),top
get(xps%,yps%)-(xps%+2,yps%+h%),lside
get(xps%+l%-1,yps%)-(xps%+l%,yps%+h%),rside
get(xps%,yps%+h%-1)-(xps%+l%,yps%+h%),bottom
line(xps%,yps%)-(xps%+l%-1,yps%+h%),7,b,21845
line(xps%+1,yps%)-(xps%+l%,yps%+h%),8,b,21845
line(xps%,yps%+1)-(xps%+l%-1,yps%+h%-1),8,b,21845
line(xps%+1,yps%+1)-(xps%+l%,yps%+h%-1),7,b,21845
mouseOn
waitinput
mouseOff
put(xps%,yps%),top,pset
put(xps%,yps%),lside,pset
put(xps%+l%-1,yps%),rside,pset
put(xps%,yps%+h%-1),bottom,pset
mouseOn
xps% = xpos%-deltaX%
yps% = ypos%-deltaY%
if xps% < 0 then xps% = 0
if xps% > 640-l%-1 then xps% = 640-l%-1
if yps% < 0 then yps% = 0
if yps% > 480-h%-1 then yps% = 480-h%-1
wend
erase top,lside,rside,bottom
end sub

'--------------------------------------------------------------------------------------------------------------------------------
'Text button code

'*Draws a text button
'*cnt%: the index of the screen area associated with this text button
'*text$: the text displayed within the button
sub drawTextButton(byVal x%, byVal y%, byVal xb%, byVal yb%, byVal text$) public
smartMouseOff x%, y%, xb%, yb%
view screen (x%, y%)-(xb%, yb%)
l% = xb% - x%
h% = yb% - y%
box x%, y%, l%, h%, RAISED
fontput center(x%, xb%, fontlength(text$)), center(y%, yb%, fontheight%), text$
view screen
mouseOn
end sub

'*Initializes and draws the textbutton
'*x%: the x-position of the textbutton
'*y%: the y-position of the textbutton
'*xb%: the x-position of the right side
'*yb%: the y-position of the bottom
'*text$: text to display in the button
'*returns: the handle of the associated screen area
function iniTextButton(byVal x%, byVal y%, byVal xb%, byVal yb%, byVal text$) public
cnt% = SA_addTop(x%, y%, xb%, yb%)
drawTextButton x%, y%, xb%, yb%, text$
iniTextButton = cnt%
end function

'*Clicks a text button, doesn't check the position of the mouse cursor
'*cnt%: the index of the screen area associated with this text button
sub clkTextButton(byVal cnt%) public
SA_getCoord SA_getIndex(cnt%), x%, y%, xb%, yb%
l% = xb% - x%
h% = yb% - y%
smartMouseOff x%, y%, xb%, yb%
box x%, y%, l%, h%, LOWERED + NOFILL
mouseOn
while but% > 0
    waitinput
wend
smartMouseOff x%, y%, xb%, yb%
box x%, y%, l%, h%, RAISED + NOFILL
mouseOn
end sub

'--------------------------------------------------------------------------------------------------------------------------------
'Checkbox code

'*Draws a check box, based on the parameters
'*cnt%: the index of the screen area this check box is based upon.
'*text$: the text displayed next to the check box
'*isOn%: a value of TRUE (-1) draws a check in the box, FALSE (0) does not
sub drawCheckbox (byval x1%, byval y1%, byval x2%, byval y2%, byVal text$, byVal isOn%) public
xbo% = x1% + 1
ybo% = y1%+fontBL-11
smartMouseOff x1%, y1%, x2%, y2%
view screen (x1%, y1%)-(x2%, y2%)
tcolor? = bcolor
bcolor = 15
box xbo%, ybo% + 1, 10, 10, LOWERED
bcolor = tcolor?
if isOn% then drawCheck xbo%, ybo%
fontputconstr x1% + 18, y1%, x2%, text$
view screen
mouseOn
end sub

'*Initializes and draws the checkbox.  Initialization includes the creation of a screen area.
'*x%: the x-position of the checkbox.
'*y%: the y-position of the checkbox.
'*xb%: the constraint on the right side (specify maximum screen x-coord for no constraint)
'*yb%: the constraint on the bottom (specify maximum screen y-coord for no constraint)
'*text$: the text to display next to the checkbox.
'*isOn%: the initial value of the checkbox, TRUE (-1) draws a check in the box, FALSE (0) does not
'*returns: the handle of the screen area related to the checkbox.
function iniCheckbox(byVal x%, byVal y%, byVal xb%, byVal yb%, byVal text$, byVal isOn%) public
xb% = min(x% + 18 + fontlength(text$), xb%)
yb% = max(y% + fontH, yb%)
iniCheckbox = SA_addTop(x%, y%, xb%, yb%)
drawCheckbox x%, y%, xb%, yb%, text$, isOn%
end function

'*Clicks a check box, doesn't check the position of the mouse cursor
'*cnt%:the screen area for this checkbox
'*isOn%: the value of the check box.  This subroutine will toggle the value of isOn%.
sub clkCheckbox (byVal cnt%, isOn%) public
isOn% = not(isOn%)
SA_getCoord SA_getIndex(cnt%), x%, y%, x2%, y2%
mouse
while but% > 0
waitinput
wend
drawCheckbox x%, y%, x2%, y2%, "", isOn%
end sub

'--------------------------------------------------------------------------------------------------------------------------------
'Scrollbar code

'*Initializes a scrollbar (horizontal or vertical based on the dimensions) and returns the handle for the associated screen area
'*x%: the x-position for the upper left-hand corner of the scrollbar
'*y%: the y-position for the upper left-hand corner of the scrollbar
'*x2%: the x-position for the bottom right-hand corner of the scrollbar
'*y2%: the y-position for the bottom right-hand corner of the scrollbar
'*bacolor?: the color for the background of the scroll
'*viewCount%: the number of items contained in the viewable region of a list associated with the scrollbar at any given time
'*totalCount%: the number of items contained in the associated list
'*current%: the index of the item to be displayed at the top of the viewable region
'*returns: the handle of the associated screen area
function iniScrollbar(byval x%, byval y%, byval x2%, byval y2%, byval bacolor?, byval viewCount%, byval totalCount%, byval current%) public
toRet% = SA_addTop(x%, y%, x2%, y2%)
drawScrollbar x%, y%, x2%, y2%, bacolor?, viewCount%, totalCount%, current%
iniScrollbar = toRet%
end function

'*Draws a scrollbar (horizontal or vertical based on the dimensions)
'*x%: the x-position for the upper left-hand corner of the scrollbar
'*y%: the y-position for the upper left-hand corner of the scrollbar
'*x2%: the x-position for the bottom right-hand corner of the scrollbar
'*y2%: the y-position for the bottom right-hand corner of the scrollbar
'*bacolor?: the color for the background of the scroll
'*viewCount%: the number of items contained in the viewable region of a list associated with the scrollbar at any given time
'*totalCount%: the number of items contained in the associated list
'*current%: the index of the item to be displayed at the top of the viewable region
sub drawScrollbar(byval x%, byval y%, byval x2%, byval y2%, byval bacolor?, byval viewCount%, byval totalCount%, byval current%) public
smartMouseOff x%, y%, x2%, y2%
tcolor? = bcolor
bcolor = bacolor?
box x% - 1, y% - 1, x2% - x% + 2, y2% - y% + 2, LOWERED
bcolor = tcolor?
drawScrollBut x%, y%, x2%, y2%, bacolor?, viewCount%, totalCount%, current%
mouseOn
end sub

'A scrollbar helper function, calculates the screen position of the slider and it's size
sub scrollbarHA(byval y%, byval y2%, byval l%, byval current%, byval viewCount%, byval totalCount%, scrollBwidth%, scrollPos%, distance%, upper%, lower%)
upper% = y% + l% + 1
distance% = y2% - y% - 2 * l% - 2
scale! = distance% / totalCount%
scrollBWidth% = viewCount% *scale!
scrollPos% = upper% + current% * scale!
lower% = upper% + distance% - scrollBWidth%
end sub

'*Takes care of the behavior of the scrollbar when clicked.
'*cnt: the handle of the associated screen area
'*bacolor?: the color for the background of the scroll
'*viewCount%: the number of items contained in the viewable region of a list associated with the scrollbar at any given time
'*totalCount%: the number of items contained in the associated list
'*current%: the index of the item to be displayed at the top of the viewable region.  This is updated accordingly.
sub clkScrollbar(byval cnt%, byval bacolor?, byval viewCount%, byval totalCount%, current%) public
SA_getCoord SA_getIndex(cnt%), x%, y%, x2%, y2%
if x2% - x% > y2% - y% then
    l% = y2% - y%
    scrollbarHA x%, x2%, l%, current%, viewCount%, totalCount%, scrollBwidth%, scrollPos%, distance%, upper%, lower%
    buttonA% = SA_addTop(x%, y%, x% + l%, y2%)
    buttonB% = SA_addTop(x2%-l%, y%, x2%, y2%)
    buttonC% = SA_addTop(scrollPos%, y%, scrollPos% + scrollBWidth%, y2%)
else
    l% = x2% - x%
    scrollbarHA y%, y2%, l%, current%, viewCount%, totalCount%, scrollBwidth%, scrollPos%, distance%, upper%, lower%
    buttonA% = SA_addTop(x%, y%, x2%, y%+l%)
    buttonB% = SA_addTop(x%, y2%-l%, x2%, y2%)
    buttonC% = SA_addTop(x%, scrollPos%, x2%, scrollPos% + scrollBWidth%)
end if
select case SA_mouseOver
case buttonA%
    decr current%
    SA_getCoord SA_getIndex(buttonA%), xaa%, yaa%, xaa2%, yaa2%
    mouseOff
    line(xaa%, yaa%)-(xaa2%, yaa2%), bcolor, b
    mouseOn
case buttonB%
    incr current%
    SA_getCoord SA_getIndex(buttonB%), xaa%, yaa%, xaa2%, yaa2%
    mouseOff
    line(xaa%, yaa%)-(xaa2%, yaa2%), bcolor, b
    mouseOn
case buttonC%
    if x2% - x% > y2% - y% then
        delta% = xpos% - scrollPos%
        waitinput
        while but% > 0
            waitinput
            scrollPos% = xpos% - delta%
            drawSBHAH x%, y%, x2%, y2%, l%, scrollPos%, scrollBWidth%, bacolor?, upper%, lower%
        wend
        scrollP% = scrollPos% - upper%
    else
        delta% = ypos% - scrollPos%
        waitinput
        while but% > 0
            waitinput
            scrollPos% = ypos% - delta%
            drawSBHAV x%, y%, x2%, y2%, l%, scrollPos%, scrollBWidth%, bacolor?, upper%, lower%
        wend
        scrollP% = scrollPos% - upper%
    end if
    current% = scrollP% / distance% * totalCount%
end select
mouse
if scrollActive% then
    sleep 0.1
elseif but% > 0 then
    sleep 0.1
    mouse
    if but% > 0 then
        sleep 0.1
        mouse
        if but% > 0 then sleep 0.1
    end if
end if
mouse
mouseOff
drawScrollBut x%, y%, x2%, y2%, bacolor?, viewCount%, totalCount%, current%
if but% > 0 then
    scrollActive% = -1
    a% = SA_mouseOver
    if a% <> cnt% then
        SA_getCoord SA_getIndex(a%), x%, y%, x2%, y2%
        line(x%, y%)-(x2%, y2%), bcolor, b
    end if
else
    scrollActive% = 0
end if
mouseOn
SA_delete SA_getIndex(buttonC%)
SA_delete SA_getIndex(buttonB%)
SA_delete SA_getIndex(buttonA%)
end sub

'Draws the buttons and slider of the scrollbar (horizontal or vertical based on the dimensions).  This subroutine is used for updating the scrollbar with reduced flicker.
'x%: the x-position for the upper left-hand corner of the scrollbar
'y%: the y-position for the upper left-hand corner of the scrollbar
'x2%: the x-position for the bottom right-hand corner of the scrollbar
'y2%: the y-position for the bottom right-hand corner of the scrollbar
'bacolor?: the color for the background of the scroll
'viewCount%: the number of items contained in the viewable region of a list associated with the scrollbar at any given time
'totalCount%: the number of items contained in the associated list
'current%: the index of the item to be displayed at the top of the viewable region
sub drawScrollBut(byval x%, byval y%, byval x2%, byval y2%, byval bacolor?, byval viewCount%, byval totalCount%, current%)
if current% < 0 then current% = 0
if current% > totalCount% - viewCount% then current% = totalCount% - viewCount%
if x2% - x% > y2% - y% then
    'horizontal
    l% = y2% - y%
    box x%, y%, l%, l%, RAISED
    drawArrow x%, y%, l%, 2
    box x2% - l%, y%, l%, l%, RAISED
    drawArrow x2% - l%, y%, l%, 3
    scrollbarHA x%, x2%, l%, current%, viewCount%, totalCount%, scrollBwidth%, scrollPos%, distance%, upper%, lower%
    drawSBHAH x%, y%, x2%, y2%, l%, scrollPos%, scrollBWidth%, bacolor?, upper%, lower%
else
    'vertical
    l% = x2% - x%
    box x%, y%, l%, l%, RAISED
    drawArrow x%, y%, l%, 0
    box x%, y2% - l%, l%, l%, RAISED
    drawArrow x%, y2% - l%, l%, 1
    scrollbarHA y%, y2%, l%, current%, viewCount%, totalCount%, scrollBwidth%, scrollPos%, distance%, upper%, lower%
    drawSBHAV x%, y%, x2%, y2%, l%, scrollPos%, scrollBWidth%, bacolor?, upper%, lower%
end if
end sub

'A helper for the scrollbar functions, draws the scroll area for the vertical scrollbar
sub drawSBHAV(byval x%, byval y%, byval x2%, byval y2%, byval l%, byval scrollPos%, byval scrollBWidth%, byval bacolor?, byval upper%, byval lower%)
if scrollPos% < upper% then
    scrollPos% = upper%
elseif scrollPos% > lower% then
    scrollPos% = lower%
end if
mouseOff
box x%, scrollPos%, l%, scrollBWidth%, RAISED
if scrollPos% > upper% then line(x%, upper%)-(x2%, scrollPos% - 1), bacolor?, bf
if scrollPos% < lower% then line(x%, scrollPos% + scrollBWidth% + 1)-(x2%, lower% + scrollBwidth%), bacolor?, bf
mouseOn
end sub

'A helper for the scrollbar functions, draws the scroll area for the horizontal scrollbar
sub drawSBHAH(byval x%, byval y%, byval x2%, byval y2%, byval l%, byval scrollPos%, byval scrollBWidth%, byval bacolor?, byval upper%, byval lower%)
if scrollPos% < upper% then
    scrollPos% = upper%
elseif scrollPos% > lower% then
    scrollPos% = lower%
end if
mouseOff
box scrollPos%, y%, scrollBwidth%, l%, RAISED
if scrollPos% > upper% then line(upper%, y%)-(scrollPos% - 1, y2%), bacolor?, bf
if scrollPos% < lower% then line(scrollPos% + scrollBWidth% + 1, y%)-(lower% + scrollBWidth%, y2%), bacolor?, bf
mouseOn
end sub

'--------------------------------------------------------------------------------------------------------------------------------
'The dropdown menu and main menu code

'*Modifies lastret? and lastSA% to coordinate events on the main menu bar.
'*lastret?:  the last returned value from a main drop down menu.  This subroutine will set this value to zero.
'*lastSA%:   the last Screen area returned from a mouse event.  This subroutine will modify this value.
'*SA_Button%(): an array of Screen areas associated with the main menu bar headers (eg. File, Edit, etc.)
sub mainMenuHandler(lastret?, lastSA%, SA_Button%()) public
if lastret? = 255 and but% = 0 then
        select case kbd$
        case chr$(0)+"K"        'Right
                array scan SA_Button%(), =lastSA%, to menuNo%
                menuNo% = menuNo% - 2
                if menuNo% < 0 then menuNo% = ubound(SA_Button%())
                lastSA% = SA_Button%(menuNo%)
        case chr$(0)+"M"        'Left
                array scan SA_Button%(), =lastSA%, to menuNo%
                if menuNo% > ubound(SA_Button%()) then menuNo% = 0
                lastSA% = SA_Button%(menuNo%)
        case else
                waitInput
                lastSA% = SA_MouseOver
        end select
else
        waitInput
        lastSA% = SA_MouseClick
end if
lastret? = 0
end sub

'*Draws the main menu bar given menuHeader$()
'*menuHeader$():  an array of the strings of each menu on the main menu bar.  For example, to have a "File" and "Help" menu, menuHeader$(0) = "File" and menuHeader$(1) = "Help".
sub drawMainMenu(menuHeader$()) public
box 0,0,640,fontH+4, RAISED
box 0,476-fontH,640,fontH+4, ETCHEDR
x% = 10
for i% = 0 to ubound(menuHeader$)
    fontput x%, 2, menuHeader$(i%)
    x% = x%+fontlength(menuHeader$(i%))+10
next
end sub

'*Initializes and draws the main menu given menuHeader$() and an empty array of the same dimensions, SA_button%()
'*menuHeader$():  an array of the strings of each menu on the main menu bar.  For example, to have a "File" and "Help" menu, menuHeader$(0) = "File" and menuHeader$(1) = "Help".
'*SA_Button%(): an array of Screen areas associated with the main menu bar headers (eg. File, Edit, etc.).  This subroutine will create screen areas and fill this array.
sub iniMainMenu(menuHeader$(), SA_button%()) public
x% = 10
for i% = 0 to ubound(menuHeader$)
    fl% = fontlength(menuHeader$(i%))
    SA_button%(i%) = SA_addTop(x%-1,1,x%+fl%+1,fontH+2)
    SA_setMButton SA_button%(i%), 1
    x% = x%+fl%+10
next
statusBarSet 10,478-fontH, 600
drawMainMenu menuHeader$()
end sub

'*Handles a click on the main menu to produce a single dropdown menu.  Will not return unless a menu item in chosen, the left, the right, or the escape key is pressed, the user moves the mouse over another menu, or the user clicks outside of the menu.
'*Format of a menu-item in the menu$() array:
'*[option Code][LeftSide]^[RightSide]|[Help]>[more]
'*Option Codes: #   Disabled
'*          *   Selected (Dot)
'*          $   Selected (Checkmark)
'*          -   Horizontal Line, all other values ignored.
'*more:  if 255, then last in list
'*menuHeader$():  an array of the strings of each menu on the main menu bar.  For example, to have a "File" and "Help" menu, menuHeader$(0) = "File" and menuHeader$(1) = "Help".
'*SA_Button%(): an array of Screen areas associated with the main menu bar headers (eg. File, Edit, etc.)
'*menu$(): an array of menu items which are to be parsed in creating a dropdown menu.
function clkMainMenu?(byVal cnt%, menuHeader$(), SA_button%(), menu$()) public
cnt% = SA_getIndex(cnt%)
array scan SA_button%(), =cnt%, to menuNo%
decr menuNo%
x% = 10
SA_getCoord cnt%,x%,y%,x2%,y2%
SmartMouseOff x%,y%,x2%,y2%
line (x%,y%)-(x2%,y2%),hbcolor,bf
swap fcolor, hfcolor
fontput x%+1, y%+1, menuHeader$(menuNo%)
mouseOn
swap fcolor, hfcolor
SA_button%(menuNo%) = -2
clkMainMenu = DDMenu(x%-2,y2%+2,menu$(),SA_button%(), 1)
SA_button%(menuNo%) = cnt%
SmartMouseOff x%,y%,x2%,y2%
line (x%,y%)-(x2%,y2%),bcolor,bf
fontput x%, 2, menuHeader$(menuNo%)
mouseOn
end function

'*Handles a click to produce a single dropdown box.  Will not return unless a menu item in chosen, the escape key is pressed, or the user clicks outside of the menu.
'*Format of a menu-item in the menu$() array:
'*[option Code][LeftSide]^[RightSide]|[Help]>[more]
'*Option Codes: #   Disabled
'*          *   Selected (Dot)
'*          $   Selected (Checkmark)
'*          -   Horizontal Line, all other values ignored.
'*more:  if 255, then last in list
'*x%: the x-position of the menu
'*y%: the y-position of the menu
'*menu$(): an array of menu items which are to be parsed in creating a dropdown menu.
function DropDownMenu?(byVal x%, byVal y%, menu$()) public
dim esc(0) as integer
esc(0) = -2
DropdownMenu = DDMenu(x%,y%,menu$(), esc(), 0)
end function

'DDMenu and ddMenuHelper are the guts behind the dropdown menu and main menu.
function DDMenu?(byVal x%, byVal y%, menu$(), esc%(), byVal lr?)
ub% = ubound(menu$)
dim lef$(ub%), rig$(ub%), hlp$(ub%), opt?(ub%), mor?(ub%)
for i% = 0 to ubound(menu$)
parseMenuItem menu$(i%),lef$(i%),rig$(i%),hlp$(i%),opt?(i%),mor?(i%)
next
DDMenu = ddMenuHelper(x%, y%, 0, lef$(), rig$(), hlp$(), opt?(), mor?(), esc%(),lr?)
end function

function ddMenuHelper%(byVal x%, byVal y%, byVal top?, lef$(), rig$(), hlp$(), opt?(), mor?(), esc%(), byVal lr?)
l% = 0:lh% = 0:bot? = top?
while mor?(bot?) < 255 and bot? <= ubound(opt?)-1
    l% = max(l%,fontlength(lef$(bot?))+fontlength(rig$(bot?)))
    lh% = max(lh%,fontlength(hlp$(bot?)))
    bot? = bot? + 1
wend
l% = max(l%,fontlength(lef$(bot?))+fontlength(rig$(bot?)))+50
lh% = max(lh%,fontlength(hlp$(bot?)))
h% = (bot?-top?+1)*(fontH+2)+6
if x% + l% > 639 then
    x% = 639-l%
end if
if y%+h% > 479 then
    y% = 479-h%
end if
size% = graphsize(l%,h%)
dim graphic(size%) as integer
smartMouseOff x%,y%,x%+l%,y%+h%
get (x%,y%)-(x%+l%,y%+h%),graphic
graphfile$ = BSaveInt$(graphic())
erase graphic
box x%,y%,l%,h%,1
sel? = -1:oldsel? = -1
dim but(top? to bot?) as integer
ya% = y%+3
for i% = top? to bot?
    but(i%) = SA_addTop(x%+3,ya% - 1,x%+l%-3,ya%+fontH+1)
    drawMenuItem x%,ya%,l%,lef$(i%),rig$(i%),opt?(i%),mor?(i%)
    ya% = ya%+fontH+2
next
mouseOn
done? = 0
while done? = 0
    highlightMenu x%,y%,l%,sel?,oldsel?,top?,lef$(),rig$(),opt?(),mor?(), hlp$()
    waitinput
    'process events
    chklast% = SA_mouseOver
    array scan esc%(), =chklast%, to i%
    if i% > 0 then
        sel? = -1
        done? = 1
    else
        array scan but%(), =chklast%, to i%
        if i% > 0 then
            sel? = top?+i%-1
            if mor?(sel?) > 0 and mor?(sel?)<255 then
                highlightMenu x%,y%,l%,sel?,oldsel?,top?,lef$(),rig$(),opt?(),mor?(), hlp$()
                recurs:
                'make the recursive call
                dim recEsc%(bot?-top?+ubound(esc%))
                ind% = 0
                for j% = top? to top?+i%-2
                    recEsc%(ind%) = but%(j%)
                    incr ind%
                next
                for j% = top?+i% to bot?
                    recEsc%(ind%) = but%(j%)
                    incr ind%
                next
                for j% = 0 to ubound(esc%)
                    recEsc%(ind%) = esc%(j%)
                    incr ind%
                next
                a% = 0:abot? = mor?(sel?)
                la% = 0
                while mor?(abot?) < 255 and abot? <= ubound(opt?)-1
                    la% = max(la%,fontlength(lef$(abot?))+fontlength(rig$(abot?)))
                    abot? = abot? + 1
                wend
                la% = la%+50
                xa% = x%+l%-2
                if xa%+la% > 639 then
                    xa%=x%-la%+2
                end if
                sel? = ddMenuHelper%(xa%,y%+(i%-1)*(fontH+2),mor?(sel?),lef$(),rig$(),hlp$(),opt?(),mor?(), recEsc%(),1)
                erase recEsc%
                array scan but%(), =chklast%, to j%
                if (sel? = 255 and j% = 0) then
                    if kbd$ <> chr$(27) and kbd$ <> chr$(0)+"M" and kbd$<>chr$(0)+"K" then
                        sel? = -1:done?=1:exit loop
                    end if
                    kbd$ = ""
                elseif(sel?<255) then
                    done?=1:exit loop
                end if
            end if
            if opt?(sel?) = 5 or opt?(sel?) = 1 then but% = 0 'dont process a bar
        end if                                         'or a disable
    end if
    if but% > 0 then
        'process a mouse click
        if i% = 0 then
            sel? = -1:done?=1:exit loop
        else
            if mor?(sel?) = 0 or mor?(sel?) = 255 then done? = 1:exit loop
        end if
    end if
    'process any other keys
    select case kbd$
    case chr$(0) +"H"'up
        if sel? < 255 then sel? = sel?-1
        if opt?(sel?) = 5 then sel? = sel?-1
        if sel? < top? or sel? = 255 then sel? = bot?
    case chr$(0)+"P" 'down
        if sel? < 255 then sel? = sel?+1
        if opt?(sel?) = 5 then sel? = sel?+1
        if sel? > bot? or sel? = 255 then sel? = top?
    case chr$(0)+ "K"  'left
        if lr? <> 0 then done? = 1:sel? = -1:exit loop
    case chr$(0)+ "M" 'right
        if mor?(sel?) > 0 and mor?(sel?) < 255 then
            'make the recursive call
            i% = sel?-top?+1
            goto recurs
        else
            righ:
            if lr? <> 0 then done? = 1:sel? = -1:exit loop
        end if
    case chr$(13) 'enter
        if mor?(sel?) > 0 and mor?(sel?) < 255 then
            'make a recursive call
            i% = sel?-top?+1
            goto recurs
        elseif opt?(sel?) <> 1 then
            done? = 1:exit loop
        end if
    case chr$(27) 'esc
        sel? = -1:done? = 1:exit loop
    end select
wend
dim graphic(size%) as integer
BLoadInt graphfile$,graphic()
kill graphfile$
smartMouseOff x%,y%,x%+l%,y%+h%
put (x%,y%), graphic, pset
mouseOn
for i% = bot? to top? step -1
    SA_delete but(i%)
next
erase graphic
erase but%
DDmenuhelper% = sel?
end function

function BSaveInt$(intArr%()) public
f$ = dir$("0.dat")
i% = 1
mask$ = "0.dat"
while f$ <> ""
mask$ = ltrim$(rtrim$(str$(i%)))+".dat"
f$ = dir$(mask$)
incr i%
wend
Segm   = VARSEG(intArr%(0))
Offs   = VARPTR(intArr%(0))
Length = (UBOUND(intArr%) + 1) *2
DEF SEG = Segm
BSAVE mask$, Offs, Length
BSaveInt$ = mask$
DEF SEG
end function

sub BLoadInt(filename$,intArr%()) public
DEF SEG = VARSEG(intArr%(0))
BLOAD filename$, VARPTR(intArr%(0))
DEF SEG
end sub

sub highlightMenu(byVal x%, byVal y%, byVal l%, byVal sel?, oldsel?, byVal top?, lef$(), rig$(), opt?(), mor?(), hlp$())
if oldsel? <> sel? and opt?(sel?) < 5 then
    ya% = y%+3+(oldsel?-top?)*(fontH+2)
    smartMouseOff x%,ya%,x%+l%,ya%+fontH+2
    line(x%+2,ya%)-(x%+l%-2,ya%+fontH),bcolor,bf
    drawMenuItem x%, ya%,l%,lef$(oldsel?),rig$(oldsel?),opt?(oldsel?),mor?(oldsel?)
    swap fcolor, hfcolor
    ya% = y%+3+(sel?-top?)*(fontH+2)
    mouseOn
    smartMouseOff x%,ya%,x%+l%,ya%+fontH+2
    line(x%+2,ya%)-(x%+l%-2,ya%+fontH),hbcolor,bf
    drawMenuItem x%, ya%,l%,lef$(sel?),rig$(sel?),opt?(sel?),mor?(sel?)
    swap fcolor, hfcolor
    mouseOn
    statusBarMsg hlp$(sel?)
    oldsel? = sel?
end if
end sub

'*Set the position of the status bar
'*x%:  x-coordinate of the upper left corner
'*y%:  y-coordinate of the upper left corner
'*w%:  width of the status bar in pixels (height given by fontH)
sub statusBarSet(x%, y%, w%) public
statusX% = x%
statusY% = y%
statusW% = w%
end sub

'*Display a message in the status bar
'*message$: the message to display.  A null string will clear the status bar
sub statusBarMsg(message$) public
xb% = statusX%+statusW%
yb% = statusY%+fontH
smartMouseOff statusX%, statusY%, xb%, yb%
line(statusX%,statusY%)-(xb%,yb%),bcolor,bf
fontput statusX%,statusY%,message$
mouseOn
end sub

sub drawMenuItem(byVal x%, byVal y%, byVal l%, lef$, rig$, byVal opt?, byVal mor?)
if mor? > 0 and mor? < 255 then drawarrow x%+l%-16,y%+fontBL/2-6,14,3
select case opt?
case 1:swap fcolor, dcolor
case 2:
    xa% = x%+8
    ya% = y%+fontBL/2
    circle(xa%,ya%),2,fcolor
    paint(xa%,ya%),fcolor,fcolor
    case 3:drawcheck x%+3,y%
case 5:dialine x%+6,y%+fontH/2,l%-12,0
end select
fontput x%+14,y%,lef$
fontput x%+l%-18-fontlength(rig$),y%,rig$
if opt? = 1 then swap fcolor, dcolor
end sub

sub parseMenuItem(menu$,lef$,rig$,hlp$,opt?,mor?)
opt? = 0
fir$ = left$(menu$,1)
select case fir$
case "#":opt? = 1
case "*":opt? = 2
case "$":opt? = 3
case "-":opt? = 5
case else
end select
if opt? > 0 then menu$ = mid$(menu$,2)
p% = instr(menu$,"^")
s% = instr(menu$,"|")
r% = instr(menu$,">")
if r% = 0 then
    mor? = 0
    r% = len(menu$)+1
else
    mor? = val(right$(menu$,len(menu$)-r%))
end if
if s% = 0 then
    hlp$ = ""
    s% = r%
else
    hlp$ = mid$(menu$,s%+1,r%-s%-1)
end if
if p% = 0 then
    rig$ = ""
    p% = s%
else
    rig$ = mid$(menu$,p%+1,s%-p%-1)
end if
lef$ = left$(menu$,p%-1)
end sub

'------------------------------------------------------------------------------
'Button bar code

'*Initializes the button bar
'*x1%: the x-coordinate of the upper left corner of the button bar
'*y1%: the y-coordinate of the upper left corner of the button bar
'*x2%: the x-coordinate of the lower right corner of the button bar
'*iconfile$(): an array listing the icon files for each button on the bar.  If iconfile$(i%) = "|" then position is a diagonal line
'*iconNo%(): an array listing the icon number in the files for each button on the bar
'*enab?(): an array indicating whether the button is enabled or not.  If SA_but(i%) is disabled then enab?(i%) = 0
'*SA_but%(): an array that is filled with handles to the screen areas associated with each button on the bar
sub iniButtonBar(byval x1%, byval y1%, byval x2%, iconfile$(), iconNo%(), enab?(), SA_but%()) public
x% = x1% + 2
y% = y1% + 2
for i% = 0 to ubound(iconNo%())
    if iconfile$(i%) = "|" then
        SA_but%(i%) = -2
        x% = x% + 4
    else
        SA_but%(i%) = SA_addTop(x%, y%, x%+20, y%+20)
        if enab?(i%) = 0 then SA_setMButton SA_but%(i%),3
        x% = x% + 24
    end if
next
drawButtonBar x1%,y1%,x2%,iconfile$(),iconNo%(), SA_but%()
end sub

'*Draws the button bar
'*x1%: the x-coordinate of the upper left corner of the button bar
'*y1%: the y-coordinate of the upper left corner of the button bar
'*x2%: the x-coordinate of the lower right corner of the button bar
'*iconfile$(): an array listing the icon files for each button on the bar
'*iconNo%(): an array listing the icon number in the files for each button on the bar
sub drawButtonBar(x1%, y1%, x2%, iconfile$(), iconNo%(), SA_but%()) public
box x1%, y1%, x2% - x1%, 24, RAISED
x% = x1% + 2
y% = y1% + 2
for i% = 0 to ubound(iconNo%())
    if iconfile$(i%) = "|" then
        dialine x%,y%,0,19
        x% = x% + 4
    else
        drawIcon x%,y%,iconfile$(i%),iconNo%(i%)
        if SA_getMButton(SA_but%(i%)) > 2 then
            a% = &B0101010101010101
            xb% = x%+20
            yb% = y%+20
            for j% = y% to yb%
                line(x%,j%)-(xb%,j%),bcolor?,,a%
                rotate left a%,1
            next
        end if
        x% = x% + 24
    end if
next
end sub

'*Clicks the button bar, doesn't check the position of the mouse cursor
'*cnt%: the handle of the screen area associated with this button on the button bar
sub clickButtonBar(cnt%) public
SA_getCoord SA_getIndex(cnt%), x%, y%, xb%, yb%
l% = xb% - x%
h% = yb% - y%
smartMouseOff x%, y%, xb%, yb%
box x%, y%, l%, h%, LOWERED + NOFILL
mouseOn
while but% > 0
    waitinput
wend
smartMouseOff x%, y%, xb%, yb%
if SA_mouseOver = cnt% then
    box x%, y%, l%, h%, RAISED + NOFILL
else
    box x%, y%, l%, h%, FLAT + NOFILL
end if
mouseOn
end sub

'*Behavior of hovering over the button on the button bar.  Doesn't check the position of the mouse cursor
'*cnt%: the handle of the screen area associated with this button on the button bar
sub mouseOverButtonBar(cnt%, statusBarText$) public
if SA_getMButton(cnt%) <= 2 then
    SA_getCoord SA_getIndex(cnt%), x%, y%, xb%, yb%
    l% = xb% - x%
    h% = yb% - y%
    smartMouseOff x%, y%, xb%, yb%
    box x%, y%, l%, h%, RAISED + NOFILL
    statusBarMsg statusBarText$
    mouseOn
    while SA_mouseOver = cnt% and but% = 0
        waitinput
    wend
    smartMouseOff x%, y%, xb%, yb%
    box x%, y%, l%, h%, FLAT + NOFILL
    statusBarMsg ""
    mouseOn
end if
end sub

'*Returns the number of icons in the icon file
'*fileName$: the filename of the icon file
'*RETURN: the number of icons in the file
function numIcon(fileName$) public
fileNo% = freefile
open fileName$ for binary as fileNo%
get fileNo%, 0, loca%
numIcon = loca%/4
end function

'*Draws an icon with the upper left corner at x%,y%
'*x%: the x-coordinate of the upper left corner of the icon
'*y%: the y-coordinate of the upper left corner of the icon
'*fileName$: the file to get the icon from
'*num%: the index of the icon in the file
sub drawIcon(x%,y%,fileName$,num%) public
fileNo% = freefile
open fileName$ for binary as fileNo%
get fileNo%, 4*num%, loca%
get fileNo%, , leng%
icon$ = string$(leng%, " ")
get fileNo%, loca%, icon$
close fileNo%
draw "BM"+ltrim$(rtrim$(str$(x%)))+","+ltrim$(rtrim$(str$(y%)))
draw icon$
end sub


'------------------------------------------------------------------------------
'Text box code

'*Wait for mouse of keyboard input, but allows a cursor to blink on the screen
'*x%: the x-position of the cursor
'*y%: the y-position of the cursor
'*chs$: the character at the cursor location (for insert redraw of character)
sub waitCursor(byval x%, byval y%, chs$) public
if (curx% <> x% or cury% <> y%) and curx% < 641 then
    if cursorState > 0 then
        gosub chgCursor
    end if
end if
if cursorState = 2 then gosub chgCursor
curx% = x%: cury% = y%: ch$ = chs$
cursorState = 0
waitinput
end sub

'*Sends a click message to the textbox and executes handling of the click
'*hndl%:  the Screen Area handle
'*text$:  the text in the textbox at the time of the click
sub clkTextBox(byval hndl%, text$) public
SA_getCoord SA_getIndex(hndl%), x%, y%, x2%, y2%
offset% = 1
oldOffset% = 0
curx% = 641                  'Don't draw cursor for now
do
    selA% = nearLetPos%(x%+2, xpos%, offset%, text$)
    selB% = selA%
    oldSelA% = selA%
    oldSelB% = selA%
    while but% > 0
        waitinput
        if xpos% > x% then
            if xpos% > x2% and fontlength(mid$(text$, offset%)) > x2% - x% - 4 then
                offset% = offset% + 10
                oldSelB% = oldSelB% + 10
            end if
        else
            offset% = offset% - 10
            if oldSelA% > 10 then oldSelA% = oldSelA% - 10
            if offset% < 1 then offset% = 1
        end if
        selB% = nearLetPos%(x%+2, xpos%, offset%, text$)
        if offset% <> oldOffset% then
            drawTextBox x%, y%, x2%, y2%, text$, offset%, min(selA%, selB%), max(selA%, selB%)
            oldOffset% = offset%
        else
            drawSelect x%, y%, x2%, y2%, selA%, selB%, oldSelA%, oldSelB%, text$, offset%
        end if
    wend
    curpos% = selB%
    newx% = letScrPos%(x%, offset%, curpos%, text$)
    timerOn
    on timer(0.4) gosub chgCursor
    while but% = 0
        select case kbd$
        case chr$(0) + "M"  'right
            if (keystatus and 3) then
                if selA% = selB% then
                    selA% = curpos%
                    selB% = curpos%+1
                    oldSelA% = selA%
                    oldSelB% = selB%
                    if selB% > len(text$)+1 then selB% = len(text$)+1
                    drawTextBox x%, y%, x2%, y2%, text$, offset%, min(selA%, selB%), max(selA%, selB%)
                else
                    incr selB%
                    if selB% > len(text$)+1 then selB% = len(text$)+1
                    drawSelect x%, y%, x2%, y2%, selA%, selB%, oldSelA%, oldSelB%, text$, offset%
                end if
            elseif selA% <> selB% then
                selA% = selB%
                drawTextBox x%, y%, x2%, y2%, text$, offset%, 0, 0
            end if
            incr curpos%
            if curpos% > len(text$)+1 then curpos% = len(text$)+1
        case chr$(0) + "P"  'down
        case chr$(0) + "K"  'left
            if (keystatus and 3) then
                if selA% = selB% then
                    selA% = curpos%
                    selB% = curpos% - 1
                    oldSelA% = selA%
                    oldSelB% = selB%
                    if selB% < 1 then selB% = 1
                    drawTextBox x%, y%, x2%, y2%, text$, offset%, min(selA%, selB%), max(selA%, selB%)
                else
                    decr selB%
                    if selB% < 1 then selB% = 1
                    if selB% >= offset% then
                        drawSelect x%, y%, x2%, y2%, selA%, selB%, oldSelA%, oldSelB%, text$, offset%
                    end if
                end if
            elseif selA% <> selB% then
                selA% = selB%
                drawTextBox x%, y%, x2%, y2%, text$, offset%, 0, 0
            end if
            decr curpos%
            if curpos% < 1 then curpos% = 1
        case chr$(0) + "H"  'up
        case chr$(13), chr$(9), chr$(27)    'enter, tab, esc
            cursorState = 1
            smartMouseOff curx%, cury%, curx% + 2, cury% + fontH
            line (curx%, cury%)-(curx%, cury% + fontH), bcolor
            line (curx%-1, cury%)-(curx%+1, cury%), bcolor
            line (curx%-1, cury%+fontH)-(curx%+1, cury% + fontH), bcolor
            mouseOn
            timer off
            exit sub
        case chr$(8)            'backspace
            if selA% = selB% then
                if curpos% > 1 then text$ = left$(text$, curpos% - 2) + mid$(text$, curpos%)
                decr curpos%
                if curpos% < 1 then curpos% = 1
            else
                text$ = left$(text$, min(selA%,selB%)-1) + mid$(text$, max(selA%,selB%))
                curpos% = min(selA%,selB%)
                selA% = curpos%
                selB% = curpos%
            end if
            drawTextBox x%, y%, x2%, y2%, text$, offset%, 0, 0
        case chr$(0) + "S"  'delete
            if selA% = selB% then
                text$ = left$(text$, curpos% - 1) + mid$(text$, curpos%+1)
            else
                text$ = left$(text$, min(selA%,selB%)-1) + mid$(text$, max(selA%,selB%))
                curpos% = min(selA%,selB%)
                selA% = curpos%
                selB% = curpos%
            end if
            drawTextBox x%, y%, x2%, y2%, text$, offset%, 0, 0
        case chr$(0) + "G"  'home
            if (keystatus and 3) then
                if selA% = selB% then
                    selA% = curpos%
                    oldSelB% = selA%
                end if
                selB% = 1
                oldSelA% = selB%
                drawTextBox x%, y%, x2%, y2%, text$, offset%, selB%, selA%
            elseif selA% <> selB% then
                selA% = selB%
                drawTextBox x%, y%, x2%, y2%, text$, offset%, 0, 0
            end if
            curpos% = 1
        case chr$(0) + "O"  'end
            if (keystatus and 3) then
                if selA% = selB% then
                    selA% = curpos%
                    oldSelA% = selA%
                end if
                selB% = len(text$)+1
                oldSelB% = selB%
                drawTextBox x%, y%, x2%, y2%, text$, offset%, selA%, selB%
            elseif selA% <> selB% then
                selA% = selB%
                drawTextBox x%, y%, x2%, y2%, text$, offset%, 0, 0
            end if
            curpos% = len(text$)+1
        case ""
        case else
            if left$(kbd$,1) <> chr$(0) then
                if selA% = selB% then
                    if (keystatus and 128) then       'If insert
                        text$ = left$(text$, curpos%-1) + kbd$ + mid$(text$, curpos%+1)
                    else
                        text$ = left$(text$, curpos%-1) + kbd$ + mid$(text$, curpos%)
                    end if
                    smartMouseOff newx%-1, y%, x2%, y2%
                    line(newx% - 1, y% + 2)-(x2% - 2, y2% - 2), bcolor, bf
                    if newx% < x2%-2 then fontPutConstr newx%, y% + 2, x2%-2, mid$(text$, curpos%)
                    mouseOn
                    incr curpos%
                    curx% = 641      'Don't draw cursor for now
                else
                    selectA% = min(selA%, selB%)
                    selectB% = max(selA%, selB%)
                    text$ = left$(text$, selectA% - 1) + kbd$ + mid$(text$, selectB%)
                    curpos% = selectA% + 1
                    selA% = curpos%
                    selB% = curpos%
                    drawTextBox x%, y%, x2%, y2%, text$, offset%, 0, 0
                end if
            end if
        end select
        'take care of wrapping
        oldoffset% = offset%
        flag = 0
        while flag = 0
            if offset% > curpos% then
                offset% = offset% - 10
                flag = 0
            elseif fontlength(mid$(text$, offset%, curpos% - offset%+1)) > x2% - x% - 4 then
                offset% = offset% + 10
                flag = 0
            else
                flag = -1
            end if
        wend
        if oldoffset% <> offset% then drawTextBox x%, y%, x2%, y2%, text$, offset%, min(selA%,selB%), max(selA%,selB%)
        newx% = letScrPos%(x%, offset%, curpos%, text$)
        waitcursor newx%-1, y%+2, mid$(text$,curpos%,1)
    wend
    drawTextBox x%, y%, x2%, y2%, text$, offset%, 0, 0
loop until SA_MouseOver <> hndl%
timer off
cursorState = 3
end sub

'Helper routine for drawing selections
sub drawSelect(byval x%, byval y%, byval x2%, byval y2%, selA%, selB%, oldSelA%, oldSelB%, byval text$, byval offset%)
if cursorState = 2 then
    gosub chgCursor
end if
xa% = x% + 3
selectA% = min(selA%, selB%)
selectB% = max(selA%, selB%)
if selectA% > oldSelA% then
    oldx% = letScrPos%(x%, offset%, oldSelA%, text$)
    newx% = letScrPos%(x%, offset%, selectA%, text$)
    mouseOff
    view screen (xa%, y% + 2)-(x2% - 2, y2% - 2)
    line(oldx%-1, y% + 2)-(newx%-1, y2% - 2), bcolor, bf
    fontput oldx%, y% + 2, mid$(text$, oldSelA%, selectA% - oldSelA%)
    view screen
    mouseOn
elseif selectA% < oldSelA% then
    oldx% = letScrPos%(x%, offset%, oldSelA%, text$)
    newx% = letScrPos%(x%, offset%, selectA%, text$)
    tcolor? = fcolor
    fcolor = hfcolor
    mouseOff
    view screen (xa%, y% + 2)-(x2% - 2, y2% - 2)
    line(oldx%-1, y% + 2)-(newx%-1, y2% - 2), hbcolor, bf
    fontput newx%, y% + 2, mid$(text$, selectA%, oldSelA% - selectA%)
    view screen
    mouseOn
    fcolor = tcolor?
end if
if selectB% > oldSelB% then
    oldx% = letScrPos%(x%, offset%, oldSelB%, text$)
    newx% = letScrPos%(x%, offset%, selectB%, text$)
    tcolor? = fcolor
    fcolor = hfcolor
    mouseOff
    view screen (xa%, y% + 2)-(x2% - 2, y2% - 2)
    line(oldx%-1, y% + 2)-(newx%-1, y2% - 2), hbcolor, bf
    fontput oldx%, y% + 2, mid$(text$, oldSelB%, selectB% - oldSelB%)
    view screen
    mouseOn
    fcolor = tcolor?
elseif selectB% < oldSelB% then
    oldx% = letScrPos%(x%, offset%, oldSelB%, text$)
    newx% = letScrPos%(x%, offset%, selectB%, text$)
    mouseOff
    view screen (xa%, y% + 2)-(x2% - 2, y2% - 2)
    line(oldx%-1, y% + 2)-(newx%-1, y2% - 2), bcolor, bf
    fontput newx%, y% + 2, mid$(text$, selectB%, oldSelB% - selectB%)
    view screen
    mouseOn
end if
oldSelB% = selectB%
oldSelA% = selectA%
curx% = 641                 'Don't redraw cursor for now
end sub

'*Initializes and draws the textbox (without focus)
'*x%: the x-position of the upper-left corner
'*y%: the y-position of the upper-left corner
'*x2%: the x-position of the lower-right corner
'*y2%: the y-position of the lower-right corner
'*text$:  the value of the text in the textbox at initialization
function iniTextBox(byval x%, byval y%, byval x2%, byval y2%, byval text$) public
y2% = max(y2%, y% + fontH+ 4)
drawTextBox x%, y%, x2%, y2%, text$, 1, 1, 1
iniTextBox = SA_addTop(x%,y%,x2%,y2%)
end function

'*Draws the textbox (without focus)
'*x%: the x-position of the upper-left corner
'*y%: the y-position of the upper-left corner
'*x2%: the x-position of the lower-right corner
'*y2%: the y-position of the lower-right corner
'*text$:  the value of the text in the textbox at initialization
'*offset%: offset from beginning character (usually 0), must be greater than or equal to 0 and less than length of text
'*selectA%: beginning of selection (usually 0), must be greater than or equal to 0 and less than length of text
'*selectB%: end of selection (usually 0), must be greater than or equal to 0 and less than length of text
sub drawTextBox(byval x%, byval y%, byval x2%, byval y2%, byval text$, byval offset%, byval selectA%, byval selectB%) public
textShow$ = mid$(text$, offset%)
selAUse% = selectA% - offset%
selBUse% = selectB% - offset%
textA$ = ""
if selAUse% > 0 then
    textA$ = left$(textShow$, selAUse%)
    textB$ = mid$(textShow$, selAUse%+1, selBUse% - selAUse%)
    textC$ = mid$(textShow$, selBUse% + 1)
elseif selBUse% > 0 then
    textB$ = left$(textShow$, selBUse%)
    textC$ = mid$(textShow$, selBUse% + 1)
else
    textC$ = textShow$
end if
xa% = x% + 3
xSela% = xa% + fontlength(textA$)
xSelb% = xSela% + fontlength(textB$)
smartMouseOff x%, y%, x2%, y2%
box x%, y%, x2% - x%, y2% - y%, LOWERED
view screen (xa%, y% + 2)-(x2% - 2, y2% - 2)
fontput xa%, y% + 2, textA$
if textB$ <> "" then line(xSela%, y% + 2)-(xSelb%-1, y% + 4 + fontH), hbcolor, bf
tcolor? = fcolor
fcolor = hfcolor
fontput xSela%, y% + 2, textB$
fcolor = tcolor?
fontput xSelb%, y% + 2, textC$
view screen
mouseOn
curx% = 641                 'Don't redraw cursor for now
end sub

'Helper function for drawing
function letScrPos%(byval x%, byval offset%, byval letpos%, byval text$)
aText$ = mid$(text$, offset%, letpos% - offset%)
letScrPos% = x% + 3 + fontlength(aText$)
end function

'Helper function for clicking
function nearLetPos%(byval x%, byval lessThan%, byval offset%, byval text$)
def seg = strseg(text$)
startP& = strptr(text$)
oldxps% = x%
x% = x% + fontlength(peek$(startP&+offset%-1,1))
while (x%+oldxps%)/2 < lessThan% and offset% =< len(text$)
    oldxps% = x%
    x% = x% + fontlength(peek$(startP&+offset%,1))
    incr offset%
wend
nearLetPos = offset%
end function

'end upperlevel gui library
'<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><

'Some array stuff

'*Expands an integer array by EXPAMT by redimentioning it while retaining the values in the array.
'*arr%(): the integer array to expand.
sub I_expArr(arr%())
ub% = ubound(arr%)
dim temp(ub%) as integer
for i% = 0 to ub%
   temp(i%) = arr%(i%)
next
if EXPAMT = 0 then EXPAMT = 10
redim arr%(ub%+EXPAMT)
for i% = 0 to ub%
   arr%(i%) = temp(i%)
next
end sub

'*Inserts an integer at the specified location in arr%().  The array is expanded if necessary.
'*arr%(): the array to expand
'*p%: position in the array to insert it
'*ub%: the highest index of valid data in the array
'*v%: integer value to insert
sub I_insArr(arr%(), ByVal p%, ub%, ByVal v%)
if ub% >= ubound(arr%) then
   I_expArr arr%()
end if
array insert arr%(p%), v%
incr ub%
end sub

'*Deletes a value from the array and contracts the array by EXPAMT if necessary
'*arr%(): the array
'*p%: index of the value to delete
'*ub%: the highest index of valid data in the array
sub I_delArr(arr%(), ByVal p%, ub%)
array delete arr%(p%)
decr ub%
if ub% < 0 then ub% = 0
if ub% + EXPAMT <= ubound(arr%) then
   I_contArr arr%()
end if
end sub

'*Contracts an array by EXPAMT
'*arr%(): the array to contract
sub I_contArr(arr%())
ub% = ubound(arr%)
if EXPAMT = 0 then EXPAMT = 10
newUb% = ub%-EXPAMT
dim temp(newUb%) as integer
for i% = 0 to newUb%
   temp(i%) = arr%(i%)
next
redim arr%(newUb%)
for i% = 0 to newUb%
   arr%(i%) = temp(i%)
next
end sub

'<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
function TRUE
TRUE = -1
end function

function FALSE
FALSE = 0
end function
