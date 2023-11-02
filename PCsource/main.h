/* ==============================================================================
 * Author:  Jonathan Weaver, jonw0224@aim.com
 * E-mail Contact: jonw0224@aim.com
 * Description:  Main program controller, event handler.
 * Version: 2.15
 * Date: 7/20/2012
 * Filename:  main.c, main.h
 *
 * Versions History:
 *      2.01 - 7/27/2006 - Created files
 *      2.01 - 8/6/2006 - Added about dialog
 *      2.01 - 2/11/2009 - Modified for Panel changes, using Updown controls
 *                         and windows themes.
 *      2.14 - 4/30/2009 - Changed for measurements
 *      2.14 - 1/31/2011 - Modifications for colors
 *      2.15 - 7/20/2012 - Modified for continous Time Per Division
 *      2.19 - 3/10/2014 - Modified to handle panelwidth for any screen dpi setting.
 *
 * Copyright (C) 2006 - 2012 Jonathan Weaver
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


#define WINVER 0x0500
#define _WIN32_IE 0x0500

#include <windows.h>
#include <commctrl.h>
#include "hdriver.h"
#include "oscdisp.h"
#include "panel.h"
#include "fourier.h"
#include "ini_io.h"
#include "func.h"
#include "settings.h"

/* Application Commands */
/* Menu items */
#define CM_FILE_SAVEWAVE                    9001
#define CM_FILE_SAVESET                     9002
#define CM_FILE_OPENSET                     9003
#define CM_FILE_LOGSETTINGS                 9004
#define CM_FILE_EXIT	                    9005
#define CM_CONFIG_HARDWARE                  9011
#define CM_CONFIG_HARDTEST                  9012
#define CM_CONFIG_CALIBRATE                 9013
#define CM_CONFIG_SAMPLE_INTERLACED         9014
#define CM_CONFIG_SAMPLE_TIMEEQUIV          9015
#define CM_CONFIG_TRIGGER_POS               9016
#define CM_CONFIG_TRIGGER_NEG               9017
#define CM_CONFIG_TRIGGER_OFF               9018
#define CM_CONFIG_WAVEFORM_REFRESH_RATE     9019
#define CM_WAVEFORM_RECON_SPLINE            9020
#define CM_WAVEFORM_RECON_TRI               9021
#define CM_WAVEFORM_RECON_SQU               9022
#define CM_WAVEFORM_RECON_PT                9023
#define CM_WAVEFORM_RECON_SINC              9024
#define CM_WAVEFORM_VT                      9025
#define CM_WAVEFORM_XY                      9026
#define CM_WAVEFORM_LIN                     9027
#define CM_WAVEFORM_LOG                     9028
#define CM_HELP_HELP                        9031
#define CM_HELP_ABOUT                       9032
#define CM_WAVEFORM_HIGH_RES                  9033

/* Toolbar buttons */
#define CM_SAVEWAVEFORM     CM_FILE_SAVEWAVE
#define CM_SAVESETUP        CM_FILE_SAVESET
#define CM_OPENSETUP        CM_FILE_OPENSET
#define CM_LOGGING          CM_FILE_LOGSETTINGS
#define CM_MODE_RUN         9101
#define CM_MODE_SINGLE      9102
#define CM_MODE_HOLD        9103
#define CM_RECON_SPLINE     CM_WAVEFORM_RECON_SPLINE
#define CM_RECON_TRI        CM_WAVEFORM_RECON_TRI
#define CM_RECON_SQU        CM_WAVEFORM_RECON_SQU
#define CM_RECON_PNT        CM_WAVEFORM_RECON_PT
#define CM_RECON_SIN        CM_WAVEFORM_RECON_SINC
#define CM_VIEW_VT          CM_WAVEFORM_VT
#define CM_VIEW_XY          CM_WAVEFORM_XY
#define CM_VIEW_LIN         CM_WAVEFORM_LIN
#define CM_VIEW_LOG         CM_WAVEFORM_LOG
#define CM_TRIG_POS         CM_CONFIG_TRIGGER_POS
#define CM_TRIG_NEG         CM_CONFIG_TRIGGER_NEG
#define CM_TRIG_OFF         CM_CONFIG_TRIGGER_OFF

//Range of toolbar commands
#define TB_CM_MIN           CM_FILE_SAVEWAVE
#define TB_CM_MAX           CM_MODE_HOLD

//Offset for tooltips
#define TOOLTIP_OFFSET      1000

//Offset for status bar descriptions
#define STATUS_OFFSET       2000
#define STATUSMSGBIN        1
#define STATUS_CONNECTED        2500
#define STATUS_NOT_CONNECTED    2501

