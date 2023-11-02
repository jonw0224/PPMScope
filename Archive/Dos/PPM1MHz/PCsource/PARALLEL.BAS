'==============================================================================
'*Author:  Jonathan Weaver
'*Date:    created 7/13/01.  Build #2 11/17/03.
'*Version:  1.0 build #2.  Added comments and pinMap
'*Filename:  parallel.bas
'*Description:  a set of subroutines designed to help interface with parallel ports
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
$compile unit "parallel.pbu"

'==============================================================================
' E X T E R N A L   D E C L A R A T I O N S
'==============================================================================

'==============================================================================
' S H A R E D   D E C L A R A T I O N S
'==============================================================================

dim static pp(2) as shared word

'===================================================================================
' B U I L D   F U N C T I O N
'===================================================================================

'*Returns the build and version number of this unit library
'*RETURN: the number of the build
function verParallel$() public
verParallel$ = "Parallel Port Interface Unit version 1.0 build #2"
end function

'==============================================================================
' P U B L I C   S U B R O U T I N E S / F U N C T I O N S
'==============================================================================

'*Set the bit to the value in v?
'*portNo%: the port number.  0=LPT1, 1=LPT2, 2=LPT3
'*byteNo%: specifies control byte, data byte, or status byte
'*bitNo%: specifies the bit in the byte
'*v?: the value of the bit, 0 to reset, 1 to set, or 2 to toggle
sub setBit(portNo%, byteNo%, bitNo%, v?) public
addr = pp(portNo%) + byteNo%
theByte? = inp(addr)
select case v?
case 0
bit reset theByte?, bitNo%
case 1
bit set theByte?, bitNo%
case 2
bit toggle theByte?, bitNo%
end select
out addr, theByte?
end sub

'*Return the value of a bit
'*portNo%: the port number.  0=LPT1, 1=LPT2, 2=LPT3
'*byteNo%: specifies control byte, data byte, or status byte
'*bitNo%: specifies the bit in the byte
'*v?: the value of the bit, 0 or 1
'*RETURN: the value of the bit on the port
function getBit(portNo%, byteNo%, bitNo%) public
theByte? = getByte(portNo%, byteNo%)
getBit = bit(theByte?, bitNo%)
end function

'*Returns the value used by setBit() to reset a bit (0)
function BITRESET public
BITRESET = 0
end function

'*Returns the value used by setBit() to set a bit (1)
function BITSET public
BITSET = 1
end function

'*Returns the value used by setBit() to toggle a bit (2)
function BITTOGGLE public
BITTOGGLE = 2
end function

'*Set the port byte to the value in byt?
'*portNo%: the port number.  0=LPT1, 1=LPT2, 2=LPT3
'*byteNo%: specifies control byte, data byte, or status byte
'*byt?: the value of the byte
sub setByte(portNo%, byteNo%, byt?) public
addr = pp(portNo%) + byteNo%
out addr, byt?
end sub

'*Return the port byte
'*portNo%: the port number.  0=LPT1, 1=LPT2, 2=LPT3
'*byteNo%: specifies control byte, data byte, or status byte
'*RETURN: the value of the byte
function getByte(portNo%, byteNo%) public
addr = pp(portNo%) + byteNo%
getByte = inp(addr)
end function

'*Returns the CONTROLPORT byte (2) used byt setBit(), getBit(), setByte(), and getByte()
function CONTROLPORT public
CONTROLPORT = 2
end function

'*Returns the DATAPORT byte (0) used byt setBit(), getBit(), setByte(), and getByte()
function DATAPORT public
DATAPORT = 0
end function

'*Returns the STATUSPORT byte (1) used byt setBit(), getBit(), setByte(), and getByte()
function STATUSPORT public
STATUSPORT = 1
end function

'*Tests if the port is valid
'*portNo%: the port number.  0=LPT1, 1=LPT2, 2=LPT3
'*RETURN:  TRUE if valid, FALSE otherwise
function isPortValid?(portNo%) public
if pp(portNo%) = 0 then
toRet? = 0  'Set to FALSE
else
toRet? = -1 'Set to TRUE
end if
isPortValid = toRet?
end function

'*Stores the addresses for the parallel ports from BIOS to be referred to by portNo%
sub setPortBases() public
def seg = 0
pp(0) = peeki(1032) 'get address for LPT1 from BIOS
pp(1) = peeki(1034) 'get address for LPT2 from BIOS
pp(2) = peeki(1036) 'get address for LPT3 from BIOS
def seg
end sub

'*Defines a map from physical pin to port byte
'*pinNo%: the number of the pin to map
'*portByte%: returned value.  DATAPORT, STATUSPORT, or CONTROLPORT
'*portbit%: returned value.  Bit in the port byte.
'*setVal?: the logic corresponding to a +5 voltage or high Z output on the pin
'*resetVal?: the logic corresponding to a 0 voltage output on the pin
sub pinMap(byVal pinNo%, portByte%, portbit%, setVal?, resetVal?) public
setVal? = BITSET
resetVal? = BITRESET
select case pinNo%
case 1
    setVal? = BITRESET
    resetVal? = BITSET
    portByte% = CONTROLPORT
    portBit% = 0
case 2
    portByte% = DATAPORT
    portBit% = 0
case 3
    portByte% = DATAPORT
    portBit% = 1
case 4
    portByte% = DATAPORT
    portBit% = 2
case 5
    portByte% = DATAPORT
    portBit% = 3
case 6
    portByte% = DATAPORT
    portBit% = 4
case 7
    portByte% = DATAPORT
    portBit% = 5
case 8
    portByte% = DATAPORT
    portBit% = 6
case 9
    portByte% = DATAPORT
    portBit% = 7
case 10
    portByte% = STATUSPORT
    portBit% = 6
case 11
    setVal? = BITRESET
    resetVal? = BITSET
    portByte% = STATUSPORT
    portBit% = 7
case 12
    portByte% = STATUSPORT
    portBit% = 5
case 13
    portByte% = STATUSPORT
    portBit% = 4
case 14
    setVal? = BITRESET
    resetVal? = BITSET
    portByte% = CONTROLPORT
    portBit% = 1
case 15
    portByte% = STATUSPORT
    portBit% = 3
case 16
    portByte% = CONTROLPORT
    portBit% = 2
case 17
    setVal? = BITRESET
    resetVal? = BITSET
    portByte% = CONTROLPORT
    portBit% = 3
end select
end sub

'==============================================================================
' P R I V A T E   S U B R O U T I N E S / F U N C T I O N S
'==============================================================================

