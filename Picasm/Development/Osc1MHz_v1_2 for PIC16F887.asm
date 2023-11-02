;==============================================================================
;*Author:  Jonathan Weaver, jonw0224@aim.com
;E-mail Contact: jonw0224@aim.com
;*Description: An oscilloscope program based on the PIC16F877 and the MAX118
;*Version: 1.200
;*Date: 6/28/2011
;*Filename: osc.asm
;
;Versions:  1.000 - 3/29/2003
;           1.000 - 7/26/2004
;           1.000 - 4/2/2005
;           1.000 - 9/29/2005 -- Additional Header comments and license added
;           1.101 - 11/3/2005 -- Began to modify for use on PIC16F877
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
;			1.200 - 6/28/2011 - Modified code to handle conditional compile for hardware version 1.0 or hardware version 1.2
;			1.200 - 8/15/2012 - Added portability for PIC16F887

;Copyright (C) 2003-2011 Jonathan Weaver
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

PIC	equ 0x887
;PIC equ 0x877

if PIC == 0x887
;=============================================================================
; Contributed by Paul Messer
;=============================================================================
    list p=16F887
	errorlevel	-302, -205, -207		;Suppress bank selection messages

;*****************************************************
;       === Configuration Word Definitions ===
;*****************************************************
; Defines for PIC16F887 operation

; '__CONFIG' directive is used to embed configuration data within .asm file.
; The labels following the directive are located in the respective .inc file.
; See respective data sheet for additional information on configuration word.

	__CONFIG _CONFIG1, _DEBUG_OFF & _LVP_OFF & _FCMEN_OFF & _IESO_OFF & _BOR_OFF & _CPD_OFF & _CP_OFF & _MCLRE_ON & _PWRTE_OFF & _WDT_OFF & _HS_OSC
	__CONFIG _CONFIG2, _WRT_OFF & _BOR40V

; '__idlocs' sets the four ID locations to the hexadecimal value of expression.
; These are not readable by the cpu, but can be read by the programning hardware.

	__idlocs	0x1234

	clockFreq = 20					;20 = 20 MHZ, 4 = 4 MHZ
	
else
    list p=16F877a
      errorlevel      -302, -205, -207   ;Suppress bank selection messages
    __config  _WDT_OFF & _HS_OSC & _LVP_OFF
    clockFreq = 20      ;20 = 20 MHZ, 4 = 4 MHZ
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
TRIGGERPOSBIT equ 0x07  ;1 is positive slope trigger, 0 is negative slope
TRIGGERENBIT equ 0x06   ;1 is trigger enabled, 0 is no trigger
CLOCKFREQBIT equ 0x05   ;1 is 20 MHz, 0 is 4 MHz
CHANNELBIT equ 0x04     ;1 is channel 2, 0 is channel 1
FREQMODEBIT3 equ 0x03   ;Reserve the bits in CONFIGLOC1 for the frequency modes
FREQMODEBIT2 equ 0x02
FREQMODEBIT1 equ 0x01
FREQMODEBIT0 equ 0x00

FREQSAMPLE1M equ D'0'   ;Table of frequency modes, 0 to 15
FREQSAMPLE833K equ D'1'
FREQSAMPLE625K equ D'2'
FREQSAMPLE417K equ D'3'
FREQSAMPLE250K equ D'4'
FREQSAMPLEDELAYED equ D'5'
FREQSAMPLEREP5M equ D'6'	;Ensure trigger is enabled
FREQSAMPLEREP2M equ D'7'	;Ensure trigger is enabled
FREQSAMPLEXY417K equ D'8'
FREQSAMPLEXY250K equ D'9'
FREQSAMPLEXY192K equ D'10'
FREQSAMPLEXYDELAYED equ D'11'

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
    cntrb               ;second counter
    cntrc               ;third counter
    modetemp			;temporary mode variable
    modetempb			;temporary mode for repetitive sampling
    cntr				;counter variable for i2cs
	i2csdata			;data for i2cs
	dataConfig			;the data configuration
	triggerLevel		;the trigger level
