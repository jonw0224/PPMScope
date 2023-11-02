/* ==============================================================================
 * Author:  Jonathan Weaver, jonw0224@aim.com
 * E-mail Contact: jonw0224@aim.com
 * Description:  Header file for oscilloscope graphs.
 * Version: 2.20
 * Date: 6/20/2014
 * Filename:  oscDisp.c, oscDisp.h
 *
 * Versions History:
 *      2.01 - 9/20/2006 - Created file
 *      2.14 - 1/31/2011 - Modifications for colors.
 *		2.14 - 3/17/2011 - Added channel weight support
 *      2.151  7/20/2012 - Modified for continous Time Per Division
 *      2.20 - 6/20/2014 - Added a range of persistence
 *
 * Copyright (C) 2006 - 2014 Jonathan Weaver
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

#define DIVISIONSX 10
#define DIVISIONSY 8
#define SPECTDIVY   5
#define SPECTPHDIVY 4

#define MODE_STOP 1
#define MODE_RUN 2
#define MODE_HOLD 4
#define MODE_XY 8
#define MODE_FREQMAGLOG 16
#define MODE_CHAENABLED 32
#define MODE_CHBENABLED 64
#define MODE_CHCENABLED 128
#define MODE_CHDENABLED 256

#define RECONST_TRIANGLE 0
#define RECONST_SINC 1
#define RECONST_SQUARE 2
#define RECONST_POINT 3
#define RECONST_BEZIER  4

#define SCOPE_SCREEN        0
#define SCOPE_FREQMAG       1
#define SCOPE_FREQPHASE     2
#define SCOPE_MEASUREMENTS  3

#define CM_SETSCREENTYPE    9001
#define CM_GETSCREENTYPE    9002

#define GETCOLORBG          1
#define GETCOLORGR          2
#define GETCOLORCHA         3
#define GETCOLORCHB         4
#define GETCOLORCUR1        5
#define GETCOLORCUR2        6
#define GETCOLORTRIG        7
#define GETCOLORCHC         8
#define GETCOLORCHD         9

#define CHANNELA            0
#define CHANNELB            1
#define CHANNELC            2
#define CHANNELD            3
#define WEIGHTA             1
#define WEIGHTB             1
#define WEIGHTC             1
#define WEIGHTD             1

/* Persistence */
#define NOPERSISTENCE   255

BOOL CALLBACK oscDispProc (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam);

/* Returns an oscilloscope display color
 * whichColor: 1 = Background Color, 2 = Grid Color, 3 = Channel A Color, 4 = Channel B Color, 5 = Cursor 1 Color, 6 = Cursor 2 Color, 7 = Trigger Color
 * return: the color as an int, or -1 if whichColor is invalid */
int oscGetColor(int whichColor);

/* Sets the oscilloscope display colors
 * scrbgcolor: Screen Background Color
 * scrfgcolor: Grid Color
 * channelAColor: Channel A Color
 * channelBColor: Channel B Color
 * channelCColor: Channel C Color
 * channelDColor: Channel D Color
 * cur1color: Cursor 1 color
 * cur2color: Cursor 2 color
 * triggerColor: Trigger color
 * returns: 1*/
int oscSetColors(int scrbgcolor, int scrfgcolor, int channelAColor, int channelBColor, int channelCColor, int channelDColor, int cur1color, int cur2color, int triggerColor);

/* Gets the display configuration
 * windowMode:  three character array representing the window modes
 *     (SCOPE_SCREEN, SCOPE_FREQMAG, SCOPE_FREQPHASE)
 * returns: 1 */
int oscDispGetConfig(char windowMode[]);

/* Sets the display configuration
 * windowMode:  three character array representing the window modes
 *     (SCOPE_SCREEN, SCOPE_FREQMAG, SCOPE_FREQPHASE)
 * returns: 1 */
int oscDispSetConfig(char windowMode[]);

/* Clears and redraws all the scope windows
 * invld: if 1 then invalidates the channel data and isn't drawn.  If 0 then channel data is drawn.
 * returns: 0 */
int refreshScopeWindows(char invld);

/* Sets the channel to enabled or disabled
 * ch: 0 is channel A, 1 is channel B, 2 is channel C, 3 is channel D
 * en: 1 is enabled, 0 is disabled
 * returns: 0 */
int setChannelEnabled(int ch, int en);

/* Gets the enabled status of the channel
 * ch: 0 is channel A, 1 is channel B, 2 is channel C, 3 is channel D
 * returns: 1 is enabled, 0 is disabled */
int getChannelEnabled(int ch);

/* Returns the time per division */
double getTimePerDivision();

/* Sets the time per division */
int setTimePerDivision(double tpd);

/* Gets the weight for drawing the channels
 * channel: 0 for channel A, 1 for channel B, 2 for channel C, and 3 for channel D
 * returns: weight in pixels */
int getPenWeight(int channel);

/* Sets the weight for drawing the channels
 * channel: 0 for channel A, 1 for channel B, 2 for channel C, and 3 for channel D
 * w: weight to use in pixels
 * returns: 0  */
int setPenWeight(int channel, int w);

/* Set the persistence
 * p: a number between 0 and 255 representing the persistence.  Numbers below 0 will set persistence to 0.  Numbers above 255 will set persistence to 255.
 */
int oscSetPersistence(int p);

/* Get the persistence setting
 * returns: a number between 0 and 255 representing the persistence.  0 is full persistence, 255 is no persistence
 */
int oscGetPersistence();

