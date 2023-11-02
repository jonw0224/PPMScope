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
;	20120922.1 - by PM
;		Many debug fixes and corrections.
;		Re-arranged interrupt driven sampling code additions per Jonathan Weaver's
;		suggestions to reduce interrupt latency and eliminate many/most pagesel's.
;	20120927.1 - by PM
;		Begin adding sampling/sending methodology for a Strip Chart mode.
;	20120929.1 -
;		Incorporated Jonathan Weaver's changes and coding improvements from
;		the DSOscope_A03_20120928b.zip file.
;	20130113.1 - by PM
;		Changes made for Rev A03 hardware to support selection reporting bits
;		for the Trigger Channel switch and the Channel 1 and 2 Attenuator switches.
;		Also added timing byte for future slower interrupt driven acquisition
;		support and an added byte for longer trigger delays... Changes will
;		require updates to the PC App code.
;	20130201.1 -
;		Incorporated Jonathan Weaver's changes and code fixes from his
;		DSOscope_A03_20130201_For_Paul.zip file.
;	20130208.1 -
;		Incorporated Jonathan Weaver's code fixes from email on 20130208.
;	20130209.1 - by PM
;		Bit setting changes made to the "Initial" routine to turn on PORTB weak
;		pull-ups for CH1ATTN and CH2ATTN input signals.  This will keep the
;		code compatible with the older Rev A02 hardware that does not have
;		CH1ATTN and CH2ATTN signals.  The on screen GAIN reporting will not
;		reflect the attenuator switch positions on the Rev A02 hardware, but
;		it will keep the bit values constant/consistent and the user can
;		mindfully make the appropriate gain conversions in their head.
;	20130211.1 / 20130302.1 - by PM
;		Started making changes to support a pre-trigger acquisition capability
;		using the interrupt driven sampling technique.
;		The maximum amount of pre-trigger capture is the (sweep-speed/div * 10 div).
;		Use a negatively entered trigger delay value to create a count of
;		samples to take after a trigger event.  This, or something like it,
;		will be left as an exercise to the reader HA HA... eventually some
;		method will need to be decided upon.  For now, we will fake it out.
;		A value of 0xffffffff will indicate that the trigger event is placed at
;		the far right side of the screen. A value of 0xffffffbf will be 25% from
;		the right side of the screen. A value of 0xffffff7f will be the middle of
;		the screen, and likewise up to a value of 0xffffff00 which will be the
;		left side of the screen.
;		The interrupt driven sampling mode will free run to continuously
;		acquire samples by just rolling around and around through the PIC's
;		sampling memory buffer.  The negative trigger delay is used to create
;		a "count of samples to acquire after a trigger event happens."  That
;		range being from 0x00 to the maximum memory buffer size.
;		While sampling, and when the trigger event occurs, capture the current
;		store into address & bank and continue to acquire the remaining "count
;		of samples to acquire after a trigger happens."
;		Now, use that saved "trigger event stored into address & bank" value
;		and the desired position for the trigger event to appear on the
;		screen to calculate a value to rotate the PIC memory buffer contents by.
;		The PIC memory buffer contents is then rotated.
;		For this pre-trigger acquistion mode, data will not be sent back to the
;		PC app until the acquistion is totally complete (similar to the current
;		"high speed sampling" methods).  Because the PIC memory buffer contents
;		have been rotated before the data is sent to the PC app, the data
;		will be perfectly aligned and presented from the Pre-Trigger Mode; So,
;		the current display methodolgy in the PC app will just work! We hope!
;	20130401.1 - by PM
;		Pre-trigger acquisition capability is working.  However, there is some
;		annoying jitter on the signal when running in continous sweep mode.
;	20130501.1 - by PM
;		Added code to check for a trigger event occurring during interrupt
;		driven pre-trigger sampling.  This eliminates the annoying
;		jitter that was occurring at the trigger position in pre-trigger mode.
;	20130606.1 - by PM
;		Incorporated fixes to the interrupt driven sampling code so that
;		breaking a trigger works when interrupt driven sampling.
;	20130618.1 - by PM
;		Added an inelegant fix to mask an occasional glitch at the left side
;		of the pre-triggered mode's displayed waveform.
;
;NEW VERSION CREATED:	A04
;	20141224.1 - by PM
;		Started working on fixes to eliminate scope hang problem when starting
;		up scope.  Hang condition occurs when setting Interlaced mode with
;		sweep speed slower than 332uSec/Div and TrOFF.  Scope hangs with traces
;		stuck at the bottom of the screen.
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

	ATTNPORT	set	PORTB
		CH1ATTN	equ	0x06
		CH2ATTN	equ	0x07

	TRGSRCPORT	set	PORTA
		TRGCH	equ	0x03

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

;Bit map for gbl_ptStatus
	RUNNINGBIT			equ	0x07	;1 is pre-triggered acquisition is running
	TRIGGEREDBIT		equ	0x06	;1 is pre-triggered acquisition is triggered
	DATAREADYBIT		equ	0x05	;1 is pre-triggered acquisition data is ready to send
	PTMEMNEW			equ	0x04	;1 is pre-triggered acquisition memory pre-the-trigger now has new data
    TEWS				equ	0x03	;1 is pre-triggered acquisition had a trigger event while sampling

;Bit map for b0_sampleBank			;Be careful!, watch the order of these!
	SAMPLEBANK3			equ	0x02
	SAMPLEBANK2			equ	0x03
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
	FREQSAMPLEINTDRVN	equ	D'12'	;Interrupt Driven Sample Mode
	FREQSAMPLESTRIPCHART equ D'13'	;Interrupt Driven Strip Chart Mode


;=============================================================================
; V A R I A B L E S
;=============================================================================

	;Global General Purpose Registers, accessible anywhere
CBLOCK	0x70
	gbl_configLoc1			;Configuration mode
	gbl_sampleRate0			;sample rate delay extender byte for interrupt driven sampling
	gbl_sampleRate1			;sample rate delay (2 bytes)
	gbl_sampleRate2
	gbl_cntra				;general use counter
	gbl_cntrb				;second counter
	gbl_cntrc				;third counter
	gbl_cntrd				;fourth counter
	gbl_modetemp			;temporary mode variable
	gbl_modetempb			;temporary mode for repetitive sampling
	gbl_spdata				;data to/from serial port
	gbl_dataConfig			;the data configuration
	gbl_w_temp				;temp storage for w register during interrupt handling
	gbl_status_temp			;temp storage for status register during interrupt handling
	gbl_sampleCntr			;temporary variable for counting interrupts for extended "slow mode" interrupt sampling
	gbl_ptStatus			;pre-trigger acquistion status
ENDC

	;Bank0 General Purpose Registers