ENDC

;=============================================================================
; M A C R O S
;=============================================================================

if PIC == 0x887
	include "p16f887.inc"
else
    include "p16F877a.inc"
endif
    include "equality.inc"
    include "banks.inc"
    include "asmext.inc"

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

CHANNELCONFSEND macro
	MOVFF dataConfig, i2csdata		;Channel configuration
    call PutByte
	clrf i2csdata
    call PutByte					;Channel 1 offset
    call PutByte					;Channel 2 offset
	MOVFF triggerLevel, i2csdata
    call PutByte				;Triggerlevel
	endm

CHANNELCONFSTORE macro
    ;Format of channel configuration is: Channel 1 Scale (2) bits
    ;                                    For scale, 00 = 1, 01 = 2, 10 = 5
    ;                                    Channel 2 Scale (2) bits
    ;                                    Channel 1 AC = 1 / DC = 0 (1) bit
    ;                                    Channel 2 AC = 1 / DC = 0 (1) bit
    ;                                    Two least significant bits = 0
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
	;Next byte is Trigger Level
	bcf ADC_CONTROLPORT, ADDR0				;Select address for trigger level
	bsf ADC_PORT, ADDR1
	bcf ADC_PORT, ADDR2
	bcf ADC_PORT, CS				;Select maxim ADC
	bcf ADC_CONTROLPORT, RDD				;Begin conversion
	goto $ + 1						;Wait 3
	nop
	movf ADC_DATAPORT, w			;Save trigger level
	bsf ADC_CONTROLPORT, RDD				;stop conversion
	bsf ADC_PORT, CS			;unselect
	bcf ADC_CONTROLPORT, ADDR0				;Unselect address for trigger level
	bcf ADC_PORT, ADDR1
	bcf ADC_PORT, ADDR2
	movwf triggerLevel
    endm

;=============================================================================
; I N T E R R U P T S
;=============================================================================

org 0x000
;Initialize
;First three lines of initialization included here to save on memory.
    MOVLF B'11000110', ADC_CONTROLPORT
    clrf ADC_DATAPORT
    goto Initial

org 0x004
IntHandler
    bcf STATUS, RP0						;Ensure we're in Bank0
	decfsz cntra, f
        goto IntHandler
    decfsz cntrb, f
		goto IntHandler
	decfsz cntrc, f
		goto IntHandler
	movf modetemp, w
MainSelect
    addwf PCL, f                        ;Add freqMode to Program Counter
	MGOTO Sample1M						;FreqMode = 0
    MGOTO Sample833k					;FreqMode = 1
	MGOTO Sample625k					;FreqMode = 2
	MGOTO Sample417k250k				;FreqMode = 3
	MGOTO Sample417k250k				;FreqMode = 4
    MGOTO SampleDelayed					;FreqMode = 5
    MGOTO SampleRep5M					;FreqMode = 6
	MGOTO SampleRep2M					;FreqMode = 7
	MGOTO SampleXY417k					;FreqMode = 8
	MGOTO SampleXY250k192k				;FreqMode = 9
	MGOTO SampleXY250k192k				;FreqMode = 10
    MGOTO SampleXYDelayed				;FreqMode = 11
	MGOTO Main							;Invalid FreqMode = 12, goto beginning
	MGOTO Main							;Invalid FreqMode = 13
	MGOTO Main							;Invalid FreqMode = 14
	MGOTO Main							;Invalid FreqMode = 15

;=============================================================================
; I N C L U D E S
;=============================================================================
    include "i2cs.inc"

;=============================================================================
;I N I T I A L I Z E
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

	;Initialize Serial Port
	MOVLF D'21', SPBRG					;Set to 57,600 baud (nominally 56,818 baud at 20 MHz clock).
	MOVLF B'00100100', TXSTA			;Initialize transmit in asynchronous mode, high speed mode
	BSF PIE1,TXIE 						;Enable transmit interrupts
	BSF PIE1,RCIE 						;Enable receive interrupts
    BNKSEL 0x0000
	MOVLF B'10000000', RCSTA			;Eight bit recieve not yet enabled

    bcf STATUS, IRP                     ;Ensure indirect addressing of Bank0 and Bank1
    clrf ADCON0