//Default settings file
#define DEFAULTSETTINGS         2502

//Icons
#define APP_SM_ICON     2
#define APP_ICON        1
#define REDDOT          3
#define GREDOT          4

//Toolbar image properties
//Number
#define TBBUTTONNUM     24  // 19 images and 5 separators
#define TBSEPARATORS    5
#define TBIMGNUM        20  // One alternative image
#define TBLOGON         19  //Beginning of alternative image
#define TBLOGOFF        3

//size
#define TBIMGX          20
#define TBIMGY          20
//transparent color
#define TBTRANSCOLOR    RGB(192,192,192)
//bitmaps
#define SAVEBMP         10
#define SAVESETBMP      11
#define OPENSETBMP      12
#define MODE_RUNBMP     13
#define MODE_SINGLEBMP  14
#define MODE_HOLDBMP    15
#define RECON_TRIBMP    16
#define RECON_SQUBMP    17
#define RECON_PNTBMP    18
#define RECON_SINBMP    19
#define VIEW_VTBMP      20
#define VIEW_XYBMP      21
#define VIEW_LINBMP     22
#define VIEW_LOGBMP     23
#define TRIG_POSBMP     24
#define TRIG_NEGBMP     25
#define TRIG_OFFBMP     26
#define LOG_OFFBMP      27
#define LOG_ONBMP       28
#define RECON_SPLINEBMP 29

#define ID_STATUSBAR        4997
#define ID_TOOLBAR          4998

/* Dialog boxes */
#define DLG_STATIC          -1

/* Cursors */
#define CROSSHAIR           5
#define CURMOVE             6
#define CURXMOVE            7
#define CURYMOVE            8

/* Channel colors */
#define CHACOLOR    0x007F7FFF
#define CHBCOLOR    0x00FF7F7F
#define CHCCOLOR    0x007FFF7F
#define CHDCOLOR    0x00FFFF7F
#define SCRCOLOR    0x00303030
#define SCRLINES    0x00009F00
#define CUR1COLOR    0x0030FFFF
#define CUR2COLOR   0x0070FFFF
#define TRGCOLOR    0x0040FFFF
//#define DIMCOLOR(rgbcolor)      ((rgbcolor >> 1) & 0x7F7F7F)

/* Message to test if other instance */
#define AREUME              0x8181

/* Handles for Toolbar and Statusbar */
HWND g_hToolBar, g_hStatusBar;
/* Handle for the main window */
HWND g_hMainWindow;
/* Handles for child windows, scope screen, spectrum screen, phase screen, and panel */
HWND g_hScreenMain, g_hScreenA, g_hScreenB, g_hPanel;

/* Samples and channels */
double channel1[2][BUFFER_MAX], channel2[2][BUFFER_MAX];
double channelA[2][BUFFER_MAX], channelB[2][BUFFER_MAX], channelC[2][BUFFER_MAX], channelD[2][BUFFER_MAX];
double chAfreqMag[2][BUFFER_MAX], chBfreqMag[2][BUFFER_MAX], chCfreqMag[2][BUFFER_MAX], chDfreqMag[2][BUFFER_MAX];;
double chAfreqPhase[2][BUFFER_MAX], chBfreqPhase[2][BUFFER_MAX],chCfreqPhase[2][BUFFER_MAX], chDfreqPhase[2][BUFFER_MAX];
double chAPeriod, chBPeriod, chCPeriod, chDPeriod;
int currentChannel;
double sampleRate[2];
double sampleCount[2];
double sampleMaxCount[2];
double sampleDelayCh1[2], sampleDelayCh2[2];

/* Volt per division, channel offsets, time per sample, and time per division */
double chAVoltDiv, chBVoltDiv, chCVoltDiv, chDVoltDiv, chAOffset, chBOffset, chCOffset, chDOffset, timeSample;

/* Reconstruction and display mode */
char reconst, chAmakeup, chBmakeup, chCmakeup, chDmakeup;
int dispmode;

/* Handles for Statusbar icons */
HICON hRedDot;
HICON hGreDot;

/* Handle for custom mouse cursor */
HCURSOR spCursor;
HCURSOR spbCursor;
HCURSOR spcCursor;
HCURSOR spdCursor;

HINSTANCE hInstance;

/* Refresh rate for the waveform captures */
int scopeRefreshRate;

/* Shared procedures */
int ToolbarStatusMsg(LPARAM lParam);
int ToolbarTooltip(LPARAM lParam);
int StatusBarShowConnection(BOOL connected);
int MenuStatusMsg(WPARAM wParam);


