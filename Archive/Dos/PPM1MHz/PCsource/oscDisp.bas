'============================================================================
'*Author:  Jonathan Weaver
'*Date:    5/3/2005
'*Version: 1.0 Build # 5 9/14/2004
'*         1.0 build # 6 5/3/2005
'*Filename:  oscDisp.bas
'*Description:  An oscilloscope screen and spectrum screen.  Scales waveforms and displays them on the screen.
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
'TODO:
'(1)  Add cursors to spectrum
'(2)  Make channels enabled or disabled...DONE 5/3/2005
'============================================================================

'==============================================================================
' C O M P I L E R   D I R E C T I V E S
'==============================================================================

$compile unit "oscDisp.pbu"
$code seg "oscillo"

'==============================================================================
' E X T E R N A L   D E C L A R A T I O N S
'==============================================================================

external xpos%, ypos%       'Mouse x and y-position, used for cursor
external but%               'Mouse button state, used for cursor
declare sub checkinput()
declare sub waitinput()     'Wait for the mouse state to change, used for dragging cursor
declare sub mouseOff()      'Turn the mouse cursor off
declare sub mouseOn()       'Turn the mouse cursor on

external bgcolor?           'Background color
external lcolor?            'Grid color
external chAcolor?          'Channel A color
external chBcolor?          'Channel B color
external curColor?          'cursor color

external mode?              'Mode setting
external reconst?           'Function reconstruction
external timeSample         'Time per sample

'Data for each channel
external channelA(), channelB()

external chAVoltDiv, chBVoltDiv     'Volts per division
external chAOffset, chBOffset       'Offset from zero

declare function getSamplesPerChannel??()

'==============================================================================
' S H A R E D   D E C L A R A T I O N S
'==============================================================================

%DIVISIONSX = 10
%DIVISIONSY = 8

'Position of the scope on the screen
shared Scope_xUL%, Scope_yUL%, Scope_xLR%, Scope_yLR%

'Position of the spectrum on the screen
shared Spect_xUL%, Spect_yUL%, Spect_xLR%, Spect_yLR%

'Position of the cursor
dim cursorX(1) as integer, cursorY(1) as integer
dim oldcursorX(1) as integer, oldcursorY(1) as integer
shared cursorX(), cursorY(), oldcursorX(), oldcursorY()

'For record mode, the image the cursor must redraw
dim graphHA(0) as integer, graphLA(0) as integer
dim graphHB(0) as integer, graphLB(0) as integer
shared graphHA(), graphLA(), graphHB(), graphLB()

'==============================================================================
' V E R S I O N   F U N C T I O N
'==============================================================================

'*Returns the version and build number of this unit
'*RETURN:  a string containing the version and build of this unit
function verOscDisp$() public
verOscDisp$ = "Oscilloscope screen area Version 1.0 build #6, 5/3/2005.  " _
    + "oscDisp.pbu"
end function

'==============================================================================
' P U B L I C   S U B R O U T I N E S / F U N C T I O N S
'==============================================================================

'*Returns the time per Division
function getTimePerDivision!() public
getTimePerDivision! = (getSamplesPerChannel??-1)*timeSample/%DIVISIONSX
end function

'*Sets the position of the scope as displayed on the screen
'*x1%:  x-coordinate of the upper left corner
'*y1%:  y-coordinate of the upper left corner
'*x2%:  x-coordinate of the lower right corner
'*y2%:  y-coordinate of the lower right corner
sub setScopePosition(byval x1%, byval y1%, byval x2%, byval y2%) public
Scope_xUL% = x1%
Scope_yUL% = y1%
Scope_xLR% = x2%
Scope_yLR% = y2%
end sub

'*Returns the position of the scope as displayed on the screen
'*x1%:  returns the x-coordinate of the upper left corner
'*y1%:  returns the y-coordinate of the upper left corner
'*x2%:  returns the x-coordinate of the lower right corner
'*y2%:  returns the y-coordinate of the lower right corner
sub getScopePosition(x1%, y1%, x2%, y2%) public
x1% = Scope_xUL%
y1% = Scope_yUL%
x2% = Scope_xLR%
y2% = Scope_yLR%
end sub

'*Sets the position of the spectrum as displayed on the screen
'*x1%:  x-coordinate of the upper left corner
'*y1%:  y-coordinate of the upper left corner
'*x2%:  x-coordinate of the lower right corner
'*y2%:  y-coordinate of the lower right corner
sub setSpectPosition(byval x1%, byval y1%, byval x2%, byval y2%) public
Spect_xUL% = x1%
Spect_yUL% = y1%
Spect_xLR% = x2%
Spect_yLR% = y2%
end sub