else
    if PIC == 0x887
;==============================================================================
;Contributed by Paul Messer
;==============================================================================
		clrf PORTA
		BNKSEL TRISA
		MOVLF B'00010111', TRISA			;Configure PORTA
		MOVLF B'11000000', OPTION_REG		;Interrupt on rising edge of RB0
		MOVLF B'00010000', INTCON			;Interrupt on RB0 only, but not enabled yet
		MOVLF B'00110001', TRISB
		MOVLF B'11111111', TRISD
		MOVLF B'00000100', TRISE			;Set up USB detect as input, CS and ADDR0 as outputs
		MOVLF B'10111001', TRISC			;Configure PORTC

		BNKSEL	ANSEL
		clrf	ANSEL		;Turn off analog mode on RE2,1,0 and RA5,3,2,1,0 so the pins read digital
		clrf	ANSELH		;Turn off analog mode on RB5,0,4,1,3,2 so the pins read digital

		;Initialize Serial Port

		BNKSEL	BAUDCTL		;Access bank 3
		movlw	0x08		;Set the Serial Port baud rate generators
		movwf	BAUDCTL
		BNKSEL	SPBRG		;Return to bank 1 and continue setting baud rate generators
		movlw	0x56		; for 57.6K baud
		movwf	SPBRG
		movlw	0x00
		movwf	SPBRGH
		movlw	0x24		;Set the Serial Port Transmitter configuration
		movwf	TXSTA
	;	bsf PIE1,TXIE 		;Enable transmit interrupts
		nop
	;	bsf PIE1,RCIE 		;Enable receive interrupts
		BNKSEL	RCSTA		;Access bank 0
		movlw	0x90		;Set the Serial Port Receiver configuration
		movwf	RCSTA

		bcf STATUS, IRP		;Ensure indirect addressing of Bank0 and Bank1
		clrf ADCON0			;Make sure PIC's ADC is off
	
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

		;Initialize Serial Port
		MOVLF D'21', SPBRG					;Set to 57,600 baud (nominally 56,818 baud at 20 MHz clock).
		MOVLF B'00100100', TXSTA			;Initialize transmit in asynchronous mode, high speed mode
		BSF PIE1,TXIE 						;Enable transmit interrupts
		BSF PIE1,RCIE 						;Enable receive interrupts
		BNKSEL 0x0000	
		MOVLF B'10000000', RCSTA			;Eight bit recieve not yet enabled

		bcf STATUS, IRP                     ;Ensure indirect addressing of Bank0 and Bank1
		clrf ADCON0
	endif
endif
	
;=============================================================================
; M A I N
;=============================================================================
Main
    call WaitComm

	clrf modetempb						;Clear the modetempb for repetative sampling
	
MainB
	movf configLoc1, w                  ;Put configuration in WREG
    bcf ADC_CONTROLPORT, ADDR0          ;Select Channel
    btfsc configLoc1, CHANNELBIT
        bsf ADC_CONTROLPORT, ADDR0
    if (high MainSelect)
        movlw high MainSelect          ;Prepare for jump
        movwf PCLATH
    else
        clrf PCLATH
    endif
    andlw (1<<FREQMODEBIT3)|(1<<FREQMODEBIT2)|(1<<FREQMODEBIT1)|(1<<FREQMODEBIT0)   ;Unmask FreqMode
    movwf modetemp						;Multiply by 3
    bcf STATUS, C
    rlf modetemp, f
    addwf modetemp, w
    bcf ADC_PORT, CS	         		;Select MAX114
    btfss configLoc1, TRIGGERENBIT      ;Decide if trigger is enabled.  If so, wait on interrupt
        goto MainSelect        
