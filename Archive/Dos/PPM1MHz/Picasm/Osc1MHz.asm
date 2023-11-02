;==============================================================================
;*Author:  Jonathan Weaver, jonw0224@netscape.net
;E-mail Contact: jonw0224@netscape.net
;*Description: An oscilloscope program based on the PIC16F877 and the MAX118
;*Version: 1.0
;*Date: 11/3/2005
;*Filename: osc.asm
;
;Versions:  1.0 - 3/29/2003
;			1.0 - 7/26/2004
;			1.0 - 4/2/2005
;			1.0 - 9/29/2005 -- Additional Header comments and license added
;			1.1 - 11/3/2005 -- Began to modify for use on PIC16F877
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

;=============================================================================
; C O N F I G U R A T I O N
;=============================================================================

	list p=16F877a

      errorlevel      -302, -205, -207   ;Suppress bank selection messages
	__config  _WDT_OFF & _HS_OSC & _LVP_OFF
	clockFreq = 20		;20 = 20 MHZ, 4 = 4 MHZ

;=============================================================================
; C O N S T A N T S
;=============================================================================

BUFFERMIN equ 0x20		;Memory restrictions for the buffer
BUFFERSIZE equ D'64'	;Number of data points to store.  In single channel
						;mode, all data points are for one channel, in XY mode
						;the data points alternate between channel 1 and
						;channel 2

;I/O Pin maps
;-----------------------------------------------------------------------------
I2CPORT set PORTC
SDA equ 0x04			;Pin map for the I2CPORT
CLK equ 0x03

ADC_CONTROLPORT set PORTB
ADC_DATAPORT set PORTD
RDD equ 0x02			;Pin map for the ADC
TRIGGER equ 0x00
ADDR2 equ 0x05			;ADDR2 and ADDR1 not used in this program (later use)
ADDR1 equ 0x04
ADDR0 equ 0x03			;Least significant bit of the ADC channel address
CS equ 0x01

;Configuration memory map
;-----------------------------------------------------------------------------
;Bit map for configLoc1
TRIGGERPOSBIT equ 0x07	;1 is positive slope trigger, 0 is negative slope
TRIGGERENBIT equ 0x06	;1 is trigger enabled, 0 is no trigger
CLOCKFREQBIT equ 0x05	;1 is 20 MHz, 0 is 4 MHz
CHANNELBIT equ 0x04		;1 is channel 2, 0 is channel 1
FREQMODEBIT3 equ 0x03	;Reserve the bits in CONFIGLOC1 for the frequency modes
FREQMODEBIT2 equ 0x02
FREQMODEBIT1 equ 0x01
FREQMODEBIT0 equ 0x00

FreqSample1M equ D'0'	;Table of frequency modes
FreqSample833k equ D'1'
FreqSample625k equ D'2'
FreqSample417k equ D'3'
FreqSample250k equ D'4'
FreqSampleDelayed equ D'5'
FreqSampleXY equ D'6'


;=============================================================================
; V A R I A B L E S
;=============================================================================

CBLOCK	0x70
	cntr				;general use counter and temporary variable
	cntrb				;second counter and temporary variable
	i2csdata			;i2csdata and cntrc (third counter)
	configLoc1			;Configuration mode
	triggerDelay1		;trigger delay (2 bytes)
	triggerDelay2
	sampleRate1			;sample rate delay (2 bytes)
	sampleRate2
ENDC

cntrc equ i2csdata

;=============================================================================
; M A C R O S
;=============================================================================

	include "p16F877a.inc"
	include "equality.inc"
	include "banks.inc"
	include "asmext.inc"

ConfRecieve macro
	call I2CSGetByte				;Recieve ConfigLoc1
	movf i2csdata, w
	andlw ~(1 << CLOCKFREQBIT)		;Don't accept flag for clock, but set it
	if clockFreq == 20				;if necessary
		iorlw 1 << CLOCKFREQBIT
	endif
	movwf configLoc1
	call I2CSGetByte				;Recieve trigger delay
	MOVFF i2csdata, triggerDelay1
	call I2CSGetByte
	MOVFF i2csdata, triggerDelay2
	call I2CSGetByte				;Recieve sample rate
	MOVFF i2csdata, sampleRate1
	call I2CSGetByte
	MOVFF i2csdata, sampleRate2
 	endm

ConfSend macro
	;Send clock frequency configuration
	;Send number of datapoints (2 bytes)
	MOVFF configLoc1, i2csdata
	call I2CSPutByte
	MOVFF triggerDelay1, i2csdata
	call I2CSPutByte
	MOVFF triggerDelay2, i2csdata
	call I2CSPutByte
	MOVFF sampleRate1, i2csdata
	call I2CSPutByte
	MOVFF sampleRate2, i2csdata
	call I2CSPutByte
	endm

