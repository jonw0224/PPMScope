/* ==============================================================================
 * Author:  Jonathan Weaver, jonw0224@aim.com
 * E-mail Contact: jonw0224@aim.com
 * Description:  Log Settings Dialog Box.
 * Version: 2.14
 * Date: 11/2/2011
 * Filename:  logdlg.c, logdlg.h
 *
 * Versions History:  
 *      2.14 - 11/2/2011 - Added logging dialog
 *
 * Copyright (C) 2011 Jonathan Weaver
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

#include <stdio.h>

int logRecord;
double logRefreshSeconds;

/* Log File */
static FILE *logFile;
char logFileName[MAX_PATH];

/* Determines the selection for the log file */
char logFileSelect;
#define LOGENABLED                1
#define LOGEVERYTIME              2
#define LOGMEASUREMENTS           4
#define LOGTIMEDOMAIN             8
#define LOGFREQDOMAIN             16

#define LOGGINGDLG            4300
#define LOGGINGDLG_MEASEN     4301
#define LOGGINGDLG_TIMEEN     4302
#define LOGGINGDLG_FREQEN     4303
#define LOGGINGDLG_ALLDATA    4304
#define LOGGINGDLG_USEINT     4305
#define LOGGINGDLG_INT        4306
#define LOGGINGDLG_FILENAME   4307
#define LOGGINGDLG_CHOOSE     4308
#define LOGGINGDLG_OK         4309
#define LOGGINGDLG_CANCEL     4310


/* Creates a log file for the measurements, input waveform, and frequency domain.
 * pszFileName: a string pointer to the filename of the log file to save.
 */
int CreateLogFile(LPSTR pszFileName);

/* Save the waveform, etc to a log file */
int SaveToLogFile();

/* Close the log file */
int CloseLogFile();

int InitializeLogging();

/* Processes messages for the Hardware dialog box */
BOOL CALLBACK LogDlgProc (HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam);

