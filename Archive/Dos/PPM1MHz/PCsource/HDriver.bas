'==============================================================================
'*Author:  Jonathan Weaver
'*Date:    2/1/2005
'*Version: 2.0 Build # 1
'*Filename:  HDriver.bas
'*Description:  Driver for the hardware communications with the oscilloscope device
'
'Copyright (C) 2005 Jonathan Weaver
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
'
'TODO:
'(1)  UpdateChannels routine .... DONE 1/31/05
'(2)  TriggerOn/Off routine .... DONE 1/31/05
'(3)  Trigger Positive/Negative routine .... DONE 1/31/05
'(4)  Adjust Sample Rate routine .... DONE 2/1/05
'(5)  Adjust Trigger Delay routine .... DONE 2/1/05
'(6)  Adjust buffersize (from 10 to maxbuffersize), also to get maxbuffersize from configRecieve
'(7)  Generalize initialize routine
'==============================================================================

'==============================================================================
' C O M P I L E R   D I R E C T I V E S
'==============================================================================

$compile unit "HDriver.pbu"
$code seg "oscillo"

'Assign to zero to compile and test hardware connected to the parallel port
'Assign to one to compile and test without connected hardware
%NOHARDWARE = 0

'==============================================================================
' E X T E R N A L   D E C L A R A T I O N S
'==============================================================================

declare sub setPortBases()
declare sub setBit(portNo%, byteNo%, bitNo%, v?)
declare function CONTROLPORT()
declare function BITSET()
declare function BITRESET()
declare function FALSE()
declare function STATUSPORT()
declare sub sendStart()
declare sub sendStop()
declare function sendByte(theByte?)
declare function recieveByte?(ack?)
declare sub waitTime()
declare function TRUE()
declare function FALSE()
declare sub releaseBus()

dim WTA as integer, WTB as integer
dim LPTPORT as integer, CLK as integer, SDA as integer, SDAIN as integer
dim CLKCONTROL as integer, SDACONTROL as integer, SDAINCONTROL as integer
dim CLKSET as byte, CLKRESET as byte, SDASET as byte, SDARESET as byte
dim SDAINSET as byte, SDAINRESET as byte

external WTA, WTB
external LPTPORT, CLK, SDA, SDAIN
external CLKCONTROL, SDACONTROL, SDAINCONTROL
external SDASET, SDARESET, CLKRESET, CLKSET, SDAINSET, SDAINRESET

'==============================================================================
' S H A R E D   D E C L A R A T I O N S
'==============================================================================

'Keep up with the configuration in the PIC Hardware
shared configLoc1?, triggerDelay1?, triggerDelay2?, sampleRate1?, sampleRate2?
shared bufferSize??, bufferSizeMax??

'==============================================================================
' V E R S I O N   F U N C T I O N
'==============================================================================

'==============================================================================
' P U B L I C   S U B R O U T I N E S / F U N C T I O N S
'==============================================================================

'Initialize the hardware driver
sub ini_HDriver public
setPortBases
WTA = 100
WTB = 1
LPTPORT = 0
CLK = 2
SDA = 0
SDAIN = 7
SDACONTROL = CONTROLPORT
SDAINCONTROL = STATUSPORT
CLKCONTROL = DATAPORT
SDAINSET = BITRESET
SDAINRESET = BITSET
SDASET = BITRESET
SDARESET = BITSET
CLKSET = BITSET
CLKRESET = BITRESET
OUTPUTMODE = FALSE
bufferSize?? = 64
bufferSizeMax?? = 64
triggerDelay1? = 0
triggerDelay2? = 1
sampleRate1? = 0
sampleRate2? = 1
configLoc1? = 0
setBit LPTPORT, CONTROLPORT, 5, 0
a? = sendConfig()
a? = recieveConfig()
end sub

'*Reports the maximum number of samples per channel
'*Returns:  the maximum number of samples per channel
function getMaxSamplesPerChannel??() public
frequencyMode? = ConfigLoc1? and &B00000111
if frequencyMode? = SampleXY then
    toRet?? = bufferSizeMax?? \ 2
else
    toRet?? = bufferSizeMax??
end if
getMaxSamplesPerChannel = toRet??
end function

