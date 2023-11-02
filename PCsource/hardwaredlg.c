/* ==============================================================================
 * Author:  Jonathan Weaver, jonw0224@aim.com
 * E-mail Contact: jonw0224@aim.com
 * Description:  Hardware Dialog Box.
 * Version: 2.18
 * Date: 1/17/2014
 * Filename:  hardwaredlg.c, hardwaredlg.h
 *
 * Versions History:
 *      2.01 - 4/29/2007 - Added hardware dialog
 *      2.18 - 1/17/2014 - Added COM ports 10 thru 19
 *
 * Copyright (C) 2007-2014 Jonathan Weaver
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
#include "hardwaredlg.h"
#include "parallel.h"
#include <stdio.h>

int updateHardwareModel(HWND hDlg, int portNumS, int tickCountS)
{
    HWND hctrl;
    switch(SendMessage(GetDlgItem(hDlg, HDWDLG_VERSION), CB_GETCURSEL, 0, 0))
    {
    case PPMSCOPE:
        EnableWindow(GetDlgItem(hDlg, HDWDLG_PORTTYPE), 1);
        break;
    case DSOSCOPE:
        EnableWindow(GetDlgItem(hDlg, HDWDLG_PORTTYPE), 0);
        SendMessage(GetDlgItem(hDlg, HDWDLG_PORTTYPE), CB_SETCURSEL, SERIALPORT-1, 0);
        updatePortType(hDlg, portNumS, tickCountS);
        break;
    }
}
int updatePortType(HWND hDlg, int portNumS, int tickCountS)
{
    char userStr[80];
    HWND hctrl;

    switch(SendMessage(GetDlgItem(hDlg, HDWDLG_PORTTYPE), CB_GETCURSEL, 0, 0)+1)
    {
    case PARALLELPORT:
        SendMessage(GetDlgItem(hDlg, HDWDLG_IODELAY_LABEL), WM_SETTEXT, 0, (LPARAM) "IO Delay");
        SendMessage(GetDlgItem(hDlg, HDWDLG_PORTADDRESS_LABEL), WM_SETTEXT, 0, (LPARAM) "Port Address");
        sprintf(userStr, "%d", tickCountS);
        SendMessage(GetDlgItem(hDlg, HDWDLG_IODELAY), WM_SETTEXT, 0, (LPARAM) userStr);
        EnableWindow(GetDlgItem(hDlg, HDWDLG_PORTADDRESS), 1);
        hctrl = GetDlgItem(hDlg, HDWDLG_PORT);
        SendMessage(hctrl, CB_RESETCONTENT, 0, 0);
        LoadString(hInstance, HDWDLG_PORT1NUM1, userStr, 80);
        SendMessage(hctrl, CB_ADDSTRING, 0, (LPARAM) userStr);
        LoadString(hInstance, HDWDLG_PORT1NUM2, userStr, 80);
        SendMessage(hctrl, CB_ADDSTRING, 0, (LPARAM) userStr);
        LoadString(hInstance, HDWDLG_PORT1NUM3, userStr, 80);
        SendMessage(hctrl, CB_ADDSTRING, 0, (LPARAM) userStr);
        LoadString(hInstance, HDWDLG_PORT1NUM4, userStr, 80);
        SendMessage(hctrl, CB_ADDSTRING, 0, (LPARAM) userStr);
        SendMessage(hctrl, CB_SETCURSEL, portNumS, 0);
        EnableWindow(GetDlgItem(hDlg, HDWDLG_TESTEN), 1);
        updatePortAddress(hDlg, portNumS);
        break;
    case SERIALPORT:
        SendMessage(GetDlgItem(hDlg, HDWDLG_IODELAY_LABEL), WM_SETTEXT, 0, (LPARAM) "Rx Timeout (mS)");
        sprintf(userStr, "%d", tickCountS);
        SendMessage(GetDlgItem(hDlg, HDWDLG_IODELAY), WM_SETTEXT, 0, (LPARAM) userStr);
        EnableWindow(GetDlgItem(hDlg, HDWDLG_PORTADDRESS), 0);
        SendMessage(GetDlgItem(hDlg, HDWDLG_PORTADDRESS_LABEL), WM_SETTEXT, 0, (LPARAM) "Configuration");
        SendMessage(GetDlgItem(hDlg, HDWDLG_PORTADDRESS), WM_SETTEXT, 0, (LPARAM) "57.6 kBaud, 8N1");
        hctrl = GetDlgItem(hDlg, HDWDLG_PORT);
        SendMessage(hctrl, CB_RESETCONTENT, 0, 0);
        LoadString(hInstance, HDWDLG_PORT2NUM1, userStr, 80);
        SendMessage(hctrl, CB_ADDSTRING, 0, (LPARAM) userStr);
        LoadString(hInstance, HDWDLG_PORT2NUM2, userStr, 80);
        SendMessage(hctrl, CB_ADDSTRING, 0, (LPARAM) userStr);
        LoadString(hInstance, HDWDLG_PORT2NUM3, userStr, 80);
        SendMessage(hctrl, CB_ADDSTRING, 0, (LPARAM) userStr);
        LoadString(hInstance, HDWDLG_PORT2NUM4, userStr, 80);
        SendMessage(hctrl, CB_ADDSTRING, 0, (LPARAM) userStr);
        LoadString(hInstance, HDWDLG_PORT2NUM5, userStr, 80);
        SendMessage(hctrl, CB_ADDSTRING, 0, (LPARAM) userStr);
        LoadString(hInstance, HDWDLG_PORT2NUM6, userStr, 80);
        SendMessage(hctrl, CB_ADDSTRING, 0, (LPARAM) userStr);
        LoadString(hInstance, HDWDLG_PORT2NUM7, userStr, 80);
        SendMessage(hctrl, CB_ADDSTRING, 0, (LPARAM) userStr);
        LoadString(hInstance, HDWDLG_PORT2NUM8, userStr, 80);
        SendMessage(hctrl, CB_ADDSTRING, 0, (LPARAM) userStr);
        LoadString(hInstance, HDWDLG_PORT2NUM9, userStr, 80);
        SendMessage(hctrl, CB_ADDSTRING, 0, (LPARAM) userStr);
        LoadString(hInstance, HDWDLG_PORT2NUM10, userStr, 80);
        SendMessage(hctrl, CB_ADDSTRING, 0, (LPARAM) userStr);
        LoadString(hInstance, HDWDLG_PORT2NUM11, userStr, 80);
        SendMessage(hctrl, CB_ADDSTRING, 0, (LPARAM) userStr);
        LoadString(hInstance, HDWDLG_PORT2NUM12, userStr, 80);
        SendMessage(hctrl, CB_ADDSTRING, 0, (LPARAM) userStr);
        LoadString(hInstance, HDWDLG_PORT2NUM13, userStr, 80);
        SendMessage(hctrl, CB_ADDSTRING, 0, (LPARAM) userStr);
        LoadString(hInstance, HDWDLG_PORT2NUM14, userStr, 80);
        SendMessage(hctrl, CB_ADDSTRING, 0, (LPARAM) userStr);
        LoadString(hInstance, HDWDLG_PORT2NUM15, userStr, 80);
        SendMessage(hctrl, CB_ADDSTRING, 0, (LPARAM) userStr);
        LoadString(hInstance, HDWDLG_PORT2NUM16, userStr, 80);
        SendMessage(hctrl, CB_ADDSTRING, 0, (LPARAM) userStr);
        LoadString(hInstance, HDWDLG_PORT2NUM17, userStr, 80);
        SendMessage(hctrl, CB_ADDSTRING, 0, (LPARAM) userStr);
        LoadString(hInstance, HDWDLG_PORT2NUM18, userStr, 80);
        SendMessage(hctrl, CB_ADDSTRING, 0, (LPARAM) userStr);
        LoadString(hInstance, HDWDLG_PORT2NUM19, userStr, 80);
        SendMessage(hctrl, CB_ADDSTRING, 0, (LPARAM) userStr);
        SendMessage(hctrl, CB_SETCURSEL, portNumS, 0);
        EnableWindow(GetDlgItem(hDlg, HDWDLG_TESTEN), 0);
        break;
    case USBPORT:
        break;
    }
}

int enableTesting(HWND hDlg, int en)
{
    EnableWindow(GetDlgItem(hDlg, HDWDLG_PORTTYPE), !en);
    EnableWindow(GetDlgItem(hDlg, HDWDLG_PORT), !en);
    EnableWindow(GetDlgItem(hDlg, HDWDLG_IODELAY), !en);
    updatePortAddress(hDlg, SendMessage(GetDlgItem(hDlg, HDWDLG_PORT), CB_GETCURSEL, 0, 0));

    EnableWindow(GetDlgItem(hDlg, HDWDLG_DATAHIGH), en);
    EnableWindow(GetDlgItem(hDlg, HDWDLG_DATALOW), en);
    EnableWindow(GetDlgItem(hDlg, HDWDLG_DATASTATE), en);

    EnableWindow(GetDlgItem(hDlg, HDWDLG_DATAINSTATE), en);

    EnableWindow(GetDlgItem(hDlg, HDWDLG_CLOCKHIGH), en);
    EnableWindow(GetDlgItem(hDlg, HDWDLG_CLOCKLOW), en);
    EnableWindow(GetDlgItem(hDlg, HDWDLG_CLOCKSTATE), en);

    return 0;
}

int updateHDriver(HWND hDlg)
{
    unsigned char hwMod;
    int pType, portNum, tickCount, buffSz;
    char conf[8];
    char userStr[80];
    char* endptr;
    HWND hctrl;

    hDriverGetConfig(&pType, &portNum, &tickCount, conf, &buffSz);
    hctrl = GetDlgItem(hDlg, HDWDLG_PORTTYPE);
    pType = SendMessage(hctrl, CB_GETCURSEL, 0, 0) + 1;
    hctrl = GetDlgItem(hDlg, HDWDLG_PORT);
    portNum = SendMessage(hctrl, CB_GETCURSEL, 0, 0);
    hctrl = GetDlgItem(hDlg, HDWDLG_IODELAY);
    GetWindowText(hctrl, userStr, GetWindowTextLength(hctrl) + 1);
    tickCount = (int) (strtod(userStr, &endptr));
    setHardwareModel(SendMessage(GetDlgItem(hDlg, HDWDLG_VERSION), CB_GETCURSEL, 0, 0));
    hDriverSetConfig(pType, portNum, tickCount, conf, buffSz);
    hDriverInitialize();
    return 0;
}

int updateAllStates(HWND hDlg, int portNum)
{
    short portCtrl;
    char portPin, portSet, portReset;
    char dataIn;
    pinMap(1, &portCtrl, &portPin, &portSet, &portReset); /* data */
    updateState(GetDlgItem(hDlg, HDWDLG_DATASTATE), (portSet == getBit(portNum, portCtrl, portPin)));
    pinMap(4, &portCtrl, &portPin, &portSet, &portReset); /* clk */
    updateState(GetDlgItem(hDlg, HDWDLG_CLOCKSTATE), (portSet == getBit(portNum, portCtrl, portPin)));
    pinMap(11, &portCtrl, &portPin, &portSet, &portReset); /* datain */
    dataIn = (portSet == getBit(portNum, portCtrl, portPin));
    updateState(GetDlgItem(hDlg, HDWDLG_DATAINSTATE), dataIn);
    SendMessage(GetDlgItem(hDlg, HDWDLG_DATAINHIGH), BM_SETCHECK, dataIn, 0);
    SendMessage(GetDlgItem(hDlg, HDWDLG_DATAINLOW), BM_SETCHECK, !dataIn, 0);