'*Returns the position of the spectrum as displayed on the screen
'*x1%:  returns the x-coordinate of the upper left corner
'*y1%:  returns the y-coordinate of the upper left corner
'*x2%:  returns the x-coordinate of the lower right corner
'*y2%:  returns the y-coordinate of the lower right corner
sub getSpectPosition(x1%, y1%, x2%, y2%) public
x1% = Spect_xUL%
y1% = Spect_yUL%
x2% = Spect_xLR%
y2% = Spect_yLR%
end sub

'*Draws the scope screen in the designated area according to mode, reconstruction, etc.
sub drawScope() public
timer off
view screen (Scope_xUL%, Scope_yUL%)-(Scope_xLR%, Scope_yLR%)
x1% = Scope_xUL% + 1
y1% = Scope_yUL% + 1
x2% = Scope_xLR% - 1
y2% = Scope_yLR% - 1
'Erase the old cursor when necessary
for i% = 0 to 1
    if bit(mode?,1) = 1 then
        if oldcursorX(i%) > 0 and oldcursorY(i%) > 0 then
            if i% = 0 then
                put (x1%, oldcursorY(i%)), graphHA, pset
                put (oldcursorX(i%), y1%), graphLA, pset
            else
                put (x1%, oldcursorY(i%)), graphHB, pset
                put (oldcursorX(i%), y1%), graphLB, pset
            end if
        end if
        if oldcursorX(i%) <> cursorX(i%) then
            graphsizeL% = 4 + CEIL(1 / 8) * 4 * (y2%-y1%)
            if cursorX(i%) > 0 then
                if i% = 0 then
                    redim graphLA(graphsizeL%) as integer
                    get (cursorX(i%), y1%)-(cursorX(i%),y2%), graphLA
                else
                    redim graphLB(graphsizeL%) as integer
                    get (cursorX(i%), y1%)-(cursorX(i%),y2%), graphLB
                end if
            end if
        end if
        if oldcursorY(i%) <> cursorY(i%) then
            graphsizeH% = 4 + CEIL((x2%-x1%) / 8) * 4 * 1
            if cursorY(i%) > 0 then
                if i% = 0 then
                    redim graphHA(graphsizeH%) as integer
                    get (x1%, cursorY(i%))-(x2%, cursorY(i%)), graphHA
                else
                    redim graphHB(graphsizeH%) as integer
                    get (x1%, cursorY(i%))-(x2%, cursorY(i%)), graphHB
                end if
            end if
        end if
    else
        if oldcursorX(i%) <> cursorX(i%) or oldcursorY(i%) <> cursorY(i%) then
        line(x1%, oldcursorY(i%))-(x2%, oldcursorY(i%)), bgcolor?
        line(oldcursorX(i%), y1%)-(oldcursorX(i%), y2%), bgcolor?
        end if
    end if
    oldcursorX(i%) = cursorX(i%)
    oldcursorY(i%) = cursorY(i%)
