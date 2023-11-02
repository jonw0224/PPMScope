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
 *      2.01 - 2/11/2009 - Modifications to main menu
 *      2.12 - 3/31/2009 - Modifications for extended trigger
 *      2.14 - 4/30/2009 - Modifications for measurements
 *      2.14 - 1/31/2011 - Modifications to settings load and save
 *      2.14 - 3/15/2011 - Modifications for Equiv Sampling checkbox on panel
 *      2.15 - 6/13/2012 - Modifications for keyboard accelerators and removed
 *                         limitation on window instances
 *      2.15 - 6/15/2012 - More modifications for keyboard accelerators
 *      2.15 - 7/20/2012 - Modified for continous Time Per Division
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

#include "main.h"
#include "aboutdlg.h"
#include "hardwaredlg.h"
#include "hdwtestdlg.h"
#include "parallel.h"
#include "refreshratedlg.h"
#include "caldlg.h"
#include "logdlg.h"

#include <stdio.h>
#include <time.h>

/*  Declare Windows procedure  */
LRESULT CALLBACK WindowProcedure (HWND, UINT, WPARAM, LPARAM);

/*  Make the class name into a global variable  */
char szClassName[ ] = "PPMScopeMain";

/* Search for other applications of the same window type
 * used to ensure only one instance by the main windows procedure */
BOOL CALLBACK Searcher(HWND hWnd, LPARAM lParam)
{
    DWORD result;
    HWND *target;
    LRESULT ok = SendMessageTimeout(hWnd, AREUME, 0, 0,
                    SMTO_BLOCK | SMTO_ABORTIFHUNG,
                    200,
                    &result);
    if(ok == 0) return TRUE; // ignore this and continue
    if(result == AREUME)
    { /* found it */
        target = (HWND *)lParam;
        *target = hWnd;
        return FALSE; // stop search
    } /* found it */
    return TRUE; // continue search
} // Searcher

/* Main windows procedure, called when the program runs */
int WINAPI WinMain (HINSTANCE hThisInstance,
                    HINSTANCE hPrevInstance,
                    LPSTR lpszArgument,
                    int nFunsterStil)

{
    MSG messages;            /* Here messages to the application are saved */
    WNDCLASSEX wincl;        /* Data structure for the windowclass */

#ifdef SINGLEINSTANCE
    /* Ensure first instance */
    BOOL alreadyRunning;
    HANDLE hMutexOneInstance = CreateMutex( NULL, FALSE,
        "PPMSCOPE-088FA840-B10D-11D3-BC36-006067709674");
    alreadyRunning = (GetLastError() == ERROR_ALREADY_EXISTS ||
                      GetLastError() == ERROR_ACCESS_DENIED);
    // The call fails with ERROR_ACCESS_DENIED if the Mutex was
    // created in a different users session because of passing
    // NULL for the SECURITY_ATTRIBUTES on Mutex creation);

    if (alreadyRunning)
    { /* kill this */
	    HWND hOther = NULL;
        EnumWindows(Searcher, (LPARAM)&hOther);

        if (hOther != NULL)
        { /* pop up */
            SetForegroundWindow(hOther);
            if (IsIconic(hOther))
            { /* restore */
                ShowWindow(hOther, SW_RESTORE);
            } /* restore */
        } /* pop up */

        return FALSE; // terminates the creation
    } /* kill this */

#endif

    hInstance = hThisInstance;    /* Remember where we come from */

    /* The Window structure */
    wincl.hInstance = hThisInstance;
    wincl.lpszClassName = szClassName;
    wincl.lpfnWndProc = WindowProcedure;      /* This function is called by windows */
    wincl.style = CS_DBLCLKS;                 /* Catch double-clicks */
    wincl.cbSize = sizeof(WNDCLASSEX);

    /* Use default icon and mouse-pointer */
    wincl.hIcon = LoadIcon(hInstance, MAKEINTRESOURCE(APP_ICON));
    wincl.hIconSm = (HICON) LoadImage(hInstance, MAKEINTRESOURCE(APP_SM_ICON), IMAGE_ICON, 16, 16, 0);
    wincl.hCursor = LoadCursor(NULL, IDC_ARROW);
    wincl.lpszMenuName = "MAINMENU";
    wincl.cbClsExtra = 0;                      /* No extra bytes after the window class */
    wincl.cbWndExtra = 0;                      /* structure or the window instance */
    /* Use Windows's default color as the background of the window */
    wincl.hbrBackground = (HBRUSH)(COLOR_3DFACE+1);

    /* Register the window class, and if it fails quit the program */
    if (!RegisterClassEx (&wincl))
        return 0;

    HACCEL g_hAcc = LoadAccelerators(hThisInstance, MAKEINTRESOURCE(1));

    /* The class is registered, let's create the program*/
    g_hMainWindow = CreateWindowEx (
           0,                   /* Extended possibilites for variation */
           szClassName,         /* Classname */
           WINDOWTEXT,          /* Title Text */
           WS_OVERLAPPEDWINDOW, /* default window */
           CW_USEDEFAULT,       /* Windows decides the position */
           CW_USEDEFAULT,       /* where the window ends up on the screen */
           720,                 /* The programs width */
           540,                 /* and height in pixels */
           HWND_DESKTOP,        /* The window is a child-window to desktop */
           NULL,                /* Main Menu */
           hThisInstance,       /* Program Instance handler */
           NULL                 /* No Window Creation data */
           );

    MoveWindowToDefaultPos();

    /* Make the window visible on the screen */
    ShowWindow (g_hMainWindow, nFunsterStil);

    /* Run the message loop. It will run until GetMessage() returns 0 */
    while (GetMessage (&messages, NULL, 0, 0))
    {
        /* Process Keyboard Accelerators */
        if(!TranslateAccelerator(g_hMainWindow, g_hAcc, &messages))
        {
            /* Forward messages to hPanel dialog */
            if (g_hPanel == 0 || !IsDialogMessage(g_hPanel, &messages))
            {
                /* Translate virtual-key messages into character messages */
                TranslateMessage(&messages);
                /* Send message to WindowProcedure */
                DispatchMessage(&messages);
            }
        }
    }
    /* The program return-value is 0 - The value that PostQuitMessage() gave */
    return messages.wParam;
}

/* Compares two strings, ignoring case and ignoring the whitespace
 * char* a: a pointer to the first string to compare to the second
 * char* b: a pointer to the second string to compare to the first
 * returns 0 if the two strings are identical */
int strcmpiwp(char* a,char* b)
{
    while(*a && *b)
    {
        if(*a == ' ' || *a == '\t')   /* Ignore whitespace */
            *a++;
        if(*b == ' ' || *b == '\t')   /* Ignore whitespace */
            *b++;
        if(tolower(*a) != tolower(*b))
        {
            break;
        }
        *a++;
        *b++;
    }
    return *a || *b;
}

/* Loads the default window position and sets the main window position */
BOOL MoveWindowToDefaultPos()
{
     char* pt;
     int x, y, w, h;
     x = strtod(getConfigPar("WINDOWPOSITIONX"), &pt);
     y = strtod(getConfigPar("WINDOWPOSITIONY"), &pt);
     w = strtod(getConfigPar("WINDOWPOSITIONW"), &pt);
     h = strtod(getConfigPar("WINDOWPOSITIONH"), &pt);
     return MoveWindow(g_hMainWindow, x, y, w, h, TRUE);
}

/* Loads the settings file from the hard-drive
 * pszFileName: the file name of the settings to be loaded
 * returns: 1 if successful, 0 if unsuccessful */