CBLOCK	0x60
	b0_triggerDelay0		;trigger delay (4 bytes)
	b0_triggerDelay1		
	b0_triggerDelay2
	b0_triggerDelay3
	b0_triggerChannel		;the trigger channel
	b0_triggerLevel			;the trigger level
	b0_sampleAddr			;address to store ADC sampled value
	b0_sampleBank			;bank to store ADC sampled value
	b0_fsr_temp				;temp storage for fsr register during interrupt handling
	b0_ptPtSampleCntr		;pre-trigger acquisition's post trigger sample counter
	b0_ptTriggerAddr		;sample's storage address when pre-trigger's trigger happens
	b0_ptTriggerBank		;sample's storage bank when pre-trigger's trigger happens
	b0_ptPlaceTriggerHere	;place trigger (0xfe = right side, 0x00 = left side, in 0x02 increments)
	b0_ptRotationCntr		;sample memory rotation counter
	b0_ptFsrTemp			;2nd level of fsr temp storage for pre-trigger
	b0_ptTemp0				;temporary storage
ENDC

	;Bank1 General Purpose Registers
CBLOCK	0xE0
	b1_ptFlushCntr			;pre-trigger flush memory counter
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

	;Bank2 General Purpose Registers
CBLOCK	0x110
	b2_unused1F
	b2_unused1E
	b2_unused1D
	b2_unused1C
	b2_unused1B
	b2_unused1A
	b2_unused19
	b2_unused18
	b2_unused17
	b2_unused16
	b2_unused15
	b2_unused14
	b2_unused13
	b2_unused12
	b2_unused11
	b2_unused10
ENDC
CBLOCK	0x160
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

	;Bank3 General Purpose Registers
CBLOCK	0x190
	b3_unused1F
	b3_unused1E
	b3_unused1D
	b3_unused1C
	b3_unused1B
	b3_unused1A
	b3_unused19
	b3_unused18
	b3_unused17
	b3_unused16
	b3_unused15
	b3_unused14
	b3_unused13
	b3_unused12
	b3_unused11
	b3_unused10
ENDC
CBLOCK	0x1E0
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




;=============================================================================
; I N T E R R U P T S
;=============================================================================

org 0x0000	;Reset Vector
;First three lines of initialization included here to save on memory.
	MOVLF B'00000001', ADC_CONTROLPORT	;Set MAX118's pins /RDD high, ADDR0 low
	clrf ADC_DATAPORT					;Set MAX118's databus port to all low
	goto Initial

org 0x0004	;Interrupt Vector
IntHandler
	;Save the current state
    movwf	gbl_w_temp					;Save off current W register contents
	swapf	STATUS,W					;Move status register into W register
	movwf	gbl_status_temp				;Save off contents of a "swapped" STATUS register

	;Now to handle the pending interrupt (it should be either a trigger interrupt or a Timer1 interrupt)
	;Note: Interrupt flag bits are set regardless of the enable bit... so, we need to validate that
	; the interrupt is truly enabled before acting on the flag state.
	btfss	INTCON, INTE				;Check for trigger interrupt being enabled
		goto ih_2
	btfss	INTCON, INTF				;Check for a trigger interrupt
		goto ih_2
	bcf		INTCON, INTE				;It was a trigger interrupt, turn off the trigger interrupt
										; for the duration of the acquisition (or the rest of the
										; acquisition in the case of Pre_Trigger acquisition)

	btfsc	gbl_ptStatus, RUNNINGBIT	;Check to see if we are doing Pre-Trigger Sampling
		goto ih_pt						;Jump if we are doing Pre-Trigger Sampling

ih_1
	decfsz gbl_cntra, f					;Count down the trigger delay, 0x01010101 implies minimum delay
		goto ih_1
	decfsz gbl_cntrb, f
		goto ih_1
	decfsz gbl_cntrc, f
		goto ih_1
	decfsz gbl_cntrd, f
		goto ih_1
	movf gbl_modetemp, w

MainSelect
	addwf	PCL, f						;Add freqMode to Program Counter
	MGOTO	Sample1M					;FreqMode = 0
	MGOTO	Sample833k					;FreqMode = 1
	MGOTO	Sample625k					;FreqMode = 2
	MGOTO	Sample417k250k				;FreqMode = 3
	MGOTO	Sample417k250k				;FreqMode = 4
	MGOTO	SampleDelayed				;FreqMode = 5
	MGOTO	SampleRep5M					;FreqMode = 6
	MGOTO	SampleRep2M					;FreqMode = 7
	MGOTO	SampleXY417k				;FreqMode = 8
	MGOTO	SampleXY250k192k			;FreqMode = 9
	MGOTO	SampleXY250k192k			;FreqMode = 10
	MGOTO	SampleXYDelayed				;FreqMode = 11
	MGOTO	SampleIntDrvn				;FreqMode = 12
	MGOTO	Main						;Invalid FreqMode = 13, goto beginning
	MGOTO	Main						;Invalid FreqMode = 14, goto beginning
	MGOTO	Main						;Invalid FreqMode = 15, goto beginning

ih_pt									;This is for a "pre-trigger sampling" trigger interrupt
	banksel	BANK0
	movf	b0_sampleBank, W			;Capture the current location that the interrupt driven
	movwf	b0_ptTriggerBank			; pre-trigger sample is being stored into
	movf	b0_sampleAddr, W
	movwf	b0_ptTriggerAddr
	bsf		gbl_ptStatus, TRIGGEREDBIT	;Flag that we have been triggered
	;fall through to also check for a timer1 interrupt. May as well try to get two birds with one stone!

ih_2
	banksel	BANK0						;It wasn't a trigger interrupt so,
	btfss	PIR1, TMR1IF				; test to see if it was a timer 1 interrupt
		goto ih_3						;It wasn't, so restore registers and then return from interrupt
	banksel	BANK1
	btfss	PIE1, TMR1IE				;Test to see if the timer interrupt is really enabled
		goto ih_3
	call	IrqServiceTimer1			;service the timer1 interrupt

ih_3
	;restore previous state	
    swapf	gbl_status_temp,W			;retrieve copy of STATUS register and "unswap" it
    movwf   STATUS						;restore pre-isr STATUS register contents
    swapf   gbl_w_temp,F				;the ol' swap'er-roo to
    swapf   gbl_w_temp,W				; restore pre-isr W register contents without clobbering STATUS register
    retfie								;return from interrupt and activate GIE


