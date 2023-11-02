'============================================================================
'*Author:  Jonathan Weaver
'*Date:    4/6/2005
'*Version: 1.0 build #1, 10/22/2002
'*         1.0 build #2, 4/6/2005
'*Filename:  oscillo.bas
'*Description:  A simple oscilloscope program, designed to work with a PIC based hardware design
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
'Todo:
'(1)  Add Freq Sample changing interface
'(2)  Add Trigger delay changing interface
'(3)  Change Trigger settings buttons ... DONE 4/6/2005
'(4)  Reconstruction modes .... DONE 2/1/2005
'(5)  True XY mode vs Ch1, Ch2 mode
'(6)  Volt/div
'(7)  Offset Ch1, and Ch2
'============================================================================

'============================================================================
' C O M P I L E R   D I R E C T I V E S
'============================================================================

$compile exe "oscillo.exe"
$dynamic

'============================================================================
' L I N K E D   F I L E S
'============================================================================

$link "gui2.pbu"            'General GUI library
$link "advgrfic.pbu"        'General graphic library
$link "logic.pbu"           'Defines true and false
$link "strgstff.pbu"        'String manipulation library
$link "numbers.pbu"

$link "HDriver.pbu"         'Hardware driver for the oscilloscope
    $link "parallel.pbu"    'Used by HDriver to communicate via parallel port
    $link "par_i2c.pbu"     'Used by HDriver to communicate via parallel port

$link "oscDisp.pbu"         'Oscilloscope and spectrum display for the waveform

'============================================================================
' S H A R E D   A N D   E X T E R N A L  D E C L A R A T I O N S
'============================================================================

'GUI shared variables
dim fontStyle as byte, fcolor as byte, bcolor as byte, keyStatus as byte
dim hbcolor as byte, hfcolor as byte, dcolor as byte

public hbcolor, hfcolor, dcolor
public fcolor, bcolor
public fontStyle
public xpos%,ypos%,but%
public kbd$, keystatus

'PAR_I2C shared variables
dim WTA as integer, WTB as integer
dim LPTPORT as integer, CLK as integer, SDA as integer, SDAIN as integer
dim CLKCONTROL as integer, SDACONTROL as integer, SDAINCONTROL as integer
dim CLKSET as byte, CLKRESET as byte, SDASET as byte, SDARESET as byte
dim SDAINSET as byte, SDAINRESET as byte

public WTA, WTB
public LPTPORT, CLK, SDA, SDAIN
public CLKCONTROL, SDACONTROL, SDAINCONTROL
public SDASET, SDARESET, CLKRESET, CLKSET, SDAINSET, SDAINRESET

'Osc Display variables
public bgcolor?
public lcolor?
public chAcolor?
public chBcolor?
public curColor?

public mode?                                            'Mode setting
public reconst?                                         'Function reconstruction
public timeSample                                       'Time per sample

%DIVISIONS = 10

'Data for each channel
dim channelA(1), channelB(1)
public channelA(), channelB()

public chAVoltDiv, chBVoltDiv                       'Volts per division
public chAOffset, chBOffset                         'Offset from zero

'Main Menu
dim menuHeader(2) as string, menuHeaderButton(2) as integer
shared menuHeader(), menuHeaderButton()

'Button bar
dim butIconFile(20) as string, butIconNum(20) as integer, butEnabled(20) as byte, butSAArea(20) as integer
shared butIconFile(), butIconNum(), butEnabled(), butSAArea()

'Keep up with the configuration in the PIC Hardware
'shared configLoc1?, triggerDelay1?, triggerDelay2?, sampleRate1?, sampleRate2?
'shared bufferSize??

'Declare data
dim dataRec(1) as byte
shared dataRec()

shared scopeArea%, spectArea%

'Keep up with buttons, textboxes, checkboxes, etc.
shared triggerDelayUBut%, triggerDelayLBut%, triggerDelayBut%, trigpos%, trigneg%, trigEnable%
shared chAOffsetUBut%, chAOffsetLBut%, chBOffsetUBut%, chBOffsetLBut%, chAOffsetBut%, chBOffsetBut%
shared timeDivUCBut%, timeDivLCBut%, timeDivUFBut%, timeDivLFBut%
shared chAVoltDivUCBut%, chAVoltDivLCBut%, chAVoltDivUFBut%, chAVoltDivLFBut%
shared chBVoltDivUCBut%, chBVoltDivLCBut%, chBVoltDivUFBut%, chBVoltDivLFBut%
shared timeDivBut%, chAVoltDivBut%, chBVoltDivBut%, truexy%, chAEnabledBut%, chBEnabledBut%

'Refresh on timer?
shared redraw

'============================================================================
' M A I N
'============================================================================

'Set up screen
screen 12
initialize

mouseOn
drawScreen 0,0,639,479

comStartRedrawTimer

'Event loop

do
    mainMenuHandler y?,a%, menuHeaderButton()
    'Process main menu events first
    doMainMenuEvents y?,a%

    'Do keyboard events
    doKeyboardEvents

    'Do mouse events
    doMouseOverEvents
    doMouseClickEvents
    doMouseOverEvents   'Sometimes, the mouse moves during a click
loop
system

redrawScope:
if redraw = 1 then
    if isPortValid(LPTPORT) then
        'Set configuration
        'Recieve data
        'Get configuration
        'Convert data
        if updateChannels(channelA(), channelB(), DCA?, DCB?) = 2 then
            sRate! = getSampleRate!()
            if sRate! <> 0 then
                timeSample = 1/sRate!
            end if
            getScopePosition x1%, y1%, x2%, y2%
            SmartMouseOff x1%, y1%, x2%, y2%
            getSpectPosition x1%, y1%, x2%, y2%
            SmartMouseOff x1%, y1%, x2%, y2%
            drawScope
            drawSpectrum
            mouseOn
            mouseOn
        end if
    else
       'some error message
        cls
        print "Error opening parallel port"
        system
    end if
end if
return

'============================================================================
'S U B R O U T I N E S   A N D   F U N C T I O N S
'============================================================================

