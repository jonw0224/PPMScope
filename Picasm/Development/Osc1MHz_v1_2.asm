;==============================================================================
;*Author:  Jonathan Weaver, jonw0224@aim.com
;E-mail Contact: jonw0224@aim.com
;*Description: An oscilloscope program based on the PIC16F877 and the MAX118
;*Version: 1.204
;*Date: 9/27/2013
;*Filename: osc1MHz_v1_2.asm
;
;Versions:  1.000 - 3/29/2003
;           1.000 - 7/26/2004
;           1.000 - 4/2/2005
;           1.000 - 9/29/2005 -- Additional Header comments and license added
;           1.101 - 11/3/2005 -- Began to modify for use on PIC16F877
;			1.102 - 3/28/2006 -- Made trigger interrupt based, expanded 
;				sampling to 256 samples across modes
;			1.102 - 4/12/2006 -- Finished expanding sampling to 256 samples.
;				Still need to test communication, sampleDelayed and sampleXY
;				modes.
;			1.103 - 4/29/2007 -- Fixed interlaced sampling, modified so sample
;				data configuration and trigger level are measured after the
;				data buffer if filled instead of at communication.
;			1.104 - 6/27/2007 -- Added faster XY sampling modes
;			1.105 - 7/18/2007 -- Added repetitive sampling and wait for 
;				trigger	in WaitComm so the scope will respond to the PC
;			1.106 - 3/1/2009 -- changed the trigger back to not respond to PC
;			1.107 - 3/1/2009 -- Changed the trigger code to shorten the 
;				trigger delay.
;				Made scope responsive to trigger change	message.
;				Removed the use of the slave parallel port.
;				Combined SampleXY250 and SampleXY192.  Tested 3/5/2009
;			1.108 - 3/9/2009 -- changed trigger code to broaden range of 
;				trigger	delay
;			1.109 - 10/28/2009 -- tested and fixed bug with trigger code
;			1.110 - 5/12/2010 -- Added serial port support to code.
;			1.111 - 2/1/2011 -- fixed a bug with the trigger code (another one)
;			1.200 - 6/28/2011 - Modified code to handle conditional compile for 
;				hardware version 1.0 or hardware version 1.2
;			1.200 - 8/15/2012 - Added portability for PIC16F887
;			1.200 - 10/5/2012 - Modified repetative sample modes to improve 
;				trigger latency.

;I NEED TO ADD FUNCTIONALITY TO THE SOFTWARE FOR THE UPDATES BELOW

;			1.201 - 9/18/2013 - Added the ability to detect Channel Attenuation
;				and Trigger Source switches for Paul Messer's DSO Scope when 
;				assembled for a PIC16F887.  Still compatible with 1.2 hardware.
;				NEED TO TEST.
;			1.202 - 9/19/2013 - Added 500 kHz interlaced mode SampleXY500k.
;				Rewrote SampleRep5MHz and SampleRep2MHz to make room for the
;				new interlaced mode. - NEED TO TEST.
;			1.203 - 9/20/2013 - Did some more code optimization of goto
;				statements and jumps to reduce the code size.
;			1.204 - 9/27/2013 - Rewrote the main and interrupt routine to 
;				minimize the post trigger delay to 2.6 uSec (13 cycles) for 
;				all modes

;Copyright (C) 2003-2013 Jonathan Weaver
;
; This file is part of PPMScope.
;
; PPMScope is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;
;==============================================================================

;=============================================================================
; C O N F I G U R A T I O N
;=============================================================================

;	ERRORLEVEL -207, -205

PIC	equ 0x887
;PIC equ 0x877
clockFreq = 20      ;20 = 20 MHZ, 4 = 4 MHZ

if PIC == 0x887
	;=============================================================================
	; Contributed by Paul Messer
	;=============================================================================
    list p=16F887		;16f887 processor

	; '__CONFIG' directive is used to embed configuration data within .asm file.
	; The labels following the directive are located in the respective .inc file.
	; See respective data sheet for additional information on configuration word.
	
	__CONFIG _CONFIG1, _DEBUG_OFF & _LVP_OFF & _FCMEN_OFF & _IESO_OFF & _BOR_OFF & _CPD_OFF & _CP_OFF & _MCLRE_ON & _PWRTE_OFF & _WDT_OFF & _HS_OSC
	__CONFIG _CONFIG2, _WRT_OFF & _BOR40V
	
	; '__idlocs' sets the four ID locations to the hexadecimal value of expression.
	; These are not readable by the cpu, but can be read by the programning hardware.
	
	__idlocs	0x1234

else
    list p=16F877a		;16f877 or 16f877a processor

	; '__CONFIG' directive is used to embed configuration data within .asm file.
	; The labels following the directive are located in the respective .inc file.
	; See respective data sheet for additional information on configuration word.

    __config  _WDT_OFF & _HS_OSC & _LVP_OFF

	__idlocs	0x1234

endif

;=============================================================================
; C O N S T A N T S
;=============================================================================

HARDWARE equ 0x12

BUFFERMIN equ 0x20      ;Memory restrictions for the buffer
BUFFERSIZE equ D'64'    ;Number of data points to store.  In single channel
                        ;mode, all data points are for one channel, in XY mode
                        ;the data points alternate between channel 1 and
                        ;channel 2
BUFFERMAX equ BUFFERMIN+BUFFERSIZE-1
TOTALBUFFERSIZE equ BUFFERSIZE*4

;I/O Pin maps
;-----------------------------------------------------------------------------
ATTNPORT set PORTB		;Attenuation detection pins
CH1ATTN	equ	0x06
CH2ATTN	equ	0x07

TRGSRCPORT set PORTA	;Trigger source detection pins
TRGCH equ 0x03

if HARDWARE == 0x10
	SPPORT set PORTC
	SP equ 0x05

	I2CPORT set PORTC
	SDA equ 0x04            ;Pin map for the I2CPORT
	CLK equ 0x03

	ADC_CONTROLPORT set PORTB
	ADC_PORT set PORTB
	RDD equ 0x02            ;Pin map for the ADC

	TRIGGERPORT set PORTB
	TRIGGER equ 0x00

	SERIALPORT set PORTC
	RX equ 0x07
	TX equ 0x06

	ADDR2 equ 0x05          ;ADDR2 and ADDR1 not used in this program (later use)
	ADDR1 equ 0x04
	ADDR0 equ 0x03          ;Least significant bit of the ADC channel address
	CS equ 0x01

	ADC_DATAPORT set PORTD

	ANALOG_SEL set PORTC
	CH1SEL equ 0x01
	CH2SEL equ 0x02
	
	ANALOG_GAIN set PORTA
	GAIN1 equ 0x00
	GAIN2 equ 0x01
	CH1SELG equ 0x04
	CH2SELG equ 0x05

	ANALOG_ACDC set PORTC
	ACDCMODE equ 0x00

else
	SPPORT set PORTA
	SP equ 0x02
	;SPPORT set PORTB
	;SP equ 0x05

	SERIALPORT set PORTC
	RX equ 0x07
	TX equ 0x06

	ADC_CONTROLPORT set PORTE
	RDD equ 0x00
	ADDR0 equ 0x01

	TRIGGERPORT set PORTB
	TRIGGER equ 0x00

	I2CPORT set PORTB
	SDA equ 0x04
	CLK equ 0x05

	ADC_PORT set PORTB
	ADDR2 equ 0x03          
	ADDR1 equ 0x02
	CS equ 0x01

	ADC_DATAPORT set PORTD

	ANALOG_SEL set PORTC
	CH1SEL equ 0x01
	CH2SEL equ 0x02

	ANALOG_GAIN set PORTA
	GAIN1 equ 0x00
	GAIN5 equ 0x01
	CH1SELG equ 0x04
	CH2SELG equ 0x05

	ANALOG_ACDC set PORTC
	ACDCMODE equ 0x00

endif

;Configuration memory map
;-----------------------------------------------------------------------------
;Bit map for configLoc1
TRIGGERPOSBIT equ 0x07  	;1 is positive slope trigger, 0 is negative slope
TRIGGERENBIT equ 0x06   	;1 is trigger enabled, 0 is no trigger
CLOCKFREQBIT equ 0x05   	;1 is 20 MHz, 0 is 4 MHz
CHANNELBIT equ 0x04     	;1 is channel 2, 0 is channel 1
FREQMODEBIT3 equ 0x03   	;Reserve the bits in configLoc1 for the frequency modes
FREQMODEBIT2 equ 0x02
FREQMODEBIT1 equ 0x01
FREQMODEBIT0 equ 0x00

FREQSAMPLE1M equ D'0'   		;Table of frequency modes, 0 to 15
FREQSAMPLE833K equ D'1'
FREQSAMPLE625K equ D'2'
FREQSAMPLE417K equ D'3'
FREQSAMPLE250K equ D'4'
FREQSAMPLEDELAYED equ D'5'
FREQSAMPLEREP5M equ D'6'		;Ensure trigger is enabled
FREQSAMPLEREP2M equ D'7'		;Ensure trigger is enabled
FREQSAMPLEXY417K equ D'8'
FREQSAMPLEXY250K equ D'9'
FREQSAMPLEXY192K equ D'10'
FREQSAMPLEXYDELAYED equ D'11'
FREQSAMPLEXYINT equ D'12'
FREQSAMPLEXY500k equ D'13'

;=============================================================================
; V A R I A B L E S
;=============================================================================

CBLOCK  0x70			;Shared General Purpose Registers, accessible anywhere
    configLoc1          ;Configuration mode
    triggerDelay1       ;trigger delay (3 bytes)
    triggerDelay2
	triggerDelay3
    sampleRate1         ;sample rate delay (2 bytes)
    sampleRate2
    cntra               ;general use counter
    cntrb               ;second general use counter
    cntrc               ;third general use counter
	functptrhigh		;function pointer high byte, selects sampling mode
    functptrlow			;function pointer low byte
    cntr				;counter variable for i2cs, only used in i2cs
	i2csdata			;data for i2cs, only used in communications routines
	dataConfig			;the data configuration and statusTemp for interrupt
	triggerLevel		;the trigger level and wregTemp for interrupt
	triggerChannel		;the trigger channel, only used as the trigger channel
ENDC

statusTemp equ dataConfig	;Dual purpose registers, named appropriately in 
wregTemp equ triggerLevel	;context

;=============================================================================
; M A C R O S
;=============================================================================

if PIC == 0x887				;Include appropriate processor header
	include "p16f887.inc"	
else
    include "p16F877a.inc"
endif
    include "equality.inc"	;Simplifies some testing
    include "banks.inc"		;Simplifies bank handling
    include "asmext.inc"	;Some common asm macros

;Sets up PCLATH for a jump to the address given
;------------------------------------------------------------------------------
MGOTOSETUP macro address
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
	endm

;Sets up PCLATH and jumps to address (universal jump anywhere)
;------------------------------------------------------------------------------
MGOTO macro address
	MGOTOSETUP address
	goto address
	endm

;Recieve configuration from the PC
;------------------------------------------------------------------------------
CONFRECIEVE macro
    call GetByte	                ;Recieve ConfigLoc1
    movf i2csdata, w
    andlw ~(1 << CLOCKFREQBIT)      ;Don't accept flag for clock, but set it
    if clockFreq == 20              ;if necessary
        iorlw 1 << CLOCKFREQBIT
    endif
    movwf configLoc1
    call GetByte	                ;Recieve trigger delay
    MOVFF i2csdata, triggerDelay1
    call GetByte
    MOVFF i2csdata, triggerDelay2
    call GetByte                
    MOVFF i2csdata, triggerDelay3
    call GetByte					;Recieve sample rate
    MOVFF i2csdata, sampleRate1
    call GetByte
    MOVFF i2csdata, sampleRate2
    endm