next
'Draw the background, if mode is RUN
if bit(mode?,0) = 1 then
    'Redraw background border
    box Scope_xUL%, Scope_yUL%, Scope_xLR%-Scope_xUL%, Scope_yLR%-Scope_yUL%
    'Redraw background
    XdivScale! = (Scope_xLR% - Scope_xUL%) / %DIVISIONSX
    YdivScale! = (Scope_yLR% - Scope_yUL%) / %DIVISIONSY
    xa! = Scope_xUL%
    for i% = 1 to %DIVISIONSX
        xb% = xa!
        xa! = xa!+XdivScale!
        xa% = xa!
        select case i%
        case 1: xb% = xb% + 4
        case 5: xa% = xa% - 2
        case 6: xb% = xb% + 2
        case 10: xa% = xa% - 4
        end select
        ya! = Scope_yUL%
        for j% = 1 to %DIVISIONSY
            yb% = ya!
            ya! = ya!+YdivScale!
            ya% = ya!
            select case j%
            case 1: yb% = yb% + 4
            case 4: ya% = ya% - 2
            case 5: yb% = yb% + 2
            case 8: ya% = ya% - 4
            end select
            'Draw background
            line(xa%-1,ya%-1)-(xb%+1,yb%+1), bgcolor?, bf
            'Draw horizontal lines
            if i% = 1 and j% < %DIVISIONSY then line(x1%, ya!)-(x2%, ya!), lcolor?
        next
        'Draw vertical lines
        if i% < %DIVISIONSX then line(xa!, y1%)-(xa!, y2%), lcolor?
    next
    'Draw high precision tick marks on zero axes and along edges
    if XdivScale! > 20 then
        yavg% = (Scope_yLR%+Scope_yUL%)/2
        x! = Scope_xUL%
        for i% = 1 to 10*%DIVISIONSX-1
            oldx% = x!+1
            x! = x!+XdivScale!/10
            x% = x!
            line(x%,y1%)-(oldx%,Scope_yUL%+4), bgcolor?, bf
            line(x%,yavg%-2)-(oldx%,yavg%-1),bgcolor?, bf
            line(x%,yavg%+1)-(oldx%,yavg%+2),bgcolor?, bf
            line(x%,y2%)-(oldx%,Scope_yLR%-4),bgcolor?, bf
            if i% mod 5 = 0 then
                line(x%, y1%)-(x%, Scope_yUL%+4), lcolor?
                line(x%, yavg%-2)-(x%, yavg%+2), lcolor?
                line(x%, y2%)-(x%, Scope_yLR%-4), lcolor?
            else
                line(x%, y1%)-(x%, Scope_yUL%+2), lcolor?
                line(x%, yavg%-1)-(x%, yavg%+1), lcolor?
                line(x%, y2%)-(x%, Scope_yLR%-2), lcolor?
            end if
        next
        oldx% = x! + 1
        line(x2%,y1%)-(oldx%,Scope_yUL%+4), bgcolor?,bf
        line(x2%,yavg%-2)-(oldx%,yavg%-1),bgcolor?,bf
        line(x2%,yavg%+1)-(oldx%,yavg%+2),bgcolor?,bf
        line(x2%,y2%)-(oldx%,Scope_yLR%-4),bgcolor?,bf
    end if
    'Draw high precision tick marks on zero axes and along edges
    if YdivScale! > 20 then
        xavg% = (Scope_xLR%+Scope_xUL%)/2
        y! = Scope_yUL%
        for i% = 1 to 10*%DIVISIONSY-1
            oldy% = y!+1
            y! = y!+YdivScale!/10
            y% = y!
            line(x1%,y%)-(Scope_xUL%+4,oldy%), bgcolor?,bf
            line(xavg%-2,y%)-(xavg%-1,oldy%),bgcolor?,bf
            line(xavg%+2,y%)-(xavg%+1,oldy%),bgcolor?,bf
            line(x2%,y%)-(Scope_xLR%-4,oldy%),bgcolor?,bf
            if i% mod 5 = 0 then
                line(x1%, y%)-(Scope_xUL%+4, y%), lcolor?
                line(xavg%-2, y%)-(xavg%+2, y%), lcolor?
                line(x2%, y%)-(Scope_xLR%-4,y%), lcolor?
            else
                line(x1%, y%)-(Scope_xUL%+2, y%), lcolor?
                line(xavg%-1, y%)-(xavg%+1, y%), lcolor?
                line(x2%, y%)-(Scope_xLR%-2, y%), lcolor?
            end if
        next
        oldy% = y! + 1
        line(x1%,y2%)-(Scope_xUL%+4,oldy%), bgcolor?,bf
        line(xavg%-2,y2%)-(xavg%-1,oldy%),bgcolor?,bf
        line(xavg%+2,y2%)-(xavg%+1,oldy%),bgcolor?,bf
        line(x2%,y2%)-(Scope_xLR%-4,oldy%),bgcolor?,bf
    end if
end if
if bit(mode?,0) = 1 or bit(mode?,1) = 1 then
'Draw the cursor
    for i% = 0 to 1
        line(x1%, cursorY(i%))-(x2%, cursorY(i%)), curColor?
        line(cursorX(i%), y1%)-(cursorX(i%), y2%), curColor?
    next
    if bit(mode?,2) = 1 then
        'XY Mode
        view (x1%, y1%)-(x2%, y2%)
        drawXYChannel x1%, y1%, x2%, y2%, channelA(), channelB(), chAcolor?
    else
        'Voltage vs time
        'Set up screen
        view (x1%, y1%)-(x2%, y2%)
        if bit(mode?, 5) = 1 then
            drawChannel x1%, y1%, x2%, y2%, channelA(), chAOffset, chAVoltDiv, chAcolor?
        end if
        if bit(mode?, 6) = 1 then
            drawChannel x1%, y1%, x2%, y2%, channelB(), chBOffset, chBVoltDiv, chBcolor?
        end if
    end if
end if
view screen
timer on
end sub

'*Draws the spectrum screen in the designated area according to modes.
sub drawSpectrum () public
dim dynamic magnA(0), phaseA(0), magnB(0), phaseB(0)
DFourier channelA(), magnA(), phaseA()
DFourier channelB(), magnB(), phaseB()
x_UL% = Spect_xUL% + 1
y_UL% = Spect_yUL% + 1
x_LR% = (Spect_xUL% + Spect_xLR%)/2 - 3
x_ULB% = x_LR% + 6
x_LRB% = Spect_xLR% - 1
y_LR% = Spect_yLR% - 1
view screen (Spect_xUL%, Spect_yUL%)-(Spect_xLR%, Spect_yLR%)
'Draw the background, if mode is RUN
if bit(mode?,4) = 1 then
    'if frequency magnitude is logrithmic
    maxmagn! = 10^int(log10(max(chAVoltDiv, chBVoltDiv))+1)
    minmagn! = 10^int(log10(min(chAVoltDiv, chBVoltDiv))-1)
    yDec% = (y_LR% - y_UL%)/(log10(maxmagn!) - log10(minmagn!))