sub doMainMenuEvents(y?, a%)
if a% >= 0 then
    if redraw = 1 then redraw = 0
end if
select case a%              'Handle menu first
case menuHeaderButton(0)    'File Menu
    dim fileMenu(2) as string
    fileMenu(0) = "Save Waveform|Save the waveform to disk"
    fileMenu(1) = "-"
    fileMenu(2) = "Exit|Exit the program>255"
    y? = clkMainMenu(a%,menuHeader(),menuHeaderButton(),fileMenu())
    erase fileMenu
    if y? = 2 then exitProgram
case menuHeaderButton(1)    'Configuration Menu
    dim viewMenu(6) as string
    viewMenu(0) = "Reconstruction>3"
    viewMenu(1) = "Time Mode|View Channels versus time"
    viewMenu(2) = "X-Y Mode|View Channel A versus Channel B>255"
    viewMenu(3) = "Triangle"
    viewMenu(4) = "Square"
    viewMenu(5) = "Sinc"
    viewMenu(6) = "Point>255"
    y? = clkMainMenu(a%,menuHeader(),menuHeaderButton(),viewMenu())
    select case y?
    case 3 : comReconstTriangle
    case 4 : comReconstSquare
    case 5 : comReconstSinc
    case 6 : comReconstPoint
    end select
    erase viewMenu
case menuHeaderButton(2)    'Help Menu
    dim helpMenu(2) as string
    helpMenu(0) = "Help"
    helpMenu(1) = "-"
    helpMenu(2) = "About"
    y? = clkMainMenu(a%,menuHeader(),menuHeaderButton(),helpMenu())
    erase helpMenu
case else
end select
if redraw = 0 then redraw = 1
end sub

'------------------------------------------------------------------------------
sub doKeyboardEvents
end sub

'------------------------------------------------------------------------------
sub doMouseClickEvents
static isOnA%, isOnB%, isOnC%, isOnD%, isOnE%, isOnF%