;Send configuration to the PC
;------------------------------------------------------------------------------
CONFSEND macro
    ;Send number of datapoints (2 bytes)
    MOVLF high TOTALBUFFERSIZE, i2csdata
    call PutByte
    MOVLF low TOTALBUFFERSIZE, i2csdata
    call PutByte
    ;Send clock frequency configuration
    MOVFF configLoc1, i2csdata
    call PutByte
    MOVFF triggerDelay1, i2csdata
    call PutByte
    MOVFF triggerDelay2, i2csdata
    call PutByte
    MOVFF triggerDelay3, i2csdata
    call PutByte
    MOVFF sampleRate1, i2csdata
    call PutByte
    MOVFF sampleRate2, i2csdata
    call PutByte
    endm

;Send front panel status to the PC
;------------------------------------------------------------------------------
CHANNELCONFSEND macro
	MOVFF dataConfig, i2csdata		;Channel configuration
    call PutByte
	clrf i2csdata
    call PutByte					;Channel 1 offset
    call PutByte					;Channel 2 offset
	MOVFF triggerLevel, i2csdata
    call PutByte					;Triggerlevel
	MOVFF triggerChannel, i2csdata
	call PutByte					;Trigger source channel
	endm

;Get front panel status
;------------------------------------------------------------------------------
CHANNELCONFSTORE macro
    ;Format of channel configuration is: Channel 1 Scale (2) bits
    ;                                    For scale, 00 = 1, 01 = 2, 10 = 5
    ;                                    Channel 2 Scale (2) bits
    ;                                    Channel 1 AC = 1 / DC = 0 (1) bit
    ;                                    Channel 2 AC = 1 / DC = 0 (1) bit
    ;                                    Channel 1 Attenuation (No Attenuation = 1, attenuation by 10 = 0) (1) bit
	;									 Channel 2 Attenuation (No attenuation = 1, attenuation by 10 = 0) (1) bit
    clrf dataConfig
	BNKSEL TRISC
	bcf TRISC, CH1SEL				;Ch1Sel output
	bsf TRISC, CH2SEL				;Ch2Sel high Z
	bcf TRISA, CH1SELG				;Ch1Sel output
	bsf TRISA, CH2SELG				;Ch2Sel high Z
	BNKSEL ANALOG_SEL	
	bcf ANALOG_SEL, CH1SEL			;Ch1Sel low
	bcf ANALOG_GAIN, CH1SELG		;Ch1SelG low
	if HARDWARE == 0x10
		bsf dataConfig, 7
		btfss ANALOG_GAIN, GAIN1		;If Gain1 then unmark
			bcf dataConfig, 7
		btfss ANALOG_GAIN, GAIN2		;If Gain2 then unmark
			bcf dataConfig, 7
		btfss ANALOG_GAIN, GAIN2		;If Gain2 then mark
			bsf dataConfig, 6
	else
		bsf dataConfig, 6				;Assume Gain = 2
		btfss ANALOG_GAIN, GAIN1		;If Gain1 then unmark
			bcf dataConfig, 6
		btfss ANALOG_GAIN, GAIN5		;If Gain5 then unmark
			bcf dataConfig, 6
		btfss ANALOG_GAIN, GAIN5		;If Gain5 then mark
			bsf dataConfig, 7
	endif
	btfsc ANALOG_ACDC, ACDCMODE		;If DC coupling open (implies AC coupling) then mark
		bsf dataConfig, 3
	bsf ANALOG_SEL, CH1SEL
	bsf ANALOG_GAIN, CH1SELG
	BNKSEL TRISC
	bsf TRISC, CH1SEL				;Ch1Sel high Z
	bcf TRISC, CH2SEL				;Ch2Sel output
	bsf TRISA, CH1SELG				;Ch1Sel high Z
	bcf TRISA, CH2SELG				;Ch2Sel output
	BNKSEL ANALOG_SEL
	bcf ANALOG_SEL, CH2SEL			;Ch2Sel low
	bcf ANALOG_GAIN, CH2SELG		;Ch1SelG low
	if HARDWARE == 0x10
		bsf dataConfig, 5
		btfss ANALOG_GAIN, GAIN1		;If Gain1 then unmark
			bcf dataConfig, 5
		btfss ANALOG_GAIN, GAIN2		;If Gain2 then unmark
			bcf dataConfig, 5
		btfss ANALOG_GAIN, GAIN2		;If Gain2 then mark
			bsf dataConfig, 4
	else
		bsf dataConfig, 4				;Assume Gain = 2
		btfss ANALOG_GAIN, GAIN1		;If Gain1 then unmark
			bcf dataConfig, 4
		btfss ANALOG_GAIN, GAIN5		;If Gain5 then unmark
			bcf dataConfig, 4
		btfss ANALOG_GAIN, GAIN5		;If Gain5 then mark
			bsf dataConfig, 5
	endif
	btfsc ANALOG_ACDC, ACDCMODE		;If DC coupling open (implies AC coupling) then mark
		bsf dataConfig, 2
    bsf ANALOG_SEL, CH2SEL
	bsf ANALOG_GAIN, CH2SELG

	btfss ATTNPORT, CH1ATTN				;If Channel 1 is Attenuated by 10 then mark
		bsf dataConfig, 1
	btfss ATTNPORT, CH2ATTN				;If Channel 2 is Attenuated by 10 then mark
		bsf dataConfig, 0

	;Next byte is Trigger Level
	bcf ADC_CONTROLPORT, ADDR0			;Select address for trigger level
	bsf ADC_PORT, ADDR1
	bcf ADC_PORT, ADDR2
	bcf ADC_PORT, CS					;Select maxim ADC
	bcf ADC_CONTROLPORT, RDD			;Begin conversion

	;Next byte/bit is Trigger Source Channel.  Get Trigger Source while waiting for conversion
	clrf triggerChannel
	btfss TRGSRCPORT, TRGCH				;If Trigger Source is Channel 2 then mark
		bsf	triggerChannel, 0

	movf ADC_DATAPORT, w				;Save trigger level
	bsf ADC_CONTROLPORT, RDD			;stop conversion
	bsf ADC_PORT, CS					;unselect
	bcf ADC_CONTROLPORT, ADDR0			;Unselect address for trigger level
	bcf ADC_PORT, ADDR1
	bcf ADC_PORT, ADDR2
	movwf triggerLevel
    endm


;=============================================================================
; R E S E T   V E C T O R
;=============================================================================
org 0x000
;Initialize
;First three lines of initialization included here to save on memory.
    MOVLF B'11000110', ADC_CONTROLPORT
    clrf ADC_DATAPORT
    goto Initial

;=============================================================================
; I N T E R R U P T  V E C T O R
;=============================================================================
org 0x004
IntHandler
	btfsc INTCON, PEIE					;Check for Timer 1 interrupt
		goto IntSaveContext
IntHandlerB
    bcf STATUS, RP0						;Ensure we're in Bank0
	movf cntr, w						;Skip the post trigger delay if not used
	addwf PCL, f
IntHandlerC
	decfsz cntra, f						;Handle the post trigger delay
        goto IntHandlerC
    decfsz cntrb, f
		goto IntHandlerC
	decfsz cntrc, f
		goto IntHandlerC
MainSelect
	MOVFF functptrhigh, PCLATH			;Jump to the proper sampling mode
	MOVFF functptrlow, PCL
IntSaveContext
    movwf	wregTemp					;Save off current W register contents
	swapf	STATUS, w					;Move status register into W register
	movwf	statusTemp					;Save off contents of a "swapped" STATUS register
	bcf STATUS, RP0						;Ensure we're in Bank0
	goto MainSelect

;=============================================================================
; I N C L U D E S
;=============================================================================
    include "i2cs.inc"

;=============================================================================
; I N I T I A L I Z E
;=============================================================================
Initial
if HARDWARE == 0x10
 
   clrf PORTA
    BNKSEL TRISA
    MOVLF B'00000011', TRISA			;Configure PORTA
    MOVLF B'11000000', OPTION_REG       ;Interrupt on rising edge of RB0
	MOVLF B'00010000', INTCON           ;Interrupt on RB0 only, but not enabled yet
    MOVLF B'00000001', ADC_CONTROLPORT
    MOVLF B'11111111', ADC_DATAPORT
    MOVLF B'00000111', TRISE            ;Set up as inputs
	MOVLF B'00000111', ADCON1           ;Turn off A/D converter
    MOVLF B'11111001', TRISC			;Configure PORTC
	MOVLF D'21', SPBRG					;Configure serial port.  Set to 57,600 baud (nominally 56,818 baud at 20 MHz clock).
	MOVLF B'00100100', TXSTA			;Initialize transmit in asynchronous mode, high speed mode
    BNKSEL RCSTA
	MOVLF B'10000000', RCSTA			;Eight bit recieve not yet enabled
    bcf STATUS, IRP                     ;Ensure indirect addressing of Bank0 and Bank1
    clrf ADCON0
	bsf TRGSRCPORT, TRGCH				;Ensure that trigger source is read as channel 1

else
    if PIC == 0x887

		;Contributed by Paul Messer

		clrf PORTA
		BNKSEL	ANSEL						;Access bank3
		clrf	ANSEL						;Turn off analog mode on RE2,1,0 and RA5,3,2,1,0 so the pins read digital
		clrf	ANSELH						;Turn off analog mode on RB5,0,4,1,3,2 so the pins read digital
		MOVLF 0x08, BAUDCTL					;Set the Serial Port baud rate generators
		BNKSEL	SPBRG						;Access bank 1 and continue setting baud rate generators
		MOVLF 0x56, SPBRG					; for 57.6K baud
		clrf SPBRGH
		MOVLF 0x24, TXSTA					;Set the Serial Port Transmitter configuration
		MOVLF B'11000000', WPUB				;Turn on weak pull-ups for CH1ATTN and CH2ATTN input signals
		MOVLF B'00010000', INTCON			;Interrupt on RB0 only, but not enabled yet
		MOVLF B'00010111', TRISA			;Configure PORTA
		MOVLF B'01000000', OPTION_REG		;Interrupt on rising edge of RB0 plus enable PORTB's weak pull-ups
		MOVLF B'11110001', TRISB			;Allow RB7, RB6 to be inputs with weak pull-ups
		MOVLF B'11111111', TRISD
		MOVLF B'00000100', TRISE			;Set up USB detect as input, CS and ADDR0 as outputs
		MOVLF B'10111001', TRISC			;Configure PORTC
		BNKSEL	RCSTA						;Access bank 0
		MOVLF 0x90, RCSTA					;Set the Serial Port Receiver configuration
		bcf STATUS, IRP						;Ensure indirect addressing of Bank0 and Bank1
		clrf ADCON0							;Make sure PIC's ADC is off
	
	else
		clrf PORTA
		BNKSEL TRISA
		MOVLF B'00010111', TRISA			;Configure PORTA
		MOVLF B'11000000', OPTION_REG       ;Interrupt on rising edge of RB0
		MOVLF B'00010000', INTCON           ;Interrupt on RB0 only, but not enabled yet
		MOVLF B'00110001', TRISB
		MOVLF B'11111111', TRISD
		MOVLF B'00000100', TRISE            ;Set up USB detect as input, CS and ADDR0 as outputs
		MOVLF B'00000111', ADCON1           ;Turn off A/D converter
		MOVLF B'10111001', TRISC			;Configure PORTC
		MOVLF D'21', SPBRG					;Set to 57,600 baud (nominally 56,818 baud at 20 MHz clock).
		MOVLF B'00100100', TXSTA			;Initialize transmit in asynchronous mode, high speed mode
		BNKSEL RCSTA	
		MOVLF B'10000000', RCSTA			;Eight bit recieve not yet enabled
		bcf STATUS, IRP                     ;Ensure indirect addressing of Bank0 and Bank1
		clrf ADCON0
		MOVLF B'11000010', PORTB			;Ensure RB7 and RB6 are high
		bsf TRGSRCPORT, TRGCH				;Ensure that trigger source is read as channel 1

	endif
	
	MOVLF B'00000101', T1CON				;Set up for timer1 with prescaler of 1
	