else
    maxmagn! = 10*max(chAVoltDiv, chBVoltDiv)
    minmagn! = 0
    yDec% = (y_LR% - y_UL%)/maxmagn!*5
end if
'if mode = run
if bit(mode?,0) = 1 then
    'Redraw background border
    box Spect_xUL%, Spect_yUL%, (Spect_xLR%-Spect_xUL%)/2-2, Spect_yLR%-Spect_yUL%
    box 0.5*(Spect_xUL%+Spect_xLR%)+2, Spect_yUL%, (Spect_xLR%-Spect_xUL%)/2-2, Spect_yLR%-Spect_yUL%
    'draw background
    line(x_UL%,y_UL%)-(x_LR%,y_LR%),bcolor?,bf
    line(x_ULB%,y_UL%)-(x_LRB%,y_LR%),bcolor?,bf
    'redraw the horizontal lines on magnitude plot
    if bit(mode?,4) = 1 then
        'logrithmic magnitude
        for i% = log10(minmagn!) to log10(maxmagn!) - 1
            y% = y_LR% - yDec%*(log10(10^i%)-log10(minmagn!))
            line(x_UL%,y%)-(x_LR%,y%),lcolor?
            for j% = 2 to 9
                y% = y_LR% - yDec%*(log10(j%*10^i%)-log10(minmagn!))
                line(x_UL%,y%)-(x_LR%,y%),lcolor?,,&B1010101010101010
            next
        next
    else
        'regular magnitude
        yStep! = (y_LR%-y_UL%) / 5
        y! = y_UL% + yStep!
        for i% = 0 to 4
            line(x_UL%, y!)-(x_LR%, y!), lcolor?
            y! = y! + yStep!
        next
    end if
    'redraw horizontal lines on phase plot
    yStep! = (y_LR% - y_UL%) / 4
    hline! = y_UL% + yStep!
    for i% = 0 to 2
        line(x_ULB%,hline!)-(x_LRB%,hline!), lcolor?
        hline! = hline! + yStep!
    next
    'redraw vertical lines on magnitude plot and phase plot
    xStep! = (x_LR%-x_UL%) / 8
    vline! = xStep!
    for i% = 0 to 6
        xa% = vline!+x_UL%
        xb% = vline!+x_ULB%
        line(xa%, y_UL%)-(xa%, y_LR%), lcolor?
        line(xb%, y_UL%)-(xb%, y_LR%), lcolor?
        vline! = vline! + xStep!
    next
end if
if bit(mode?,0) = 1 or bit(mode?,1) = 1 then
    'draw the channels
    view screen (x_UL%, y_UL%)-(x_LR%, y_LR%)
    if bit(mode?, 5) = 1 then
        drawSpectMagn x_UL%, y_UL%, x_LR%, y_LR%, yDec%, minmagn!, magnA(), chAColor?
    end if
    if bit(mode?, 6) = 1 then
        drawSpectMagn x_UL%, y_UL%, x_LR%, y_LR%, yDec%, minmagn!, magnB(), chBColor?
    end if
    view (x_ULB%, y_UL%)-(x_LRB%, y_LR%)
    if bit(mode?, 5) = 1 then
        drawSpectPhase x_ULB%, y_UL%, x_LRB%, y_LR%, phaseA(), chAColor?
    end if
    if bit(mode?, 6) = 1 then
        drawSpectPhase x_ULB%, y_UL%, x_LRB%, y_LR%, phaseB(), chBColor?
    end if
end if
view screen
end sub

'*Creates a cursor
'*xAscr%:  the x-position of the screen to create the cursor over
'*yBscr%:  the y-position of the screen to create the cursor over
sub setCursor(byval xscr%, byval yscr%) public
if (cursorX(0) =< 0) or (overCursor(xscr%, yscr%) = 0) then i% = 0 else i% = 1
cursorX(i%) = xscr%
cursorY(i%) = yscr%
end sub

'*Gets the value of the cursor on the scope base on the handle
'*hndl%:  the handle of the cursor (0 or 1)
'*t!:  the time value on the scope at the cursor location.  In XY-Mode this is zero.
'*chAv!:  the channel A Voltage on the scope at the cursor location
'*chBv!:  the channel B Voltage on the scope at the cursor location
sub getCursor(byval hndl%, t!, chAv!, chBv!) public
t! = 0
chAV! = 0
chBV! = 0
if cursorX(hndl%) > 0 and cursorY(hndl%) > 0 then
    scopeValue cursorX(hndl%), cursorY(hndl%), t!, chAV!, chBV!