;=============================================================================
; M A I N
;=============================================================================
;Initalize for the program
;-----------------------------------------------------------------------------
Initial
	clrf	PORTA
	MOVLF B'11110011', PORTB			;ADDR2=0,ADDR1=0,/CS=1
	banksel TRISA
	MOVLF B'11000000', WPUB				;Turn on weak pull-ups for CH1ATTN and CH2ATTN signals
	MOVLF B'00011111', TRISA			;Configure PORTA
	MOVLF B'01000000', OPTION_REG		;Interrupt on rising edge of RB0 plus enable PORTB's weak pull-ups
	MOVLF B'00010000', INTCON			;Interrupt on RB0 only, but not enabled yet
	MOVLF B'11110001', TRISB
	MOVLF B'11111111', TRISD
	MOVLF B'00000100', TRISE			;Set up USB detect as input, CS and ADDR0 as outputs
	MOVLF B'10111001', TRISC			;Configure PORTC

	banksel	ANSEL			;Access bank 3
	clrf	ANSEL			;Turn off analog mode on RE2,1,0 and RA5,3,2,1,0 so the pins read digital
	clrf	ANSELH			;Turn off analog mode on RB5,0,4,1,3,2 so the pins read digital

	;Initialize Serial Port

	movlw	0x08			;Set the Serial Port baud rate generators
	movwf	BAUDCTL
	banksel	SPBRG			;Return to bank 1 and continue setting baud rate generators
	movlw	0x56			; for 57.6K baud
	movwf	SPBRG
	movlw	0x00
	movwf	SPBRGH
	movlw	0x24			;Set the Serial Port Transmitter configuration
	movwf	TXSTA
	banksel	RCSTA			;Access bank 0
	movlw	0x90			;Set the Serial Port Receiver configuration, Serial Port now enabled!
	movwf	RCSTA

	bcf		STATUS, IRP		;Ensure indirect addressing of Bank0 and Bank1
							; WaitComm_Data takes care of clearing FSR7 bit
	clrf	ADCON0			;Make sure PIC's ADC is off

Main
	clrf	gbl_ptStatus				;Clear the pre-trigger status register
	clrf	gbl_modetempb				;Clear the gbl_modetempb for repetitive sampling
	banksel	BANK0
	bsf		ADC_PORT, CS				;Unselect MAX118

	call	WaitComm					;Call WaitComm and stay there until we have
										; received a "ConfReceive" Configuration Information Field
	
MainB
	bcf		ADC_CONTROLPORT, ADDR0		;Select Channel
	btfsc	gbl_configLoc1, CHANNELBIT
		bsf		ADC_CONTROLPORT, ADDR0

	if (high MainSelect)
		movlw	high MainSelect			;Prepare for jump
		movwf	PCLATH
	else
		clrf PCLATH
	endif

	movf	gbl_configLoc1, w			;Put configuration in WREG
	andlw	((1<<FREQMODEBIT3)|(1<<FREQMODEBIT2)|(1<<FREQMODEBIT1)|(1<<FREQMODEBIT0))	;Unmask FreqMode
	movwf	gbl_modetemp				;Multiply by 3
	bcf		STATUS, C
	rlf		gbl_modetemp, f
	addwf	gbl_modetemp, w				; and put the result into W register for later computed jump
	movwf	gbl_modetemp				;Store the jump for main select (freqmode)
	incf	b0_triggerDelay3, w			;Get the trigger delay ready
	movwf	gbl_cntra
	incf	b0_triggerDelay2, w	
	movwf	gbl_cntrb
	incf	b0_triggerDelay1, w
	movwf	gbl_cntrc
	incf	b0_triggerDelay0, w
	movwf	gbl_cntrd
	movf	gbl_modetemp, w				;Get back the jump for main select (freqmode)
	bcf		ADC_PORT, CS				;Select MAX118
	btfss	gbl_configLoc1, TRIGGERENBIT	;Decide if trigger is enabled.  If so, wait on interrupt
		goto MainSelect

MainWaitTrig							;Trigger is enabled, set up interrupt
	banksel	OPTION_REG					;Access bank 1
	bcf		OPTION_REG, INTEDG			;Assume trigger on falling edge
	btfsc	gbl_configLoc1, TRIGGERPOSBIT	;Test for trigger on positive edge instead
		bsf	OPTION_REG, INTEDG			; and, it is, so set to trigger on positive edge
	banksel	BANK0						;Access bank 0

										;Check for a negative value of the trigger delay
	btfss	b0_triggerDelay0, 0x07		; to determine if we should be doing a pre-trigger acquisition
		goto	MainWTrigB				; if it is positive, go wait for the regular trigger
	movf	b0_triggerDelay3, W			;PC app sends a pre-scaled value of 0xff for right
										; side, to 0x00 for left side, screen placement of trigger event
	andlw	0xfe						;Make sure it is an even number
	movwf	b0_ptPlaceTriggerHere		;Put it into the "place trigger position here" variable
	banksel	BANK1
	movwf	b1_ptFlushCntr				;Also put it into the count of samples to take before
										; allowing the trigger to be enabled. This essentially
										; flushes the memory of stale data.
	banksel	BANK0
	xorlw	0xfe						;Then, invert that, but keep it even, to arrive at a count of
										; samples to take after the trigger
	movwf	b0_ptPtSampleCntr
	bsf		gbl_ptStatus, RUNNINGBIT	;Set the pre-trigger acquisition state to running
	movf	gbl_modetemp, W				;Restore the freqmode for Mainselect's computed jump
	goto	MainSelect					; and, start the pre-trigger sampling
	

MainWTrigB
	bcf		INTCON, INTF				;Ensure that the RB0 interrupt flag is clear
	bsf		INTCON, INTE				;Enable the RB0 specific interrupt
	bsf		INTCON, GIE					;Enable interrupts
MainWTrigB_1
	call	GetByte						;Wait for the trigger unless a "break trigger"
	skipEqLF B'11110011', gbl_spdata	;message is received
		goto	MainWTrigB_1
	bcf		INTCON, INTE				;Disable the RB0 specific interrupt
	bcf		INTCON, GIE					;Disable interrupts
	MOVLF B'11011100', gbl_spdata		;Respond with "DC"
	call	PutByte
	goto	Main						;Abort

										;Note that the jitter on the interrupt is
										;1 cycles.  This translates to 200 ns
										;on the PIC running at 20 MHz

;=============================================================================
; S U B R O U T I N E S
;=============================================================================

;Wait for command from computer and respond accordingly

	; Received Commands are:
	;	0xF8 (248) => Send a "0xDC" (220) followed by send of Sampled Data Field + Channel Field
	;	0xF9 (249) => Send a "0xDD" (221) followed by send of Configuration Information Field
	;	0xFA (250) => Send a "0xDE" (222) followed by receive of Configuration Information Field
	;	0xF3 (243) => Send a "0xDC" (220) acknowledgement of a Trigger Break missed

;-----------------------------------------------------------------------------
WaitComm
	call GetByte						;Wait for receive

WaitComm_Data							;***** Check for/Respond to Command "0xF8" (248) *****
	skipEqLF B'11111000', gbl_spdata
		goto WaitComm_Conf
	MOVLF B'11011100', gbl_spdata		;Send beginning of message "0xDC" (220)
	call PutByte
	MOVLF BUFFERMIN, FSR				;Set pointer to beginning of queue, also clears FSR7
	MOVLF BUFFERSIZE, gbl_cntrb			;Set counter
	bcf		STATUS, IRP					;Set indirection to bank 0, FSR7 cleared in previous instruction
WaitComm_SendDataA
	MOVFF INDF, gbl_spdata				;Get data ready to send from Bank 0
	incf FSR, F							;Increment pointer
	call PutByte						;Send data
	decfsz gbl_cntrb, f
		goto WaitComm_SendDataA
	MOVLF BUFFERSIZE, gbl_cntrb			;Set counter
	bsf FSR, 7							;Bank 1
	decf FSR, f