'*Reports the current number of samples per channel
'*Returns:  the current number of samples per channel
function getSamplesPerChannel??() public
frequencyMode? = ConfigLoc1? and &B00000111
if frequencyMode? = SampleXY then
    toRet?? = bufferSize?? \ 2
else
    toRet?? = bufferSize??
end if
getSamplesPerChannel = toRet??
end function

'*Sets the current number of samples per channel, limiting to the maximum allowable
'*spchannel??:  the number of samples per channel to set, up to the maximum
sub setSamplesPerChannel(spchannel??) public
spchannel?? = max(spchannel??,10)
frequencyMode? = ConfigLoc1? and &B00000111
if frequencyMode? = SampleXY then
    bufferSize?? = spchannel??*2
else
    bufferSize?? = spchannel??
end if
bufferSize?? = min(bufferSize??, bufferSizeMax??)
end sub

'*sampleRateAdj?: 0 = no adjustment.  1 = Course adjustment increase.  2 = fine adjustment increase.  4 = course adjustment decrease.  8 = fine adjustment increase.
sub sampleRateChange(sampleRateAdj?) public
frequencyMode? = ConfigLoc1? and &B00000111
select case sampleRateAdj?
case ADJ_CINCR  '1 is course adjustment increase.
    select case frequencyMode?
    case SampleDelay
        sampleRate2? = sampleRate2? / 2
        if sampleRate2? = 0 then
            sampleRate2? = 1
            if sampleRate1? = 0 then
                frequencyMode? = Sample250k
            else
                sampleRate1? = sampleRate1? - 1
            end if
        end if
    case SampleXY
        sampleRate2? = sampleRate2? / 2
        if sampleRate2? = 0 then
            sampleRate2? = 1
            if sampleRate1? > 0 then
                sampleRate1? = sampleRate1? - 1
            end if
        end if
    case Sample833k
        frequencyMode? = Sample1M
    case Sample625k
        frequencyMode? = Sample833k
    case Sample417k
        frequencyMode? = Sample625k
    case Sample250k
        frequencyMode? = Sample417k
        sampleRate1? = 0
        sampleRate2? = 1
    end select
case ADJ_FINCR  '2 is fine adjustment increase.
    select case frequencyMode?
    case SampleDelay
        sampleRate2? = sampleRate2? - 1
        if sampleRate2? = 0 then
            if sampleRate1? = 0 then
                frequencyMode? = Sample250k
            else
                sampleRate1? = sampleRate1? - 1
            end if
            sampleRate2? = 1
        end if
    case SampleXY
        sampleRate2? = sampleRate2? - 1
        if sampleRate2? = 0 then
            sampleRate2? = 1
            if sampleRate1? > 0 then
                sampleRate1? = sampleRate1? - 1
            end if
        end if
    case Sample833k
        frequencyMode? = Sample1M
    case Sample625k
        frequencyMode? = Sample833k
    case Sample417k
        frequencyMode? = Sample625k
    case Sample250k
        frequencyMode? = Sample417k
        sampleRate1? = 0
        sampleRate2? = 1
    end select
case ADJ_CDECR  '4 is course adjustment decrease.
    select case frequencyMode?
    case SampleDelay, SampleXY
        oldSampleRate2? = sampleRate2?
        sampleRate2? = sampleRate2? * 2
        if sampleRate2? < oldSampleRate2? then
            sampleRate2? = 1
            if sampleRate1? < 255 then
                sampleRate1? = sampleRate1? + 1
            end if
        end if
    case Sample1M
        frequencyMode? = Sample833k
    case Sample833k
        frequencyMode? = Sample625k
    case Sample625k
        frequencyMode? = Sample417k
    case Sample417k
        frequencyMode? = Sample250k
    case Sample250k
        frequencyMode? = SampleDelay
        sampleRate1? = 0
        sampleRate2? = 1
    end select
case ADJ_FDECR  '8 is fine adjustment decrease.
    select case frequencyMode?
    case SampleDelay, SampleXY
        sampleRate2? = sampleRate2? + 1
        if sampleRate2? = 0 then
            sampleRate2? = 1
            if sampleRate1? < 255 then
                sampleRate1? = sampleRate1? + 1
            end if
        end if
    case Sample1M
        frequencyMode? = Sample833k
    case Sample833k
        frequencyMode? = Sample625k
    case Sample625k
        frequencyMode? = Sample417k
    case Sample417k
        frequencyMode? = Sample250k
    case Sample250k
        frequencyMode? = SampleDelay
        sampleRate1? = 0
        sampleRate2? = 1
    end select
