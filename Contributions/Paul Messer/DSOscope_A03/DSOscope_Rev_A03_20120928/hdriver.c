/* ==============================================================================
 * Author:  Jonathan Weaver, jonw0224@aim.com
 * E-mail Contact: jonw0224@aim.com
 * Description:  Hardware interface to the oscilloscope
 * Version: 1.0.5
 * Date: 6/13/2012
 * Filename:  hdriver.c, hdriver.h
 *
 * Versions History:
 *      9/6/2006 - Created file, configuration routines and background routines
 *      1/31/2009 - Modified file for extended XY sampling and repetitive
 *                    sampling.
 *                    Added setRepetitive, getRepetitive, and
 *                    updateChannelHelper routines.
 *                    Added useRepetitive and useInterlace global variables
 *                    Modified getMaxSamplesPerChannel, getSamplesPerChannel,
 *                    setSamplesPerChannel, sampleRateChange, getSampleRate,
 *                    setSampleRate, getMaxSampleRate, setTrueXY, getTrueXY,
 *                    and updateChannel routines.
 *      2/11/2009 - Completed modifications and fixed bugs.
 *      3/22/2009 - Added modifications for extended trigger delay.
 *      3/31/2009 - Completed trigger delay modifications and fixed bugs.
 *      4/1/2009 - Fixed more bugs and modified updateChannels to change refresh
 *      2/19/2010 - Modified updateChannels to not send a config message when
 *                  in interlace mode unnecessarily.  Interlace mode is intended
 *                  to be a single shot mode that responds to a single trigger
 *                  event.  Without this change, half of the trigger events are
 *                  ignored in interlace mode.
 *      6/3/2010 -  Began adding serial port support.  Edited hDriverSetConfig,
 *                  hDriverGetConfig, hDriverInitialize routines.
 *      6/13/2012 - Serial port bug fixes.
 *
 * Copyright (C) 2006-2009 Jonathan Weaver
 *
 * This file is part of PPMScope.
 *
 * PPMScope is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * ==============================================================================
 */

#include "par_i2c.h"
#include "parallel.h"
#include "serial.h"
#include "hdriver.h"

#include "settings.h"
#include "debug.h"
//#include <windows.h>

#ifdef NOHARDWARE
#include <stdlib.h>
#include <time.h>
#include <math.h>
#endif

int bufferSizeMax, bufferSize;
unsigned char configLoc1, triggerDelay1, triggerDelay2, triggerDelay3, sampleRate1, sampleRate2;
int portType;
double triggerLevel;
unsigned char useRepetitive, useInterlace;

/*****************************************************************************/
/* B A C K G R O U N D   R O U T I N E S                                     */
/*****************************************************************************/

int getMultiplierA(char sampleConfig)
{
    switch(sampleConfig & 0xC0)
    {
    case 0x40:
        return 2;
    case 0x80:
        return 5;
    }
    return 1;
}

int getMultiplierB(char sampleConfig)
{
    switch(sampleConfig & 0x30)
    {
    case 0x10:
        return 2;
    case 0x20:
        return 5;
    }
    return 1;
}

double dataValue(char ch, unsigned char dataPoint, unsigned char offset, double m)
{
    return ((double) (dataPoint - offset - 127.5)) /
           256.0*3.9*5/m;
}

/* Helper routine.  Populates ch[] for updateChannel
 * ch: channel array to populate
 * dataRec: byte data to populate from
 * chOffset: channel offset to use
 * m: channel gain to use
 */
int updateChannelHelper(double ch[], unsigned char dataRec[],
                        unsigned char chOffset, double m)
{
    char frequencyMode;
    int a, i;
    frequencyMode = configLoc1 & 0x0f;
    if(frequencyMode == SAMPLE_REP5M)
    {
        a = 0;
        for(i = 0; i < bufferSizeMax; i = i + 5)
            ch[i] = dataValue(0, dataRec[a++], chOffset, m);
        for(i = 1; i < bufferSizeMax; i = i + 5)
            ch[i] = dataValue(0, dataRec[a++], chOffset, m);
        for(i = 2; i < bufferSizeMax; i = i + 5)
            ch[i] = dataValue(0, dataRec[a++], chOffset, m);
        for(i = 3; i < bufferSizeMax; i = i + 5)
            ch[i] = dataValue(0, dataRec[a++], chOffset, m);
        for(i = 4; i < bufferSizeMax; i = i + 5)
            ch[i] = dataValue(0, dataRec[a++], chOffset, m);
    }
    else if(frequencyMode == SAMPLE_REP2M)
    {
        a = 0;
        for(i = 0; i < bufferSizeMax; i = i + 3)
            ch[i] = dataValue(0, dataRec[a++], chOffset, m);
        for(i = 1; i < bufferSizeMax; i = i + 3)
            ch[i] = dataValue(0, dataRec[a++], chOffset, m);
        for(i = 2; i < bufferSizeMax; i = i + 3)
            ch[i] = dataValue(0, dataRec[a++], chOffset, m);
    }
    else
    {
        for(i = 0; i < bufferSizeMax; i++)
            ch[i] = dataValue(0, dataRec[i], chOffset, m);
    }
    return 0;
}

/* Returns the values for rate1 and rate2 to get the clock delay
 * dlay: a number between 12 and 457730
 * rate1: the high part of the clock delay
 * rate2: the low part of the clock delay */
int setClockDelay(int dlay, unsigned char* rate1, unsigned char* rate2)
{
    *rate1 = dlay / (7*256 + 3);
    *rate2 = (dlay - 5 - 3*(*rate1))/7 - (*rate1)*256;
    return 0;
}

/* Returns the clock delay based on values for rate1 and rate2
 * rate1: the high part of the clock delay
 * rate2: the low part of the clock delay */
int clockDelay(unsigned char rate1, unsigned char rate2)
{
    if(!rate2)
    {
        if(!rate1) rate1 = 255;
        return 5 + 7*(rate1*256+256+rate2)+3*rate1;
    }
    else
        return 5 + 7*(rate1*256+rate2)+3*rate1;
}

/*****************************************************************************/
/* C O M M U N I C A T I O N S   R O U T I N E S                             */
/*****************************************************************************/

/* Start of Paul's code change */
/* Flush the receiver buffer   */
void uflushReceiverBuffer()
{
    int bogicount;
    unsigned char bogichar;
    bogicount = 0;
    #ifdef DEBUGON
        dPrStr("Flushing Receiver Buffer...");
    #endif
    DIAGPRINT "Flushing Receiver Buffer...\r\n");
   while (serialRXChar(&bogichar) != 0)
   {
       ++bogicount;
   }
    #ifdef DEBUGON
        dPrStr("Flushed Character Count: "); dPrInt(bogicount); dPrStr("\r\n");
    #endif
    DIAGPRINT "Flushed Character Count: 0x%X\r\n", bogicount);
}
/* End of Paul's code change */

/*
 */
int ureleaseBus()
{
    if(portType == PARALLELPORT)
    {
        return releaseBus();
    }
    return 0;
}

/*
 */

/* Send a start signal to the slave device */
int usendStart()
{
    if(portType == PARALLELPORT)
    {
        return sendStart();
    }
    else if(portType == SERIALPORT)
    {
        uflushReceiverBuffer();
    }
    return 0;
}