WaitComm_SendDataB
	MOVFF INDF, gbl_spdata				;Get data ready to send from Bank 1
	decf FSR, F							;Increment pointer
	call PutByte						;Send data
	decfsz gbl_cntrb, f
		goto WaitComm_SendDataB
	MOVLF BUFFERSIZE, gbl_cntrb			;Set counter
	bsf STATUS, IRP						;Bank 3
	incf FSR, f
WaitComm_SendDataC
	MOVFF INDF, gbl_spdata				;Get data ready to send from Bank 3
	incf FSR, F							;Increment pointer
	call PutByte						;Send data
	decfsz gbl_cntrb, f
		goto WaitComm_SendDataC
	MOVLF BUFFERSIZE, gbl_cntrb			;Set counter
	bcf FSR, 7							;Bank 2
	decf FSR, f
WaitComm_SendDataD
	MOVFF INDF, gbl_spdata				;Get data ready to send from Bank 2
	decf FSR, F							;Increment pointer
	call PutByte						;Send data
	decfsz gbl_cntrb, f
		goto WaitComm_SendDataD
WaitComm_SendDataExit
	bcf STATUS, IRP						;Set indirection back to Bank 0
	call	ChannelConfSend
	goto	WaitComm

WaitComm_Conf							;***** Check for/Respond to Command "0xF9" (249) *****
	skipEqLF B'11111001', gbl_spdata
		goto WaitComm_Rec
	MOVLF B'11011101', gbl_spdata		;Send beginning of message "0xDD" (221)
	call	PutByte
	call	ConfSend
	goto	WaitComm

WaitComm_Rec							;***** Check for/Respond to Command "0xFA" (250) *****
	skipEqLF B'11111010', gbl_spdata
		goto WaitComm_Break
	MOVLF B'11011110', gbl_spdata		;Send beginning of message "0xDE" (222)
	call	PutByte
	call	ConfReceive
	return

WaitComm_Break							;***** Check for/Respond to Command "0xF3" (243) *****
	skipEqLF B'11110011', gbl_spdata
		goto WaitComm					;No valid message sent
	MOVLF B'11011100', gbl_spdata		;Send ack "0xDC" (220) for a trigger break
	call	PutByte
	goto	WaitComm



;GetByte is used to receive a byte on the serial port
;------------------------------------------------------------------------------
GetByte
	banksel	BANK0
GetByteA
	btfss PIR1, RCIF			
		goto GetByteA
GetByteB
	btfss RCSTA, FERR					;Handle the frame error
		goto GetByteC
	movf RCREG, w						;Throw away data with errors
	goto GetByteA
GetByteC
	btfss RCSTA, OERR					;Handle the over run error
		goto GetByteE
	bcf RCSTA, CREN						;Reset the receive logic
	bsf RCSTA, CREN
GetByteD
	movf RCREG, w						;Throw away data with errors
	btfsc PIR1, RCIF
		goto GetByteD
	goto GetByteA
GetByteE								;No errors if we got here	
	MOVFF RCREG, gbl_spdata				;Read byte from serial FIFO
	retlw 0
	
;PutByte is used to put a byte on the serial port
;------------------------------------------------------------------------------
PutByte
	banksel	BANK0
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
	movwf	INDF						;Save to QUEUE
	bsf		ADC_PORT, CS				;Unselect MAX118
	bcf		STATUS, IRP					;Set indirection to bank 0 and/or bank 1
	call	ChannelConfStore
	goto Main

;=============================================================================
;*****************************************************************************
;=============================================================================

;Interrupt Driven Sampling with Command Responder
;This code section consists of three routines:
; (1) An interrupt handler for the Timer1 rollover interrupt
; (2) A looping routine that responds to PC commands while we are waiting for
;		sampling interrupts
; (3) A routine to rotate the acquired sample memory to align it for proper
;		pre-trigger display

;Jonathan Weaver: Measurements from simulation (9/27/2012 and 9/28/2012)
;Interrupt to the first sample = 103 cycles using minimum delay
;Sampling rate = 5000000/(8*SAMPLERATE1:SAMPLERATE2+35) with 20 MHz clock
;Minimum value for SAMPLERATE1:SAMPLERATE2 ~= 20 
;(around 140 cycles to execute the timer1 interrupt.  Added some time for
;processing the serial port.)
;Maximum sample rate (at SAMPLERATE1:SAMPLERATE2 = 20) is 25,641 Hz.
;Waveform completion at that sample rate is 100 times per second
;Maximum communication rate is 5,670 bytes per second or 22 waveforms per second
;using the serial interface.

;Note!  The SAMPLERATE1:2 values get complemented here.  The Timer counts up and
; when it rolls over to 0x0000, the interrupt is generated.
;This code does a channel 0 and a channel 1 sample on each Timer 1 interrupt... ie., it
; samples in a "chopped" mode.  Channel 0 samples are stored in even acquisition memory
; locations and Channel 1 samples are stored in odd acquisition memory locations.
; The number of samples for each channel is 1/2 of the total acquisition memory size!
;-----------------------------------------------------------------------------

IrqServiceTimer1
	;reload timer for next interrupt and clear the interrupt flag
	;sample ADC and store into appropriate location
	;increment location and maybe the bank to store into for next time around
	;turn off interrupt if done acquiring
	;return from call
	banksel	BANK0
	bcf		T1CON, TMR1ON				;Turn off Timer 1 for a fail safe loading experience
	comf	gbl_sampleRate1, W
	movwf	TMR1H
	comf	gbl_sampleRate2, W			;LSB of sampling rate
	movwf	TMR1L
	bcf		PIR1, TMR1IF				;Clear the Timer 1 interrupt flag
	bsf		T1CON, TMR1ON				;Turn Timer 1 back on

	decfsz gbl_sampleCntr, f			;Implement the longer sample delay, only sample when sampleCntr is zero
		return
	incf	gbl_sampleRate0, w			;Restore sampleCntr using sampleRate0 (MSB)
	movwf	gbl_sampleCntr

	nop
	movf	FSR, W						;Save the current FSR
	movwf	b0_fsr_temp
							;Setup the indirection register with the acquisition memory address pointer
	movf b0_sampleAddr, W
	movwf FSR
	;Assume indirect bank0
	bcf STATUS, IRP
	bcf FSR, 7
	;Set indirect bank1 if needed
	btfsc b0_sampleBank, SAMPLEBANK1
        bsf FSR, 7
	;Set indirect bank2 if needed
    btfsc b0_sampleBank, SAMPLEBANK2
        bsf STATUS, IRP
    ;Set indirect bank3 if needed
    btfsc b0_sampleBank, SAMPLEBANK3
        bsf FSR, 7
    btfsc b0_sampleBank, SAMPLEBANK3
        bsf STATUS, IRP

	bcf		ADC_CONTROLPORT, ADDR0		;Set ADC to channel 0
	bcf		ADC_PORT, CS				;Select MAX118
	bcf		ADC_CONTROLPORT, RDD		;Begin Conversion - needs 5 cycles (1uSec)
