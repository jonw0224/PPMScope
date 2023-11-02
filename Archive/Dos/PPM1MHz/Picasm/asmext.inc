;==============================================================================
;*Author:  Jonathan Weaver, jonw0224@netscape.net
;E-mail Contact: jonw0224@netscape.net
;*Description:  Extention of assembly instructions on registers and literals.
;*Version: 1.0
;*Date: 11/1/2005
;*Filename: asmext.inc
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
;Versions:  1.0 - 1/5/2005 - Defined headers, began writing macros
;           1.0 - 1/6/2005 - Wrote more macros
;           1.0 - 7/1/2005 - Tested macros, fixed bugs.  Rewrote SHIFTX and ROTX.
;			1.0 - 7/11/2005 - Finished testing macros.  Added comments to headers.
;			1.0 - 11/1/2005 - Wrote VROTF and VSHIFTF macros.
;==============================================================================

f equ F
w equ W

;------------------------------------------------------------------------------
;*Adds regA to regB and stores in WREG or regB.  Affects WREG, STATUS.  2 Instruction Cycles.
;*regA: the register to add to regB
;*regB: the register to add to regA
;*dest: literal equal to F to store in regB, W to store in WREG
ADDFF macro regA, regB, dest	;public
    movf regA, w
    addwf regB, dest
endm

;------------------------------------------------------------------------------
;*Ands regA and regB and stores in WREG or regB.  Affects WREG, STATUS.  2 Instruction Cycles.
;*regA: the register to and with regB
;*regB: the register to and with regA
;*dest: literal equal to F to store in regB, W to store in WREG
ANDFF macro regA, regB, dest	;public
    movf regA, w
    andwf regB, dest
endm

;------------------------------------------------------------------------------
;*Inclusive ors regA and regB and stores in WREG or regB.  Affects WREG, STATUS.  2 Instruction Cycles.
;*regA: the register to or with regB
;*regB: the register to or with regA
;*dest: literal equal to F to store in regB, W to store in WREG
IORFF macro regA, regB, dest	;public
    movf regA, w
    iorwf regB, dest
endm

;------------------------------------------------------------------------------
;*Moves the value in regA to regB.  Affects WREG, STATUS.  2 Instruction Cycles.
;*regA: the register to move to regB
;*regB: the destination register
MOVFF macro regA, regB	;public
    movf regA, w
    movwf regB
endm

;------------------------------------------------------------------------------
;*Shifts the value in reg left by lit and stores in reg.  Affects WREG, STATUS.  2 to 5 Instruction Cycles.
;*reg: the register to shift
;*lit: a literal containing the number of bits to shift left
SHIFTL macro reg, lit	;public
    local cnt
    if (lit) < 4                    ;1 -> 2 cycles, 2 -> 4 cycles, 3 -> 5 cycles
        cnt = lit
        while cnt > 0
            rlf reg, f
            cnt--
        endw
        if (lit) == 1
            bcf reg, 0
        else
            if (lit) == 2 then
            	bcf reg, 0
            	bcf reg, 1
            else
            	movlw (0xFF << (lit))
	            andwf reg, f
	        endif
        endif
    else
        if (lit) < 6
            if (lit) == 4           ;4 -> 3 cycles
                swapf reg, f
                movlw 0xF0
                andwf reg, f
            else                    ;5 -> 4 cycles
                swapf reg, f
                rlf reg, f
                movlw B'11100000'
                andwf reg, f
            endif
        else
            if (lit) == 6           ;6 -> 5 cycles
                rrf reg, f
                rrf reg, f
                rrf reg, f
                movlw B'11000000'
                andwf reg, f
            else                    ;7 -> 3 cycles
                rrf reg, f
                clrf reg
                rrf reg, f
            endif
        endif
    endif
endm