BOOL LoadSettingsFile(LPSTR pszFileName)
{
    char* iniStr;
    char configure[8];
    int portType, portNo, tickCnt, i;
    char a[RECLENGTH];
    char* pt;

    clearConfig();
    if(readConfigFile(pszFileName))
    {

        MoveWindowToDefaultPos();

        iniStr = getConfigPar("PORTTYPE");
        if(*iniStr == 'P')
            portType = PARALLELPORT;
        else if(*iniStr == 'S')
            portType = SERIALPORT;
        else
            portType = USBPORT;
        portNo = strtod(getConfigPar("PORTNUMBER"), &pt);
        tickCnt = strtod(getConfigPar("TICKCOUNT"), &pt);
        configure[0] = strtod(getConfigPar("CONFIGLOC1"), &pt);
        configure[1] = strtod(getConfigPar("TRIGGERDELAY0"), &pt);
        configure[2] = strtod(getConfigPar("TRIGGERDELAY1"), &pt);
        configure[3] = strtod(getConfigPar("TRIGGERDELAY2"), &pt);
        configure[4] = strtod(getConfigPar("TRIGGERDELAY3"), &pt);
        configure[5] = strtod(getConfigPar("SAMPLERATE0"), &pt);
        configure[6] = strtod(getConfigPar("SAMPLERATE1"), &pt);
        configure[7] = strtod(getConfigPar("SAMPLERATE2"), &pt);

        iniStr = getConfigPar("HARDWAREMODEL");
        if(*iniStr == 'D')
            setHardwareModel(DSOSCOPE);
        else
            setHardwareModel(PPMSCOPE);

        scopeRefreshRate = strtod(getConfigPar("REFRESHRATE"), &pt);

        setPenWeight(CHANNELA, strtod(getConfigPar("WEIGHTA"), &pt));
        setPenWeight(CHANNELB, strtod(getConfigPar("WEIGHTB"), &pt));
        setPenWeight(CHANNELC, strtod(getConfigPar("WEIGHTC"), &pt));
        setPenWeight(CHANNELD, strtod(getConfigPar("WEIGHTD"), &pt));

        /* Set the port address */
        if(portNo == LPTCUSTOM)
            setPortAdr(portNo, strtol(getConfigPar("PORTADDRESS"), &pt, 16));

        iniStr = getConfigPar("SAMPLEMODE");
        if(iniStr[0] == 'R')
            dispmode = MODE_RUN;
        else if(iniStr[0] == 'S')
            dispmode = MODE_STOP | MODE_HOLD;
        else if(iniStr[0] == 'H')
            dispmode = MODE_HOLD | MODE_RUN;
        else
            dispmode = MODE_STOP;

        iniStr = getConfigPar("CHAENABLED");
        if(iniStr[0] == 'Y')
            dispmode = dispmode | MODE_CHAENABLED;
        iniStr = getConfigPar("CHBENABLED");
        if(iniStr[0] == 'Y')
            dispmode = dispmode | MODE_CHBENABLED;
        iniStr = getConfigPar("CHCENABLED");
        if(iniStr[0] == 'Y')
            dispmode = dispmode | MODE_CHCENABLED;
        iniStr = getConfigPar("CHDENABLED");
        if(iniStr[0] == 'Y')
            dispmode = dispmode | MODE_CHDENABLED;

        chAVoltDiv = strtod(getConfigPar("CHAVOLTPERDIV"), &pt);
        chBVoltDiv = strtod(getConfigPar("CHBVOLTPERDIV"), &pt);
        chCVoltDiv = strtod(getConfigPar("CHCVOLTPERDIV"), &pt);
        chDVoltDiv = strtod(getConfigPar("CHDVOLTPERDIV"), &pt);
        chAOffset = strtod(getConfigPar("CHAOFFSET"), &pt);
        chBOffset = strtod(getConfigPar("CHBOFFSET"), &pt);
        chCOffset = strtod(getConfigPar("CHCOFFSET"), &pt);
        chDOffset = strtod(getConfigPar("CHDOFFSET"), &pt);

        /* Channel Makeup */
        iniStr = getConfigPar("CHA");
        chAmakeup = 0;
        for(i = CB_CHOICE1; i<= CB_CHOICE10; i++)
        {
            LoadString(hInstance, i, a, RECLENGTH);
            if(strcmpiwp(iniStr,a) == 0)
            {
                chAmakeup = i - CB_CHOICE1;
                break;
            }
        }
        iniStr = getConfigPar("CHB");
        chBmakeup = 0;
        for(i = CB_CHOICE1; i<= CB_CHOICE10; i++)
        {
            LoadString(hInstance, i, a, RECLENGTH);
            if(strcmpiwp(iniStr,a) == 0)
            {
               chBmakeup = i - CB_CHOICE1;
               break;
            }
        }
        iniStr = getConfigPar("CHC");
        chCmakeup = 0;
        for(i = CB_CHOICE14; i<= CB_CHOICE23; i++)
        {
            LoadString(hInstance, i, a, RECLENGTH);
            if(strcmpiwp(iniStr,a) == 0)
            {
               chCmakeup = i - CB_CHOICE14;
               break;
            }
        }
        iniStr = getConfigPar("CHD");
        chDmakeup = 0;
        for(i = CB_CHOICE14; i<= CB_CHOICE23; i++)
        {
            LoadString(hInstance, i, a, RECLENGTH);
            if(strcmpiwp(iniStr,a) == 0)
            {
               chDmakeup = i - CB_CHOICE14;
               break;
            }
        }

        /* MeasurementLoadSettingsFiles */
        iniStr = getConfigPar("MEASURE1");
        measureFunct[0] = 0;
        for(i = MEASURE_CHOICE0; i <= MEASURE_CHOICE24; i++)
        {
            LoadString(hInstance, i, a, RECLENGTH);
            if(strcmpiwp(iniStr,a) == 0)
            {
               measureFunct[0] = (i - MEASURE_CHOICE0) * 4;
               break;
            }
        }
        iniStr = getConfigPar("MEASURESOURCE1");
        for(i = MEASURE_SRC_CH1; i <= MEASURE_SRC_CH4; i++)
        {
            LoadString(hInstance, i, a, RECLENGTH);
            if(strcmpiwp(iniStr,a) == 0)
            {
                measureFunct[0]+= (i - MEASURE_SRC_CH1);
                break;
            }
        }
        iniStr = getConfigPar("MEASURE2");
        measureFunct[1] = 0;
        for(i = MEASURE_CHOICE0; i <= MEASURE_CHOICE24; i++)
        {
            LoadString(hInstance, i, a, RECLENGTH);
            if(strcmpiwp(iniStr,a) == 0)
            {
               measureFunct[1] = (i - MEASURE_CHOICE0) * 4;
               break;
            }
        }
        iniStr = getConfigPar("MEASURESOURCE2");
        for(i = MEASURE_SRC_CH1; i <= MEASURE_SRC_CH4; i++)
        {
            LoadString(hInstance, i, a, RECLENGTH);
            if(strcmpiwp(iniStr,a) == 0)
            {
                measureFunct[1]+= (i - MEASURE_SRC_CH1);
                break;
            }
        }
        iniStr = getConfigPar("MEASURE3");
        measureFunct[2] = 0;
        for(i = MEASURE_CHOICE0; i <= MEASURE_CHOICE24; i++)
        {
            LoadString(hInstance, i, a, RECLENGTH);
            if(strcmpiwp(iniStr,a) == 0)
            {
               measureFunct[2] = (i - MEASURE_CHOICE0)*4;
               break;
            }
        }
        iniStr = getConfigPar("MEASURESOURCE3");
        for(i = MEASURE_SRC_CH1; i <= MEASURE_SRC_CH4; i++)
        {
            LoadString(hInstance, i, a, RECLENGTH);
            if(strcmpiwp(iniStr,a) == 0)
            {
                measureFunct[2]+= (i - MEASURE_SRC_CH1);
                break;
            }
        }
        iniStr = getConfigPar("MEASURE4");
        measureFunct[3] = 0;
        for(i = MEASURE_CHOICE0; i <= MEASURE_CHOICE24; i++)
        {
            LoadString(hInstance, i, a, RECLENGTH);
            if(strcmpiwp(iniStr,a) == 0)
            {
               measureFunct[3] = (i - MEASURE_CHOICE0)*4;
               break;
            }
        }
        iniStr = getConfigPar("MEASURESOURCE4");
        for(i = MEASURE_SRC_CH1; i <= MEASURE_SRC_CH4; i++)
        {
            LoadString(hInstance, i, a, RECLENGTH);
            if(strcmpiwp(iniStr,a) == 0)
            {
                measureFunct[3]+= (i - MEASURE_SRC_CH1);
                break;
            }
        }

        iniStr = getConfigPar("RECONSTRUCTION");
        if(iniStr[0] == 'S')
            if(iniStr[1] == 'q')
                reconst = RECONST_SQUARE;
            else if(iniStr[1] == 'p')
                reconst = RECONST_BEZIER;
            else
                reconst = RECONST_SINC;
        else if(iniStr[0] == 'P')
            reconst = RECONST_POINT;
        else
            reconst = RECONST_TRIANGLE;

        iniStr = getConfigPar("ALLOWTIMEEQUIV");
        if(iniStr[0] == 'Y')
            setRepetitive(1);
        else
            setRepetitive(0);

        /* High resolution mode */
        iniStr = getConfigPar("HIGHRESMODE");
        if(iniStr[0] == 'Y')
            setHighResolution(1);
        else
            setHighResolution(0);

        setSamplesPerChannel(strtod(getConfigPar("BUFFERSIZE"), &pt));
        setOscDispType(g_hScreenMain, "SCREENATYPE");
        setOscDispType(g_hScreenA, "SCREENBTYPE");
        setOscDispType(g_hScreenB, "SCREENCTYPE");

        /* Colors */
        oscSetColors(strtol(getConfigPar("SCRBGCOLOR"), &pt, 16),
            strtol(getConfigPar("SCRFGCOLOR"), &pt, 16),
            strtol(getConfigPar("CHACOLOR"), &pt, 16),
            strtol(getConfigPar("CHBCOLOR"), &pt, 16),
            strtol(getConfigPar("CHCCOLOR"), &pt, 16),
            strtol(getConfigPar("CHDCOLOR"), &pt, 16),
            strtol(getConfigPar("CUR1COLOR"), &pt, 16),
            strtol(getConfigPar("CUR2COLOR"), &pt, 16),
            strtol(getConfigPar("TRIGGERCOLOR"), &pt, 16));

        hDriverSetConfig(portType, portNo, tickCnt, configure, BUFFER_MAX);

        /* Time Per Division */
        setTimePerDivision(strtod(getConfigPar("TIMEPERDIV"), &pt));

        /* Persistence */
        oscSetPersistence(strtod(getConfigPar("PERSISTENCE"), &pt));

        /* Update */
        SendMessage(g_hPanel, WM_REFRESHPANEL, 0, 0);
        MainWindowRefresh(g_hMainWindow);
        refreshScopeWindows(1);

        return 1;
    }
    else
    {
        portType = PARALLELPORT;
        portNo = 0;
        tickCnt = 500;
        configure[0] = 1 << 5;
        configure[1] = 0;
        configure[2] = 0;
        configure[3] = 0;
        configure[4] = 1;
        configure[5] = 0;
        configure[6] = 0;
        configure[7] = 1;

        hDriverSetConfig(portType, portNo, tickCnt, configure, BUFFER_MAX);
        hDriverInitialize();           /* Initialize hardware */
        SetTimer(g_hMainWindow, 1, scopeRefreshRate, NULL); /* Start redraw timer */
        currentChannel = 0;

        chAmakeup = CH1ONLY;
        chBmakeup = CH2ONLY;
        chCmakeup = CH1ONLY;
        chDmakeup = CH2ONLY;

        reconst = RECONST_TRIANGLE;
        dispmode = MODE_HOLD | MODE_STOP | MODE_CHAENABLED | MODE_CHBENABLED;

        chAVoltDiv = 5;
        chBVoltDiv = 5;
        chCVoltDiv = 5;
        chDVoltDiv = 5;
        chAOffset = 0;
        chBOffset = 0;
        chCOffset = 0;
        chDOffset = 0;

        SendMessage(g_hPanel, WM_REFRESHPANEL, 0, 0);
        MainWindowRefresh(g_hMainWindow);
        return 0;
    }
}

