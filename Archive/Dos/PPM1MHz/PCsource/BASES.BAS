'*Author:  Jonathan Weaver
'*Date:    1/28/2003
'*Version: 1.0 build #1
'*Filename:  bases.bas
'*Description:  A collection of base conversion routines

'===================================================================================
' C O M P I L E R   D I R E C T I V E S
'===================================================================================

$compile unit "bases.pbu"

'===================================================================================
' B U I L D   F U N C T I O N
'===================================================================================

'*Returns the build and version number of this unit library
'*RETURN: the number of the build
function verBases$() public
verBases$ = "Bases conversion Ver 1.0, build #1:  bases.pbu"
end function

'===================================================================================
' S U B R O U T I N E S   A N D   F U N C T I O N S
'===================================================================================

'*Returns the value of a hexidecimal string
'*hexStr$:  a string of length 2 (a hexadecimal byte)
'*RETURN:  the value of hexStr$ as a byte
function fromHex?(byval hexStr$) public
hexStr$ = lcase$(hexStr$)
fromHex = 16*fromHexHelper?(left$(hexStr$,1))+fromHexHelper?(right$(hexStr$,1))
end function

'Helps fromHex? function
function fromHexHelper?(byVal hexChar$)
select case hexChar$
case "a"
	constB? = 10
case "b"
	constB? = 11
case "c"
	constB? = 12
case "d"
	constB? = 13
case "e"
	constB? = 14
case "f"
	constB? = 15
case else
	constB? = val(hexChar$)
end select
fromHexHelper = constB?
end function

'*Returns the value of a binary string
'*binStr$:  an eight character string of 1's and 0's representing a byte
'*RETURN:  the byte represented by binStr$
function fromBinary?(byval binStr$) public
constB? = 0
for i% = 1 to 8
	shift left constB?, 1
	char$ = mid$(binStr$,i%,1)
	if char$ = "1" then
		constB? = constB? + 1
	end if
next
fromBinary = constB?
end function