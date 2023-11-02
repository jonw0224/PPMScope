;==============================================================================
;*Author:  Jonathan Weaver, jonw0224@aim.com
;E-mail Contact: jonw0224@aim.com
;*Description: Software immulated I2C Slave Device.  I2CPort sets I/O port for I2C.  CLK sets clock pin.  SDA sets data pin.
;*Version: 1.0
;*Date: 10/28/2009
;*Filename: i2cs.inc
;
;Program Words:	78
;Data Words:	 2
;
;Versions:  1.0 - 12/29/2002 -- Code finished, tested, and cleaned.
;			1.0 - 07/10/2003 -- Made code portable with external constants.
;			1.0 - 9/29/2005 -- Additional Header comments and license added
;			1.0 - 10/28/2009 -- Fixed bug so that code will work with interrupts
;
;Copyright (C) 2002-2009 Jonathan Weaver
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

;;;;;; External Constants ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;*CLK is a literal which determines which pin will be the clock signal
;external CLK

;*SDA is a literal which determines which pin will be the data signal
;external CLK

;*I2CPORT is a literal which determines which port will be used as the I2C port.  Example setup for CLK = RB6 and SDA = RB7.<br><br>  CLK equ 0x06<br>  SDA equ 0x07<br> I2CPORT equ PORTB
;external I2CPORT


;;;;;;; Variables ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;*I2C Data byte, declare as register in main program
;external i2csdata

;*Temporary Counter, declare as register in main program
;external cntr

;;;;;;; I2CSGetStop Routine ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;*Tests if the next clock cycle is stop, start, or continued transmission.
;*Returns:  If Stop detected, returns hFF in WREG.  If Start detected, returns hFE in WREG.  If continued transmission, recieves next byte and returns h00 in WREG.  Next byte appears in i2csdata
I2CSGetStop ;public
		btfss I2CPORT, CLK			;Clock line high?
			goto I2CSGetStop
		btfsc I2CPORT, SDA
			goto I2CSGetStopL2		;SDA was high
I2CSGetStopL1
		btfsc I2CPORT, SDA
			retlw 0xFF				;Detected stop bit
		btfsc I2CPORT, CLK
			goto I2CSGetStopL1		;Wait for clock to go low
		movlw 0x02
		movwf i2csdata
		goto I2CSGetByteL1			;Get next byte, no stop bit
I2CSGetStopL2
		btfss I2CPORT, SDA
			goto I2CSGetStopL3		;Detected start bit
		btfsc I2CPORT, CLK
			goto I2CSGetStopL2		;Wait for clock to go low
		movlw 0x03
		movwf i2csdata
		goto I2CSGetByteL1			;Get next byte, no start bit
I2CSGetStopL3
		btfsc I2CPORT, CLK
			goto I2CSGetStopL3		;Wait for clock to go low
		retlw 0xFE

;;;;;;; I2CSWaitStart Routine ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;*Waits for a start condition.  Never returns unless Start detected and byte recieved.
;*Returns: 0x00 in WREG.  Byte returned in i2csdata
I2CSWaitStart ;public
		BNKSEL I2CPORT+0x080
		bsf I2CPORT, SDA			;Release SDA
		BNKSEL I2CPORT
I2CSWaitStartL3
		btfss I2CPORT, CLK			;Clock line high?
			goto I2CSWaitStartL3
		btfss I2CPORT, SDA			;Data line high?
			goto I2CSWaitStartL3
I2CSWaitStartL2
		btfsc I2CPORT, SDA			;Data line low?
			goto I2CSWaitStartL2
		btfss I2CPORT, CLK			;Clock line high?
			goto I2CSWaitStartL3
I2CSWaitStartL1
		btfsc I2CPORT, CLK			;Clock line low?
			goto I2CSWaitStartL1
		;Fall into I2CSGetByte

;;;;;;; I2CSGetByte Routine ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;*Recieves a byte and sends an acknowledge.  Recieved byte appears in i2csdata
;*Returns:  0x00 in WREG
I2CSGetByte ;public
		bcf STATUS, C				;Clear carry
		clrf i2csdata				;Clear Input byte
		bsf i2csdata, 0				;Set indicator
I2CSGetByteL1
		btfss I2CPORT, CLK			;Clock high transition?
			goto I2CSGetByteL1
		bcf STATUS, C				;High transition, get bit into carry
		btfsc I2CPORT, SDA			;Assume clear, set if necessary
			bsf STATUS, C
		rlf i2csdata, F				;Add to LSB
I2CSGetByteL2
		btfsc I2CPORT, CLK			;Clock low transition
			goto I2CSGetByteL2
		btfss STATUS, C				;Check indicator.  High is done
			goto I2CSGetByteL1
		;Fall into Acknowledge

;;;;;;; I2CSPutAck Routine ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;*Send an acknowledge.
;*Returns: 0x00 in WREG
I2CSPutAck ;public
		bcf I2CPORT, SDA			;Ensure SDA low
		BNKSEL I2CPORT+0x080
		bcf I2CPORT, SDA			;Hold SDA low
		BNKSEL I2CPORT
I2CSPutAckL1
		btfss I2CPORT, CLK			;Clock high transition
			goto I2CSPutAckL1
I2CSPutAckL2
		btfsc I2CPORT, CLK			;Clock low transition
			goto I2CSPutAckL2
		BNKSEL I2CPORT+0x080
		bsf I2CPORT, SDA			;Release SDA
		BNKSEL I2CPORT
		retlw 0

;;;;;;; I2CSPutByte ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;*Sends a byte.  Expects: the byte to send to be in i2csdata.
;*Returns: 0x00 in WREG if Ack detected.  0xFF in WREG if Ack not detected
I2CSPutByte ;public
		bcf I2CPORT, SDA			;Ensure SDA pulls low
		movlw 0x08
		movwf cntr
		goto I2CSPutByteL1S
I2CSPutByteL1
		btfsc I2CPORT, CLK			;Clock low transition
			goto I2CSPutByteL1
I2CSPutByteL1S
		BNKSEL I2CPORT+0x080
		bsf I2CPORT, SDA			;Release SDA
		btfss i2csdata, 7
			bcf I2CPORT, SDA		;Hold SDA low
		BNKSEL I2CPORT
I2CSPutByteL2
		btfss I2CPORT, CLK			;Clock high transition
			goto I2CSPutByteL2
		rlf i2csdata, F
		decfsz cntr, F
			goto I2CSPutByteL1
I2CSPutByteL3
		btfsc I2CPORT, CLK			;Clock low transition
			goto I2CSPutByteL3
		BNKSEL I2CPORT+0x080
		bsf I2CPORT, SDA			;Release SDA
		BNKSEL I2CPORT
		;Fall into I2CSGetAck

;;;;;;; I2CSGetAck ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;*Detects if the master sent an acknowledge.  Expects: to be called when clock is low
;*Returns: 0x00 in WREG if Ack detected.  0xFF in WREG if Ack not detected
I2CSGetAck ;public
		btfss I2CPORT, CLK			;Clock high transition
			goto I2CSGetAck
		movlw 0x00					;Ack
		btfsc I2CPORT, SDA			;Test SDA
			movlw 0xFF				;No Ack
I2CSGetAckL1
		btfsc I2CPORT, CLK			;Clock low transition
			goto I2CSGetAckL1
		return