end if
end sub

'*Returns the handle of the cursor if the screen position is over it.  Returns -1 if not over a cursor, 0 if over the first cursor, 1 if over the second cursor.
'*xscr%:  the x-position of the screen to check
'*yscr%:  the y-position of the screen to check
function overCursor(byval xscr%, byval yscr%) public
toRet% = -1
for i% = 0 to 1
    if (cursorX(i%) + 4 > xscr%) and (cursorX(i%) - 4 < xscr%) and _
        (cursorY(i%) + 4 > yscr%) and (cursorY(i%) - 4 < yscr%) then _
        toRet% = i%
next
overCursor = toRet%
end function

'*Handles mouse clicks within the scope area
sub clkScope() public
hndl% = overCursor(xpos%, ypos%)
if hndl% >= 0 then
    while but% > 0
        while x% = xpos% and y% = ypos% and but% > 0
            checkinput
        wend
        x% = xpos% : y% = ypos%
        if xpos% > Scope_xUL% and xpos% < Scope_xLR% and _
            ypos% > Scope_yUL% and ypos% < Scope_yLR% then
            'Move the cursor if dragging
            cursorX(hndl%) = xpos%
            cursorY(hndl%) = ypos%
        else
            'Delete cursor if dragged off the scope screen
            cursorX(hndl%) = -1
            cursorY(hndl%) = -1
        end if
        mouseOff
        drawScope
        mouseOn
    wend
else
    'Create a cursor
    setCursor xpos%, ypos%
    mouseOff
    drawScope
    mouseOn
end if
end sub

'*Returns the values of the scope corresponding to given screen coordinates
'*scrx%:  x-coordinate of the screen
'*scry%:  y-coordinate of the screen
'*t!:  the returned time value of the screen coordinate.  If in XY_mode, returns zero
'*chAV!:  the returned value of channel A for the screen coordinate.
'*chBV!:  the returned value of channel B for the screen coordinate.
sub scopeValue (byval scrx%, byval scry%, t!, chAV!, chBV!) public
x1% = Scope_xUL% + 1                                    'Allow for border
y1% = Scope_yUL% + 1
x2% = Scope_xLR% - 1
y2% = Scope_yLR% - 1
x% = scrx%-x1%                                          'Calculate offset from corner
y% = scry%-y1%
if bit(mode?,2) = 1 then
    'XYMode
    deltax! = (x2%-x1%)/%DIVISIONSX                          'Calculate Scale
    deltay! = (y2%-y1%)/%DIVISIONSY
    chAV! = (%DIVISIONSY/2-y%/deltay!)*chAVoltDiv-chAOffset
    chBV! = (-%DIVISIONSX/2+x%/deltax!)*chBVoltDiv-chBOffset
    t! = 0
else
    'Voltage vs time
    deltax! = (x2%-x1%)/getSamplesPerChannel??()      'Calculate scale
    deltay! = (y2%-y1%)/%DIVISIONSY
    a! = (%DIVISIONSY/2-y%/deltay!)
    chAV! = a*chAVoltDiv-chAOffset              'Convert y-offset to Voltage
    chBV! = a*chBVoltDiv-chBOffset
    t! = x%*timeSample!/deltax!                      'Convert x-offset to Time
end if
end sub

'*Returns the values of the spectrum corresponding to given screen coordinates
'*scrx%:  x-coordinate of the screen
'*scry%:  y-coordinate of the screen
'*freq!:  the frequency value of the screen coordinate
'*chMagn!:  the magnitude value of the screen coordinate, if the coordinate is over the Magnitude plot, otherwise, zero
'*chPhase!:  the phase value of the screen coordinate, if the coordinate is over the Phase plot, otherwise, zero
sub spectumValue (byval scrx%, byval scry%, freq!, chMagn!, chPhase!) public
x_UL% = Spect_xUL% + 1
y_UL% = Spect_yUL% + 1
x_LR% = (Spect_xUL% + Spect_xLR%)/2 - 3
x_ULB% = x_LR% + 6
x_LRB% = Spect_xLR% - 1
y_LR% = Spect_yLR% - 1
if scrx% < x_LR% and scrx% > x_UL% then
    'on magnitude plot
    if bit(mode?,4) = 1 then
        'if magnitude is logrithmic
        maxmagn! = 10^int(log10(max(chAVoltDiv, chBVoltDiv))+1)
        minmagn! = 10^int(log10(min(chAVoltDiv, chBVoltDiv))-1)
        yDec% = (y_LR% - y_UL%)/(log10(maxmagn!) - log10(minmagn!))
        chMagn! = minmagn!*10^((y_LR% - scry%)/yDec%)
    else
        maxmagn! = 10*max(chAVoltDiv, chBVoltDiv)
        minmagn! = 0
        yDec% = (y_LR% - y_UL%)/maxmagn!*5
        chMagn! = (y_LR% - scry%)/yDec%
    end if
    deltax! = (x_LR% - x_UL%)*2
    freq! = (scrx% - x_UL%)/deltax!/timeSample!
    chPhase! = 0
