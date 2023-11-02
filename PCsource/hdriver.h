/* ==============================================================================
 * Author:  Jonathan Weaver, jonw0224@aim.com
 * E-mail Contact: jonw0224@aim.com
 * Description:  Hardware interface to the oscilloscope
 * Version: 2.18
 * Date: 1/17/2014
 * Filename:  hdriver.c, hdriver.h
 *
 * Versions History:
 *      9/6/2006 - Created file, configuration routines and background routines
 *      1/30/2013 - updated headers for hDriverSetConfig, hDriverGetConfig,
 *                  updateChannels
 *      1/17/2014 - Modified code for trigger levels to be reported on both
 *                  channels.  Changed definition of getTriggerLevel
 *
 * Copyright (C) 2006-2014 Jonathan Weaver
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

#define BUFFER_MAX (256)

#define PARALLELPORT 1
#define SERIALPORT 2
#define USBPORT 3

/* Hardware Models */
#define PPMSCOPE    0
#define DSOSCOPE    1

/* Adjustments */
#define ADJ_NOADJ 0
#define ADJ_CINCR 1
#define ADJ_FINCR 2
#define ADJ_CDECR 3
#define ADJ_FDECR 4

/* Sample rates */
#define SAMPLE_1M           0
#define SAMPLE_833K         1
#define SAMPLE_625K         2
#define SAMPLE_417K         3
#define SAMPLE_250K         4
#define SAMPLE_DELAY        5
#define SAMPLE_REP5M        6
#define SAMPLE_REP2M        7
#define SAMPLE_XY417K       8
#define SAMPLE_XY250K       9
#define SAMPLE_XY192K       10
#define SAMPLE_XYDELAY      11
#define SAMPLE_XYINTDELAY   12
#define SAMPLE_XY500K       13

/* Diagnostic String for use by the hardware testing feature */
#define DIAGNOSTIC_UPPERBOUND 10000
char diagnostic[DIAGNOSTIC_UPPERBOUND];
/* Pointer for the end of the diagnostic string */
char *dPtr;
/* Macro definition for diagnostic printing */
#define DIAGPRINT if(dPtr<diagnostic+DIAGNOSTIC_UPPERBOUND-100) dPtr+=sprintf(dPtr,

/* Sets the configuration for the hDriver.  Configuration must be set before
 * hDriver is initialized.
 * pType: portType (PARALLELPORT, SERIALPORT, USBPORT)
 * portNum: Indicates which port to use
 * tickCount: delay for clocking waveforms
 * conf[]: eight character array indicating configuration:  configLoc1,
 *         triggerDelay0, triggerDelay1, triggerDelay2, triggerDelay3,
 *         sampleRate0, sampleRate1, sampleRate2
 * buffSz: buffer size per channel
 * returns: 1 if successful, 0 otherwise */
int hDriverSetConfig(int pType, int portNum, int tickCount, char conf[], int buffSz);

/* Gets the configuration from the hDriver after it is set.
 * pType: portType (PARALLELPORT, SERIALPORT, USBPORT)
 * portNum: Indicates which port to use
 * tickCount: delay for clocking waveforms
 * conf[]: eight character array indicating configuration:  configLoc1,
 *         triggerDelay0, triggerDelay1, triggerDelay2, triggerDelay3,
 *         sampleRate0, sampleRate1, sampleRate2
 * buffSz: buffer size per channel
 * returns: 1 if successful, 0 otherwise */
int hDriverGetConfig(int* pType, int* portNum, int* tickCount, char conf[], int* buffSz);

/* Initialize the hDriver by opening the ports, setting pins, etc.
 * returns: 1 if successful, 0 otherwise */
int hDriverInitialize();

/* Reports the trigger level in Volts (note the trigger is on channel 1)
 * chan: Channel to report trigger level on.  1 = Ch1.  2 = Ch2.  Any other number means use the trigger channel.
 * returns: the trigger level */
double getTriggerLevel(char chan);

/* Reports the maximum number of samples per channel
 * returns: the maximum number of samples per channel */
int getMaxSamplesPerChannel();

/* Reports the number of samples per channel
 * returns: the number of samples per channel */
int getSamplesPerChannel();

/* Sets the samples per channel
 * spchannel: samples per channel
 * returns: the cooresponding bufferSize */
int setSamplesPerChannel(int spchannel);

/* Adjusts the sample rate either fine or course up or down
 * sampleRateAdj:  ADJ_NOADJ (no adjustment), ADJ_CINCR (course increase),
 *     ADJ_FINCR (fine increase), ADJ_CDECR (course decrease),
 *     ADJ_FDECR (fine decrease)
 * returns: 1 if limits are hit.
 */
