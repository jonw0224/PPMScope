'===========================================================================
'*Author:  Jonathan Weaver
'*Date:    created 10/4/2004
'*Version:  1.0, build #1
'*Filename:  numbers.bas
'*Description:  Contains number formatting functions
'
'Copyright (C) 2004 Jonathan Weaver
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
'===========================================================================

'===========================================================================
' C O M P I L E R   D I R E C T I V E S
'===========================================================================

$optimize speed
$cpu 80386
$compile unit "numbers.pbu"
$lib all off

'===================================================================================
' B U I L D   F U N C T I O N
'===================================================================================

'*Returns the build and version number of this unit library
'*RETURN: the number of the build
function verNumbers$() public
verLogic$ = "Number formatting functions Ver 1.0, build #1, 10/4/2004:  number.pbu"
end function

'===========================================================================
' P U B L I C   S U B R O U T I N E S   /   F U N C T I O N S
'===========================================================================


'*Returns the english representation of a number with appropriate magnitude designation (M,k,m,u,n)
'*number!:  the number to represent
'*sigDig%:  the significant digits to display
'*RETURN:  a string containing the representation of the number
function engNumRep$(number!, sigDig%) public
num! = abs(number!)
if num! >= 10^15 then                   'Use scientific notation
    retStr$ = str$(number!,sigDig%)
elseif num! >= 10^12 then               'Units in Terra
    mant! = number!/10^12
    retStr$ = str$(mant!,sigDig%)+"T"
elseif num! >= 10^9 then                'Units in Giga
    mant! = number!/10^9
    retStr$ = str$(mant!,sigDig%)+"G"
elseif num! >= 10^6 then                'Units in Mega
    mant! = number!/10^6
    retStr$ = str$(mant!,sigDig%)+"M"
elseif num! >= 10^3 then                'Units in kilo
    mant! = number!/10^3
    retStr$ = str$(mant!,sigDig%)+"k"
elseif num! >= 1 then                   'Use regular notation
    retStr$ = str$(number!,sigDig%)
elseif num! >= 10^-3 then               'Units in milli
    mant! = number!/10^-3
    retStr$ = str$(mant!,sigDig%)+"m"
elseif num! >= 10^-6 then               'Units in micro
    mant! = number!/10^-6
    retStr$ = str$(mant!,sigDig%)+"u"
elseif num! >= 10^-9 then               'Units in nano
    mant! = number!/10^-9
    retStr$ = str$(mant!,sigDig%)+"n"
elseif num! >= 10^-12 then              'Units in pico
    mant! = number!/10^-12
    retStr$ = str$(mant!,sigDig%)+"p"
elseif num! >= 10^-15 then              'Units in fempta
    mant! = number!/10^-15
    retStr$ = str$(mant!,sigDig%)+"f"
else                                    'Use scientific notation
    retStr$ = str$(number!,sigDig%)
end if
engNumRep$ = ltrim$(rtrim$(retStr$))
end function

function fromEngNumRep!(byVal numstr$) public
numstr$ = ltrim$(rtrim$(numstr$))
a$ = right$(numstr$,1)
select case a$
case "t", "T"
    toRet! = val(left$(numstr$, len(numstr$)-1))*10^12
case "G", "g"
    toRet! = val(left$(numstr$, len(numstr$)-1))*10^9
case "M"
    toRet! = val(left$(numstr$, len(numstr$)-1))*10^6
case "k", "K"
    toRet! = val(left$(numstr$, len(numstr$)-1))*10^3
case "m"
    toRet! = val(left$(numstr$, len(numstr$)-1))*10^-3
case "u", "U"
    toRet! = val(left$(numstr$, len(numstr$)-1))*10^-6
case "n", "N"
    toRet! = val(left$(numstr$, len(numstr$)-1))*10^-9
case "p", "P"
    toRet! = val(left$(numstr$, len(numstr$)-1))*10^-12
case "f", "F"
    toRet! = val(left$(numstr$, len(numstr$)-1))*10^-15
case else
    toRet! = val(numstr$)
end select
fromEngNumRep = toRet!
end function