MainWaitTrig                            ;Trigger is enabled, set up interrupt
    movwf modetemp						;Store the jump for main select (freqmode)
    incf triggerDelay3, w				;Get the trigger delay ready
    movwf cntra
    incf triggerDelay2, w	
    movwf cntrb
    incf triggerDelay1, w
    movwf cntrc    
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
    call WaitByte						;Wait for the trigger unless a "break trigger"
    skipEqLF B'11110011', i2csdata		;message is recieved
    	goto MainWTrigB
    MOVLF B'11011100', i2csdata     	;Respond
    call PutByte
	bcf INTCON, GIE						;Disable RB0 Interrupt
    goto Main							;Abort

                                        ;Note that the gitter on the interrupt is
                                        ;1 cycles.  This translates to 200 ns
                                        ;on the PIC running at 20 MHz

;=============================================================================
; S U B R O U T I N E S
;=============================================================================

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
        goto WaitComm               ;No valid message sent
    MOVLF B'11011110', i2csdata     ;Send beginning of message
    call PutByte
    CONFRECIEVE
    
;	goto WaitComm					;For DEBUGGING, simply return to WaitComm
	return

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
	;Delay 82 cycles
;	MOVLF D'27', cntr
;PutByteSerialDelay
;	decfsz cntr, f
;		goto PutByteSerialDelay
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
    bcf PCLATH, 3					;insure correct program memory page
    bcf PCLATH, 4
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
    bcf PCLATH, 3					;insure correct program memory page
    bcf PCLATH, 4
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
    bcf PCLATH, 3					;insure correct program memory page
    bcf PCLATH, 4
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
    btfss configLoc1, 0			;Delay 250k or 192k
        call DelayFive			 ;192k
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
    btfss configLoc1, 0			;Delay 250k or 192k
        call DelayFive			 ;192k
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
    btfss configLoc1, 0			;Delay 250k or 192k
        call DelayFive			 ;192k
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
    btfss configLoc1, 0			;Delay 250k or 192k
        call DelayFive			 ;192k
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
    btfss configLoc1, 0			;Delay 250k or 192k
        call DelayFive			 ;192k
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
    btfss configLoc1, 0			;Delay 250k or 192k
        call DelayFive			 ;192k
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
    btfss configLoc1, 0			;Delay 250k or 192k
        call DelayFive			 ;192k
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
    btfss configLoc1, 0			;Delay 250k or 192k
        call DelayFive			 ;192k
    goto $ + 1
	nop
	decfsz cntrc, F             	;Increment counter, 64 samples?
        goto SampleXY250kLD
    nop
    movf ADC_DATAPORT, W            ;Sample Y, last in Bank 3
    bsf ADC_CONTROLPORT, RDD        ;Stop conversion
    bcf PCLATH, 3					;insure correct program memory page
    bcf PCLATH, 4
    goto ADCShutdown

;Fastest sample
;Sampling rate = 1 MHz with 20 MHz clock
;Sampling rate = 200 kHz with 4 MHz clock
;-----------------------------------------------------------------------------
Sample1M
    bcf ADC_CONTROLPORT, RDD         	;Begin Conversion
    MOVLF BUFFERMIN, FSR                ;Initialize pointer
	nop
    local count
    count = 1
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
    bcf PCLATH, 3						;insure correct program memory page
    bcf PCLATH, 4
    goto ADCShutdown

;Fastest XY sample
;Sampling rate = 416.667 kHz with 20 MHz clock
;Sampling rate =  83.333 kHz with 4 MHz clock
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
    bcf PCLATH, 3					;insure correct program memory page
    bcf PCLATH, 4
	goto ADCShutdown
	
;Fast sample
;Sampling rate = 833.333 kHz with 20 MHz clock
;Sampling rate = 166.667 kHz with 4 MHz clock
;-----------------------------------------------------------------------------
Sample833k
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
Sample833kEnd
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
    bcf PCLATH, 3						;insure correct program memory page
    bcf PCLATH, 4
    goto ADCShutdown