/* Saves the settings in a file
 * LPSTR pszFileName: the filename to save the settings in
 * returns: 1 is successful, 0 if unsuccessful */
BOOL SaveSettingsFile(LPSTR pszFileName)
{
    char a[RECLENGTH];
    char configure[8];
    int portType, portNo, tickCnt, buffersize;
    RECT mainRect;

    /* Insert some stuff here to load settings into setting file memory */
    hDriverGetConfig(&portType, &portNo, &tickCnt, configure, &buffersize);
    sprintf(a, "%d", configure[0]);
    setConfigPar("CONFIGLOC1", a);
    sprintf(a, "%d", configure[1]);
    setConfigPar("TRIGGERDELAY0", a);
    sprintf(a, "%d", configure[2]);
    setConfigPar("TRIGGERDELAY1", a);
    sprintf(a, "%d", configure[3]);
    setConfigPar("TRIGGERDELAY2", a);
    sprintf(a, "%d", configure[4]);
    setConfigPar("TRIGGERDELAY3", a);
    sprintf(a, "%d", configure[5]);
    setConfigPar("SAMPLERATE0", a);
    sprintf(a, "%d", configure[6]);
    setConfigPar("SAMPLERATE1", a);
    sprintf(a, "%d", configure[7]);
    setConfigPar("SAMPLERATE2", a);
    sprintf(a, "%d", buffersize);
    setConfigPar("BUFFERSIZE", a);

    /* Hardware Model */
    if(getHardwareModel() == PPMSCOPE)
        setConfigPar("HARDWAREMODEL", "PPMSCOPE");
    else
        setConfigPar("HARDWAREMODEL", "DSOSCOPE");

    sprintf(a, "%d", scopeRefreshRate);
    setConfigPar("REFRESHRATE", a);
    sprintf(a, "%d", getPenWeight(CHANNELA));
    setConfigPar("WEIGHTA", a);
    sprintf(a, "%d", getPenWeight(CHANNELB));
    setConfigPar("WEIGHTB", a);
    sprintf(a, "%d", getPenWeight(CHANNELC));
    setConfigPar("WEIGHTC", a);
    sprintf(a, "%d", getPenWeight(CHANNELD));
    setConfigPar("WEIGHTD", a);

    if(portType == PARALLELPORT)
        setConfigPar("PORTTYPE", "P");
    else if(portType == SERIALPORT)
        setConfigPar("PORTTYPE", "S");
    else if(portType == USBPORT)
        setConfigPar("PORTTYPE", "U");
    sprintf(a, "%d", portNo);
    setConfigPar("PORTNUMBER", a);
    sprintf(a, "%d", tickCnt);
    setConfigPar("TICKCOUNT", a);

    /* Save the port address */
    sprintf(a, "0x%X", portAdr(portNo));
    setConfigPar("PORTADDRESS", a);

    if(getRepetitive())
        setConfigPar("ALLOWTIMEEQUIV", "Y");
    else
        setConfigPar("ALLOWTIMEEQUIV", "N");

    sprintf(a, "%f", chAVoltDiv);
    setConfigPar("CHAVOLTPERDIV", a);
    sprintf(a, "%f", chBVoltDiv);
    setConfigPar("CHBVOLTPERDIV", a);
    sprintf(a, "%f", chCVoltDiv);
    setConfigPar("CHCVOLTPERDIV", a);
    sprintf(a, "%f", chDVoltDiv);
    setConfigPar("CHDVOLTPERDIV", a);
    sprintf(a, "%f", chAOffset);
    setConfigPar("CHAOFFSET", a);
    sprintf(a, "%f", chBOffset);
    setConfigPar("CHBOFFSET", a);
    sprintf(a, "%f", chCOffset);
    setConfigPar("CHCOFFSET", a);
    sprintf(a, "%f", chDOffset);
    setConfigPar("CHDOFFSET", a);
    if(dispmode & MODE_CHAENABLED)
        setConfigPar("CHAENABLED", "Yes");
    else
        setConfigPar("CHAENABLED", "No");
    if(dispmode & MODE_CHBENABLED)
        setConfigPar("CHBENABLED", "Yes");
    else
        setConfigPar("CHBENABLED", "No");
    if(dispmode & MODE_CHCENABLED)
        setConfigPar("CHCENABLED", "Yes");
    else
        setConfigPar("CHCENABLED", "No");
    if(dispmode & MODE_CHDENABLED)
        setConfigPar("CHDENABLED", "Yes");
    else
        setConfigPar("CHDENABLED", "No");

    /* Save Channel Makeup */
    LoadString(hInstance, chAmakeup+CB_CHOICE1, a, RECLENGTH);
    setConfigPar("CHA", a);
    LoadString(hInstance, chBmakeup+CB_CHOICE1, a, RECLENGTH);
    setConfigPar("CHB", a);
    LoadString(hInstance, chCmakeup+CB_CHOICE1, a, RECLENGTH);
    setConfigPar("CHC", a);
    LoadString(hInstance, chDmakeup+CB_CHOICE1, a, RECLENGTH);
    setConfigPar("CHD", a);

    /* Save Measurement Settings */
    LoadString(hInstance, measureFunct[0] / 4+MEASURE_CHOICE0, a, RECLENGTH);
    setConfigPar("MEASURE1", a);
    LoadString(hInstance, measureFunct[0] % 4 + MEASURE_SRC_CH1, a, RECLENGTH);
    setConfigPar("MEASURESOURCE1", a);
    LoadString(hInstance, measureFunct[1] / 4+MEASURE_CHOICE0, a, RECLENGTH);
    setConfigPar("MEASURE2", a);
    LoadString(hInstance, measureFunct[1] % 4 + MEASURE_SRC_CH1, a, RECLENGTH);
    setConfigPar("MEASURESOURCE2", a);
    LoadString(hInstance, measureFunct[2] / 4+MEASURE_CHOICE0, a, RECLENGTH);
    setConfigPar("MEASURE3", a);
    LoadString(hInstance, measureFunct[2] % 4 + MEASURE_SRC_CH1, a, RECLENGTH);
    setConfigPar("MEASURESOURCE3", a);
    LoadString(hInstance, measureFunct[3] / 4+MEASURE_CHOICE0, a, RECLENGTH);
    setConfigPar("MEASURE4", a);
    LoadString(hInstance, measureFunct[3] % 4 + MEASURE_SRC_CH1, a, RECLENGTH);
    setConfigPar("MEASURESOURCE4", a);

    switch(reconst)
    {
    case RECONST_TRIANGLE:
        setConfigPar("RECONSTRUCTION", "Triangle");
        break;
    case RECONST_SINC:
        setConfigPar("RECONSTRUCTION", "Sinc");
        break;
    case RECONST_SQUARE:
        setConfigPar("RECONSTRUCTION", "Square");
        break;
    case RECONST_POINT:
        setConfigPar("RECONSTRUCTION", "Point");
        break;
    case RECONST_BEZIER:
        setConfigPar("RECONSTRUCTION", "Spline");
        break;
    }
    if(dispmode & MODE_RUN)
    {
        if(dispmode & MODE_HOLD)
            setConfigPar("SAMPLEMODE", "Hold");
        else
            setConfigPar("SAMPLEMODE", "Run");
    }
    else
    {
        if(dispmode & MODE_HOLD)
            setConfigPar("SAMPLEMODE", "Stop");
        else
            setConfigPar("SAMPLEMODE", "Off");
    }
    getOscDispType(g_hScreenMain, "SCREENATYPE");
    getOscDispType(g_hScreenA, "SCREENBTYPE");
    getOscDispType(g_hScreenB, "SCREENCTYPE");

    /* High resolution mode */
    if(getHighResolution())
        setConfigPar("HIGHRESMODE", "Yes");
    else
        setConfigPar("HIGHRESMODE", "No");

    /* Colors */
    sprintf(a, "0x%X", oscGetColor(GETCOLORBG));
    setConfigPar("SCRBGCOLOR", a);
    sprintf(a, "0x%X", oscGetColor(GETCOLORGR));
    setConfigPar("SCRFGCOLOR", a);
    sprintf(a, "0x%X", oscGetColor(GETCOLORCHA));
    setConfigPar("CHACOLOR", a);
    sprintf(a, "0x%X", oscGetColor(GETCOLORCHB));
    setConfigPar("CHBCOLOR", a);
    sprintf(a, "0x%X", oscGetColor(GETCOLORCHC));
    setConfigPar("CHCCOLOR", a);
    sprintf(a, "0x%X", oscGetColor(GETCOLORCHD));
    setConfigPar("CHDCOLOR", a);
    sprintf(a, "0x%X", oscGetColor(GETCOLORCUR1));
    setConfigPar("CUR1COLOR", a);
    sprintf(a, "0x%X", oscGetColor(GETCOLORCUR2));
    setConfigPar("CUR2COLOR", a);
    sprintf(a, "0x%X", oscGetColor(GETCOLORTRIG));
    setConfigPar("TRIGGERCOLOR", a);

    /* Time Per Division */
    sprintf(a, "%e", getTimePerDivision());
    setConfigPar("TIMEPERDIV", a);

    /* Window position and size */
    GetWindowRect(g_hMainWindow, &mainRect);
    sprintf(a, "%d", mainRect.top);
    setConfigPar("WINDOWPOSITIONY", a);
    sprintf(a, "%d", mainRect.left);
    setConfigPar("WINDOWPOSITIONX", a);
    sprintf(a, "%d", mainRect.right - mainRect.left + 1);
    setConfigPar("WINDOWPOSITIONW", a);
    sprintf(a, "%d", mainRect.bottom - mainRect.top + 1);
    setConfigPar("WINDOWPOSITIONH", a);

    /* Persistence */
    sprintf(a, "%d", oscGetPersistence());
    setConfigPar("PERSISTENCE", a);

    return writeConfigFile(pszFileName);
}

