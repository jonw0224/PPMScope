'===========================================================================
'*Author:  Jonathan Weaver
'*Date:    created 7/5/2001
'*Version:  1.0, build #1
'*Filename:  logic.bas
'*Description:  Contains some common logic functions.
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
'===========================================================================

'===========================================================================
' C O M P I L E R   D I R E C T I V E S 
'===========================================================================

$optimize speed
$cpu 80386
$compile unit "logic.pbu"
$lib all off

'===================================================================================
' B U I L D   F U N C T I O N
'===================================================================================

'*Returns the build and version number of this unit library
'*RETURN: the number of the build
function verLogic$() public
verLogic$ = "Logical functions Ver 1.0, build #1:  logic.pbu"
end function

'===========================================================================
' P U B L I C   S U B R O U T I N E S   /   F U N C T I O N S  
'===========================================================================

'*Returns a value (255) which is treated as TRUE
'*returns: true
function TRUE() public
TRUE = 255
end function

'*Returns a value (0) which is treated as FALSE
'*returns: false
function FALSE() public
FALSE = 0
end function