;------------------------------------------------------------------------------
;*Shifts the value in reg right by lit and stores in reg.  Affects WREG, STATUS.  2 to 5 Instruction Cycles.
;*reg: the register to shift
;*lit: a literal containing the number of bits to shift left
SHIFTR macro reg, lit	;public
    local cnt
    if (lit) < 4                    ;1 -> 2 cycles, 2 -> 4 cycles, 3 -> 5 cycles
        cnt = lit
        while cnt > 0
            rrf reg, f
            cnt--
        endw
        if (lit) == 1
            bcf reg, 7
        else
            movlw (0xFF >> (lit))
            andwf reg, f
        endif
    else
        if (lit) < 6
            if (lit) == 4           ;4 -> 3 cycles
                swapf reg, f
                movlw 0x0F
                andwf reg, f
            else                    ;5 -> 4 cycles
                swapf reg, f
                rrf reg, f
                movlw B'00000111'
                andwf reg, f
            endif
        else
            if (lit) == 6           ;6 -> 5 cycles
                rlf reg, f
                rlf reg, f
                rlf reg, f
                movlw B'00000011'
                andwf reg, f
            else                    ;7 -> 3 cycles
                rlf reg, f
                clrf reg
                rlf reg, f
            endif
        endif
    endif
endm

;------------------------------------------------------------------------------
;*Rotates the value in reg left by lit and stores in reg.  Affects WREG, STATUS.  1 to 4 Instruction Cycles.
;*reg: the register to shift
;*lit: a literal containing the number of bits to shift left
ROTL macro reg, lit	;public
    local cnt
    if (lit) < 3                    ;1 -> 2 cycles, 2 -> 4 cycles
        cnt = lit
        while cnt > 0
            rlf reg, w
            rlf reg, f
            cnt--
        endw
    else
        if (lit) < 6
            swapf reg, f            ;4 -> 1 cycles
            if (lit) == 3           ;3 -> 3 cycles
                rrf reg, w
                rrf reg, f
            endif
            if (lit) == 5
                rlf reg, w          ;5 -> 3 cycles
                rlf reg, f
            endif
        else                        ;6 -> 4 cycles, 7 -> 2 cycles
            cnt = 8 - (lit)
            while cnt > 0
                rrf reg, w
                rrf reg, f
                cnt--
            endw
        endif
    endif
endm

;------------------------------------------------------------------------------
;*Rotates the value in reg left by lit and stores in reg.  Affects WREG, STATUS.  1 to 4 Instruction Cycles.
;*reg: the register to shift
;*lit: a literal containing the number of bits to shift left
ROTR macro reg, lit	;public
    ROTL reg, 8-lit
endm

;------------------------------------------------------------------------------
;*Shifts regA left by regB.  Requires 13 program words and 13 cycles.  Affects WREG and STATUS.
;*regA: register to shift
;*regB: register that determines shift (7 to 0 are valid)
VSHIFTL macro regA, regB ;public
    bcf STATUS, C   ;Conditional shift by 1
    btfsc regB, 0
        rlf regA, f
    bcf STATUS, C   ;Conditional shift by 2
    btfsc regB, 1
        rlf regA, f
    bcf STATUS, C
    btfsc regB, 1
        rlf regA, f
    swapf regA, w      ;Conditional shift by 4
    andlw 0xF0
    btfsc regB, 2
        movwf regA
endm

;------------------------------------------------------------------------------
;*Shifts regA right by regB.  Requires 13 program words and 13 cycles.  Affects WREG and STATUS.
;*regA: register to shift
;*regB: register that determines shift (7 to 0 are valid)
VSHIFTR macro regA, regB ;public
    bcf STATUS, C   ;Conditional shift by 1
    btfsc regB, 0
        rrf regA, f
    bcf STATUS, C   ;Conditional shift by 2
    btfsc regB, 1
        rrf regA, f
    bcf STATUS, C
    btfsc regB, 1
        rrf regA, f
    swapf regA, w      ;Conditional shift by 4
    andlw 0x0F
    btfsc regB, 2
        movwf regA
endm

;------------------------------------------------------------------------------
;*Rotates regA left by regB.  Requires 11 program words and 11 cycles.  Affects WREG and STATUS.
;*regA: register to rotate
;*regB: register that determines rotate (7 to 0 are valid)
VROTL macro regA, regB ;public
    rlf regA, w        ;Conditional rotate by 1
    btfsc regB, 0
        rlf regA, f
    rlf regA, w        ;Conditional rotate by 2
    btfsc regB, 1
        rlf regA, f
    rlf regA, w
    btfsc regB, 1
        rlf regA, f
    btfsc regB, 2      ;Conditional rotate by 4
        swapf regA, f
endm