end select
configLoc1? = (configLoc1? and &B11111000) or frequencyMode?
end sub

'*triggerDelayAdj?: 0 = no adjustment.  1 = Course adjustment increase.  2 = fine adjustment increase.  4 = course adjustment decrease.  8 = fine adjustment increase.
sub triggerDelayChange(triggerDelayAdj?) public
select case triggerDelayAdj?
case ADJ_CDECR  'Course adjustment decrease
        triggerDelay2? = triggerDelay2? / 2
        if triggerDelay2? = 0 then
            triggerDelay2? = 1
            if triggerDelay1? > 0 then
                triggerDelay1? = triggerDelay1? - 1
            end if
        end if
case ADJ_FDECR 'Fine adjustment decrease
    triggerDelay2? = triggerDelay2? - 1
    if triggerDelay2? = 0 then
        if triggerDelay1? = 0 then
            frequencyMode? = Sample250k
        else
            triggerDelay1? = triggerDelay1? - 1
        end if
        triggerDelay2? = 1
    end if
case ADJ_CINCR 'Course adjustment increase
    oldtriggerDelay2? = triggerDelay2?
    triggerDelay2? = triggerDelay2? * 2
    if triggerDelay2? < oldtriggerDelay2? then
        triggerDelay2? = 1
        if triggerDelay1? < 255 then
            triggerDelay1? = triggerDelay1? + 1
        end if
    end if
case ADJ_FINCR 'Fine adjustment increase
    triggerDelay2? = triggerDelay2? + 1
    if triggerDelay2? = 0 then
        triggerDelay2? = 1
        if triggerDelay1? < 255 then
            triggerDelay1? = triggerDelay1? + 1
        end if
    end if
end select
end sub

'*Constant function representing no sampleRate or triggerDelay adjustment
'*return: 0
function ADJ_NOADJ() public
ADJ_NOADJ = 0
end function

'*Constant function representing course increase sampleRate or triggerDelay adjustment
'*return: 1
function ADJ_CINCR() public
ADJ_CINCR = 1
end function

'*Constant function representing fine increase sampleRate or triggerDelay adjustment
'*return: 2
function ADJ_FINCR() public
ADJ_FINCR = 2
end function

'*Constant function representing course decrease sampleRate or triggerDelay adjustment
'*return: 4
function ADJ_CDECR() public
ADJ_CDECR = 4
end function

'*Constant function representing fine decrease sampleRate or triggerDelay adjustment
'*return: 8
function ADJ_FDECR() public
ADJ_FDECR = 8
end function

'Constant function representing 1 MHz sampling rate
'return: 0
function Sample1M()
Sample1M = 0
end function

'Constant function representing 833 kHz sampling rate
'return: 1
function Sample833k()
Sample833k = 1
end function

'Constant function representing 625 kHz sampling rate
'return: 1
function Sample625k()
Sample625k = 2
end function

'Constant function representing 417 kHz sampling rate
'return: 1
function Sample417k()
Sample417k = 3
end function

'Constant function representing 250 kHz sampling rate
'return: 1
function Sample250k()
Sample250k = 4
end function

'Constant function representing delayed sampling rate
'return: 1
function SampleDelay()
SampleDelay = 5
end function

'Constant function representing true XY mode sampling rate
'return: 1
function SampleXY()
SampleXY = 6
end function

'*Sets the sample rate to the rate in sRate!
'*sRate!:  sample rate in Hz, will be modified to ACTUAL sample rate for display at end of call
sub setSampleRate(sRate!) public
fMode? = configLoc1? and &B00000111
if (configLoc1? and 2^5) > 0  then
    theDelay = int(20e6 / 4 / sRate!)
else
    theDelay = int(4e6 / 4 / sRate!)
end if
if fMode? = SampleXY then
    if theDelay < 31 then theDelay = 31
    setClockDelay theDelay-19, sampleRate1?, sampleRate2?