elseif scrx% > x_ULB% and scrx% < x_LRB% then
    'on phase plot
    deltax! = (x_LR% - x_UL%)*2
    chPhase! = 3.1415926*(1 - (scry% - y_UL%)/(y_LR% - y_UL%)*2)
    freq! = (scrx% - x_ULB%)/deltax!/timeSample!
    chMagn! = 0
end if
end sub

'*Constant function to designate the Run mode.  In run mode, the drawScope and drawSpectrum subroutines always refresh, erasing previous data.
'*Returns: 1
function Mode_RUN() public
Mode_RUN = 1
end function

'*Constant function to designate the Stop mode.  In stop mode, the drawScope and drawSpectrum subroutines never refresh
'*Returns: 0
function Mode_STOP() public
Mode_STOP = 0
end function

'*Constant function to designate the Hold mode.  In hold mode, the drawScope and drawSpectrum subroutines always refresh, but do not erase previous data
'*Returns: 2
function Mode_HOLD() public
Mode_HOLD = 2
end function

'*Constant function to designate the XY mode.  In XY mode, the Scope screen places ChannelA on the horizontal axis and ChannelB on the vertical axis
'*Returns: 4
function Mode_XY() public
Mode_XY = 4
end function

'*Returns: 16
function Mode_FREQMAGLOG() public
Mode_FREQMAGLOG = 16
end function

'*Returns: 32
function Mode_CHAENABLED() public
Mode_CHAENABLED = 32
end function

'*Returns: 64
function Mode_CHBENABLED() public
Mode_CHBENABLED = 64
end function


'*Constant function to designate signal reconstruction using triangular pulses.
'*Returns: 0
function reconst_TRIANGLE() public
reconst_TRIANGLE = 0
end function

'*Constant function to designate signal reconstruction using sinc functions.
'*Returns: 1
function reconst_SINC() public
reconst_SINC = 1
end function

'*Constant function to designate signal reconstruction using square pulses.
'*Returns: 2
function reconst_SQUARE() public
reconst_SQUARE = 2
end function

'*Constant function to designate NO signal reconstuction.  Data points are displayed.
'*Returns: 3
function reconst_POINT() public
reconst_POINT = 3
end function

'*Do the discrete Fourier transform on channel()
'*channel():  an array with time domain information for a channel
'*amplitude():  a dynamic array that returns amplitude information base on harmonic number in order of increasing frequency.  Omega-hat = 2*pi*(array index)/(total samples).  Frequency = (array index)/(total samples)/(time per sample).
'*phase():  a dynamic array that returns phase information based on harmonic number
sub DFourier(channel(), magn(), phase()) public
pi = 3.141592654
a% = ubound(channel) + 1
u_freq% = a%/2
redim magn(u_freq%)
redim phase(u_freq%)
for n% = 0 to u_freq%
    chsumReal = 0
    chsumImg = 0
    for k% = 0 to a%-1
        i! = cos(2*pi*k%*n%/a%)
        j! = sin(2*pi*k%*n%/a%)
        chsumReal = chsumReal + channel(k%)*i!
        chsumImg = chsumImg + channel(k%)*j!
    next
    magn(n%) = sqr(chsumReal^2+chsumImg^2)/a%
    if chsumReal = 0 then
        if chsumImg > 0 then
            phase(n%) = pi/2
        else
            phase(n%) = -pi/2
        end if
    else
        phase(n%) = atn(chsumImg/chsumReal)
    end if
    if chsumReal < 0 then
        if phase(n%) > 0 then phase(n%) = phase(n%) - pi else phase(n%) = phase(n%) + pi
    end if
    if n% > 0 and n% < u_freq% then magn(n%) = magn(n%)*2
next
end sub

'==============================================================================
' P R I V A T E   S U B R O U T I N E S / F U N C T I O N S
'==============================================================================