;--Start jitter reduction fix--
;	goto	$+1							;Do a 5 cycle delay from /RD going active
;	goto	$+1
;	nop

	;The following check is to used to eliminate the jitter seen on pre-trigger sampling.
    ; Without this check, a trigger event happening while we are already servicing
	; a timer interrupt will end up being logged one sample clock late.  With the event
	; being logged one sample clock late, the pre-trigger memory will end up being rotated
	; one position too far.  This check and flag setting will be used to correct the
	; rotation count... Note: this isn't perfect... there will still be a small window hole.
	; By doing this check before CH1 is sampled, we are favoring the CH0 trigger for best
	; jitter reduction.
	;Check to see if a trigger event happened while sampling, if so set the flag
	; Note: this also results in the needed 5 cycle delay that is commented out above
	btfsc	INTCON, INTE				;Trigger interrupt enable
		btfss INTCON, INTF				;Trigger interrupt flag
	goto	irqst1_0					;Jump if there was no trigger event while sampling
	bsf	gbl_ptStatus, TEWS				;Flag that there was a trigger event while sampling
irqst1_0
	nop
;--End jitter reduction fix--

	movf	ADC_DATAPORT, W				;Sample ADC channel 0
	bsf		ADC_CONTROLPORT, RDD		;Stop conversion
	bsf		ADC_CONTROLPORT, ADDR0		;Set ADC to channel 1
	bcf		ADC_CONTROLPORT, RDD		;Begin next conversion
	movwf	INDF						;Save channel 0 sample to the acquisition memory
    btfsc b0_sampleBank, SAMPLEBANK0    ;Increment acquistion memory pointer if Bank0
        incf	FSR, F						
    btfsc b0_sampleBank, SAMPLEBANK1    ;Decrement memory pointer if Bank1
        decf FSR, F
	movf	ADC_DATAPORT, W				;Sample ADC channel 1
	bsf		ADC_CONTROLPORT, RDD		;Stop conversion
	bsf		ADC_PORT, CS				;Unselect MAX118
    btfsc b0_sampleBank, SAMPLEBANK2    ;Decrement memory pointer if Bank2
        decf FSR, F
	btfsc b0_sampleBank, SAMPLEBANK3    ;Increment memory pointer if Bank3
		incf FSR, F
	movwf	INDF						;Save channel 1 sample to the acquistion memory

	movlw 0x02							;Prepare to increment sampleAddr by 2
	btfsc b0_sampleBank, SAMPLEBANK1	;If BANK1, prepare to decrement sampleAddr by 2
		movlw (0x00 - 0x02)
	btfsc b0_sampleBank, SAMPLEBANK2	;If BANK2, prepare to decrement sampleAddr by 2
		movlw (0x00 - 0x02)
	addwf b0_sampleAddr, F
	movlw BUFFERMIN-1					;Check for filling last aquisition memory location in bank
	xorwf b0_sampleAddr, W
	btfsc STATUS, Z
		goto irqst1_1					;Jump, filled last aquisition memory location in bank

	movlw	BUFFERMAX+1					;Check for filling last acquisition memory location in bank
	xorwf	b0_sampleAddr, W
	btfss	STATUS, Z
		goto irqst1_3					;Jump, we are not done filling the current bank
	movlw	BUFFERMAX					;Reset the acquisition memory pointer to its END
	movwf	b0_sampleAddr
	goto	irqst1_2

irqst1_1
    MOVLF BUFFERMIN, b0_sampleAddr		;Reset the acquisition memory pointer to its BEGINNING

irqst1_2
	bcf		STATUS, C					;Prepare to shift the acquisition bank to the next bank
	rlf 	b0_sampleBank, F
	btfss	b0_sampleBank, 4			;Check to see if done with this acquisitions sampling
		goto irqst1_3					;Not done, so keep going...
	btfss	gbl_ptStatus, RUNNINGBIT	;Check to see if we are doing a pre-trigger sampling
		goto irqst1_4					;Done with a regular trigger's sampling
	clrf	b0_sampleBank				;Pre-trigger sampling, so just set the bank back to zero
	bsf		b0_sampleBank, SAMPLEBANK0


irqst1_3
		;If we are doing pre-trigger sampling
		; check to see if the pre-trigger memory's pre-the-trigger area has been flushed (loaded)
		; with the latest data for this sample run.
		; If it has been, then turn on the trigger interrupt.
	btfss	gbl_ptStatus, RUNNINGBIT
		goto irqst1_5
	btfsc	gbl_ptStatus, PTMEMNEW
		goto irqst1_3_a
	banksel	BANK1
	movf	b1_ptFlushCntr, F
	btfsc	STATUS, Z
		bsf	gbl_ptStatus, PTMEMNEW
	decf	b1_ptFlushCntr, F
	decf	b1_ptFlushCntr, F
	banksel	BANK0
	btfss	gbl_ptStatus, PTMEMNEW
		goto irqst1_3_a
	bcf		INTCON, INTF
	bsf		INTCON, INTE
	goto	irqst1_5

irqst1_3_a
		;If we are doing pre-trigger sampling AND if we have already seen a trigger, then
		; check to see if the required number of samples after a trigger event has been completed
		; If it has, then stop the acquisition so we don't overwrite the pre-trigger samples
	btfss	gbl_ptStatus, TRIGGEREDBIT
		goto irqst1_5
	decf	b0_ptPtSampleCntr, F
	decfsz	b0_ptPtSampleCntr, F
		goto irqst1_5

		;Now calculate an amount to rotate the sample memory to align the trigger with
		; its requested position on the screen
		;Convert the captured address/bank of where the trigger event was stored
		; into a meaningful linear address value... Wow is this confusing!  Lets hope we
		; get it right!
		;First account for whether the address was in an incrementing or a decrementing bank
	movlw	BUFFERMIN
	subwf	b0_ptTriggerAddr, W
	btfsc	b0_ptTriggerBank, SAMPLEBANK1
		xorlw 0x3f
	btfsc	b0_ptTriggerBank, SAMPLEBANK2
		xorlw 0x3f
		;Now account for the various banks
	btfsc	b0_ptTriggerBank, SAMPLEBANK1
		addlw (BUFFERSIZE * 1)
	btfsc	b0_ptTriggerBank, SAMPLEBANK2
		addlw (BUFFERSIZE * 3)
	btfsc	b0_ptTriggerBank, SAMPLEBANK3
		addlw (BUFFERSIZE * 2)
	addlw	0xfe						;Subtract 2 from the value to account for the post increment
;--Start jitter reduction fix--
	btfsc	gbl_ptStatus, TEWS			;Check if we previously logged a Trigger Event While Sampling
		addlw 0xfe						;Subtract 2 to account for the Trigger Event While Sampling