else
    if theDelay =< 5 then
        configLoc1? = configLoc1? and &B11111000 or Sample1M
    elseif theDelay =< 6 then
        configLoc1? = configLoc1? and &B11111000 or Sample833k
    elseif theDelay =< 8 then
        configLoc1? = configLoc1? and &B11111000 or Sample625k
    elseif theDelay =< 12 then
        configLoc1? = configLoc1? and &B11111000 or Sample417k
    elseif theDelay =< 20 then
        configLoc1? = configLoc1? and &B11111000 or Sample250k
    else
        theDelay = theDelay - 12
        if theDelay < 12 then theDelay = 12
        if theDelay > 461314 then theDelay = 461314
        configLoc1? = configLoc1? and &B11111000 or SampleDelay
        setClockDelay theDelay, sampleRate1?, sampleRate2?
    end if
end if
sRate! = getSampleRate!()
end sub

'*Returns the maximum possible sample rate of the device
'*Returns: the maximum possible sample rate of the device
function getMaxSampleRate!() public
if (configLoc1? and 2^5) > 0 then
    '20 MHz Clock
    frequency! = 1e6
else
    '4 MHz Clock
    frequency! = 200000
end if
getMaxSampleRate = frequency!
end function

'*Returns the frequency of the sample rate in Hz
function getSampleRate!() public
'Get the clock cycle delay
fMode? = configLoc1? and &B00000111
select case fMode?
case SampleDelay
    theDelay = clockDelay(sampleRate1?, sampleRate2?)+12
case SampleXY
    theDelay = clockDelay(sampleRate1?, sampleRate2?)+19
case Sample1M
    theDelay = 5
case Sample833k
    theDelay = 6
case Sample625k
    theDelay = 8
case Sample417k
    theDelay = 12
case Sample250k
    theDelay = 20
end select
'Convert to real frequency
if (configLoc1? and 2^5) > 0 then
    '20 MHz Clock
    frequency! = 20e6 / 4 / theDelay
else
    '4 MHz Clock
    frequency! = 4e6 / 4 / theDelay
end if
getSampleRate = frequency!
end function

'*Adjust the delay associated with the trigger
'*tDelay!: the delay in seconds for the trigger, will updated to actual value after delay is set
sub setTriggerDelay(tDelay!) public
if (configLoc1? and 2^5) > 0 then
    theDelay = tDelay! * 20e6 / 4
else
    theDelay = tDelay! * 4e6 / 4
end if
if theDelay < 12 then theDelay = 12
if theDelay > 461314 then theDelay = 461314
setClockDelay theDelay, triggerDelay1?, triggerDelay2?
tDelay! = getTriggerDelay!()
end sub

'*Returns delay in seconds from the trigger level to beginning of capture
function getTriggerDelay!() public
if (configLoc1? and 2^5) > 0 then
    '20 MHz Clock
    Tdelay! = clockDelay(triggerDelay1?, triggerDelay2?) * 4 / 20e6
else
    '4 MHz Clock
    Tdelay! = 4 * clockDelay(triggerDelay1?, triggerDelay2?) / 4e6
end if
getTriggerDelay! = Tdelay!
end function

'*Switch to true XY capture mode based on the state passed
'*state?:  true indicates true XY mode on, false indicates true XY mode off
sub setTrueXY(state?) public
if state? then
    configLoc1? = configLoc1? and &B11111000 or SampleXY
    decr sampleRate2?           'keep sample rate the same between SampleXY and SampleDelay
else
    configLoc1? = configLoc1? and &B11111000 or SampleDelay
    incr sampleRate2?           'keep sample rate the same between SampleXY and SampleDelay
end if
end sub

'*Returns 1 if TrueXY is on, 2 if TrueXY is available but not on.  Otherwise, returns 0.
function getTrueXY() public
toRet = 0
if configLoc1? and SampleXY = SampleXY then
    toRet = 1
elseif configLoc1? and SampleDelay = SampleDelay then
    toRet = 2
end if
getTrueXY = toRet
end function

'*Turns the trigger on or off
'*state?:  true turns the trigger on, false turns the trigger off
sub enableTrigger(state?) public
if state? then
    bit set configLoc1?, 6