;Repetative sample
;Equivalent sampling rate = 5 MHz with 20 MHz clock
;-----------------------------------------------------------------------------
SampleRep5M
    movlw high SampleRep5MPickSt
    movwf PCLATH
	movf modetempb, w
	addwf PCL, f
SampleRep5MPickSt
	MGOTO SampleRep5MStep1
	MGOTO SampleRep5MStep2
	MGOTO SampleRep5MStep3
	MGOTO SampleRep5MStep4
	MGOTO SampleRep5MStep5
SampleRep5MPickEn
SampleRep5MStep1
    bcf ADC_CONTROLPORT, RDD         	;Begin Conversion
    MOVLF BUFFERMIN, FSR                ;Initialize pointer
	nop
    local count
    count = 1
    while count < D'52'
	    bsf ADC_CONTROLPORT, RDD		;Latch Conversion into SPP
	    bcf ADC_CONTROLPORT, RDD        ;Start next conversion
        movf ADC_DATAPORT, W	        ;Save Sample
        movwf INDF                      ;Save to QUEUE
        incf FSR, F                     ;Increment QUEUE pointer
        count = count + 1
    endw
    bsf ADC_CONTROLPORT, RDD        	;Stop conversion
    movf ADC_DATAPORT, W            	;Sample
SampleRep5MEndA
	movwf INDF
	incf FSR, F
	goto SampleRep5MEndB
SampleRep5MEndC
	movwf INDF
	decf FSR, F
SampleRep5MEndB
	ADDLF D'3', modetempb, f
	bsf ADC_PORT, CS
	MGOTO MainB  
	
SampleRep5MStep2
    nop
    bcf ADC_CONTROLPORT, RDD         	;Begin Conversion
	goto $ + 1
	nop
    local count
    count = 1
    while count < D'12'
	    bsf ADC_CONTROLPORT, RDD		;Latch Conversion into SPP
	    bcf ADC_CONTROLPORT, RDD        ;Start next conversion
        movf ADC_DATAPORT, W	        ;Save Sample
        movwf INDF                      ;Save to QUEUE
        incf FSR, F                     ;Increment QUEUE pointer
        count = count + 1
    endw
    bsf ADC_CONTROLPORT, RDD			;Latch Conversion into SPP
    bcf ADC_CONTROLPORT, RDD	        ;Start next conversion
    movf ADC_DATAPORT, W            	;Sample
    movwf INDF
    bsf FSR, 7							;goto bank 2
    count = 1
    while count < D'39'
        bsf ADC_CONTROLPORT, RDD        ;Stop conversion
        bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
        movf ADC_DATAPORT, W            ;Sample
        movwf INDF                      ;Save to QUEUE
        decf FSR, F                     ;Increment QUEUE pointer
        count = count + 1
	endw
    bsf ADC_CONTROLPORT, RDD        	;Stop conversion
    movf ADC_DATAPORT, W            	;Sample
	MGOTO SampleRep5MEndC
	
SampleRep5MStep3
    goto $ + 1
    bcf ADC_CONTROLPORT, RDD         	;Begin Conversion
	goto $ + 1
	nop
    local count
    count = 1
    while count < D'25'
        bsf ADC_CONTROLPORT, RDD        ;Stop conversion
        bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
        movf ADC_DATAPORT, W            ;Sample
        movwf INDF                      ;Save to QUEUE
        decf FSR, F                     ;Increment QUEUE pointer
        count = count + 1
	endw
    bsf ADC_CONTROLPORT, RDD        	;Stop conversion
    bcf ADC_CONTROLPORT, RDD
    movf ADC_DATAPORT, W            	;Sample
    movwf INDF
    bsf STATUS, IRP						;goto bank 4
    count = 1
    while count < D'26'
        bsf ADC_CONTROLPORT, RDD        ;Stop conversion
        bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
        movf ADC_DATAPORT, W            ;Sample
        movwf INDF                      ;Save to QUEUE
        incf FSR, F                     ;Increment QUEUE pointer
        count = count + 1
	endw
    bsf ADC_CONTROLPORT, RDD
    movf ADC_DATAPORT, W            ;Sample
	MGOTO SampleRep5MEndA
	