/* Send a stop signal to the slave device */
int usendStop()
{
    if(portType == PARALLELPORT)
    {
        return sendStop();
    }
    return 0;
}

/* Send a byte to the slave device
 * theByte:  a byte to send
 * returns: 1 if the slave device acknowledges, 0 if the slave device does not
 */
short usendByte(char theByte)
{
    if(portType == PARALLELPORT)
    {
        return sendByte(theByte);
    }
    else if(portType == SERIALPORT)
    {
        return serialTXChar(theByte);
    }
    return 1;
}

/* Recieve a byte from the slave device
 * ack: nonzero indicates send acknowledge, zero indicates don't send acknowledge
 * tmout: 1 indicates use a timeout.  0 indicates don't allow a timeout.  Will be returned as 1 if timed out.  0 otherwise.
 * returns: the byte recieved
 */
short urecieveByte(char ack, char* tmout)
{
    if(portType == PARALLELPORT)
    {
        return recieveByte(ack);
    }
    else if(portType == SERIALPORT)
    {
        unsigned char toRet;
        if(*tmout)
            *tmout = !serialRXChar(&toRet);
        else
            while(!serialRXChar(&toRet));
        return toRet;
    }
    return 0;
}

/* Send a message to start and recieve acknowlede and the confirming byte
 * command: the command byte to send
 * reply: the expected reply byte
 * return: 1 if sucessful, 0 if not */
int beginMessage(short command, short reply)
{
    int count, countb, countMax;
    char tmout;
    short rec;
    count = 0;
    tmout = 1;  // Use a serial port timeout

    #ifdef DEBUGON
        dPrStr("Begin Message...\r\n");
    #endif
    DIAGPRINT "Begin Message...\r\n", sampleRate1);
    /* if(portType == SERIALPORT)
    {
        uflushReceiverBuffer();
    } */
    do
    {
        ureleaseBus();
        #ifdef DEBUGON
            dPrStr("Transmit: "); dPrInt(command); dPrStr("\r\nExpecting Response: "); dPrInt(reply); dPrStr("\r\n");
        #endif
        DIAGPRINT "Transmit: 0x%X\r\nExpecting Response: 0x%X\r\n", command, reply);
        usendStart();
        usendByte(command);
        if(portType == SERIALPORT)
        {
             /* If using a serial port, send the command once and wait until the
             * recieve times out, then go ahead and exit */
            do
            {
                rec = urecieveByte(1, &tmout);
                #ifdef DEBUGON
                    dPrStr("Receive: "); dPrInt(rec);
                    dPrStr("  Timeout: "); dPrInt(tmout); dPrStr("\r\n");
                #endif
                DIAGPRINT "Receive: 0x%X  Timeout: %d\r\n", rec, tmout);
            } while((tmout == 1) && (++count < 10));

        }
        else
        {
            rec = urecieveByte(1, &tmout);
            #ifdef DEBUGON
                dPrStr("Receive: "); dPrInt(rec); dPrStr("\r\n");
            #endif
            DIAGPRINT "Receive: 0x%X\r\n", rec);
        }
     } while ((rec != reply) && (++count < 10));
    if(rec != reply)
    {
        #ifdef DEBUGON
             dPrStr("Message failed to initiate\r\n");
        #endif
        DIAGPRINT "Message failed to initiate\r\n");
        return 0;
    }
    #ifdef DEBUGON
         dPrStr("Message initiated sucessfully\r\n");
    #endif
    DIAGPRINT "Message initiated successfully\r\n");
    return 1;
}

/* Recieves configuration settings from the oscilloscope
 * returns: 1 if successful, 0 otherwise */
int recieveConfig()
{
#ifdef NOHARDWARE
    bufferSizeMax = BUFFER_MAX;
    /* 1 MHz version */
    configLoc1 = configLoc1 | (1 << 5);
    return 1;
#else
    #ifdef DEBUGON
        dPrStr("Recieving configuration...\r\n");
    #endif
    DIAGPRINT "Receiving Configuration...\r\n");
    char bufferSizeML, bufferSizeMH;
    char tmout = 0;                            //Don't use a serial port timeout
    if (beginMessage(0xF9, 0xDD))
    {
        bufferSizeMH = urecieveByte(1, &tmout);
        bufferSizeML = urecieveByte(1, &tmout);
        bufferSizeMax = bufferSizeMH << 8 + bufferSizeML;
        #ifdef DEBUGON
            dPrStr("Receiving BufferSize: "); dPrInt(bufferSizeMax); dPrStr("\r\n");
        #endif
        DIAGPRINT "Receiving BufferSize: %d\r\n", bufferSizeMax);
        configLoc1 = urecieveByte(1, &tmout);
        #ifdef DEBUGON
            dPrStr("Receiving ConfigLoc1: "); dPrInt(configLoc1); dPrStr("\r\n");
        #endif
        DIAGPRINT "Receiving ConfigLoc1: 0x%X\r\n", configLoc1);
        triggerDelay1 = urecieveByte(1, &tmout);
        #ifdef DEBUGON
            dPrStr("Receiving TriggerDelay1: "); dPrInt(triggerDelay1); dPrStr("\r\n");
        #endif
        DIAGPRINT "Receiving TriggerDelay1: 0x%X\r\n", triggerDelay1);
        triggerDelay2 = urecieveByte(1, &tmout);
        #ifdef DEBUGON
            dPrStr("Receiving TriggerDelay2: "); dPrInt(triggerDelay2); dPrStr("\r\n");
        #endif
        DIAGPRINT "Receiving TriggerDelay2: 0x%X\r\n", triggerDelay2);
        triggerDelay3 = urecieveByte(1, &tmout);
        #ifdef DEBUGON
            dPrStr("Receiving TriggerDelay3: "); dPrInt(triggerDelay3); dPrStr("\r\n");
        #endif
        DIAGPRINT "Receiving TriggerDelay3: 0x%X\r\n", triggerDelay3);
        sampleRate1 = urecieveByte(1, &tmout);
        #ifdef DEBUGON
            dPrStr("Receiving SampleRate1: "); dPrInt(sampleRate1); dPrStr("\r\n");
        #endif
        DIAGPRINT "Receiving SampleRate1: 0x%X\r\n", sampleRate1);
        sampleRate2 = urecieveByte(0, &tmout);
        #ifdef DEBUGON
            dPrStr("Receiving SampleRate2: "); dPrInt(sampleRate2); dPrStr("\r\n");
        #endif
        DIAGPRINT "Receiving SampleRate2: 0x%X\r\n\r\n", sampleRate2);
        usendStop();
        return 1;
    }
    usendStop();
    return 0;
#endif
}

/* Sends configuration settings to the oscilloscope
 * returns: 1 if the configuration was accepted by the device, otherwise 0 */