else
    bit reset configLoc1?, 6
end if
end sub

'*Returns true if the trigger is enabled, otherwise returns false
function getEnableTrigger() public
getEnableTrigger = bit(configLoc1?,6)
end function

'*Sets the trigger slope either positive or negative
'*state?:  true denotes positive slope, false denotes negative slope
sub triggerSlope(state?) public
if state? then
    bit set configLoc1?, 7
else
    bit reset configLoc1?, 7
end if
end sub

'*Gets the trigger slope.  True denotes positive slope, false denotes negative slope.
function getTriggerSlope() public
getTriggerSlope = bit(configLoc1?, 7)
end function

'*Updates channelA() and channelB() with the appropriate channels
'*channelA():  the channelA array
'*channelB():  the channelB array
'*DCA?:  one if channel A is DC coupled, zero otherwise
'*DCB?:  one if channel B is DC coupled, zero otherwise
'*Return:  two if redraw required, one if successful, zero if not successful
function updateChannels(channelA(), channelB(), DCA?, DCB?) public
static updateState?
toRet? = 0
fMode? = configLoc1? and &B00000111
if fMode? = SampleXY then
    if updateState? = 0 then
        toRet? = sendConfig()
        updateState? = 1
    elseif updateState? = 1 then
        dim dataRec(bufferSize??-1) as byte
        redim channelA(bufferSize??/2-1)
        redim channelB(bufferSize??/2-1)
        if recieveData(dataRec(), sampleConfig?, channelAOffset?, channelBOffset?) then toRet? = 2
        multiplier? = sampleConfig? and &B11000000
        ma% = 1
        select case multiplier?
        case &B00000000 : ma% = 1
        case &B01000000 : ma% = 10
        case &B10000000 : ma% = 100
        end select
        multiplier? = sampleConfig? and &B00110000
        mb% = 1
        select case multiplier?
        case &B00000000 : mb% = 1
        case &B00010000 : mb% = 10
        case &B00100000 : mb% = 100
        end select
        DCA? = bit(sampleConfig?, 3)         'DC coupled?
        DCB? = bit(sampleConfig?, 2)
        'Account for the fact that channelB is not sampled at the same time as channelA
        'In fact ChannelB is sampled 6 clock cycles behind ChannelA but at the least
        'ChannelA is sample once every 33 cycles (151 kHz on 20 MHz clock)
        if (configLoc1? and 2^5) > 0 then
            BDelay! = 6/5e6
        else
            BDelay! = 1/1e6
        end if
        Bscale! = getSampleRate!*BDelay!
        for i?? = 0 to bufferSize??-1 step 2
            channelA(a??) = (dataRec(i??)-channelAOffset?-128)/256*24/ma%
            'Assume function is fairly linear between samples and extrapolate the past
            if i?? = 0 then
                dataPoint? = dataRec(i??+1) + (dataRec(i??+1)-dataRec(i??+3))*Bscale!
            else
                dataPoint? = dataRec(i??+1) + (dataRec(i??-1)-dataRec(i??+1))*BScale!
            end if
            channelB(a??) = (dataPoint?-channelBOffset?-128)/256*24/mb%
            incr a??
        next
        erase dataRec()
        updateState? = 0
    end if
else
    if updateState? = 0 then
        bit reset configLoc1?, 4            'ChannelA first
        toRet? = sendConfig()
        updateState? = 1
    elseif updateState? = 1 then
        dim dataRec(bufferSize??-1) as byte
        redim channelA(bufferSize??-1)
        toRet? = recieveData(dataRec(), sampleConfig?, channelAOffset?, channelBOffset?)
        m% = 1
        multiplier? = sampleConfig? and &B11000000
        select case multiplier?
        case &B00000000 : m% = 1
        case &B01000000 : m% = 10
        case &B10000000 : m% = 100
        end select
        DCA? = bit(sampleConfig?, 3)         'DC coupled?
        for i?? = 0 to bufferSize??-1
            channelA(i??) = (dataRec(i??)-channelAOffset?-128)/256*24/m%
        next
        erase dataRec()
        if toRet? then updateState? = 2
    elseif updateState? = 2 then
        bit set configLoc1?, 4              'Now ChannelB
        toRet? = sendConfig()
        updateState? = 3
    else
        dim dataRec(bufferSize??-1) as byte
        redim channelB(bufferSize??-1)
        if recieveData(dataRec(), sampleConfig?, channelAOffset?, channelBOffset?) then toRet? = 2
        m% = 1
        multiplier? = sampleConfig? and &B00110000
        select case multiplier?
        case &B00000000 : m% = 1
        case &B00010000 : m% = 10
        case &B00100000 : m% = 100
        end select
        DCB? = bit(sampleConfig?, 2)
        for i?? = 0 to bufferSize??-1
            channelB(i??) = (dataRec(i??)-channelBOffset?-128)/256*24/m%
        next
        erase dataRec()
        updateState? = 0
    end if