;To be filled out when configuration is added to program
;For now send scale of 1, DC mode on both channels
ChannelConfSend macro
	;Format of channel configuration is: Channel 1 Scale (2) bits
	;									 For scale, 00 = 1, 01 = 10, 10 = 100
	;									 Channel 2 Scale (2) bits
	;									 Channel 1 AC = 1 / DC = 0 (1) bit
	;									 Channel 2 AC = 1 / DC = 0 (1) bit
	;									 Two least significant bits = 0
	clrf i2csdata
	call I2CSPutByte
	;Next byte is Channel 1 offset
	clrf i2csdata
	call I2CSPutByte
	;Next byte is Channel 2 offset
	clrf i2csdata
	call I2CSPutByte
	endm

;=============================================================================
; I N T E R R U P T S
;=============================================================================

org 0x000
;Initialize
;First three lines of initialization included here to save on memory.
	MOVLF B'11000110', ADC_CONTROLPORT
	clrf ADC_DATAPORT
	goto INITIAL

org 0x004
INT_HANDLER
	retfie

;=============================================================================
; I N C L U D E S
;=============================================================================
	include "i2cs.inc"

;=============================================================================
; M A I N
;=============================================================================
;Initalize for the program
;-----------------------------------------------------------------------------
INITIAL:
	clrf PORTA
	BNKSEL TRISA
	MOVLF B'00111111', TRISA
	MOVLF B'10000000', OPTION_REG
	MOVLF B'00000000', INTCON
	MOVLF B'00000001', ADC_CONTROLPORT
	MOVLF B'11111111', ADC_DATAPORT
	MOVLF B'00010111', TRISE			;Set up as inputs, use parallel port slave mode
	MOVLF B'00000111', ADCON1			;Turn off A/D converter
	BNKSEL 0x0000
	bcf STATUS, IRP						;Ensure indirect addressing of Bank0 and Bank1
	clrf ADCON0

MAIN
	call WaitComm
	movf configLoc1, w			;Put configuration in WREG
	bcf ADC_CONTROLPORT, ADDR0			;Select Channel
	btfsc configLoc1, CHANNELBIT
		bsf ADC_CONTROLPORT, ADDR0
	if (high Main_Select)
		movlw high Main_Select	;Prepare for jump
		movwf PCLATH
	else
		clrf PCLATH
	endif
	andlw (1<<FREQMODEBIT3)|(1<<FREQMODEBIT2)|(1<<FREQMODEBIT1)|(1<<FREQMODEBIT0)	;Unmask FreqMode
Main_Select
	addwf PCL, f		  		;Add freqMode to Program Counter
	goto Sample1M				;FreqMode = 0
	goto Sample833k				;FreqMode = 1
	goto Sample625k				;FreqMode = 2
	goto Sample417k250k			;FreqMode = 3
	goto Sample417k250k			;FreqMode = 4
	goto SampleDelayed			;FreqMode = 5
	goto SampleXY				;FreqMode = 6