int sendConfig()
{
#ifdef NOHARDWARE
    static char a;
//    if(a)
//        a = 0;
//    else
        a = 1;
    return a;
#else
    int a;
    #ifdef DEBUGON
        dPrStr("Sending Confiuration...\r\n");
    #endif
    DIAGPRINT "Sending Configuration...\r\n");
    if (beginMessage(0xFA, 0xDE))
    {
        #ifdef DEBUGON
            dPrStr("ConfigLoc1 Transmit: ");
            dPrInt(configLoc1);
        #endif
        DIAGPRINT "ConfigLoc1 Transmit: 0x%X\r\n", configLoc1);
        usendByte(configLoc1);
        #ifdef DEBUGON
            dPrStr("\r\nTriggerDelay1 Transmit: ");
            dPrInt(triggerDelay1);
        #endif
        DIAGPRINT "TriggerDelay1 Transmit: 0x%X\r\n", triggerDelay1);
        usendByte(triggerDelay1);
        #ifdef DEBUGON
            dPrStr("\r\nTriggerDelay2 Transmit: ");
            dPrInt(triggerDelay2);
        #endif
        DIAGPRINT "TriggerDelay2 Transmit: 0x%X\r\n", triggerDelay2);
        usendByte(triggerDelay2);
        #ifdef DEBUGON
            dPrStr("\r\nTriggerDelay3 Transmit: ");
            dPrInt(triggerDelay3);
        #endif
        DIAGPRINT "TriggerDelay3 Transmit: 0x%X\r\n", triggerDelay3);
        usendByte(triggerDelay3);
        #ifdef DEBUGON
            dPrStr("\r\nSampleRate1 Transmit: ");
            dPrInt(sampleRate1);
        #endif
        DIAGPRINT "SampleRate1 Transmit: 0x%X\r\n", sampleRate1);
        usendByte(sampleRate1);
        #ifdef DEBUGON
            dPrStr("\r\nSampleRate2 Transmit: ");
            dPrInt(sampleRate2);
        #endif
        DIAGPRINT "SampleRate2 Transmit: 0x%X\r\n\r\n", sampleRate2);
        a = usendByte(sampleRate2);
        #ifdef DEBUGON
            dPrStr("\r\nAcknowledged: ");
            dPrInt(a);
            dPrStr("\r\n");
        #endif
        usendStop();
        return a;
    }
    return 0;
#endif
}

/* Recieve data from the oscilloscope
 * dateRec: array of bytes representing sample data
 * sampleConfig: indication of the state of the sampling device
 * chAOffset: the offset of channel 1
 * chBOffset: the offset of channel 2
 * trigOffset: the trigger offset */
int recieveData(unsigned char dataRec[], unsigned char* sampleConfig,
    unsigned char* chAOffset, unsigned char* chBOffset,
    unsigned char* trigOffset)
{
#ifdef NOHARDWARE
#define PI (3.141592653589793)
    double a, b, nb, t, bDelay;
    int i;
    a = getSampleRate();
    b = getTriggerDelay();
    if(a == 0)
    {
        return 0;
    }
    //srand(time(NULL));
    nb = ((double) (rand() % 640))/10.0/a;
    for(i = 0; i < BUFFER_MAX; i++)
    {
        t = ((double) i)/a;
        if(getTrueXY() == 1)
        {
            if(configLoc1 & (1 << 5))
                bDelay = 6.0/5.0e6;
            else
                bDelay = 6.0/1.0e6;
            if(!(i % 2))
            {
                /* channel a = 2*cos(2*PI*5000*t) */
                if(configLoc1 & (1<<6))  /* trigger enabled */
                    if(configLoc1 & (1<<7)) /* trigger positive */
                        dataRec[i] = (int) (32.0*cos(2*PI*5000*(t/2-b)) + 127.5);
                    else
                        dataRec[i] = (int) (32.0*cos(2*PI*5000*(t/2-b)+PI) + 127.5);
                else
                    dataRec[i] = (int) (32.0*cos(2*PI*5000*(t/2-nb)) + 127.5);
            } /* if odd */
            else
            {
                /* channel b = 4*sin(2*pi*5000*t) */
                if(configLoc1 & (1<<6))  /* trigger enabled */
                    if(configLoc1 & (1<<7)) /* trigger positive */
                        dataRec[i] = (int) (64.0*sin(2*PI*5000*(t/2 - 1.2e-6 - b)) + 127.5);
                    else
                        dataRec[i] = (int) (64.0*sin(2*PI*5000*(t/2 - 1.2e-6 - b)+PI) + 127.5);
                else
                    dataRec[i] = (int) (64.0*sin(2*PI*5000*(t/2 - 1.2e-6 - nb)) + 127.5);
            } /* if even */
        } /* sampleXY */
        else
        {
            if(configLoc1 & (1<<4)) /* channel b = 4*sin(2*PI*5000*t) */
                if(configLoc1 & (1<<6))  /* trigger enabled */
                    if(configLoc1 & (1<<7)) /* trigger positive */
                        dataRec[i] = (int) (64.0*sin(2*PI*5000*(t-b)) + 127.5);
                    else
                        dataRec[i] = (int) (64.0*sin(2*PI*5000*(t-b)+PI) + 127.5);
                else
                    dataRec[i] = (int) (64.0*sin(2*PI*5000*(t-nb)) + 127.5);
            else /* channel a = 2*cos(2*PI*5000*t) */
                if(configLoc1 & (1<<6))  /* trigger enabled */
                    if(configLoc1 & (1<<7)) /* trigger positive */
                        dataRec[i] = (int) (32.0*cos(2*PI*5000*(t-b)) + 127.5);
                    else
                        dataRec[i] = (int) (32.0*cos(2*PI*5000*(t-b)+PI) + 127.5);
                else
                    dataRec[i] = (int) (32.0*cos(2*PI*5000*(t-nb)) + 127.5);
        } /* else sampleXY */
    } /* for */
    *sampleConfig = (0 << 7) |  /* Ch1 5X */
                    (0 << 6) |  /* Ch1 2X */
                    (0 << 5) |  /* Ch2 5X */
                    (0 << 4) |  /* Ch2 2X */
                    (0 << 3) |  /* Ch1 AC */
                    (0 << 2);   /* Ch2 AC */
    *chAOffset = 0;
    *chBOffset = 0;
    *trigOffset = 127;
    return 1;
#else
    int count;
    char tmout = 0;     //Don't use a serial port timeout

    #ifdef DEBUGON
        dPrStr("Requesting data\r\n");
    #endif
    DIAGPRINT "Requesting data\r\n");
    if (beginMessage(0xF8, 0xDC))
    {
        for(count = 0; count < bufferSizeMax-1; count++)
        {
            if(portType == SERIALPORT)
            {
                /* Don't allow a timeout when recieving data */
                dataRec[count] = urecieveByte(1, &tmout);
            }
            else
                dataRec[count] = urecieveByte(1, &tmout);
            #ifdef DEBUGON
                dPrStr("Byte ("); dPrInt(count); dPrStr("): "); dPrInt(dataRec[count]); dPrStr("\r\n");
            #endif
            DIAGPRINT "Byte (%d): %d\r\n", count, dataRec[count]);
        }
        dataRec[bufferSizeMax-1] = urecieveByte(0, &tmout);
        #ifdef DEBUGON
            dPrStr("Byte ("); dPrInt(bufferSizeMax - 1); dPrStr("): "); dPrInt(dataRec[bufferSizeMax - 1]); dPrStr("\r\n");
        #endif
        DIAGPRINT "Byte (%d): %d\r\n", bufferSizeMax - 1, dataRec[bufferSizeMax - 1]);
        *sampleConfig = urecieveByte(1, &tmout);
        #ifdef DEBUGON
            dPrStr("SampleConfig "); dPrInt(*sampleConfig); dPrStr("\r\n");
        #endif
        DIAGPRINT "SampleConfig 0x%X\r\n", *sampleConfig);
        *chAOffset = urecieveByte(1, &tmout);
        #ifdef DEBUGON
            dPrStr("ChannelAOffset "); dPrInt(*chAOffset); dPrStr("\r\n");
        #endif
        DIAGPRINT "ChannelAOffset %d\r\n", *chAOffset);
        *chBOffset = urecieveByte(1, &tmout);
        #ifdef DEBUGON
            dPrStr("ChannelBOffset "); dPrInt(*chBOffset); dPrStr("\r\n");
        #endif
        DIAGPRINT "ChannelBOffset %d\r\n", *chBOffset);
        *trigOffset = urecieveByte(0, &tmout);
        #ifdef DEBUGON
            dPrStr("TriggerOffset "); dPrInt(*trigOffset); dPrStr("\r\n");
        #endif
        DIAGPRINT "TriggerOffset %d\r\n", *trigOffset);

        return 1;
    }
    return 0;