/* Saves the default settings to a file
 * returns 1 if successful, 0 if unsuccessful */
int SaveDefaultSettingsFile()
{
    static FILE *configFile;
    char toWrite[2000];

    LoadString(hInstance, DEFAULTSETTINGS, toWrite, 2000);

    configFile = fopen("default.cfg", "w");
    if(configFile == NULL)
        return 0;

    if(fputs (toWrite, configFile) != EOF)
        return fflush(configFile);

    fclose(configFile);

    return 1;
}

/* Displays the save or open configuration file dialog box.
 * hwnd: window handle to the main window
 * bSave: TRUE means save the file.  FALSE means open the file.
 */
BOOL DoFileOpenSave(HWND hwnd, BOOL bSave)
{
   OPENFILENAME ofn;
   char szFileName[MAX_PATH];

   ZeroMemory(&ofn, sizeof(ofn));
   szFileName[0] = 0;

   ofn.lStructSize = sizeof(ofn);
   ofn.hwndOwner = hwnd;
   ofn.lpstrFilter = "Configuration Files (*.cfg)\0*.cfg\0All Files (*.*)\0*.*\0\0";
   ofn.lpstrFile = szFileName;
   ofn.nMaxFile = MAX_PATH;
   ofn.lpstrDefExt = "txt";

   if(bSave)
   {
      ofn.Flags = OFN_EXPLORER | OFN_PATHMUSTEXIST | OFN_HIDEREADONLY |
         OFN_OVERWRITEPROMPT;

      if(GetSaveFileName(&ofn))
      {
         if(!SaveSettingsFile(szFileName))
         {
            MessageBox(hwnd, "Save file failed.", "Error",
               MB_OK | MB_ICONEXCLAMATION);
            return FALSE;
         }
      }
   }
   else
   {
      ofn.Flags = OFN_EXPLORER | OFN_FILEMUSTEXIST | OFN_HIDEREADONLY;
      if(GetOpenFileName(&ofn))
      {
         if(!LoadSettingsFile(szFileName))
         {
            MessageBox(hwnd, "Load of file failed, loading defaults...", "Error",
               MB_OK | MB_ICONEXCLAMATION);
            return FALSE;
         }
      }
   }
   return TRUE;
}

/* Save the waveform to a csv file
 * pszFileName: a pointer to a string containing the filename
 */
int SaveWaveformFile(LPSTR pszFileName)
{
    static FILE *wFile;
    int i;
    double a, b;
    char userStr[80];

    wFile = fopen(pszFileName, "w");
    if(wFile == NULL)
        return 0;

    a = 1 / getSampleRate();
    b = 0;

    fprintf(wFile, "Time Domain\n\nTime, Ch1, Ch2, ChA, ChB\n");

    for(i = 0; i < getSamplesPerChannel(); i++)
    {
          fprintf(wFile, "%g, %g, %g, %g, %g\n", b, channel1[currentChannel][i],
               channel2[currentChannel][i], channelA[currentChannel][i],
               channelB[currentChannel][i]);
          b+= a;
    }

    fprintf(wFile, "\n\n\nFequency Domain\n\nFreq, ChAMagn, ChBMagn, ChAPhase, ChBPhase\n");

    a = getSampleRate() / getSamplesPerChannel();

    for(i = 0; i < getSamplesPerChannel()/2 + 1; i++)
    {
          fprintf(wFile, "%g, %g, %g, %g, %g\n", b, chAfreqMag[currentChannel][i],
               chBfreqMag[currentChannel][i], chAfreqPhase[currentChannel][i],
               chBfreqPhase[currentChannel][i]);
          b+= a;
    }

    fprintf(wFile, "\n\n\nMeasurements\n\nMeasurement, Instanteous, Max, Avg, Std, Min\n");

    for(i = 0; i < 4; i++)
    {
        LoadString(hInstance, MEASURE_CHOICE0 + measureFunct[i], userStr, 80);
        fprintf(wFile, "%s, %g, %g, %g, %g, %g\n", userStr, mStat[i].last, mStat[i].max, mStat[i].average, mStat[i].stddev, mStat[i].min);
    }

    fflush(wFile);
    fclose(wFile);

    return 1;
}

/* Displays the save waveform file dialog */
int DoFileWaveformSave(HWND hwnd)
{
   OPENFILENAME ofn;
   char szFileName[MAX_PATH];

   ZeroMemory(&ofn, sizeof(ofn));
   szFileName[0] = 0;

   ofn.lStructSize = sizeof(ofn);
   ofn.hwndOwner = hwnd;
   ofn.lpstrFilter = "Waveform Comma Delimited File (*.csv)\0*.csv\0All Files (*.*)\0*.*\0\0";
   ofn.lpstrFile = szFileName;
   ofn.nMaxFile = MAX_PATH;
   ofn.lpstrDefExt = "csv";

   ofn.Flags = OFN_EXPLORER | OFN_PATHMUSTEXIST | OFN_HIDEREADONLY | OFN_OVERWRITEPROMPT;

      if(GetSaveFileName(&ofn))
      {
         if(!SaveWaveformFile(szFileName))
         {
            MessageBox(hwnd, "Save file failed.", "Error",
               MB_OK | MB_ICONEXCLAMATION);
            return FALSE;
         }
      }

      return TRUE;
}