'Helper subroutine to the draw scope subroutine.  Draws a channel on the screen
'for voltage vs. time mode
sub drawChannel(byval x1%, byval y1%, byval x2%, byval y2%, channel(), byval chOffset, byval chVoltDiv, byval theCol?)
    deltax! = (x2%-x1%)/ubound(channel())
    deltay! = (y2%-y1%)/8
    select case reconst?
    case reconst_TRIANGLE
        oldy% = deltay!*4-deltay!*(channel(0)+chOffset)/chVoltDiv
        oldx% = 0
        for i% = 1 to ubound(channel())
            y% = deltay!*4-deltay!*(channel(i%)+chOffset)/chVoltDiv
            x% = i%*deltax!
            line(x%,y%)-(oldx%,oldy%),theCol?
            oldy% = y%
            oldx% = x%
        next
    case reconst_SINC
        dim magn(0), phase(0)
        DFourier channel(), magn(), phase()
        oldx% = 0
        a! = 0
        for i% = 0 to ubound(magn)
            a! = magn(i%)*cos(-phase(i%)) + a!
        next
        oldy% = deltay!*4-deltay!*(a!+chOffset)/chVoltDiv
        for x% = 1 to x2%-x1%
            a! = 0
            for i% = 0 to ubound(magn)
                a! = magn(i%)*cos(2*3.1415926*i%*x%/deltax!/(ubound(channel())+1)-phase(i%)) + a!
            next
            y% = deltay!*4-deltay!*(a!+chOffset)/chVoltDiv
            line(x%, y%)-(oldx%, oldy%), theCol?
            oldx% = x%
            oldy% = y%
        next
'        a! = 3.1415926/deltax!
'        sinc! = 0
'        arg! = 0
'        for i% = 0 to ubound(channel())
'            if arg! = 0 then
'                sinc! = sinc! + channel(i%)
'            else
'                sinc! = sinc! + channel(i%)*sin(arg!)/arg!
'            end if
'            arg! = arg! + 3.1415926
'        next
'        oldx% = 0
'        oldy% = deltay!*4-deltay!*(sinc! + chOffset)/chVoltDiv
'        for x% = 1 to x2%-x1%
'            sinc! = 0
'            arg! = -3.1415926/deltax!*x%
'            for i% = 0 to ubound(channel())
'                if arg! = 0 then
'                    sinc! = sinc! + channel(i%)
'                else
'                    sinc! = sinc! + channel(i%)*sin(arg!)/arg!
'                end if
'                arg! = arg! + 3.1415926
'            next
'            y% = deltay!*4-deltay!*(sinc! + chOffset)/chVoltDiv
'            line(x%, y%)-(oldx%, oldy%),theCol?
'            oldy% = y%
'            oldx% = x%
'        next
    case reconst_SQUARE
        oldy% = deltay!*4-deltay!*(channel(0)+chOffset)/chVoltDiv
        oldx% = 0
        for i% = 1 to ubound(channel())
            y% = deltay!*4-deltay!*(channel(i%)+chOffset)/chVoltDiv
            x% = i%*deltax!-deltax!/2
            line(x%,oldy%)-(oldx%,oldy%),theCol?
            line(x%,oldy%)-(x%,y%), theCol?
            oldy% = y%
            oldx% = x%
        next
        line(oldx%+deltax!,oldy%)-(oldx%,oldy%),theCol?
    case reconst_POINT
        for i% = 1 to ubound(channel())
            y% = deltay!*4-deltay!*(channel(i%)+chOffset)/chVoltDiv
            x% = i%*deltax!
            pset(x%,y%),theCol?
            oldy% = y%
            oldx% = x%
        next
    end select
end sub

'Helper subroutine to the draw scope subroutine.  Draws the channels on the screen
'for XY mode
sub drawXYChannel(byval x1%, byval y1%, byval x2%, byval y2%, chA(), chB(), chColor?)
    deltax! = (x2%-x1%)/%DIVISIONSX
    deltay! = (y2%-y1%)/%DIVISIONSY
    oldy% = deltay!*%DIVISIONSY/2-deltay!*(chA(0)+chAOffset)/chAVoltDiv
    oldx% = deltax!*%DIVISIONSX/2+deltax!*(chB(0)+chBOffset)/chBVoltDiv
    for i% = 1 to ubound(chA())
        y% = deltay!*%DIVISIONSY/2-deltay!*(chA(i%)+chAOffset)/chAVoltDiv
        x% = deltax!*%DIVISIONSX/2+deltax!*(chB(i%)+chBOffset)/chBVoltDiv
        line(x%,y%)-(oldx%,oldy%),chColor?
        oldx% = x%
        oldy% = y%
    next
end sub