end if
updateChannels = toRet?
end function

'=================================================================================
'C O M M U N I C A T I O N   R O U T I N E S
'=================================================================================

'*Recieves data from oscilloscope
'*dataRec(): an array of bytes representing data recieved from the slave device
'*sampleConfig: a byte returned to indicate the configuration of the sampling device
'*channelAOffset: a byte returned to indicate the offset of channel A
'*channelBOffset: a byte returned to indicate the offset of channel B
'*returns: 1 if successful, 0 otherwise
function recieveData(dataRec() as byte, sampleConfig as byte, channelAOffset as byte, channelBOffset as byte) public
$IF %NOHARDWARE
    'Send a message to start and recieve acknowledge and the confirming byte
    toRet = 1
    a! = getSampleRate!()
    b! = getTriggerDelay!()
    if a! = 0 then
        toRet = 0
    else
        nb! = rnd*64/a!
        for i? = 0 to ubound(dataRec)
            t! = i? / a!
            if configLoc1? and &B00000111 = sampleXY then
                'Channel B is 6 cycles behind channel A
                if (configLoc1? and 2^5) > 0 then
                    BDelay! = 6/5e6
                else
                    BDelay! = 1/1e6
                end if
                if i? mod 2 = 0 then
                    'Channel A, 4*cos(2*pi*5000*t)
                    if bit(configLoc1?,6) then                  'Trigger enabled
                        if bit(configLoc1?, 7) then             'Trigger positive
                            dataRec(i?) = 32*cos(2*3.1415926*5000*(t!-b!))+128
                        else                                    'Trigger negative
                            dataRec(i?) = 32*cos(2*3.1415926*5000*(t!-b!)+3.1415926)+128
                        end if
                    else
                        dataRec(i?) = 32*cos(2*3.1415926*5000*(t!-nb!))+128
                    end if
                else
                    'Channel B, 2*sin(2*pi*5000*t)
                    if bit(configLoc1?,6) then                  'Trigger enabled
                        if bit(configLoc1?, 7) then             'Trigger positive
                            dataRec(i?) = 64*sin(2*3.1415926*5000*(t!-b!))+128
                        else                                    'Trigger negative
                            dataRec(i?) = 64*sin(2*3.1415926*5000*(t!-b!)+3.1415926)+128
                        end if
                    else
                        dataRec(i?) = 64*sin(2*3.1415926*5000*(t!-nb!))+128
                    end if
                end if
            else
                if bit(configLoc1?,4) then
                    'Channel B, 2*sin(2*pi*5000*t)
                    if bit(configLoc1?,6) then                  'Trigger enabled
                        if bit(configLoc1?, 7) then             'Trigger positive
                            dataRec(i?) = 64*sin(2*3.1415926*5000*(t!-b!))+128
                        else                                    'Trigger negative
                            dataRec(i?) = 64*sin(2*3.1415926*5000*(t!-b!)+3.1415926)+128
                        end if
                    else
                        dataRec(i?) = 64*sin(2*3.1415926*5000*(t!-nb!))+128
                    end if
                else
                    'Channel A, 4*cos(2*pi*5000*t)
                    if bit(configLoc1?,6) then                  'Trigger enabled
                        if bit(configLoc1?, 7) then             'Trigger positive
                            dataRec(i?) = 32*cos(2*3.1415926*5000*(t!-b!))+128
                        else                                    'Trigger negative
                            dataRec(i?) = 32*cos(2*3.1415926*5000*(t!-b!)+3.1415926)+128
                        end if
                    else
                        dataRec(i?) = 32*cos(2*3.1415926*5000*(t!-nb!))+128
                    end if
                end if
            end if
        next
    end if
    sampleConfig = 0
    channelAOffset = 0
    channelBOffset = 0
    'Conclude the message
    sendStop
    recieveData = toRet