while but% > 0                  'Handle mouse clicks
    clickedSA% = SA_mouseClick
    select case clickedSA%
    case scopeArea%
        clkScope
        refreshCursorDisp
    case butSAArea(4)
        clickButtonBar clickedSA%
        redraw = 1
        mode? = (mode? and not mode_HOLD and not mode_STOP) or (mode_RUN + Mode_DrawBG)
    case butSAArea(5)
        clickButtonBar clickedSA%
        redraw = 2
    case butSAArea(6)
        redraw = 1
        clickButtonBar clickedSA%
        mode? = (mode? and not mode_RUN and not mode_STOP) or (mode_HOLD + Mode_DrawBG)
    case butSAArea(8)
        clickButtonBar clickedSA%
        comReconstTriangle
    case butSAArea(9)
        clickButtonBar clickedSA%
        comReconstSquare
    case butSAArea(10)
        clickButtonBar clickedSA%
        comReconstSinc
    case butSAArea(11)
        clickButtonBar clickedSA%
        comReconstPoint
    case butSAArea(13)
        clickButtonBar clickedSA%
        mode? = mode? and not(mode_XY)
        refreshScope
    case butSAArea(14)
        clickButtonBar clickedSA%
        mode? = mode? or mode_XY
        refreshScope
    case butSAArea(15)
        clickButtonBar clickedSA%
        mode? = mode? and not(mode_FREQMAGLOG)
        refreshScope
    case butSAArea(16)
        clickButtonBar clickedSA%
        mode? = mode? or mode_FREQMAGLOG
        refreshScope
    case butSAArea(18)
        clickButtonBar clickedSA%
        comTriggerPos
    case butSAArea(19)
        clickButtonBar clickedSA%
        comTriggerNeg
    case butSAArea(20)
        clickButtonBar clickedSA%
        comTriggerOff
    case triggerDelayUBut%
        clkTextButton clickedSA%
        triggerDelayChange ADJ_FINCR
        comTriggerDelay
    case triggerDelayLBut%
        clkTextButton clickedSA%
        triggerDelayChange ADJ_FDECR
        comTriggerDelay
    case triggerDelayBut%
        text$ = engNumRep$(getTriggerDelay(), 4)
        tcolor? = bcolor
        bcolor = 15
        timerStop
        clkTextBox triggerDelayBut%, text$
        bcolor = tcolor?
        setTriggerDelay fromEngNumRep(text$)
        comTriggerDelay
    case trigpos%
        if getEnableTrigger and isFalse(getTriggerSlope) then
            clkCheckBox clickedSA%, 0
            comTriggerPos
        end if
    case trigneg%
        if getEnableTrigger and getTriggerSlope then
            clkCheckBox clickedSA%, 0
            comTriggerNeg
        end if
    case trigEnable%
        if getEnableTrigger then
            clkCheckBox clickedSA%, -1
            comTriggerOff
        else
            clkCheckBox clickedSA%, 0
            comTriggerOn
        end if
    case chAOffsetUBut%
        clkTextButton clickedSA%
        chAOffset = chAOffset + chAVoltDiv / 5
        comRefreshChAOffset
    case chAOffsetLBut%
        clkTextButton clickedSA%
        chAOffset = chAOffset - chAVoltDiv / 5
        comRefreshChAOffset
    case chBOffsetUBut%
        clkTextButton clickedSA%
        chBOffset = chBOffset + chBVoltDiv / 5
        comRefreshChBOffset
    case chBOffsetLBut%
        clkTextButton clickedSA%
        chBOffset = chBOffset - chBVoltDiv / 5
        comRefreshChBOffset
    case chAOffsetBut%
        text$ = engNumRep$(chAOffset, 4)
        tcolor? = bcolor
        bcolor = 15
        timerStop
        clkTextBox chAOffsetBut%, text$
        bcolor = tcolor?
        comStartRedrawTimer
        chAOffset = fromEngNumRep(text$)
        comRefreshChAOffset
    case chBOffsetBut%
        text$ = engNumRep$(chBOffset, 4)
        tcolor? = bcolor
        bcolor = 15
        timerStop
        clkTextBox chBOffsetBut%, text$
        bcolor = tcolor?
        comStartRedrawTimer
        chBOffset = fromEngNumRep(text$)
        comRefreshChBOffset
    case chAVoltDivUCBut%
        clkTextButton clickedSA%
        chAVoltDiv = round(chAVoltDiv * 1.5, 1)
        chAOffset = chAOffset * 1.5
        comRefreshChAVoltDiv
    case chAVoltDivLCBut%
        clkTextButton clickedSA%
        oldVoltDiv = chAVoltDiv
        chAVoltDiv = round(chAVoltDiv * 0.5, 1)
        if chAVoltDiv = 0 then chAVoltDiv = 0.1
        chAOffset = chAOffset * chAVoltDiv/oldVoltDiv
        comRefreshChAVoltDiv
    case chAVoltDivUFBut%
        clkTextButton clickedSA%
        oldVoltDiv = chAVoltDiv
        chAVoltDiv = round(chAVoltDiv * 1.1, 1)
        if chAVoltDiv - oldVoltDiv < 0.05 then chAVoltDiv = chAVoltDiv + 0.1
        chAOffset = chAOffset * chAVoltDiv/oldVoltDiv
        comRefreshChAVoltDiv
    case chAVoltDivLFBut%
        clkTextButton clickedSA%
        oldVoltDiv = chAVoltDiv
        chAVoltDiv = round(chAVoltDiv * 0.9, 1)
        if oldVoltDiv - chAVoltDiv < 0.05 then chAVoltDiv = chAVoltDiv - 0.1
        if chAVoltDiv = 0 then chAVoltDiv = 0.1
        chAOffset = chAOffset * chAVoltDiv/oldVoltDiv
        comRefreshChAVoltDiv
    case chBVoltDivUCBut%
        clkTextButton clickedSA%
        chBVoltDiv = round(chBVoltDiv * 1.5, 1)
        chBOffset = chBOffset * 1.5
        comRefreshChBVoltDiv
    case chBVoltDivLCBut%
        clkTextButton clickedSA%
        oldVoltDiv = chBVoltDiv
        chBVoltDiv = round(chBVoltDiv * 0.5, 1)
        if chBVoltDiv = 0 then chBVoltDiv = 0.1
        chBOffset = chBOffset * chBVoltDiv/oldVoltDiv
        comRefreshChBVoltDiv
    case chBVoltDivUFBut%
        clkTextButton clickedSA%
        oldVoltDiv = chBVoltDiv
        chBVoltDiv = round(chBVoltDiv * 1.1, 1)
        if chBVoltDiv - oldVoltDiv < 0.05 then chBVoltDiv = chBVoltDiv + 0.1
        chBOffset = chBOffset * chBVoltDiv/oldVoltDiv
        comRefreshChBVoltDiv
    case chBVoltDivLFBut%
        clkTextButton clickedSA%
        oldVoltDiv = chBVoltDiv
        chBVoltDiv = round(chBVoltDiv * 0.9, 1)
        if oldVoltDiv - chBVoltDiv < 0.05 then chBVoltDiv = chBVoltDiv - 0.1
        if chBVoltDiv = 0 then chBVoltDiv = 0.1
        chBOffset = chBOffset * chBVoltDiv/oldVoltDiv
        comRefreshChBVoltDiv
    case timeDivBut%
        text$ = engNumRep$(getTimePerDivision(), 4)
        tcolor? = bcolor
        bcolor = 15
        timerStop
        clkTextBox timeDivBut%, text$
        bcolor = tcolor?
        timePerDiv! = fromEngNumRep(text$)
        if timePerDiv! < (getMaxSamplesPerChannel()-1)/getMaxSampleRate()/%DIVISIONS then
            setSampleRate getMaxSampleRate()
            setSamplesPerChannel timePerDiv!*getSampleRate()*%DIVISIONS+1
        else
            setSamplesPerChannel getMaxSamplesPerChannel()
            setSampleRate ((getSamplesPerChannel()-1)/timePerDiv!/%DIVISIONS)
        end if
        comStartRedrawTimer
        comRefreshTimeDiv
    case timeDivUCBut%
        clkTextButton clickedSA%
        if getSamplesPerChannel() = getMaxSamplesPerChannel() then
            sampleRateChange ADJ_CDECR
        else
            setSamplesPerChannel int(getSamplesPerChannel()*2)
        end if
        comRefreshTimeDiv
    case timeDivLCBut%
        clkTextButton clickedSA%
        if getSampleRate() = getMaxSampleRate() then
            setSamplesPerChannel int(getSamplesPerChannel()*0.5)
        else
            sampleRateChange ADJ_CINCR
        end if
        comRefreshTimeDiv
    case timeDivUFBut%
        clkTextButton clickedSA%
        if getSamplesPerChannel() = getMaxSamplesPerChannel() then
            sampleRateChange ADJ_FDECR
        else
            setSamplesPerChannel int(getSamplesPerChannel()*1.1)
        end if
        comRefreshTimeDiv
    case timeDivLFBut%
        clkTextButton clickedSA%
        if getSampleRate() = getMaxSampleRate() then
            setSamplesPerChannel int(getSamplesPerChannel()*0.9)
        else
            sampleRateChange ADJ_FINCR
        end if
        comRefreshTimeDiv
    case chAVoltDivBut%
        text$ = engNumRep$(chAVoltDiv, 4)
        tcolor? = bcolor
        bcolor = 15
        timerStop
        clkTextBox chAVoltDivBut%, text$
        bcolor = tcolor?
        comStartRedrawTimer
        oldVoltDiv = chAVoltDiv
        chAVoltDiv = fromEngNumRep(text$)
        chAOffset = chAVoltDiv/oldVoltDiv*chAOffset
        comRefreshChAVoltDiv
    case chBVoltDivBut%
        text$ = engNumRep$(chBVoltDiv, 4)
        tcolor? = bcolor
        bcolor = 15
        timerStop
        clkTextBox chBVoltDivBut%, text$
        bcolor = tcolor?
        comStartRedrawTimer
        oldVoltDiv = chBVoltDiv
        chBVoltDiv = fromEngNumRep(text$)
        chBOffset = chBVoltDiv/oldVoltDiv*chBOffset
        comRefreshChBVoltDiv
    case truexy%
        clkCheckBox clickedSA%, isOnD%         'Tie isOn to value
    case chAEnabledBut%
        isOn% = isTrue(mode? and mode_CHAENABLED)
        clkCheckBox clickedSA%, isOn%
        if isOn% then
            mode? = mode? or mode_CHAENABLED
        else
            mode? = mode? and not(mode_CHAENABLED)
        end if
    case chBEnabledBut%
        isOn% = isTrue(mode? and mode_CHBENABLED)
        clkCheckBox clickedSA%, isOn%
        if isOn% then
            mode? = mode? or mode_CHBENABLED
        else
            mode? = mode? and not(mode_CHBENABLED)
        end if
    case else
        waitinput
    end select
