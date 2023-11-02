;==============================================================================
;*Author:  Jonathan Weaver, jonw0224@aim.com
;E-mail Contact: jonw0224@aim.com
;*Description: An oscilloscope program based on the PIC16F877 and the MAX118
;*Version: 1.200
;*Date: 6/28/2011
;*Filename: osc.asm
;
;Versions:	1.000 - 3/29/2003
;			1.000 - 7/26/2004
;			1.000 - 4/2/2005
;			1.000 - 9/29/2005 -- Additional Header comments and license added
;			1.101 - 11/3/2005 -- Began to modify for use on PIC16F877
;			1.102 - 3/28/2006 -- Made trigger interrupt based, expanded sampling
;				to 256 samples across modes
;			1.102 - 4/12/2006 -- Finished expanding sampling to 256 samples.
;				Still need to test communication, sampleDelayed and sampleXY
;				modes.
;			1.103 - 4/29/2007 -- Fixed interlaced sampling, modified so sample
;				data configuration and trigger level are measured after the
;				data buffer if filled instead of at communication.
;			1.104 - 6/27/2007 -- Added faster XY sampling modes
;			1.105 - 7/18/2007 -- Added repetitive sampling and wait for trigger
;				in WaitComm so the scope will respond to the PC
;			1.106 - 3/1/2009 -- changed the trigger back to not respond to PC
;			1.107 - 3/1/2009 -- Changed the trigger code to shorten the 
;				trigger delay. - NEED TO TEST
;				Made scope responsive to trigger change	message. - NEED TO TEST
;				Removed the use of the slave parallel port. - NEED TO TEST
;				Combined SampleXY250 and SampleXY192. - NEED TO TEST - tested 3/5/2009
;			1.108 - 3/9/2009 -- changed trigger code to broaden range of trigger
;				delay - NEED TO TEST
;			1.109 - 10/28/2009 -- tested and fixed bug with trigger code
;			1.110 - 5/12/2010 -- Added serial port support to code.  NEED TO TEST
;			1.111 - 2/1/2011 -- fixed a bug with the trigger code (another one)
;			1.200 - 6/28/2011 - Modified code to handle conditional compile for
;				hardware version 1.0 or hardware version 1.2

;*****BEGIN PM DSOscope CHANGE DESCRIPTION************************************
;NEW VERSION CREATED:	A02
;	20120522.1 - by PM
;		Changes for working with new DSOscope hardware (uses PIC16F887
;		instead of PIC16F877A).  Changes made for serial port configuration
;		and disabling of PIC ADC so port pins work as digital.
;		Changes made to eliminate I2C references/accesses.
;
;NEW VERSION CREATED:	A03
;	20120908.1 - by PM
;		Started making changes to add an interrupt driven sampling mode.  The
;		interrupt driven sampling mode will only be use for the slower speed
;		acquisitions... probably 1mSec/sample and slower.  At that
;		speed (1mSec/sample) it would take:
;		    (1mSec/sample)*256 samples = 0.256 seconds for a full capture.
;		The intent of the interrupt driven sampling mode is to allow the
;		DSOscope to update the PC screen as it continues to sample the data
;		for an acquisition.  Currently the PC has to wait for the full capture
;		to be completed before the screen gets updated.  On very slow sample
;		speeds, it looks like the scope has died or is not doing anything.
;		Then, all of a sudden it finishes its sampling and the PC screen is
;		showing the new captured waveform.  With an interrupt driven method,
;		the PC screen can be continuously painted in with the slow, newly
;		arriving, waveform.
;	20120914.1 - by PM
;		Code changes for an interrupt driven sampling mode completed.  First
;		test attempt failed... duh, what did I expect! ;-)   time for debug!
;
;*****END PM DSOscope CHANGE DESCRIPTION**************************************
;
;
;Copyright (C) 2003-2011 Jonathan Weaver
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

	LIST P=16F887

	errorlevel	-302, -205, -207		;Suppress bank selection messages


;*****************************************************
;       === Configuration Word Definitions ===
;*****************************************************
; Defines for PIC16F887 operation in the DSOscope CPU Board

; '__CONFIG' directive is used to embed configuration data within .asm file.
; The labels following the directive are located in the respective .inc file.
; See respective data sheet for additional information on configuration word.

	__CONFIG _CONFIG1, _DEBUG_OFF & _LVP_OFF & _FCMEN_OFF & _IESO_OFF & _BOR_OFF & _CPD_OFF & _CP_OFF & _MCLRE_ON & _PWRTE_OFF & _WDT_OFF & _HS_OSC
	__CONFIG _CONFIG2, _WRT_OFF & _BOR40V

; '__idlocs' sets the four ID locations to the hexadecimal value of expression.
; These are not readable by the cpu, but can be read by the programning hardware.

	__idlocs	0x1234

	clockFreq = 20					;20 = 20 MHZ, 4 = 4 MHZ

;=============================================================================
; C O N S T A N T S
;=============================================================================

BANK0			equ	0x0000	;Starting addresses for Special Function Register memory
BANK1			equ	0x0080
BANK2			equ	0x0100
BANK3			equ	0x0180

BUFFERMIN		equ	0x20	;Memory restrictions for the buffer
BUFFERSIZE		equ	D'64'	;Number of data points to store.  In single channel
							;mode, all data points are for one channel, in XY mode
							;the data points alternate between channel 1 and
							;channel 2
BUFFERMAX		equ	BUFFERMIN+BUFFERSIZE-1
TOTALBUFFERSIZE	equ	BUFFERSIZE*4

;I/O Pin maps
;-----------------------------------------------------------------------------
	SERIALPORT	set	PORTC
		RX		equ	0x07
		TX		equ	0x06

	ADC_CONTROLPORT	set	PORTE
		RDD		equ	0x00
		ADDR0	equ	0x01

	TRIGGERPORT	set	PORTB
		TRIGGER	equ	0x00

	ADC_PORT	set	PORTB
		ADDR2	equ	0x03
		ADDR1	equ	0x02
		CS		equ	0x01

	ADC_DATAPORT	set	PORTD

	ANALOG_SEL	set	PORTC
		CH1SEL	equ	0x01
		CH2SEL	equ	0x02

	ANALOG_GAIN	set	PORTA
		GAIN1	equ	0x00
		GAIN5	equ	0x01
		CH1SELG	equ	0x04
		CH2SELG	equ	0x05

	ANALOG_ACDC	set	PORTC
		ACDCMODE	equ	0x00

;Configuration memory map
;-----------------------------------------------------------------------------
;Bit map for gbl_configLoc1
	TRIGGERPOSBIT		equ	0x07	;1 is positive slope trigger, 0 is negative slope
	TRIGGERENBIT		equ	0x06	;1 is trigger enabled, 0 is no trigger
	CLOCKFREQBIT		equ	0x05	;1 is 20 MHz, 0 is 4 MHz
	CHANNELBIT			equ	0x04	;1 is channel 2, 0 is channel 1
	FREQMODEBIT3		equ	0x03	;Reserve the bits in CONFIGLOC1 for the frequency modes
	FREQMODEBIT2		equ	0x02
	FREQMODEBIT1		equ	0x01
	FREQMODEBIT0		equ	0x00

;Bit map for b0_sampleBank
	SAMPLEBANK2			equ	0x03	;note the order of these!, matches sampling protocol=> 0, 1, 3, 2
	SAMPLEBANK3			equ	0x02
	SAMPLEBANK1			equ	0x01
	SAMPLEBANK0			equ	0x00


;Table of frequency modes, 0 to 15
	FREQSAMPLE1M		equ	D'0'
	FREQSAMPLE833K		equ	D'1'
	FREQSAMPLE625K		equ	D'2'
	FREQSAMPLE417K		equ	D'3'
	FREQSAMPLE250K		equ	D'4'
	FREQSAMPLEDELAYED	equ	D'5'
	FREQSAMPLEREP5M		equ	D'6'	;Ensure trigger is enabled
	FREQSAMPLEREP2M		equ	D'7'	;Ensure trigger is enabled
	FREQSAMPLEXY417K	equ	D'8'
	FREQSAMPLEXY250K	equ	D'9'
	FREQSAMPLEXY192K	equ	D'10'
	FREQSAMPLEXYDELAYED	equ	D'11'
	FREQSAMPLEINTDRVN	equ	D'12'	;Interrupt Driven Sample Mode			<<<===PM CODE CHANGE...
	FREQSAMPLEXYINTDRVN	equ	D'13'	;Interrupt Driven Sample XY Mode		<<<===PM CODE CHANGE...

;=============================================================================
; V A R I A B L E S
;=============================================================================

CBLOCK	0x70			;Shared General Purpose Registers, accessible anywhere
	gbl_configLoc1			;Configuration mode
	gbl_sampleRate1			;sample rate delay (2 bytes)
	gbl_sampleRate2
	gbl_cntra				;general use counter
	gbl_cntrb				;second counter
	gbl_cntrc				;third counter
	gbl_modetemp			;temporary mode variable
	gbl_modetempb			;temporary mode for repetitive sampling
	gbl_spdata				;data to/from serial port
	gbl_dataConfig			;the data configuration
	gbl_w_temp				;temp storage for w register during interrupt handling
	gbl_status_temp			;temp storage for status register during interrupt handling
	gbl_pclath_temp			;temp storage for pclath register during interrupt handling
	gbl_unused2
	gbl_unused1
	gbl_unused0
ENDC

CBLOCK	0x60		;Bank0 General Purpose Registers
	b0_triggerDelay1		;trigger delay (3 bytes)
	b0_triggerDelay2
	b0_triggerDelay3
	b0_triggerLevel			;the trigger level
	b0_sampleAddr			;address to store ADC sampled value
	b0_sampleBank			;bank to store ADC sampled value
	b0_fsr_temp				;temp storage for fsr register during interrupt handling
	b0_unused8
	b0_unused7
	b0_unused6
	b0_unused5
	b0_unused4
	b0_unused3
	b0_unused2
	b0_unused1
	b0_unused0
ENDC

CBLOCK	0xE0		;Bank1 General Purpose Registers
	b1_unusedF
	b1_unusedE
	b1_unusedD
	b1_unusedC
	b1_unusedB
	b1_unusedA
	b1_unused9
	b1_unused8
	b1_unused7
	b1_unused6
	b1_unused5
	b1_unused4
	b1_unused3
	b1_unused2
	b1_unused1
	b1_unused0
ENDC

CBLOCK	0x160		;Bank2 General Purpose Registers
	b2_unusedF
	b2_unusedE
	b2_unusedD
	b2_unusedC
	b2_unusedB
	b2_unusedA
	b2_unused9
	b2_unused8
	b2_unused7
	b2_unused6
	b2_unused5
	b2_unused4
	b2_unused3
	b2_unused2
	b2_unused1
	b2_unused0
ENDC

CBLOCK	0x1E0		;Bank3 General Purpose Registers
	b3_unusedF
	b3_unusedE
	b3_unusedD
	b3_unusedC
	b3_unusedB
	b3_unusedA
	b3_unused9
	b3_unused8
	b3_unused7
	b3_unused6
	b3_unused5
	b3_unused4
	b3_unused3
	b3_unused2
	b3_unused1
	b3_unused0