Main_ExitSelect
	goto MAIN					;FreqMode = 7 (shouldn't happen)
	goto MAIN					;FreqMode = 8 (shouldn't happen)
	goto MAIN					;FreqMode = 9 (shouldn't happen)
	goto MAIN					;FreqMode = 10 (shouldn't happen)
	goto MAIN					;FreqMode = 11 (shouldn't happen)
	goto MAIN					;FreqMode = 12 (shouldn't happen)
	goto MAIN					;FreqMode = 13 (shouldn't happen)
	goto MAIN					;FreqMode = 14 (shouldn't happen)
	goto MAIN					;FreqMode = 15 (shouldn't happen)


;=============================================================================
; S U B R O U T I N E S
;=============================================================================

;Wait for command from computer and respond accordingly
;-----------------------------------------------------------------------------
WaitComm
	bcf PORTA, 2
	bcf PORTA, 3
	bsf PORTA, 5
	call I2CSWaitStart
	skipEqLF B'11111000', i2csdata
		goto WaitComm_Conf
WaitComm_Data
	MOVLF B'11011100', i2csdata		;Send beginning of message
	bcf PORTA, 2
	bsf PORTA, 3
	bcf PORTA, 5
	call I2CSPutByte
	MOVLF BUFFERMIN, FSR			;Set pointer to beginning of queue
WaitComm_SendData
	MOVFF INDF, i2csdata			;Get data ready to send
	incf FSR, F						;Increment pointer
	bcf PORTA, 2
	bsf PORTA, 3
	bsf PORTA, 5
	call I2CSPutByte				;Send data
	andlw 0xFF						;Until end of queue
	skipNotZero
		goto WaitComm_SendData
	bsf PORTA, 2
	bcf PORTA, 3
	bcf PORTA, 5
	ChannelConfSend
	return
WaitComm_Conf
	skipEqLF B'11111001', i2csdata
		goto WaitComm_Rec
	MOVLF B'11011101', i2csdata		;Send beginning of message
	bsf PORTA, 2
	bcf PORTA, 3
	bsf PORTA, 5
	call I2CSPutByte
	bsf PORTA, 2
	bsf PORTA, 3
	bcf PORTA, 5
	ConfSend
	return
WaitComm_Rec
	skipEqLF B'11111010', i2csdata
		goto WaitComm				;No valid message sent
	MOVLF B'11011110', i2csdata		;Send beginning of message
	bsf PORTA, 2
	bsf PORTA, 3
	bsf PORTA, 5
	call I2CSPutByte
	bcf PORTA, 2
	bcf PORTA, 3
	bcf PORTA, 5
	ConfRecieve
	return

;ADCSetup, sets up the MAX114/MAX118 for sampling
;-----------------------------------------------------------------------------
ADCSetup
	btfsc configLoc1, TRIGGERENBIT
		call WaitTrigger
	bsf ADC_CONTROLPORT, CS
	bsf ADC_CONTROLPORT, RDD
	BNKSEL ADC_CONTROLPORT + 0x080
	bcf ADC_CONTROLPORT, RDD
	BNKSEL ADC_CONTROLPORT
	bcf ADC_CONTROLPORT, CS					;Select MAX114
	bcf ADC_CONTROLPORT, RDD				;Begin AD converion
	return

;ADCShutdown, shutsdown the MAX114/MAX118
;-----------------------------------------------------------------------------
ADCShutdown
	bsf ADC_CONTROLPORT, RDD				;Stop conversion
	movwf INDF								;Save to QUEUE
	bsf ADC_CONTROLPORT, CS					;Unselect MAX114
	BNKSEL ADC_CONTROLPORT + 0x080
	bsf ADC_CONTROLPORT, RDD
	BNKSEL ADC_CONTROLPORT
	return

;WaitTrigger, syncs up with the waveform
;Determines configuration dictates that the trigger is positive or negative
;and acts accordingly.
;-----------------------------------------------------------------------------
WaitTrigger
	MOVFF triggerDelay2, cntr			;Get the trigger delay
	MOVFF triggerDelay1, cntrb
	movf configLoc1, w					;Get the trigger status
	andlw 0x01 << TRIGGERPOSBIT
	skipZero							;Positive of negative trigger
		goto TriggerPos
TriggerNeg
	btfss ADC_CONTROLPORT, TRIGGER		;Continue if trigger is high
		goto $ - 1
	btfsc ADC_CONTROLPORT, TRIGGER		;Wait for trigger to go low
		goto $ - 1						;Possible 600 ns jitter at 20 MHz Clock
	goto Delay

TriggerPos
	btfsc ADC_CONTROLPORT, TRIGGER		;Continue if trigger is low
		goto $ - 1
	btfss ADC_CONTROLPORT, TRIGGER		;Wait for trigger to go high
		goto $ - 1						;Possible 600 ns jitter at 20 MHz Clock
	goto Delay

;Delay used to adjust sample rate and trigger delay
;Any delay due to using a call must be added (i.e. delay doesn't include call
;statement)
;Delay = 5+7*(cntrb:cntr)+3*cntrb if cntr > 0, cntrb >= 0
;If cntr =  then delay as if cntr = 256
;If cntrb:cntr = 0x0000 then Delay as if cntrb = 255, cntr = 256
;-----------------------------------------------------------------------------
Delay
	movlw 0x01
DelayLoop
	subwf cntr, F
	btfss STATUS, C
		subwf cntrb, F
	movf cntr, F
	skipZero
		goto DelayLoop
	movf cntrb, F
	skipZero
		goto DelayLoop
	return

;Fastest sample
;Sampling rate = 1 MHz with 20 MHz clock
;Sampling rate = 200 kHz with 4 MHz clock
;-----------------------------------------------------------------------------
Sample1M
	call ADCSetup
	MOVLF BUFFERMIN, FSR				;Initialize pointer
	movf ADC_DATAPORT, W				;Read slave port, but throw away value
	bsf ADC_CONTROLPORT, RDD
	bcf ADC_CONTROLPORT, RDD			;Start next conversion, sample on slave port
	goto $ + 1							;Wait two cycles
	local count
	count = 1
	while count < BUFFERSIZE
		movf ADC_DATAPORT, W			;Sample
		bsf ADC_CONTROLPORT, RDD		;Stop conversion
		bcf ADC_CONTROLPORT, RDD		;Begin next conversion
		movwf INDF						;Save to QUEUE
		incf FSR, F						;Increment QUEUE pointer
		count = count + 1
	endw
	movf ADC_DATAPORT, W						;Last sample
	call ADCShutdown
	goto MAIN

;Fast sample
;Sampling rate = 833.333 kHz with 20 MHz clock
;Sampling rate = 166.667 kHz with 4 MHz clock
;-----------------------------------------------------------------------------
Sample833k
	call ADCSetup
	MOVLF BUFFERMIN, FSR				;Initialize pointer
	movf ADC_DATAPORT, W				;Read slave port, but throw away value
	bsf ADC_CONTROLPORT, RDD
	bcf ADC_CONTROLPORT, RDD			;Start next conversion, sample on slave port
	goto $ + 1							;Wait three cycles
	nop
	local count
	count = 1
	while count < BUFFERSIZE
		movf ADC_DATAPORT, W			;Sample
		bsf ADC_CONTROLPORT, RDD		;Stop conversion
		bcf ADC_CONTROLPORT, RDD		;Begin next conversion
		movwf INDF						;Save to QUEUE
		incf FSR, F						;Increment QUEUE pointer
		nop								;Wait a cycle
		count = count + 1
	endw
	movf ADC_DATAPORT, W				;Last sample
	call ADCShutdown
	goto MAIN

;Fast sample
;Sampling rate = 625 kHz with 20 MHz clock
;Sampling rate = 125 kHz with 4 MHz clock
;-----------------------------------------------------------------------------
Sample625k
	call ADCSetup
	MOVLF BUFFERSIZE, cntr				;Initialize counter
	MOVLF BUFFERMIN, FSR				;Initialize pointer
	movf ADC_DATAPORT, W				;Read slave port, but throw away value
	bsf ADC_CONTROLPORT, RDD
	bcf ADC_CONTROLPORT, RDD			;Start next conversion, sample on slave port
	goto StSample625kLoop				;Wait 5 cycles
Sample625kLoop
	movf ADC_DATAPORT, W				;Sample
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	movwf INDF							;Save to QUEUE
	incf FSR, F							;Increment QUEUE pointer
StSample625kLoop
	decfsz cntr, F						;Increment counter, 64 samples?
		goto Sample625kLoop
	nop
	movf ADC_DATAPORT, W						;Last sample
	call ADCShutdown
	goto MAIN

;Fast sample
;Sampling rate = 416.667 kHz with 20 MHz clock
;Sampling rate =  83.333 kHz with 4 MHz clock
;or
;Sampling rate = 250 kHz with 20 MHz clock
;Sampling rate =  50 kHz with 4 MHz clock
;-----------------------------------------------------------------------------
Sample417k250k
	call ADCSetup
	MOVLF BUFFERSIZE, cntr			;Initialize counter
	MOVLF BUFFERMIN, FSR			;Initialize pointer
	movf ADC_DATAPORT, W			;Read slave port, but throw away value
	bsf ADC_CONTROLPORT, RDD
	bcf ADC_CONTROLPORT, RDD		;Start next conversion, sample on slave port
	goto StSample417kLoop
Sample417kLoop
	movf ADC_DATAPORT, W			;Sample
	bsf ADC_CONTROLPORT, RDD		;Stop conversion
	bcf ADC_CONTROLPORT, RDD		;Begin next conversion
	movwf INDF						;Save to QUEUE
	incf FSR, F						;Increment QUEUE pointer
StSample417kLoop
	btfss configLoc1, 2				;Choose to delay 4 cycles or 12 cycles depending on mode
		goto Sample417k				;Delaying 4 cycles, sample at 417k
Sample250k
	MOVLF 0x02, cntrb				;Delay 10 cycles
	decfsz cntrb, F
		goto $ - 1
	goto $ + 1
Sample417k
	nop
	decfsz cntr, F					;Increment counter, 64 samples?
		goto Sample417kLoop
	nop
	movf ADC_DATAPORT, W					;Last sample
	call ADCShutdown
	goto MAIN

;Sample Delayed
;Sampling rate = 5e6 / (19 + 7 * SAMPLERATE1:SAMPLERATE2 + 3 * SAMPLERATE1) with 20 MHz clock
;Sampling rate = 1e6 / (19 + 7 * SAMPLERATE1:SAMPLERATE2 + 3 * SAMPLERATE1) with 4 MHz clock
;-----------------------------------------------------------------------------
;Because memory is limited, SampledDelay needs to utilize all memory in
;the PIC16F84. Therefore, some variables are used here in an unconventional
;way and no values in any variable should be trusted after this procedure runs
;except the data in the buffer
SampleDelayed
	call ADCSetup
	MOVLF BUFFERSIZE, cntrc			;Initialize counter, use cntrc as counter
	MOVLF BUFFERMIN, FSR			;Initialize pointer
	nop
	movf ADC_DATAPORT, W			;Read slave port, but throw away value
	bsf ADC_CONTROLPORT, RDD
	bcf ADC_CONTROLPORT, RDD		;Start next conversion, sample on slave port
	goto StSampleDelayedLoop
SampleDelayedLoop
	movf ADC_DATAPORT, W			;Sample
	bsf ADC_CONTROLPORT, RDD		;Stop conversion
	bcf ADC_CONTROLPORT, RDD		;Begin next conversion
	movwf INDF						;Save to QUEUE
	incf FSR, F						;Increment QUEUE pointer
StSampleDelayedLoop
	MOVFF sampleRate2, cntr			;Restore cntr from i2csdata
	MOVFF sampleRate1, cntrb		;Restore cntrb from EEDATA
	call Delay
	decfsz cntrc, F				;Increment counter, 64 samples?
		goto SampleDelayedLoop
	nop
	movf ADC_DATAPORT, W			;Last sample
	call ADCShutdown
	goto MAIN

;SampleXY
;Sampling rate = 5e6 / (26 + 7 * SAMPLERATE1:SAMPLERATE2 + 3 * SAMPLERATE1) with 20 MHz clock
;Sampling rate = 5e6 / (26 + 7 * SAMPLERATE1:SAMPLERATE2 + 3 * SAMPLERATE1) with 4 MHz clock
;SampleXY does not sample X and Y at the same time.  Y is sampled 6 clock cycles
;behind X.  For a 20 MHz clock this is 1.2 uS, for a 4 MHz clock this is 6 uS.
;-----------------------------------------------------------------------------
;Because memory is limited, SampleXY needs to utilize all memory in
;the PIC16F84. Therefore, some variables are used here in an unconventional
;way and no values in any variable should be trusted after this procedure runs
;except the data in the buffer
SampleXY
	call ADCSetup
	MOVLF BUFFERSIZE/2, cntrc		;Initialize counter, use cntrc as counter
	MOVLF BUFFERMIN, FSR			;Initialize pointer
	bcf ADC_CONTROLPORT, ADDR0		;Set channel to X
	movf ADC_DATAPORT, W			;Read slave port, but throw away value
	bsf ADC_CONTROLPORT, RDD
	bcf ADC_CONTROLPORT, RDD		;Start next conversion, sample on slave port
	goto StSampleXYLoop
SampleXYLoop
	movf ADC_DATAPORT, W			;Sample X
	bsf ADC_CONTROLPORT, RDD		;Stop conversion
	bsf ADC_CONTROLPORT, ADDR0		;Set channel to Y
	bcf ADC_CONTROLPORT, RDD		;Begin next conversion
	movwf INDF						;Save to QUEUE
	incf FSR, F						;Increment QUEUE pointer
	movf ADC_DATAPORT, W			;Sample Y
	bsf ADC_CONTROLPORT, RDD		;Stop conversion
	bcf ADC_CONTROLPORT, ADDR0		;Set channel to X
	bcf ADC_CONTROLPORT, RDD		;Begin next conversion
	movwf INDF						;Save to QUEUE
	incf FSR, F						;Increment QUEUE pointer
StSampleXYLoop
	MOVFF sampleRate2, cntr			;Restore cntr from i2csdata
	MOVFF sampleRate1, cntrb		;Restore cntrb from EEDATA
	call Delay
	decfsz cntrc, F				;Increment counter, 64 samples?
		goto SampleXYLoop
	nop
	movf ADC_DATAPORT, W			;Last sample X
	bsf ADC_CONTROLPORT, RDD		;Stop conversion
	bsf ADC_CONTROLPORT, ADDR0		;Set channel to Y
	bcf ADC_CONTROLPORT, RDD		;Begin next conversion
	movwf INDF						;Save to QUEUE
	incf FSR, F						;Increment QUEUE pointer
	movf ADC_DATAPORT, W			;Last Sample Y
	call ADCShutdown
	goto MAIN

;=============================================================================
end		;end of program