/*  This function is called by the Windows function DispatchMessage()  */
// hwnd: handle to the window
// message: message for the window to process
// wParam: a parameter, interpretation depends on message
// lParam: a parameter, interpretation depends on message
LRESULT CALLBACK WindowProcedure (HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    int i, j, k;
    MENUITEMINFO mii;

    switch (message)                  /* handle the messages */
    {
        case WM_CREATE:

            #ifdef DEBUGON
                dOpen("debug.txt");
            #endif

            /* Main window */
            MainWindowCreate(hwnd);
            StatusBarShowConnection(0);

            /* Load hardware defaults, create defaults file if not available */

            if(!LoadSettingsFile("default.cfg"))
            {
                SaveDefaultSettingsFile();
                LoadSettingsFile("default.cfg");
            }

            hDriverInitialize();          /* Initialize hardware */

            /* Update the menu and toolbar */
            MainWindowRefresh(hwnd);

            /* Update the side panel */
            populatePanel();

            SetTimer(hwnd, 1, scopeRefreshRate, NULL); /* Start redraw timer */
            currentChannel = 0;

            /* Initialize the logging code */
            InitializeLogging();

            break;
        case WM_TIMER:
            switch (wParam)
            {
            case 1:
                if(dispmode & MODE_RUN)
                {
                    j = updateChannels(channel1[!currentChannel], channel2[!currentChannel]);
                    StatusBarShowConnection(j);
                    if((j & 0x03) == 2)
                    {
                        currentChannel = !currentChannel;
                        MapChannels(channel1[currentChannel], channel2[currentChannel], channelA[currentChannel], channelB[currentChannel], channelC[currentChannel], channelD[currentChannel]);
                        i = getMaxSamplesPerChannel();
                        sampleMaxCount[currentChannel] = i;
                        sampleCount[currentChannel] = getSamplesPerChannel();
                        sampleRate[currentChannel] = getSampleRate();
                        faFourier(channelA[currentChannel], chAfreqMag[currentChannel], chAfreqPhase[currentChannel], i);
                        faFourier(channelB[currentChannel], chBfreqMag[currentChannel], chBfreqPhase[currentChannel], i);
                        faFourier(channelC[currentChannel], chCfreqMag[currentChannel], chCfreqPhase[currentChannel], i);
                        faFourier(channelD[currentChannel], chDfreqMag[currentChannel], chDfreqPhase[currentChannel], i);
                        chAPeriod = sigPeriod(channelA[currentChannel], i)*i/sampleRate[currentChannel];
                        chBPeriod = sigPeriod(channelB[currentChannel], i)*i/sampleRate[currentChannel];
                        chCPeriod = sigPeriod(channelC[currentChannel], i)*i/sampleRate[currentChannel];
                        chDPeriod = sigPeriod(channelD[currentChannel], i)*i/sampleRate[currentChannel];
                        updateTriggerLevel();
                        updateTriggerChannel();
                        updateChannelMsg(j);
                        doMeasurements();
                        drawScope(); /* Draw the oscilloscope screens */
                        if((logFileSelect & LOGENABLED) && (logFileSelect & LOGEVERYTIME))
                            SaveToLogFile();
                    }    /* if update channels */
                }    /* if redraw */
                else
                    StatusBarShowConnection(0);
                break;
            case 2:
                if((logFileSelect & LOGENABLED) && !(logFileSelect & LOGEVERYTIME))
                    SaveToLogFile();
                break;
            }
            break;
        case WM_CLOSE:

            #ifdef DEBUGON
                dClose();
            #endif

            /* Stop logging if necessary */
            if(logFileSelect & LOGENABLED)
                CloseLogFile();

            MainWindowClose(hwnd);
            KillTimer(hwnd, 1);        /* End redraw timer */
            KillTimer(hwnd, 2);        /* End logging timer */
            break;
        case WM_DESTROY:
            PostQuitMessage (0);       /* send a WM_QUIT to the message queue */
            break;
        case WM_COMMAND:
            switch (LOWORD(wParam))
            {
                case CM_FILE_EXIT:
                    SendMessage(hwnd, WM_CLOSE, 0, 0);
                    break;
                case CM_FILE_OPENSET:
                    DoFileOpenSave(hwnd, FALSE);
                    refreshScopeWindows(1);
                    break;
                case CM_FILE_SAVESET:
                    DoFileOpenSave(hwnd, TRUE);
                    break;
                case CM_FILE_SAVEWAVE:
                    DoFileWaveformSave(hwnd);
                    break;
                case CM_FILE_LOGSETTINGS:
                    if(logFileSelect & LOGENABLED)
                    {
                        logFileSelect &= ~LOGENABLED;
                        KillTimer(g_hMainWindow, 2);
                        CloseLogFile();
                    }
                    else
                    {
                        DialogBox(hInstance, MAKEINTRESOURCE(LOGGINGDLG), hwnd, LogDlgProc);
                    }
                    if(logFileSelect & LOGENABLED)
                    {
                        SendMessage(g_hToolBar, TB_CHANGEBITMAP, CM_FILE_LOGSETTINGS, TBLOGON);
                        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_FILE_LOGSETTINGS, TRUE);
                        mii.cbSize = sizeof(MENUITEMINFO);
                        mii.fMask = MIIM_TYPE;
                        mii.fType = MFT_STRING;
                        mii.cch = 19;
                        mii.dwTypeData = "&Logging Off\tCtrl+L";
                        SetMenuItemInfo(GetMenu(hwnd), CM_FILE_LOGSETTINGS, FALSE, &mii);
                        SendMessage(g_hStatusBar, SB_SETTEXT, STATUSMSGBIN, (LPARAM) "Logging on...");
                        DrawMenuBar(hwnd);
                    }
                    else
                    {
                        //Change the toolbar
                        SendMessage(g_hToolBar, TB_CHANGEBITMAP, CM_FILE_LOGSETTINGS, TBLOGOFF);
                        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_FILE_LOGSETTINGS, FALSE);
                        // Change the menu
                        mii.cbSize = sizeof(MENUITEMINFO);
                        mii.fMask = MIIM_TYPE;
                        mii.fType = MFT_STRING;
                        mii.cch = 14;
                        mii.dwTypeData = "&Log Settings\tCtrl+L";
                        SetMenuItemInfo(GetMenu(hwnd), CM_FILE_LOGSETTINGS, FALSE, &mii);
                        DrawMenuBar(hwnd);
                        // Status bar message
                        SendMessage(g_hStatusBar, SB_SETTEXT, STATUSMSGBIN, (LPARAM) "Logging off...");
                    }
                    break;
                case CM_MODE_RUN:
                    if((dispmode & (MODE_STOP | MODE_RUN | MODE_HOLD)) != MODE_RUN)
                    {
                        dispmode = dispmode & ~MODE_STOP | MODE_RUN;
                        refreshScopeWindows(0);
                    }
                    SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_MODE_RUN, TRUE);
                    SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_MODE_SINGLE, FALSE);
                    break;
                case CM_MODE_HOLD:
                    if((dispmode & MODE_HOLD) != MODE_HOLD)
                    {
                        dispmode = dispmode | MODE_HOLD;
                        refreshScopeWindows(0);
                        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_MODE_HOLD, TRUE);
                    }
                    else
                    {
                        dispmode = dispmode & ~MODE_HOLD;
                        refreshScopeWindows(0);
                        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_MODE_HOLD, FALSE);
                    }
                    break;
                case CM_MODE_SINGLE:
                    dispmode = dispmode | MODE_STOP | MODE_RUN;
                    SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_MODE_RUN, FALSE);
                    SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_MODE_SINGLE, TRUE);
                    break;
                case CM_VIEW_VT:
                    if(dispmode & MODE_XY)
                    {
                        CheckMenuRadioItem(GetMenu(g_hMainWindow), CM_VIEW_VT, CM_VIEW_XY,
                            CM_VIEW_VT, MF_BYCOMMAND);
                        dispmode = dispmode & ~MODE_XY;
                        refreshScopeWindows(0);
                    }
                    SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_VIEW_VT, TRUE);
                    SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_VIEW_XY, FALSE);
                    break;
                case CM_VIEW_XY:
                    if(!(dispmode & MODE_XY))
                    {
                        CheckMenuRadioItem(GetMenu(g_hMainWindow), CM_VIEW_VT, CM_VIEW_XY,
                            CM_VIEW_XY, MF_BYCOMMAND);
                        dispmode = dispmode | MODE_XY;
                        refreshScopeWindows(0);
                    }
                    SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_VIEW_VT, FALSE);
                    SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_VIEW_XY, TRUE);
                    break;
                case CM_VIEW_LIN:
                    if(dispmode & MODE_FREQMAGLOG)
                    {
                        CheckMenuRadioItem(GetMenu(g_hMainWindow), CM_VIEW_LIN, CM_VIEW_LOG,
                            CM_VIEW_LIN, MF_BYCOMMAND);
                        dispmode = dispmode & ~MODE_FREQMAGLOG;
                        refreshScopeWindows(0);
                    }
                    SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_VIEW_LIN, TRUE);
                    SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_VIEW_LOG, FALSE);
                    break;
                case CM_VIEW_LOG:
                    if(!(dispmode & MODE_FREQMAGLOG))
                    {
                        CheckMenuRadioItem(GetMenu(g_hMainWindow), CM_VIEW_LIN, CM_VIEW_LOG,
                            CM_VIEW_LOG, MF_BYCOMMAND);
                        dispmode = dispmode | MODE_FREQMAGLOG;
                        refreshScopeWindows(0);
                    }
                    SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_VIEW_LIN, FALSE);
                    SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_VIEW_LOG, TRUE);
                    break;
                case CM_CONFIG_HARDWARE:
                     KillTimer(hwnd, 1); /* Stop redraw timer */
                     DialogBox(hInstance, MAKEINTRESOURCE(HARDWAREDLG), hwnd, HardwareDlgProc);
                     SetTimer(hwnd, 1, scopeRefreshRate, NULL); /* Start redraw timer */
                     break;
                case CM_CONFIG_HARDTEST:
                     KillTimer(hwnd, 1); /* Stop redraw timer */
                     DialogBox(hInstance, MAKEINTRESOURCE(HDWTESTDLG), hwnd, HdwTestDlgProc);
                     SetTimer(hwnd, 1, scopeRefreshRate, NULL); /* Start redraw timer */
                     break;
                case CM_CONFIG_CALIBRATE:
                     DialogBox(hInstance, MAKEINTRESOURCE(CALDLG), hwnd, CalDlgProc);
                     break;
                case CM_CONFIG_SAMPLE_INTERLACED:
                     SendMessage(g_hPanel, WM_COMMAND, CM_CONFIG_SAMPLE_INTERLACED, 0);
                    break;
                case CM_CONFIG_SAMPLE_TIMEEQUIV:
                    SendMessage(g_hPanel, WM_COMMAND, CM_CONFIG_SAMPLE_TIMEEQUIV, 0);
                    break;
                case CM_CONFIG_WAVEFORM_REFRESH_RATE:
                    DialogBox(hInstance, MAKEINTRESOURCE(REFRESHRATEDLG), hwnd, RefreshRateDlgProc);
                    SetTimer(hwnd, 1, scopeRefreshRate, NULL); /* reset redraw timer */
                    break;
                case CM_WAVEFORM_HIGH_RES:
                    if(getHighResolution())
                    {
                        CheckMenuItem(GetMenu(g_hMainWindow), CM_WAVEFORM_HIGH_RES, MF_UNCHECKED);
                        setHighResolution(0);
                    }
                    else
                    {
                        CheckMenuItem(GetMenu(g_hMainWindow), CM_WAVEFORM_HIGH_RES, MF_CHECKED);
                        setHighResolution(1);
                    }
                    break;
                case CM_HELP_HELP:
                    ShellExecute(0, "open", "PPMScope.chm", "", "" , SW_SHOWNORMAL);
                    break;
                case CM_HELP_ABOUT:
                    DialogBox(hInstance, MAKEINTRESOURCE(ABOUTDLG), hwnd, AboutDlgProc);
                    break;
                case CM_TRIG_POS:
                    setTriggerPos();
                    setTimePerDiv(getTimePerDivision());
                    RefreshTimeDiv();
                    refreshScopeWindows(1);
                    break;
                case CM_TRIG_OFF:
                    setTriggerOff();
                    setTimePerDiv(getTimePerDivision());
                    RefreshTimeDiv();
                    refreshScopeWindows(1);
                    break;
                case CM_TRIG_NEG:
                    setTriggerNeg();
                    setTimePerDiv(getTimePerDivision());
                    RefreshTimeDiv();
                    refreshScopeWindows(1);
                    break;
                case CM_RECON_TRI:
                    reconst = RECONST_TRIANGLE;
                    CheckMenuRadioItem(GetMenu(g_hMainWindow), CM_RECON_SPLINE, CM_RECON_SIN,
                        CM_RECON_TRI, MF_BYCOMMAND);
                    SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_SPLINE, FALSE);
                    SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_TRI, TRUE);
                    SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_SIN, FALSE);
                    SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_SQU, FALSE);
                    SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_PNT, FALSE);
                    refreshScopeWindows(0);
                    break;
                case CM_RECON_SPLINE:
                    reconst = RECONST_BEZIER;
                    CheckMenuRadioItem(GetMenu(g_hMainWindow), CM_RECON_SPLINE, CM_RECON_SIN,
                        CM_RECON_SPLINE, MF_BYCOMMAND);
                    SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_SPLINE, TRUE);
                    SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_TRI, FALSE);
                    SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_SIN, FALSE);
                    SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_SQU, FALSE);
                    SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_PNT, FALSE);
                    refreshScopeWindows(0);
                    break;
                case CM_RECON_SQU:
                    reconst = RECONST_SQUARE;
                    CheckMenuRadioItem(GetMenu(g_hMainWindow), CM_RECON_SPLINE, CM_RECON_SIN,
                        CM_RECON_SQU, MF_BYCOMMAND);
                    SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_SPLINE, FALSE);
                    SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_TRI, FALSE);
                    SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_SIN, FALSE);
                    SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_SQU, TRUE);
                    SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_PNT, FALSE);
                    refreshScopeWindows(0);
                    break;
                case CM_RECON_PNT:
                    reconst = RECONST_POINT;
                    CheckMenuRadioItem(GetMenu(g_hMainWindow), CM_RECON_SPLINE, CM_RECON_SIN,
                        CM_RECON_PNT, MF_BYCOMMAND);
                    SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_SPLINE, FALSE);
                    SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_TRI, FALSE);
                    SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_SIN, FALSE);
                    SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_SQU, FALSE);
                    SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_PNT, TRUE);
                    refreshScopeWindows(0);
                    break;
                case CM_RECON_SIN:
                    reconst = RECONST_SINC;
                    CheckMenuRadioItem(GetMenu(g_hMainWindow), CM_RECON_SPLINE, CM_RECON_SIN,
                        CM_RECON_SIN, MF_BYCOMMAND);
                    SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_SPLINE, FALSE);
                    SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_TRI, FALSE);
                    SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_SIN, TRUE);
                    SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_SQU, FALSE);
                    SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_PNT, FALSE);
                    refreshScopeWindows(0);
                    break;
                case CM_VOLT_PER_DIV_CHA_CINC:
                    chAVoltDivChange(ADJ_FINCR);
                    break;
                case CM_VOLT_PER_DIV_CHA_CDEC:
                    chAVoltDivChange(ADJ_FDECR);
                    break;
                case CM_VOLT_OFFSET_CHA_INC:
                    chAOffsetChange(ADJ_FINCR);
                    break;
                case CM_VOLT_OFFSET_CHA_DEC:
                    chAOffsetChange(ADJ_FDECR);
                    break;
                case CM_VOLT_PER_DIV_CHB_CINC:
                    chBVoltDivChange(ADJ_FINCR);
                    break;
                case CM_VOLT_PER_DIV_CHB_CDEC:
                    chBVoltDivChange(ADJ_FDECR);
                    break;
                case CM_VOLT_OFFSET_CHB_INC:
                    chBOffsetChange(ADJ_FINCR);
                    break;
                case CM_VOLT_OFFSET_CHB_DEC:
                    chBOffsetChange(ADJ_FDECR);
                    break;
                case CM_VOLT_PER_DIV_CHC_CINC:
                    chCVoltDivChange(ADJ_FINCR);
                    break;
                case CM_VOLT_PER_DIV_CHC_CDEC:
                    chCVoltDivChange(ADJ_FDECR);
                    break;
                case CM_VOLT_OFFSET_CHC_INC:
                    chCOffsetChange(ADJ_FINCR);
                    break;
                case CM_VOLT_OFFSET_CHC_DEC:
                    chCOffsetChange(ADJ_FDECR);
                    break;
                case CM_VOLT_PER_DIV_CHD_CINC:
                    chDVoltDivChange(ADJ_FINCR);
                    break;
                case CM_VOLT_PER_DIV_CHD_CDEC:
                    chDVoltDivChange(ADJ_FDECR);
                    break;
                case CM_VOLT_OFFSET_CHD_INC:
                    chDOffsetChange(ADJ_FINCR);
                    break;
                case CM_VOLT_OFFSET_CHD_DEC:
                    chDOffsetChange(ADJ_FDECR);
                    break;
                case CM_TIME_PER_DIV_DEC:
                    timePerDivChange(ADJ_FDECR);
                    break;
                case CM_TIME_PER_DIV_INC:
                    timePerDivChange(ADJ_FINCR);
                    break;
                case CM_TRIGGER_DELAY_DEC:
                    triggerDelayChange(ADJ_FDECR);
                    refreshTriggerDelay();
                    break;
                case CM_TRIGGER_DELAY_INC:
                    triggerDelayChange(ADJ_FINCR);
                    refreshTriggerDelay();
                    break;
                default:
                    break;
            }
            break;
        case WM_NOTIFY:
           switch (((LPNMHDR) lParam)->code)
	       {
                case TTN_GETDISPINFO:
                {
                    ToolbarTooltip(lParam);
                    break;
                }
                case TBN_HOTITEMCHANGE:
                {
                    ToolbarStatusMsg(lParam);
                    break;
                }
                default:
                    break;
            }
            break;
        case WM_MENUSELECT:
            MenuStatusMsg(wParam);
            break;
        case WM_SIZE:
            MainWindowResize(hwnd);
            break;
        case AREUME:
            return AREUME;
        default:                      /* for messages that we don't deal with */
            return DefWindowProc (hwnd, message, wParam, lParam);
    }

    return 0;
}