;--End jitter reduction fix--
		;Then calculate out how much rotation is needed to align the trigger event with
		; the requested screen position
	subwf	b0_ptPlaceTriggerHere, W
	andlw	0xfe						;Make sure it is an even number
	movwf	b0_ptRotationCntr
		;Now decide whether rotating right or rotating left gets us aligned the quickest
	btfss	b0_ptRotationCntr, 7
		goto irqst1_3_1					;Fastest is to rotate right
	movlw	0xfe						;Fastest is to rotate left, make some counter adjustments
	xorwf	b0_ptRotationCntr, F
	incf	b0_ptRotationCntr, F
	incf	b0_ptRotationCntr, F
	call	RotateSampleMemLeft
	goto	irqst1_3_2
irqst1_3_1
	call	RotateSampleMemRight
irqst1_3_2
	bsf		gbl_ptStatus, DATAREADYBIT	;Set the pre-trigger acquisition's data is now ready flag

irqst1_4
	bcf		T1CON, TMR1ON				;The acquisition is done, so turn off Timer 1
	bcf		PIR1, TMR1IF				;Clear the interrupt flag, too
	banksel	BANK1
	bcf		PIE1, TMR1IE				;Turn off the Timer 1 Interrupt Enable
	bcf		INTCON, PEIE				; and the Peripheral Interrupt Enable

irqst1_5
	banksel	BANK0
	movf	b0_fsr_temp, W				;Restore FSR register
	movwf	FSR
	return								;Returns to the IntHandler routine that then restores
										; state and does the retfie


;-  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
SampleIntDrvn
	;Setup the sample write location and sample bank variables
	;Load Timer 1 for sampling interrupt generation and clear timer 1 interrupt flag 
	;Turn on Timer 1
	;Enable the Timer 1 interrupt
	banksel	BANK0
	movlw	BUFFERMIN					;Initialize sample buffer memory storage pointer
	movwf	b0_sampleAddr
	clrf	b0_sampleBank				;Initialize sample bank pointer
	bsf		b0_sampleBank, SAMPLEBANK0
	bcf		T1CON, TMR1ON				;Turn off Timer 1 for a fail safe loading experience
	bsf		T1CON, T1CKPS1				;Set the Timer 1 Prescaler to 1:8
	bsf		T1CON, T1CKPS0

	movlw	0x01
	movwf	gbl_sampleCntr				;Set the sampleCntr to 1 so it will sample on the first interrupt
	
	movlw	0xFF						;Force Timer1 to do an almost immediate interrupt so 
	movwf	TMR1H						; that we get started sampling ASAP.  The real sample
	movwf	TMR1L						; interval gets loaded in the IrqServiceTimer1 routine.
	bcf		PIR1, TMR1IF				;Clear the Timer 1 interrupt flag
	banksel	BANK1
	bsf		PIE1, TMR1IE				;Enable the Timer 1 interrupt...
	banksel	BANK0
	bsf		INTCON, PEIE				;Enable the Peripheral interrupts
	bsf		T1CON, TMR1ON				;Turn on Timer 1
	bsf		INTCON, GIE					; ...NOW ARMED FOR PROCESSING INTERRUPTS!


	;Respond to any commands from PC app while Interrupt Driven Sampling
	; Received Commands are:
	;	0xF8 (248) => Send a "0xDC" (220) followed by send of Sampled Data Field + Channel Field
	;	0xF9 (249) => Send a "0xDD" (221) followed by send of Configuration Information Field
	;	0xFA (250) => Send a "0xDE" (222) followed by receive of Configuration Information Field
	;	0xF3 (243) => Send a "0xDC" (220) acknowledgement of a Trigger Break missed and then exits
	;
	;When the Timer 1 interrupt gets turned off (will be done by the IrqServiceTimer1
	; routine after the sample memory buffer has been fully filled), leave this
	; routine and go back to Main

sid_GetByte
	banksel	BANK1						;Check to see if the Timer 1 interrupt has been turned off
	btfss	PIE1, TMR1IE
		goto	sid_Exit				; it has been turned off so head for the exit door
	banksel	BANK0
	btfss	PIR1, RCIF			
		goto sid_GetByte
sid_GetByteB
	btfss	RCSTA, FERR					;Handle the frame error
		goto sid_GetByteC
	movf	RCREG, w					;Throw away data with errors
	goto	sid_GetByte
sid_GetByteC
	btfss	RCSTA, OERR					;Handle the over run error
		goto sid_GetByteE
	bcf		RCSTA, CREN					;Reset the receive logic
	bsf		RCSTA, CREN
sid_GetByteD
	movf	RCREG, w					;Throw away data with errors
	btfsc	PIR1, RCIF
		goto sid_GetByteD
	goto	sid_GetByte
sid_GetByteE							;No errors if we got here	
	MOVFF	RCREG, gbl_spdata			;Read byte from serial FIFO

	btfss	gbl_ptStatus, RUNNINGBIT	;Check to see if we are/were running a pre-trigger acquisition
		goto sid_WaitComm_Data
	btfss	gbl_ptStatus, DATAREADYBIT	;Check to see if pre-trigger acquisition data is ready
		goto sid_WaitComm_Break			; if not, ignore commands (except for the break trigger) at this time!

sid_WaitComm_Data						;***** Check for/Respond to Command "0xF8" (248) *****
	skipEqLF B'11111000', gbl_spdata
		goto sid_WaitComm_Conf
	MOVLF	B'11011100', gbl_spdata		;Send beginning of message "0xDC" (220)
	call	PutByte
	MOVLF	BUFFERMIN, FSR				;Set pointer to beginning of queue, also clears FSR7
	MOVLF	BUFFERSIZE, gbl_cntrb		;Set counter
	bcf		STATUS, IRP					;Set indirection to bank 0, FSR7 cleared in previous instruction
sid_WaitComm_SendDataA					;In Bank 0
	MOVFF	INDF, gbl_spdata			;Get data ready to send
	incf	FSR, F						;Increment pointer
	call	PutByte						;Send data
	decfsz	gbl_cntrb, f
		goto sid_WaitComm_SendDataA
	MOVLF	BUFFERSIZE, gbl_cntrb		;Set counter
	decf	FSR, f						;Point at first sampled data element in Bank 1 
	bsf		FSR, 7						;Set Bank 1
sid_WaitComm_SendDataB
	MOVFF	INDF, gbl_spdata			;Get data ready to send
	decf	FSR, F						;Increment pointer
	call	PutByte						;Send data
	decfsz	gbl_cntrb, f
		goto sid_WaitComm_SendDataB
	MOVLF	BUFFERSIZE, gbl_cntrb		;Set counter
	incf	FSR, f						;Point at first sampled data element in Bank 3
	bsf		STATUS, IRP					;Set Bank 3
sid_WaitComm_SendDataC
	MOVFF	INDF, gbl_spdata			;Get data ready to send
	incf	FSR, F						;Increment pointer
	call	PutByte						;Send data
	decfsz	gbl_cntrb, f
		goto sid_WaitComm_SendDataC
	MOVLF	BUFFERSIZE, gbl_cntrb		;Set counter
	decf	FSR, f						;Point at first sampled data element in Bank 2
	bcf		FSR, 7						;Set Bank 2