int sampleRateChange(char sampleRateAdj);

/* Adjusts the trigger delay either fine or course up or down
 * triggerDelayAdj:  ADJ_NOADJ (no adjustment), ADJ_CINCR (course increase),
 *     ADJ_FINCR (fine increase), ADJ_CDECR (course decrease),
 *     ADJ_FDECR (fine decrease)
 * returns: 0
 */
int triggerDelayChange(char triggerDelayAdj);

/* Returns the frequency of the sample rate in Hz */
double getSampleRate();

/* Sets the sample rate to the rate in sRate (Hz)
 * srate: the DESIRED sample rate in Hz
 * returns: the ACTUAL sample rate in Hz */
double setSampleRate(double sRate);

/* Returns the maximum possible sample rate of the device */
double getMaxSampleRate();

/* Returns the delay from the trigger level to beginning of capture in seconds */
double getTriggerDelay();

/* Adjust the delay associated with the trigger
 * tDelay: the DESIRED trigger delay in seconds
 * returns: the ACTUAL trigger delay in seconds */
double setTriggerDelay(double tDelay);

/* Switch to true XY capture mode based on state passed
 * state: 1 indicates true XY mode on, 0 inidcates true XY mode off
 * returns: 0 if action wasn't taken, 1 if action was taken */
int setTrueXY(char state);

/* Returns 1 if true XY mode is on otherwise returns 0. */
int getTrueXY();

/* Switch modes between using repetitive sampling or not.  Repetitive sampling
 * is sampling a waveform using multiple trigger events to construct a picture
 * of the waveform displayed as if it was sampled at a higher sampling rate
 * using one trigger event.
 * state: 1 indicates use repetitive sampling modes
 * returns: 0 if action wasn't taken, 1 if action was taken */
int setRepetitive(char state);

/* Retuns 1 if repetitive sampling is being used, 2 if repetitive sampling is
 * available but not being used, and 0 if not used at all. */
int getRepetitive();

/* Turns the trigger on or off
 * state: 1 turns trigger on, 0 turns trigger off
 * returns: 0  */
int enableTrigger(char state);

/* Indicates the status of the trigger
 * Returns 1 if trigger is enabled, otherwise returns 0  */
int getEnableTrigger();

/* Sets the trigger slope either positive of negative
 * state: 1 denotes positive slope, 0 denotes negative slope
 * returns: 0  */
int triggerSlope(char state);

/* Gets the trigger slope.
 * returns: 1 is slope is positive, 0 if slope is negative */
int getTriggerSlope();

/* Gets the trigger Channel
 * returns: 1 for channel 1, 2 for channel 2
 */
int getTriggerChannel();

/* Returns the delay in channel data after the triggerdelay.
 * Usually this value is one, but in some modes, particularly XY mode, the
 * second channel is sampled sometime after the first channel.  The post
 * trigger delay of channel 1 is 0, but channel 2 is 1.2 uSec for most XY modes.
 * Use this function to get the post trigger delay of any channel in any mode.
 * ch: the channel to get the post trigger delay for.
 * returns: the post trigger delay in seconds.
 */
double getPostTriggerDelay(int ch);

/* Sets the high resolution mode
 * hr: high resolution mode.  1 = high resolution mode.  0 = regular resolution mode.
 * returns: 0 */
int setHighResolution(char hr);

/* Gets the high resolution mode
 * returns: 0 = regular resolution.  Non-zero = high resolution mode (usually 1) */
char getHighResolution();

/* Updates channelA and channelB arrays with data from the appropriate
 * channels
 * channelA[]: the channelA array
 * channelB[]: the channelB array
 * Returns: Lower nibble or the lower byte (and with 0x000f) determines if
 *          redraw is required.  The lower nibble will be 2 if redraw required,
 *          1 if successful, 0 if not successful.
 *          The upper nibble of the lower byte (and with 0x00f0) indicates the
 *          attenuation and coupling.  The bit pattern in this byte is
 *          bit7 = 1 if Ch1 is attenuated by 10 (0 = no attenuation)
 *          bit6 = 1 if Ch2 is attenuated by 10 (0 = no attenuation)
 *          bit5 = 1 if Ch1 is AC coupled (0 = DC coupled)
 *          bit4 = 1 if Ch2 is AC coupled (0 = DC coupled)
 *          The lower nibble of the upper byte (and with 0x0f00) indicates the
 *          channel B multiplier.  The upper nibble of upper byte (and with
 *          0xf000) indicates the channel A multipler.   */
int updateChannels(double channelA[], double channelB[]);