#endif
}

/*******************************************************************************
 * P U B L I C   R O U T I N E S
 ******************************************************************************/

/* Sets the configuration for the hDriver.  Configuration must be set before
 * hDriver is initialized.
 * pType: portType (PARALLELPORT, SERIALPORT, USBPORT)
 * portNum: Indicates which port to use
 * tickCount: delay for clocking waveforms
 * conf[]: six character array indicating configuration:  configLoc1,
 *         triggerDelay1, triggerDelay2, triggerDelay3, sampleRate1, sampleRate2
 * buffSz: buffer size per channel
 * returns: 1 if successful, 0 otherwise */
int hDriverSetConfig(int pType, int portNum, int tickCount, char conf[], int buffSz)
{
    portType = pType;

    switch(conf[0] & 0x0f)
    {
    case SAMPLE_REP5M:
    case SAMPLE_REP2M:
        useRepetitive = 1;
        useInterlace = 0;
        enableTrigger(1);
        break;
    case SAMPLE_XYDELAY:
    case SAMPLE_XY192K:
    case SAMPLE_XY250K:
    case SAMPLE_XY417K:
    case SAMPLE_XYINTDELAY:
        useRepetitive = 0;
        useInterlace = 1;
    default:
        useRepetitive = 0;
        useInterlace = 0;
    }

    if(portType == PARALLELPORT || portType == SERIALPORT)
    {
        lptPort = portNum;
        wTime = tickCount;
        configLoc1 = conf[0];
        triggerDelay1 = conf[1];
        triggerDelay2 = conf[2];
        triggerDelay3 = conf[3];
        sampleRate1 = conf[4];
        sampleRate2 = conf[5];
        bufferSize = buffSz;
        return 1;
    }
    else
    {
        /* Not yet implemented */

        return 0;
    }
}

/* Gets the configuration from the hDriver after it is set.
 * pType: portType (PARALLELPORT, SERIALPORT, USBPORT)
 * portNum: Indicates which port to use
 * tickCount: delay for clocking waveforms
 * conf[]: six character array indicating configuration:  configLoc1,
 *         triggerDelay1, triggerDelay2, triggerDelay3, sampleRate1, sampleRate2
 * buffSz: buffer size per channel
 * returns: 1 if successful, 0 otherwise */
int hDriverGetConfig(int* pType, int* portNum, int* tickCount, char conf[], int* buffSz)
{
    if(portType == PARALLELPORT || portType == SERIALPORT)
    {
        *pType = portType;
        *portNum = lptPort;
        *tickCount = wTime;
        conf[0] = configLoc1;
        conf[1] = triggerDelay1;
        conf[2] = triggerDelay2;
        conf[3] = triggerDelay3;
        conf[4] = sampleRate1;
        conf[5] = sampleRate2;
        *buffSz = bufferSize;
        return 1;
    }
    else
    {
        /* Not yet implemented */

        return 0;
    }
}

/* Initialize the hDriver by opening the ports, setting pins, etc.
 * returns: 1 if successful, 0 otherwise */
int hDriverInitialize()
{
    int a;
    dPtr = diagnostic;
    DIAGPRINT "Initializing...\r\n");

    if(portType == PARALLELPORT)
    {
        parallelPortClose();

        /* Initialize */
        if(lptPort == LPTCUSTOM)
        {
            DIAGPRINT "Opening port...\r\nPort Type: Parallel Port\r\nPort: Custom LPT\r\nPort Address: 0x%X\r\n", portAdr(lptPort));
        }
        else
        {
            DIAGPRINT "Opening port...\r\nPort Type: Parallel Port\r\nPort: LPT%d\r\nPort Address: 0x%X\r\n", lptPort+1, portAdr(lptPort));
        }
        if(!parallelPortOpen())
        {
            DIAGPRINT "Failed to load port driver\r\n\r\n");
            return 0;
        }
        DIAGPRINT "Port driver loaded successfully\r\n\r\n");
        bufferSizeMax = BUFFER_MAX;
        useRepetitive = 0;
        useInterlace = 0;
        pinMap(1, &sdaControl, &sda, &sdaSet, &sdaReset);
        pinMap(4, &clkControl, &clk, &clkSet, &clkReset);
        pinMap(11, &sdainControl, &sdain, &sdainSet, &sdainReset);
        /* Ensure parallel port is not bidirectional */
        setBit(lptPort, CONTROLPORT, 5, 0);
        /* Ensure pins are set correclty */
        releaseBus();
        a = sendConfig();
        return recieveConfig() && a;
    }
    else if(portType == SERIALPORT)
    {
        char serialPortName[6];
        sprintf(serialPortName, "COM%d",  lptPort+1);
        #ifdef DEBUGON
            dPrStr(serialPortName);
        #endif
        DIAGPRINT "Opening port...\r\nPort Type: Serial Port\r\nPort: COM%d\r\n", lptPort+1);
        serialPortClose();
        //a = serialPortOpen(serialPortName, "57600,N,8,1");
        a = serialPortOpen(serialPortName, "baud=57600 parity=N data=8 stop=1");
        if(a == 1)
        {
            /* Set port timeouts */
            if(!setPortTimeouts(10, 10, 10, 10, 10))
                a = -4;
        }
        if(a != 1)
        {
            DIAGPRINT "Failed to open port\r\n");
            switch (a)
            {
            case -1:
                 DIAGPRINT "Failed to open device\r\n\r\n");
                 break;
            case -2:
                 DIAGPRINT "Failed to configure device\r\n\r\n");
                 break;
            case -3:
                 DIAGPRINT "Failed to configure device\r\n\r\n");
                 break;
            case -4:
                 DIAGPRINT "Failed to set device timeouts\r\n\r\n");
                 break;
            }
            //DIAGPRINT "Error: %d", GetLastError());
            return 0;
        }
        DIAGPRINT "Port opened successfully\r\n\r\n");
        bufferSizeMax = BUFFER_MAX;
        useRepetitive = 0;
        useInterlace = 0;
        a = sendConfig();
        return recieveConfig() && a;
    }
    else
    {
        /* Not yet implemented */
    }
}