return 0;
}

int updateState(HWND hctrl, int state)
{
    if(state)
        SendMessage(hctrl, WM_SETTEXT, 0, (LPARAM) "H");
    else
        SendMessage(hctrl, WM_SETTEXT, 0, (LPARAM) "L");
    return 0;
}

int updatePortAddress(HWND hDlg, int a)
{
    char userStr[20];
    EnableWindow(GetDlgItem(hDlg, HDWDLG_PORTADDRESS), 0);
    if(SendMessage(GetDlgItem(hDlg, HDWDLG_PORTTYPE), CB_GETCURSEL, 0, 0) == 0)
    {
        sprintf(userStr, "0x%X", portAdr(a));
        SendMessage(GetDlgItem(hDlg, HDWDLG_PORTADDRESS), WM_SETTEXT, 0, (LPARAM) userStr);
        EnableWindow(GetDlgItem(hDlg, HDWDLG_PORTADDRESS), (a == LPTCUSTOM));
    }
    return 0;
}

/* Processes messages for the Hardware dialog box */
BOOL CALLBACK HardwareDlgProc (HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
    HWND hctrl;
    int pType, portNum, tickCount, buffSz;
    static int pTypeS, portNumS, tickCountS;
    char conf[8], userStr[80];
    int a, i;
    short portCtrl;
    char portPin, portSet, portReset;
    char *p;

    switch (message)
    {
    case WM_INITDIALOG:
        /* Initialize comboboxes */
        hctrl = GetDlgItem(hDlg, HDWDLG_VERSION);
        LoadString(hInstance, HDWDLG_HDWTYPE1, userStr, 80);
        SendMessage(hctrl, CB_ADDSTRING, 0, (LPARAM) userStr);
        LoadString(hInstance, HDWDLG_HDWTYPE2, userStr, 80);
        SendMessage(hctrl, CB_ADDSTRING, 0, (LPARAM) userStr);
        SendMessage(hctrl, CB_SETCURSEL, getHardwareModel(), 0);
        hDriverGetConfig(&pTypeS, &portNumS, &tickCountS, conf, &buffSz);
        hctrl = GetDlgItem(hDlg, HDWDLG_PORTTYPE);
        LoadString(hInstance, HDWDLG_PORTTYPECHOICE1, userStr, 80);
        SendMessage(hctrl, CB_ADDSTRING, 0, (LPARAM) userStr);
        LoadString(hInstance, HDWDLG_PORTTYPECHOICE2, userStr, 80);
        SendMessage(hctrl, CB_ADDSTRING, 0, (LPARAM) userStr);
        SendMessage(hctrl, CB_SETCURSEL, pTypeS - 1, 0);

        enableTesting(hDlg, 0);
        updateHardwareModel(hDlg, portNumS, tickCountS);
        updatePortType(hDlg, portNumS, tickCountS);
        updatePortAddress(hDlg, portNumS);
        EnableWindow(GetDlgItem(hDlg, HDWDLG_DATAINHIGH), 0);
        EnableWindow(GetDlgItem(hDlg, HDWDLG_DATAINLOW), 0);

        return TRUE;
    case WM_COMMAND:
        switch (LOWORD (wParam))
        {
        case HDWDLG_VERSION:
            if (HIWORD(wParam) == CBN_SELENDOK)
            {
                updateHardwareModel(hDlg, portNumS, tickCountS);
            }
            break;
        case HDWDLG_PORTTYPE:
            if (HIWORD(wParam) == CBN_SELENDOK)
            {
                updatePortType(hDlg, portNumS, tickCountS);
            }
            break;
        case HDWDLG_PORT:
            if (HIWORD(wParam) == CBN_SELENDOK)
            {
                updatePortAddress(hDlg, SendMessage(GetDlgItem(hDlg, HDWDLG_PORT), CB_GETCURSEL, 0, 0));
            }
            break;
        case HDWDLG_PORTADDRESS:
            if(HIWORD(wParam) == EN_KILLFOCUS)
            {
                hctrl = GetDlgItem(hDlg, LOWORD(wParam));
                i = GetWindowTextLength(hctrl);
                GetWindowText(hctrl, userStr, i + 1);
                a = strtol(userStr, &p, 16);
                setPortAdr(SendMessage(GetDlgItem(hDlg, HDWDLG_PORT), CB_GETCURSEL, 0, 0), a);
            }
            break;
        case HDWDLG_TESTEN:
            hctrl = GetDlgItem(hDlg, LOWORD(wParam));
            a = !SendMessage(hctrl, BM_GETCHECK, 0, 0);
            SendMessage(hctrl, BM_SETCHECK, a, 0);
            if(a)
            {
                updateHDriver(hDlg);
                enableTesting(hDlg, 1);
                hDriverGetConfig(&pType, &portNum, &tickCount, conf, &buffSz);
                updateAllStates(hDlg, portNum);
            }
            else
            {
                enableTesting(hDlg, 0);
            }
            break;
        case HDWDLG_DATAHIGH:
            hctrl = GetDlgItem(hDlg, HDWDLG_DATAHIGH);
            SendMessage(hctrl, BM_SETCHECK, 1, 0);
            SendMessage(GetDlgItem(hDlg, HDWDLG_DATALOW), BM_SETCHECK, 0, 0);

            hDriverGetConfig(&pType, &portNum, &tickCount, conf, &buffSz);
            if(pType == PARALLELPORT)
            {
                pinMap(1, &portCtrl, &portPin, &portSet, &portReset); /* data */
                setBit(portNum, portCtrl, portPin, portSet);
                updateAllStates(hDlg, portNum);
            }
            break;
        case HDWDLG_DATALOW:
            hctrl = GetDlgItem(hDlg, HDWDLG_DATALOW);
            SendMessage(hctrl, BM_SETCHECK, 1, 0);
            SendMessage(GetDlgItem(hDlg, HDWDLG_DATAHIGH), BM_SETCHECK, 0, 0);

            hDriverGetConfig(&pType, &portNum, &tickCount, conf, &buffSz);
            if(pType == PARALLELPORT)
            {
                pinMap(1, &portCtrl, &portPin, &portSet, &portReset); /* data */
                setBit(portNum, portCtrl, portPin, portReset);
                updateAllStates(hDlg, portNum);
            }
            break;
        case HDWDLG_CLOCKHIGH:
            hctrl = GetDlgItem(hDlg, HDWDLG_CLOCKHIGH);
            SendMessage(hctrl, BM_SETCHECK, 1, 0);
            SendMessage(GetDlgItem(hDlg, HDWDLG_CLOCKLOW), BM_SETCHECK, 0, 0);

            hDriverGetConfig(&pType, &portNum, &tickCount, conf, &buffSz);
            if(pType == PARALLELPORT)
            {
                pinMap(4, &portCtrl, &portPin, &portSet, &portReset); /* data */
                setBit(portNum, portCtrl, portPin, portSet);
                updateAllStates(hDlg, portNum);
            }
            break;
        case HDWDLG_CLOCKLOW:
            hctrl = GetDlgItem(hDlg, HDWDLG_CLOCKLOW);
            SendMessage(hctrl, BM_SETCHECK, 1, 0);
            SendMessage(GetDlgItem(hDlg, HDWDLG_CLOCKHIGH), BM_SETCHECK, 0, 0);

            hDriverGetConfig(&pType, &portNum, &tickCount, conf, &buffSz);
            if(pType == PARALLELPORT)
            {
                pinMap(4, &portCtrl, &portPin, &portSet, &portReset); /* data */
                setBit(portNum, portCtrl, portPin, portReset);
                updateAllStates(hDlg, portNum);
            }
            break;
        case HDWDLG_OK:
            updateHDriver(hDlg);
            EndDialog(hDlg, 0);
            break;
        case HDWDLG_CANCEL:
            hDriverGetConfig(&pType, &portNum, &tickCount, conf, &buffSz);
            hDriverSetConfig(pTypeS, portNumS, tickCountS, conf, buffSz);
            hDriverInitialize();
            EndDialog(hDlg, 0);
            break;
        }
        return TRUE;
        break;
    case WM_CLOSE:
        EndDialog (hDlg, 0);
        break;
    case WM_DESTROY:
        break;
    }
    return FALSE;
}
