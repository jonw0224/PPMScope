;==============================================================================
;*Author:  Jonathan Weaver, jonw0224@netscape.net
;E-mail Contact: jonw0224@netscape.net
;*Description: A set of equality testing macros.  Assumes all registers and literals are signed bytes.
;*Version: 1.0
;*Date: 7/10/2003
;*Filename: equality.inc
;
;Versions:  1.0 - 7/10/2003 -- Code finished.  Added comments.
;			1.0 - 9/29/2005 -- Additional Header comments and license added
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

;================================================================================
; M A C R O S
;================================================================================

;*This macro skips the next line if regA is equal to regB
skipEqFF macro regA,regB ;public
	movf regA, w
	xorwf regB, w
	btfss STATUS, Z
endm

;*This macro skips the next line if regA is greater than or equal to regB
skipGrEqFF macro regA, regB ;public
	movf regB, w
	subwf regA, w
	andlw B'10000000'
	btfss STATUS, Z
endm

;*This macro skips the next line if regA is greater than regB
skipGrFF macro regA, regB ;public
	movf regA, w
	subwf regB, w
	andlw B'10000000'
	btfsc STATUS, Z
endm

;*This macro skips the next line if the literal is equal to regB
skipEqLF macro lit, regB ;public
	movf regB, w
	xorlw lit
	btfss STATUS, Z
endm

;*This macro skips the next line if the literal is greater than or equal to regB
skipGrEqLF macro lit, regB ;public
	movf regB, w
	sublw lit
	andlw B'10000000'
	btfss STATUS, Z
endm

;*This macro skips the next line if the literal is greater than regB
skipGrLF macro lit, regB ;public
	movlw lit
	subwf regB, w
	andlw B'10000000'
	btfsc STATUS, Z
endm

;*This macro skips the next line if the regA is greater than or equal to the literal
skipGrEqFL macro regA, lit ;public
	movlw lit
	subwf regA, w
	andlw B'10000000'
	btfss STATUS, Z
endm

;*This macro skips the next line if the regA is greater than the literal
skipGrFL macro regA, lit ;public
	movf regA, w
	sublw regB
	andlw B'10000000'
	btfsc STATUS, Z
endm

;*This macro skips the next line if the result of the previous line is zero
skipZero macro ;public
	btfss STATUS, Z
endm

;*This macro skips the next line if the result of the previous line is not zero
skipNotZero macro ;public
	btfsc STATUS, Z
endm

;*This macro skips the next line if the result of the previous line is less than zero
skipLessZero macro ;public
	andlw B'10000000'
	btfsc STATUS, Z
endm

;*This macro skips the next line if the result of the previous line is more than or equal to zero
skipMoreEqZero macro ;public
	andlw B'10000000'
	btfss STATUS, Z
endm

;*This macro skips the next line if the result of the previous line is less than or equal to zero
skipLessEqZero macro ;public
	addlw B'01111111'
	andlw B'10000000'
	btfss STATUS, Z
endm

;*This macro skips the next line if the result of the previous line is more than zero
skipMoreZero macro ;public
	addlw B'01111111'
	andlw B'10000000'
	btfsc STATUS, Z
endm