/* Sets the oscilloscope screen type for each control
 * hwnd: handle for the control
 * parName: parameter to read from configuration array */
int setOscDispType(HWND hwnd, char* parName)
{
    char* iniStr;

    iniStr = getConfigPar(parName);
    if(iniStr[0] == 'V')
        SendMessage(hwnd, CM_SETSCREENTYPE, SCOPE_SCREEN, 0);
    else if(iniStr[0] == 'M')
        SendMessage(hwnd, CM_SETSCREENTYPE, SCOPE_MEASUREMENTS, 0);
    else if(iniStr[0] == 'X')
    {
         SendMessage(hwnd, CM_SETSCREENTYPE, SCOPE_SCREEN, 0);
         dispmode = dispmode | MODE_XY;
    }
    else if(iniStr[4] == 'M')
        SendMessage(hwnd, CM_SETSCREENTYPE, SCOPE_FREQMAG, 0);
    else if(iniStr[4] == 'P')
        SendMessage(hwnd, CM_SETSCREENTYPE, SCOPE_FREQPHASE, 0);
    else
    {
        SendMessage(hwnd, CM_SETSCREENTYPE, SCOPE_FREQMAG, 0);
        dispmode = dispmode | MODE_FREQMAGLOG;
    }
    return 0;
}

/* Saves the oscilloscope screen type for each control
 * hwnd: handle for the control
 * parName: parameter to save to configureation array */
int getOscDispType(HWND hwnd, char* parName)
{
    int a;
    a = SendMessage(hwnd, CM_GETSCREENTYPE, 0, 0);
    if(a == SCOPE_SCREEN)
         if(dispmode & MODE_XY)
             setConfigPar(parName, "XY");
         else
             setConfigPar(parName, "VoltTime");
    else if(a == SCOPE_MEASUREMENTS)
        setConfigPar(parName, "Measurements");
    else if(a == SCOPE_FREQMAG)
         if(dispmode & MODE_FREQMAGLOG)
             setConfigPar(parName, "FreqLogMagn");
         else
             setConfigPar(parName, "FreqMagn");
    else
        setConfigPar(parName, "FreqPhase");
    return 0;
}

/* Create the application status bar
 * hwnd:  the handle of the main window
 * returns:  the handle of the Status Bar
 */
HWND StatusBarCreate(HWND hwnd)
{
    HWND hwndSB;

    hwndSB = CreateWindowEx(0, STATUSCLASSNAME, NULL,
        WS_CHILD | WS_VISIBLE | SBARS_SIZEGRIP | WS_CLIPSIBLINGS | SBT_TOOLTIPS, 0, 0, 0, 0,
        hwnd, (HMENU)ID_STATUSBAR, hInstance, NULL);

    hGreDot = (HICON) LoadImage(hInstance, MAKEINTRESOURCE(GREDOT), IMAGE_ICON, 16, 16, 0);
    hRedDot = (HICON) LoadImage(hInstance, MAKEINTRESOURCE(REDDOT), IMAGE_ICON, 16, 16, 0);

    StatusBarSetParts(hwndSB);

    return hwndSB;
}

/* Sizes the parts of the status bar based on the window size
 * hwnd:  the handle of the status bar
 * returns:  0
 */
int StatusBarSetParts(HWND hwndSB)
{

    #define STATUSPARTNUM   7

    int iStatusWidths[STATUSPARTNUM];
    RECT clRect;

    GetClientRect(hwndSB, &clRect);
    iStatusWidths[0] = 20;
    iStatusWidths[1] = clRect.right - 510;
    iStatusWidths[2] = clRect.right - 410;
    iStatusWidths[3] = clRect.right - 310;
    iStatusWidths[4] = clRect.right - 210;
    iStatusWidths[5] = clRect.right - 110;
    iStatusWidths[6] = -1;
    SendMessage(hwndSB, SB_SETPARTS, STATUSPARTNUM, (LPARAM)iStatusWidths);
    return 0;
}

/* Updates and displays the connection status to the hardware in the status bar
 * connected:  TRUE means the device is connected, false means the device is not connected
 * returns:  0
 */
int StatusBarShowConnection(BOOL connected)
{
    char a[60];
    if (connected)
    {
        LoadString(hInstance, STATUS_CONNECTED, a, 60);
        SendMessage(g_hStatusBar, SB_SETICON, 0, (LPARAM) hGreDot);
        SendMessage(g_hStatusBar, SB_SETTIPTEXT, 0, (LPARAM) &a);
    }
    else
    {
        LoadString(hInstance, STATUS_NOT_CONNECTED, a, 60);
        SendMessage(g_hStatusBar, SB_SETICON, 0, (LPARAM) hRedDot);
        SendMessage(g_hStatusBar, SB_SETTIPTEXT, 0, (LPARAM) &a);
    }
    return 0;
}

/* Create the application toolbar
 * hwnd:  the handle of the main window
 * returns:  the handle of the toolbar
 */