wend
end sub

'------------------------------------------------------------------------------
sub DoMouseOverEvents
static ms%

SAOver% = SA_mouseOver
select case SAOver%
case scopeArea%
    if overCursor(xpos%, ypos%) >= 0 then
        if ms% <> 2 then setMCursor "Default.cur", 3
        ms% = 2
    else
        if ms% <> 1 then setMCursor "Default.cur", 7
        ms% = 1
    end if
    scopeValue xpos%, ypos%, t!, chAV!, chBV!
    scopeValDisp t!, chAV!, chBV!
case spectArea%
    if ms% <> 1 then setMCursor "Default.cur", 7
    ms% = 1
    spectumValue xpos%, ypos%, freq!, chMagn!, chPhase!
    spectValDisp freq!, chMagn!, chPhase!
case butSAArea(0)
    mouseOverButtonBar SAOver%, "Save waveform"
case butSAArea(1)
    mouseOverButtonBar SAOver%, "Save settings"
case butSAArea(2)
    mouseOverButtonBar SAOver%, "Open settings"
case butSAArea(4)
    mouseOverButtonBar SAOver%, "Run mode"
case butSAArea(5)
    mouseOverButtonBar SAOver%, "Hold mode"
case butSAArea(6)
    mouseOverButtonBar SAOver%, "Stop"
case butSAArea(8)
    mouseOverButtonBar SAOver%, "Reconstruct triangle"
case butSAArea(9)
    mouseOverButtonBar SAOver%, "Reconstruct square"
case butSAArea(10)
    mouseOverButtonBar SAOver%, "Reconstruct sinc"
case butSAArea(11)
    mouseOverButtonBar SAOver%, "Reconstruct point"
case butSAArea(13)
    mouseOverButtonBar SAOver%, "Time versus voltage"
case butSAArea(14)
    mouseOverButtonBar SAOver%, "Channel A versus Channel B"
case butSAArea(15)
    mouseOverButtonBar SAOver%, "Frequency linear scale"
case butSAArea(16)
    mouseOverButtonBar SAOver%, "Frequency logrithmic scale"
case butSAArea(18)
    mouseOverButtonBar SAOver%, "Trigger positive"
case butSAArea(19)
    mouseOverButtonBar SAOver%, "Trigger negative"
case butSAArea(20)
    mouseOverButtonBar SAOver%, "No Trigger"
case else
    if ms% <> 0 then
        setMCursor "CursorA.cur", 5
        scopeValDest
    end if
    ms% = 0
end select
end sub

sub comTriggerDelay
tcolor? = bcolor
bcolor = 15
SA_getCoord SA_getIndex(triggerDelayBut%), x%, y%, x2%, y2%
drawTextBox x%, y%, x2%, y2%, engNumRep$(getTriggerDelay(), 4), 1, 1, 1
bcolor = tcolor?
comStartRedrawTimer
end sub

sub comStartRedrawTimer
on timer (0.1) gosub redrawScope
timerOn
redraw = 1
end sub

sub comTriggerRefresh
a? = getEnableTrigger
b? = getTriggerSlope
tcolor? = fcolor
if a? then
    SA_GetCoord SA_getIndex(trigEnable%), x%, y%, x1%, y1%
    drawCheckBox x%, y%, x1%, y1%, "Enabled", -1
else
    SA_GetCoord SA_getIndex(trigEnable%), x%, y%, x1%, y1%
    drawCheckBox x%, y%, x1%, y1%, "Enabled", 0
    fcolor = dcolor
end if
if b? then
    SA_GetCoord SA_getIndex(trigpos%), x%, y%, x1%, y1%
    drawCheckBox x%, y%, x1%, y1%, "Pos", -1
    SA_GetCoord SA_getIndex(trigneg%), x%, y%, x1%, y1%
    drawCheckBox x%, y%, x1%, y1%, "Neg", 0
else
    SA_GetCoord SA_getIndex(trigpos%), x%, y%, x1%, y1%
    drawCheckBox x%, y%, x1%, y1%, "Pos", 0
    SA_GetCoord SA_getIndex(trigneg%), x%, y%, x1%, y1%
    drawCheckBox x%, y%, x1%, y1%, "Neg", -1
end if
fcolor = tcolor?
end sub

sub comTriggerPos
enableTrigger TRUE
triggerSlope TRUE
comTriggerRefresh
end sub

sub comTriggerNeg
enableTrigger TRUE
triggerSlope FALSE
comTriggerRefresh
end sub

sub comTriggerOff
enableTrigger FALSE
comTriggerRefresh
end sub

sub comTriggerOn
enableTrigger TRUE
comTriggerRefresh
end sub

sub comRefreshTimeDiv
SA_getCoord SA_getIndex(timeDivBut%), x%, y%, x2%, y2%
tcolor? = bcolor
bcolor = 15
timerStop
timeSample! = 1/getSampleRate()
drawTextBox x%, y%, x2%, y2%, engNumRep$(getTimePerDivision(), 4), 1, 1, 1
bcolor = tcolor?
box x%+2, y2%+fontH+10, x2%-x%-4, fontH, FLAT
fontput x%+2, y2%+10+fontH, engNumRep$(1/timeSample!, 4)
timerOn
refreshScope
end sub