endif
	
;=============================================================================
; M A I N
;=============================================================================

;Debug / testing code
;	MOVLF D'0', configLoc1
;	bsf configLoc1, TRIGGERENBIT
;	MOVLF D'0', triggerDelay1
;	MOVLF D'1', triggerDelay2
;	MOVLF D'5', triggerDelay3
;	movlw D'1'
;	movwf sampleRate1
;	movwf sampleRate2
;	movwf cntra
;	movwf cntrb
;	movwf cntrc
;	goto MainA

Main
;	goto IntHandler

;Normal main code
    call WaitComm
MainA
	clrf PCLATH							;Prepare for jumps
	movf configLoc1, w                  ;Put configuration in WREG
    andlw (1<<FREQMODEBIT3)|(1<<FREQMODEBIT2)|(1<<FREQMODEBIT1)|(1<<FREQMODEBIT0)   ;Unmask FreqMode
	call loadFunctptrlow				;Setup functptrlow based on frequency mode
	movwf functptrlow
	movf configLoc1, w                  ;Put configuration in WREG
    andlw (1<<FREQMODEBIT3)|(1<<FREQMODEBIT2)|(1<<FREQMODEBIT1)|(1<<FREQMODEBIT0)   ;Unmask FreqMode
	call loadFunctptrhigh				;Setup functptrhigh based on frequency mode
	movwf functptrhigh
MainB
    bcf ADC_CONTROLPORT, ADDR0          ;Select Channel of ADC
    btfsc configLoc1, CHANNELBIT
        bsf ADC_CONTROLPORT, ADDR0
    bcf ADC_PORT, CS	         		;Select MAX114
    btfss configLoc1, TRIGGERENBIT      ;Decide if trigger is enabled.  If so, wait on interrupt
        goto MainSelect        
MainWaitTrig                            ;Trigger is enabled, set up interrupt
	incf triggerDelay1, w				;Set up cntrc = triggerDelay1 + 1
	movwf cntrc
	incf triggerDelay2, w				;Set up cntrb = triggerDelay2 + 1
	movwf cntrb	
	clrf cntr							;Assume cntr is not used for trigger delay, set to zero
	movlw D'3'							;If triggerDelay3 <= 3 continue otherwise jump
	subwf triggerDelay3, w
	movwf cntra							
	incf cntra, f						;cntra = triggerDelay3 - 2
	btfsc STATUS, C						;If triggerDelay3 < 3 continue otherwise jump
		goto MainSetTriggerDelay
    movf triggerDelay1, f				;If triggerDelay1 = 0 continue otherwise jump
	btfss STATUS, Z
		goto MainSetTriggerDelay
	movf triggerDelay2, f				;If triggerDelay2 = 0 continue otherwise jump
	btfss STATUS, Z
		goto MainSetTriggerDelay
	sublw D'0'							;wreg = 3 - triggerDelay3
	movwf cntr
	rlf cntr, f							;cntr = 2*(3 - triggerDelay3), cntr is used for low triggerdelays
	goto MainSkipSetTriggerDelay
MainSetTriggerDelay						;Since triggerDelay3 >= 3, we need to increment cntrb and cntrc
	movlw D'1'
	btfss STATUS, C
		subwf cntrb, f
	btfss STATUS, C
		subwf cntrc, f
MainSkipSetTriggerDelay

;Debug code
;	goto IntHandler

;Normal code
    BNKSEL OPTION_REG
    bcf OPTION_REG, INTEDG              ;Assume trigger on falling edge
    movf configLoc1, w                  ;Get the trigger status
    andlw 0x01 << TRIGGERPOSBIT
    skipZero                            ;Positive or negative trigger
        bsf OPTION_REG, INTEDG          ;Trigger on rising edge
    BNKSEL 0x0000
    bcf INTCON, INTF                    ;Ensure that the RB0 interrupt flag is clear
    bsf INTCON, GIE                     ;Enable RB0 Interrupt
MainWTrigB
    goto Main

                                        ;Note that the gitter on the interrupt is
                                        ;1 cycles.  This translates to 200 ns
                                        ;on the PIC running at 20 MHz

;=============================================================================
; S U B R O U T I N E S
;=============================================================================

;Lookup table used to set functptrlow
;-----------------------------------------------------------------------------
loadFunctptrlow
	addwf PCL, f
	retlw (low Sample1M)				;FreqMode = 0
    retlw (low Sample833k)				;FreqMode = 1
	retlw (low Sample625k)				;FreqMode = 2
	retlw (low Sample417k250k)			;FreqMode = 3
	retlw (low Sample417k250k)			;FreqMode = 4
    retlw (low SampleDelayed)			;FreqMode = 5
    retlw (low SampleRep5M)				;FreqMode = 6
	retlw (low SampleRep2M)				;FreqMode = 7
	retlw (low SampleXY417k)			;FreqMode = 8
	retlw (low SampleXY250k192k)		;FreqMode = 9
	retlw (low SampleXY250k192k)		;FreqMode = 10
    retlw (low SampleXYDelayed)			;FreqMode = 11
	retlw (low SampleIntStart)			;FreqMode = 12
	retlw (low SampleXY500k)			;FreqMode = 13

;Lookup table used to set functptrhigh
;-----------------------------------------------------------------------------
loadFunctptrhigh
	addwf PCL, f
	retlw (high Sample1M)				;FreqMode = 0
    retlw (high Sample833k)				;FreqMode = 1
	retlw (high Sample625k)				;FreqMode = 2
	retlw (high Sample417k250k)			;FreqMode = 3
	retlw (high Sample417k250k)			;FreqMode = 4
    retlw (high SampleDelayed)			;FreqMode = 5
    retlw (high SampleRep5M)			;FreqMode = 6
	retlw (high SampleRep2M)			;FreqMode = 7
	retlw (high SampleXY417k)			;FreqMode = 8
	retlw (high SampleXY250k192k)		;FreqMode = 9
	retlw (high SampleXY250k192k)		;FreqMode = 10
    retlw (high SampleXYDelayed)		;FreqMode = 11
	retlw (high SampleIntStart)			;FreqMode = 12
	retlw (high SampleXY500k)			;FreqMode = 13

;Wait for command from computer and respond accordingly
;-----------------------------------------------------------------------------
WaitComm
    call WaitByte					;Wait for recieve
WaitComm_Test						;Determine the command and the response
    skipEqLF B'11111000', i2csdata
        goto WaitComm_Conf
WaitComm_Data
    MOVLF B'11011100', i2csdata     ;Send beginning of message
    call PutByte
    MOVLF BUFFERMIN, FSR            ;Set pointer to beginning of queue
    MOVLF BUFFERSIZE, cntrb			;Set counter
WaitComm_SendDataA
    MOVFF INDF, i2csdata            ;Get data ready to send
    incf FSR, F                     ;Increment pointer
    call PutByte	                ;Send data
    andlw 0xFF                      ;Until end of queue
    skipZero
        goto WaitComm_SendDataExit
    decfsz cntrb, f
    	goto WaitComm_SendDataA
	MOVLF BUFFERSIZE, cntrb			;Set counter
	bsf FSR, 7						;Bank 1
	decf FSR, f
WaitComm_SendDataB
    MOVFF INDF, i2csdata            ;Get data ready to send
    decf FSR, F                     ;Increment pointer
    call PutByte	                ;Send data
    andlw 0xFF                      ;Until end of queue
    skipZero
        goto WaitComm_SendDataExit
    decfsz cntrb, f
    	goto WaitComm_SendDataB
	MOVLF BUFFERSIZE, cntrb			;Set counter
	bsf STATUS, IRP					;Bank 3
	incf FSR, f
WaitComm_SendDataC
    MOVFF INDF, i2csdata            ;Get data ready to send
    incf FSR, F                     ;Increment pointer
    call PutByte	                ;Send data
    andlw 0xFF                      ;Until end of queue
    skipZero
        goto WaitComm_SendDataExit
    decfsz cntrb, f
    	goto WaitComm_SendDataC
	MOVLF BUFFERSIZE, cntrb			;Set counter
	bcf FSR, 7						;Bank 3
	decf FSR, f
WaitComm_SendDataD
    MOVFF INDF, i2csdata            ;Get data ready to send
    decf FSR, F                     ;Increment pointer
    call PutByte	                ;Send data
    andlw 0xFF                      ;Until end of queue
    skipZero
        goto WaitComm_SendDataExit
    decfsz cntrb, f
    	goto WaitComm_SendDataD
WaitComm_SendDataExit
	bcf FSR, 7						;Bank 0
	bcf STATUS, IRP
    CHANNELCONFSEND
    goto WaitComm
WaitComm_Conf
    skipEqLF B'11111001', i2csdata
        goto WaitComm_Rec
    MOVLF B'11011101', i2csdata     ;Send beginning of message
    call PutByte	
    CONFSEND
    goto WaitComm
WaitComm_Rec
    skipEqLF B'11111010', i2csdata
        goto WaitComm_BreakTrigger   
    MOVLF B'11011110', i2csdata     ;Send beginning of message
    call PutByte
    CONFRECIEVE
	return
WaitComm_BreakTrigger
    skipEqLF B'11110011', i2csdata		;message is recieved
    	goto WaitComm					;No Valid Message Sent
    MOVLF B'11011100', i2csdata     	;Respond
    call PutByte
   	bcf INTCON, GIE						;Disable RB0 Interrupt
	goto WaitComm

;WaitByte is used to wait for a byte either on serial port or on the i2c port
;------------------------------------------------------------------------------
WaitByte
	btfss SPPORT, SP
	    goto I2CSWaitStart		
	goto GetByteSerial

;GetByte is used to recieve a byte on either a serial port or on the i2c port
;------------------------------------------------------------------------------
GetByte
	btfss SPPORT, SP
	    goto I2CSGetByte		
GetByteSerial
	bsf RCSTA, CREN
	btfss PIR1, RCIF			
		goto GetByteSerial
GetByteSerialB
	btfss RCSTA, FERR			;Handle the frame error
		goto GetByteSerialC
	movf RCREG, w				;Throw away data with errors
	goto GetByteSerial
GetByteSerialC
	btfss RCSTA, OERR			;Handle the over run error
		goto GetByteSerialE
	bcf RCSTA, CREN				;Reset the recieve logic
	bsf RCSTA, CREN
GetByteSerialD
	movf RCREG, w				;Throw away data with errors
	btfsc PIR1, RCIF
	    goto GetByteSerialD
	goto GetByteSerial
