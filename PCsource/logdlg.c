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

#include "main.h"
#include "logdlg.h"
#include "engNum.h"
#include <time.h>

/* Creates a log file for the measurements, input waveform, and frequency domain.
 * pszFileName: a string pointer to the filename of the log file to save.
 */
int CreateLogFile(LPSTR pszFileName)
{
    double a, b;
    int i;
    int j;
    char userStr[80];

    logFile = fopen(pszFileName, "w");
    if(logFile == NULL)
        return 0;

    /* Header for log file */
    fprintf(logFile,",,");
    if(logFileSelect & LOGMEASUREMENTS)
    {
        fprintf(logFile, "Measurements,,,,");
    }
    if(logFileSelect & LOGTIMEDOMAIN)
    {
        fprintf(logFile, "ChannelA Time Domain,");
        for(i = 1; i < getSamplesPerChannel(); i++)
            fprintf(logFile, ",");
        fprintf(logFile, "ChannelB Time Domain,");
        for(i = 1; i < getSamplesPerChannel(); i++)
            fprintf(logFile, ",");
    }
    if(logFileSelect & LOGFREQDOMAIN)
    {
        fprintf(logFile, "ChannelA Frequency Magnitude,");
        for(i = 0; i < getSamplesPerChannel()/2; i++)
            fprintf(logFile, ",");
        fprintf(logFile, "ChannelB Frequency Magnitude,");
        for(i = 0; i < getSamplesPerChannel()/2; i++)
            fprintf(logFile, ",");
        fprintf(logFile, "ChannelA Frequency Phase,");
        for(i = 0; i < getSamplesPerChannel()/2; i++)
            fprintf(logFile, ",");
        fprintf(logFile, "ChannelB Frequency Phase,");
        for(i = 0; i < getSamplesPerChannel()/2; i++)
            fprintf(logFile, ",");
    }
    fprintf(logFile, "\n");

    /* Second row of header */
    fprintf(logFile, "Time, Record No,");
    /* Measurements */
    if(logFileSelect & LOGMEASUREMENTS)
    {
        for(i = 0; i < 4; i++)
        {
            LoadString(hInstance, MEASURE_CHOICE0 + measureFunct[i], userStr, 80);
            fprintf(logFile, "%s,", userStr);
        }
    }
    /* Time domain */
    if(logFileSelect & LOGTIMEDOMAIN)
    {
        a = 1 / getSampleRate();
        for(j = 0; j < 2; j++)
        {
            b = 0;
            for(i = 0; i < getSamplesPerChannel(); i++)
            {
                fprintf(logFile, "%g,", b);
                b+= a;
            }
        }
    }
    /* Frequency domain */
    if(logFileSelect & LOGFREQDOMAIN)
    {
        a = getSampleRate() / getSamplesPerChannel();
        for(j = 0; j < 4; j++)
        {
            b = 0;
            for(i = 0; i < getSamplesPerChannel()/2 + 1; i++)
            {
                fprintf(logFile, "%g,", b);
                b+= a;
            }
        }
    }
    fprintf(logFile, "\n");
    logRecord = 1;
    return 1;
}

/* Save the waveform, etc to a log file
 */
int SaveToLogFile()
{
    int i;

    /* Time */
    time_t rawtime;
    struct tm * timeinfo;
    char buffer [80];

    time (&rawtime);
    timeinfo = (struct tm *) localtime(&rawtime);

    strftime (buffer,80,"%x %X,",timeinfo);
    fprintf(logFile, buffer);

    /* Second row of header */
    fprintf(logFile, "%d,", logRecord);
    /* Measurements */
    if(logFileSelect & LOGMEASUREMENTS)
    {
        for(i = 0; i < 4; i++)
            fprintf(logFile, "%g,", mStat[i].last);
    }
    /* Time domain */
    if(logFileSelect & LOGTIMEDOMAIN)
    {
        for(i = 0; i < getSamplesPerChannel(); i++)
            fprintf(logFile, "%g,", channelA[currentChannel][i]);
        for(i = 0; i < getSamplesPerChannel(); i++)
            fprintf(logFile, "%g,", channelB[currentChannel][i]);
    }
    /* Frequency domain */
    if(logFileSelect & LOGFREQDOMAIN)
    {
        for(i = 0; i < getSamplesPerChannel()/2 + 1; i++)
            fprintf(logFile, "%g,", chAfreqMag[currentChannel][i]);
        for(i = 0; i < getSamplesPerChannel()/2 + 1; i++)
            fprintf(logFile, "%g,", chBfreqMag[currentChannel][i]);
        for(i = 0; i < getSamplesPerChannel()/2 + 1; i++)
            fprintf(logFile, "%g,", chAfreqPhase[currentChannel][i]);
        for(i = 0; i < getSamplesPerChannel()/2 + 1; i++)
            fprintf(logFile, "%g,", chBfreqPhase[currentChannel][i]);
    }
    fprintf(logFile, "\n");
    logRecord++;
}