sub comRefreshChAVoltDiv
SA_getCoord SA_getIndex(chAVoltDivBut%), x%, y%, x2%, y2%
tcolor? = bcolor
bcolor = 15
timerStop
drawTextBox x%, y%, x2%, y2%, engNumRep$(chAVoltDiv, 4), 1, 1, 1
timerOn
bcolor = tcolor?
comRefreshChAOffset
end sub

sub comRefreshChBVoltDiv
SA_getCoord SA_getIndex(chBVoltDivBut%), x%, y%, x2%, y2%
tcolor? = bcolor
bcolor = 15
timerStop
drawTextBox x%, y%, x2%, y2%, engNumRep$(chBVoltDiv, 4), 1, 1, 1
timerOn
bcolor = tcolor?
comRefreshChBOffset
end sub

sub comRefreshChAOffset
SA_getCoord SA_getIndex(chAOffsetBut%), x%, y%, x2%, y2%
tcolor? = bcolor
bcolor = 15
timerStop
drawTextBox x%, y%, x2%, y2%, engNumRep$(chAOffset, 4), 1, 1, 1
timerOn
bcolor = tcolor?
refreshScope
end sub

sub comRefreshChBOffset
SA_getCoord SA_getIndex(chBOffsetBut%), x%, y%, x2%, y2%
tcolor? = bcolor
bcolor = 15
timerStop
drawTextBox x%, y%, x2%, y2%, engNumRep$(chBOffset, 4), 1, 1, 1
timerOn
bcolor = tcolor?
refreshScope
end sub

sub comReconstTriangle
reconst? = reconst_TRIANGLE
refreshScope
end sub

sub comReconstSquare
reconst? = reconst_SQUARE
refreshScope
end sub

sub comReconstSinc
reconst? = reconst_SINC
refreshScope
end sub

sub comReconstPoint
reconst? = reconst_POINT
refreshScope
end sub

sub refreshCursorDisp
getCursor 0, t!, chAV!, chBV!
getCursor 1, t1!, chAV1!, chBV1!
cursorDisp t!, chAV!, chBV!, t1!, chAV1!, chBV1!
end sub

sub refreshScope
mode? = mode? + Mode_DrawBG
timerStop
drawScope
drawSpectrum
timerOn
refreshCursorDisp
end sub

'------------------------------------------------------------------------------
sub exitProgram
system
end sub

'------------------------------------------------------------------------------
sub cursorDisp (byval t!, byval chAV!, byval chBV!, byval t1!, byval chAV1!, byval chBV1!)
timerStop
ya% = 37+429-6-fontH-5*(fontH+4)
fontStyle = BOLD
line(330,ya%)-(619-2,ya%+5*(fontH+4)),bcolor?,bf
a% = 332+fontlength("Cursor 1")
d% = 619
b% = (d%+2*a%)/3
c% = (2*d%+a%)/3
fontStyle = BOLD + UNDERLINE
fontcent a%,ya%,b%, "T"
fontcent b%,ya%,c%,"Ch A"
fontcent c%,ya%,d%,"Ch B"
fontStyle = NORMAL
ya% = ya% + fontH+4
fontput 332,ya%, "Cursor 1"
fontcent a%,ya%,b%, engNumRep$(t!, 4) + "s"
fontcent b%,ya%,c%, engNumRep$(chAV!,4)+"V"
fontcent c%,ya%,d%, engNumRep$(chBV!,4)+"V"
ya% = ya% + fontH+4
fontput 332,ya%, "Cursor 2"
fontcent a%,ya%,b%, engNumRep$(t1!,4)+"s"
fontcent b%,ya%,c%, engNumRep$(chAV1!,4)+"V"
fontcent c%,ya%,d%, engNumRep$(chBV1!,4)+"V"
ya% = ya% + fontH+4
fontput 332,ya%, "Delta"
fontcent a%,ya%,b%, engNumRep$(t!-t1!,4)+"s"
fontcent b%,ya%,c%, engNumRep$(chAV!-chAV1!,4)+"V"
fontcent c%,ya%,d%, engNumRep$(chBV!-chBV1!,4)+"V"
ya% = ya% + fontH+4
fontput 332, ya%, "1/Delta"
if t! = t1! then
    fontcent a%,ya%,b%, "NAN"
else
    fontcent a%,ya%,b%, engNumRep$(1/(t!-t1!),4)+"Hz"
end if
timerOn
end sub

'------------------------------------------------------------------------------
sub scopeValDisp (t!, chAV!, chBV!)
line (640-statusValWidth, 478-fontH)-(637,478),bcolor?, bf
timerStop
fontput 650-statusValWidth, 478-fontH, "T="+engNumRep$(t!,4)+"s"
fontput 650-statusValWidth*2/3, 478-fontH, "ChA="+engNumRep$(chAV!,4)+"V"
fontput 650-statusValWidth/3, 478-fontH, "ChB="+engNumRep$(chBV!,4)+"V"
timerOn
end sub

'------------------------------------------------------------------------------
sub spectValDisp (freq!, chMagn!, chPhase!)
line (640-statusValWidth, 478-fontH)-(637,478),bcolor?, bf
timerStop
fontput 650-statusValWidth, 478-fontH, "Freq="+str$(freq!,4)
fontput 650-statusValWidth*2/3+fontlength("req"), 478-fontH, "Magn="+engNumRep$(chMagn!,4)+"V"
fontput 650-statusValWidth/3+fontlength("agn"), 478-fontH, "Ph="+str$(chPhase!,4)
timerOn
end sub

'------------------------------------------------------------------------------
sub scopeValDest
line (640-statusValWidth, 478-fontH)-(637,478),bcolor?, bf
end sub

'------------------------------------------------------------------------------
function statusValWidth
statusValWidth = 39*fontlength("8")+40
end function

'Draws the Screen after a dialog has been called
'------------------------------------------------------------------------------
sub drawScreen(byVal x1%, byVal y1%, byVal x2%, byVal y2%)
static initial?

