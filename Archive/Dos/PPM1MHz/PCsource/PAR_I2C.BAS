'==============================================================================
'*Author:  Jonathan Weaver
'*Date:    created 11/17/03.
'*Version:  1.0 build #1.
'*Filename:  par_i2c.bas
'*Description:  simulate i2c protocol on a parallel port
'
'Copyright (C) 2003 Jonathan Weaver
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
'==============================================================================

'==============================================================================
' C O M P I L E R   D I R E C T I V E S
'==============================================================================

$Dynamic
$cpu 80386
$lib all off
$optimize speed
$compile unit "par_i2c.pbu"

'==============================================================================
' E X T E R N A L   D E C L A R A T I O N S
'==============================================================================

'*Subroutine used from parallel.pbu.  Sets a bit on the parallel port.
declare sub setBit(portNo%, byteNo%, bitNo%, v?)

'*Function used from parallel.pbu.  Gets a bit from the parallel port.
declare function getBit(portNo%, byteNo%, bitNo%)


dim WTA as integer, WTB as integer
dim LPTPORT as integer, CLK as integer, SDA as integer, SDAIN as integer
dim CLKCONTROL as integer, SDACONTROL as integer, SDAINCONTROL as integer
dim CLKSET as byte, CLKRESET as byte, SDASET as byte, SDARESET as byte
dim SDAINSET as byte, SDAINRESET as byte

'*Integers to determine timing
external WTA, WTB

'*Integers to specify port, clock bit, data out bit, and data in bit
external LPTPORT, CLK, SDA, SDAIN

'*Integers to specify the control byte for the clock, data out, and data in
external CLKCONTROL, SDACONTROL, SDAINCONTROL

'*Integers to specify the polarity for data out, clock, and data in
external SDASET, SDARESET, CLKRESET, CLKSET, SDAINSET, SDAINRESET

'==============================================================================
' S H A R E D   D E C L A R A T I O N S
'==============================================================================

'===================================================================================
' B U I L D   F U N C T I O N
'===================================================================================

'*Returns the build and version number of this unit library
'*RETURN: the number of the build
function verPar_i2c$() public
verParallel$ = "Parallel Port I2C Unit version 1.0 build #1"
end function

'==============================================================================
' P U B L I C   S U B R O U T I N E S / F U N C T I O N S
'==============================================================================

'*Releases the bus by pulling SDA and CLK high
sub releaseBus public
setBit LPTPORT, SDACONTROL, SDA, SDASET
setBit LPTPORT, CLKCONTROL, CLK, CLKSET
end sub

'*Sends a start signal to the slave device
sub sendStart public
setBit LPTPORT, SDACONTROL, SDA, SDASET
setBit LPTPORT, CLKCONTROL, CLK, CLKSET
setBit LPTPORT, SDACONTROL, SDA, SDARESET
setBit LPTPORT, CLKCONTROL, CLK, CLKRESET
end sub

'*Sends a stop signal to the slave device
sub sendStop public
setBit LPTPORT, CLKCONTROL, CLK, CLKRESET
setBit LPTPORT, SDACONTROL, SDA, SDARESET
setBit LPTPORT, CLKCONTROL, CLK, CLKSET
releaseBus
end sub

'*Send a zero to the device
sub sendZero public
setBit LPTPORT, SDACONTROL, SDA, SDARESET
setBit LPTPORT, CLKCONTROL, CLK, CLKSET
setBit LPTPORT, CLKCONTROL, CLK, CLKRESET
end sub

'*Send a one to the device
sub sendOne public
setBit LPTPORT, SDACONTROL, SDA, SDASET
setBit LPTPORT, CLKCONTROL, CLK, CLKSET
setBit LPTPORT, CLKCONTROL, CLK, CLKRESET
end sub

'*Sends a byte to the slave device
'*Returns:  1 if slave device acknowledges, 0 if slave device does not.
function sendByte(theByte?) public
for i% = 0 to 7
    waitTime
    if int(theByte? / 128) = 0 then
        sendZero
    else
        sendOne
    end if
    rotate left theByte?, 1
next
waitTime
setBit LPTPORT, SDACONTROL, SDA, SDASET
setBit LPTPORT, CLKCONTROL, CLK, CLKSET
a? = getBit(LPTPORT, SDAINCONTROL, SDAIN)
if SDAINSET = 1 then
    bit toggle a?, 0
end if
sendByte = a?   
setBit LPTPORT, CLKCONTROL, CLK, CLKRESET
end function

'*Recieves a byte.  Send an acknowlege if appropriate
'*ack?:  TRUE indicates send acknowledge, FALSE indicates don't send acknowledge
'*returns: the byte recieved
function recieveByte?(ack?) public
setBit LPTPORT, SDACONTROL, SDA, SDASET
setBit LPTPORT, CLKCONTROL, CLK, CLKRESET
buildByte? = 0
for i% = 0 to 7
    setBit LPTPORT, CLKCONTROL, CLK, CLKSET
    waitTime
    buildByte? = buildByte?*2+getBit(LPTPORT, SDAINCONTROL, SDAIN)
    setBit LPTPORT, CLKCONTROL, CLK, CLKRESET
next
if SDAINSET = 0 then
    recieveByte = not(buildByte?)
else
    recieveByte = buildByte?
end if
if ack? then
    setBit LPTPORT, SDACONTROL, SDA, SDARESET
    setBit LPTPORT, CLKCONTROL, CLK, CLKSET
    setBit LPTPORT, CLKCONTROL, CLK, CLKRESET
else
    setBit LPTPORT, SDACONTROL, SDA, SDASET
    setBit LPTPORT, CLKCONTROL, CLK, CLKSET
    setBit LPTPORT, CLKCONTROL, CLK, CLKRESET
end if
end function

'*Waits an amount of time specified by WTA and WTB
sub waitTime public
for i% = 0 to WTA
    for j% = 0 to WTB
    next
next
end sub

'==============================================================================
' P R I V A T E   S U B R O U T I N E S / F U N C T I O N S
'==============================================================================

