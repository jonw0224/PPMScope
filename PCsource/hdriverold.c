/* ==============================================================================
 * Author:  Jonathan Weaver, jonw0224@aim.net
 * E-mail Contact: jonw0224@aim.net
 * Description:  Hardware interface to the oscilloscope
 * Version: 1.0
 * Date: 10/3/2006
 * Filename:  hdriver.c, hdriver.h
 *
 * Versions History:  
 *      9/6/2006 - Created file, configuration routines and background routines
 *
 * Copyright (C) 2006 Jonathan Weaver
 * 
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 2 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 * 
 * You should have received a copy of the GNU General Public License along with
 * this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 * 
 * ============================================================================== 
 */
 
#include "par_i2c.h"
#include "hdriver.h"

#define NOHARDWARE

#include "debug.h"

#ifdef NOHARDWARE
#include <stdlib.h>
#include <time.h>
#include <math.h>
#endif

int bufferSizeMax, bufferSize;
unsigned char configLoc1, triggerDelay1, triggerDelay2, sampleRate1, sampleRate2;
int portType;
double triggerLevel;

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
        256.0*24.0/m;
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

/* Send a message to start and recieve acknowlede and the confirming byte
 * command: the command byte to send
 * reply: the expected reply byte
 * return: 1 if sucessful, 0 if not */
int beginMessage(short command, short reply)
{
    int count, countb;
    count = 0;
    do
    {
        releaseBus();
        countb = 0;
        do
            sendStart();
        while ((!sendByte(command)) && (++countb < 10));
     } while ((recieveByte(1) != reply) && (++count < 10));
    if(count == 10)
        return 0;
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
    char bufferSizeML, bufferSizeMH;
    if (beginMessage(0xF9, 0xDD))
    {
        bufferSizeMH = recieveByte(1);
        bufferSizeML = recieveByte(1);
        bufferSizeMax = bufferSizeMH << 8 + bufferSizeML; 
        configLoc1 = recieveByte(1);
        triggerDelay1 = recieveByte(1);
        triggerDelay2 = recieveByte(1);
        sampleRate1 = recieveByte(1);
        sampleRate2 = recieveByte(0);
        sendStop();
        return 1;
    }
    sendStop();
    return 0;
#endif
}

/* Sends configuration settings to the oscilloscope
 * returns: 1 if the configuration was accepted by the device, otherwise 0 */