sub drawSpectMagn(byval x1%, byval y1%, byval x2%, byval y2%, byval yDec%, byval minmagn!, channel(), theCol?)
    deltax! = (x2% - x1%)/ubound(channel())
    select case reconst?
    case reconst_TRIANGLE
        oldy% = spectMagn(y2%, yDec%, minmagn!, channel(0))
        oldx! = x1%
        for i% = 1 to ubound(channel())
            y% = spectMagn(y2%, yDec%, minmagn!, channel(i%))
            x! = oldx! + deltax!
            line(x!,y%)-(oldx!,oldy%),theCol?
            oldy% = y%
            oldx! = x!
        next
    case reconst_SINC
        dim magn(0), phase(0)
        DFourier channel(), magn(), phase()
        oldx% = 0
        a! = 0
        for i% = 0 to ubound(magn)
            a! = magn(i%)*cos(-phase(i%)) + a!
        next
        oldy% = spectMagn(y2%, yDec%, minmagn!, a!)
        for x% = 1 to x2%-x1%
            a! = 0
            for i% = 0 to ubound(magn)
                a! = magn(i%)*cos(2*3.1415926*i%*x%/deltax!/(ubound(channel())+1)-phase(i%)) + a!
            next
            y% = spectMagn(y2%, yDec%, minmagn!, a!)
            line(x1%+x%, y%)-(x1%+oldx%, oldy%), theCol?
            oldx% = x%
            oldy% = y%
        next
'        arg! = 0
'        sinc! = 0
'        for i% = 0 to ubound(channel())
'            if arg! = 0 then
'                sinc! = sinc! + channel(i%)
'            else
'                sinc! = sinc! + channel(i%)*sin(arg!)/arg!
'            end if
'            arg! = arg! + 3.1415926
'        next
'        oldx% = 0
'        oldy% = spectMagn(y2%, yDec%, minmagn!, sinc!)
'        for x% = 1 to x2%-x1%
'            sinc! = 0
'            arg! = -3.1415926/deltax!*x%
'            for i% = 0 to ubound(channel())
'                if arg! = 0 then
'                    sinc! = sinc! + channel(i%)
'                else
'                    sinc! = sinc! + channel(i%)*sin(arg!)/arg!
'                end if
'                arg! = arg! + 3.1415926
'            next
'            y% = spectMagn(y2%, yDec%, minmagn!, sinc!)
'            line(x1% + x%, y%)-(x1% + oldx%, oldy%),theCol?
'            oldy% = y%
'            oldx% = x%
'        next
    case reconst_SQUARE
        oldy% = spectMagn(y2%, yDec%, minmagn!, channel(0))
        oldx% = 0
        x! = x1%+deltax!/2
        for i% = 1 to ubound(channel())
            y% = spectMagn(y2%, yDec%, minmagn!, channel(i%))
            x! = x! + deltax!
            line(x!,oldy%)-(oldx!,oldy%),theCol?
            line(x!,oldy%)-(x!,y%), theCol?
            oldy% = y%
            oldx! = x!
        next
        line(oldx!+deltax!,oldy%)-(oldx!,oldy%),theCol?
    case reconst_POINT
        for i% = 1 to ubound(channel())
            y% = spectMagn(y2%, yDec%, minmagn!, channel(i%))
            x% = i%*deltax!
            pset(x%+x1%,y%),theCol?
            oldy% = y%
            oldx% = x%
        next
    end select
end sub

'Draws the phase for the spectrum graph.  Helper function for drawSpect.
'x1%:  x-coordinate of upper left corner
'y1%:  y-coordinate of upper left corner
'x2%:  x-coordinate of the lower right corner
'y2%:  y-coordinate of the lower right corner
'channel(): array containing phase information
'chcolor?:  color to draw the channel
sub drawSpectPhase(byval x1%, byval y1%, byval x2%, byval y2%, channel(), chColor?)
drawChannel x1%, y1%, x2%, y2%, channel(), 0, 8/2/3.1415926, chColor?
end sub

'Helper function for the spectrum magnitude, returns the screen coordinate for the value
'y_LR%: y-position of the lower right corner
'yDec%: in logrithmic mode, the distance representing a decade, in regular mode, the distance representing volt/div
'minmagn!:  in logrithmic mode, the minimum magnitude
'y!:  the value to find the screen coordinate for
'RETURNS:  the screen coordinate of y! given all other inputs
function spectMagn(byval y_LR%, byval yDec%, byval minmagn!, byval y!)
if bit(mode?,4) = 1 then
    'logrithmic magnitude
    if y! <= 0 then y! = minmagn!/10
    y% = y_LR% - yDec%*(log10(y!/minmagn!))
else
    'regular magnitude
    y% = y_LR% - yDec%*y!
end if
spectMagn = y%
end function

'Draw a LOWERED box using the x and y locations, width and height, and bgcolor?
'x%: the x-position for the upper left corner of the box
'y%: the y-position for the upper left corner of the box
'l%: the outer width of the box in pixels
'h%: the outer height of the box in pixels
SUB box (byVal x%,  byVal y%, byVal l%, byVal h%)
xb% = x% + l%
yb% = y% + h%
LINE (x%, y%)-(xb%, y%), 0
LINE (x%, y%)-(x%, yb%), 0
LINE (xb%, y%)-(xb%, yb%), 15
LINE (x%, yb%)-(xb%, yb%), 15
END SUB