HWND ToolBarCreate(HWND hwnd)
{
    HWND hwndTB;
    HIMAGELIST himglst;
    HBITMAP hbmp;
    TBBUTTON tbb[TBBUTTONNUM];
    int toolbar_sepPos[] = {4, 8, 14, 17, 20, 24};   //seperator positions
    int imgres[] = {SAVEBMP,
        SAVESETBMP,
        OPENSETBMP,
        LOG_OFFBMP,
        MODE_RUNBMP,
        MODE_SINGLEBMP,
        MODE_HOLDBMP,
        RECON_SPLINEBMP,
        RECON_TRIBMP,
        RECON_SQUBMP,
        RECON_PNTBMP,
        RECON_SINBMP,
        VIEW_VTBMP,
        VIEW_XYBMP,
        VIEW_LINBMP,
        VIEW_LOGBMP,
        TRIG_POSBMP,
        TRIG_NEGBMP,
        TRIG_OFFBMP,
        LOG_ONBMP};
    int buttoncom[] = {CM_SAVEWAVEFORM,
        CM_SAVESETUP,
        CM_OPENSETUP,
        CM_LOGGING,
        CM_MODE_RUN,
        CM_MODE_SINGLE,
        CM_MODE_HOLD,
        CM_RECON_SPLINE,
        CM_RECON_TRI,
        CM_RECON_SQU,
        CM_RECON_PNT,
        CM_RECON_SIN,
        CM_VIEW_VT,
        CM_VIEW_XY,
        CM_VIEW_LIN,
        CM_VIEW_LOG,
        CM_TRIG_POS,
        CM_TRIG_NEG,
        CM_TRIG_OFF};
    int i, j, k;

    // Create a toolbar.
    hwndTB = CreateWindowEx(0, TOOLBARCLASSNAME, (LPSTR) NULL,
         WS_CHILD | TBSTYLE_FLAT | TBSTYLE_WRAPABLE | TBSTYLE_TOOLTIPS | WS_CLIPSIBLINGS, 0, 0, 0, 0, hwnd,
         (HMENU) ID_TOOLBAR, hInstance, NULL);

    // Send the TB_BUTTONSTRUCTSIZE message, which is required for backward compatibility.
    SendMessage(hwndTB, TB_BUTTONSTRUCTSIZE, (WPARAM) sizeof(TBBUTTON), 0);

    //Create imagelist
    himglst = ImageList_Create(TBIMGX, TBIMGY, ILC_MASK | ILC_COLOR24, 0, 4);

    for(i = 0; i < TBIMGNUM; i++)
    {
        hbmp = LoadImage(hInstance, MAKEINTRESOURCE(imgres[i]), IMAGE_BITMAP, 0, 0, LR_DEFAULTCOLOR);
        ImageList_AddMasked(himglst, hbmp, TBTRANSCOLOR);
    }

    SendMessage(hwndTB, TB_SETBUTTONSIZE, 0, (LPARAM) MAKELONG (TBIMGX+16, TBIMGY+18));
    SendMessage(hwndTB, TB_SETIMAGELIST, 0, (LPARAM) himglst);

    j = 0;

    for (i = 0; i < TBBUTTONNUM; i++)
    {
        tbb[i].iBitmap = j;
        tbb[i].idCommand = buttoncom[j];
        tbb[i].fsState = TBSTATE_ENABLED;
        tbb[i].fsStyle = TBSTYLE_BUTTON;
        tbb[i].dwData = 0;
        tbb[i].iString = 0;
        for(k = 0; k < TBSEPARATORS; k++)
        {
            if (i == toolbar_sepPos[k])
            {
                tbb[i].fsStyle = TBSTYLE_SEP;
                tbb[i].idCommand = 0;
                tbb[i].iBitmap = (int) NULL;
                j--;
            }
        }
        j++;
    }

    SendMessage(hwndTB, TB_ADDBUTTONS, TBBUTTONNUM, (LPARAM) (LPTBBUTTON) &tbb);

    SendMessage(hwndTB, TB_AUTOSIZE, 0, 0);
    SendMessage(hwndTB, TB_SETBUTTONSIZE, 0, (LPARAM) MAKELONG (TBIMGX+8, TBIMGY+10));

    ShowWindow(hwndTB, SW_SHOW);

    DeleteObject(hbmp);
    return hwndTB;

}

/* Creates the main window
 * hwnd:  the handle to the main window
 * returns: 0
 */
int MainWindowCreate(HWND hwnd)
{
    HBRUSH scopeBrush;
    RECT mainRect, statusRect, toolRect, panelRect;
    int ht, tp, bt, hta, wa, wb;
    INITCOMMONCONTROLSEX icex;
    WNDCLASSEX wincl;
    char scopeClassName[ ] = "scope";

    //Load Common controls
    icex.dwSize = sizeof(INITCOMMONCONTROLSEX);
    icex.dwICC  = ICC_BAR_CLASSES;
    InitCommonControlsEx(&icex);

    //Create toolbar and status bar
    g_hToolBar = ToolBarCreate(hwnd);
    g_hStatusBar = StatusBarCreate(hwnd);

    /* Create the side panel */
    g_hPanel = CreateDialog(hInstance, "PANEL", hwnd, PanelProc);

    //Create waveform screens
    GetClientRect(hwnd, &mainRect);
    GetWindowRect(g_hStatusBar, &statusRect);
    GetWindowRect(g_hToolBar, &toolRect);
    GetWindowRect(g_hPanel, &panelRect);

    /* Create a window class for the scope screens */
    /* Declare the Window structure */
    wincl.hInstance = hInstance;
    wincl.lpszClassName = scopeClassName;
    wincl.lpfnWndProc = oscDispProc;                     /* This function is called by windows */
    wincl.style = CS_DBLCLKS | CS_HREDRAW | CS_VREDRAW;                 /* Catch double-clicks */
    wincl.cbSize = sizeof(WNDCLASSEX);
    wincl.hIcon = NULL;
    wincl.hIconSm = NULL;
    spCursor = LoadCursor(hInstance, MAKEINTRESOURCE(CROSSHAIR));
    spbCursor = LoadCursor(hInstance, MAKEINTRESOURCE(CURMOVE));
    spcCursor = LoadCursor(hInstance, MAKEINTRESOURCE(CURYMOVE));
    spdCursor = LoadCursor(hInstance, MAKEINTRESOURCE(CURXMOVE));
    wincl.hCursor = spCursor;
    wincl.lpszMenuName = NULL;
    wincl.cbClsExtra = 0;                      /* No extra bytes after the window class */
    wincl.cbWndExtra = 0;                      /* structure or the window instance */
    scopeBrush = CreateSolidBrush(SCRCOLOR);        /* Near black */
    wincl.hbrBackground = scopeBrush;               /* Near Black */

    /* Register the window class */
   if (!RegisterClassEx (&wincl))
        return 0;

    tp = toolRect.bottom - toolRect.top;
    bt = mainRect.bottom - statusRect.bottom + statusRect.top - 5;
    ht = bt - tp;
    hta = (ht - 5)*2/3;
    wa = mainRect.right - 15 - panelRect.right + panelRect.left;
    wb = (wa - 5) / 2;
    g_hScreenMain = CreateWindowEx(0, scopeClassName, NULL,
        WS_CHILD | WS_CLIPSIBLINGS | WS_VISIBLE | SS_BLACKRECT,
        5, tp, wa, hta,
        hwnd, NULL, hInstance, NULL);
    g_hScreenA = CreateWindowEx(0, scopeClassName, NULL,
        WS_CHILD | WS_CLIPSIBLINGS | WS_VISIBLE | SS_BLACKRECT,
        5, 5 + tp + hta, wb, hta/2,
        hwnd, NULL, hInstance, NULL);
    g_hScreenB = CreateWindowEx(0, scopeClassName, NULL,
        WS_CHILD | WS_CLIPSIBLINGS | WS_VISIBLE | SS_BLACKRECT,
        wb+10, 5 + tp + hta, wb, hta/2,
        hwnd, NULL, hInstance, NULL);
    MoveWindow(g_hPanel, wa+10, tp, panelRect.right - panelRect.left, ht, TRUE);
    ShowWindow(g_hPanel, SW_SHOW);

    return 1;
}

/* Closes the main window
 * hwnd:  the handle to the main window
 * returns: 0
 */
int MainWindowClose(HWND hwnd)
{
    //Delete the toolbar
    ImageList_Destroy((HIMAGELIST) SendMessage(g_hToolBar, TB_GETIMAGELIST, 0, 0));   // Delete the image list
    DeleteObject(g_hToolBar);
    //Delete the statusbar
    DeleteObject(g_hStatusBar);
    DestroyIcon(hRedDot);
    DestroyIcon(hGreDot);
    //Destroy the window, all child windows will also be destroyed here.
    DestroyWindow(hwnd);
    return 0;
}

/* Resizes the main window
 * hwnd:  the handle to the main window
 * returns: 0
 */
int MainWindowResize(HWND hwnd)
{
    RECT mainRect, statusRect, toolRect, panelRect;
    int ht, tp, bt, hta, wa, wb;

    SendMessage(g_hToolBar, TB_AUTOSIZE, 0, 0);     /* Size toolbar */
    SendMessage(g_hStatusBar, WM_SIZE, 0, 0);       /* Size status bar */
    StatusBarSetParts(g_hStatusBar);

    GetClientRect(hwnd, &mainRect);
    GetWindowRect(g_hStatusBar, &statusRect);
    GetWindowRect(g_hToolBar, &toolRect);
    GetWindowRect(g_hPanel, &panelRect);

    tp = toolRect.bottom - toolRect.top;
    bt = mainRect.bottom - statusRect.bottom + statusRect.top - 5;
    ht = bt - tp;
    if (ht < 0) ht = 0;
    hta = (ht - 5)*2/3;
    if (hta < 0) hta = 0;
    wa = mainRect.right - 15 - panelRect.right + panelRect.left;
    if (wa < 0) wa = 0;
    wb = (wa - 5) / 2;
    if (wb < 0) wb = 0;

    MoveWindow(g_hScreenMain, 5, tp, wa, hta, TRUE);
    MoveWindow(g_hScreenA, 5, 5 + tp + hta, wb, hta/2, TRUE);
    MoveWindow(g_hScreenB, wb+10, 5 + tp + hta, wb, hta/2, TRUE);
    MoveWindow(g_hPanel, wa+10, tp, panelRect.right - panelRect.left, ht, TRUE);
    return 0;
}

