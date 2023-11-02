

$compile exe "osctest.exe"
$dynamic


$link "advgrfic.pbu"

$link "parallel.pbu"
$link "par_i2c.pbu"

$link "logic.pbu"
$link "strgstff.pbu"
$link "bases.pbu"



dim WTA as integer, WTB as integer
dim LPTPORT as integer, CLK as integer, SDA as integer, SDAIN as integer
dim CLKCONTROL as integer, SDACONTROL as integer, SDAINCONTROL as integer
dim CLKSET as byte, CLKRESET as byte, SDASET as byte, SDARESET as byte
dim SDAINSET as byte, SDAINRESET as byte

public WTA, WTB
public LPTPORT, CLK, SDA, SDAIN
public CLKCONTROL, SDACONTROL, SDAINCONTROL
public SDASET, SDARESET, CLKRESET, CLKSET, SDAINSET, SDAINRESET

dim OUTPUTMODE as integer
shared pinListH$, pinListL$
shared OUTPUTMODE

dim channelA(63) as single, channelB(63) as single
shared channelA(), channelB()

dim voltDivA as single, voltDivB as single, voltOffsetA as single, voltOffsetB as single
shared voltDivA
shared voltDivB
shared voltOffsetA
shared voltOffsetB

dim reconType as byte, timeDiv as single
shared reconType
shared timeDiv

dim triggerSlope as byte, voltOffsetTrigger as single, triggerDelay as single, XYmode as byte
shared triggerSlope
shared voltOffsetTrigger
shared triggerDelay
shared XYmode

shared configLoc1?, triggerDelay1?, triggerDelay2?, sampleRate1?, sampleRate2?

on key(1) gosub exitall
key(1) on
screen 12
colorSet 0,10,10,10
colorSet 1, 20, 25, 37
colorSet 2, 18, 23, 33
colorSet 3, 22, 27, 40
colorSet 4,45,45,40
colorSet 5,25,25,20
colorSet 6,30,30,63
colorSet 7, 0,40,0
colorSet 15, 60, 60, 60

drawDesktop 0,0,639,479

fcolor = 0
bcolor = 4
dcolor = 5
hfcolor = 15
hbcolor = 6

initialize
setPortBases
dim dataRec(63) as byte

redrawScope:
if isPortValid(LPTPORT) then

setBit LPTPORT, CONTROLPORT, 5, 0
setBit LPTPORT, DATAPORT, 3, 1

print "Sending config: "
configLoc1? = &B11110000
triggerDelay1? = 0
triggerDelay2? = 1
sampleRate1? = 0
sampleRate2? = 1
a = sendConfig()
print "done", a

configLoc1? = 0
triggerDelay1? = 0
triggerDelay2? = 0
sampleRate1? = 0
sampleRate2? = 0
a = recieveConfig()
print "Recieving config: ", a
print 5,0,10,20,1
print configLoc1?, triggerDelay1?, triggerDelay2?, sampleRate1?, sampleRate2?
print "done"

a = recieveData(dataRec(), sampleConfig?, channelAOffset?, channelBOffset?)
print a
for i% = 0 to ubound(dataRec) step 2
channelA(a%) = dataRec(i%)/256*5+5
channelB(a%) = dataRec(i%+1)/256*5
incr a%
next
drawScope 100,100,400,400

else
cls
print "Error opening parallel port"
system
end if
exitAll:
system



sub exitProgram
system
end sub

sub drawDesktop(byVal x1%, byVal y1%, byVal x2%, byVal y2%)
view screen (x1%,y1%)-(x2%,y2%)
line(x1%,y1%)-(x2%,y2%), 1, bf
x1% = x1% - x1% mod 4
x2% = x2% - x2% mod 4 - 4
y1% = y1% - y1% mod 4
y2% = y2% - y2% mod 4
for x% = x1% to x2% step 4
for y% = y1% to y2% step 4
pset(x%+ y% mod 3, y%), 2
pset(x%+ y% mod 3+2, y%+2), 3
next
next
view screen
end sub

sub drawScope(byVal x1%, byVal y1%, byVal x2%, byVal y2%)
view screen (x1%,y1%)-(x2%,y2%)
tcolor% = bcolor
bcolor = 0
line(x1%,y1%)-(x2%,y2%), 0, bf
bcolor = tcolor%
incrx% = (x2%-x1%-2)/10
for i% = 1 to 9
x% = x1%+i%*incrx%
line(x%,y1%+1)-(x%,y2%-1),7
next
incry% = (y2%-y1%-2)/10
for i% = 1 to 9
y% = y1%+i%*incry%
line(x1%+1,y%)-(x2%-1,y%),7
next
incrx = (x2%-x1%-2)/63
for i% = 0 to 62
x% = x1%+i%*incrx
line (x%, -incry%*channelA(i%)+y2%)-(x%+incrx, -incry%*channelA(i%+1)+y2%),15
line (x%, -incry%*channelB(i%)+y2%)-(x%+incrx, -incry%*channelB(i%+1)+y2%),14
next
view screen
end sub

function RECONPT()
RECONPT = 7
end function

function RECONSINC()
RECONSINC = 6
end function

function RECONHOLD()
RECONHOLD = 5
end function

function RECONTRI()
RECONTRI = 4
end function

sub initialize
WTA = 100
WTB = 100
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
end sub


function recieveData(dataRec() as byte, sampleConfig as byte, channelAOffset as byte, channelBOffset as byte) public
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
end function

function sendConfig() public
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
end function

function recieveConfig() public
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
end function


function clockDelay(rate1?,rate2?)
if rate2? = 0 then
if rate1? = 0 then rate1? = 255
toRet = 5+7*(rate1?*256+rate2?+256)+3*rate1?
else
toRet = 5+7*(rate1?*256+rate2?)+3*rate1?
end if
clockDelay = toRet
end function

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