view screen (x1%, y1%)-(x2%, y2%)

'Draw the background
drawDesktop 0, fontH+38, 9, 430-fontH*2
drawDesktop 620, fontH+38, 639, 430-fontH*2
drawDesktop 0, 28 + fontH, 639, 37 + fontH
drawDesktop 0, 431-2*fontH, 639, 476-fontH

'Draw the main menu
drawMainMenu menuHeader()

'Draw the button bar
drawButtonBar 0, fontH+5, 640, butIconFile(), butIconNum(), butSAArea()

'Main dialog
mouseOff
box 10, fontH+38,619,430-fontH*2, ETCHEDR
cursorDisp 0, 0, 0, 0, 0, 0
mouseOn
a% = 330
d% = 619
b% = (d%+2*a%)/3
c% = (2*d%+a%)/3
y% = fontH+50
fontStyle = BOLD
tcolor? = bcolor
tfcolor? = fcolor
bcolor = 2
fcolor = 15
mouseOff
box a%+2, y%-2, d%-a%-4, fontH+2, LOWERED
for i% = y% to y% + fontH - 2 step 2
    line(a%+4,i%)-(d%-4,i%),1
next
fontcent a%, y%, d%, "PPMO - PC PIC MAXIM Oscilloscope"
bcolor = tcolor?
fcolor = tfcolor?
y% = y% + fontH + 12

box a%+2, y%-2, b%-a%-4, fontH+2, ETCHEDR
fontcent a%, y%, b%, "T"
bcolor = chAColor?
box b%+2, y%-2, c%-b%-4, fontH+2, ETCHEDR
fontcent b%, y%, c%, "Ch A"
bcolor = chBColor?
box c%+2, y%-2, d%-c%-4, fontH+2, ETCHEDR
fontcent c%, y%, d%, "Ch B"
fontStyle = NORMAL
mouseOn

y% = y% + fontH + 10
if initial? = 0 then
    truexy% = iniCheckbox(a%+2, y%, b%-2, y%, "True X-Y", 0)
    chAEnabledBut% = iniCheckbox(b%+2, y%, c%-2, y%, "Enabled", 1)
    chBEnabledBut% = iniCheckbox(c%+2, y%, d%-2, y%, "Enabled", 1)
else
    SA_getCoord SA_getIndex(truexy%), x1%, y1%, x2%, y2%
    drawCheckbox x1%, y1%, x2%, y2%, "True X-Y", isOn%               'Relate isOn to real value
    SA_getCoord SA_getIndex(chAEnabledBut%), x1%, y1%, x2%, y2%
    drawCheckbox x1%, y1%, x2%, y2%, "Enabled", isTrue(mode? and mode_CHAENABLED)
    SA_getCoord SA_getIndex(chBEnabledBut%), x1%, y1%, x2%, y2%
    drawCheckbox x1%, y1%, x2%, y2%, "Enabled", isTrue(mode? and mode_CHBENABLED)
end if
y% = y% + fontH + 4

mouseOff
fontput a%+2, y%, "Time / Div (s)"
fontput b%+2, y%, "Volt / Div"
fontput c%+2, y%, "Volt / Div"
y% = y% + fontH + 2
bcolor = 15     'WHITE
mouseOn

if initial? = 0 then
    timeDivBut% = iniTextBox(a%+2, y%, b%-22, y%, engNumRep$(getTimePerDivision(),4))
    chAVoltDivBut% = iniTextBox(b%+2, y%, c%-22, y%, engNumRep$(chAVoltDiv,4))
    chBVoltDivBut% = iniTextBox(c%+2, y%, d%-22, y%, engNumRep$(chBVoltDiv,4))
else
    SA_getCoord SA_getIndex(timeDivBut%), x1%, y1%, x2%, y2%
    drawTextbox x1%, y1%, x2%, y2%, engNumRep$(getTimePerDivision(),4), 1, 1, 1
    SA_getCoord SA_getIndex(chAVoltDivBut%), x1%, y1%, x2%, y2%
    drawTextbox x1%, y1%, x2%, y2%, engNumRep$(chAVoltDiv,4), 1,1,1
    SA_getCoord SA_getIndex(chBVoltDivBut%), x1%, y1%, x2%, y2%
    drawTextbox x1%, y1%, x2%, y2%, engNumRep$(chBVoltDiv,4),1,1,1
end if
bcolor = tcolor?
ya% = y%+int(fontH/2)+2
yb% = y%+4+fontH
if initial? = 0 then
    timeDivUCBut% = SA_addTop(b%-11,y%,b%-3,ya%)
    timeDivLCBut% = SA_addTop(b%-11,ya%+1,b%-3,yb%)
    timeDivUFBut% = SA_addTop(b%-20,y%,b%-12,ya%)
    timeDivLFBut% = SA_addTop(b%-20,ya%+1,b%-12,yb%)
    chAVoltDivUCBut% = SA_addTop(c%-11,y%,c%-3,ya%)
    chAVoltDivLCBut% = SA_addTop(c%-11,ya%+1,c%-3,yb%)
    chAVoltDivUFBut% = SA_addTop(c%-20,y%,c%-12,ya%)
    chAVoltDivLFBut% = SA_addTop(c%-20,ya%+1,c%-12,yb%)
    chBVoltDivUCBut% = SA_addTop(d%-11,y%,d%-3,ya%)
    chBVoltDivLCBut% = SA_addTop(d%-11,ya%+1,d%-3,yb%)
    chBVoltDivUFBut% = SA_addTop(d%-20,y%,d%-12,ya%)
    chBVoltDivLFBut% = SA_addTop(d%-20,ya%+1,d%-12,yb%)