GetByteSerialE					;No errors if we got here	
	MOVFF RCREG, i2csdata		;Read byte from serial FIFO
	bcf RCSTA, CREN
	retlw 0
	
;PutByte is used to put a byte either on the serial port or on the i2c port
;------------------------------------------------------------------------------
PutByte
	btfss SPPORT, SP
		goto I2CSPutByte
PutByteSerial
	btfss PIR1, TXIF
		goto PutByteSerial
	MOVFF i2csdata, TXREG
	retlw 0

;Delay used to adjust sample rate and trigger delay
;Any delay due to using a call must be added (i.e. delay doesn't include call
;statement)
;Delay = 5+7*(cntrb:cntra)+3*cntrb if cntra > 0, cntrb >= 0
;If cntra = 0 then delay as if cntra = 256
;If cntrb:cntra = 0x0000 then Delay as if cntrb = 255, cntra = 256
;-----------------------------------------------------------------------------
Delay
    movlw 0x01
DelayLoop
    subwf cntra, F
    btfss STATUS, C
        subwf cntrb, F
    movf cntra, F
    skipZero
        goto DelayLoop
    movf cntrb, F
    skipZero
        goto DelayLoop
	return

;ADCShutdown, shutsdown the MAX114/MAX118
;-----------------------------------------------------------------------------
ADCShutdown
    movwf INDF                      ;Save to QUEUE
    bsf ADC_PORT, CS		        ;Unselect MAX114
    bcf STATUS, IRP					;Set bank = 0
	CHANNELCONFSTORE
    goto Main

;Interrupt based sampling mode.  Original idea from Paul Messer
;Interrupt based sampling mode start
;-----------------------------------------------------------------------------
SampleIntStart
	bcf ADC_CONTROLPORT, RDD		;Begin conversion
	bcf T1CON, TMR1ON				;Timer1 off
	comf sampleRate1, w				;Set timer value
	movwf TMR1H
	comf sampleRate2, w
	movwf TMR1L
	bsf T1CON, TMR1ON				;Timer1 on
	bsf INTCON, PEIE				;Set up Timer1 interrupt
	bcf PIR1, TMR1IF
	BNKSEL PIE1
	bsf PIE1, TMR1IE
	BNKSEL 0x0000
	bsf INTCON, GIE
	MOVLF BUFFERMIN, FSR			;Initialize pointer
	MOVLF BUFFERSIZE-1, cntra
	movf ADC_DATAPORT, w			;Sample
	movwf INDF
	incf FSR, F
	MOVLF D'66', functptrlow
SampleIntReturn
	;restore previous state	
    swapf	statusTemp, w			;retrieve copy of STATUS register and "unswap" it
    movwf   STATUS					;restore pre-isr STATUS register contents
    swapf   wregTemp, f				;the ol' swap'er-roo to
    swapf   wregTemp, w				;restore pre-isr W register contents without clobbering STATUS register
    retfie							;return from interrupt and activate GIE
	
SampleIntBank0
	bcf ADC_CONTROLPORT, RDD		;Begin Conversion
	
	movf ADC_DATAPORT, w			;Sample
	bsf ADC_CONTROLPORT, RDD		;Stop conversion
	movwf INDF
	incf FSR, F
	
	
;Sample Delayed
;Sampling rate = 5e6 / (19 + 7 * SAMPLERATE1:SAMPLERATE2 + 3 * SAMPLERATE1) with 20 MHz clock
;Sampling rate = 1e6 / (19 + 7 * SAMPLERATE1:SAMPLERATE2 + 3 * SAMPLERATE1) with 4 MHz clock
;-----------------------------------------------------------------------------
SampleDelayed
    bcf ADC_CONTROLPORT, RDD        		;Begin Conversion
    MOVLF BUFFERSIZE-1, cntrc       ;Initialize counter, use cntrc as counter
    MOVLF BUFFERMIN, FSR            ;Initialize pointer
    MOVFF sampleRate2, cntra        ;Restore cntra
    MOVFF sampleRate1, cntrb        ;Restore cntrb
	nop
    call Delay
SampleDelayedLoopA
    movf ADC_DATAPORT, W            ;Sample
    bsf ADC_CONTROLPORT, RDD	        	;Stop conversion
    bcf ADC_CONTROLPORT, RDD   		    ;Begin next conversion
    movwf INDF                      ;Save to QUEUE
    incf FSR, F                     ;Increment QUEUE pointer
StSampleDelayedLoopA
    MOVFF sampleRate2, cntra        ;Restore cntra
    MOVFF sampleRate1, cntrb        ;Restore cntrb
    call Delay
    decfsz cntrc, F             ;Increment counter, 64 samples?
        goto SampleDelayedLoopA
	nop
	movf ADC_DATAPORT, W			;Last sample in Bank 1
    bsf ADC_CONTROLPORT, RDD        		;Stop conversion
    bcf ADC_CONTROLPORT, RDD        		;Begin next conversion
    movwf INDF                      ;Save to QUEUE
	bsf FSR, 7						;Move QUEUE pointer to Bank 2
	MOVLF BUFFERSIZE-1, cntrc
    MOVFF sampleRate2, cntra         ;Restore cntra
    MOVFF sampleRate1, cntrb        ;Restore cntrb
	call Delay
	nop
SampleDelayedLoopB
    movf ADC_DATAPORT, W            ;Sample
    bsf ADC_CONTROLPORT, RDD        ;Stop conversion
    bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
    movwf INDF                      ;Save to QUEUE
    decf FSR, F                     ;Increment QUEUE pointer
    MOVFF sampleRate2, cntra         ;Restore cntra
    MOVFF sampleRate1, cntrb        ;Restore cntrb
    call Delay
    decfsz cntrc, F		            ;Increment counter, 64 samples?
        goto SampleDelayedLoopB
	nop
	movf ADC_DATAPORT, W			;Last sample in Bank 2
    bsf ADC_CONTROLPORT, RDD        ;Stop conversion
    bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
    movwf INDF                      ;Save to QUEUE
	bsf STATUS, IRP					;Move QUEUE pointer to Bank 4
	MOVLF BUFFERSIZE-1, cntrc
    MOVFF sampleRate2, cntra         ;Restore cntra
    MOVFF sampleRate1, cntrb        ;Restore cntrb
	call Delay
	nop
SampleDelayedLoopC
    movf ADC_DATAPORT, W            ;Sample
    bsf ADC_CONTROLPORT, RDD        ;Stop conversion
    bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
    movwf INDF                      ;Save to QUEUE
    incf FSR, F                     ;Increment QUEUE pointer
    MOVFF sampleRate2, cntra         ;Restore cntra
    MOVFF sampleRate1, cntrb        ;Restore cntrb
    call Delay
    decfsz cntrc, F		            ;Increment counter, 64 samples?
        goto SampleDelayedLoopC
	nop
	movf ADC_DATAPORT, W			;Last sample in Bank 4
    bsf ADC_CONTROLPORT, RDD        ;Stop conversion
    bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
    movwf INDF                      ;Save to QUEUE
	bcf FSR, 7						;Move QUEUE pointer to Bank 2
	MOVLF BUFFERSIZE-1, cntrc
    MOVFF sampleRate2, cntra         ;Restore cntra
    MOVFF sampleRate1, cntrb        ;Restore cntrb
	call Delay
	nop
SampleDelayedLoopD
    movf ADC_DATAPORT, W            ;Sample
    bsf ADC_CONTROLPORT, RDD        ;Stop conversion
    bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
    movwf INDF                      ;Save to QUEUE
    decf FSR, F                     ;Increment QUEUE pointer
    MOVFF sampleRate2, cntra         ;Restore cntra
    MOVFF sampleRate1, cntrb        ;Restore cntrb
    call Delay
    decfsz cntrc, F		            ;Increment counter, 64 samples?
        goto SampleDelayedLoopD
    nop
    movf ADC_DATAPORT, W            ;Last sample
    bsf ADC_CONTROLPORT, RDD        ;Stop conversion
    goto ADCShutdown

;SampleXYDelayed
;Sampling rate = 5e6 / (26 + 7 * SAMPLERATE1:SAMPLERATE2 + 3 * SAMPLERATE1) with 20 MHz clock
;Sampling rate = 5e6 / (26 + 7 * SAMPLERATE1:SAMPLERATE2 + 3 * SAMPLERATE1) with 4 MHz clock
;SampleXYDelayed does not sample X and Y at the same time.  Y is sampled 6 clock cycles
;behind X.  For a 20 MHz clock this is 1.2 uS, for a 4 MHz clock this is 6 uS.
;-----------------------------------------------------------------------------
SampleXYDelayed
    bcf ADC_CONTROLPORT, RDD        ;Begin Conversion
    bsf ADC_CONTROLPORT, ADDR0 		    ;Set channel to Y
    MOVLF BUFFERMIN, FSR            ;Initialize pointer
    movf ADC_DATAPORT, W            ;Sample X
	bsf ADC_CONTROLPORT, RDD        ;Stop conversion
	bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
    bcf ADC_CONTROLPORT, ADDR0      ;Set channel to X
    movwf INDF                      ;Save to QUEUE
    incf FSR, F                     ;Increment QUEUE pointer
    MOVLF BUFFERSIZE/2-1, cntrc   	;Initialize counter, use cntrc as counter
    MOVFF sampleRate2, cntra         ;Restore cntra
    MOVFF sampleRate1, cntrb        ;Restore cntrb
	call Delay
	nop
SampleXYDelayedLA
    movf ADC_DATAPORT, W            ;Sample Y
    bsf ADC_CONTROLPORT, RDD        ;Stop conversion
	bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
	bsf ADC_CONTROLPORT, ADDR0      ;Set channel to Y
    movwf INDF                      ;Save to QUEUE
    incf FSR, F                     ;Increment QUEUE pointer
    movf ADC_DATAPORT, W            ;Sample X
	bsf ADC_CONTROLPORT, RDD        ;Stop conversion
	bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
	bcf ADC_CONTROLPORT, ADDR0      ;Set channel to X
    movwf INDF                      ;Save to QUEUE
    incf FSR, F                     ;Increment QUEUE pointer
    MOVFF sampleRate2, cntra         ;Restore cntra
    MOVFF sampleRate1, cntrb        ;Restore cntrb
    call Delay
    decfsz cntrc, F             	;Increment counter, 64 samples?
        goto SampleXYDelayedLA
    nop
    movf ADC_DATAPORT, W            ;Sample Y, last in Bank 1
    bsf ADC_CONTROLPORT, RDD        ;Stop conversion
	bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
	bsf ADC_CONTROLPORT, ADDR0      ;Set channel to Y
    movwf INDF                      ;Save to QUEUE
	bsf FSR, 7						;Move QUEUE pointer to Bank 2
    movf ADC_DATAPORT, W            ;Sample X
	bsf ADC_CONTROLPORT, RDD        ;Stop conversion
	bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
	bcf ADC_CONTROLPORT, ADDR0      ;Set channel to X
    movwf INDF                      ;Save to QUEUE
	decf FSR, f						;Increment QUEUE pointer
    MOVLF BUFFERSIZE/2-1, cntrc     ;Initialize counter, use cntrc as counter
    MOVFF sampleRate2, cntra         ;Restore cntra
    MOVFF sampleRate1, cntrb        ;Restore cntrb
    call Delay
	nop