/* Close the log file
 */
int CloseLogFile()
{
    fflush(logFile);
    fclose(logFile);
}

int InitializeLogging()
{
    logRecord = 1;
    logRefreshSeconds = 1;
    logFileSelect = 0;
    sprintf(logFileName, "log.csv");
}

/* Displays the save or open configuration file dialog box.
 * hwnd: window handle to the main window
 */
BOOL DoLogFileChoose(HWND hwnd)
{
   OPENFILENAME ofn;

   ZeroMemory(&ofn, sizeof(ofn));
   logFileName[0] = 0;

   ofn.lStructSize = sizeof(ofn);
   ofn.hwndOwner = hwnd;
   ofn.lpstrFilter = "Log Files (*.csv)\0*.csv\0All Files (*.*)\0*.*\0\0";
   ofn.lpstrFile = logFileName;
   ofn.nMaxFile = MAX_PATH;
   ofn.lpstrDefExt = "csv";

   ofn.Flags = OFN_EXPLORER | OFN_FILEMUSTEXIST | OFN_HIDEREADONLY;
   if(GetSaveFileName(&ofn))
   {
       return TRUE;
   }
   return FALSE;
}

/* Processes messages for the Calibrate dialog box */
BOOL CALLBACK LogDlgProc (HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
    HWND hctrl;
    char a[20];

    switch (message)
    {
    case WM_INITDIALOG:
        if(logFileSelect & LOGENABLED)
            SendMessage(GetDlgItem(hDlg, LOGGINGDLG_OK), WM_SETTEXT, 0, (LPARAM) "Stop");
        else
            SendMessage(GetDlgItem(hDlg, LOGGINGDLG_OK), WM_SETTEXT, 0, (LPARAM) "Start");
        if(logFileSelect & LOGMEASUREMENTS)
            SendMessage(GetDlgItem(hDlg, LOGGINGDLG_MEASEN), BM_SETCHECK, BST_CHECKED, 0);
        if(logFileSelect & LOGTIMEDOMAIN)
            SendMessage(GetDlgItem(hDlg, LOGGINGDLG_TIMEEN), BM_SETCHECK, BST_CHECKED, 0);
        if(logFileSelect & LOGFREQDOMAIN)
            SendMessage(GetDlgItem(hDlg, LOGGINGDLG_FREQEN), BM_SETCHECK, BST_CHECKED, 0);
        if(logFileSelect & LOGEVERYTIME)
        {
            EnableWindow(GetDlgItem(hDlg, LOGGINGDLG_INT), 0);
            hctrl = GetDlgItem(hDlg, LOGGINGDLG_ALLDATA);
            SendMessage(hctrl, BM_SETCHECK, BST_CHECKED, 0);
            SendMessage(GetDlgItem(hDlg, LOGGINGDLG_USEINT), BM_SETCHECK, BST_UNCHECKED, 0);
        }
        else
        {
            EnableWindow(GetDlgItem(hDlg, LOGGINGDLG_INT), 1);
            hctrl = GetDlgItem(hDlg, LOGGINGDLG_USEINT);
            SendMessage(hctrl, BM_SETCHECK, BST_CHECKED, 0);
            SendMessage(GetDlgItem(hDlg, LOGGINGDLG_ALLDATA), BM_SETCHECK, BST_UNCHECKED, 0);
            NumToEngStr(logRefreshSeconds, a);
            SendMessage(GetDlgItem(hDlg, LOGGINGDLG_INT), WM_SETTEXT, 0, (LPARAM) a);
        }
        SendMessage(GetDlgItem(hDlg, LOGGINGDLG_FILENAME), WM_SETTEXT, 0, (LPARAM) logFileName);
        return TRUE;
    case WM_COMMAND:
        switch (LOWORD (wParam))
        {
        case LOGGINGDLG_OK:
            if(SendMessage(GetDlgItem(hDlg, LOGGINGDLG_MEASEN), BM_GETCHECK, 0, 0) == BST_CHECKED)
                logFileSelect |= LOGMEASUREMENTS;
            else
                logFileSelect &= ~LOGMEASUREMENTS;
            if(SendMessage(GetDlgItem(hDlg, LOGGINGDLG_TIMEEN), BM_GETCHECK, 0, 0) == BST_CHECKED)
                logFileSelect |= LOGTIMEDOMAIN;
            else
                logFileSelect &= ~LOGTIMEDOMAIN;
            if(SendMessage(GetDlgItem(hDlg, LOGGINGDLG_FREQEN), BM_GETCHECK, 0, 0) == BST_CHECKED)
                logFileSelect |= LOGFREQDOMAIN;
            else
                logFileSelect &= ~LOGFREQDOMAIN;
            if(SendMessage(GetDlgItem(hDlg, LOGGINGDLG_ALLDATA), BM_GETCHECK, 0, 0) == BST_CHECKED)
                logFileSelect |= LOGEVERYTIME;
            else
                logFileSelect &= ~LOGEVERYTIME;
            SendMessage(GetDlgItem(hDlg, LOGGINGDLG_INT), WM_GETTEXT, 20, (LPARAM) a);
            logRefreshSeconds = EngStrToNum(a);
            if(logFileSelect & ~LOGEVERYTIME)
            {
                SetTimer(g_hMainWindow, 2, logRefreshSeconds*1000, NULL); /* Start logging timer */
            }
            else
            {
                KillTimer(g_hMainWindow, 2);
            }
            if(logFileSelect & LOGENABLED)
            {
                logFileSelect &= ~LOGENABLED;
                CloseLogFile();
            }
            else
            {
                SendMessage(GetDlgItem(hDlg, LOGGINGDLG_FILENAME), WM_GETTEXT, MAX_PATH, (LPARAM) logFileName);
                if(CreateLogFile(logFileName))
                    logFileSelect |= LOGENABLED;
                else
                {
                    SendMessage(hDlg, WM_COMMAND,LOGGINGDLG_CHOOSE,0);
                    //MessageBox(hDlg, "Error Creating Log File.  Try again.", "Error", 0);
                    return TRUE;
                }
            }
        case LOGGINGDLG_CANCEL:
            EndDialog (hDlg, 0);
            return TRUE;
            break;
        case LOGGINGDLG_MEASEN:
        case LOGGINGDLG_TIMEEN:
        case LOGGINGDLG_FREQEN:
            hctrl = GetDlgItem(hDlg, LOWORD(wParam));
            SendMessage(hctrl, BM_SETCHECK, !SendMessage(hctrl, BM_GETCHECK, 0, 0), 0);
            break;
        case LOGGINGDLG_ALLDATA:
            EnableWindow(GetDlgItem(hDlg, LOGGINGDLG_INT), 0);
            hctrl = GetDlgItem(hDlg, LOWORD(wParam));
            SendMessage(hctrl, BM_SETCHECK, 1, 0);
            SendMessage(GetDlgItem(hDlg, LOGGINGDLG_USEINT), BM_SETCHECK, 0, 0);
            break;
        case LOGGINGDLG_USEINT:
            EnableWindow(GetDlgItem(hDlg, LOGGINGDLG_INT), 1);
            hctrl = GetDlgItem(hDlg, LOWORD(wParam));
            SendMessage(hctrl, BM_SETCHECK, 1, 0);
            SendMessage(GetDlgItem(hDlg, LOGGINGDLG_ALLDATA), BM_SETCHECK, 0, 0);
            break;
        case LOGGINGDLG_CHOOSE:
            if(DoLogFileChoose(hDlg))
                SendMessage(GetDlgItem(hDlg, LOGGINGDLG_FILENAME), WM_SETTEXT, 0, (LPARAM) logFileName);
            break;
        }
        break;
    case WM_CLOSE:
        EndDialog(hDlg, 0);
        break;
    case WM_DESTROY:
        break;
    }
    return FALSE;
}