end if
mouseOff
box b%-11, y%, 8, ya%-y%, RAISED
box b%-11, ya%+1, 8, ya%-y%, RAISED
drawArrow b%-10, y%+1, 6, 0
drawArrow b%-10, ya%+2, 6, 1
line (b%-9,y%+2)-(b%-5,y%+2),0
line (b%-9,yb%-2)-(b%-5,yb%-2),0
box b%-20, y%, 8, ya%-y%, RAISED
box b%-20, ya%+1, 8, ya%-y%, RAISED
drawArrow b%-19, y%+1, 6, 0
drawArrow b%-19, ya%+2, 6, 1
box c%-11, y%, 8, ya%-y%, RAISED
box c%-11, ya%+1, 8, ya%-y%, RAISED
drawArrow c%-10, y%+1, 6, 0
drawArrow c%-10, ya%+2, 6, 1
line (c%-9,y%+2)-(c%-5,y%+2),0
line (c%-9,yb%-2)-(c%-5,yb%-2),0
box c%-20, y%, 8, ya%-y%, RAISED
box c%-20, ya%+1, 8, ya%-y%, RAISED
drawArrow c%-19, y%+1, 6, 0
drawArrow c%-19, ya%+2, 6, 1
box d%-11, y%, 8, ya%-y%, RAISED
box d%-11, ya%+1, 8, ya%-y%, RAISED
drawArrow d%-10, y%+1, 6, 0
drawArrow d%-10, ya%+2, 6, 1
line (d%-9,y%+2)-(d%-5,y%+2),0
line (d%-9,yb%-2)-(d%-5,yb%-2),0
box d%-20, y%, 8, ya%-y%, RAISED
box d%-20, ya%+1, 8, ya%-y%, RAISED
drawArrow d%-19, y%+1, 6, 0
drawArrow d%-19, ya%+2, 6, 1

y% = y% + fontH + 10

fontput a%+2, y%, "Sample Rate (Hz)"
fontput b%+2, y%, "Offset (V)"
fontput c%+2, y%, "Offset (V)"
y% = y% + fontH + 2
box a%+2, y%, b%-a%-4,fontH+4, LOWERED
fontput a%+4, y%+2, engNumRep$(1/timeSample!, 4)
bcolor = 15     'WHITE
mouseOn
if initial? = 0 then
    chAOffsetBut% = iniTextBox(b%+2, y%, c%-13, y%, engNumRep$(chAOffset,4))
    chBOffsetBut% = iniTextBox(c%+2, y%, d%-13, y%, engNumRep$(chBOffset,4))
else
    SA_getCoord SA_getIndex(chAOffsetBut%), x1%, y1%, x2%, y2%
    drawTextbox x1%, y1%, x2%, y2%, engNumRep$(chAOffset,4),1,1,1
    SA_getCoord SA_getIndex(chBOffsetBut%), x1%, y1%, x2%, y2%
    drawTextbox x1%, y1%, x2%, y2%, engNumRep$(chBOffset,4),1,1,1
end if
bcolor = tcolor?
ya% = y%+int(fontH/2)+2
yb% = y%+4+fontH
if initial? = 0 then
    chAOffsetUBut% = SA_addTop(c%-11,y%,c%-3,ya%)
    chAOffsetLBut% = SA_addTop(c%-11,ya%+1,c%-3,yb%)
    chBOffsetUBut% = SA_addTop(d%-11,y%,d%-3,ya%)
    chBOffsetLBut% = SA_addTop(d%-11,ya%+1,d%-3,yb%)
end if
mouseOff
box c%-11, y%, 8, ya%-y%, RAISED
box c%-11, ya%+1, 8, ya%-y%, RAISED
drawArrow c%-10, y%+1, 6, 0
drawArrow c%-10, ya%+2, 6, 1
box d%-11, y%, 8, ya%-y%, RAISED
box d%-11, ya%+1, 8, ya%-y%, RAISED
drawArrow d%-10, y%+1, 6, 0
drawArrow d%-10, ya%+2, 6, 1
'Add fontput statement inside box to report sample rate

y% = y% + fontH + 10
fontput a%+2, y%, "Equivalent time"
fontput b%+2, y%, "DC Coupling"
fontput c%+2, y%, "DC Coupling"

y% = y% + fontH + 20
fontStyle = BOLD
box a%+2, y%-2, b%-a%-4, fontH+2, ETCHEDR
fontcent a%, y%, b%, "Trigger"
fontStyle = NORMAL
y% = y% + fontH + 10
mouseOn
tcolor? = fcolor
if initial? = 0 then
    if getEnableTrigger then
        trigEnable% = iniCheckbox(a%+2, y%, b%-2, y%, "Enabled", -1)
    else
        trigEnable% = iniCheckbox(a%+2, y%, b%-2, y%, "Enabled", 0)
        fcolor = dcolor
    end if
else
    comTriggerRefresh
end if
y% = y% + fontH + 4
if initial? = 0 then
    if getTriggerSlope then
        trigpos% = iniCheckbox(a%+2, y%, (a%+b%)/2-2, y%, "Pos", -1)
        trigneg% = iniCheckbox((a%+b%)/2+2, y%, b%-2, y%, "Neg", 0)
    else
        trigpos% = iniCheckbox(a%+2, y%, (a%+b%)/2-2, y%, "Pos", 0)
        trigneg% = iniCheckbox((a%+b%)/2+2, y%, b%-2, y%, "Neg", -1)
    end if
end if
fcolor = tcolor?
y% = y% + fontH + 4
mouseOff
fontput a%+2, y%, "Trigger Delay (s)"
y% = y% + fontH + 2
tcolor? = bcolor
bcolor = 15     'WHITE
mouseOn
if initial? = 0 then
    triggerDelayBut% = iniTextBox(a%+2, y%, b%-13, y%, engNumRep$(getTriggerDelay(),4))     'Attach to real value
else
    SA_getCoord SA_getIndex(triggerDelayBut%), x1%, y1%, x2%, y2%
    drawTextbox x1%, y1%, x2%, y2%, engNumRep$(getTriggerDelay(),4),1,1,1                   'Attach to real value
end if
bcolor = tcolor?
ya% = y%+int(fontH/2)+2
yb% = y%+4+fontH
if initial? = 0 then
    triggerDelayUBut% = SA_addTop(b%-11,y%,b%-3,ya%)
    triggerDelayLBut% = SA_addTop(b%-11,ya%+1,b%-3,yb%)