SampleXYDelayedLB
    movf ADC_DATAPORT, W            ;Sample Y
    bsf ADC_CONTROLPORT, RDD        ;Stop conversion
	bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
	bsf ADC_CONTROLPORT, ADDR0      ;Set channel to Y
    movwf INDF                      ;Save to QUEUE
    decf FSR, F                     ;Increment QUEUE pointer
    movf ADC_DATAPORT, W            ;Sample X
	bsf ADC_CONTROLPORT, RDD        ;Stop conversion
	bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
	bcf ADC_CONTROLPORT, ADDR0      ;Set channel to X
    movwf INDF                      ;Save to QUEUE
    decf FSR, F                     ;Increment QUEUE pointer
    MOVFF sampleRate2, cntra         ;Restore cntra
    MOVFF sampleRate1, cntrb        ;Restore cntrb
    call Delay
    decfsz cntrc, F             	;Increment counter, 64 samples?
        goto SampleXYDelayedLB
    nop
    movf ADC_DATAPORT, W            ;Sample Y, last in Bank 2
    bsf ADC_CONTROLPORT, RDD        ;Stop conversion
	bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
	bsf ADC_CONTROLPORT, ADDR0      ;Set channel to Y
    movwf INDF                      ;Save to QUEUE
	bsf STATUS, IRP					;Move QUEUE pointer to Bank 4
    movf ADC_DATAPORT, W            ;Sample X
	bsf ADC_CONTROLPORT, RDD        ;Stop conversion
	bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
	bcf ADC_CONTROLPORT, ADDR0      ;Set channel to X
    movwf INDF                      ;Save to QUEUE
	incf FSR, f						;Increment QUEUE pointer
    MOVLF BUFFERSIZE/2-1, cntrc     ;Initialize counter, use cntrc as counter
    MOVFF sampleRate2, cntra         ;Restore cntra
    MOVFF sampleRate1, cntrb        ;Restore cntrb
    call Delay
	nop
SampleXYDelayedLC
    movf ADC_DATAPORT, W            ;Sample Y
    bsf ADC_CONTROLPORT, RDD        ;Stop conversion
	bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
	bsf ADC_CONTROLPORT, ADDR0      ;Set channel to Y
    movwf INDF                      ;Save to QUEUE
    incf FSR, F                     ;Increment QUEUE pointer
    movf ADC_DATAPORT, W            ;Sample X
	bsf ADC_CONTROLPORT, RDD        ;Stop conversion
	bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
	bcf ADC_CONTROLPORT, ADDR0      ;Set channel to X
    movwf INDF                      ;Save to QUEUE
    incf FSR, F                     ;Increment QUEUE pointer
    MOVFF sampleRate2, cntra         ;Restore cntra
    MOVFF sampleRate1, cntrb        ;Restore cntrb
    call Delay
    decfsz cntrc, F             	;Increment counter, 64 samples?
        goto SampleXYDelayedLC
    nop
    movf ADC_DATAPORT, W            ;Sample Y, last in Bank 4
    bsf ADC_CONTROLPORT, RDD        ;Stop conversion
	bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
	bsf ADC_CONTROLPORT, ADDR0      ;Set channel to Y
    movwf INDF                      ;Save to QUEUE
	bcf FSR, 7						;Move QUEUE pointer to Bank 3
    movf ADC_DATAPORT, W            ;Sample X
	bsf ADC_CONTROLPORT, RDD        ;Stop conversion
	bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
	bcf ADC_CONTROLPORT, ADDR0      ;Set channel to X
    movwf INDF                      ;Save to QUEUE
	decf FSR, f						;Increment QUEUE pointer
    MOVLF BUFFERSIZE/2-1, cntrc     ;Initialize counter, use cntrc as counter
    MOVFF sampleRate2, cntra         ;Restore cntra
    MOVFF sampleRate1, cntrb        ;Restore cntrb
    call Delay
	nop
SampleXYDelayedLD
    movf ADC_DATAPORT, W            ;Sample Y
    bsf ADC_CONTROLPORT, RDD        ;Stop conversion
	bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
	bsf ADC_CONTROLPORT, ADDR0      ;Set channel to Y
    movwf INDF                      ;Save to QUEUE
    decf FSR, F                     ;Increment QUEUE pointer
    movf ADC_DATAPORT, W            ;Sample X
    bsf ADC_CONTROLPORT, RDD        ;Stop conversion
	bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
	bcf ADC_CONTROLPORT, ADDR0      ;Set channel to X
    movwf INDF                      ;Save to QUEUE
    decf FSR, F                     ;Increment QUEUE pointer
    MOVFF sampleRate2, cntra         ;Restore cntra
    MOVFF sampleRate1, cntrb        ;Restore cntrb
    call Delay
    decfsz cntrc, F             	;Increment counter, 64 samples?
        goto SampleXYDelayedLD
    nop
    movf ADC_DATAPORT, W            ;Sample Y, last in Bank 3
    bsf ADC_CONTROLPORT, RDD        ;Stop conversion
    goto ADCShutdown

;Fast sample
;Sampling rate = 625 kHz with 20 MHz clock
;Sampling rate = 125 kHz with 4 MHz clock
;-----------------------------------------------------------------------------
Sample625k
    bcf ADC_CONTROLPORT, RDD            ;Begin Conversion
    MOVLF BUFFERSIZE-1, cntra		    ;Initialize counter
    MOVLF BUFFERMIN, FSR                ;Initialize pointer
	nop
Sample625kLoopA
    movf ADC_DATAPORT, W                ;Sample
    bsf ADC_CONTROLPORT, RDD            ;Stop conversion
    bcf ADC_CONTROLPORT, RDD            ;Begin next conversion
    movwf INDF                          ;Save to QUEUE
    incf FSR, F                         ;Increment QUEUE pointer
    decfsz cntra, F                      ;Increment counter, 64 samples?
        goto Sample625kLoopA
    nop
	movf ADC_DATAPORT, w				;Last sample in Bank 1
	bsf ADC_CONTROLPORT, RDD			;stop conversion
	bcf ADC_CONTROLPORT, RDD			;begin next conversion
	movwf INDF							;Save to QUEUE
	bsf FSR, 7							;Move QUEUE pointer to Bank 2
	MOVLF BUFFERSIZE-1, cntra
	nop
Sample625kLoopB
    movf ADC_DATAPORT, W                ;Sample
    bsf ADC_CONTROLPORT, RDD            ;Stop conversion
    bcf ADC_CONTROLPORT, RDD            ;Begin next conversion
    movwf INDF                          ;Save to QUEUE
    decf FSR, F                         ;Increment QUEUE pointer
    decfsz cntra, F                      ;Increment counter, 64 samples?
        goto Sample625kLoopB
	nop
	movf ADC_DATAPORT, w				;Last sample in Bank 2
	bsf ADC_CONTROLPORT, RDD			;stop conversion
	bcf ADC_CONTROLPORT, RDD			;begin next conversion
	movwf INDF							;Save to QUEUE
	bsf STATUS, IRP						;Move QUEUE pointer to Bank 4
	MOVLF BUFFERSIZE-1, cntra
	nop
Sample625kLoopC
    movf ADC_DATAPORT, W                ;Sample
    bsf ADC_CONTROLPORT, RDD            ;Stop conversion
    bcf ADC_CONTROLPORT, RDD            ;Begin next conversion
    movwf INDF                          ;Save to QUEUE
    incf FSR, F                         ;Increment QUEUE pointer
    decfsz cntra, F                      ;Increment counter, 64 samples?
        goto Sample625kLoopC
	nop
	movf ADC_DATAPORT, w				;Last sample in Bank 4
	bsf ADC_CONTROLPORT, RDD			;stop conversion
	bcf ADC_CONTROLPORT, RDD			;begin next conversion
	movwf INDF							;Save to QUEUE
	bcf FSR, 7							;Move QUEUE pointer to Bank 3
	MOVLF BUFFERSIZE-1, cntra
	nop
Sample625kLoopD
    movf ADC_DATAPORT, W                ;Sample
    bsf ADC_CONTROLPORT, RDD            ;Stop conversion
    bcf ADC_CONTROLPORT, RDD            ;Begin next conversion
    movwf INDF                          ;Save to QUEUE
    decf FSR, F                         ;Increment QUEUE pointer
    decfsz cntra, F                      ;Increment counter, 64 samples?
        goto Sample625kLoopD
	nop
    movf ADC_DATAPORT, W                ;Last sample
    bsf ADC_CONTROLPORT, RDD            ;Stop conversion
    goto ADCShutdown

;Fast sample
;Sampling rate = 416.667 kHz with 20 MHz clock
;Sampling rate =  83.333 kHz with 4 MHz clock
;or
;Sampling rate = 250 kHz with 20 MHz clock
;Sampling rate =  50 kHz with 4 MHz clock
;-----------------------------------------------------------------------------
Sample417k250k
    bcf ADC_CONTROLPORT, RDD        ;Begin Conversion
    MOVLF BUFFERSIZE - 1, cntra     ;Initialize counter
    MOVLF BUFFERMIN, FSR            ;Initialize pointer
	goto $ + 1						;Delay 3
	btfss configLoc1, 2				;Choose to delay by 3 more or by 11 more
		goto Sample417kLoopA
	call DelaySeven					;Delay 9 cycles
Sample417kLoopA
    movf ADC_DATAPORT, W            ;Sample
    bsf ADC_CONTROLPORT, RDD        ;Stop conversion
    bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
    movwf INDF                      ;Save to QUEUE
    incf FSR, F                     ;Increment QUEUE pointer
    btfss configLoc1, 2             ;Choose to delay 4 cycles or 12 cycles depending on mode
        goto Sample417kA            ;Delaying 4 cycles, sample at 417k
Sample250kA
	call DelaySeven					;Delay 9 cycles
Sample417kA
    nop
    decfsz cntra, F                  ;Increment counter, 64 samples?
        goto Sample417kLoopA
    nop
	movf ADC_DATAPORT, W			;Last sample bank 1
    bsf ADC_CONTROLPORT, RDD        ;Stop conversion
    bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
    movwf INDF                      ;Save to QUEUE
	bsf FSR, 7						;Goto bank 2
	MOVLF BUFFERSIZE - 1, cntra		;Reinitialize counter
	goto $ + 1
    btfss configLoc1, 2             ;Choose to delay 5 cycles or 13 cycles depending on mode
        goto Sample417kLoopB        ;Delaying  cycles, sample at 417k
	call DelaySeven					;Delay 9 cycles
Sample417kLoopB
    movf ADC_DATAPORT, W            ;Sample
    bsf ADC_CONTROLPORT, RDD        ;Stop conversion
    bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
    movwf INDF                      ;Save to QUEUE
    decf FSR, F                     ;Increment QUEUE pointer
StSample417kLoopB
    btfss configLoc1, 2             ;Choose to delay 4 cycles or 12 cycles depending on mode
        goto Sample417kB            ;Delaying 4 cycles, sample at 417k
Sample250kB
	call DelaySeven					;Delay 9 cycles
Sample417kB
    nop
    decfsz cntra, F                  ;Increment counter, 64 samples?
        goto Sample417kLoopB
    nop
	movf ADC_DATAPORT, W			;Last sample bank 2
    bsf ADC_CONTROLPORT, RDD        ;Stop conversion
    bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
    movwf INDF                      ;Save to QUEUE
	bsf STATUS, IRP					;Goto bank 4
	MOVLF BUFFERSIZE - 1, cntra		;Reinitialize counter
	goto $ + 1
    btfss configLoc1, 2             ;Choose to delay 5 cycles or 13 cycles depending on mode
        goto Sample417kLoopC        ;Delaying  cycles, sample at 417k
	call DelaySeven					;Delay 9 cycles