;------------------------------------------------------------------------------
;*Rotates regA right by regB.  Requires 11 program words and 11 cycles.  Affects WREG and STATUS.
;*regA: register to rotate
;*regB: register that determines rotate (7 to 0 are valid)
VROTR macro regA, regB ;public
    rrf regA, w        ;Conditional rotate by 1
    btfsc regB, 0
        rrf regA, f
    rrf regA, w        ;Conditional rotate by 2
    btfsc regB, 1
        rrf regA, f
    rrf regA, w
    btfsc regB, 1
        rrf regA, f
    btfsc regB, 2      ;Conditional rotate by 4
        swapf regA, f
endm

;------------------------------------------------------------------------------
;*Subracts regA from regB and stores in WREG or regB.  Affects STATUS, WREG.  2 Instruction Cycles.
;*regA: the register to subtract
;*regB: the register to subtract from
;*dest: literal equal to F to store in regB, W to store in WREG
SUBFF macro regA, regB, dest	;public
    movf regA, w
    subwf regB, dest
endm

;------------------------------------------------------------------------------
;*Exclusive ors regA and regB and stores in WREG or regB.  Affects STATUS, WREG.  2 Instruction Cycles.
;*regA: the register to exclusive or with regB
;*regB: the register to exclusive or with regA
;*dest: literal equal to F to store in regB, W to store in WREG
XORFF macro regA, regB, dest	;public
    movf regA, w
    xorwf regB, dest
endm

;------------------------------------------------------------------------------
;*Adds lit and reg and stores in WREG or reg.  Affects STATUS, WREG.  2 Instruction Cycles.
;*lit: the literal to add with reg
;*reg: the register to add with lit
;*dest: literal equal to F to store in reg, W to store in WREG
ADDLF macro lit, reg, dest	;public
    movlw lit
    addwf reg, dest
endm

;------------------------------------------------------------------------------
;*Ands lit and reg and stores in WREG or reg.  Affects WREG, STATUS.  2 Instruction Cycles.
;*lit: literal to and with reg
;*reg: register to and with lit
;*dest: literal equal to F to store in reg, W to store in WREG
ANDLF macro lit, reg, dest	;public
    movlw lit
    andwf reg, dest
endm

;------------------------------------------------------------------------------
;*Inclusive ors lit and reg and stores in WREG or reg.  Affects WREG, STATUS.  2 Instruction Cycles.
;*lit: literal to inclusive or with reg
;*reg: register to inclusive or with lit
;*dest: literal equal to F to store in reg, W to store in WREG
IORLF macro lit, reg, dest	;public
    movlw lit
    iorwf reg, dest
endm

;------------------------------------------------------------------------------
;*Moves lit to reg.  Affects WREG.  2 Instruction Cycles.
;*lit: literal to move
;*reg: register to move literal to
MOVLF macro lit, reg	;public
    movlw lit
    movwf reg
endm

;------------------------------------------------------------------------------
;*Subtracts reg from lit and stores in WREG or reg.  Affects WREG, STATUS.  2 to 3 Instruction Cycles.
;*lit: literal to subtract from
;*reg: register to subtract from literal
;*dest: literal equal to F to store in reg, W to store in WREG
SUBLF macro lit, reg, dest	;public
    movf reg, w
    sublw lit
    if dest == 1
        movwf reg
    endif
endm

;------------------------------------------------------------------------------
;*Exclusive ors lit and reg and stores in WREG or reg.  Affects WREG, STATUS.  2 Instruction Cycles.
;*lit: literal to exclusive or with reg
;*reg: register to exclusive or with literal
;*dest: literal equal to F to store in reg, W to store in WREG
XORLF macro lit, reg, dest	;public
    movlw lit
    xorwf reg, dest
endm

;------------------------------------------------------------------------------
;*Negates reg and stores in WREG or reg.  Affects STATUS.  2 Instruction Cycles.
;*reg: register to negate (result is 0 - register)
;*dest: literal equal to F to store in reg, W to store in WREG
NEGATEF macro reg, dest	;public
    if dest == 1
        comf reg, f
        incf reg, f
    else
        movf reg, w
        sublw 0x00      ;WREG = 0 - reg
    endif
endm

;------------------------------------------------------------------------------
;*Sets WREG equal to reg and reg equal to WREG.  Affects STATUS.  2 Instruction Cycles.
;*reg: the register to swap with WREG
SWAPWF macro reg	;public
    xorwf reg, f        ;reg = reg xor WREG
    xorwf reg, w        ;WREG = reg xor WREG xor WREG = reg
    xorwf reg, f        ;reg = reg xor WREG xor reg = WREG
endm