/* Reports the trigger level in Volts (note the trigger is on channel 1
 * returns: the trigger level */
double getTriggerLevel()
{
    return triggerLevel;
}

/* Switch modes between using repetitive sampling or not.  Repetitive sampling
 * is sampling a waveform using multiple trigger events to construct a picture
 * of the waveform displayed as if it was sampled at a higher sampling rate
 * using one trigger event.
 * state: 1 indicates use repetitive sampling modes
 * returns: 0 if action wasn't taken, 1 if action was taken */
int setRepetitive(char state)
{
    if(useRepetitive == state)
        return 0;
    useRepetitive = state;
    //if(state)
    //    enableTrigger(1);
    return 1;
}

/* Retuns 1 if repetitive sampling is being used, 2 if repetitive sampling is
 * available but not being used, and 0 if not used at all. */
int getRepetitive()
{
    char frequencyMode;
    frequencyMode = configLoc1 & 0x0f;
    if (frequencyMode == SAMPLE_REP5M || frequencyMode == SAMPLE_REP2M)
        return 1;
    else
        if (useRepetitive)
            return 2;
    return 0;
}

/* Reports the maximum number of samples per channel
 * returns: the maximum number of samples per channel */
int getMaxSamplesPerChannel()
{
    char frequencyMode;
    frequencyMode = configLoc1 & 0x0f;
    switch(frequencyMode)
    {
        case SAMPLE_XYDELAY:
        case SAMPLE_XY417K:
        case SAMPLE_XY250K:
        case SAMPLE_XY192K:
        case SAMPLE_XYINTDELAY:
            return (bufferSizeMax / 2);
            break;
        default:
            return bufferSizeMax;
    }
}

/* Reports the number of samples per channel
 * returns: the number of samples per channel */
int getSamplesPerChannel()
{
    char frequencyMode;
    frequencyMode = configLoc1 & 0x0f;
    switch(frequencyMode)
    {
        case SAMPLE_XYDELAY:
        case SAMPLE_XY417K:
        case SAMPLE_XY250K:
        case SAMPLE_XY192K:
        case SAMPLE_XYINTDELAY:
            return (bufferSize / 2);
            break;
        default:
            return bufferSize;
    }
}

/* Sets the samples per channel
 * spchannel: samples per channel
 * returns: the cooresponding bufferSize */
int setSamplesPerChannel(int spchannel)
{
    char frequencyMode;
    if(spchannel < 10) spchannel = 10;
    frequencyMode = configLoc1 & 0x0f;
    switch(frequencyMode)
    {
        case SAMPLE_XYDELAY:
        case SAMPLE_XY417K:
        case SAMPLE_XY250K:
        case SAMPLE_XY192K:
        case SAMPLE_XYINTDELAY:
            bufferSize = spchannel * 2;
            break;
        default:
            bufferSize = spchannel;
    }
    if(bufferSize > BUFFER_MAX) bufferSize = BUFFER_MAX;
    return bufferSize;
}

/* Adjusts the sample rate either fine or course up or down
 * sampleRateAdj:  ADJ_NOADJ (no adjustment), ADJ_CINCR (course increase),
 *     ADJ_FINCR (fine increase), ADJ_CDECR (course decrease),
 *     ADJ_FDECR (fine decrease)
 * returns: 0
 */
int sampleRateChange(char sampleRateAdj)
{
    char frequencyMode;
    frequencyMode = configLoc1 & 0x0f;
    switch(sampleRateAdj)
    {
    case ADJ_CINCR:
        switch(frequencyMode)
        {
        case SAMPLE_DELAY:
            sampleRate2 = sampleRate2 / 2;
            if(sampleRate2 == 0)
            {
                sampleRate2 = 255;
                if(sampleRate1 == 0)
                    frequencyMode = SAMPLE_250K;
                else
                    sampleRate1--;
            }
            break;
        case SAMPLE_XYDELAY:
            sampleRate2 = sampleRate2 / 2;
            if(sampleRate2 == 0)
            {
                sampleRate2 = 255;
                if(sampleRate1 == 0)
                    frequencyMode = SAMPLE_XY192K;
                else
                    sampleRate1--;
            }
            break;
        case SAMPLE_XY192K:
            frequencyMode = SAMPLE_XY250K;
            break;
        case SAMPLE_XY250K:
            frequencyMode = SAMPLE_XY417K;
            break;
        case SAMPLE_833K:
            frequencyMode = SAMPLE_1M;
            break;
        case SAMPLE_625K:
            frequencyMode = SAMPLE_833K;
            break;
        case SAMPLE_417K:
            frequencyMode = SAMPLE_625K;
            break;
        case SAMPLE_250K:
            frequencyMode = SAMPLE_417K;
            sampleRate1 = 0;
            sampleRate2 = 1;
            break;
        case SAMPLE_1M:
            if(useRepetitive & getEnableTrigger())
                frequencyMode = SAMPLE_REP2M;
            break;
        case SAMPLE_REP2M:
            if(useRepetitive & getEnableTrigger())
                frequencyMode = SAMPLE_REP5M;
            break;
        }
        break;
    case ADJ_FINCR:
        switch(frequencyMode)
        {
        case SAMPLE_DELAY:
            sampleRate2 = sampleRate2 - 1;
            if(sampleRate2 == 0)
            {
                if(sampleRate1 == 0)
                    frequencyMode = SAMPLE_250K;
                else
                    sampleRate1--;
                sampleRate2 = 255;
            }
            break;
        case SAMPLE_XYDELAY:
            sampleRate2 = sampleRate2 - 1;
            if(sampleRate2 == 0)
            {
                sampleRate2 = 255;
                if(sampleRate1 == 0)
                    frequencyMode = SAMPLE_XY192K;
                else
                    sampleRate1--;
            }
            break;
        case SAMPLE_XY192K:
            frequencyMode = SAMPLE_XY250K;
            break;
        case SAMPLE_XY250K:
            frequencyMode = SAMPLE_XY417K;
            break;
        case SAMPLE_833K:
            frequencyMode = SAMPLE_1M;
            break;
        case SAMPLE_625K:
            frequencyMode = SAMPLE_833K;
            break;
        case SAMPLE_417K:
            frequencyMode = SAMPLE_625K;
            break;
        case SAMPLE_250K:
            frequencyMode = SAMPLE_417K;
            sampleRate1 = 0;
            sampleRate2 = 1;
            break;
        case SAMPLE_1M:
            if(useRepetitive & getEnableTrigger())
                frequencyMode = SAMPLE_REP2M;
            break;
        case SAMPLE_REP2M:
            if(useRepetitive & getEnableTrigger())
                frequencyMode = SAMPLE_REP5M;
            break;
        }
        break;
    case ADJ_CDECR:
        switch(frequencyMode)
        {
        case SAMPLE_DELAY:
        case SAMPLE_XYDELAY:
            if (sampleRate2 < 128)
                sampleRate2 *= 2;
            else
            {
                sampleRate2 = 1;
                if(sampleRate1 < 255)
                    sampleRate1++;
            }
            break;
        case SAMPLE_REP5M:
            if(useRepetitive)
                frequencyMode = SAMPLE_REP2M;
            else
                frequencyMode = SAMPLE_1M;
            break;
        case SAMPLE_REP2M:
            frequencyMode = SAMPLE_1M;
            break;
        case SAMPLE_1M:
            frequencyMode = SAMPLE_833K;
            break;
        case SAMPLE_833K:
            frequencyMode = SAMPLE_625K;
            break;
        case SAMPLE_625K:
            frequencyMode = SAMPLE_417K;
            break;
        case SAMPLE_417K:
            frequencyMode = SAMPLE_250K;
            break;
        case SAMPLE_250K:
            frequencyMode = SAMPLE_DELAY;
            sampleRate1 = 0;
            sampleRate2 = 1;
            break;
        case SAMPLE_XY417K:
            frequencyMode = SAMPLE_XY250K;
            break;
        case SAMPLE_XY250K:
            frequencyMode = SAMPLE_XY192K;
            break;
        case SAMPLE_XY192K:
            frequencyMode = SAMPLE_XYDELAY;
            sampleRate1 = 0;
            sampleRate2 = 1;
            break;
        }
        break;
    case ADJ_FDECR:
        switch(frequencyMode)
        {
        case SAMPLE_DELAY:
        case SAMPLE_XYDELAY:
            if (sampleRate2 < 255)
                sampleRate2++;
            else
            {
                sampleRate2 = 1;
                if(sampleRate1 < 255)
                    sampleRate1++;
            }
            break;
        case SAMPLE_XYINTDELAY:
            if (sampleRate2 < 255)
                sampleRate2++;
            else
            {
                sampleRate2 = 0;
                if(sampleRate1 < 255)
                    sampleRate1++;
            }
            break;
        case SAMPLE_REP5M:
            if(useRepetitive)
                frequencyMode = SAMPLE_REP2M;
            else
                frequencyMode = SAMPLE_1M;
            break;
        case SAMPLE_REP2M:
            frequencyMode = SAMPLE_1M;
            break;
        case SAMPLE_1M:
            frequencyMode = SAMPLE_833K;
            break;
        case SAMPLE_833K:
            frequencyMode = SAMPLE_625K;
            break;
        case SAMPLE_625K:
            frequencyMode = SAMPLE_417K;
            break;
        case SAMPLE_417K:
            frequencyMode = SAMPLE_250K;
            break;
        case SAMPLE_250K:
            frequencyMode = SAMPLE_DELAY;
            sampleRate1 = 0;
            sampleRate2 = 1;
            break;
        case SAMPLE_XY417K:
            frequencyMode = SAMPLE_XY250K;
            break;
        case SAMPLE_XY250K:
            frequencyMode = SAMPLE_XY192K;
            break;
        case SAMPLE_XY192K:
            frequencyMode = SAMPLE_XYDELAY;
            sampleRate1 = 0;
            sampleRate2 = 1;
            break;
        }
        break;
    }
    configLoc1 = (configLoc1 & (~0x0f)) | frequencyMode;
    return 0;
}