ENDC

;=============================================================================
; I N C L U D E S
;=============================================================================
	include "p16F887.inc"
	include "equality.inc"
	include "asmext.inc"


;=============================================================================
; M A C R O S
;=============================================================================

MGOTO macro address
	if (address & (0x1000))
		bsf PCLATH, 4
	else
		bcf PCLATH, 4
	endif
	if (address & (0x800))
		bsf PCLATH, 3
	else
		bcf PCLATH, 3
	endif
	goto address
	endm

CONFRECEIVE macro
	call GetByte						;Receive ConfigLoc1
	movf gbl_spdata, w
	andlw ~(1 << CLOCKFREQBIT)			;Don't accept flag for clock, but set it
	if clockFreq == 20					;if necessary
		iorlw 1 << CLOCKFREQBIT
	endif
	movwf gbl_configLoc1
	banksel	BANK0
	call GetByte						;Receive trigger delay
	MOVFF gbl_spdata, b0_triggerDelay1
	call GetByte
	MOVFF gbl_spdata, b0_triggerDelay2
	call GetByte
	MOVFF gbl_spdata, b0_triggerDelay3
	call GetByte						;Receive sample rate
	MOVFF gbl_spdata, gbl_sampleRate1
	call GetByte
	MOVFF gbl_spdata, gbl_sampleRate2
	endm

CONFSEND macro
	;Send number of datapoints (2 bytes)
	MOVLF high TOTALBUFFERSIZE, gbl_spdata
	call PutByte
	MOVLF low TOTALBUFFERSIZE, gbl_spdata
	call PutByte
	;Send clock frequency configuration
	MOVFF gbl_configLoc1, gbl_spdata
	call PutByte
	banksel	BANK0
	MOVFF b0_triggerDelay1, gbl_spdata
	call PutByte
	MOVFF b0_triggerDelay2, gbl_spdata
	call PutByte
	MOVFF b0_triggerDelay3, gbl_spdata
	call PutByte
	MOVFF gbl_sampleRate1, gbl_spdata
	call PutByte
	MOVFF gbl_sampleRate2, gbl_spdata
	call PutByte
	endm

CHANNELCONFSEND macro
	MOVFF gbl_dataConfig, gbl_spdata	;Channel configuration
	call PutByte
	clrf gbl_spdata
	call PutByte						;Channel 1 offset
	call PutByte						;Channel 2 offset
	banksel	BANK0
	MOVFF b0_triggerLevel, gbl_spdata
	call PutByte						;Triggerlevel
	endm

CHANNELCONFSTORE macro
	;Format of channel configuration is:	Channel 1 Scale (2) bits
	;											For scale, 00 = 1, 01 = 2, 10 = 5
	;										Channel 2 Scale (2) bits
	;										Channel 1 AC = 1 / DC = 0 (1) bit
	;										Channel 2 AC = 1 / DC = 0 (1) bit
	;										Two least significant bits = 0
	clrf gbl_dataConfig
	banksel	TRISC
	bsf TRISC, CH2SEL					;Ch2Sel high Z
	bcf TRISC, CH1SEL					;Ch1Sel output
	bsf TRISA, CH2SELG					;Ch2Sel high Z
	bcf TRISA, CH1SELG					;Ch1Sel output
	banksel	ANALOG_SEL	
	bcf ANALOG_SEL, CH1SEL				;Ch1Sel low
	bcf ANALOG_GAIN, CH1SELG			;Ch1SelG low
	bsf gbl_dataConfig, 6				;Assume Gain = 2
	btfss ANALOG_GAIN, GAIN1			;If Gain1 then unmark
		bcf gbl_dataConfig, 6
	btfss ANALOG_GAIN, GAIN5			;If Gain5 then unmark
		bcf gbl_dataConfig, 6
	btfss ANALOG_GAIN, GAIN5			;If Gain5 then mark
		bsf gbl_dataConfig, 7
	btfsc ANALOG_ACDC, ACDCMODE			;If DC coupling open (implies AC coupling) then mark
		bsf gbl_dataConfig, 3
	bsf ANALOG_SEL, CH1SEL				;Recharge ACDCMODE signal line if it was driven low by above checks
	bsf ANALOG_GAIN, CH1SELG			;Recharge GAIN5 or GAIN1 signal line if it was driven low by above checks

	banksel	TRISC
	bsf TRISC, CH1SEL					;Ch1Sel high Z
	bcf TRISC, CH2SEL					;Ch2Sel output
	bsf TRISA, CH1SELG					;Ch1Sel high Z
	bcf TRISA, CH2SELG					;Ch2Sel output
	banksel	ANALOG_SEL
	bcf ANALOG_SEL, CH2SEL				;Ch2Sel low
	bcf ANALOG_GAIN, CH2SELG			;Ch1SelG low
	bsf gbl_dataConfig, 4				;Assume Gain = 2
	btfss ANALOG_GAIN, GAIN1			;If Gain1 then unmark
		bcf gbl_dataConfig, 4
	btfss ANALOG_GAIN, GAIN5			;If Gain5 then unmark
		bcf gbl_dataConfig, 4
	btfss ANALOG_GAIN, GAIN5			;If Gain5 then mark
		bsf gbl_dataConfig, 5
	btfsc ANALOG_ACDC, ACDCMODE			;If DC coupling open (implies AC coupling) then mark
		bsf gbl_dataConfig, 2
	bsf ANALOG_SEL, CH2SEL				;Recharge ACDCMODE signal line if it was driven low by above checks
	bsf ANALOG_GAIN, CH2SELG			;Recharge GAIN5 or GAIN1 signal line if it was driven low by above checks

	;Next byte is Trigger Level
	bcf ADC_CONTROLPORT, ADDR0			;Select address for trigger level
	bsf ADC_PORT, ADDR1
	bcf ADC_PORT, ADDR2
	bcf ADC_PORT, CS					;Select maxim ADC
	bcf ADC_CONTROLPORT, RDD			;Begin conversion
	nop									;Wait 3
	nop
	nop
	movf ADC_DATAPORT, w				;Save trigger level
	bsf ADC_CONTROLPORT, RDD			;stop conversion
	bsf ADC_PORT, CS					;unselect
	bcf ADC_CONTROLPORT, ADDR0			;Unselect address for trigger level
	bcf ADC_PORT, ADDR1
	bcf ADC_PORT, ADDR2
	banksel	BANK0
	movwf b0_triggerLevel
	endm

;=============================================================================
; I N T E R R U P T S
;=============================================================================

org 0x0000	;Reset Vector
;First three lines of initialization included here to save on memory.
	MOVLF B'00000001', ADC_CONTROLPORT
	clrf ADC_DATAPORT
	goto Initial

org 0x0004	;Interrupt Vector
IntHandler
	bcf		INTCON, GIE					;Turn off any further interrupts
	;The following "unacceptably lengthens" the start of the acquisition, but what else can we do!?!,
	; we have to save the current state
    movwf	gbl_w_temp					;Save off current W register contents
	swapf	STATUS,W					;Move status register into W register
	movwf	gbl_status_temp				;Save off contents of STATUS register
    movf	PCLATH,W					;Move pclath register into w register
    movwf	gbl_pclath_temp				;Save off contents of PCLATH register

	;Now to handle the pending interrupt (it should be either a trigger interrupt or a timer1 interrupt)
	pagesel	Triggered
	btfsc	INTCON,INTF					;Test to see if it wasn't a trigger interrupt
		goto	Triggered				;It was a trigger, so just jump, forget about the stack cleanup
	banksel	BANK0
	btfss	PIR1, TMR1IF				;Test to see if it was a timer 1 interrupt
		goto	ih_1					;It wasn't, so restore registers and then return from interrupt
	pagesel	IrqServiceTimer1
	call	IrqServiceTimer1			;service the timer1 interrupt

ih_1
	;restore previous state	
    movf    gbl_pclath_temp,W			;retrieve copy of PCLATH register
    movwf   PCLATH						;restore pre-isr PCLATH register contents
    swapf	gbl_status_temp,W			;retrieve copy of STATUS register
    movwf   STATUS						;restore pre-isr STATUS register contents
    swapf   gbl_w_temp,F
    swapf   gbl_w_temp,W				;restore pre-isr W register contents
    retfie								;return from interrupt and activate GIE

Triggered
	bcf		INTCON, INTE				;Now that we are triggered, turn off the trigger interrupt
										; for the duration of the acquisition
iht_1
	decfsz gbl_cntra, f					;Count down the trigger delay, 0xfff implies minimum delay
		goto iht_1
	decfsz gbl_cntrb, f
		goto iht_1
	decfsz gbl_cntrc, f
		goto iht_1
	movf gbl_modetemp, w
MainSelect
	addwf PCL, f						;Add freqMode to Program Counter
	MGOTO Sample1M						;FreqMode = 0
	MGOTO Sample833k					;FreqMode = 1
	MGOTO Sample625k					;FreqMode = 2
	MGOTO Sample417k250k				;FreqMode = 3
	MGOTO Sample417k250k				;FreqMode = 4
;	MGOTO SampleDelayed					;FreqMode = 5
	MGOTO SampleIntDrvn					;FreqMode = 12	<<== THIS IS HERE FOR TEST
	MGOTO SampleRep5M					;FreqMode = 6
	MGOTO SampleRep2M					;FreqMode = 7
	MGOTO SampleXY417k					;FreqMode = 8
	MGOTO SampleXY250k192k				;FreqMode = 9
	MGOTO SampleXY250k192k				;FreqMode = 10
	MGOTO SampleXYDelayed				;FreqMode = 11
	MGOTO SampleIntDrvn					;FreqMode = 12
	MGOTO SampleXYIntDrvn				;FreqMode = 13
	MGOTO Main							;Invalid FreqMode = 14, goto beginning
	MGOTO Main							;Invalid FreqMode = 15