Sample417kLoopC
    movf ADC_DATAPORT, W            ;Sample
    bsf ADC_CONTROLPORT, RDD        ;Stop conversion
    bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
    movwf INDF                      ;Save to QUEUE
    incf FSR, F                     ;Increment QUEUE pointer
StSample417kLoopC
    btfss configLoc1, 2             ;Choose to delay 4 cycles or 12 cycles depending on mode
        goto Sample417kC            ;Delaying 4 cycles, sample at 417k
Sample250kC
	call DelaySeven					;Delay 9 cycles
Sample417kC
    nop
    decfsz cntra, F                  ;Increment counter, 64 samples?
        goto Sample417kLoopC
    nop
	movf ADC_DATAPORT, W			;Last sample bank 4
    bsf ADC_CONTROLPORT, RDD        ;Stop conversion
    bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
    movwf INDF                      ;Save to QUEUE
	bcf FSR, 7						;Goto bank 3
	MOVLF BUFFERSIZE - 1, cntra		;Reinitialize counter
	goto $ + 1
    btfss configLoc1, 2             ;Choose to delay 5 cycles or 13 cycles depending on mode
        goto Sample417kLoopD        ;Delaying  cycles, sample at 417k
	call DelaySeven					;Delay 9 cycles
Sample417kLoopD
    movf ADC_DATAPORT, W            ;Sample
    bsf ADC_CONTROLPORT, RDD        ;Stop conversion
    bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
    movwf INDF                      ;Save to QUEUE
    decf FSR, F                     ;Increment QUEUE pointer
StSample417kLoopD
    btfss configLoc1, 2             ;Choose to delay 4 cycles or 12 cycles depending on mode
        goto Sample417kD            ;Delaying 4 cycles, sample at 417k
Sample250kD
	call DelaySeven					;Delay 9 cycles
Sample417kD
    nop
    decfsz cntra, F                  ;Increment counter, 64 samples?
        goto Sample417kLoopD
    nop
    movf ADC_DATAPORT, W            ;Last sample
    bsf ADC_CONTROLPORT, RDD        ;Stop conversion
    goto ADCShutdown

;Delay Seven Cycles, helper to Sample417k250k
DelaySeven
	goto $ + 1						;7
;Delay Five Cycles, helper to SampleXY250k192k
DelayFive
	nop								;5
	goto $ + 1						
;Delay Five Cycles, helper to SampleXY250k192k
DelayTwo
	return							;2

;Fast sample XY
;Sampling rate = 250 kHz with 20 MHz clock
;-----------------------------------------------------------------------------
SampleXY250k192k
    bcf ADC_CONTROLPORT, RDD        ;Begin Conversion
    bsf ADC_CONTROLPORT, ADDR0      ;Set channel to Y
    MOVLF BUFFERMIN, FSR            ;Initialize pointer
    movf ADC_DATAPORT, W            ;Sample X
	bsf ADC_CONTROLPORT, RDD        ;Stop conversion
	bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
    bcf ADC_CONTROLPORT, ADDR0      ;Set channel to X
    movwf INDF                      ;Save to QUEUE
    incf FSR, F                     ;Increment QUEUE pointer
    MOVLF BUFFERSIZE/2-1, cntrc   	;Initialize counter, use cntrc as counter
    btfss configLoc1, 0				;Delay 250k or 192k
        call DelayFive			 	;192k
	call DelayTwo
SampleXY250kLA
    movf ADC_DATAPORT, W            ;Sample Y
    bsf ADC_CONTROLPORT, RDD        ;Stop conversion
	bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
	bsf ADC_CONTROLPORT, ADDR0      ;Set channel to Y
    movwf INDF                      ;Save to QUEUE
    incf FSR, F                     ;Increment QUEUE pointer
    movf ADC_DATAPORT, W            ;Sample X
	bsf ADC_CONTROLPORT, RDD        ;Stop conversion
	bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
	bcf ADC_CONTROLPORT, ADDR0      ;Set channel to X
    movwf INDF                      ;Save to QUEUE
    incf FSR, F                     ;Increment QUEUE pointer
    btfss configLoc1, 0				;Delay 250k or 192k
        call DelayFive			 	;192k
    goto $ + 1
    nop
    decfsz cntrc, F             	;Increment counter, 64 samples?
        goto SampleXY250kLA
    nop
    movf ADC_DATAPORT, W            ;Sample Y, last in Bank 1
    bsf ADC_CONTROLPORT, RDD        ;Stop conversion
	bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
	bsf ADC_CONTROLPORT, ADDR0      ;Set channel to Y
    movwf INDF                      ;Save to QUEUE
	bsf FSR, 7						;Move QUEUE pointer to Bank 2
    movf ADC_DATAPORT, W            ;Sample X
	bsf ADC_CONTROLPORT, RDD        ;Stop conversion
	bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
	bcf ADC_CONTROLPORT, ADDR0      ;Set channel to X
    movwf INDF                      ;Save to QUEUE
	decf FSR, f						;Increment QUEUE pointer
    MOVLF BUFFERSIZE/2-1, cntrc     ;Initialize counter, use cntrc as counter
    btfss configLoc1, 0				;Delay 250k or 192k
        call DelayFive			 	;192k
	call DelayTwo
SampleXY250kLB
    movf ADC_DATAPORT, W            ;Sample Y
    bsf ADC_CONTROLPORT, RDD        ;Stop conversion
	bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
	bsf ADC_CONTROLPORT, ADDR0      ;Set channel to Y
    movwf INDF                      ;Save to QUEUE
    decf FSR, F                     ;Increment QUEUE pointer
    movf ADC_DATAPORT, W            ;Sample X
	bsf ADC_CONTROLPORT, RDD        ;Stop conversion
	bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
	bcf ADC_CONTROLPORT, ADDR0      ;Set channel to X
    movwf INDF                      ;Save to QUEUE
    decf FSR, F                     ;Increment QUEUE pointer
    btfss configLoc1, 0				;Delay 250k or 192k
        call DelayFive			 	;192k
    goto $ + 1
	nop
    decfsz cntrc, F             	;Increment counter, 64 samples?
        goto SampleXY250kLB
    nop
    movf ADC_DATAPORT, W            ;Sample Y, last in Bank 2
    bsf ADC_CONTROLPORT, RDD        ;Stop conversion
	bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
	bsf ADC_CONTROLPORT, ADDR0      ;Set channel to Y
    movwf INDF                      ;Save to QUEUE
	bsf STATUS, IRP					;Move QUEUE pointer to Bank 4
    movf ADC_DATAPORT, W            ;Sample X
	bsf ADC_CONTROLPORT, RDD        ;Stop conversion
	bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
	bcf ADC_CONTROLPORT, ADDR0      ;Set channel to X
    movwf INDF                      ;Save to QUEUE
	incf FSR, f						;Increment QUEUE pointer
    MOVLF BUFFERSIZE/2-1, cntrc     ;Initialize counter, use cntrc as counter
    btfss configLoc1, 0				;Delay 250k or 192k
        call DelayFive			 	;192k
	call DelayTwo
SampleXY250kLC
    movf ADC_DATAPORT, W            ;Sample Y
    bsf ADC_CONTROLPORT, RDD        ;Stop conversion
	bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
	bsf ADC_CONTROLPORT, ADDR0      ;Set channel to Y
    movwf INDF                      ;Save to QUEUE
    incf FSR, F                     ;Increment QUEUE pointer
    movf ADC_DATAPORT, W            ;Sample X
	bsf ADC_CONTROLPORT, RDD        ;Stop conversion
	bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
	bcf ADC_CONTROLPORT, ADDR0      ;Set channel to X
    movwf INDF                      ;Save to QUEUE
    incf FSR, F                     ;Increment QUEUE pointer
    btfss configLoc1, 0				;Delay 250k or 192k
        call DelayFive			 	;192k
    goto $ + 1
    nop
    decfsz cntrc, F             	;Increment counter, 64 samples?
        goto SampleXY250kLC
    nop
    movf ADC_DATAPORT, W            ;Sample Y, last in Bank 4
    bsf ADC_CONTROLPORT, RDD        ;Stop conversion
	bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
	bsf ADC_CONTROLPORT, ADDR0      ;Set channel to Y
    movwf INDF                      ;Save to QUEUE
	bcf FSR, 7						;Move QUEUE pointer to Bank 3
    movf ADC_DATAPORT, W            ;Sample X
	bsf ADC_CONTROLPORT, RDD        ;Stop conversion
	bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
	bcf ADC_CONTROLPORT, ADDR0      ;Set channel to X
    movwf INDF                      ;Save to QUEUE
	decf FSR, f						;Increment QUEUE pointer
    MOVLF BUFFERSIZE/2-1, cntrc     ;Initialize counter, use cntrc as counter
    btfss configLoc1, 0				;Delay 250k or 192k
        call DelayFive			 	;192k
	call DelayTwo
SampleXY250kLD
    movf ADC_DATAPORT, W            ;Sample Y
    bsf ADC_CONTROLPORT, RDD        ;Stop conversion
	bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
	bsf ADC_CONTROLPORT, ADDR0      ;Set channel to Y
    movwf INDF                      ;Save to QUEUE
    decf FSR, F                     ;Increment QUEUE pointer
    movf ADC_DATAPORT, W            ;Sample X
    bsf ADC_CONTROLPORT, RDD        ;Stop conversion
	bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
	bcf ADC_CONTROLPORT, ADDR0      ;Set channel to X
    movwf INDF                      ;Save to QUEUE
    decf FSR, F                     ;Increment QUEUE pointer
    btfss configLoc1, 0				;Delay 250k or 192k
        call DelayFive			 	;192k
    goto $ + 1
	nop
	decfsz cntrc, F             	;Increment counter, 64 samples?
        goto SampleXY250kLD
    nop
    movf ADC_DATAPORT, W            ;Sample Y, last in Bank 3
    bsf ADC_CONTROLPORT, RDD        ;Stop conversion
    goto ADCShutdown

;Repetative sample helper functions
;Equivalent sampling rate = 5 MHz with 20 MHz clock
;-----------------------------------------------------------------------------
SampleRep5MEnd
	movlw (low SampleRep5M)					;Test for step 1
	xorwf functptrlow, w
	btfss STATUS, Z						
		goto SampleRep5MEndC				;End of another step
	MOVLF (low SampleRep5MStep2), functptrlow	;End of step 1
	bcf STATUS, IRP							;Restore buffer pointer for step 2
SampleRep5MEndB
	goto MainWaitTrig						;Wait for next trigger
SampleRep5MEndC
	movlw (low SampleRep5MStep2)			;Test for step 2
	xorwf functptrlow, w
	btfss STATUS, Z
		goto SampleRep5MEndD				;End of another step
	MOVLF (low SampleRep5MStep3), functptrlow	;End of step 2
	goto MainWaitTrig
SampleRep5MEndD
	movlw (low SampleRep5MStep3)			;Test for step 3
	xorwf functptrlow, w
	btfss STATUS, Z
		goto SampleRep5MEndE				;End of another step
	MOVLF (low SampleRep5MStep4), functptrlow	;End of step 3
	goto MainWaitTrig