SampleRep5MStep4
    goto $ + 1
    nop
    bcf ADC_CONTROLPORT, RDD         	;Begin Conversion
	goto $ + 1
	nop
    local count
    count = 1
    while count < D'38'
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
    while count < D'13'
        bsf ADC_CONTROLPORT, RDD        ;Stop conversion
        bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
	    movf ADC_DATAPORT, W
        movwf INDF                      ;Save to QUEUE
        decf FSR, F                     ;Increment QUEUE pointer
        count = count + 1
	endw
    bsf ADC_CONTROLPORT, RDD        	;Stop conversion
    movf ADC_DATAPORT, W            	;Sample
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
    bcf ADC_CONTROLPORT, RDD         	;Begin Conversion
	nop
	goto Sample1MhzEnd
	
;Repetative sample
;Equivalent sampling rate = 2.5 MHz with 20 MHz clock
;-----------------------------------------------------------------------------
SampleRep2M
    movlw high SampleRep2MPickSt
    movwf PCLATH
	movf modetempb, w
	addwf PCL, f
SampleRep2MPickSt
	MGOTO SampleRep2MStep1
	MGOTO SampleRep2MStep2
	MGOTO SampleRep2MStep3
SampleRep2MPickEn
SampleRep2MStep1
    bcf ADC_CONTROLPORT, RDD         	;Begin Conversion
    MOVLF BUFFERMIN, FSR                ;Initialize pointer
    nop
    local count
    count = 1
    while count < BUFFERSIZE
        movf ADC_DATAPORT, W	        ;Save Sample
	    bsf ADC_CONTROLPORT, RDD		;Latch Conversion into SPP
	    bcf ADC_CONTROLPORT, RDD        ;Start next conversion
        movwf INDF                      ;Save to QUEUE
        incf FSR, F                     ;Increment QUEUE pointer
        nop
        count = count + 1
    endw
    movf ADC_DATAPORT, W
    bsf ADC_CONTROLPORT, RDD			;Latch Conversion into SPP
    bcf ADC_CONTROLPORT, RDD	        ;Start next conversion
    movwf INDF
    bsf FSR, 7							;goto bank 2
    nop
    count = 1
    while count < D'22'
        movf ADC_DATAPORT, W            ;Sample
        bsf ADC_CONTROLPORT, RDD        ;Stop conversion
        bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
        movwf INDF                      ;Save to QUEUE
        decf FSR, F                     ;Increment QUEUE pointer
		nop
        count = count + 1
	endw
    movf ADC_DATAPORT, W            	;Sample
    bsf ADC_CONTROLPORT, RDD        	;Stop conversion
	MGOTO SampleRep5MEndC

SampleRep2MStep2
    goto $ + 1							;Delay 2
    bcf ADC_CONTROLPORT, RDD         	;Begin Conversion
    goto $ + 1                          ;Wait three cycles
    nop
    local count
    count = 1
    while count < D'42'
        movf ADC_DATAPORT, W            ;Sample
        bsf ADC_CONTROLPORT, RDD        ;Stop conversion
        bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
        movwf INDF                      ;Save to QUEUE
        decf FSR, F                     ;Increment QUEUE pointer
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
        movf ADC_DATAPORT, W            ;Sample
        bsf ADC_CONTROLPORT, RDD        ;Stop conversion
        bcf ADC_CONTROLPORT, RDD        ;Begin next conversion
        movwf INDF                      ;Save to QUEUE
        incf FSR, F                     ;Increment QUEUE pointer
        nop
        count = count + 1
	endw
    movf ADC_DATAPORT, W            ;Sample
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
    bcf ADC_CONTROLPORT, RDD         	;Begin Conversion
    nop
	goto Sample833kEnd
	
;=============================================================================
end     ;end of program