sid_WaitComm_SendDataD
	MOVFF	INDF, gbl_spdata			;Get data ready to send
	decf	FSR, F						;Increment pointer
	call	PutByte						;Send data
	decfsz	gbl_cntrb, f
		goto sid_WaitComm_SendDataD
sid_WaitComm_SendDataExit
	bcf STATUS, IRP						;Set indirection back to Bank 0
	call	ChannelConfSend
	goto	sid_GetByte

sid_WaitComm_Conf						;***** Check for/Respond to Command "0xF9" (249) *****
	skipEqLF B'11111001', gbl_spdata
		goto sid_WaitComm_Rec
	MOVLF B'11011101', gbl_spdata		;Send beginning of message "0xDD" (221)
	call	PutByte
	call	ConfSend
	goto	sid_GetByte

sid_WaitComm_Rec						;***** Check for/Respond to Command "0xFA" (250) *****
	skipEqLF B'11111010', gbl_spdata
		goto sid_WaitComm_Break
	MOVLF B'11011110', gbl_spdata		;Send ready to receive message "0xDE" (222)
	call	PutByte
	call	ConfReceiveRateOnly
	goto	sid_GetByte

sid_WaitComm_Break						;***** Check for/Respond to Command "0xF3" (243) *****
	skipEqLF B'11110011', gbl_spdata
		goto sid_GetByte				;No valid message sent
	MOVLF B'11011100', gbl_spdata		;Send ack "0xDC" (220) for a trigger break
	call	PutByte
	call	irqst1_4					;Clean up before falling through to exit


sid_Exit
	bcf		INTCON, GIE					;Disable interrupts
	banksel	BANK0
	bsf		ADC_PORT, CS				;Unselect MAX118
	call	ChannelConfStore			;Update state of front panel switches/knobs
	goto	Main


;-  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
RotateSampleMemLeft
	;Rotate the data stored in the sample buffer memory by 0xNN positions to the left
	;Used after a pre-trigger sampling to align the data in the buffer memory
	banksel	BANK0
	movf	FSR, W						;Save the current FSR
	movwf	b0_ptFsrTemp

rsmL_1
	movf	b0_ptRotationCntr, F		;Check to see if no memory rotation is needed
	btfsc	STATUS, Z
		goto rsm_exit
	movlw	BUFFERMIN					;Not done, so setup the indirection register
	movwf	FSR

	;Start the rotation with BANK0
	bcf		STATUS, IRP
	bcf		FSR, 7
	movf	INDF, W
	movwf	b0_ptTemp0					;Save very first location, to later be put into very last location
	call	rsm_slide_lower

	;Set BANK1
	bsf		FSR, 7
	movf	INDF, W						;Get the first location in bank 1 (is the top address of bank)
	bcf		FSR, 7						;Set indirection back to bank 0
	movwf	INDF						;Deposit bank 1's first location into bank 0's last location
	bsf		FSR, 7						;Now go back to bank 1
	call	rsm_slide_higher

	;Set BANK3
	bsf		STATUS, IRP
	movf	INDF, W						;Get the first location in bank 3 (is the bottom address bank)
	bcf		STATUS, IRP					;Set indirection back to bank 1
	movwf	INDF						;Deposit bank 3's first location into bank 1's last location
	bsf		STATUS, IRP					;Now go back to bank 3
	call	rsm_slide_lower

    ;Set BANK2
	bcf		FSR, 7
	movf	INDF, W						;Get the first location in bank 2 (is the top address of bank)
	bsf		FSR, 7						;Set indirection back to bank 3
	movwf	INDF						;Deposit bank 2's first location into bank 3's last location
	bcf		FSR, 7						;Now go back to bank 2
	call	rsm_slide_higher

	movf	b0_ptTemp0, W				;Now put the very first location into the very last location
	movwf	INDF
	decfsz	b0_ptRotationCntr, F		;Check to see if memory has been rotated enough
		goto rsmL_1
	goto	rsm_exit


RotateSampleMemRight
	;Rotate the data stored in the sample buffer memory by 0xNN positions to the right
	;Used after a pre-trigger sampling to align the data in the buffer memory
	banksel	BANK0
	movf	FSR, W						;Save the current FSR
	movwf	b0_ptFsrTemp

rsmR_1
	movf	b0_ptRotationCntr, F		;Check to see if no memory rotation is needed
	btfsc	STATUS, Z
		goto rsm_exit
	movlw	BUFFERMIN					;Not done, so setup the indirection register
	movwf	FSR

	;Start the rotation with BANK2
	bsf		STATUS, IRP
	bcf		FSR, 7
	movf	INDF, W
	movwf	b0_ptTemp0					;Save very first location, to later be put into very last location
	call	rsm_slide_lower

	;Set BANK3
	bsf		FSR, 7
	movf	INDF, W						;Get the last location in bank 3 (is the top address of bank)
	bcf		FSR, 7						;Set indirection back to bank 2
	movwf	INDF						;Deposit bank 3's last location into bank 2's first location
	bsf		FSR, 7						;Now go back to bank 3
	call	rsm_slide_higher

	;Set BANK1
	bcf		STATUS, IRP
	movf	INDF, W						;Get the last location in bank 1 (is the bottom address of bank)
	bsf		STATUS, IRP					;Set indirection back to bank 3
	movwf	INDF						;Deposit bank 1's last location into bank 3's first location
	bcf		STATUS, IRP					;Now go back to bank 1
	call	rsm_slide_lower

    ;Set BANK0
	bcf		FSR, 7
	movf	INDF, W						;Get the last location in bank 0 (is the top address of bank)
	bsf		FSR, 7						;Set indirection back to bank 1
	movwf	INDF						;Deposit bank 0's last location into bank 1's first location
	bcf		FSR, 7						;Now go back to bank 0
	call	rsm_slide_higher

	movf	b0_ptTemp0, W				;Now put the very first location into the very last location
	movwf	INDF
	decfsz	b0_ptRotationCntr, F		;Check to see if memory has been rotated enough
		goto rsmR_1

rsm_exit
	;The following five instructions provide an inelegant fix to mask an occasional glitch at the
	; left side of the pre-triggered mode's displayed waveform.  This fix copies
	; the second sample locations into the first sample locations.  The pre-triggered mode's
	; displayed waveform glitch happens because of the rotation count adjustment that keeps
	; the trigger point from jittering in the pre-trigger sampling mode
	bcf		STATUS, IRP					;Set bank 0, note: FSR7 is already clear upon entry
	movf	BUFFERMIN + 2, W
	movwf	BUFFERMIN
	movf	BUFFERMIN + 3, W
	movwf	BUFFERMIN + 1
	;end of inelegant fix to pre-triggered mode's displayed waveform glitch
	movf	b0_ptFsrTemp, W				;Restore the previous FSR
	movwf	FSR
	return