SampleRep5MEndE
	movlw (low SampleRep5MStep4)			;Test for step 4
	xorwf functptrlow, w
	btfss STATUS, Z
		goto ADCShutdown					;End of step 5
	MOVLF (low SampleRep5MStep5), functptrlow	;End of step 4
	goto MainWaitTrig
	
SampleRep5MStep2
	movlw BUFFERMIN + D'52'
    bcf ADC_CONTROLPORT, RDD         	;Begin Conversion
	movwf FSR
	goto Sample1MEntry2
	
SampleRep5MStep3
	MOVLF BUFFERMIN + D'24' + B'10000000', FSR	;Restore buffer pointer for step 3
    bcf ADC_CONTROLPORT, RDD         	;Begin Conversion
	bcf STATUS, IRP						;Some of buffer pointer restoration is included here to save a programming word
	goto Sample1MEntry3
	
SampleRep5MStep4
    goto $ + 1
	movlw BUFFERMIN + D'26' + B'10000000' ;Restore buffer pointer for step 4 to save some programming space
    bcf ADC_CONTROLPORT, RDD         	;Begin Conversion
	movwf FSR
	goto Sample1MEntry4

SampleRep5MStep5
	MGOTOSETUP Sample1MhzEnd
	MOVLF BUFFERMIN + D'50', FSR 		;Restore buffer pointer for step 5 to save some programming space
    bcf ADC_CONTROLPORT, RDD         	;Begin Conversion
	nop
	goto Sample1MhzEnd

;Repetative sample helper functions
;Equivalent sample rate of 2.5 MHz with 20 MHz clock
;-----------------------------------------------------------------------------
SampleRep2MEnd
	movlw (low SampleRep2M)					;Test for step 1
	xorwf functptrlow, w
	btfss STATUS, Z
		goto SampleRep2MEndB
	MOVLF BUFFERMIN + D'41', FSR			;End step 1
	MOVLF (high SampleRep2MStep2), functptrhigh
	MOVLF (low SampleRep2MStep2), functptrlow
	goto MainWaitTrig
SampleRep2MEndB
	movlw (low SampleRep2MStep2)			;Test for step 2
	xorwf functptrlow, w
	btfss STATUS, Z
		goto ADCShutdown					;End of step 3
	MOVLF (low SampleRep2MStep3), functptrlow	;End of step 2
	goto MainWaitTrig					

SampleRep2MStep2
	MGOTOSETUP Sample833kEntry1
    bcf ADC_CONTROLPORT, RDD         	;Begin Conversion
	bcf STATUS, IRP						;Managing address here to save programming space
	goto Sample833kEntry1

SampleRep2MStep3
	MOVLF BUFFERMIN + D'43' + B'10000000', FSR		;Delay 4.  Managing FSR here to save programming space
	MGOTOSETUP Sample833kEntry2
    bcf ADC_CONTROLPORT, RDD         	;Begin Conversion
    nop
	goto Sample833kEntry2

;Fastest sample
;Sampling rate = 1 MHz with 20 MHz clock
;Sampling rate = 200 kHz with 4 MHz clock
;-----------------------------------------------------------------------------
Sample1M

;Repetative sample (shared with Sample1M)
;Equivalent sampling rate = 5 MHz with 20 MHz clock
;-----------------------------------------------------------------------------
SampleRep5M
    bcf ADC_CONTROLPORT, RDD         	;Begin Conversion
    MOVLF BUFFERMIN, FSR                ;Initialize pointer
	nop
    local count
    count = 1
    while count < D'53'
	    bsf ADC_CONTROLPORT, RDD		;Latch Conversion into SPP
	    bcf ADC_CONTROLPORT, RDD        ;Start next conversion
        movf ADC_DATAPORT, W	        ;Save Sample
        movwf INDF                      ;Save to QUEUE
        incf FSR, F                     ;Increment QUEUE pointer
        count = count + 1
    endw
Sample1MEntry2
    while count < BUFFERSIZE
	    bsf ADC_CONTROLPORT, RDD		;Latch Conversion into SPP
	    bcf ADC_CONTROLPORT, RDD        ;Start next conversion
        movf ADC_DATAPORT, W	        ;Save Sample
        movwf INDF                      ;Save to QUEUE
        incf FSR, F                     ;Increment QUEUE pointer
        count = count + 1
    endw
    bsf ADC_CONTROLPORT, RDD			;Latch Conversion into SPP
    bcf ADC_CONTROLPORT, RDD	        ;Start next conversion
    movf ADC_DATAPORT, W
    movwf INDF
    bsf FSR, 7							;goto bank 2
    count = 1
    while count < D'40'
        bsf ADC_CONTROLPORT, RDD        ;Stop conversion
        bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
        movf ADC_DATAPORT, W            ;Sample
        movwf INDF                      ;Save to QUEUE
        decf FSR, F                     ;Increment QUEUE pointer
        count = count + 1
	endw
Sample1MEntry3
    while count < BUFFERSIZE
        bsf ADC_CONTROLPORT, RDD        ;Stop conversion
        bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
        movf ADC_DATAPORT, W            ;Sample
        movwf INDF                      ;Save to QUEUE
        decf FSR, F                     ;Increment QUEUE pointer
        count = count + 1
	endw
    bsf ADC_CONTROLPORT, RDD
    bcf ADC_CONTROLPORT, RDD
    movf ADC_DATAPORT, W
    movwf INDF
    bsf STATUS, IRP						;goto bank 4
    count = 1
    while count < D'27'
        bsf ADC_CONTROLPORT, RDD        ;Stop conversion
        bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
        movf ADC_DATAPORT, W            ;Sample
        movwf INDF                      ;Save to QUEUE
        incf FSR, F                     ;Increment QUEUE pointer
        count = count + 1
	endw
Sample1MEntry4
    while count < BUFFERSIZE
        bsf ADC_CONTROLPORT, RDD        ;Stop conversion
        bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
        movf ADC_DATAPORT, W            ;Sample
        movwf INDF                      ;Save to QUEUE
        incf FSR, F                     ;Increment QUEUE pointer
        count = count + 1
	endw
    bsf ADC_CONTROLPORT, RDD
    bcf ADC_CONTROLPORT, RDD
    movf ADC_DATAPORT, W            ;Sample
    movwf INDF
    bcf FSR, 7							;goto bank 3
    count = 1
    while count < D'14'
        bsf ADC_CONTROLPORT, RDD        ;Stop conversion
        bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
	    movf ADC_DATAPORT, W
        movwf INDF                      ;Save to QUEUE
        decf FSR, F                     ;Increment QUEUE pointer
        count = count + 1
	endw
Sample1MhzEnd
    while count < BUFFERSIZE
        bsf ADC_CONTROLPORT, RDD        ;Stop conversion
        bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
	    movf ADC_DATAPORT, W
        movwf INDF                      ;Save to QUEUE
        decf FSR, F                     ;Increment QUEUE pointer
        count = count + 1
	endw
    bsf ADC_CONTROLPORT, RDD        	;Stop conversion
    movf ADC_DATAPORT, W            	;Sample
	MGOTOSETUP SampleRep5MEnd
	btfsc configLoc1, 1					;Check if ending 5MHz repetative sampling mode
		goto SampleRep5MEnd
;Ending regular 1 MHz sampling
SampleRep5MEndStep5
	MGOTO ADCShutdown

;Fastest XY sample
;Sampling rate = 500 kHz with 20 MHz clock
;Sampling rate =  100 kHz with 4 MHz clock
;-----------------------------------------------------------------------------
SampleXY500k
    bcf ADC_CONTROLPORT, RDD        ;Begin Conversion
    bcf ADC_CONTROLPORT, ADDR0      ;Set channel to x
    MOVLF BUFFERMIN, FSR            ;Initialize pointer
	decf ADC_CONTROLPORT, f			;Stop Conversion and set channel to y
	decf ADC_CONTROLPORT, f			;Begin next conversion
	movf ADC_DATAPORT, W            ;Sample X
    movwf INDF                      ;Save to QUEUE
    incf FSR, F                     ;Increment QUEUE pointer
    count = 1
    while count < BUFFERSIZE / 2
		decf ADC_CONTROLPORT, f			;Stop Conversion
		decf ADC_CONTROLPORT, f			;Begin next conversion and set channel to Y
		movf ADC_DATAPORT, W            ;Sample Y
		movwf INDF                      ;Save to QUEUE
		incf FSR, F                     ;Increment QUEUE pointer
		decf ADC_CONTROLPORT, f			;Stop Conversion
		decf ADC_CONTROLPORT, f			;Begin next conversion and set channel to X
		movf ADC_DATAPORT, W            ;Sample X
		movwf INDF                      ;Save to QUEUE
		incf FSR, F                     ;Increment QUEUE pointer
		count = count + 1
	endw
	decf ADC_CONTROLPORT, f			;Stop Conversion
	decf ADC_CONTROLPORT, f			;Begin next conversion and set channel to Y
    movf ADC_DATAPORT, W            ;Sample Y, last in Bank 1
    movwf INDF                      ;Save to QUEUE
	bsf FSR, 7						;Move QUEUE pointer to Bank 2
	decf ADC_CONTROLPORT, f			;Stop Conversion
	decf ADC_CONTROLPORT, f			;Begin next conversion and set channel to X
    movf ADC_DATAPORT, W            ;Sample X
    movwf INDF                      ;Save to QUEUE
	decf FSR, f						;Increment QUEUE pointer
    count = 1
    while count < BUFFERSIZE / 2
		decf ADC_CONTROLPORT, f			;Stop Conversion
		decf ADC_CONTROLPORT, f			;Begin next conversion and set channel to Y
		movf ADC_DATAPORT, W            ;Sample Y
		movwf INDF                      ;Save to QUEUE
		decf FSR, F                     ;Increment QUEUE pointer
		decf ADC_CONTROLPORT, f			;Stop Conversion
		decf ADC_CONTROLPORT, f			;Begin next conversion and set channel to X
		movf ADC_DATAPORT, W            ;Sample X
		movwf INDF                      ;Save to QUEUE
		decf FSR, F                     ;Increment QUEUE pointer
		count = count + 1
	endw
	decf ADC_CONTROLPORT, f			;Stop Conversion
	decf ADC_CONTROLPORT, f			;Begin next conversion and set channel to Y
    movf ADC_DATAPORT, W            ;Sample Y, last in Bank 2
    movwf INDF                      ;Save to QUEUE
	bsf STATUS, IRP					;Move QUEUE pointer to Bank 4
	decf ADC_CONTROLPORT, f			;Stop Conversion
	decf ADC_CONTROLPORT, f			;Begin next conversion and set channel to X
    movf ADC_DATAPORT, W            ;Sample X
    movwf INDF                      ;Save to QUEUE
	incf FSR, f						;Increment QUEUE pointer
    count = 1
    while count < BUFFERSIZE / 2
		decf ADC_CONTROLPORT, f			;Stop Conversion
		decf ADC_CONTROLPORT, f			;Begin next conversion and set channel to Y
		movf ADC_DATAPORT, W            ;Sample Y
		movwf INDF                      ;Save to QUEUE
		incf FSR, F                     ;Increment QUEUE pointer
		decf ADC_CONTROLPORT, f			;Stop Conversion
		decf ADC_CONTROLPORT, f			;Begin next conversion and set channel to X
		movf ADC_DATAPORT, W            ;Sample X
		movwf INDF                      ;Save to QUEUE
		incf FSR, F                     ;Increment QUEUE pointer
		count = count + 1
	endw
	decf ADC_CONTROLPORT, f			;Stop Conversion
	decf ADC_CONTROLPORT, f			;Begin next conversion and set channel to Y
    movf ADC_DATAPORT, W            ;Sample Y, last in Bank 4
    movwf INDF                      ;Save to QUEUE
	bcf FSR, 7						;Move QUEUE pointer to Bank 3
	decf ADC_CONTROLPORT, f			;Stop Conversion
	decf ADC_CONTROLPORT, f			;Begin next conversion and set channel to X
    movf ADC_DATAPORT, W            ;Sample X
    movwf INDF                      ;Save to QUEUE
	decf FSR, f						;Increment QUEUE pointer
    count = 1
    while count < BUFFERSIZE / 2
		decf ADC_CONTROLPORT, f			;Stop Conversion
		decf ADC_CONTROLPORT, f			;Begin next conversion and set channel to Y
		movf ADC_DATAPORT, W            ;Sample Y
		movwf INDF                      ;Save to QUEUE
		decf FSR, F                     ;Increment QUEUE pointer
		decf ADC_CONTROLPORT, f			;Stop Conversion
		decf ADC_CONTROLPORT, f			;Begin next conversion and set channel to X
		movf ADC_DATAPORT, W            ;Sample X
		movwf INDF                      ;Save to QUEUE
		decf FSR, F                     ;Increment QUEUE pointer
		count = count + 1
	endw
    movf ADC_DATAPORT, W            ;Sample Y, last in Bank 3
    bsf ADC_CONTROLPORT, RDD        ;Stop conversion
	MGOTO ADCShutdown

