;==============================================================================
;*Author:  Jonathan Weaver, jonw0224@netscape.net
;E-mail Contact: jonw0224@netscape.net
;*Description:  Banking macro.  A replacement for the banksel command.  Uses minimal bit set/clear commands to set desired bank.
;*Version: 2.0
;*Date: 11/9/2005
;*Filename:  banks.inc
;
;Versions:  1.0 - 7/10/2003 - Created Unit
;			1.0 - 9/29/2005 - Added comments and license
;			2.0 - 11/9/2005 - Complete change in file, generalized for
;							  different processor banking, selects bank based
;							  on label passed to BNKSEL function.
;							  Removed BANK0 and BANK1 macros (for flexibility)
;
;Copyright (C) 2005 Jonathan Weaver
;
;This program is free software; you can redistribute it and/or modify it under
;the terms of the GNU General Public License as published by the Free Software
;Foundation; either version 2 of the License, or (at your option) any later
;version.
;
;This program is distributed in the hope that it will be useful, but WITHOUT
;ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
;FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
;details.
;
;You should have received a copy of the GNU General Public License along with
;this program; if not, write to the Free Software Foundation, Inc.,
;51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
;
;==============================================================================

variable CURRENTBANK
CURRENTBANK set 0x0000


;*Sets the STATUS bits RP0 and RP1 correctly depending on the label passed.  Comparable to banksel command, except that it remembers the last bank selected in a variable named CURRENTBANK.  Based on CURRENTBANK and label, it will execute only necessary bsf, bcf commands.  1 to 2 program words and cycles.
;*reg: the register whose bank to select
BNKSEL macro reg ;public
	if reg & 0x0100
		if (CURRENTBANK & 0x0100) == 0
			bsf STATUS, RP1
		endif
	else
		if (CURRENTBANK & 0x0100) == 0x0100
			bcf STATUS, RP1
		endif
	endif
	if reg & 0x0080
		if (CURRENTBANK & 0x0080) == 0
			bsf STATUS, RP0
		endif
	else
		if (CURRENTBANK & 0x0080) == 0x0080
			bcf STATUS, RP0
		endif
	endif
	CURRENTBANK set reg & 0x180
endm