/* Adjusts the trigger delay either fine or course up or down
 * triggerDelayAdj:  ADJ_NOADJ (no adjustment), ADJ_CINCR (course increase),
 *     ADJ_FINCR (fine increase), ADJ_CDECR (course decrease),
 *     ADJ_FDECR (fine decrease)
 * returns: 0
 */
int triggerDelayChange(char triggerDelayAdj)
{
    double tDelay, tSample;
    tDelay = getTriggerDelay();
    tSample = 1/getSampleRate();
    switch(triggerDelayAdj)
    {
    case ADJ_CDECR:
    case ADJ_FDECR:
        if(tDelay < tSample)
            tSample = tDelay;
        if(setTriggerDelay(tDelay-tSample) == tDelay)
        {
           if(!(triggerDelay1 == 0 && triggerDelay2 == 0 && triggerDelay3 == 0))
           {
               if(triggerDelay3 == 0)
               {
                   if(triggerDelay2 == 0)
                   {
                       triggerDelay1--;
                       triggerDelay2 = 255;
                   }
                   else
                       triggerDelay2--;
                   triggerDelay3 = 255;
               }
               else
                   triggerDelay3--;
           }
        }
        return 0;
    case ADJ_CINCR:
    case ADJ_FINCR:
        if(setTriggerDelay(tDelay+tSample) == tDelay)
        {
            if(!(triggerDelay1 == 255 && triggerDelay2 == 255 && triggerDelay3 == 255))
            {
                if(triggerDelay3 == 255)
                {
                    if(triggerDelay2 == 255)
                    {
                        triggerDelay1++;
                        triggerDelay2 = 0;
                    }
                    else
                        triggerDelay2++;
                    triggerDelay3 = 0;
                }
                else
                    triggerDelay3++;
            }
        }
        return 0;
    }
}

/* Returns the frequency of the sample rate in Hz */
double getSampleRate()
{
    char frequencyMode;
    int theDelay;
    frequencyMode = configLoc1 & 0x0f;
    switch(frequencyMode)
    {
    case SAMPLE_XYINTDELAY:
        theDelay = 8*(sampleRate1*256 + sampleRate2) + 35;
        break;
    case SAMPLE_DELAY:
        theDelay = clockDelay(sampleRate1, sampleRate2) + 14;
        break;
    case SAMPLE_XYDELAY:
        theDelay = clockDelay(sampleRate1, sampleRate2) + 21;
        break;
    case SAMPLE_REP5M:
        theDelay = 1;
        break;
    case SAMPLE_REP2M:
        theDelay = 2;
        break;
    case SAMPLE_1M:
        theDelay = 5;
        break;
    case SAMPLE_833K:
        theDelay = 6;
        break;
    case SAMPLE_625K:
        theDelay = 8;
        break;
    case SAMPLE_417K:
    case SAMPLE_XY417K:
        theDelay = 12;
        break;
    case SAMPLE_XY250K:
    case SAMPLE_250K:
        theDelay = 20;
        break;
    case SAMPLE_XY192K:
        theDelay = 26;
        break;
    }
    if(configLoc1 & (1 << 5))
        return 20.0e6 / 4 / theDelay;
    else
        return 4.0e6 / 4 / theDelay;
}

/* Sets the sample rate to the rate in sRate (Hz)
 * srate: the DESIRED sample rate in Hz
 * returns: the ACTUAL sample rate in Hz */