;Fastest XY sample
;Sampling rate = 416.667 kHz with 20 MHz clock
;Sampling rate =  83.333 kHz with 4 MHz clock
;-----------------------------------------------------------------------------
SampleXY417k
    bcf ADC_CONTROLPORT, RDD        ;Begin Conversion
    bsf ADC_CONTROLPORT, ADDR0      ;Set channel to Y
    MOVLF BUFFERMIN, FSR            ;Initialize pointer
    movf ADC_DATAPORT, W            ;Sample X
	bsf ADC_CONTROLPORT, RDD        ;Stop conversion
	bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
    bcf ADC_CONTROLPORT, ADDR0      ;Set channel to X
    movwf INDF                      ;Save to QUEUE
    incf FSR, F                     ;Increment QUEUE pointer
    count = 1
    while count < BUFFERSIZE / 2
		movf ADC_DATAPORT, W            ;Sample Y
		bsf ADC_CONTROLPORT, RDD        ;Stop conversion
		bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
		bsf ADC_CONTROLPORT, ADDR0      ;Set channel to Y
		movwf INDF                      ;Save to QUEUE
		incf FSR, F                     ;Increment QUEUE pointer
		movf ADC_DATAPORT, W            ;Sample X
		bsf ADC_CONTROLPORT, RDD        ;Stop conversion
		bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
		bcf ADC_CONTROLPORT, ADDR0      ;Set channel to X
		movwf INDF                      ;Save to QUEUE
		incf FSR, F                     ;Increment QUEUE pointer
		count = count + 1
	endw
    movf ADC_DATAPORT, W            ;Sample Y, last in Bank 1
    bsf ADC_CONTROLPORT, RDD        ;Stop conversion
	bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
	bsf ADC_CONTROLPORT, ADDR0      ;Set channel to Y
    movwf INDF                      ;Save to QUEUE
	bsf FSR, 7						;Move QUEUE pointer to Bank 2
    movf ADC_DATAPORT, W            ;Sample X
	bsf ADC_CONTROLPORT, RDD        ;Stop conversion
	bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
	bcf ADC_CONTROLPORT, ADDR0      ;Set channel to X
    movwf INDF                      ;Save to QUEUE
	decf FSR, f						;Increment QUEUE pointer
    count = 1
    while count < BUFFERSIZE / 2
		movf ADC_DATAPORT, W            ;Sample Y
		bsf ADC_CONTROLPORT, RDD        ;Stop conversion
		bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
		bsf ADC_CONTROLPORT, ADDR0      ;Set channel to Y
		movwf INDF                      ;Save to QUEUE
		decf FSR, F                     ;Increment QUEUE pointer
		movf ADC_DATAPORT, W            ;Sample X
		bsf ADC_CONTROLPORT, RDD        ;Stop conversion
		bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
		bcf ADC_CONTROLPORT, ADDR0      ;Set channel to X
		movwf INDF                      ;Save to QUEUE
		decf FSR, F                     ;Increment QUEUE pointer
		count = count + 1
	endw
    movf ADC_DATAPORT, W            ;Sample Y, last in Bank 2
    bsf ADC_CONTROLPORT, RDD        ;Stop conversion
	bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
	bsf ADC_CONTROLPORT, ADDR0      ;Set channel to Y
    movwf INDF                      ;Save to QUEUE
	bsf STATUS, IRP					;Move QUEUE pointer to Bank 4
    movf ADC_DATAPORT, W            ;Sample X
	bsf ADC_CONTROLPORT, RDD        ;Stop conversion
	bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
	bcf ADC_CONTROLPORT, ADDR0      ;Set channel to X
    movwf INDF                      ;Save to QUEUE
	incf FSR, f						;Increment QUEUE pointer
    count = 1
    while count < BUFFERSIZE / 2
		movf ADC_DATAPORT, W            ;Sample Y
		bsf ADC_CONTROLPORT, RDD        ;Stop conversion
		bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
		bsf ADC_CONTROLPORT, ADDR0      ;Set channel to Y
		movwf INDF                      ;Save to QUEUE
		incf FSR, F                     ;Increment QUEUE pointer
		movf ADC_DATAPORT, W            ;Sample X
		bsf ADC_CONTROLPORT, RDD        ;Stop conversion
		bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
		bcf ADC_CONTROLPORT, ADDR0      ;Set channel to X
		movwf INDF                      ;Save to QUEUE
		incf FSR, F                     ;Increment QUEUE pointer
		count = count + 1
	endw
    movf ADC_DATAPORT, W            ;Sample Y, last in Bank 4
    bsf ADC_CONTROLPORT, RDD        ;Stop conversion
	bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
	bsf ADC_CONTROLPORT, ADDR0      ;Set channel to Y
    movwf INDF                      ;Save to QUEUE
	bcf FSR, 7						;Move QUEUE pointer to Bank 3
    movf ADC_DATAPORT, W            ;Sample X
	bsf ADC_CONTROLPORT, RDD        ;Stop conversion
	bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
	bcf ADC_CONTROLPORT, ADDR0      ;Set channel to X
    movwf INDF                      ;Save to QUEUE
	decf FSR, f						;Increment QUEUE pointer
    count = 1
    while count < BUFFERSIZE / 2
		movf ADC_DATAPORT, W            ;Sample Y
		bsf ADC_CONTROLPORT, RDD        ;Stop conversion
		bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
		bsf ADC_CONTROLPORT, ADDR0      ;Set channel to Y
		movwf INDF                      ;Save to QUEUE
		decf FSR, F                     ;Increment QUEUE pointer
		movf ADC_DATAPORT, W            ;Sample X
		bsf ADC_CONTROLPORT, RDD        ;Stop conversion
		bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
		bcf ADC_CONTROLPORT, ADDR0      ;Set channel to X
		movwf INDF                      ;Save to QUEUE
		decf FSR, F                     ;Increment QUEUE pointer
		count = count + 1
	endw
    movf ADC_DATAPORT, W            ;Sample Y, last in Bank 3
    bsf ADC_CONTROLPORT, RDD        ;Stop conversion
	MGOTO ADCShutdown
	
;Fast sample
;Sampling rate = 833.333 kHz with 20 MHz clock
;Sampling rate = 166.667 kHz with 4 MHz clock
;-----------------------------------------------------------------------------
Sample833k
;Repetative sample
;Equivalent sampling rate = 2.5 MHz with 20 MHz clock
;-----------------------------------------------------------------------------
SampleRep2M
    bcf ADC_CONTROLPORT, RDD	        ;Begin Conversion
    MOVLF BUFFERMIN, FSR                ;Initialize pointer
    nop
    local count
    count = 1
    while count < BUFFERSIZE
        movf ADC_DATAPORT, W            ;Sample
        bsf ADC_CONTROLPORT, RDD        ;Stop conversion
        bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
        movwf INDF                      ;Save to QUEUE
        incf FSR, F                     ;Increment QUEUE pointer
        nop                             ;Wait a cycle
        count = count + 1
    endw
    movf ADC_DATAPORT, W
    bsf ADC_CONTROLPORT, RDD
    bcf ADC_CONTROLPORT, RDD
    movwf INDF
    bsf FSR, 7							;goto bank 2
    nop         	                    ;Wait a cycle
    count = 1
    while count < D'23'
        movf ADC_DATAPORT, W            ;Sample
        bsf ADC_CONTROLPORT, RDD        ;Stop conversion
        bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
        movwf INDF                      ;Save to QUEUE
        decf FSR, F                     ;Increment QUEUE pointer
        nop                             ;Wait a cycle
        count = count + 1
    endw
Sample833kEntry1
    while count < BUFFERSIZE
        movf ADC_DATAPORT, W            ;Sample
        bsf ADC_CONTROLPORT, RDD        ;Stop conversion
        bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
        movwf INDF                      ;Save to QUEUE
        decf FSR, F                     ;Increment QUEUE pointer
        nop                             ;Wait a cycle
        count = count + 1
    endw
    movf ADC_DATAPORT, W
    bsf ADC_CONTROLPORT, RDD
    bcf ADC_CONTROLPORT, RDD
    movwf INDF
    bsf STATUS, IRP						;goto bank 4
    nop         	                    ;Wait a cycle
    count = 1
    while count < D'44'
        movf ADC_DATAPORT, W            ;Sample
        bsf ADC_CONTROLPORT, RDD        ;Stop conversion
        bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
        movwf INDF                      ;Save to QUEUE
        incf FSR, F                     ;Increment QUEUE pointer
        nop                             ;Wait a cycle
        count = count + 1
    endw
Sample833kEntry2
    while count < BUFFERSIZE
        movf ADC_DATAPORT, W            ;Sample
        bsf ADC_CONTROLPORT, RDD        ;Stop conversion
        bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
        movwf INDF                      ;Save to QUEUE
        incf FSR, F                     ;Increment QUEUE pointer
        nop                             ;Wait a cycle
        count = count + 1
    endw
    movf ADC_DATAPORT, W
    bsf ADC_CONTROLPORT, RDD
    bcf ADC_CONTROLPORT, RDD
    movwf INDF
    bcf FSR, 7							;goto bank 3
    nop         	                    ;Wait a cycle
    count = 1
    while count < BUFFERSIZE
        movf ADC_DATAPORT, W            ;Sample
        bsf ADC_CONTROLPORT, RDD        ;Stop conversion
        bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
        movwf INDF                      ;Save to QUEUE
        decf FSR, F                     ;Increment QUEUE pointer
        nop                             ;Wait a cycle
        count = count + 1
    endw
    movf ADC_DATAPORT, W                ;Last sample
    bsf ADC_CONTROLPORT, RDD	        ;Stop conversion
	MGOTOSETUP SampleRep2MEnd			;If we're using repetative mode
	btfsc configLoc1, 2
		goto SampleRep2MEnd
Sample833kEnd
	MGOTO ADCShutdown
		
;=============================================================================
end     ;end of program