;------------------------------------------------------------------------------
;*Sets regA equal to regB and regB equal to regA.  Affects STATUS, WREG.  4 Instruction Cycles.
;*regA: register to move to regB
;*regB: register to move to regA
SWAPFF macro regA, regB	;public
    movf regA, w
    xorwf regB, w       ;WREG = regA xor regB
    xorwf regA, f       ;regA = regA xor regB xor regA = regB
    xorwf regB, f       ;regB = regB xor regA xor regB = regA
endm

;------------------------------------------------------------------------------
;*Adds regA to regB and stores in regB, but preserves WREG.  Affects STATUS.  5 Instruction Cycles.
;*regA: register to add to regB
;*regB: register to add to regA
ADDFF_TW macro regA, regB	;public
    xorwf regA, f       ;regA = regA xor WREG
    xorwf regA, w       ;WREG = WREG xor regA xor WREG = regA
    addwf regB, f       ;regB = regB - regA
    xorwf regA, w       ;WREG = regA xor regA xor WREG = WREG
    xorwf regA, f       ;regA = regA xor WREG xor WREG = regA
endm

;------------------------------------------------------------------------------
;*Ands regA and regB and stores in regB, but preserves WREG.  Affects STATUS.  5 Instruction Cycles.
;*regA: register to and with regB
;*regB: register to and with regA
ANDFF_TW macro regA, regB	;public
    xorwf regA, f       ;regA = regA xor WREG
    xorwf regA, w       ;WREG = WREG xor regA xor WREG = regA
    andwf regB, f       ;regB = regB and regA
    xorwf regA, w       ;WREG = regA xor regA xor WREG = WREG
    xorwf regA, f       ;regA = regA xor WREG xor WREG = regA
endm

;------------------------------------------------------------------------------
;*Inclusive ors regA and regB and stores in regB, but preserves WREG.  Affects STATUS.  5 Instruction Cycles.
;*regA: register to inclusive or with regB
;*regB: register to inclusive or with regA
IORFF_TW macro regA, regB	;public
    xorwf regA, f       ;regA = regA xor WREG
    xorwf regA, w       ;WREG = WREG xor regA xor WREG = regA
    iorwf regB, f       ;regB = regB or regA
    xorwf regA, w       ;WREG = regA xor regA xor WREG = WREG
    xorwf regA, f       ;regA = regA xor WREG xor WREG = regA
endm

;------------------------------------------------------------------------------
;*Moves the value in regA to regB, but preserves WREG.  Affects STATUS.  4 Instruction Cycles.
;*regA: register to move to regB
;*regB: destination register
MOVFF_TW macro regA, regB	;public
    xorwf regA, w
    movwf regB          ;regB = regA xor WREG
    xorwf regA, w       ;WREG = regA xor WREG xor regA = WREG
    xorwf regB, f       ;regB = regA xor WREG xor WREG = regA
endm

;------------------------------------------------------------------------------
;*Subracts regA from regB and stores in regB, but preserves WREG.  Affects STATUS.  5 Instruction Cycles.
;*regA: register to subtract from regB
;*regB: register regA is subtracted from and the destination register
SUBFF_TW macro regA, regB	;public
    xorwf regA, f       ;regA = regA xor WREG
    xorwf regA, w       ;WREG = WREG xor regA xor WREG = regA
    subwf regB, f       ;regB = regB - regA
    xorwf regA, w       ;WREG = regA xor regA xor WREG = WREG
    xorwf regA, f       ;regA = regA xor WREG xor WREG = regA
endm

;------------------------------------------------------------------------------
;*Exclusive ors regA and regB and stores in regB, but preserves WREG.  Affects STATUS.  5 Instruction Cycles.
;*regA: register to exclusive or with regB
;*regB: register to exclusive or with regA
XORFF_TW macro regA, regB	;public
    xorwf regB, f       ;regB = WREG xor regB
    xorwf regA, w       ;WREG = WREG xor regA
    xorwf regB, f       ;regB = WREG xor regB xor WREG xor regA = regA xor regB
    xorwf regA, w       ;WREG = WREG xor regA xor regA = WREG
endm

;------------------------------------------------------------------------------
;*Adds lit and reg and stores in reg, but preserves WREG.  Affects STATUS.  4 Instruction Cycles.
;*lit: literal to add to reg
;*reg: register which to add literal
ADDLF_TW macro lit, reg	;public
    subwf reg, f        ;reg = reg - WREG
    addlw lit           ;WREG = WREG + lit
    addwf reg, f        ;reg = reg - WREG + WREG + lit = reg + lit
    addlw 0-lit         ;WREG = WREG - lit