double setSampleRate(double sRate)
{
    char frequencyMode;
    int theDelay;
    frequencyMode = configLoc1 & 0x0f;
    if(configLoc1 & (1 << 5))
        theDelay = 20e6 / 4 / sRate;
    else
        theDelay = 4e6 / 4 / sRate;
    if(useInterlace)
    {
        if(theDelay <= 12)
            configLoc1 = (configLoc1 & (~0x0f)) | SAMPLE_XY417K;
        else if(theDelay <= 20)
            configLoc1 = (configLoc1 & (~0x0f)) | SAMPLE_XY250K;
        else if(theDelay <= 26)
            configLoc1 = (configLoc1 & (~0x0f)) | SAMPLE_XY192K;
        else if(theDelay <= 200)
        {
            theDelay = theDelay - 21;
            if(theDelay < 12)
                theDelay = 12;
            // if(theDelay > 457730)
            //     theDelay = 457730;
            configLoc1 = (configLoc1 & (~0x0f)) | SAMPLE_XYDELAY;
            setClockDelay(theDelay, &sampleRate1, &sampleRate2);
        }
        else
        {
            theDelay = theDelay - 35;
            if(theDelay > 524280)
                theDelay = 524280;
            configLoc1 = (configLoc1 & (~0x0f)) | SAMPLE_XYINTDELAY;
            theDelay = theDelay /8;
            sampleRate1 = theDelay / 256;
            sampleRate2 = theDelay % 256;
        }
    }
    else
    {
        if(useRepetitive & theDelay <= 2 & getEnableTrigger())
        {
            if(theDelay <= 1)
            {
                configLoc1 = (configLoc1 & (~0x0f)) | SAMPLE_REP5M;
            }
            else if(theDelay <= 2)
            {
                 configLoc1 = (configLoc1 & (~0x0f)) | SAMPLE_REP2M;
            }
        }
        else if(theDelay <= 5)
            configLoc1 = (configLoc1 & (~0x0f)) | SAMPLE_1M;
        else if(theDelay <= 6)
            configLoc1 = (configLoc1 & (~0x0f)) | SAMPLE_833K;
        else if(theDelay <= 8)
            configLoc1 = (configLoc1 & (~0x0f)) | SAMPLE_625K;
        else if(theDelay <= 12)
            configLoc1 = (configLoc1 & (~0x0f)) | SAMPLE_417K;
        else if(theDelay <= 20)
            configLoc1 = (configLoc1 & (~0x0f)) | SAMPLE_250K;
        else
        {
            theDelay = theDelay - 14;
            if(theDelay < 12)
                theDelay = 12;
            if(theDelay > 457730)
                theDelay = 457730;
            configLoc1 = (configLoc1 & (~0x0f)) | SAMPLE_DELAY;
            setClockDelay(theDelay, &sampleRate1, &sampleRate2);
        }
    }
    return getSampleRate();
}

/* Returns the maximum possible sample rate of the device */
double getMaxSampleRate()
{
    if(configLoc1 & (1 << 5))
    {
        if(useInterlace)
            return 5.0e6 / 12;
        if(useRepetitive & getEnableTrigger())
            return 5.0e6;
        return 1.0e6;
    }
    else
        if(useInterlace)
            return 5.0e6 / 12 / 5;
        if(useRepetitive & getEnableTrigger())
            return 5.0e6 / 5;
        return 1.0e6 / 5;
}

/* Returns the delay from the trigger level to beginning of capture in seconds */
double getTriggerDelay()
{
    double i;
    char frequencyMode;
    i =  22 + 3*triggerDelay3 + 770*triggerDelay2 + 197122*triggerDelay1;
    frequencyMode = configLoc1 & 0x0f;
    if(frequencyMode == SAMPLE_REP5M || frequencyMode == SAMPLE_REP2M)
        i = i + 9;
    if(frequencyMode == SAMPLE_XYINTDELAY)
        i = i + 81;
    if(configLoc1 & (1 << 5))
        return (i) * 4 / 20.0e6;
    else
        return (i) * 4 / 4.0e6;
}

/* Adjust the delay associated with the trigger
 * tDelay: the DESIRED trigger delay in seconds
 * returns: the ACTUAL trigger delay in seconds */
double setTriggerDelay(double tDelay)
{
    int theDelay, a;
    char frequencyMode;

    if(configLoc1 & (1 << 5))
        theDelay = (int) (tDelay * 20.0e6 / 4.0);
    else
        theDelay = (int) (tDelay * 4.0e6 / 4.0);
    theDelay = theDelay - 14;
    frequencyMode = configLoc1 & 0x0f;
    if(frequencyMode == SAMPLE_REP5M || frequencyMode == SAMPLE_REP2M)
        theDelay = theDelay - 9;
    if(frequencyMode == SAMPLE_XYINTDELAY)
        theDelay = theDelay - 81;
    if(theDelay < 0)
    {
        triggerDelay1 = 0;
        triggerDelay2 = 0;
        triggerDelay3 = 0;
        return getTriggerDelay();
    }
    if(theDelay > 255*197122 + 255*770 + 255*3)
    {
        triggerDelay1 = 255;
        triggerDelay2 = 255;
        triggerDelay3 = 255;
        return getTriggerDelay();
    }
    a = theDelay / 197122;
    if(a > 255) a = 255;
    triggerDelay1 = a;
    theDelay = theDelay - triggerDelay1 * 197122;
    a = theDelay / 770;
    if(a > 255)
    {
         triggerDelay1++;
         triggerDelay2 = a - 256;
    }
    else
        triggerDelay2 = a;
    theDelay = theDelay - triggerDelay2*770;
    a = theDelay / 3;
    if((theDelay % 3) > 1) a++;
    if(a > 255)
    {
         triggerDelay2++;
         triggerDelay3 = a - 256;
    }
    else
        triggerDelay3 = a;
    return getTriggerDelay();
}

/* Switch to true XY capture mode based on state passed
 * state: 1 indicates true XY mode on, 0 inidcates true XY mode off
 * returns: 0 if action wasn't taken, 1 if action was taken */
int setTrueXY(char state)
{
    double sRate;
    if(!useInterlace)
    {
        if(state)
        {
            sRate = getSampleRate();
            useInterlace = 1;
            setSampleRate(sRate);
            return 1;
        }
    }
    else
    {
        if(!state)
        {
            sRate = getSampleRate();
            useInterlace = 0;
            setSampleRate(sRate);
            return 1;
        }
    }
    return 0;
}

/* Returns 1 if true XY mode is on, 2 if true XY mode is available but not on,
 * otherwise returns 0. */
int getTrueXY()
{
    char freqMode;
    freqMode = configLoc1 & 0x0f;
    switch(freqMode)
    {
    case SAMPLE_XYDELAY:
    case SAMPLE_XY417K:
    case SAMPLE_XY250K:
    case SAMPLE_XY192K:
    case SAMPLE_XYINTDELAY:
        return 1;
    case SAMPLE_417K:
    case SAMPLE_250K:
    case SAMPLE_DELAY:
        return 2;
    }
    return 0;
}

/* Turns the trigger on or off
 * state: 1 turns trigger on, 0 turns trigger off
 * returns: 0  */
int enableTrigger(char state)
{
    if(state)
        configLoc1 = configLoc1 | (1<<6);
    else
    {
        configLoc1 = configLoc1 & (~(1<<6));
        /* Send message to turn off trigger in the oscilloscope */
        int i = 0;
        while((!beginMessage(0xF3, 0xDC)) && (i++ < 10));
    }
    return 0;
}

/* Indicates the status of the trigger
 * Returns 1 if trigger is enabled, otherwise returns 0  */
int getEnableTrigger()
{
    return (configLoc1 & (1 << 6)) >> 6;
}

/* Sets the trigger slope either positive of negative
 * state: 1 denotes positive slope, 0 denotes negative slope
 * returns: 0  */