int MainWindowRefresh(HWND hwnd)
{
    /* Set up the main menu */
    if(dispmode & MODE_XY)
    {
        CheckMenuRadioItem(GetMenu(hwnd), CM_VIEW_VT, CM_VIEW_XY,
           CM_VIEW_XY, MF_BYCOMMAND);
        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_VIEW_VT, FALSE);
        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_VIEW_XY, TRUE);
    }
    else
    {
        CheckMenuRadioItem(GetMenu(hwnd), CM_VIEW_VT, CM_VIEW_XY,
           CM_VIEW_VT, MF_BYCOMMAND);
        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_VIEW_VT, TRUE);
        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_VIEW_XY, FALSE);
    }

    if(dispmode & MODE_FREQMAGLOG)
    {
        CheckMenuRadioItem(GetMenu(hwnd), CM_VIEW_LIN, CM_VIEW_LOG,
           CM_VIEW_LOG, MF_BYCOMMAND);
        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_VIEW_LIN, FALSE);
        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_VIEW_LOG, TRUE);
    }
    else
    {
        CheckMenuRadioItem(GetMenu(hwnd), CM_VIEW_LIN, CM_VIEW_LOG,
           CM_VIEW_LIN, MF_BYCOMMAND);
        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_VIEW_LIN, TRUE);
        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_VIEW_LOG, FALSE);
    }

    if(getHighResolution())
        CheckMenuItem(GetMenu(hwnd), CM_WAVEFORM_HIGH_RES, MF_CHECKED);
    else
        CheckMenuItem(GetMenu(hwnd), CM_WAVEFORM_HIGH_RES, MF_UNCHECKED);

    if(getRepetitive())
        CheckMenuItem(GetMenu(hwnd), CM_CONFIG_SAMPLE_TIMEEQUIV, MF_CHECKED);
    else
        CheckMenuItem(GetMenu(hwnd), CM_CONFIG_SAMPLE_TIMEEQUIV, MF_UNCHECKED);


    if(dispmode & MODE_STOP)
    {
        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_MODE_RUN, FALSE);
        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_MODE_SINGLE, TRUE);
    }
    else
    {
        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_MODE_RUN, TRUE);
        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_MODE_SINGLE, FALSE);
    }
    if(dispmode & MODE_HOLD)
    {
        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_MODE_HOLD, TRUE);
    }
    else
    {
        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_MODE_HOLD, FALSE);
    }

    switch(reconst)
    {
    case RECONST_TRIANGLE:
        CheckMenuRadioItem(GetMenu(hwnd), CM_RECON_SPLINE, CM_RECON_SIN,
            CM_RECON_TRI, MF_BYCOMMAND);
        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_SPLINE, FALSE);
        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_TRI, TRUE);
        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_SIN, FALSE);
        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_SQU, FALSE);
        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_PNT, FALSE);
        break;
    case RECONST_SINC:
        CheckMenuRadioItem(GetMenu(hwnd), CM_RECON_SPLINE, CM_RECON_SIN,
            CM_RECON_SIN, MF_BYCOMMAND);
        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_SPLINE, FALSE);
        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_TRI, FALSE);
        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_SIN, TRUE);
        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_SQU, FALSE);
        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_PNT, FALSE);
        break;
    case RECONST_SQUARE:
        CheckMenuRadioItem(GetMenu(hwnd), CM_RECON_SPLINE, CM_RECON_SIN,
            CM_RECON_SQU, MF_BYCOMMAND);
        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_SPLINE, FALSE);
        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_TRI, FALSE);
        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_SIN, FALSE);
        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_SQU, TRUE);
        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_PNT, FALSE);
        break;
    case RECONST_POINT:
        CheckMenuRadioItem(GetMenu(hwnd), CM_RECON_SPLINE, CM_RECON_SIN,
            CM_RECON_PNT, MF_BYCOMMAND);
        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_SPLINE, FALSE);
        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_TRI, FALSE);
        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_SIN, FALSE);
        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_SQU, FALSE);
        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_PNT, TRUE);
        break;
    case RECONST_BEZIER:
        CheckMenuRadioItem(GetMenu(hwnd), CM_RECON_SPLINE, CM_RECON_SIN,
            CM_RECON_SPLINE, MF_BYCOMMAND);
        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_SPLINE, TRUE);
        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_TRI, FALSE);
        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_SIN, FALSE);
        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_SQU, FALSE);
        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_RECON_PNT, FALSE);
        break;
    }
    if(getEnableTrigger())
        if(getTriggerSlope())
        {
            CheckMenuRadioItem(GetMenu(hwnd), CM_TRIG_POS, CM_TRIG_OFF,
                CM_TRIG_POS, MF_BYCOMMAND);
            SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_TRIG_POS, TRUE);
            SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_TRIG_NEG, FALSE);
            SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_TRIG_OFF, FALSE);
        }
        else
        {
            CheckMenuRadioItem(GetMenu(hwnd), CM_TRIG_POS, CM_TRIG_OFF,
                CM_TRIG_NEG, MF_BYCOMMAND);
            SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_TRIG_POS, FALSE);
            SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_TRIG_NEG, TRUE);
            SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_TRIG_OFF, FALSE);
        }
    else
    {
        CheckMenuRadioItem(GetMenu(hwnd), CM_TRIG_POS, CM_TRIG_OFF,
            CM_TRIG_OFF, MF_BYCOMMAND);
        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_TRIG_POS, FALSE);
        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_TRIG_NEG, FALSE);
        SendMessage(g_hToolBar, TB_CHECKBUTTON, CM_TRIG_OFF, TRUE);
    }
}

/* Displays the tooltip over the toolbar button
 * hwnd:  the handle to the main window
 * returns: 0
 */
int ToolbarTooltip(LPARAM lParam)
{
    UINT idButton;
    LPTOOLTIPTEXT lpttt;

    lpttt = (LPTOOLTIPTEXT) lParam;     // Cast
    idButton = lpttt->hdr.idFrom;       // Get command id

    if((idButton >= TB_CM_MIN) & (idButton <= TB_CM_MAX))
    {
        lpttt->hinst = hInstance;           // Set instance
        lpttt->lpszText = MAKEINTRESOURCE(idButton+TOOLTIP_OFFSET);  // Point to tooltip resource
    }
    return 0;
}

/* Displays the status bar description for the toolbar button
 * hwnd:  the handle to the main window
 * returns: 0
 */
int ToolbarStatusMsg(LPARAM lParam)
{
    int idButton;
    char a[80];
    LPNMTBHOTITEM lpttt;

    lpttt = (LPNMTBHOTITEM) lParam;

    // Specify the resource identifier of the descriptive
    // text for the given button.
    idButton = lpttt->idNew;
    // sprintf(a, "%d", idButton);
    // SendMessage(g_hStatusBar, SB_SETTEXT, 2, a);
    LoadString(hInstance, idButton + STATUS_OFFSET, a, 80);
    SendMessage(g_hStatusBar, SB_SETTEXT, STATUSMSGBIN, (LPARAM) a);
    return 0;
}

/* Displays a message on the status bar when the mouse is over a main menu item
 * wParam: the wParam passed to the message in the windows procedure
 * return: 0
 */
int MenuStatusMsg(WPARAM wParam)
{
    char a[80];
    int idMenuItem;
    idMenuItem = LOWORD(wParam);
    LoadString(hInstance, idMenuItem + STATUS_OFFSET, a, 80);
    SendMessage(g_hStatusBar, SB_SETTEXT, STATUSMSGBIN, (LPARAM) a);
    return 0;
}

int MapChHelper(char chMakeup, double channel1[], double channel2[], double channelout[])
{
    int i;
    switch(chMakeup)
    {
    case CH1ONLY:
        for(i = 0; i < BUFFER_MAX; i++)
            channelout[i] = channel1[i];
        break;
    case CH2ONLY:
        for(i = 0; i < BUFFER_MAX; i++)
            channelout[i] = channel2[i];
        break;
    case NEGCH1ONLY:
        for(i = 0; i < BUFFER_MAX; i++)
            channelout[i] = -channel1[i];
        break;
    case NEGCH2ONLY:
        for(i = 0; i < BUFFER_MAX; i++)
            channelout[i] = -channel2[i];
        break;
    case CH1PLUSCH2:
        for(i = 0; i < BUFFER_MAX; i++)
            channelout[i] = channel1[i] + channel2[i];
        break;
    case NEGCH1PLUSCH2:
        for(i = 0; i < BUFFER_MAX; i++)
            channelout[i] = -(channel1[i] + channel2[i]);
        break;
    case CH1LESSCH2:
        for(i = 0; i < BUFFER_MAX; i++)
            channelout[i] = channel1[i] - channel2[i];
        break;
    case CH2LESSCH1:
        for(i = 0; i < BUFFER_MAX; i++)
            channelout[i] = channel2[i] - channel1[i];
        break;
    case CH1TIMESCH2:
        for(i = 0; i < BUFFER_MAX; i++)
            channelout[i] = channel1[i] * channel2[i];
        break;
    case NEGCH1TIMESCH2:
        for(i = 0; i < BUFFER_MAX; i++)
            channelout[i] = -channel1[i] * channel2[i];
        break;
    }
    return 0;
}

int  MapChannels(double channel1[], double channel2[], double channelA[], double channelB[], double channelC[], double channelD[])
{
    MapChHelper(chAmakeup, channel1, channel2, channelA);
    MapChHelper(chBmakeup, channel1, channel2, channelB);
    MapChHelper(chCmakeup, channelA, channelB, channelC);
    MapChHelper(chDmakeup, channelA, channelB, channelD);
}