endm

;------------------------------------------------------------------------------
;*Ands lit and reg and stores in reg, but preserves WREG.  Affect STATUS.  7 Instruction Cycles.
;*lit: literal to and with reg
;*reg: register which to and with literal
ANDLF_TW macro lit, reg	;public
    SWAPWF reg
    andlw lit           ;WREG = reg and lit
    SWAPWF reg
endm

;------------------------------------------------------------------------------
;*Inclusive ors lit and reg and stores in reg, but preserves WREG.  Affects STATUS.  7 Instruction Cycles.
;*lit: literal to inclusive or with reg
;*reg: register which to inclusive or with literal
IORLF_TW macro lit, reg	;public
    SWAPWF reg
    iorlw lit           ;WREG = reg or lit
    SWAPWF reg
endm

;------------------------------------------------------------------------------
;*Moves lit to reg, but preserves WREG.  Affects STATUS.  4 instruction cycles.
;*lit: literal to move
;*reg: register to move literal to
MOVLF_TW macro lit, reg	;public
    movwf reg           ;reg = WREG
    xorlw lit           ;WREG = WREG xor lit
    xorwf reg, f        ;reg = WREG xor WREG xor lit = lit
    xorlw lit           ;WREG = WREG xor lit xor lit
endm

;------------------------------------------------------------------------------
;*Subtracts reg from lit and stores in reg, but preserves WREG.  Affects STATUS.  6 Instruction Cycles.
;*lit: literal to subtract reg from
;*reg: register to subtract from lit and destination register
SUBLF_TW macro lit, reg	;public
    subwf reg, f        ;reg = reg - WREG
    addlw 0-lit         ;WREG = WREG - lit
    addwf reg, f        ;reg = reg - WREG + WREG - lit = reg - lit
    addlw lit           ;WREG = WREG - lit + lit = WREG
    NEGATEF reg, f      ;Negate reg, 2 cycles
endm

;------------------------------------------------------------------------------
;*Exclusive ors lit and reg and stores in reg, but preserves WREG.  Affects STATUS.  4 Instruction Cycles.
;*lit: literal to exclusive or reg with
;*reg: register to exclusive or with lit and destination register
XORLF_TW macro lit, reg	;public
    xorwf reg, f        ;reg = reg xor WREG
    xorlw lit           ;WREG = WREG xor lit
    xorwf reg, f        ;reg = reg xor WREG xor WREG xor lit = reg xor lit
    xorlw lit           ;WREG = WREG xor lit xor lit = WREG
endm

;------------------------------------------------------------------------------
;*Sets regA equal to regB and regB equal to regA, but preserves WREG.  Affects STATUS.  8 Instruction Cycles.
;*regA: register to move regB to
;*regB: register to more regA to
SWAPFF_TW macro regA, regB	;public
    xorwf regA, f       ;regA = regA xor WREG
    xorwf regB, f       ;regB = regB xor WREG
    xorwf regA, w       ;WREG = WREG xor regA xor WREG = regA
    xorwf regB, w       ;WREG = regA xor WREG xor regB
    xorwf regA, f       ;regA = WREG xor regA xor regB xor regA xor WREG = regB
    xorwf regB, f       ;regB = WREG xor regA xor regB xor regB xor WREG = regA
    xorwf regA, w       ;WREG = WREG xor regA xor regB xor regA = WREG xor regB
    xorwf regB, w       ;WREG = WREG xor regB xor regB = WREG
endm

;------------------------------------------------------------------------------
;*Adds WREG to the Program Counter.  Usually used to lookup a value in a table of retlw between labels TableStart and TableEnd.  1 to 6 Instruction Cycles.
;*TableStart:  starting address in program memory of the table, should be immediately following call to ADDWPC
;*TableEnd:  ending address in program memory of the table.  For support if table crosses a page boundary (gives warning).
ADDWPC macro TableStart, TableEnd	;public
    if (high TableStart)
        movlw high TableStart
        movwf PCLATH
    endif
    if (high TableStart) == (high TableEnd)
        addwf PCL, f
    else
        messg "Table crosses page boundary"
        addwf PCL, w
        btfss STATUS, C
            incf PCLATH, f
        movwf PCL
    endif
endm