int triggerSlope(char state)
{
    if(state)
        configLoc1 = configLoc1 | (1<<7);
    else
        configLoc1 = configLoc1 & (~(1<<7));
    return 0;
}

/* Gets the trigger slope.
 * returns: 1 is slope is positive, 0 if slope is negative */
int getTriggerSlope()
{
    return (configLoc1 & (1 << 7)) >> 7;
}

/* Updates channelA and channelB arrays with data from the appropriate
 * channels
 * channelA[]: the channelA array
 * channelB[]: the channelB array
 * Returns: Lower nibble or the lower byte (and with 0x000f) determines if
 *          redraw is required.  The lower nibble will be 2 if redraw required,
 *          1 if successful, 0 if not successful.
 *          The upper nibble of the lower byte (and with 0x00f0) will be 2 if
 *          channel A is DC coupled 1 if channel B is DC coupled, and 3 if both
 *          channels are DC coupled.  Otherwise channels are AC coupled.
 *          The lower nibble of the upper byte (and with 0x0f00) indicates the
 *          channel B multiplier.  The upper nibble of upper byte (and with
 *          0xf000) indicates the channel A multipler.   */
int updateChannels(double chA[], double chB[])
{
    #ifdef DEBUGON
        dPrStr("updateChannels\n");
    #endif
    static unsigned char dataRec[BUFFER_MAX];
    static unsigned char cf[6];
    static char updateState;
    unsigned char sampleConfig, chAOffset, chBOffset, trigOffset;
    char frequencyMode;
    int ma, mb;
    int toRet;
    double bDelay;
    int i, a, b;
    unsigned char dataPoint;
    frequencyMode = configLoc1 & 0x0f;
    if(useInterlace)
    {
        if(updateState == 0)
        {
            cf[0] = configLoc1 | (1<<4);
            cf[1] = sampleRate1;
            cf[2] = sampleRate2;
            cf[3] = triggerDelay1;
            cf[4] = triggerDelay2;
            cf[5] = triggerDelay3;
            if(sendConfig())
            {
                updateState = 1;
                return 1;
            }
        }
        else
        {
            if(cf[0] != (configLoc1 | (1<<4)) || cf[1] != sampleRate1 || cf[2] != sampleRate2 ||
                cf[3] != triggerDelay1 || cf[4] != triggerDelay2 || cf[5] != triggerDelay3)
            {
                updateState = 0;
                return 1;
            }
            if(recieveData(dataRec, &sampleConfig,
               &chAOffset, &chBOffset, &trigOffset))
            {
                ma = getMultiplierA(sampleConfig);
                mb = getMultiplierB(sampleConfig);
                toRet = (sampleConfig & 0x0C) << 2;      /* Record DC modes */
                toRet = toRet | (ma << 12) | ( mb << 8); /* Record multipliers */
                if(configLoc1 & (1 << 5))
                {
                    bDelay = 6.0 / 5.0e6;
                    if((configLoc1 & 0x0f) == SAMPLE_XYINTDELAY) bDelay = 11.0 / 5.0e6;
                }
                else
                {
                    bDelay = 6.0 / 1.0e6;
                    if((configLoc1 & 0x0f) == SAMPLE_XYINTDELAY) bDelay = 11.0 / 1.0e6;
                }
                bDelay = getSampleRate()*bDelay;
                a = 0;
                for(i = 0; i < bufferSize; i+=2)
                {
                    chA[a] = dataValue(0, dataRec[i], chAOffset, (double) ma);
                    if(i == 0)
                        dataPoint = dataRec[i+1] + bDelay*
                            (dataRec[i+1] - dataRec[i+3]) + 0.5;
                    else
                        dataPoint = dataRec[i+1] + bDelay*
                            (dataRec[i-1] - dataRec[i+1]) + 0.5;
                    chB[a] = dataValue(1, dataPoint, chBOffset, (double) mb);
                    a++;
                }
                triggerLevel = dataValue(3, trigOffset, 0, (double) ma);


                cf[0] = configLoc1 | (1<<4);
                cf[1] = sampleRate1;
                cf[2] = sampleRate2;
                cf[3] = triggerDelay1;
                cf[4] = triggerDelay2;
                cf[5] = triggerDelay3;
                if(!(sendConfig()))
                    updateState = 0;

                //updateState = 0;
                return toRet | 2;

            }  /* if recieve data */
        }    /* if updateState */
    } /* if frequencyMode */
    else
    {
        if(updateState == 0)
        {
            cf[0] = configLoc1 | (1<<4);
            cf[1] = sampleRate1;
            cf[2] = sampleRate2;
            cf[3] = triggerDelay1;
            cf[4] = triggerDelay2;
            cf[5] = triggerDelay3;
            #ifdef DEBUGON
                dPrStr("UpdateState=0\n");
            #endif
            configLoc1 = configLoc1 & (~(1<<4));
            if(sendConfig())
            {
                updateState = 1;
                return 1;
            }
        }
        else if(updateState == 1)
        {
            #ifdef DEBUGON
                dPrStr("UpdateState=1\n");
            #endif
            if(recieveData(dataRec, &sampleConfig,
                &chAOffset, &chBOffset, &trigOffset))
            {
                ma = getMultiplierA(sampleConfig);
                updateChannelHelper(chA, dataRec, chAOffset, (double) ma);
                updateState = 2;
                configLoc1 = configLoc1 | (1<<4);
                if(sendConfig())
                    updateState = 3;
                return 1;
            }
        }
        else if(updateState == 2)
        {
            #ifdef DEBUGON
                 dPrStr("UpdateState=2\n");
            #endif
            configLoc1 = configLoc1 | (1<<4);
            if(sendConfig())
            {
                updateState = 3;
                return 1;
            }
        }
        else
        {
            #ifdef DEBUGON
                dPrStr("UpdateState=3\n");
            #endif
            if(cf[0] != (configLoc1 | (1<<4)) || cf[1] != sampleRate1 || cf[2] != sampleRate2 ||
                cf[3] != triggerDelay1 || cf[4] != triggerDelay2 || cf[5] != triggerDelay3)
            {
                updateState = 0;
                return 1;
            }

            if(recieveData(dataRec, &sampleConfig,
                &chAOffset, &chBOffset, &trigOffset))
            {
                toRet = (sampleConfig & 0x0C) << 2;   /* Record DC modes */
                ma = getMultiplierA(sampleConfig);
                mb = getMultiplierB(sampleConfig);
                toRet = toRet | (ma << 12) | ( mb << 8); /* Record multipliers */
                updateChannelHelper(chB, dataRec, chBOffset, (double) mb);
                triggerLevel = dataValue(3, trigOffset, 0, ma);
                updateState = 0;

                cf[0] = configLoc1 | (1<<4);
                cf[1] = sampleRate1;
                cf[2] = sampleRate2;
                cf[3] = triggerDelay1;
                cf[4] = triggerDelay2;
                cf[5] = triggerDelay3;
                configLoc1 = configLoc1 & (~(1<<4));
                if(sendConfig())
                    updateState = 1;
                return toRet | 2;

            }  /* if recieveData */
        } /* if updateState */
    } /* else frequencyMode */
    return 0;
}