int sendConfig()
{
#ifdef NOHARDWARE
    static char a;
    if(a)
        a = 0;
    else
        a = 1;
    return a;       
#else
    int a;

    if (beginMessage(0xFA, 0xDE))
    {
        sendByte(configLoc1);
        sendByte(triggerDelay1);
        sendByte(triggerDelay2);
        sendByte(sampleRate1);
        a = sendByte(sampleRate2);
        sendStop();
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
        if((configLoc1 & 0x0f) == SAMPLE_XYDELAY)
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
                        dataRec[i] = (int) (32.0*cos(2*PI*2000*(t/2-b)) + 127.5);
                    else
                        dataRec[i] = (int) (32.0*cos(2*PI*2000*(t/2-b)+PI) + 127.5);
                else
                    dataRec[i] = (int) (32.0*cos(2*PI*2000*(t/2-nb)) + 127.5);                                        
            } /* if odd */
            else
            {
                /* channel b = 4*sin(2*pi*5000*t) */
                if(configLoc1 & (1<<6))  /* trigger enabled */
                    if(configLoc1 & (1<<7)) /* trigger positive */
                        dataRec[i] = (int) (64.0*cos(2*PI*10000*(t/2 - 1.2e-6 - b)) + 127.5);
                    else
                        dataRec[i] = (int) (64.0*cos(2*PI*10000*(t/2 - 1.2e-6 - b)+PI) + 127.5);
                else
                    dataRec[i] = (int) (64.0*cos(2*PI*10000*(t/2 - 1.2e-6 - nb)) + 127.5);                                                        
            } /* if even */                    
        } /* sampleXY */
        else
        {
            if(configLoc1 & (1<<4)) /* channel b = 4*sin(2*PI*5000*t) */
                if(configLoc1 & (1<<6))  /* trigger enabled */
                    if(configLoc1 & (1<<7)) /* trigger positive */
                        dataRec[i] = (int) (64.0*cos(2*PI*10000*(t-b)) + 127.5);
                    else
                        dataRec[i] = (int) (64.0*cos(2*PI*10000*(t-b)+PI) + 127.5);
                else
                    dataRec[i] = (int) (64.0*cos(2*PI*10000*(t-nb)) + 127.5);                                                        
            else /* channel a = 2*cos(2*PI*5000*t) */
                if(configLoc1 & (1<<6))  /* trigger enabled */
                    if(configLoc1 & (1<<7)) /* trigger positive */
                        dataRec[i] = (int) (32.0*cos(2*PI*2000*(t-b)) + 127.5);
                    else
                        dataRec[i] = (int) (32.0*cos(2*PI*2000*(t-b)+PI) + 127.5);
                else
                    dataRec[i] = (int) (32.0*cos(2*PI*2000*(t-nb)) + 127.5);                                                                            
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
    
    if (beginMessage(0xF8, 0xDC))
    {
        for(count = 0; count < bufferSize-1; count++)
            dataRec[count] = recieveByte(1);
        dataRec[bufferSize-1] = recieveByte(0);
        *sampleConfig = recieveByte(1);
        *chAOffset = recieveByte(1);
        *chBOffset = recieveByte(1);
        *trigOffset = recieveByte(0);

/*        dPrStr("Data");
        for(count = 0; count < bufferSize; count++)
        {
            dPrInt(dataRec[count]);
            dPrStr("\n");
        }
        dPrStr("End Data \n\n");
*/
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
 * conf[]: five character array indicating configuration:  configLoc1, 
 *         triggerDelay1, triggerDelay2, sampleRate1, sampleRate2
 * buffSz: buffer size per channel
 * returns: 1 if successful, 0 otherwise */
int hDriverSetConfig(int pType, int portNum, int tickCount, char conf[], int buffSz)
{
    portType = pType;
    if(portType == PARALLELPORT)
    {
        lptPort = portNum;
        wTime = tickCount;
        configLoc1 = conf[0];
        triggerDelay1 = conf[1];
        triggerDelay2 = conf[2];
        sampleRate1 = conf[3];
        sampleRate2 = conf[4];
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
 * conf[]: five character array indicating configuration:  configLoc1, 
 *         triggerDelay1, triggerDelay2, sampleRate1, sampleRate2
 * buffSz: buffer size per channel 
 * returns: 1 if successful, 0 otherwise */
int hDriverGetConfig(int* pType, int* portNum, int* tickCount, char conf[], int* buffSz)
{
    if(portType == PARALLELPORT)
    {
        *pType = portType;
        *portNum = lptPort;
        *tickCount = wTime;
        conf[0] = configLoc1;
        conf[1] = triggerDelay1;
        conf[2] = triggerDelay2;
        conf[3] = sampleRate1;
        conf[4] = sampleRate2;
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
        
    if(portType == PARALLELPORT)
    {
        parallelPortClose();
        
        /* Initialize */
        if(!parallelPortOpen())
        {
            return 0;
        }
        bufferSizeMax = BUFFER_MAX;
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
    else
    {
        /* Not yet implemented */
        return 0;
    }        
}

/* Reports the trigger level in Volts (note the trigger is on channel 1
 * returns: the trigger level */
double getTriggerLevel()
{
    return triggerLevel;
}

/* Reports the maximum number of samples per channel
 * returns: the maximum number of samples per channel */
int getMaxSamplesPerChannel()
{
    char frequencyMode;
    frequencyMode = configLoc1 & 0x0f;
    if(frequencyMode == SAMPLE_XYDELAY)
        return (bufferSizeMax / 2);
    else
        return bufferSizeMax;
}    
    
/* Reports the number of samples per channel
 * returns: the number of samples per channel */
int getSamplesPerChannel()
{
    char frequencyMode;
    frequencyMode = configLoc1 & 0x0f;
    if(frequencyMode == SAMPLE_XYDELAY)
    {
        return (bufferSize / 2);
    }
    else
        return bufferSize;
}


/* Sets the samples per channel
 * spchannel: samples per channel
 * returns: the cooresponding bufferSize */
int setSamplesPerChannel(int spchannel)
{
    char frequencyMode;
    if(spchannel < 10) spchannel = 10;
    frequencyMode = configLoc1 & 0x0f;
    if(frequencyMode == SAMPLE_XYDELAY)
        bufferSize = spchannel * 2;
    else
        bufferSize = spchannel;
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
                    sampleRate2 = 1;
                else
                    sampleRate1--;
            }    
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
                    sampleRate2 = 1;
                else
                    sampleRate1--;
            }    
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
    switch(triggerDelayAdj)
    {
    case ADJ_CDECR:
        triggerDelay2 /= 2;
        if(triggerDelay2 == 0)
            if(triggerDelay1 > 0)
            {
                triggerDelay2 = 255;
                triggerDelay1--;
            }
            else
                triggerDelay2 = 1;
        return 0;
    case ADJ_FDECR:
        triggerDelay2--;
        if(triggerDelay2 == 0)
        {
            triggerDelay2 = 255;
            if(triggerDelay1 == 0)
                triggerDelay2 = 1;
            else
                triggerDelay1--;
        }            
        return 0;
    case ADJ_CINCR:
        if(triggerDelay2 < 128)
            triggerDelay2 *= 2;
        else
        {
            if(triggerDelay1 < 255)
            {
                triggerDelay2 = 1;
                triggerDelay1++;
            }
        }    
        return 0;
    case ADJ_FINCR:
        if(triggerDelay2 < 255)
            triggerDelay2++;
        else if(triggerDelay1 < 255)
        {
            triggerDelay2 = 1;
            triggerDelay1++;
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
    case SAMPLE_DELAY:
        theDelay = clockDelay(sampleRate1, sampleRate2) + 14;
        break;
    case SAMPLE_XYDELAY:
        theDelay = clockDelay(sampleRate1, sampleRate2) + 21;
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
        theDelay = 12;
        break;
    case SAMPLE_250K:
        theDelay = 20;
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
    if(frequencyMode == SAMPLE_XYDELAY)
    {
        if(theDelay < 33) 
                theDelay = 33;
        setClockDelay(theDelay - 21, &sampleRate1, &sampleRate2);
    }
    else
    {
        if(theDelay <= 5)
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
        return 1.0e6;
    else
        return 200000.0;
}    

/* Returns the delay from the trigger level to beginning of capture in seconds */
double getTriggerDelay()
{
    if(configLoc1 & (1 << 5))
        return (clockDelay(triggerDelay1, triggerDelay2) + 22) * 4 / 20.0e6;
    else
        return (clockDelay(triggerDelay1, triggerDelay2) + 22) * 4 / 4.0e6;
}

/* Adjust the delay associated with the trigger
 * tDelay: the DESIRED trigger delay in seconds
 * returns: the ACTUAL trigger delay in seconds */
double setTriggerDelay(double tDelay)
{
    int theDelay;
    if(configLoc1 & (1 << 5))
        theDelay = tDelay * 20e6 / 4;
    else
        theDelay = tDelay * 4e6 / 4;
    theDelay = theDelay - 22;
    if(theDelay < 12) 
        theDelay = 12;
    if(theDelay > 457730)
        theDelay = 457730;
    setClockDelay(theDelay, &triggerDelay1, &triggerDelay2);
    return getTriggerDelay();
}

/* Switch to true XY capture mode based on state passed
 * state: 1 indicates true XY mode on, 0 inidcates true XY mode off
 * returns: 0 if action wasn't taken, 1 if action was taken */
int setTrueXY(char state)
{
    if((configLoc1 & 0x0f) == SAMPLE_DELAY)
        if(state)
        {
            configLoc1 = (configLoc1 & (~0x0f)) | SAMPLE_XYDELAY;
            sampleRate2--;
            return 1;
        }
    if((configLoc1 & 0x0f) == SAMPLE_XYDELAY)
        if(!state)
        {
            configLoc1 = (configLoc1 & (~0x0f)) | SAMPLE_DELAY;
            sampleRate2++;
            return 1;
        }
    return 0;       
}            

/* Returns 1 if true XY mode is on, 2 if true XY mode is available but not on,
 * otherwise returns 0. */
int getTrueXY()
{
    if((configLoc1 & 0x0f) == SAMPLE_XYDELAY)
        return 1;
    if((configLoc1 & 0x0f) == SAMPLE_DELAY)
        if(!(sampleRate1==0 && sampleRate2 == 1))
            return 2;
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
        configLoc1 = configLoc1 & (~(1<<6));
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
    static unsigned char dataRec[BUFFER_MAX];
    static char updateState;
    unsigned char sampleConfig, chAOffset, chBOffset, trigOffset;
    char frequencyMode;
    int ma, mb, toRet;
    double bDelay;
    int i, a;
    unsigned char dataPoint;
    frequencyMode = configLoc1 & 0x0f;
    if(frequencyMode == SAMPLE_XYDELAY)
    {
        if(updateState == 0)
        {
            if(sendConfig())
            {
                updateState = 1;
                return 1;
            }
        }
        else
        {
            if(recieveData(dataRec, &sampleConfig, 
               &chAOffset, &chBOffset, &trigOffset))
            {
                ma = getMultiplierA(sampleConfig);
                mb = getMultiplierB(sampleConfig);
                toRet = (sampleConfig & 0x0C) << 2;   /* Record DC modes */
                toRet = toRet | (ma << 12) | ( mb << 8); /* Record multipliers */
                if(configLoc1 & (1 << 5))
                    bDelay = 6.0 / 5.0e6;
                else
                    bDelay = 6.0 / 1.0e6;
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
                triggerLevel = dataValue(3, trigOffset, 0, ma);
                updateState = 0;
                return toRet | 2;
            }  /* if recieve data */
        }    /* if updateState */
    } /* if frequencyMode */
    else
    {
        if(updateState == 0)
        {
            configLoc1 = configLoc1 & (~(1<<4));
            if(sendConfig())
            {
                updateState = 1;
                return 1;
            }
        }
        else if(updateState == 1)    
        {
            if(recieveData(dataRec, &sampleConfig, 
                &chAOffset, &chBOffset, &trigOffset))
            {
                ma = getMultiplierA(sampleConfig);
                for(i = 0; i < bufferSize; i++)
                    chA[i] = dataValue(0, dataRec[i], chAOffset, (double) ma);
                updateState = 2;
                return 1;
            }
        }
        else if(updateState == 2)
        {        
            configLoc1 = configLoc1 | (1<<4);
            if(sendConfig())
            {
                updateState = 3;
                return 1;
            }
        }
        else    
        {                    
            if(recieveData(dataRec, &sampleConfig, 
                &chAOffset, &chBOffset, &trigOffset))
            {
                toRet = (sampleConfig & 0x0C) << 2;   /* Record DC modes */
                ma = getMultiplierA(sampleConfig);
                mb = getMultiplierB(sampleConfig);
                toRet = toRet | (ma << 12) | ( mb << 8); /* Record multipliers */
                for(i = 0; i < bufferSize; i++)
                    chB[i] = dataValue(0, dataRec[i], chBOffset, (double) mb);
                triggerLevel = dataValue(3, trigOffset, 0, ma);
                updateState = 0;
                return toRet | 2;
            }  /* if recieveData */ 
        } /* if updateState */    
    } /* else frequencyMode */
    return 0;    
}