$ELSE
    'Send a message to start and recieve acknowledge and the confirming byte
    toRet = beginMessage(&b11111000, &b11011100)
    'Now recieve the data
    if toRet = 1 then
        for i? = 0 to ubound(dataRec)-1
            waitTime
            dataRec(i?) = recieveByte?(TRUE)
        next
        waitTime
        dataRec(i?) = recieveByte?(FALSE)
        waitTime
        'Now recieve ending configuration data
        sampleConfig = recieveByte?(TRUE)
        waitTime
        channelAOffset = recieveByte?(TRUE)
        waitTime
        channelBOffset = recieveByte?(FALSE)
        waitTime
    end if
    'Conclude the message
    sendStop
    recieveData = toRet
$ENDIF
end function

'*Sends configuration settings to the oscilloscope
'*Returns: 1 if the configuration was accepted by the device, otherwise returns 0
function sendConfig() public
$if %NOHARDWARE
    sendConfig = 1
$else
    'Send a message to start and recieve acknowledge and the confirming byte
    toRet = beginMessage(&b11111010, &b11011110)
    if toRet = 1 then
        'Now send the configuration
        ack? = sendByte(configLoc1?)
        waitTime
        ack? = sendByte(triggerDelay1?)
        waitTime
        ack? = sendByte(triggerDelay2?)
        waitTime
        ack? = sendByte(sampleRate1?)
        waitTime
        sendConfig = sendByte(sampleRate2?)
        'Conclude the message
    end if
    sendStop
    sendConfig = toRet
$endif
end function

'*Recieves configuration settings from the oscilloscope
'*returns:  1 if sucessful, 0 otherwise
function recieveConfig() public
$if %NOHARDWARE
    recieveConfig = 1
$else
    'Send a message to start and recieve acknowledge and the confirming byte
    toRet = beginMessage(&b11111001, &b11011101)
    if toRet = 1 then
        'Recieve the configuration
        configLoc1? = recieveByte?(TRUE)
        triggerDelay1? = recieveByte?(TRUE)
        triggerDelay2? = recieveByte?(TRUE)
        sampleRate1? = recieveByte?(TRUE)
        sampleRate2? = recieveByte?(FALSE)
    end if
    'Conclude the message
    sendStop
    recieveConfig = toRet
$endif
end function

'==============================================================================
' P R I V A T E   S U B R O U T I N E S / F U N C T I O N S
'==============================================================================

'*returns the values for rate1?, rate2? to get clockDelay to return dLay&
'*dLay&:  a number between 12 and 461314
'*rate1?:  the high part of the clock delay
'*rate2?:  the low part of the clock delay
sub setClockDelay(byval dLay&, rate1?, rate2?)
rate1? = int(dLay& / (7*256+3))
rate2? = int((dLay& - 5 - 3 * rate1?) / 7) - rate1? * 256
end sub

function clockDelay(byval rate1?, byval rate2?)
if rate2? = 0 then
    if rate1? = 0 then rate1? = 255
    toRet = 5+7*(rate1?*256+rate2?+256)+3*rate1?
else
    toRet = 5+7*(rate1?*256+rate2?)+3*rate1?
end if
clockDelay = toRet
end function

'*Send a message to start and recieve acknowledge and the confirming byte
'*commandByte?:  the command byte to send
'*replyByte?:  the expected response
'*returns:  1 if successful, 0 otherwise
function beginMessage(commandByte?,replyByte?)
cnt = 0
toRet? = 1
do
    releaseBus
    cntb = 0
    do
        sendStart
        waitTime
        ackA? = sendByte(commandByte?)
        incr cntb
    loop until ackA? = 1 or cntb > 9
    waitTime
    incr cnt
loop until recieveByte?(TRUE) = replyByte? or cnt > 9
if cnt = 10 then
    toRet? = 0
end if
beginMessage = toRet?
end function