;=============================================================================
; M A I N
;=============================================================================
;Initalize for the program
;-----------------------------------------------------------------------------
Initial
	clrf PORTA
	banksel TRISA
	MOVLF B'00010111', TRISA			;Configure PORTA
	MOVLF B'11000000', OPTION_REG		;Interrupt on rising edge of RB0
	MOVLF B'00010000', INTCON			;Interrupt on RB0 only, but not enabled yet
	MOVLF B'00110001', TRISB
	MOVLF B'11111111', TRISD
	MOVLF B'00000100', TRISE			;Set up USB detect as input, CS and ADDR0 as outputs
	MOVLF B'10111001', TRISC			;Configure PORTC

	banksel	ANSEL
	clrf	ANSEL		;Turn off analog mode on RE2,1,0 and RA5,3,2,1,0 so the pins read digital
	clrf	ANSELH		;Turn off analog mode on RB5,0,4,1,3,2 so the pins read digital

	;Initialize Serial Port

	banksel	BAUDCTL		;Access bank 3
	movlw	0x08		;Set the Serial Port baud rate generators
	movwf	BAUDCTL
	banksel	SPBRG		;Return to bank 1 and continue setting baud rate generators
	movlw	0x56		; for 57.6K baud
	movwf	SPBRG
	movlw	0x00
	movwf	SPBRGH
	movlw	0x24		;Set the Serial Port Transmitter configuration
	movwf	TXSTA
	banksel	RCSTA		;Access bank 0
	movlw	0x80		;movlw 0x90		;Set the Serial Port Receiver configuration (but don't receive yet)
	movwf	RCSTA

	bcf STATUS, IRP		;Ensure indirect addressing of Bank0 and Bank1
	clrf ADCON0			;Make sure PIC's ADC is off
	
Main
	call WaitComm

	clrf gbl_modetempb					;Clear the gbl_modetempb for repetitive sampling
	
MainB
	bcf ADC_CONTROLPORT, ADDR0			;Select Channel
	btfsc gbl_configLoc1, CHANNELBIT
		bsf ADC_CONTROLPORT, ADDR0
	if (high MainSelect)
		movlw high MainSelect			;Prepare for jump
		movwf PCLATH
	else
		clrf PCLATH
	endif
	movf gbl_configLoc1, w				;Put configuration in WREG
	andlw ((1<<FREQMODEBIT3)|(1<<FREQMODEBIT2)|(1<<FREQMODEBIT1)|(1<<FREQMODEBIT0))	;Unmask FreqMode
	movwf gbl_modetemp					;Multiply by 3
	bcf STATUS, C
	rlf gbl_modetemp, f
	addwf gbl_modetemp, w				; and put the result into W register for later computed jump
	bcf ADC_PORT, CS					;Select MAX118
	btfss gbl_configLoc1, TRIGGERENBIT	;Decide if trigger is enabled.  If so, wait on interrupt
		goto MainSelect
MainWaitTrig							;Trigger is enabled, set up interrupt
	movwf gbl_modetemp					;Store the jump for main select (freqmode)
	incf b0_triggerDelay3, w			;Get the trigger delay ready
	movwf gbl_cntra
	incf b0_triggerDelay2, w	
	movwf gbl_cntrb
	incf b0_triggerDelay1, w
	movwf gbl_cntrc
	banksel OPTION_REG
	bcf OPTION_REG, INTEDG				;Assume trigger on falling edge
	movf gbl_configLoc1, w				;Get the trigger status
	andlw (0x01 << TRIGGERPOSBIT)
	skipZero							;Positive or negative trigger
		bsf OPTION_REG, INTEDG			;Trigger on rising edge
	banksel	BANK0
	bcf INTCON, INTF					;Ensure that the RB0 interrupt flag is clear
	bsf	INTCON, INTE					;Enable the RB0 specific interrupt
	bsf INTCON, GIE						;Enable interrupts

MainWTrigB
	call WaitByte						;Wait for the trigger unless a "break trigger"
	skipEqLF B'11110011', gbl_spdata	;message is received
		goto MainWTrigB
	MOVLF B'11011100', gbl_spdata		;Respond
	call PutByte
	bcf	INTCON, INTE					;Disable the RB0 specific interrupt
	bcf INTCON, GIE						;Disable interrupts
	goto Main							;Abort

										;Note that the jitter on the interrupt is
										;1 cycles.  This translates to 200 ns
										;on the PIC running at 20 MHz

;=============================================================================
; S U B R O U T I N E S
;=============================================================================

;Wait for command from computer and respond accordingly
;-----------------------------------------------------------------------------
WaitComm
	call WaitByte						;Wait for receive
WaitComm_Test							;Determine the command and the response
	skipEqLF B'11111000', gbl_spdata
		goto WaitComm_Conf
WaitComm_Data
	MOVLF B'11011100', gbl_spdata		;Send beginning of message
	call PutByte
	MOVLF BUFFERMIN, FSR				;Set pointer to beginning of queue
	MOVLF BUFFERSIZE, gbl_cntrb			;Set counter

WaitComm_SendDataA
	MOVFF INDF, gbl_spdata				;Get data ready to send
	incf FSR, F							;Increment pointer
	call PutByte						;Send data
	decfsz gbl_cntrb, f
		goto WaitComm_SendDataA
	MOVLF BUFFERSIZE, gbl_cntrb			;Set counter
	bsf FSR, 7							;Bank 1
	decf FSR, f
WaitComm_SendDataB
	MOVFF INDF, gbl_spdata				;Get data ready to send
	decf FSR, F							;Increment pointer
	call PutByte						;Send data
	decfsz gbl_cntrb, f
		goto WaitComm_SendDataB
	MOVLF BUFFERSIZE, gbl_cntrb			;Set counter
	bsf STATUS, IRP						;Bank 3
	incf FSR, f
WaitComm_SendDataC
	MOVFF INDF, gbl_spdata				;Get data ready to send
	incf FSR, F							;Increment pointer
	call PutByte						;Send data
	decfsz gbl_cntrb, f
		goto WaitComm_SendDataC
	MOVLF BUFFERSIZE, gbl_cntrb			;Set counter
	bcf FSR, 7							;Bank 2
	decf FSR, f
WaitComm_SendDataD
	MOVFF INDF, gbl_spdata				;Get data ready to send
	decf FSR, F							;Increment pointer
	call PutByte						;Send data
	decfsz gbl_cntrb, f
		goto WaitComm_SendDataD
WaitComm_SendDataExit
	bcf FSR, 7							;Bank 0
	bcf STATUS, IRP
	CHANNELCONFSEND
	goto WaitComm

WaitComm_Conf
	skipEqLF B'11111001', gbl_spdata
		goto WaitComm_Rec
	MOVLF B'11011101', gbl_spdata		;Send beginning of message
	call PutByte	
	CONFSEND
	goto WaitComm

WaitComm_Rec
	skipEqLF B'11111010', gbl_spdata
;		goto WaitComm					;No valid message sent
		goto WaitComm_Break
	MOVLF B'11011110', gbl_spdata		;Send beginning of message
	call PutByte
	CONFRECEIVE
	return

WaitComm_Break
	skipEqLF B'11110011', gbl_spdata
		goto WaitComm					;No valid message sent
	MOVLF B'11011100', gbl_spdata		;Send ack for trigger break
	call PutByte
	return


;WaitByte is used to wait for a byte on the serial port
;------------------------------------------------------------------------------
WaitByte

;GetByte is used to receive a byte on the serial port
;------------------------------------------------------------------------------
GetByte
GetByteSerial
	bsf RCSTA, CREN						;Enable receive (start listening to the serial port)
	btfss PIR1, RCIF			
		goto GetByteSerial
GetByteSerialB
	btfss RCSTA, FERR					;Handle the frame error
		goto GetByteSerialC
	movf RCREG, w						;Throw away data with errors
	goto GetByteSerial
GetByteSerialC
	btfss RCSTA, OERR					;Handle the over run error
		goto GetByteSerialE
	bcf RCSTA, CREN						;Reset the receive logic
	bsf RCSTA, CREN
GetByteSerialD
	movf RCREG, w						;Throw away data with errors
	btfsc PIR1, RCIF
		goto GetByteSerialD
	goto GetByteSerial
GetByteSerialE							;No errors if we got here	
	MOVFF RCREG, gbl_spdata				;Read byte from serial FIFO
	bcf RCSTA, CREN						;Disable receive (ignore serial port until I want to hear from it)
	retlw 0
	
;PutByte is used to put a byte on the serial port
;------------------------------------------------------------------------------
PutByte
PutByteSerial
	btfss PIR1, TXIF
		goto PutByteSerial
	MOVFF gbl_spdata, TXREG
	retlw 0

;Delay used to adjust sample rate
;Any delay due to using a call must be added (i.e. delay doesn't include call
;statement)
;Delay = 5+7*(gbl_cntrb:gbl_cntra)+3*gbl_cntrb if gbl_cntra > 0, gbl_cntrb >= 0
;If gbl_cntra = 0 then delay as if gbl_cntra = 256
;If gbl_cntrb:gbl_cntra = 0x0000 then Delay as if gbl_cntrb = 255, gbl_cntra = 256
;-----------------------------------------------------------------------------
Delay
	movlw 0x01
DelayLoop
	subwf gbl_cntra, F
	btfss STATUS, C
		subwf gbl_cntrb, F
	movf gbl_cntra, F
	skipZero
		goto DelayLoop
	movf gbl_cntrb, F
	skipZero
		goto DelayLoop
	return

;ADCShutdown, shutsdown the MAX118
;-----------------------------------------------------------------------------
ADCShutdown
	movwf INDF							;Save to QUEUE
	bsf ADC_PORT, CS					;Unselect MAX118
	bcf STATUS, IRP						;Set bank = 0
	CHANNELCONFSTORE
	goto Main

;Sample Delayed
;Sampling rate = 5e6 / (19 + 7 * SAMPLERATE1:SAMPLERATE2 + 3 * SAMPLERATE1) with 20 MHz clock
;Sampling rate = 1e6 / (19 + 7 * SAMPLERATE1:SAMPLERATE2 + 3 * SAMPLERATE1) with 4 MHz clock
;-----------------------------------------------------------------------------
SampleDelayed
	bcf ADC_CONTROLPORT, RDD			;Begin Conversion
	MOVLF BUFFERSIZE-1, gbl_cntrc		;Initialize counter, use gbl_cntrc as counter
	MOVLF BUFFERMIN, FSR				;Initialize pointer
	MOVFF gbl_sampleRate2, gbl_cntra	;Restore gbl_cntra
	MOVFF gbl_sampleRate1, gbl_cntrb	;Restore gbl_cntrb
	nop
	call Delay
SampleDelayedLoopA
	movf ADC_DATAPORT, W				;Sample
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	movwf INDF							;Save to QUEUE
	incf FSR, F							;Increment QUEUE pointer
StSampleDelayedLoopA
	MOVFF gbl_sampleRate2, gbl_cntra	;Restore gbl_cntra
	MOVFF gbl_sampleRate1, gbl_cntrb	;Restore gbl_cntrb
	call Delay
	decfsz gbl_cntrc, F					;Increment counter, 64 samples?
		goto SampleDelayedLoopA
	nop
	movf ADC_DATAPORT, W				;Last sample in Bank 1
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	movwf INDF							;Save to QUEUE
	bsf FSR, 7							;Move QUEUE pointer to Bank 2
	MOVLF BUFFERSIZE-1, gbl_cntrc
	MOVFF gbl_sampleRate2, gbl_cntra	;Restore gbl_cntra
	MOVFF gbl_sampleRate1, gbl_cntrb	;Restore gbl_cntrb
	call Delay
	nop
SampleDelayedLoopB
	movf ADC_DATAPORT, W				;Sample
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	movwf INDF							;Save to QUEUE
	decf FSR, F							;Increment QUEUE pointer
	MOVFF gbl_sampleRate2, gbl_cntra	;Restore gbl_cntra
	MOVFF gbl_sampleRate1, gbl_cntrb	;Restore gbl_cntrb
	call Delay
	decfsz gbl_cntrc, F					;Increment counter, 64 samples?
		goto SampleDelayedLoopB
	nop
	movf ADC_DATAPORT, W				;Last sample in Bank 2
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	movwf INDF							;Save to QUEUE
	bsf STATUS, IRP						;Move QUEUE pointer to Bank 4
	MOVLF BUFFERSIZE-1, gbl_cntrc
	MOVFF gbl_sampleRate2, gbl_cntra	;Restore gbl_cntra
	MOVFF gbl_sampleRate1, gbl_cntrb	;Restore gbl_cntrb
	call Delay
	nop
SampleDelayedLoopC
	movf ADC_DATAPORT, W				;Sample
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	movwf INDF							;Save to QUEUE
	incf FSR, F							;Increment QUEUE pointer
	MOVFF gbl_sampleRate2, gbl_cntra	;Restore gbl_cntra
	MOVFF gbl_sampleRate1, gbl_cntrb	;Restore gbl_cntrb
	call Delay
	decfsz gbl_cntrc, F					;Increment counter, 64 samples?
		goto SampleDelayedLoopC
	nop
	movf ADC_DATAPORT, W				;Last sample in Bank 4
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	movwf INDF							;Save to QUEUE
	bcf FSR, 7							;Move QUEUE pointer to Bank 2
	MOVLF BUFFERSIZE-1, gbl_cntrc
	MOVFF gbl_sampleRate2, gbl_cntra	;Restore gbl_cntra
	MOVFF gbl_sampleRate1, gbl_cntrb	;Restore gbl_cntrb
	call Delay
	nop
SampleDelayedLoopD
	movf ADC_DATAPORT, W				;Sample
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	movwf INDF							;Save to QUEUE
	decf FSR, F							;Increment QUEUE pointer
	MOVFF gbl_sampleRate2, gbl_cntra	;Restore gbl_cntra
	MOVFF gbl_sampleRate1, gbl_cntrb	;Restore gbl_cntrb
	call Delay
	decfsz gbl_cntrc, F					;Increment counter, 64 samples?
		goto SampleDelayedLoopD
	nop
	movf ADC_DATAPORT, W				;Last sample
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf PCLATH, 3						;insure correct program memory page
	bcf PCLATH, 4
	goto ADCShutdown

;SampleXYDelayed
;Sampling rate = 5e6 / (26 + 7 * SAMPLERATE1:SAMPLERATE2 + 3 * SAMPLERATE1) with 20 MHz clock
;Sampling rate = 5e6 / (26 + 7 * SAMPLERATE1:SAMPLERATE2 + 3 * SAMPLERATE1) with 4 MHz clock
;SampleXYDelayed does not sample X and Y at the same time.  Y is sampled 6 clock cycles
;behind X.  For a 20 MHz clock this is 1.2 uS, for a 4 MHz clock this is 6 uS.
;-----------------------------------------------------------------------------
SampleXYDelayed
	bcf ADC_CONTROLPORT, RDD			;Begin Conversion
	bsf ADC_CONTROLPORT, ADDR0			;Set channel to Y
	MOVLF BUFFERMIN, FSR				;Initialize pointer
	movf ADC_DATAPORT, W				;Sample X
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	bcf ADC_CONTROLPORT, ADDR0			;Set channel to X
	movwf INDF							;Save to QUEUE
	incf FSR, F							;Increment QUEUE pointer
	MOVLF BUFFERSIZE/2-1, gbl_cntrc		;Initialize counter, use gbl_cntrc as counter
	MOVFF gbl_sampleRate2, gbl_cntra	;Restore gbl_cntra
	MOVFF gbl_sampleRate1, gbl_cntrb	;Restore gbl_cntrb
	call Delay
	nop
SampleXYDelayedLA
	movf ADC_DATAPORT, W				;Sample Y
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	bsf ADC_CONTROLPORT, ADDR0			;Set channel to Y
	movwf INDF							;Save to QUEUE
	incf FSR, F							;Increment QUEUE pointer
	movf ADC_DATAPORT, W				;Sample X
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	bcf ADC_CONTROLPORT, ADDR0			;Set channel to X
	movwf INDF							;Save to QUEUE
	incf FSR, F							;Increment QUEUE pointer
	MOVFF gbl_sampleRate2, gbl_cntra	;Restore gbl_cntra
	MOVFF gbl_sampleRate1, gbl_cntrb	;Restore gbl_cntrb
	call Delay
	decfsz gbl_cntrc, F					;Increment counter, 64 samples?
		goto SampleXYDelayedLA
	nop
	movf ADC_DATAPORT, W				;Sample Y, last in Bank 1
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	bsf ADC_CONTROLPORT, ADDR0			;Set channel to Y
	movwf INDF							;Save to QUEUE
	bsf FSR, 7							;Move QUEUE pointer to Bank 2
	movf ADC_DATAPORT, W				;Sample X
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	bcf ADC_CONTROLPORT, ADDR0			;Set channel to X
	movwf INDF							;Save to QUEUE
	decf FSR, f							;Increment QUEUE pointer
	MOVLF BUFFERSIZE/2-1, gbl_cntrc		;Initialize counter, use gbl_cntrc as counter
	MOVFF gbl_sampleRate2, gbl_cntra	;Restore gbl_cntra
	MOVFF gbl_sampleRate1, gbl_cntrb	;Restore gbl_cntrb
	call Delay
	nop
SampleXYDelayedLB
	movf ADC_DATAPORT, W				;Sample Y
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	bsf ADC_CONTROLPORT, ADDR0			;Set channel to Y
	movwf INDF							;Save to QUEUE
	decf FSR, F							;Increment QUEUE pointer
	movf ADC_DATAPORT, W				;Sample X
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	bcf ADC_CONTROLPORT, ADDR0			;Set channel to X
	movwf INDF							;Save to QUEUE
	decf FSR, F							;Increment QUEUE pointer
	MOVFF gbl_sampleRate2, gbl_cntra	;Restore gbl_cntra
	MOVFF gbl_sampleRate1, gbl_cntrb	;Restore gbl_cntrb
	call Delay
	decfsz gbl_cntrc, F					;Increment counter, 64 samples?
		goto SampleXYDelayedLB
	nop
	movf ADC_DATAPORT, W				;Sample Y, last in Bank 2
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	bsf ADC_CONTROLPORT, ADDR0			;Set channel to Y
	movwf INDF							;Save to QUEUE
	bsf STATUS, IRP						;Move QUEUE pointer to Bank 4
	movf ADC_DATAPORT, W				;Sample X
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	bcf ADC_CONTROLPORT, ADDR0			;Set channel to X
	movwf INDF							;Save to QUEUE
	incf FSR, f							;Increment QUEUE pointer
	MOVLF BUFFERSIZE/2-1, gbl_cntrc		;Initialize counter, use gbl_cntrc as counter
	MOVFF gbl_sampleRate2, gbl_cntra	;Restore gbl_cntra
	MOVFF gbl_sampleRate1, gbl_cntrb	;Restore gbl_cntrb
	call Delay
	nop
SampleXYDelayedLC
	movf ADC_DATAPORT, W				;Sample Y
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	bsf ADC_CONTROLPORT, ADDR0			;Set channel to Y
	movwf INDF							;Save to QUEUE
	incf FSR, F							;Increment QUEUE pointer
	movf ADC_DATAPORT, W				;Sample X
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	bcf ADC_CONTROLPORT, ADDR0			;Set channel to X
	movwf INDF							;Save to QUEUE
	incf FSR, F							;Increment QUEUE pointer
	MOVFF gbl_sampleRate2, gbl_cntra	;Restore gbl_cntra
	MOVFF gbl_sampleRate1, gbl_cntrb	;Restore gbl_cntrb
	call Delay
	decfsz gbl_cntrc, F					;Increment counter, 64 samples?
		goto SampleXYDelayedLC
	nop
	movf ADC_DATAPORT, W				;Sample Y, last in Bank 4
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	bsf ADC_CONTROLPORT, ADDR0			;Set channel to Y
	movwf INDF							;Save to QUEUE
	bcf FSR, 7							;Move QUEUE pointer to Bank 3
	movf ADC_DATAPORT, W				;Sample X
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	bcf ADC_CONTROLPORT, ADDR0			;Set channel to X
	movwf INDF							;Save to QUEUE
	decf FSR, f							;Increment QUEUE pointer
	MOVLF BUFFERSIZE/2-1, gbl_cntrc		;Initialize counter, use gbl_cntrc as counter
	MOVFF gbl_sampleRate2, gbl_cntra	;Restore gbl_cntra
	MOVFF gbl_sampleRate1, gbl_cntrb	;Restore gbl_cntrb
	call Delay
	nop
SampleXYDelayedLD
	movf ADC_DATAPORT, W				;Sample Y
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	bsf ADC_CONTROLPORT, ADDR0			;Set channel to Y
	movwf INDF							;Save to QUEUE
	decf FSR, F							;Increment QUEUE pointer
	movf ADC_DATAPORT, W				;Sample X
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	bcf ADC_CONTROLPORT, ADDR0			;Set channel to X
	movwf INDF							;Save to QUEUE
	decf FSR, F							;Increment QUEUE pointer
	MOVFF gbl_sampleRate2, gbl_cntra	;Restore gbl_cntra
	MOVFF gbl_sampleRate1, gbl_cntrb	;Restore gbl_cntrb
	call Delay
	decfsz gbl_cntrc, F					;Increment counter, 64 samples?
		goto SampleXYDelayedLD
	nop
	movf ADC_DATAPORT, W				;Sample Y, last in Bank 3
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf PCLATH, 3						;insure correct program memory page
	bcf PCLATH, 4
	goto ADCShutdown

;Fast sample
;Sampling rate = 625 kHz with 20 MHz clock
;Sampling rate = 125 kHz with 4 MHz clock
;-----------------------------------------------------------------------------
Sample625k
	bcf ADC_CONTROLPORT, RDD			;Begin Conversion
	MOVLF BUFFERSIZE-1, gbl_cntra		;Initialize counter
	MOVLF BUFFERMIN, FSR				;Initialize pointer
	nop
Sample625kLoopA
	movf ADC_DATAPORT, W				;Sample
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	movwf INDF							;Save to QUEUE
	incf FSR, F							;Increment QUEUE pointer
	decfsz gbl_cntra, F					;Increment counter, 64 samples?
		goto Sample625kLoopA
	nop
	movf ADC_DATAPORT, w				;Last sample in Bank 1
	bsf ADC_CONTROLPORT, RDD			;stop conversion
	bcf ADC_CONTROLPORT, RDD			;begin next conversion
	movwf INDF							;Save to QUEUE
	bsf FSR, 7							;Move QUEUE pointer to Bank 2
	MOVLF BUFFERSIZE-1, gbl_cntra
	nop
Sample625kLoopB
	movf ADC_DATAPORT, W				;Sample
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	movwf INDF							;Save to QUEUE
	decf FSR, F							;Increment QUEUE pointer
	decfsz gbl_cntra, F					;Increment counter, 64 samples?
		goto Sample625kLoopB
	nop
	movf ADC_DATAPORT, w				;Last sample in Bank 2
	bsf ADC_CONTROLPORT, RDD			;stop conversion
	bcf ADC_CONTROLPORT, RDD			;begin next conversion
	movwf INDF							;Save to QUEUE
	bsf STATUS, IRP						;Move QUEUE pointer to Bank 4
	MOVLF BUFFERSIZE-1, gbl_cntra
	nop
Sample625kLoopC
	movf ADC_DATAPORT, W				;Sample
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	movwf INDF							;Save to QUEUE
	incf FSR, F							;Increment QUEUE pointer
	decfsz gbl_cntra, F					;Increment counter, 64 samples?
		goto Sample625kLoopC
	nop
	movf ADC_DATAPORT, w				;Last sample in Bank 4
	bsf ADC_CONTROLPORT, RDD			;stop conversion
	bcf ADC_CONTROLPORT, RDD			;begin next conversion
	movwf INDF							;Save to QUEUE
	bcf FSR, 7							;Move QUEUE pointer to Bank 3
	MOVLF BUFFERSIZE-1, gbl_cntra
	nop
Sample625kLoopD
	movf ADC_DATAPORT, W				;Sample
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	movwf INDF							;Save to QUEUE
	decf FSR, F							;Increment QUEUE pointer
	decfsz gbl_cntra, F					;Increment counter, 64 samples?
		goto Sample625kLoopD
	nop
	movf ADC_DATAPORT, W				;Last sample
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf PCLATH, 3						;insure correct program memory page
	bcf PCLATH, 4
	goto ADCShutdown

;Fast sample
;Sampling rate = 416.667 kHz with 20 MHz clock
;Sampling rate =  83.333 kHz with 4 MHz clock
;or
;Sampling rate = 250 kHz with 20 MHz clock
;Sampling rate =  50 kHz with 4 MHz clock
;-----------------------------------------------------------------------------
Sample417k250k
	bcf ADC_CONTROLPORT, RDD			;Begin Conversion
	MOVLF BUFFERSIZE - 1, gbl_cntra		;Initialize counter
	MOVLF BUFFERMIN, FSR				;Initialize pointer
	goto $ + 1							;Delay 3
	btfss gbl_configLoc1, 2				;Choose to delay by 3 more or by 11 more
		goto Sample417kLoopA
	call DelaySeven						;Delay 9 cycles
Sample417kLoopA
	movf ADC_DATAPORT, W				;Sample
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	movwf INDF							;Save to QUEUE
	incf FSR, F							;Increment QUEUE pointer
	btfss gbl_configLoc1, 2				;Choose to delay 4 cycles or 12 cycles depending on mode
		goto Sample417kA				;Delaying 4 cycles, sample at 417k
Sample250kA
	call DelaySeven						;Delay 9 cycles
Sample417kA
	nop
	decfsz gbl_cntra, F					;Increment counter, 64 samples?
		goto Sample417kLoopA
	nop
	movf ADC_DATAPORT, W				;Last sample bank 1
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	movwf INDF							;Save to QUEUE
	bsf FSR, 7							;Goto bank 2
	MOVLF BUFFERSIZE - 1, gbl_cntra		;Reinitialize counter
	goto $ + 1
	btfss gbl_configLoc1, 2				;Choose to delay 5 cycles or 13 cycles depending on mode
		goto Sample417kLoopB			;Delaying  cycles, sample at 417k
	call DelaySeven						;Delay 9 cycles
Sample417kLoopB
	movf ADC_DATAPORT, W				;Sample
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	movwf INDF							;Save to QUEUE
	decf FSR, F							;Increment QUEUE pointer
StSample417kLoopB
	btfss gbl_configLoc1, 2				;Choose to delay 4 cycles or 12 cycles depending on mode
		goto Sample417kB				;Delaying 4 cycles, sample at 417k
Sample250kB
	call DelaySeven						;Delay 9 cycles
Sample417kB
	nop
	decfsz gbl_cntra, F					;Increment counter, 64 samples?
		goto Sample417kLoopB
	nop
	movf ADC_DATAPORT, W				;Last sample bank 2
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	movwf INDF							;Save to QUEUE
	bsf STATUS, IRP						;Goto bank 4
	MOVLF BUFFERSIZE - 1, gbl_cntra		;Reinitialize counter
	goto $ + 1
	btfss gbl_configLoc1, 2				;Choose to delay 5 cycles or 13 cycles depending on mode
		goto Sample417kLoopC			;Delaying  cycles, sample at 417k
	call DelaySeven						;Delay 9 cycles
Sample417kLoopC
	movf ADC_DATAPORT, W				;Sample
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	movwf INDF							;Save to QUEUE
	incf FSR, F							;Increment QUEUE pointer
StSample417kLoopC
	btfss gbl_configLoc1, 2				;Choose to delay 4 cycles or 12 cycles depending on mode
		goto Sample417kC				;Delaying 4 cycles, sample at 417k
Sample250kC
	call DelaySeven						;Delay 9 cycles
Sample417kC
	nop
	decfsz gbl_cntra, F					;Increment counter, 64 samples?
		goto Sample417kLoopC
	nop
	movf ADC_DATAPORT, W				;Last sample bank 4
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	movwf INDF							;Save to QUEUE
	bcf FSR, 7							;Goto bank 3
	MOVLF BUFFERSIZE - 1, gbl_cntra		;Reinitialize counter
	goto $ + 1
	btfss gbl_configLoc1, 2				;Choose to delay 5 cycles or 13 cycles depending on mode
		goto Sample417kLoopD			;Delaying  cycles, sample at 417k
	call DelaySeven						;Delay 9 cycles
Sample417kLoopD
	movf ADC_DATAPORT, W				;Sample
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	movwf INDF							;Save to QUEUE
	decf FSR, F							;Increment QUEUE pointer
StSample417kLoopD
	btfss gbl_configLoc1, 2				;Choose to delay 4 cycles or 12 cycles depending on mode
		goto Sample417kD				;Delaying 4 cycles, sample at 417k
Sample250kD
	call DelaySeven						;Delay 9 cycles
Sample417kD
	nop
	decfsz gbl_cntra, F					;Increment counter, 64 samples?
		goto Sample417kLoopD
	nop
	movf ADC_DATAPORT, W				;Last sample
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf PCLATH, 3						;insure correct program memory page
	bcf PCLATH, 4
	goto ADCShutdown

;Delay Seven Cycles, helper to Sample417k250k
DelaySeven
	goto $ + 1							;7
;Delay Five Cycles, helper to SampleXY250k192k
DelayFive
	nop									;5
	goto $ + 1						
;Delay Two Cycles, helper to SampleXY250k192k
DelayTwo
	return								;2


;Fast sample XY
;Sampling rate = 250 kHz with 20 MHz clock
SampleXY250k192k
	bcf ADC_CONTROLPORT, RDD			;Begin Conversion
	bsf ADC_CONTROLPORT, ADDR0			;Set channel to Y
	MOVLF BUFFERMIN, FSR				;Initialize pointer
	movf ADC_DATAPORT, W				;Sample X
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	bcf ADC_CONTROLPORT, ADDR0			;Set channel to X
	movwf INDF							;Save to QUEUE
	incf FSR, F							;Increment QUEUE pointer
	MOVLF BUFFERSIZE/2-1, gbl_cntrc		;Initialize counter, use gbl_cntrc as counter
	btfss gbl_configLoc1, 0				;Delay 250k or 192k
		call DelayFive					;192k
	call DelayTwo
SampleXY250kLA
	movf ADC_DATAPORT, W				;Sample Y
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	bsf ADC_CONTROLPORT, ADDR0			;Set channel to Y
	movwf INDF							;Save to QUEUE
	incf FSR, F							;Increment QUEUE pointer
	movf ADC_DATAPORT, W				;Sample X
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	bcf ADC_CONTROLPORT, ADDR0			;Set channel to X
	movwf INDF							;Save to QUEUE
	incf FSR, F							;Increment QUEUE pointer
	btfss gbl_configLoc1, 0				;Delay 250k or 192k
		call DelayFive					;192k
	goto $ + 1
	nop
	decfsz gbl_cntrc, F					;Increment counter, 64 samples?
		goto SampleXY250kLA
	nop
	movf ADC_DATAPORT, W				;Sample Y, last in Bank 1
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	bsf ADC_CONTROLPORT, ADDR0			;Set channel to Y
	movwf INDF							;Save to QUEUE
	bsf FSR, 7							;Move QUEUE pointer to Bank 2
	movf ADC_DATAPORT, W				;Sample X
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	bcf ADC_CONTROLPORT, ADDR0			;Set channel to X
	movwf INDF							;Save to QUEUE
	decf FSR, f							;Increment QUEUE pointer
	MOVLF BUFFERSIZE/2-1, gbl_cntrc		;Initialize counter, use gbl_cntrc as counter
	btfss gbl_configLoc1, 0				;Delay 250k or 192k
		call DelayFive					;192k
	call DelayTwo
SampleXY250kLB
	movf ADC_DATAPORT, W				;Sample Y
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	bsf ADC_CONTROLPORT, ADDR0			;Set channel to Y
	movwf INDF							;Save to QUEUE
	decf FSR, F							;Increment QUEUE pointer
	movf ADC_DATAPORT, W				;Sample X
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	bcf ADC_CONTROLPORT, ADDR0			;Set channel to X
	movwf INDF							;Save to QUEUE
	decf FSR, F							;Increment QUEUE pointer
	btfss gbl_configLoc1, 0				;Delay 250k or 192k
		call DelayFive					;192k
	goto $ + 1
	nop
	decfsz gbl_cntrc, F					;Increment counter, 64 samples?
		goto SampleXY250kLB
	nop
	movf ADC_DATAPORT, W				;Sample Y, last in Bank 2
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	bsf ADC_CONTROLPORT, ADDR0			;Set channel to Y
	movwf INDF							;Save to QUEUE
	bsf STATUS, IRP						;Move QUEUE pointer to Bank 4
	movf ADC_DATAPORT, W				;Sample X
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	bcf ADC_CONTROLPORT, ADDR0			;Set channel to X
	movwf INDF							;Save to QUEUE
	incf FSR, f							;Increment QUEUE pointer
	MOVLF BUFFERSIZE/2-1, gbl_cntrc		;Initialize counter, use gbl_cntrc as counter
	btfss gbl_configLoc1, 0				;Delay 250k or 192k
		call DelayFive					;192k
	call DelayTwo
SampleXY250kLC
	movf ADC_DATAPORT, W				;Sample Y
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	bsf ADC_CONTROLPORT, ADDR0			;Set channel to Y
	movwf INDF							;Save to QUEUE
	incf FSR, F							;Increment QUEUE pointer
	movf ADC_DATAPORT, W				;Sample X
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	bcf ADC_CONTROLPORT, ADDR0			;Set channel to X
	movwf INDF							;Save to QUEUE
	incf FSR, F							;Increment QUEUE pointer
	btfss gbl_configLoc1, 0				;Delay 250k or 192k
		call DelayFive					;192k
	goto $ + 1
	nop
	decfsz gbl_cntrc, F					;Increment counter, 64 samples?
		goto SampleXY250kLC
	nop
	movf ADC_DATAPORT, W				;Sample Y, last in Bank 4
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	bsf ADC_CONTROLPORT, ADDR0			;Set channel to Y
	movwf INDF							;Save to QUEUE
	bcf FSR, 7							;Move QUEUE pointer to Bank 3
	movf ADC_DATAPORT, W				;Sample X
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	bcf ADC_CONTROLPORT, ADDR0			;Set channel to X
	movwf INDF							;Save to QUEUE
	decf FSR, f							;Increment QUEUE pointer
	MOVLF BUFFERSIZE/2-1, gbl_cntrc		;Initialize counter, use gbl_cntrc as counter
	btfss gbl_configLoc1, 0				;Delay 250k or 192k
		call DelayFive					;192k
	call DelayTwo
SampleXY250kLD
	movf ADC_DATAPORT, W				;Sample Y
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	bsf ADC_CONTROLPORT, ADDR0			;Set channel to Y
	movwf INDF							;Save to QUEUE
	decf FSR, F							;Increment QUEUE pointer
	movf ADC_DATAPORT, W				;Sample X
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	bcf ADC_CONTROLPORT, ADDR0			;Set channel to X
	movwf INDF							;Save to QUEUE
	decf FSR, F							;Increment QUEUE pointer
	btfss gbl_configLoc1, 0				;Delay 250k or 192k
		call DelayFive					;192k
	goto $ + 1
	nop
	decfsz gbl_cntrc, F					;Increment counter, 64 samples?
		goto SampleXY250kLD
	nop
	movf ADC_DATAPORT, W				;Sample Y, last in Bank 3
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf PCLATH, 3						;insure correct program memory page
	bcf PCLATH, 4
	goto ADCShutdown

;Fastest sample
;Sampling rate = 1 MHz with 20 MHz clock
;Sampling rate = 200 kHz with 4 MHz clock
;-----------------------------------------------------------------------------
Sample1M
	bcf ADC_CONTROLPORT, RDD			;Begin Conversion
	MOVLF BUFFERMIN, FSR				;Initialize pointer
	nop
	local count
	count = 1
	while count < BUFFERSIZE
		bsf ADC_CONTROLPORT, RDD		;Latch Conversion into SPP
		bcf ADC_CONTROLPORT, RDD		;Start next conversion
		movf ADC_DATAPORT, W			;Save Sample
		movwf INDF						;Save to QUEUE
		incf FSR, F						;Increment QUEUE pointer
		count = count + 1
	endw
	bsf ADC_CONTROLPORT, RDD			;Latch Conversion into SPP
	bcf ADC_CONTROLPORT, RDD			;Start next conversion
	movf ADC_DATAPORT, W
	movwf INDF
	bsf FSR, 7							;goto bank 2
	count = 1
	while count < BUFFERSIZE
		bsf ADC_CONTROLPORT, RDD		;Stop conversion
		bcf ADC_CONTROLPORT, RDD		;Begin next conversion
		movf ADC_DATAPORT, W			;Sample
		movwf INDF						;Save to QUEUE
		decf FSR, F						;Increment QUEUE pointer
		count = count + 1
	endw
	bsf ADC_CONTROLPORT, RDD
	bcf ADC_CONTROLPORT, RDD
	movf ADC_DATAPORT, W
	movwf INDF
	bsf STATUS, IRP						;goto bank 4
	count = 1
	while count < BUFFERSIZE
		bsf ADC_CONTROLPORT, RDD		;Stop conversion
		bcf ADC_CONTROLPORT, RDD		;Begin next conversion
		movf ADC_DATAPORT, W			;Sample
		movwf INDF						;Save to QUEUE
		incf FSR, F						;Increment QUEUE pointer
		count = count + 1
	endw
	bsf ADC_CONTROLPORT, RDD
	bcf ADC_CONTROLPORT, RDD
	movf ADC_DATAPORT, W				;Sample
	movwf INDF
	bcf FSR, 7							;goto bank 3
	count = 1
	while count < D'14'
		bsf ADC_CONTROLPORT, RDD		;Stop conversion
		bcf ADC_CONTROLPORT, RDD		;Begin next conversion
		movf ADC_DATAPORT, W
		movwf INDF						;Save to QUEUE
		decf FSR, F						;Increment QUEUE pointer
		count = count + 1
	endw
Sample1MhzEnd
	while count < BUFFERSIZE
		bsf ADC_CONTROLPORT, RDD		;Stop conversion
		bcf ADC_CONTROLPORT, RDD		;Begin next conversion
		movf ADC_DATAPORT, W
		movwf INDF						;Save to QUEUE
		decf FSR, F						;Increment QUEUE pointer
		count = count + 1
	endw
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	movf ADC_DATAPORT, W				;Sample
	bcf PCLATH, 3						;insure correct program memory page
	bcf PCLATH, 4
	goto ADCShutdown

;Fastest XY sample
;Sampling rate = 416.667 kHz with 20 MHz clock
;Sampling rate =  83.333 kHz with 4 MHz clock
SampleXY417k
	bcf ADC_CONTROLPORT, RDD			;Begin Conversion
	bsf ADC_CONTROLPORT, ADDR0			;Set channel to Y
	MOVLF BUFFERMIN, FSR				;Initialize pointer
	movf ADC_DATAPORT, W				;Sample X
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	bcf ADC_CONTROLPORT, ADDR0			;Set channel to X
	movwf INDF							;Save to QUEUE
	incf FSR, F							;Increment QUEUE pointer
	count = 1
	while count < BUFFERSIZE / 2
		movf ADC_DATAPORT, W			;Sample Y
		bsf ADC_CONTROLPORT, RDD		;Stop conversion
		bcf ADC_CONTROLPORT, RDD		;Begin next conversion
		bsf ADC_CONTROLPORT, ADDR0		;Set channel to Y
		movwf INDF						;Save to QUEUE
		incf FSR, F						;Increment QUEUE pointer
		movf ADC_DATAPORT, W			;Sample X
		bsf ADC_CONTROLPORT, RDD		;Stop conversion
		bcf ADC_CONTROLPORT, RDD		;Begin next conversion
		bcf ADC_CONTROLPORT, ADDR0		;Set channel to X
		movwf INDF						;Save to QUEUE
		incf FSR, F						;Increment QUEUE pointer
		count = count + 1
	endw
	movf ADC_DATAPORT, W				;Sample Y, last in Bank 1
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	bsf ADC_CONTROLPORT, ADDR0			;Set channel to Y
	movwf INDF							;Save to QUEUE
	bsf FSR, 7							;Move QUEUE pointer to Bank 2
	movf ADC_DATAPORT, W				;Sample X
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	bcf ADC_CONTROLPORT, ADDR0			;Set channel to X
	movwf INDF							;Save to QUEUE
	decf FSR, f							;Increment QUEUE pointer
	count = 1
	while count < BUFFERSIZE / 2
		movf ADC_DATAPORT, W			;Sample Y
		bsf ADC_CONTROLPORT, RDD		;Stop conversion
		bcf ADC_CONTROLPORT, RDD		;Begin next conversion
		bsf ADC_CONTROLPORT, ADDR0		;Set channel to Y
		movwf INDF						;Save to QUEUE
		decf FSR, F						;Increment QUEUE pointer
		movf ADC_DATAPORT, W			;Sample X
		bsf ADC_CONTROLPORT, RDD		;Stop conversion
		bcf ADC_CONTROLPORT, RDD		;Begin next conversion
		bcf ADC_CONTROLPORT, ADDR0		;Set channel to X
		movwf INDF						;Save to QUEUE
		decf FSR, F						;Increment QUEUE pointer
		count = count + 1
	endw
	movf ADC_DATAPORT, W				;Sample Y, last in Bank 2
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	bsf ADC_CONTROLPORT, ADDR0			;Set channel to Y
	movwf INDF							;Save to QUEUE
	bsf STATUS, IRP						;Move QUEUE pointer to Bank 4
	movf ADC_DATAPORT, W				;Sample X
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	bcf ADC_CONTROLPORT, ADDR0			;Set channel to X
	movwf INDF							;Save to QUEUE
	incf FSR, f							;Increment QUEUE pointer
	count = 1
	while count < BUFFERSIZE / 2
		movf ADC_DATAPORT, W			;Sample Y
		bsf ADC_CONTROLPORT, RDD		;Stop conversion
		bcf ADC_CONTROLPORT, RDD		;Begin next conversion
		bsf ADC_CONTROLPORT, ADDR0		;Set channel to Y
		movwf INDF						;Save to QUEUE
		incf FSR, F						;Increment QUEUE pointer
		movf ADC_DATAPORT, W			;Sample X
		bsf ADC_CONTROLPORT, RDD		;Stop conversion
		bcf ADC_CONTROLPORT, RDD		;Begin next conversion
		bcf ADC_CONTROLPORT, ADDR0		;Set channel to X
		movwf INDF						;Save to QUEUE
		incf FSR, F						;Increment QUEUE pointer
		count = count + 1
	endw
	movf ADC_DATAPORT, W				;Sample Y, last in Bank 4
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	bsf ADC_CONTROLPORT, ADDR0			;Set channel to Y
	movwf INDF							;Save to QUEUE
	bcf FSR, 7							;Move QUEUE pointer to Bank 3
	movf ADC_DATAPORT, W				;Sample X
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD			;Begin next conversion
	bcf ADC_CONTROLPORT, ADDR0			;Set channel to X
	movwf INDF							;Save to QUEUE
	decf FSR, f							;Increment QUEUE pointer
	count = 1
	while count < BUFFERSIZE / 2
		movf ADC_DATAPORT, W			;Sample Y
		bsf ADC_CONTROLPORT, RDD		;Stop conversion
		bcf ADC_CONTROLPORT, RDD		;Begin next conversion
		bsf ADC_CONTROLPORT, ADDR0		;Set channel to Y
		movwf INDF						;Save to QUEUE
		decf FSR, F						;Increment QUEUE pointer
		movf ADC_DATAPORT, W			;Sample X
		bsf ADC_CONTROLPORT, RDD		;Stop conversion
		bcf ADC_CONTROLPORT, RDD		;Begin next conversion
		bcf ADC_CONTROLPORT, ADDR0		;Set channel to X
		movwf INDF						;Save to QUEUE
		decf FSR, F						;Increment QUEUE pointer
		count = count + 1
	endw
	movf ADC_DATAPORT, W				;Sample Y, last in Bank 3
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf PCLATH, 3						;insure correct program memory page
	bcf PCLATH, 4
	goto ADCShutdown
	
;Fast sample
;Sampling rate = 833.333 kHz with 20 MHz clock
;Sampling rate = 166.667 kHz with 4 MHz clock
;-----------------------------------------------------------------------------
Sample833k
	bcf ADC_CONTROLPORT, RDD			;Begin Conversion
	MOVLF BUFFERMIN, FSR				;Initialize pointer
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
	movf ADC_DATAPORT, W
	bsf ADC_CONTROLPORT, RDD
	bcf ADC_CONTROLPORT, RDD
	movwf INDF
	bsf FSR, 7							;goto bank 2
	nop		 							;Wait a cycle
	count = 1
	while count < BUFFERSIZE
		movf ADC_DATAPORT, W			;Sample
		bsf ADC_CONTROLPORT, RDD		;Stop conversion
		bcf ADC_CONTROLPORT, RDD		;Begin next conversion
		movwf INDF						;Save to QUEUE
		decf FSR, F						;Increment QUEUE pointer
		nop								;Wait a cycle
		count = count + 1
	endw
	movf ADC_DATAPORT, W
	bsf ADC_CONTROLPORT, RDD
	bcf ADC_CONTROLPORT, RDD
	movwf INDF
	bsf STATUS, IRP						;goto bank 4
	nop		 							;Wait a cycle
	count = 1
	while count < D'44'
		movf ADC_DATAPORT, W			;Sample
		bsf ADC_CONTROLPORT, RDD		;Stop conversion
		bcf ADC_CONTROLPORT, RDD		;Begin next conversion
		movwf INDF						;Save to QUEUE
		incf FSR, F						;Increment QUEUE pointer
		nop								;Wait a cycle
		count = count + 1
	endw
Sample833kEnd
	while count < BUFFERSIZE
		movf ADC_DATAPORT, W			;Sample
		bsf ADC_CONTROLPORT, RDD		;Stop conversion
		bcf ADC_CONTROLPORT, RDD		;Begin next conversion
		movwf INDF						;Save to QUEUE
		incf FSR, F						;Increment QUEUE pointer
		nop								;Wait a cycle
		count = count + 1
	endw
	movf ADC_DATAPORT, W
	bsf ADC_CONTROLPORT, RDD
	bcf ADC_CONTROLPORT, RDD
	movwf INDF
	bcf FSR, 7							;goto bank 3
	nop		 							;Wait a cycle
	count = 1
	while count < BUFFERSIZE
		movf ADC_DATAPORT, W			;Sample
		bsf ADC_CONTROLPORT, RDD		;Stop conversion
		bcf ADC_CONTROLPORT, RDD		;Begin next conversion
		movwf INDF						;Save to QUEUE
		decf FSR, F						;Increment QUEUE pointer
		nop								;Wait a cycle
		count = count + 1
	endw
	movf ADC_DATAPORT, W				;Last sample
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf PCLATH, 3						;insure correct program memory page
	bcf PCLATH, 4
	goto ADCShutdown

;Repetitive sample
;Equivalent sampling rate = 5 MHz with 20 MHz clock
;-----------------------------------------------------------------------------
SampleRep5M
	movlw high SampleRep5MPickSt
	movwf PCLATH
	movf gbl_modetempb, w
	addwf PCL, f
SampleRep5MPickSt
	MGOTO SampleRep5MStep1
	MGOTO SampleRep5MStep2
	MGOTO SampleRep5MStep3
	MGOTO SampleRep5MStep4
	MGOTO SampleRep5MStep5
SampleRep5MPickEn
SampleRep5MStep1
	bcf ADC_CONTROLPORT, RDD		 	;Begin Conversion
	MOVLF BUFFERMIN, FSR				;Initialize pointer
	nop
	local count
	count = 1
	while count < D'52'
		bsf ADC_CONTROLPORT, RDD		;Latch Conversion into SPP
		bcf ADC_CONTROLPORT, RDD		;Start next conversion
		movf ADC_DATAPORT, W			;Save Sample
		movwf INDF						;Save to QUEUE
		incf FSR, F						;Increment QUEUE pointer
		count = count + 1
	endw
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	movf ADC_DATAPORT, W				;Sample
SampleRep5MEndA
	movwf INDF
	incf FSR, F
	goto SampleRep5MEndB
SampleRep5MEndC
	movwf INDF
	decf FSR, F
SampleRep5MEndB
	ADDLF D'3', gbl_modetempb, f
	bsf ADC_PORT, CS
	MGOTO MainB
	
SampleRep5MStep2
	nop
	bcf ADC_CONTROLPORT, RDD		 	;Begin Conversion
	goto $ + 1
	nop
	local count
	count = 1
	while count < D'12'
		bsf ADC_CONTROLPORT, RDD		;Latch Conversion into SPP
		bcf ADC_CONTROLPORT, RDD		;Start next conversion
		movf ADC_DATAPORT, W			;Save Sample
		movwf INDF						;Save to QUEUE
		incf FSR, F						;Increment QUEUE pointer
		count = count + 1
	endw
	bsf ADC_CONTROLPORT, RDD			;Latch Conversion into SPP
	bcf ADC_CONTROLPORT, RDD			;Start next conversion
	movf ADC_DATAPORT, W				;Sample
	movwf INDF
	bsf FSR, 7							;goto bank 2
	count = 1
	while count < D'39'
		bsf ADC_CONTROLPORT, RDD		;Stop conversion
		bcf ADC_CONTROLPORT, RDD		;Begin next conversion
		movf ADC_DATAPORT, W			;Sample
		movwf INDF						;Save to QUEUE
		decf FSR, F						;Increment QUEUE pointer
		count = count + 1
	endw
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	movf ADC_DATAPORT, W				;Sample
	MGOTO SampleRep5MEndC
	
SampleRep5MStep3
	goto $ + 1
	bcf ADC_CONTROLPORT, RDD		 	;Begin Conversion
	goto $ + 1
	nop
	local count
	count = 1
	while count < D'25'
		bsf ADC_CONTROLPORT, RDD		;Stop conversion
		bcf ADC_CONTROLPORT, RDD		;Begin next conversion
		movf ADC_DATAPORT, W			;Sample
		movwf INDF						;Save to QUEUE
		decf FSR, F						;Increment QUEUE pointer
		count = count + 1
	endw
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	bcf ADC_CONTROLPORT, RDD
	movf ADC_DATAPORT, W				;Sample
	movwf INDF
	bsf STATUS, IRP						;goto bank 4
	count = 1
	while count < D'26'
		bsf ADC_CONTROLPORT, RDD		;Stop conversion
		bcf ADC_CONTROLPORT, RDD		;Begin next conversion
		movf ADC_DATAPORT, W			;Sample
		movwf INDF						;Save to QUEUE
		incf FSR, F						;Increment QUEUE pointer
		count = count + 1
	endw
	bsf ADC_CONTROLPORT, RDD
	movf ADC_DATAPORT, W				;Sample
	MGOTO SampleRep5MEndA
	
SampleRep5MStep4
	goto $ + 1
	nop
	bcf ADC_CONTROLPORT, RDD		 	;Begin Conversion
	goto $ + 1
	nop
	local count
	count = 1
	while count < D'38'
		bsf ADC_CONTROLPORT, RDD		;Stop conversion
		bcf ADC_CONTROLPORT, RDD		;Begin next conversion
		movf ADC_DATAPORT, W			;Sample
		movwf INDF						;Save to QUEUE
		incf FSR, F						;Increment QUEUE pointer
		count = count + 1
	endw
	bsf ADC_CONTROLPORT, RDD
	bcf ADC_CONTROLPORT, RDD
	movf ADC_DATAPORT, W				;Sample
	movwf INDF
	bcf FSR, 7							;goto bank 3
	count = 1
	while count < D'13'
		bsf ADC_CONTROLPORT, RDD		;Stop conversion
		bcf ADC_CONTROLPORT, RDD		;Begin next conversion
		movf ADC_DATAPORT, W
		movwf INDF						;Save to QUEUE
		decf FSR, F						;Increment QUEUE pointer
		count = count + 1
	endw
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	movf ADC_DATAPORT, W				;Sample
	MGOTO SampleRep5MEndC

SampleRep5MStep5
	goto $ + 1
	if (Sample1MhzEnd & (0x1000))
		bsf PCLATH, 4
	else
		bcf PCLATH, 4
	endif
	if (Sample1MhzEnd & (0x800))
		bsf PCLATH, 3
	else
		bcf PCLATH, 3
	endif
	bcf ADC_CONTROLPORT, RDD		 	;Begin Conversion
	nop
	goto Sample1MhzEnd
	
;Repetitive sample
;Equivalent sampling rate = 2.5 MHz with 20 MHz clock
;-----------------------------------------------------------------------------
SampleRep2M
	movlw high SampleRep2MPickSt
	movwf PCLATH
	movf gbl_modetempb, w
	addwf PCL, f
SampleRep2MPickSt
	MGOTO SampleRep2MStep1
	MGOTO SampleRep2MStep2
	MGOTO SampleRep2MStep3
SampleRep2MPickEn
SampleRep2MStep1
	bcf ADC_CONTROLPORT, RDD		 	;Begin Conversion
	MOVLF BUFFERMIN, FSR				;Initialize pointer
	nop
	local count
	count = 1
	while count < BUFFERSIZE
		movf ADC_DATAPORT, W			;Save Sample
		bsf ADC_CONTROLPORT, RDD		;Latch Conversion into SPP
		bcf ADC_CONTROLPORT, RDD		;Start next conversion
		movwf INDF						;Save to QUEUE
		incf FSR, F						;Increment QUEUE pointer
		nop
		count = count + 1
	endw
	movf ADC_DATAPORT, W
	bsf ADC_CONTROLPORT, RDD			;Latch Conversion into SPP
	bcf ADC_CONTROLPORT, RDD			;Start next conversion
	movwf INDF
	bsf FSR, 7							;goto bank 2
	nop
	count = 1
	while count < D'22'
		movf ADC_DATAPORT, W			;Sample
		bsf ADC_CONTROLPORT, RDD		;Stop conversion
		bcf ADC_CONTROLPORT, RDD		;Begin next conversion
		movwf INDF						;Save to QUEUE
		decf FSR, F						;Increment QUEUE pointer
		nop
		count = count + 1
	endw
	movf ADC_DATAPORT, W				;Sample
	bsf ADC_CONTROLPORT, RDD			;Stop conversion
	MGOTO SampleRep5MEndC

SampleRep2MStep2
	goto $ + 1							;Delay 2
	bcf ADC_CONTROLPORT, RDD		 	;Begin Conversion
	goto $ + 1							;Wait three cycles
	nop
	local count
	count = 1
	while count < D'42'
		movf ADC_DATAPORT, W			;Sample
		bsf ADC_CONTROLPORT, RDD		;Stop conversion
		bcf ADC_CONTROLPORT, RDD		;Begin next conversion
		movwf INDF						;Save to QUEUE
		decf FSR, F						;Increment QUEUE pointer
		nop
		count = count + 1
	endw
	movf ADC_DATAPORT, W
	bsf ADC_CONTROLPORT, RDD
	bcf ADC_CONTROLPORT, RDD
	movwf INDF
	bsf STATUS, IRP						;goto bank 4
	nop
	count = 1
	while count < D'43'
		movf ADC_DATAPORT, W			;Sample
		bsf ADC_CONTROLPORT, RDD		;Stop conversion
		bcf ADC_CONTROLPORT, RDD		;Begin next conversion
		movwf INDF						;Save to QUEUE
		incf FSR, F						;Increment QUEUE pointer
		nop
		count = count + 1
	endw
	movf ADC_DATAPORT, W				;Sample
	bsf ADC_CONTROLPORT, RDD
	MGOTO SampleRep5MEndA

SampleRep2MStep3
	goto $ + 1							;Delay 4
	if (Sample833kEnd & (0x1000))
		bsf PCLATH, 4
	else
		bcf PCLATH, 4
	endif
	if (Sample833kEnd & (0x800))
		bsf PCLATH, 3
	else
		bcf PCLATH, 3
	endif
	bcf ADC_CONTROLPORT, RDD		 	;Begin Conversion
	nop
	goto Sample833kEnd



;Interrupt Driven Sampling with Command Responder
;This code section consists of two routines:
; (1) An interrupt handler for the Timer1 rollover interrupt
; (2) A looping routine that responds to PC commands while we are waiting for sampling interrupts
;Sampling rate = 5e6/Timer1prescaler(8:4:2:1)/(SAMPLERATE1:SAMPLERATE2) with 20 MHz clock
;-----------------------------------------------------------------------------

IrqServiceTimer1
	;reload timer for next interrupt and clear the interrupt flag
	;sample ADC and store into appropriate location
	;increment location and maybe the bank to store into for next time around
	;turn off interrupt if done acquiring
	;return from call
	banksel	BANK0
;	movf	gbl_sampleRate1, W			;MSB of sampling rate
	movlw	0xFF						;<==TEST... fake out sample rate for 2.7KHz
	movwf	TMR1H
;	movf	gbl_sampleRate2, W			;LSB of sampling rate
	movlw	0x18						;<==TEST... fake out sample rate for 2.7KHz
	movwf	TMR1L
	bcf		PIR1, TMR1IF				;Clear the Timer 1 interrupt flag
	movf	FSR, W						;Save the current FSR
	movwf	b0_fsr_temp

							;Setup the indirection register with the acquisition memory address pointer
							;Note!: This is a bit strange, as the other sampling methods use an
							; acquisition memory loading technique of inc-dec-inc-dec for
							; bank0-bank1-bank3-bank2 ... so, we have to accomodate!
	movf	b0_sampleAddr, W			;Get the acquisition memory address pointer
	btfsc	b0_sampleBank, SAMPLEBANK1	;Check for it not being "decrementing bank 1"
		xorlw	0x7f					;Its bank 1, so invert the address pointer
	btfsc	b0_sampleBank, SAMPLEBANK3	;Check for it not being "decrementing bank 3"
		xorlw	0x7f					;Its bank 3, so invert the address pointer

	movwf	FSR							;Now, put the acquisition memory pointer into the indirection register

	btfss	b0_sampleBank, SAMPLEBANK0	;Setup the indirection bank bits IRP and FSR7
		goto $+4
	bcf		FSR, 7
	bcf		STATUS, IRP
	goto	irqst1_1
	btfss	b0_sampleBank, SAMPLEBANK1
		goto $+4
	bsf		FSR, 7
	bcf		STATUS, IRP
	goto	irqst1_1
	btfss	b0_sampleBank, SAMPLEBANK3
		goto $+4
	bsf		FSR, 7
	bsf		STATUS, IRP
	goto	irqst1_1
	btfss	b0_sampleBank, SAMPLEBANK2
		goto $+3
	bcf		FSR, 7
	bsf		STATUS, IRP

irqst1_1
	bcf		ADC_CONTROLPORT, RDD		;Begin Conversion - needs 5 cycles (1uSec)
	goto	$+1							;Do a 5 cycle delay
	goto	$+1
	nop
	movf	ADC_DATAPORT, W				;Sample
	bsf		ADC_CONTROLPORT, RDD		;Stop conversion
	movwf	INDF						;Save sample in the acquisition memory
	incf	b0_sampleAddr, F			;Increment acquisition memory pointer
	movlw	BUFFERMAX+1					;Check for filling last acquisition memory location in bank
	xorwf	b0_sampleAddr, W
	btfss	STATUS, Z
		goto	irqst1_2				;Jump, we are not done filling the current bank
	movlw	BUFFERMIN					;Reset the acquistion memory pointer to its start
	movwf	b0_sampleAddr
	bcf		STATUS, C					;Prepare to shift the acquisition bank to the next bank
	rlf 	b0_sampleBank, F
	btfss	b0_sampleBank, 4			;Check to see if done with this acquisitions sampling
		goto	irqst1_2				;Not done, so keep going...
	banksel	BANK1						;The acquisition is done, so turn off the Timer 1 Interrupt Enable
	bcf		PIE1, TMR1IE
	bcf		INTCON, PEIE
irqst1_2
	banksel	BANK0
	movf	b0_fsr_temp, W				;Restore FSR register
	movwf	FSR
	return


;-  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
SampleIntDrvn
	;Setup the sample write location and sample bank variables
	;Load timer 1 for sampling interrupt and clear timer 1 interrupt flag 
	;Enable the timer 1 interrupt
	banksel	BANK0
	movlw	BUFFERMIN					;Initialize sample buffer memory storage pointer
	movwf	b0_sampleAddr
	movlw	0x01						;Initialize sample bank pointer
	movwf	b0_sampleBank
	
	bsf		T1CON, T1CKPS1				;Set the Timer 1 Prescaler to 1:8  (NOTE!!! This setting
	bsf		T1CON, T1CKPS0				; may need to be a passed variable from the PC eventually)

;	movf	gbl_sampleRate1, W			;MSB of sampling rate
	movlw	0xFF						;<==TEST... fake out sample rate for 2.7KHz
	movwf	TMR1H
;	movf	gbl_sampleRate2, W			;LSB of sampling rate
	movlw	0x18						;<==TEST... fake out sample rate for 2.7KHz
	movwf	TMR1L
	bcf		PIR1, TMR1IF				;Clear the Timer 1 interrupt flag
	banksel	BANK1
	bsf		PIE1, TMR1IE				;Enable the Timer 1 interrupt...
	bsf		INTCON, PEIE				;Enable the Peripheral interrupts
	bsf		INTCON, GIE					; ...NOW ARMED FOR PROCESSING INTERRUPTS!

	;Respond to any commands from PC while Interrupt Driven Sampling
	; Received Commands are:
	;	0xF8 => Send a "0xDC" followed by send of Sampled Data Field
	;	0xF9 => Send a "0xDD" followed by send of Configuration Information Field
	;	0xFA => Send a "0xDE" followed by receive of Configuration Information Field
	;	0xF3 => Send a "0xDC" acknowledgement of a Trigger Break missed (shouldn't happen)
	;
	;When the Timer 1 interrupt gets turned off (will be done by the IrqServiceTimer1
	; routine after the sample memory buffer has been fully filled), leave this
	; routine and go back to Main

sid_GetByteSerial
	banksel	BANK1						;Check to see if the Timer 1 interrupt has been turned off
	btfss	PIE1, TMR1IE
		goto	sid_Exit
	banksel	BANK0
	bsf RCSTA, CREN						;Enable receive (start listening to the serial port)
	btfss PIR1, RCIF			
		goto sid_GetByteSerial
sid_GetByteSerialB
	btfss RCSTA, FERR					;Handle the frame error
		goto sid_GetByteSerialC
	movf RCREG, w						;Throw away data with errors
	goto sid_GetByteSerial
sid_GetByteSerialC
	btfss RCSTA, OERR					;Handle the over run error
		goto sid_GetByteSerialE
	bcf RCSTA, CREN						;Reset the receive logic
	bsf RCSTA, CREN
sid_GetByteSerialD
	movf RCREG, w						;Throw away data with errors
	btfsc PIR1, RCIF
		goto sid_GetByteSerialD
	goto sid_GetByteSerial
sid_GetByteSerialE						;No errors if we got here	
	MOVFF RCREG, gbl_spdata				;Read byte from serial FIFO

sid_WaitComm_Test						;Determine the command and the response
	skipEqLF B'11111000', gbl_spdata
		goto sid_WaitComm_Conf
sid_WaitComm_Data
	MOVLF B'11011100', gbl_spdata		;Send beginning of message
	pagesel	PutByte
	call PutByte
	pagesel	SampleIntDrvn
	MOVLF BUFFERMIN, FSR				;Set pointer to beginning of queue, also clears FSR7
	MOVLF BUFFERSIZE, gbl_cntrb			;Set counter
	bcf	STATUS, IRP						;Set indirection to bank 0, FSR7 cleared in previous instruction

sid_WaitComm_SendDataA					;In Bank 0
	MOVFF INDF, gbl_spdata				;Get data ready to send
	incf FSR, F							;Increment pointer
	pagesel	PutByte
	call PutByte						;Send data
	pagesel	SampleIntDrvn
	decfsz gbl_cntrb, f
		goto sid_WaitComm_SendDataA
	MOVLF BUFFERSIZE, gbl_cntrb			;Set counter
	bsf FSR, 7							;Set Bank 1
	decf FSR, f							;Point at last sampled data element in Bank 1 
sid_WaitComm_SendDataB
	MOVFF INDF, gbl_spdata				;Get data ready to send
	decf FSR, F							;Increment pointer
	pagesel	PutByte
	call PutByte						;Send data
	pagesel	SampleIntDrvn
	decfsz gbl_cntrb, f
		goto sid_WaitComm_SendDataB
	MOVLF BUFFERSIZE, gbl_cntrb			;Set counter
	bsf STATUS, IRP						;Set Bank 3
	incf FSR, f							;Point at first sampled data element in Bank 3
sid_WaitComm_SendDataC
	MOVFF INDF, gbl_spdata				;Get data ready to send
	incf FSR, F							;Increment pointer
	pagesel	PutByte
	call PutByte						;Send data
	pagesel	SampleIntDrvn
	decfsz gbl_cntrb, f
		goto sid_WaitComm_SendDataC
	MOVLF BUFFERSIZE, gbl_cntrb			;Set counter
	bcf FSR, 7							;Bank 2
	decf FSR, f							;Point at last sampled data element in Bank 2
sid_WaitComm_SendDataD
	MOVFF INDF, gbl_spdata				;Get data ready to send
	decf FSR, F							;Increment pointer
	pagesel	PutByte
	call PutByte						;Send data
	pagesel	SampleIntDrvn
	decfsz gbl_cntrb, f
		goto sid_WaitComm_SendDataD
sid_WaitComm_SendDataExit
	bcf FSR, 7
	bcf STATUS, IRP
	pagesel	PutByte
	CHANNELCONFSEND
	pagesel	SampleIntDrvn
	goto sid_GetByteSerial

sid_WaitComm_Conf
	skipEqLF B'11111001', gbl_spdata
		goto sid_WaitComm_Rec
	MOVLF B'11011101', gbl_spdata		;Send beginning of message
	pagesel	PutByte
	call PutByte
	CONFSEND
	pagesel	SampleIntDrvn
	goto sid_GetByteSerial

sid_WaitComm_Rec
	pagesel	SampleIntDrvn
	skipEqLF B'11111010', gbl_spdata
;		goto WaitComm					;No valid message sent
		goto sid_WaitComm_Break
	MOVLF B'11011110', gbl_spdata		;Send beginning of message
	pagesel	PutByte
	call PutByte
	pagesel	GetByte
	CONFRECEIVE
	pagesel	SampleIntDrvn
	goto	sid_GetByteSerial

sid_WaitComm_Break
	pagesel	SampleIntDrvn
	skipEqLF B'11110011', gbl_spdata
		goto sid_GetByteSerial
	MOVLF B'11011100', gbl_spdata
	pagesel	PutByte
	call PutByte
	pagesel	SampleIntDrvn
	goto	sid_GetByteSerial

sid_Exit
	bsf ADC_PORT, CS					;Unselect MAX118
	bcf STATUS, IRP						;Set bank = 0
	CHANNELCONFSTORE
	pagesel	Main
	goto	Main


;-  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
SampleXYIntDrvn							;NOT IMPLEMENTED YET
	pagesel	Main
	goto	Main

;=============================================================================
end		;end of program