rsm_slide_lower
	incf	FSR, F
	movf	INDF, W
	decf	FSR, F
	movwf	INDF
	incf	FSR, F
	movlw	BUFFERMAX
	xorwf	FSR, W
	andlw	0x7f						;Mask out the FSR7 bit from the comparison
	btfss	STATUS, Z
		goto rsm_slide_lower
	return

rsm_slide_higher
	decf	FSR, F
	movf	INDF, W
	incf	FSR, F
	movwf	INDF
	decf	FSR, F
	movlw	BUFFERMIN
	xorwf	FSR, W
	andlw	0x7f						;Mask out the FSR7 bit from the comparison
	btfss	STATUS, Z
		goto rsm_slide_higher
	return

;=============================================================================
;*****************************************************************************
;=============================================================================


;Receive and store the user settings from the PC application
;-----------------------------------------------------------------------------
ConfReceive
	call GetByte						;Receive ConfigLoc1
	movf gbl_spdata, w
	andlw ~(1 << CLOCKFREQBIT)			;Don't accept flag for clock, but set it
	if clockFreq == 20					;if necessary
		iorlw 1 << CLOCKFREQBIT
	endif
	movwf gbl_configLoc1
	call GetByte						;Receive trigger delay
	MOVFF gbl_spdata, b0_triggerDelay0
	call GetByte
	MOVFF gbl_spdata, b0_triggerDelay1
	call GetByte
	MOVFF gbl_spdata, b0_triggerDelay2
	call GetByte
	MOVFF gbl_spdata, b0_triggerDelay3
	call GetByte						;Receive sample rate
	MOVFF gbl_spdata, gbl_sampleRate0
	call GetByte
	MOVFF gbl_spdata, gbl_sampleRate1
	call GetByte
	MOVFF gbl_spdata, gbl_sampleRate2
	return

;Receive user settings from the PC application. BUT, throw most of them away!
;This is used during the SampleIntDrvn routine to prevent changing
;of state during an interrupt driven acquisition that is in progress.
;However, allow the sampleRate0,1,2 variable to be changed.  This allows
;a mis-entered large time/div sweep speed to be corrected on the fly.  Otherwise,
;the user might have to wait a long time before the sampling completed and
;the user would again get control.
;-----------------------------------------------------------------------------
ConfReceiveRateOnly
	call GetByte						;Receive ConfigLoc1
	call GetByte						;Receive trigger delay
	call GetByte
	call GetByte
	call GetByte
	call GetByte						;Receive sample rate
	MOVFF gbl_spdata, gbl_sampleRate0
	call GetByte
	MOVFF gbl_spdata, gbl_sampleRate1
	call GetByte
	MOVFF gbl_spdata, gbl_sampleRate2
	return

;Send the current DSOscope configuration to the PC application
;-----------------------------------------------------------------------------
ConfSend
	MOVLF high TOTALBUFFERSIZE, gbl_spdata
	call PutByte
	MOVLF low TOTALBUFFERSIZE, gbl_spdata
	call PutByte
	;Send clock frequency configuration
	MOVFF gbl_configLoc1, gbl_spdata
	call PutByte
	MOVFF b0_triggerDelay0, gbl_spdata
	call PutByte
	MOVFF b0_triggerDelay1, gbl_spdata
	call PutByte
	MOVFF b0_triggerDelay2, gbl_spdata
	call PutByte
	MOVFF b0_triggerDelay3, gbl_spdata
	call PutByte
	MOVFF gbl_sampleRate0, gbl_spdata
	call PutByte
	MOVFF gbl_sampleRate1, gbl_spdata
	call PutByte
	MOVFF gbl_sampleRate2, gbl_spdata
	call PutByte
	return

;Send the current DSOscope channel settings to the PC application
;-----------------------------------------------------------------------------
ChannelConfSend
	MOVFF gbl_dataConfig, gbl_spdata	;Channel configuration
	call PutByte
	clrf gbl_spdata
	call PutByte						;Channel 1 offset
	call PutByte						;Channel 2 offset
	MOVFF b0_triggerLevel, gbl_spdata
	call PutByte						;Triggerlevel
	MOVFF b0_triggerChannel, gbl_spdata
	call PutByte						;Trigger Channel
	return


;Read and store the current front panel settings of the DSOscope
;-----------------------------------------------------------------------------
ChannelConfStore
	;Format of channel data configuration byte is:	Channel 1 Gain Scale (2) bits
	;													For gain scale, 00 = 1, 01 = 2, 10 = 5
	;												Channel 2 Gain Scale (2) bits
	;												Channel 1 AC = 1 / DC = 0 (1) bit
	;												Channel 2 AC = 1 / DC = 0 (1) bit
	;												Channel 1 Attenuated by 10 = 1 / by 1 = 0
	;												Channel 2 Attenuated by 10 = 1 / by 1 = 0
	clrf gbl_dataConfig
	banksel	TRISC					;Access Bank1
	bsf TRISC, CH2SEL					;Ch2Sel high Z
	bcf TRISC, CH1SEL					;Ch1Sel output
	bsf TRISA, CH2SELG					;Ch2SelG high Z
	bcf TRISA, CH1SELG					;Ch1SelG output
	banksel	ANALOG_SEL				;Access Bank0
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

	banksel	TRISC					;Access Bank1
	bsf TRISC, CH1SEL					;Ch1Sel high Z
	bcf TRISC, CH2SEL					;Ch2Sel output
	bsf TRISA, CH1SELG					;Ch1SelG high Z
	bcf TRISA, CH2SELG					;Ch2SelG output
	banksel	ANALOG_SEL				;Access Bank0
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

	btfss ATTNPORT, CH1ATTN				;If Channel 1 is Attenuated by 10 then mark
		bsf gbl_dataConfig, 1
	btfss ATTNPORT, CH2ATTN				;If Channel 2 is Attenuated by 10 then mark
		bsf gbl_dataConfig, 0

	;Next byte/bit is Trigger Source Channel
	clrf b0_triggerChannel
	btfss TRGSRCPORT, TRGCH				;If Trigger Source is Channel 2 then mark
		bsf	b0_triggerChannel, 0

	;Next byte is Trigger Level
	bcf ADC_CONTROLPORT, ADDR0			;Select address for trigger level
	bsf ADC_PORT, ADDR1
	bcf ADC_PORT, CS					;Select maxim ADC
	bcf ADC_CONTROLPORT, RDD			;Begin conversion
	nop									;Wait 5
	nop
	nop
	nop
	nop
	movf ADC_DATAPORT, W				;Save trigger level
	bsf ADC_CONTROLPORT, RDD			;stop conversion
	bsf ADC_PORT, CS					;unselect maxim ADC
	bcf ADC_PORT, ADDR1					;Unselect address for trigger level
	movwf b0_triggerLevel
	return


;=============================================================================
;*****************************************************************************
;=============================================================================


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

;=============================================================================
end		;end of program