end if
mouseOn
box b%-11, y%, 8, ya%-y%, RAISED
box b%-11, ya%+1, 8, ya%-y%, RAISED
drawArrow b%-10, y%+1, 6, 0
drawArrow b%-10, ya%+2, 6, 1

'Status bar
box 0, 476-fontH, 640, fontH+4, RAISED
box 1, 477-fontH, 635-statusValWidth, fontH+2, LOWERED
statusBarSet 10,478-fontH,625-statusValWidth
box 638-statusValWidth, 477-fontH, statusValWidth, fontH+2, LOWERED
mouseOff

'Scope and spectrum
drawScope
mode? = mode? + mode_DrawBG
drawSpectrum
view screen
initial? = 1
mouseOn
end sub

'------------------------------------------------------------------------------
sub drawDesktop(byVal x1%, byVal y1%, byVal x2%, byVal y2%)
line(x1%,y1%)-(x2%,y2%), 1, bf
x1% = x1% - x1% mod 4
x2% = x2% - x2% mod 4 - 4
y1% = y1% - y1% mod 4
y2% = y2% - y2% mod 4
for x% = x1% to x2% step 4
    for y% = y1% to y2% step 4
        pset(x%+ y% mod 3, y%), 2
        pset(x%+ y% mod 3+2, y%+2), 3
    next
next
end sub

'Initialize the program
'------------------------------------------------------------------------------
sub initialize
colorSet 0,10,10,10         'Set font palette (light black)
colorSet 1, 20, 25, 37      'Desktop colors
colorSet 2, 18, 23, 33      'Background color
colorSet 3, 22, 27, 40      'Background color
colorSet 4,45,45,40         'Menu background
colorSet 5,25,25,20         'Menu disabled
colorSet 6,30,30,63         'Highlighted background
colorSet 7, 0,40,0          'lines for scope screen color
colorSet 15, 60, 60, 60     'Usually close to white
colorSet 10, 60, 0, 0
colorSet 14, 0, 60, 0
colorSet 8, 32, 32, 20
colorSet 9, 50, 50, 28

fcolor = 0                  'Font color
bcolor = 4                  'Menu Background
dcolor = 5                  'Disabled
hfcolor = 15                'Highlighted font
hbcolor = 6                 'Highlighted background
bgcolor? = 0                'Oscilloscope background color
lcolor? = 7                 'Lines for scope screen color
chAcolor? = 15
chBcolor? = 10
curColor? = 14

loadfont "tahoma10.ft2"     'initialize the fonts
mouseInitialize             'initialize the mouse
setMCursor "Cursora.cur", 5 'set the mouse cursor

SA_initialize               'Set up for the scope
scopeArea% = SA_addTop(20,fontH+48,320,fontH+304)
setScopePosition 20,fontH+48,320,fontH+304
spectArea% = SA_addTop(20, fontH+308, 320, 457-fontH)
setSpectPosition 20,fontH+308,320,457-fontH
mode? = mode_STOP + mode_CHAENABLED + mode_CHBENABLED
reconst? = reconst_TRIANGLE
chAVoltDiv = 5
chBVoltDiv = 5
chAOffset = 0
chBOffset = 0
mode? = mode_RUN + mode_drawBG + mode_CHAENABLED + mode_CHBENABLED
reconst? = reconst_TRIANGLE

'initialize the communications ports
ini_HDriver
timeSample! = 1/getSampleRate()

'Menu bar
menuHeader(0) = "File"
menuHeader(1) = "Configuration"
menuHeader(2) = "Help"
iniMainMenu menuHeader(), menuHeaderButton()

'Button bar
butIconFile(0) = "menubar.ico" : butIconNum(0) = 0 : butEnabled(0) = 255
butIconFile(1) = "menubar.ico" : butIconNum(1) = 1 : butEnabled(1) = 255
butIconFile(2) = "menubar.ico" : butIconNum(2) = 2 : butEnabled(2) = 255
butIconFile(3) = "|" : butIconNum(3) = 0 : butEnabled(3) = 255
butIconFile(4) = "menubar.ico" : butIconNum(4) = 3 : butEnabled(4) = 255
butIconFile(5) = "menubar.ico" : butIconNum(5) = 4 : butEnabled(5) = 255
butIconFile(6) = "menubar.ico" : butIconNum(6) = 5 : butEnabled(6) = 255
butIconFile(7) = "|" : butIconNum(7) = 0 : butEnabled(7) = 255
butIconFile(8) = "menubar.ico" : butIconNum(8) = 6 : butEnabled(8) = 255
butIconFile(9) = "menubar.ico" : butIconNum(9) = 7 : butEnabled(9) = 255
butIconFile(10) = "menubar.ico" : butIconNum(10) = 8 : butEnabled(10) = 255
butIconFile(11) = "menubar.ico" : butIconNum(11) = 9 : butEnabled(11) = 255
butIconFile(12) = "|" : butIconNum(12) = 0 : butEnabled(12) = 255
butIconFile(13) = "menubar.ico" : butIconNum(13) = 10 : butEnabled(13) = 255
butIconFile(14) = "menubar.ico" : butIconNum(14) = 11 : butEnabled(14) = 255
butIconFile(15) = "menubar.ico" : butIconNum(15) = 12 : butEnabled(15) = 255
butIconFile(16) = "menubar.ico" : butIconNum(16) = 13 : butEnabled(16) = 255
butIconFile(17) = "|" : butIconNum(17) = 0 : butEnabled(17) = 255
butIconFile(18) = "menubar.ico" : butIconNum(18) = 14 : butEnabled(18) = 255
butIconFile(19) = "menubar.ico" : butIconNum(19) = 15 : butEnabled(19) = 255
butIconFile(20) = "menubar.ico" : butIconNum(20) = 16 : butEnabled(20) = 255

iniButtonBar 0, fontH+5, 640, butIconFile(), butIconNum(), butEnabled(), butSAArea()

end sub

