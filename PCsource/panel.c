/* ==============================================================================
 * Author:  Jonathan Weaver, jonw0224@aim.com
 * E-mail Contact: jonw0224@aim.com
 * Description:  Side panel window.
 * Version: 2.18
 * Date: 1/17/2014
 * Filename:  panel.c, panel.h
 *
 * Versions History:
 *      2.01 - 8/17/2006 - created files
 *      2.01 - 2/11/2009 - Modifications for using updown controls and window
 *                         themes.  Modifications for triggering and repetitive
 *                         or time equivalent sampling.
 *      2.12 - 3/31/2009 - Modifications for extended triggering.
 *      2.13 - 2/19/2010 - Modifications to button responses to the Math
 *                         functions.  Math functions are calculated at a change
 *                         not simply set to zero.
 *      2.14 - 1/31/2011 - Modified WM_REFRESHPANEL for color modifications.
 *      2.14 - 3/15/2011 - Modifications for time equivalent sampling checkbox
 *      2.15 - 6/13/2012 - Modified for accepting enter key for changes.
 *      2.15 - 6/15/2012 - Modified to make time per div, volt per div, volt
 *                         offset, and trigger delay modifiers public for use
 *                         by the main program in handling hotkeys.
 *      2.15 - 7/20/2012 - Modified for continous Time Per Division
 *      2.17 - 6/13/2013 - Modified for 1, 2, 5 sequence of coarse time per
 *                         division and volt per division adjustments.
 *      2.18 - 1/17/2014 - Modified for display of appropriate trigger level.
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

#include "main.h"
#include "engNum.h"

#include <stdio.h>

#define TRNOT 0
#define TRPOS 1
#define TRNEG 2

WNDPROC oldProc;

LRESULT CALLBACK EdProc(HWND, UINT, WPARAM, LPARAM);
HWND CreateToolTip(int toolID, HWND hDlg, WCHAR* pText);
HWND ChangeToolTip(HWND hwndTool, HWND hwndTip, HWND hDlg, WCHAR* pText);
int StatisticText(MEASURESTAT s, char* toRet);

HWND hTT[4];
char tipText[4][80];
int tipTextFocus;
int cursorDispCh[2];

// Draws a 3D shaded rectangle
// hDC: hDC to draw to
// x: upper left corner x position
// y: upper left corner y position
// x2: lower right corner x position
// y2: lower right corner y position
// hc1: color of outside highlight (on top and left)
// hc2: color of inside highlight
// sc1: color of outside shadow (on bottom and right)
// sc2: color of inside shadow
// return: 0
int ThreeDRect(HDC hDC, int x, int y, int x2, int y2,
    DWORD hc1, DWORD hc2, DWORD sc1, DWORD sc2)
{
    HPEN hPen1, hPen2;

    //Draw Outside 3D rectangle
    hPen1 = CreatePen(PS_SOLID, 0, sc2);
    hPen2 = CreatePen(PS_SOLID, 0, sc1);

    //Replaces commented code below
    //Shadow
    SelectObject(hDC, hPen1);
    MoveToEx(hDC, x, y, NULL);
    LineTo(hDC, x2, y);
    LineTo(hDC, x2, y2);
    LineTo(hDC, x, y2);
    LineTo(hDC, x, y);
    //Highlight
    SelectObject(hDC, hPen2);
    DeleteObject(hPen1);
    hPen1 = CreatePen(PS_SOLID, 0, hc1);
    SelectObject(hDC, hPen1);
    DeleteObject(hPen2);
    hPen2 = CreatePen(PS_SOLID, 0, hc2);
    MoveToEx(hDC, x+1, y+1, NULL);
    LineTo(hDC, x+1, y2-1);
    LineTo(hDC, x2-1, y2-1);
    LineTo(hDC, x2-1, y+1);
    LineTo(hDC, x+1, y+1);

    /*
    //Shadow
    SelectObject(hDC, hPen1);
    MoveToEx(hDC, x, y2, NULL);
    LineTo(hDC, x2, y2);
    LineTo(hDC, x2, y-1);
    MoveToEx(hDC, x2 - 1, y+1, NULL);
    SelectObject(hDC, hPen2);
    LineTo(hDC, x2 - 1, y2 - 1);
    LineTo(hDC, x, y2 - 1);
    DeleteObject(hPen1);
    //Highlight
    hPen1 = CreatePen(PS_SOLID, 0, hc1);
    SelectObject(hDC, hPen1);
    DeleteObject(hPen2);
    hPen2 = CreatePen(PS_SOLID, 0, hc2);
    LineTo(hDC, x, y);
    LineTo(hDC, x2, y);
    SelectObject(hDC, hPen2);
    MoveToEx(hDC, x2 - 2, y + 1, NULL);
    LineTo(hDC, x+1, y+1);
    LineTo(hDC, x+1, y2 - 1);
    */

    //Clean up
    SelectObject(hDC, GetStockObject(BLACK_PEN));
    DeleteObject(hPen1);
    DeleteObject(hPen2);
    return 0;
}


// Draws an up arrow
// hDC: where to draw
// return: 0
/*int DrawUpArrow(HDC hDC)
{
    MoveToEx(hDC, 3, 6, NULL);
    LineTo(hDC, 5, 4);
    LineTo(hDC, 6, 4);
    LineTo(hDC, 8, 6);
    LineTo(hDC, 4, 6);
    LineTo(hDC, 5, 5);
    LineTo(hDC, 7, 5);
    return 0;
}
*/

// Draws a down arrow
// hDC: where to draw
// return: 0
/* int DrawDownArrow(HDC hDC)
{
    MoveToEx(hDC, 3, 3, NULL);
    LineTo(hDC, 5, 5);
    LineTo(hDC, 6, 5);
    LineTo(hDC, 8, 3);
    LineTo(hDC, 4, 3);
    LineTo(hDC, 5, 4);
    LineTo(hDC, 7, 4);
    return 0;
}
*/

// Draws the custom buttons on the form and controls the repeat of some button
// messages
// hPnl: handle to the panel
// pdis: the LPDRAWITEMSTRUCT
// *clkState: a pointer to the click state of some buttons, used for timer
// *ctrl: a pointer to the command ID the timer message should send to the panel
int DrawCustomButtons(HWND hPnl, LPDRAWITEMSTRUCT pdis, int* clkState, int* ctrl)
{
    HBRUSH hBrush;
    RECT newRect;
    int cx, cy;
    char tstr[40];

    //Get dimensions
    cx = pdis->rcItem.right - pdis->rcItem.left-1;
    cy = pdis->rcItem.bottom - pdis->rcItem.top-1;
    switch (pdis->CtlID)
    {
    case DLG_UNUSED:
    case CM_CHA_COLOR:
    case CM_CHB_COLOR:
    case CM_CHC_COLOR:
    case CM_CHD_COLOR:
        ThreeDRect(pdis->hDC, 0, 0, cx, cy,
            GetSysColor(COLOR_3DHILIGHT),
            GetSysColor(COLOR_3DLIGHT),
            GetSysColor(COLOR_3DSHADOW),
            GetSysColor(COLOR_3DDKSHADOW));
        ThreeDRect(pdis->hDC, 2, 2, cx-2, cy-2,
            GetSysColor(COLOR_3DSHADOW),
            GetSysColor(COLOR_3DDKSHADOW),
            GetSysColor(COLOR_3DHILIGHT),
            GetSysColor(COLOR_3DLIGHT));
        if(pdis->CtlID == CM_CHA_COLOR)
            hBrush = CreateSolidBrush(oscGetColor(GETCOLORCHA));
        else if(pdis->CtlID == CM_CHB_COLOR)
            hBrush = CreateSolidBrush(oscGetColor(GETCOLORCHB));
        else if(pdis->CtlID == CM_CHC_COLOR)
            hBrush = CreateSolidBrush(oscGetColor(GETCOLORCHC));
        else if(pdis->CtlID == CM_CHD_COLOR)
            hBrush = CreateSolidBrush(oscGetColor(GETCOLORCHD));
        else
            hBrush = CreateSolidBrush(GetSysColor(COLOR_3DFACE));
        newRect.left = pdis->rcItem.left + 4;
        newRect.right = pdis->rcItem.right - 4;
        newRect.top = pdis->rcItem.top + 4;
        newRect.bottom = pdis->rcItem.bottom - 4;
        FillRect(pdis->hDC, &newRect, hBrush);
        DeleteObject(hBrush);
        SendMessage(pdis->hwndItem, WM_GETTEXT, 40, (LPARAM) tstr);
        SetBkMode(pdis->hDC, TRANSPARENT);
        DrawText(pdis->hDC, tstr, -1, &newRect, DT_CENTER | DT_VCENTER);
        break;
    default:
        if(pdis->itemState & ODS_SELECTED)
        {
            hBrush = CreateSolidBrush(GetSysColor(COLOR_3DFACE));
            FillRect(pdis->hDC, &pdis->rcItem, hBrush);
            DeleteObject(hBrush);
            hBrush = CreateSolidBrush(GetSysColor(COLOR_3DDKSHADOW));
            newRect.right = pdis->rcItem.right - 1;
            newRect.left = pdis->rcItem.left + 1;
            newRect.bottom = pdis->rcItem.bottom - 1;
            newRect.top = pdis->rcItem.top + 1;
            FrameRect(pdis->hDC, &newRect, hBrush);
            DeleteObject(hBrush);
            *ctrl = pdis->CtlID;
            *clkState = 1;
            SendMessage(hPnl, WM_COMMAND, *ctrl, 0);
        }
        else
        {
            ThreeDRect(pdis->hDC, 0, 0, cx, cy,
                GetSysColor(COLOR_3DHILIGHT),
                GetSysColor(COLOR_3DLIGHT),
                GetSysColor(COLOR_3DSHADOW),
                GetSysColor(COLOR_3DDKSHADOW));
            if(pdis->CtlID == *ctrl)
            {
                KillTimer(hPnl, 1);
                *clkState = 0;
            }
        }
        if(pdis->itemState & ODS_FOCUS)
        {
            hBrush = CreateSolidBrush(0x00202020);
            FrameRect(pdis->hDC, &pdis->rcItem, hBrush);
            DeleteObject(hBrush);
        }
        SelectObject(pdis->hDC, GetStockObject(BLACK_PEN));
    }
    return 0;
}


/*Refreshes the trigger drop down box*/
int refreshTrigger()
{
    if(getEnableTrigger())
        if(getTriggerSlope())
            SendMessage(GetDlgItem(g_hPanel, CB_TRIGGER_MODE), CB_SETCURSEL, TRPOS, 0);
        else
            SendMessage(GetDlgItem(g_hPanel, CB_TRIGGER_MODE), CB_SETCURSEL, TRNEG, 0);
    else
        SendMessage(GetDlgItem(g_hPanel, CB_TRIGGER_MODE), CB_SETCURSEL, TRNOT, 0);
    MainWindowRefresh(g_hMainWindow);
}

/* Refreshes the trigger delay */
int refreshTriggerDelay()
{
    refreshChOffsetHelper(GetDlgItem(g_hPanel, ED_TRIGGER_DELAY), getTriggerDelay());
    return 0;
}


/* Private helper to RefreshTimeDiv */
int refreshTimeDivHelper(HWND ctrlA, HWND ctrlB)
{
    char a[50];
    NumToEngStr(getTimePerDivision(), a);
    SendMessage(ctrlA, WM_SETTEXT, 0, (LPARAM) a);
    NumToEngStr(getSampleRate(), a);
    SendMessage(ctrlB, WM_SETTEXT, 0, (LPARAM) a);

    if(getRepetitive() == 1)
        SendMessage(GetDlgItem(g_hPanel, ST_TIME), WM_SETTEXT, 0, (LPARAM) "Time Eq Sampling");
    else if(getTrueXY() == 1)
        SendMessage(GetDlgItem(g_hPanel, ST_TIME), WM_SETTEXT, 0, (LPARAM) "Interlaced Sampling");
    else
        SendMessage(GetDlgItem(g_hPanel, ST_TIME), WM_SETTEXT, 0, (LPARAM) "Sequential Sampling");

    return 0;
}

/* Updates the time per division on the panel readout */
int RefreshTimeDiv()
{
    refreshTimeDivHelper(GetDlgItem(g_hPanel, ED_TIME_PER_DIV),
            GetDlgItem(g_hPanel, ED_SAMPLE_RATE));
    refreshTrigger();
    refreshTriggerDelay();
    return 0;
}

/* Private helper to refresh channel offset */
int refreshChOffsetHelper(HWND ctrl, double chOffset)
{
    char a[50];
    NumToEngStr(chOffset, a);
    SendMessage(ctrl, WM_SETTEXT, 0, (LPARAM) a);
    return 0;
}

/* Updates Channel B offset on the panel readout */
int RefreshChBOffset()
{
    refreshChOffsetHelper(GetDlgItem(g_hPanel, ED_VOLT_OFFSET_CHB),
        chBOffset);
    return 0;
}

/* Updates Channel A offset on the panel readout */
int RefreshChAOffset()
{
    refreshChOffsetHelper(GetDlgItem(g_hPanel, ED_VOLT_OFFSET_CHA),
        chAOffset);
    return 0;
}

/* Updates Channel C offset on the panel readout */
int RefreshChCOffset()
{
    refreshChOffsetHelper(GetDlgItem(g_hPanel, ED_VOLT_OFFSET_CHC),
        chCOffset);
    return 0;
}

/* Updates Channel D offset on the panel readout */
int RefreshChDOffset()
{
    refreshChOffsetHelper(GetDlgItem(g_hPanel, ED_VOLT_OFFSET_CHD),
        chDOffset);
    return 0;
}

/* Updates Channel A voltdiv on the panel readout */
int RefreshChAVoltDiv()
{
    refreshChOffsetHelper(GetDlgItem(g_hPanel, ED_VOLT_PER_DIV_CHA), chAVoltDiv);
    RefreshChAOffset();
    return 0;
}

/* Updates Channel B voltdiv on the panel readout */
int RefreshChBVoltDiv()
{
    refreshChOffsetHelper(GetDlgItem(g_hPanel, ED_VOLT_PER_DIV_CHB), chBVoltDiv);
    RefreshChBOffset();
    return 0;
}

/* Updates Channel B voltdiv on the panel readout */
int RefreshChCVoltDiv()
{
    refreshChOffsetHelper(GetDlgItem(g_hPanel, ED_VOLT_PER_DIV_CHC), chCVoltDiv);
    RefreshChCOffset();
    return 0;
}

/* Updates Channel B voltdiv on the panel readout */
int RefreshChDVoltDiv()
{
    refreshChOffsetHelper(GetDlgItem(g_hPanel, ED_VOLT_PER_DIV_CHD), chDVoltDiv);
    RefreshChDOffset();
    return 0;
}

/* Limits offset */
double limitOffset(double offset)
{
    if(offset >= 500)
        return 500;
    if(offset <= -500)
        return -500;
    return offset;
}

/* Limits volt per division */
double limitVoltPerDiv(double voltPerDiv)
{
    if(voltPerDiv >= 100)
        return 100;
    if(voltPerDiv <= 0.01)
        return 0.01;
    return voltPerDiv;
}

/* Set the trigger positive */
int setTriggerPos()
{
    double tpd;
    tpd = getTimePerDivision();
    enableTrigger(1);
    triggerSlope(1);
    refreshTrigger();
    setTimePerDiv(tpd);
    RefreshTimeDiv();
    return 0;
}

/* Set the trigger negative */
int setTriggerNeg()
{
    double tpd;
    tpd = getTimePerDivision();
    enableTrigger(1);
    triggerSlope(0);
    refreshTrigger();
    setTimePerDiv(tpd);
    RefreshTimeDiv();
    return 0;
}

/* Set the trigger off */
int setTriggerOff()
{
    double tpd;
    tpd = getTimePerDivision();
    enableTrigger(0);
    refreshTrigger();
    setTimePerDiv(tpd);
    RefreshTimeDiv();
    return 0;
}

int setCursorInfo(int windowType, double xval[2], double cha[2], double chb[2], double chc[2], double chd[2])
{
    double deltaxval, deltacha, deltachb;
    char a[80];
    char *b;

    switch(windowType)
    {
    case SCOPE_SCREEN:
        /* Headings */
        SendMessage(GetDlgItem(g_hPanel, ST_LABA), WM_SETTEXT, 0, (LPARAM) "T");
        SendMessage(GetDlgItem(g_hPanel, ST_LABB), WM_SETTEXT, 0, (LPARAM) "1/T");
        if(cursorDispCh[0]==0)
            SendMessage(GetDlgItem(g_hPanel, ST_LABC), WM_SETTEXT, 0, (LPARAM) "Ch A");
        else
            SendMessage(GetDlgItem(g_hPanel, ST_LABC), WM_SETTEXT, 0, (LPARAM) "Ch C");
        if(cursorDispCh[1]==0)
            SendMessage(GetDlgItem(g_hPanel, ST_LABD), WM_SETTEXT, 0, (LPARAM) "Ch B");
        else
            SendMessage(GetDlgItem(g_hPanel, ST_LABD), WM_SETTEXT, 0, (LPARAM) "Ch D");

        /* Cursor 1 */
        NumToEngStr(xval[0], a);
        for(b = a; *b; b++);
        *b++ = 's';
        *b = '\0';
        SendMessage(GetDlgItem(g_hPanel, ST_T_CUR1), WM_SETTEXT, 0, (LPARAM) a);
        if(xval[0] == 0)
            sprintf(a, "NAN");
        else
        {
            NumToEngStr(1/xval[0], a);
            for(b = a; *b; b++);
            *b++ = 'H';
            *b++ = 'z';
            *b = '\0';
        }
        SendMessage(GetDlgItem(g_hPanel, ST_P_CUR1), WM_SETTEXT, 0, (LPARAM) a);
        if(cursorDispCh[0]==0)
            NumToEngStr(cha[0], a);
        else
            NumToEngStr(chc[0], a);
        for(b = a; *b; b++);
        *b++ = 'V';
        *b = '\0';
        SendMessage(GetDlgItem(g_hPanel, ST_CHA_CUR1), WM_SETTEXT, 0, (LPARAM) a);
        if(cursorDispCh[1]==0)
            NumToEngStr(chb[0], a);
        else
            NumToEngStr(chd[0], a);
        for(b = a; *b; b++);
        *b++ = 'V';
        *b = '\0';
        SendMessage(GetDlgItem(g_hPanel, ST_CHB_CUR1), WM_SETTEXT, 0, (LPARAM) a);
        /* Cursor 2 */
        NumToEngStr(xval[1], a);
        for(b = a; *b; b++);
        *b++ = 's';
        *b = '\0';
        SendMessage(GetDlgItem(g_hPanel, ST_T_CUR2), WM_SETTEXT, 0, (LPARAM) a);
        if(xval[1] == 0)
            sprintf(a, "NAN");
        else
        {
            NumToEngStr(1/xval[1], a);
            for(b = a; *b; b++);
            *b++ = 'H';
            *b++ = 'z';
            *b = '\0';
        }
        SendMessage(GetDlgItem(g_hPanel, ST_P_CUR2), WM_SETTEXT, 0, (LPARAM) a);
        if(cursorDispCh[0]==0)
            NumToEngStr(cha[1], a);
        else
            NumToEngStr(chc[1], a);
        for(b = a; *b; b++);
        *b++ = 'V';
        *b = '\0';
        SendMessage(GetDlgItem(g_hPanel, ST_CHA_CUR2), WM_SETTEXT, 0, (LPARAM) a);
        if(cursorDispCh[1]==0)
            NumToEngStr(chb[1], a);
        else
            NumToEngStr(chd[1], a);
        for(b = a; *b; b++);
        *b++ = 'V';
        *b = '\0';
        SendMessage(GetDlgItem(g_hPanel, ST_CHB_CUR2), WM_SETTEXT, 0, (LPARAM) a);
        /* Delta */
        deltaxval = xval[0] - xval[1];
        if(cursorDispCh[0]==0)
            deltacha = cha[0] - cha[1];
        else
            deltacha = chc[0] - chc[1];
        if(cursorDispCh[1]==0)
            deltachb = chb[0] - chb[1];
        else
            deltachb = chd[0] - chd[1];
        SendMessage(GetDlgItem(g_hPanel, ST_CHB_DELTA), WM_SETTEXT, 0, (LPARAM) a);
        NumToEngStr(deltaxval, a);
        for(b = a; *b; b++);
        *b++ = 's';
        *b = '\0';
        SendMessage(GetDlgItem(g_hPanel, ST_T_DELTA), WM_SETTEXT, 0, (LPARAM) a);
        if(deltaxval == 0)
            sprintf(a, "NAN");
        else
        {
            NumToEngStr(1/deltaxval, a);
            for(b = a; *b; b++);
            *b++ = 'H';
            *b++ = 'z';
            *b = '\0';
        }
        SendMessage(GetDlgItem(g_hPanel, ST_P_DELTA), WM_SETTEXT, 0, (LPARAM) a);
        NumToEngStr(deltacha, a);
        for(b = a; *b; b++);
        *b++ = 'V';
        *b = '\0';
        SendMessage(GetDlgItem(g_hPanel, ST_CHA_DELTA), WM_SETTEXT, 0, (LPARAM) a);
        NumToEngStr(deltachb, a);
        for(b = a; *b; b++);
        *b++ = 'V';
        *b = '\0';
        SendMessage(GetDlgItem(g_hPanel, ST_CHB_DELTA), WM_SETTEXT, 0, (LPARAM) a);
        break;
    case SCOPE_FREQMAG:
    case SCOPE_FREQPHASE:
        /* Headings */
        SendMessage(GetDlgItem(g_hPanel, ST_LABA), WM_SETTEXT, 0, (LPARAM) "Freq");
        SendMessage(GetDlgItem(g_hPanel, ST_LABB), WM_SETTEXT, 0, (LPARAM) "1/Freq");
        SendMessage(GetDlgItem(g_hPanel, ST_LABC), WM_SETTEXT, 0, (LPARAM) "Magn");
        SendMessage(GetDlgItem(g_hPanel, ST_LABD), WM_SETTEXT, 0, (LPARAM) "Phase");
        /* Cursor 1 */
        NumToEngStr(xval[0], a);
        for(b = a; *b; b++);
        *b++ = 'H';
        *b++ = 'z';
        *b = '\0';
        SendMessage(GetDlgItem(g_hPanel, ST_T_CUR1), WM_SETTEXT, 0, (LPARAM) a);
        if(xval[0] == 0)
            sprintf(a, "NAN");
        else
        {
            NumToEngStr(1/xval[0], a);
            for(b = a; *b; b++);
            *b++ = 's';
            *b = '\0';
        }
        SendMessage(GetDlgItem(g_hPanel, ST_P_CUR1), WM_SETTEXT, 0, (LPARAM) a);
        NumToEngStr(cha[0], a);
        for(b = a; *b; b++);
        *b++ = 'V';
        *b = '\0';
        SendMessage(GetDlgItem(g_hPanel, ST_CHA_CUR1), WM_SETTEXT, 0, (LPARAM) a);
        NumToEngStr(chb[0], a);
        SendMessage(GetDlgItem(g_hPanel, ST_CHB_CUR1), WM_SETTEXT, 0, (LPARAM) a);
        /* Cursor 2 */
        NumToEngStr(xval[1], a);
        for(b = a; *b; b++);
        *b++ = 'H';
        *b++ = 'z';
        *b = '\0';
        SendMessage(GetDlgItem(g_hPanel, ST_T_CUR2), WM_SETTEXT, 0, (LPARAM) a);
        if(xval[1] == 0)
            sprintf(a, "NAN");
        else
        {
            NumToEngStr(1/xval[1], a);
            for(b = a; *b; b++);
            *b++ = 's';
            *b = '\0';
        }
        SendMessage(GetDlgItem(g_hPanel, ST_P_CUR2), WM_SETTEXT, 0, (LPARAM) a);
        NumToEngStr(cha[1], a);
        for(b = a; *b; b++);
        *b++ = 'V';
        *b = '\0';
        SendMessage(GetDlgItem(g_hPanel, ST_CHA_CUR2), WM_SETTEXT, 0, (LPARAM) a);
        NumToEngStr(chb[1], a);
        SendMessage(GetDlgItem(g_hPanel, ST_CHB_CUR2), WM_SETTEXT, 0, (LPARAM) a);
        /* Delta */
        deltaxval = xval[0] - xval[1];
        deltacha = cha[0] - cha[1];
        deltachb = chb[0] - chb[1];
        SendMessage(GetDlgItem(g_hPanel, ST_CHB_DELTA), WM_SETTEXT, 0, (LPARAM) a);
        NumToEngStr(deltaxval, a);
        for(b = a; *b; b++);
        *b++ = 'H';
        *b++ = 'z';
        *b = '\0';
        SendMessage(GetDlgItem(g_hPanel, ST_T_DELTA), WM_SETTEXT, 0, (LPARAM) a);
        if(deltaxval == 0)
            sprintf(a, "NAN");
        else
        {
            NumToEngStr(1/deltaxval, a);
            for(b = a; *b; b++);
            *b++ = 's';
            *b = '\0';
        }
        SendMessage(GetDlgItem(g_hPanel, ST_P_DELTA), WM_SETTEXT, 0, (LPARAM) a);
        NumToEngStr(deltacha, a);
        for(b = a; *b; b++);
        *b++ = 'V';
        *b = '\0';
        SendMessage(GetDlgItem(g_hPanel, ST_CHA_DELTA), WM_SETTEXT, 0, (LPARAM) a);
        NumToEngStr(deltachb, a);
        SendMessage(GetDlgItem(g_hPanel, ST_CHB_DELTA), WM_SETTEXT, 0, (LPARAM) a);
        break;
    }
    return 0;
}

/* Refreshes the XY check box and gives proper messages */
int refreshXYChkbox(HWND panel) {
    int a, i;
    HWND hctrl;
    hctrl = GetDlgItem(panel, CM_CONFIG_SAMPLE_INTERLACED);

    a = getTrueXY();
    if(a == 1)
        SendMessage(hctrl, BM_SETCHECK, 1, 0);
    else
        SendMessage(hctrl, BM_SETCHECK, 0, 0);

    i = SendMessage(hctrl, BM_GETCHECK, 0, 0);
    if(i == BST_CHECKED)
        SendMessage(GetDlgItem(panel, ST_TIME), WM_SETTEXT, 0, (LPARAM) "Interlaced Sampling");
    else
        SendMessage(GetDlgItem(panel, ST_TIME), WM_SETTEXT, 0, (LPARAM) "Sequential Sampling");
    return 0;
}

/* Updates the channel readouts using value returned by updateChannels */
int updateChannelMsg(int j)
{
    int ma, mb, dca, dcb, aa, ab;
    double gaina, gainb;

    char a[50];
    dca = (j & (1 << 5)) >> 5;  /* DC bit for channel 1 */
    dcb = (j & (1 << 4)) >> 4;  /* DC bit for channel 2 */
    aa = (j & (1 << 7)) >> 7;   /* Attenuator for channel 1 */
    ab = (j & (1 << 6)) >> 6;   /* Attenuator for channel 2 */
    ma = (j & 0xf000) >> 12;    /* Multiplier for channel 1 */
    mb = (j & 0x0f00) >> 8;     /* Multiplier for channel 2 */

    gaina = ma;
    if(aa)
        gaina = ((double) ma)/10.0;
    gainb = mb;
    if(ab)
        gainb = ((double) mb)/10.0;

    if(dca)
        sprintf(a, "%.1f X   AC Coupled", gaina);
    else
        sprintf(a, "%.1f X   DC Coupled", gaina);
    SendMessage(GetDlgItem(g_hPanel, ST_CHA), WM_SETTEXT, 0, (LPARAM) a);

    if(dcb)
        sprintf(a, "%.1f X   AC Coupled", gainb);
    else
        sprintf(a, "%.1f X   DC Coupled", gainb);
    SendMessage(GetDlgItem(g_hPanel, ST_CHB), WM_SETTEXT, 0, (LPARAM) a);

    return 0;
}


/* Update the Triggerlevel readout */
int updateTriggerLevel()
{
    double trig;
    char a[50];
    trig = getTriggerLevel(0);
    sprintf(a, "Trig lvl=");
    NumToEngStr(trig, &a[9]);
    SendMessage(GetDlgItem(g_hPanel, ST_TRIG), WM_SETTEXT, 0, (LPARAM) a);
}

/* Update the TriggerChannel readout */
int updateTriggerChannel()
{
    char a[50];
    sprintf(a, "Trig Source=Ch%d", getTriggerChannel());
    SendMessage(GetDlgItem(g_hPanel, ST_TRIG_SRC), WM_SETTEXT, 0, (LPARAM) a);
}

/* Set the math statistic to zero */
int resetMStat(int i)
{
    mStat[i].NumSamples = 0;
    mStat[i].average = 0;
    mStat[i].max = 0;
    mStat[i].min = 0;
    mStat[i].q = 0;
    mStat[i].stddev = 0;
    return 0;
}

/*Sets the time per division */
int setTimePerDiv(double tpd){
    double sr;
    //double tDlay;
    //tDlay = getTriggerDelay();
    dPrStr("setTimePerDiv:\nTime per Div:");
    dPrFlt(tpd);
    dPrStr("\nMaxSamplePerChannel:");
    dPrInt(getMaxSamplesPerChannel());
    dPrStr("\nMaxSampleRate:");
    dPrFlt(getMaxSampleRate());
    if(tpd < (getMaxSamplesPerChannel() - 1) / getMaxSampleRate() / DIVISIONSX)
    {
        dPrStr("SampleRateLimited\nSampleRate:");
        sr = setSampleRate(getMaxSampleRate());
        dPrFlt(sr);
        dPrStr("\nSamplesPerChannelSetting:");
        dPrInt(tpd*sr*DIVISIONSX+2);
        dPrStr("\nSamplesPerChannel:");
        setSamplesPerChannel(tpd*sr*DIVISIONSX+2);
        dPrInt(getSamplesPerChannel());
        dPrStr("\n");
    }
    else
    {
        dPrStr("\nSamplesPerChannelLimited\nSamplesPerChannel:");
        setSamplesPerChannel(getMaxSamplesPerChannel());
        dPrInt(getSamplesPerChannel());
        dPrStr("\nSampleRateSetting:");
        dPrFlt((getSamplesPerChannel() - 1)/tpd/DIVISIONSX);
        sr = setSampleRate((getSamplesPerChannel()-1)/tpd/DIVISIONSX);
        dPrStr("\nSampleRate:");
        dPrInt(getSampleRate());
        if((sr*tpd*((double) DIVISIONSX)) > getMaxSamplesPerChannel() - 1)
        {
            dPrStr("\nAdjustingSampleRate...\nSampleRate:");
            sampleRateChange(ADJ_FDECR);
            sr = getSampleRate();
            dPrFlt(sr);
        }
        dPrStr("\nSamplesPerChannelSetting:");
        dPrFlt(tpd*sr*DIVISIONSX+2);
        setSamplesPerChannel(tpd*sr*DIVISIONSX+2);
        dPrStr("\nSamplesPerChannel:");
        dPrInt(getSamplesPerChannel());
        dPrStr("\n");
    }
    //if(tDlay > 0)
    //    setTriggerDelay(tDlay*tpd/getTimePerDivision());
    setTimePerDivision(tpd);
    return 0;
}

/* Changes the time per division based on the push buttons */
int timePerDivChange(char adjust)
{
/*    int i;
    i =  getSamplesPerChannel();
    switch(adjust)
    {
    case ADJ_FINCR:
       if(getSampleRate() == getMaxSampleRate())
           setSamplesPerChannel(i*9/10);
       else
           sampleRateChange(ADJ_FINCR);
       break;
    case ADJ_FDECR:
       if(i == getMaxSamplesPerChannel())
           sampleRateChange(ADJ_FDECR);
       else
           setSamplesPerChannel(i*11/10);
       break;
    case ADJ_CINCR:
        if(getSampleRate() == getMaxSampleRate())
            setSamplesPerChannel(getSamplesPerChannel()/2);
        else
            sampleRateChange(ADJ_CINCR);
        break;
    case ADJ_CDECR:
        if(i == getMaxSamplesPerChannel())
            sampleRateChange(ADJ_CDECR);
         else
            setSamplesPerChannel(i*2);
         break;
    } */
    double tpd, a, j;
    switch(adjust)
    {
    case ADJ_FINCR:
       setTimePerDiv(getTimePerDivision()*9/10);
       break;
    case ADJ_FDECR:
       setTimePerDiv(getTimePerDivision()*11/10);
       break;
    case ADJ_CINCR:
       tpd = getTimePerDivision();
       a = 1.0;
       j = tpd;
       while(j >= 10)
       {
           j /= 10.0;
           a *= 10.0;
       }
       while(j < 1)
       {
           j *= 10.0;
           a /= 10.0;
       }
       if(j <= 1.0001)
           setTimePerDiv(0.5*a);
       else if(j <=2.0001)
           setTimePerDiv(a);
       else if(j <= 5.0001)
           setTimePerDiv(2*a);
       else
           setTimePerDiv(5*a);
       break;
    case ADJ_CDECR:
       tpd = getTimePerDivision();
       a = 1.0;
       j = tpd;
       while(j >= 10)
       {
           j /= 10.0;
           a *= 10.0;
       }
       while(j < 0.9999)
       {
           j *= 10.0;
           a /= 10.0;
       }
       if(j < 1.9999)
           setTimePerDiv(2*a);
       else if(j < 4.9999)
           setTimePerDiv(5*a);
       else
           setTimePerDiv(10*a);
       break;
    }
    refreshXYChkbox(g_hPanel);
    RefreshTimeDiv();
    //refreshScopeWindows(1);
    refreshScopeWindows(0);
    return 0;
}

int voltDivChange(char adjust, double tpd, double *voltDiv)
{
    double a, j;
    switch(adjust)
    {
    case ADJ_FDECR:
        *voltDiv = ((double) ((int) (90.0*(*voltDiv)+0.5)))/100.0;
        if((tpd - *voltDiv) < 0.005)
        *voltDiv = tpd - 0.01;
        break;
    case ADJ_FINCR:
        *voltDiv = ((double) ((int) (110.0*(*voltDiv)+0.5)))/100.0;
        if((*voltDiv - tpd) < 0.005)
            *voltDiv = tpd + 0.01;
        break;
    case ADJ_CDECR:
       a = 1.0;
       j = *voltDiv;
       while(j >= 10)
       {
           j /= 10.0;
           a *= 10.0;
       }
       while(j < 1)
       {
           j *= 10.0;
           a /= 10.0;
       }
       if(j <= 1.0001)
           *voltDiv = 0.5*a;
       else if(j <= 2.0001)
           *voltDiv = a;
       else if(j <= 5.0001)
           *voltDiv = 2.0*a;
       else
           *voltDiv = 5.0*a;
       break;
    case ADJ_CINCR:
       a = 1.0;
       j = *voltDiv;
       while(j >= 10)
       {
           j /= 10.0;
           a *= 10.0;
       }
       while(j < 0.9999)
       {
           j *= 10.0;
           a /= 10.0;
       }
       if(j < 1.9999)
           *voltDiv = 2.0*a;
       else if(j < 4.9999)
           *voltDiv = 5.0*a;
       else
           *voltDiv = 10.0*a;
       break;
    }
    *voltDiv = limitVoltPerDiv(*voltDiv);
    return 0;
}

/* Changes the Channel A Volts per Div based on the push buttons */
int chAVoltDivChange(char adjust)
{
    double tpd;
    tpd = chAVoltDiv;
    voltDivChange(adjust, tpd, &chAVoltDiv);
    chAOffset = limitOffset(chAOffset * chAVoltDiv / tpd);
    RefreshChAVoltDiv();
    refreshScopeWindows(0);
    return 0;
}

/* Changes the Channel B Volts per Div based on the push buttons */
int chBVoltDivChange(char adjust)
{
    double tpd;
    tpd = chBVoltDiv;
    voltDivChange(adjust, tpd, &chBVoltDiv);
    chBOffset = limitOffset(chBOffset * chBVoltDiv / tpd);
    RefreshChBVoltDiv();
    refreshScopeWindows(0);
    return 0;
}

/* Changes the Channel C Volts per Div based on the push buttons */
int chCVoltDivChange(char adjust)
{
    double tpd;
    tpd = chCVoltDiv;
    voltDivChange(adjust, tpd, &chCVoltDiv);
    chCOffset = limitOffset(chCOffset * chCVoltDiv / tpd);
    RefreshChCVoltDiv();
    refreshScopeWindows(0);
    return 0;
}

/* Changes the Channel D Volts per Div based on the push buttons */
int chDVoltDivChange(char adjust)
{
    double tpd;
    tpd = chDVoltDiv;
    voltDivChange(adjust, tpd, &chDVoltDiv);
    chDOffset = limitOffset(chDOffset * chDVoltDiv / tpd);
    RefreshChDVoltDiv();
    refreshScopeWindows(0);
    return 0;
}

/* Change the channel A offset based on the buttons */
int chAOffsetChange(char adjust)
{
    switch(adjust)
    {
    case ADJ_FDECR:
    case ADJ_CDECR:
        chAOffset = limitOffset(chAOffset - chAVoltDiv / 5);
        break;
    case ADJ_FINCR:
    case ADJ_CINCR:
        chAOffset = limitOffset(chAOffset + chAVoltDiv / 5);
        break;
    }
    RefreshChAOffset();
    refreshScopeWindows(0);
    return 0;
}

/* Change the channel B offset based on the buttons */
int chBOffsetChange(char adjust)
{
    switch(adjust)
    {
    case ADJ_FDECR:
    case ADJ_CDECR:
        chBOffset = limitOffset(chBOffset - chBVoltDiv / 5);
        break;
    case ADJ_FINCR:
    case ADJ_CINCR:
        chBOffset = limitOffset(chBOffset + chBVoltDiv / 5);
        break;
    }
    RefreshChBOffset();
    refreshScopeWindows(0);
    return 0;
}

/* Change the channel C offset based on the buttons */
int chCOffsetChange(char adjust)
{
    switch(adjust)
    {
    case ADJ_FDECR:
    case ADJ_CDECR:
        chCOffset = limitOffset(chCOffset - chCVoltDiv / 5);
        break;
    case ADJ_FINCR:
    case ADJ_CINCR:
        chCOffset = limitOffset(chCOffset + chCVoltDiv / 5);
        break;
    }
    RefreshChCOffset();
    refreshScopeWindows(0);
    return 0;
}

/* Change the channel D offset based on the buttons */
int chDOffsetChange(char adjust)
{
    switch(adjust)
    {
    case ADJ_FDECR:
    case ADJ_CDECR:
        chDOffset = limitOffset(chDOffset - chDVoltDiv / 5);
        break;
    case ADJ_FINCR:
    case ADJ_CINCR:
        chDOffset = limitOffset(chDOffset + chDVoltDiv / 5);
        break;
    }
    RefreshChDOffset();
    refreshScopeWindows(0);
    return 0;
}

/* Panel window procedure, called by windows */
// hPnl: handle to the panel window
// message: message to process
// wParam: a parameter, interpretation depends on message
// lParam: a parameter, interpretation depends on message
BOOL CALLBACK PanelProc (HWND hPnl, UINT message, WPARAM wParam, LPARAM lParam)
{
    char a[80];
    char userStr[80];
    char inputStr[80];
    HWND hctrl[4];
    POINT p;
    double tst, tpd, sr, spc;
    int i, j, k;
    char temp;
    static int iCount, ctrl, clkState;
    switch (message)
    {
    case WM_INITDIALOG:
        iCount = 0;
        clkState = 0;


        /* Initialize comboboxes */
        hctrl[0] = GetDlgItem(hPnl, CB_CHA_SOURCE);
        hctrl[1] = GetDlgItem(hPnl, CB_CHB_SOURCE);
        for(i = CB_CHOICE1; i <= CB_CHOICE10; i++)
        {
            LoadString(hInstance, i, userStr, 80);
            SendMessage(hctrl[0], CB_ADDSTRING, 0, (LPARAM) userStr);
            SendMessage(hctrl[1], CB_ADDSTRING, 0, (LPARAM) userStr);
        }
        hctrl[0] = GetDlgItem(hPnl, CB_CHC_SOURCE);
        hctrl[1] = GetDlgItem(hPnl, CB_CHD_SOURCE);

        for(i = CB_CHOICE14; i <= CB_CHOICE23; i++)
        {
            LoadString(hInstance, i, userStr, 80);
            SendMessage(hctrl[0], CB_ADDSTRING, 0, (LPARAM) userStr);
            SendMessage(hctrl[1], CB_ADDSTRING, 0, (LPARAM) userStr);
        }

        hctrl[0] = GetDlgItem(hPnl, CB_TRIGGER_MODE);
        for(i = CB_CHOICE11; i <= CB_CHOICE13; i++)
        {
            LoadString(hInstance, i, userStr, 80);
            SendMessage(hctrl[0], CB_ADDSTRING, 0, (LPARAM) userStr);
        }

        hctrl[0] = GetDlgItem(hPnl, MATH_F1);
        hctrl[1] = GetDlgItem(hPnl, MATH_F2);
        hctrl[2] = GetDlgItem(hPnl, MATH_F3);
        hctrl[3] = GetDlgItem(hPnl, MATH_F4);
        for(i = MEASURE_CHOICE0; i <= MEASURE_CHOICE24; i++)
        {
            LoadString(hInstance, i, userStr, 80);
            for(j = 0; j < 4; j++)
            {
                SendMessage(hctrl[j], CB_ADDSTRING, 0, (LPARAM) userStr);
            }
        }
        for(i = 0; i < 4; i++)
        {
            SendMessage(hctrl[i], CB_SETDROPPEDWIDTH, 58, 0);
            // SendMessage(hctrl[i], CB_SETMINVISIBLE, 10, 0);
        }

        hctrl[0] = GetDlgItem(hPnl, MATHSRC_F1);
        hctrl[1] = GetDlgItem(hPnl, MATHSRC_F2);
        hctrl[2] = GetDlgItem(hPnl, MATHSRC_F3);
        hctrl[3] = GetDlgItem(hPnl, MATHSRC_F4);
        for(i = MEASURE_SRC_CH1; i <= MEASURE_SRC_CH4;i++)
        {
            LoadString(hInstance, i, userStr, 80);
            for(j = 0; j < 4; j++)
            {
                SendMessage(hctrl[j], CB_ADDSTRING, 0, (LPARAM) userStr);
            }
        }

        oldProc = (WNDPROC) SetWindowLong(GetDlgItem(hPnl, ED_MATH_F1), GWLP_WNDPROC,
                      (LONG) EdProc);
        oldProc = (WNDPROC) SetWindowLong(GetDlgItem(hPnl, ED_MATH_F2), GWLP_WNDPROC,
                      (LONG) EdProc);
        oldProc = (WNDPROC) SetWindowLong(GetDlgItem(hPnl, ED_MATH_F3), GWLP_WNDPROC,
                      (LONG) EdProc);
        oldProc = (WNDPROC) SetWindowLong(GetDlgItem(hPnl, ED_MATH_F4), GWLP_WNDPROC,
                      (LONG) EdProc);

        for(i = 0; i < 4; i++)
            resetMStat(i);

        hTT[0] = CreateToolTip(ED_MATH_F1, hPnl, (WCHAR *) tipText[0]);
        hTT[1] = CreateToolTip(ED_MATH_F2, hPnl, (WCHAR *) tipText[1]);
        hTT[2] = CreateToolTip(ED_MATH_F3, hPnl, (WCHAR *) tipText[2]);
        hTT[3] = CreateToolTip(ED_MATH_F4, hPnl, (WCHAR *) tipText[3]);

        cursorDispCh[0] = 0;
        cursorDispCh[1] = 0;
        populatePanel(hPnl);

        return TRUE;
    case WM_DRAWITEM:
        //return TRUE;
        return DrawCustomButtons(hPnl, (LPDRAWITEMSTRUCT) lParam, &clkState, &ctrl);
    case WM_TIMER:
        SendMessage(hPnl, WM_COMMAND, ctrl, 0);
        return TRUE;
    case WM_REFRESHPANEL:
         populatePanel(hPnl);
         InvalidateRect(hPnl, NULL, TRUE);
         return TRUE;
    case WM_COMMAND:
        switch (LOWORD (wParam))
        {
        case ST_LABC:
            hctrl[0] = GetDlgItem(hPnl, LOWORD(wParam));
            i = GetWindowTextLength(hctrl[0]);
            GetWindowText(hctrl[0], inputStr, i + 1);
            if(strcmp(inputStr,"Ch A")==0)
            {
                SetWindowText(hctrl[0],"Ch C");
                cursorDispCh[0] = 1;
                SendMessage(g_hScreenMain,WM_PAINT,0,0);
            }
            else if(strcmp(inputStr,"Ch C")==0)
            {
                SetWindowText(hctrl[0],"Ch A");
                cursorDispCh[0] = 0;
                SendMessage(g_hScreenMain,WM_PAINT,0,0);
            }
            break;
        case ST_LABD:
            hctrl[0] = GetDlgItem(hPnl, LOWORD(wParam));
            i = GetWindowTextLength(hctrl[0]);
            GetWindowText(hctrl[0], inputStr, i + 1);
            if(strcmp(inputStr,"Ch B")==0)
            {
                SetWindowText(hctrl[0],"Ch D");
                cursorDispCh[1] = 1;
                SendMessage(g_hScreenMain,WM_PAINT,0,0);
            }
            else if(strcmp(inputStr,"Ch D")==0)
            {
                SetWindowText(hctrl[0],"Ch B");
                cursorDispCh[1] = 0;
                SendMessage(g_hScreenMain,WM_PAINT,0,0);
            }
            break;
        case ED_TRIGGER_DELAY:
            if(HIWORD(wParam) == EN_KILLFOCUS)
            {
                hctrl[0] = GetDlgItem(hPnl, LOWORD(wParam));
                i = GetWindowTextLength(hctrl[0]);
                GetWindowText(hctrl[0], inputStr, i + 1);
                setTriggerDelay(EngStrToNum(inputStr));
                refreshTriggerDelay();
                refreshScopeWindows(1);
            }
            break;
        case CM_CONFIG_SAMPLE_INTERLACED:
            hctrl[0] = GetDlgItem(hPnl, LOWORD(wParam));
            SendMessage(hctrl[0], BM_SETCHECK, !SendMessage(hctrl[0], BM_GETCHECK, 0, 0), 0);
            if(SendMessage(hctrl[0], BM_GETCHECK, 0, 0) == BST_CHECKED)
            {
                CheckMenuItem(GetMenu(g_hMainWindow), CM_CONFIG_SAMPLE_INTERLACED, MF_CHECKED);
                setTrueXY(1);
            }
            else
            {
                CheckMenuItem(GetMenu(g_hMainWindow), CM_CONFIG_SAMPLE_INTERLACED, MF_UNCHECKED);
                setTrueXY(0);
            }
            hctrl[0] = GetDlgItem(hPnl, ED_TIME_PER_DIV);
            i = GetWindowTextLength(hctrl[0]);
            GetWindowText(hctrl[0], inputStr, i + 1);
            tpd = EngStrToNum(inputStr);
            setTimePerDiv(tpd);
            refreshXYChkbox(hPnl);
            RefreshTimeDiv();
            //refreshScopeWindows(1);
            refreshScopeWindows(0);
            break;
        case CM_CONFIG_SAMPLE_TIMEEQUIV:
            hctrl[0] = GetDlgItem(hPnl, LOWORD(wParam));
            SendMessage(hctrl[0], BM_SETCHECK, !SendMessage(hctrl[0], BM_GETCHECK, 0, 0), 0);
            if(SendMessage(hctrl[0], BM_GETCHECK, 0, 0) == BST_CHECKED)
            {
                CheckMenuItem(GetMenu(g_hMainWindow), CM_CONFIG_SAMPLE_TIMEEQUIV, MF_CHECKED);
                setRepetitive(1);
            }
            else
            {
                CheckMenuItem(GetMenu(g_hMainWindow), CM_CONFIG_SAMPLE_TIMEEQUIV, MF_UNCHECKED);
                setRepetitive(0);
            }
            hctrl[0] = GetDlgItem(hPnl, ED_TIME_PER_DIV);
            i = GetWindowTextLength(hctrl[0]);
            GetWindowText(hctrl[0], inputStr, i + 1);
            tpd = EngStrToNum(inputStr);
            setTimePerDiv(tpd);
            RefreshTimeDiv();
            //refreshScopeWindows(1);
            refreshScopeWindows(0);
            break;
        case ED_VOLT_OFFSET_CHA:
            if(HIWORD(wParam) == EN_KILLFOCUS)
            {
                hctrl[0] = GetDlgItem(hPnl, LOWORD(wParam));
                i = GetWindowTextLength(hctrl[0]);
                GetWindowText(hctrl[0], inputStr, i + 1);
                chAOffset = limitOffset(EngStrToNum(inputStr));
                RefreshChAOffset();
                refreshScopeWindows(0);
            }
            break;
        case ED_VOLT_OFFSET_CHB:
            if(HIWORD(wParam) == EN_KILLFOCUS)
            {
                hctrl[0] = GetDlgItem(hPnl, LOWORD(wParam));
                i = GetWindowTextLength(hctrl[0]);
                GetWindowText(hctrl[0], inputStr, i + 1);
                chBOffset = limitOffset(EngStrToNum(inputStr));
                RefreshChBOffset();
                refreshScopeWindows(0);
            }
            break;
        case ED_VOLT_OFFSET_CHC:
            if(HIWORD(wParam) == EN_KILLFOCUS)
            {
                hctrl[0] = GetDlgItem(hPnl, LOWORD(wParam));
                i = GetWindowTextLength(hctrl[0]);
                GetWindowText(hctrl[0], inputStr, i + 1);
                chCOffset = limitOffset(EngStrToNum(inputStr));
                RefreshChCOffset();
                refreshScopeWindows(0);
            }
            break;
        case ED_VOLT_OFFSET_CHD:
            if(HIWORD(wParam) == EN_KILLFOCUS)
            {
                hctrl[0] = GetDlgItem(hPnl, LOWORD(wParam));
                i = GetWindowTextLength(hctrl[0]);
                GetWindowText(hctrl[0], inputStr, i + 1);
                chDOffset = limitOffset(EngStrToNum(inputStr));
                RefreshChDOffset();
                refreshScopeWindows(0);
            }
            break;
        case ED_VOLT_PER_DIV_CHA:
            if(HIWORD(wParam) == EN_KILLFOCUS)
            {
                hctrl[0] = GetDlgItem(hPnl, LOWORD(wParam));
                i = GetWindowTextLength(hctrl[0]);
                GetWindowText(hctrl[0], inputStr, i + 1);
                tpd = chAVoltDiv;
                chAVoltDiv = limitVoltPerDiv(((double) ((int) (100.0*EngStrToNum(inputStr)+0.5))) / 100.0);
                chAOffset = limitOffset(chAOffset * chAVoltDiv / tpd);
                RefreshChAVoltDiv();
                refreshScopeWindows(0);
            }
            break;
        case ED_VOLT_PER_DIV_CHB:
            if(HIWORD(wParam) == EN_KILLFOCUS)
            {
                hctrl[0] = GetDlgItem(hPnl, LOWORD(wParam));
                i = GetWindowTextLength(hctrl[0]);
                GetWindowText(hctrl[0], inputStr, i + 1);
                tpd = chBVoltDiv;
                chBVoltDiv = limitVoltPerDiv(((double) ((int) (100.0*EngStrToNum(inputStr)+0.5))) / 100.0);
                chBOffset = limitOffset(chBOffset * chBVoltDiv / tpd);
                RefreshChBVoltDiv();
                refreshScopeWindows(0);
            }
            break;
        case ED_VOLT_PER_DIV_CHC:
            if(HIWORD(wParam) == EN_KILLFOCUS)
            {
                hctrl[0] = GetDlgItem(hPnl, LOWORD(wParam));
                i = GetWindowTextLength(hctrl[0]);
                GetWindowText(hctrl[0], inputStr, i + 1);
                tpd = chCVoltDiv;
                chCVoltDiv = limitVoltPerDiv(((double) ((int) (100.0*EngStrToNum(inputStr)+0.5))) / 100.0);
                chCOffset = limitOffset(chCOffset * chCVoltDiv / tpd);
                RefreshChCVoltDiv();
                refreshScopeWindows(0);
            }
            break;
        case ED_VOLT_PER_DIV_CHD:
            if(HIWORD(wParam) == EN_KILLFOCUS)
            {
                hctrl[0] = GetDlgItem(hPnl, LOWORD(wParam));
                i = GetWindowTextLength(hctrl[0]);
                GetWindowText(hctrl[0], inputStr, i + 1);
                tpd = chDVoltDiv;
                chDVoltDiv = limitVoltPerDiv(((double) ((int) (100.0*EngStrToNum(inputStr)+0.5))) / 100.0);
                chDOffset = limitOffset(chDOffset * chDVoltDiv / tpd);
                RefreshChDVoltDiv();
                refreshScopeWindows(0);
            }
            break;
        case CM_CHA_ENABLED:
            hctrl[0] = GetDlgItem(hPnl, LOWORD(wParam));
            SendMessage(hctrl[0], BM_SETCHECK, !SendMessage(hctrl[0], BM_GETCHECK, 0, 0), 0);
            setChannelEnabled(0, SendMessage(hctrl[0], BM_GETCHECK, 0, 0));
            break;
        case CM_CHB_ENABLED:
            hctrl[0] = GetDlgItem(hPnl, LOWORD(wParam));
            SendMessage(hctrl[0], BM_SETCHECK, !SendMessage(hctrl[0], BM_GETCHECK, 0, 0), 0);
            setChannelEnabled(1, SendMessage(hctrl[0], BM_GETCHECK, 0, 0));
            break;
        case CM_CHC_ENABLED:
            hctrl[0] = GetDlgItem(hPnl, LOWORD(wParam));
            SendMessage(hctrl[0], BM_SETCHECK, !SendMessage(hctrl[0], BM_GETCHECK, 0, 0), 0);
            setChannelEnabled(CHANNELC, SendMessage(hctrl[0], BM_GETCHECK, 0, 0));
            break;
        case CM_CHD_ENABLED:
            hctrl[0] = GetDlgItem(hPnl, LOWORD(wParam));
            SendMessage(hctrl[0], BM_SETCHECK, !SendMessage(hctrl[0], BM_GETCHECK, 0, 0), 0);
            setChannelEnabled(CHANNELD, SendMessage(hctrl[0], BM_GETCHECK, 0, 0));
            break;
        case ED_TIME_PER_DIV:
            if(HIWORD(wParam) == EN_KILLFOCUS)
            {
                hctrl[0] = GetDlgItem(hPnl, LOWORD(wParam));
                i = GetWindowTextLength(hctrl[0]);
                GetWindowText(hctrl[0], inputStr, i + 1);
                tpd = EngStrToNum(inputStr);
                setTimePerDiv(tpd);
                refreshXYChkbox(hPnl);
                RefreshTimeDiv();
                refreshScopeWindows(0);
            }
            break;
        case CB_TRIGGER_MODE:
            if (HIWORD(wParam) == CBN_SELENDOK)
            {
                switch(SendMessage(GetDlgItem(hPnl, LOWORD(wParam)), CB_GETCURSEL, 0, 0))
                {
                case TRNOT:
                    setTriggerOff();
                    break;
                case TRPOS:
                    setTriggerPos();
                    break;
                case TRNEG:
                    setTriggerNeg();
                    break;
                }
                setTimePerDiv(getTimePerDivision());
                RefreshTimeDiv();
                refreshScopeWindows(1);
            }
            break;
        case CB_CHA_SOURCE:
            if (HIWORD(wParam) == CBN_SELENDOK)
            {
                chAmakeup = SendMessage(GetDlgItem(hPnl, LOWORD(wParam)), CB_GETCURSEL, 0, 0);
                for(i = 0; i < 4; i++)
                {
                    if((measureFunct[i] % 4) == 0)
                        resetMStat(i);
                    if((measureFunct[i] % 4) == 2 && chCmakeup != 4)
                        resetMStat(i);
                    if(((measureFunct[i] % 4) == 3) && chDmakeup != 4)
                        resetMStat(i);
                }
            }
            break;
        case CB_CHB_SOURCE:
            if (HIWORD(wParam) == CBN_SELENDOK)
            {
                chBmakeup = SendMessage(GetDlgItem(hPnl, LOWORD(wParam)), CB_GETCURSEL, 0, 0);
                for(i = 0; i < 4; i++)
                {
                    if((measureFunct[i] % 4) == 1)
                        resetMStat(i);
                    if((measureFunct[i] % 4) == 2 && chCmakeup != 3)
                        resetMStat(i);
                    if(((measureFunct[i] % 4) == 3) && chDmakeup != 3)
                        resetMStat(i);

                }
            }
            break;
        case CB_CHC_SOURCE:
            if (HIWORD(wParam) == CBN_SELENDOK)
            {
                chCmakeup = SendMessage(GetDlgItem(hPnl, LOWORD(wParam)), CB_GETCURSEL, 0, 0);
                for(i = 0; i < 4; i++)
                {
                    if((measureFunct[i] % 4) == 2)
                        resetMStat(i);
                }
            }
            break;
        case CB_CHD_SOURCE:
            if (HIWORD(wParam) == CBN_SELENDOK)
            {
                chDmakeup = SendMessage(GetDlgItem(hPnl, LOWORD(wParam)), CB_GETCURSEL, 0, 0);
                for(i = 0; i < 4; i++)
                {
                    if((measureFunct[i] % 4) == 3)
                        resetMStat(i);
                }
            }
            break;
        case MATH_F1:
        case MATHSRC_F1:
            if (HIWORD(wParam) == CBN_SELENDOK)
            {
                measureFunct[0] = SendMessage(GetDlgItem(hPnl, MATH_F1), CB_GETCURSEL, 0, 0)*4+SendMessage(GetDlgItem(hPnl,MATHSRC_F1), CB_GETCURSEL,0,0);
                resetMStat(0);
                doMeasurements();
            }
            break;
        case MATH_F2:
        case MATHSRC_F2:
            if (HIWORD(wParam) == CBN_SELENDOK)
            {
                measureFunct[1] = SendMessage(GetDlgItem(hPnl, MATH_F2), CB_GETCURSEL, 0, 0)*4+SendMessage(GetDlgItem(hPnl, MATHSRC_F2),CB_GETCURSEL,0,0);
                resetMStat(1);
                doMeasurements();
            }
            break;
        case MATH_F3:
        case MATHSRC_F3:
            if (HIWORD(wParam) == CBN_SELENDOK)
            {
                measureFunct[2] = SendMessage(GetDlgItem(hPnl, MATH_F3), CB_GETCURSEL, 0, 0)*4+SendMessage(GetDlgItem(hPnl, MATHSRC_F3),CB_GETCURSEL,0,0);
                resetMStat(2);
                doMeasurements();
            }
        break;
        case MATH_F4:
        case MATHSRC_F4:
            if (HIWORD(wParam) == CBN_SELENDOK)
            {
                measureFunct[3] = SendMessage(GetDlgItem(hPnl, MATH_F4), CB_GETCURSEL, 0, 0)*4+SendMessage(GetDlgItem(hPnl, MATHSRC_F4),CB_GETCURSEL,0,0);
                resetMStat(3);
                doMeasurements();
            }
            break;
        case DLG_OK:
            // Cheap way to have the dialog box accept the enter key is to have a default button that grabs the focus
            SetFocus(GetDlgItem(hPnl, LOWORD(wParam)));
        default:
            break;
        }
        break;
    case WM_NOTIFY:
        switch (((LPNMHDR)lParam)->code)
        {
        case UDN_DELTAPOS:
            switch(((LPNMHDR)lParam)->idFrom)
            {
            case CM_TIME_PER_DIV_F:
                if(((LPNMUPDOWN)lParam)->iDelta > 0)
                    timePerDivChange(ADJ_FINCR);
                else
                    timePerDivChange(ADJ_FDECR);
                break;
            case CM_TIME_PER_DIV_C:
                if(((LPNMUPDOWN)lParam)->iDelta > 0)
                    timePerDivChange(ADJ_CINCR);
                else
                    timePerDivChange(ADJ_CDECR);
                break;
            case CM_TRIGGER_DELAY:
                if(((LPNMUPDOWN)lParam)->iDelta > 0)
                    triggerDelayChange(ADJ_FDECR);
                else
                    triggerDelayChange(ADJ_FINCR);
                refreshTriggerDelay();
                refreshScopeWindows(1);
                break;
            case CM_VOLT_PER_DIV_CHA_F:
                if(((LPNMUPDOWN)lParam)->iDelta > 0)
                    chAVoltDivChange(ADJ_FDECR);
                else
                    chAVoltDivChange(ADJ_FINCR);
                break;
            case CM_VOLT_PER_DIV_CHB_F:
                if(((LPNMUPDOWN)lParam)->iDelta > 0)
                    chBVoltDivChange(ADJ_FDECR);
                else
                    chBVoltDivChange(ADJ_FINCR);
                break;
            case CM_VOLT_PER_DIV_CHC_F:
                if(((LPNMUPDOWN)lParam)->iDelta > 0)
                    chCVoltDivChange(ADJ_FDECR);
                else
                    chCVoltDivChange(ADJ_FINCR);
                break;
            case CM_VOLT_PER_DIV_CHD_F:
                if(((LPNMUPDOWN)lParam)->iDelta > 0)
                    chDVoltDivChange(ADJ_FDECR);
                else
                    chDVoltDivChange(ADJ_FINCR);
                break;
            case CM_VOLT_PER_DIV_CHA_C:
                if(((LPNMUPDOWN)lParam)->iDelta > 0)
                    chAVoltDivChange(ADJ_CDECR);
                else
                    chAVoltDivChange(ADJ_CINCR);
                break;
            case CM_VOLT_PER_DIV_CHB_C:
                if(((LPNMUPDOWN)lParam)->iDelta > 0)
                    chBVoltDivChange(ADJ_CDECR);
                else
                    chBVoltDivChange(ADJ_CINCR);
                break;
            case CM_VOLT_PER_DIV_CHC_C:
                if(((LPNMUPDOWN)lParam)->iDelta > 0)
                    chCVoltDivChange(ADJ_CDECR);
                else
                    chCVoltDivChange(ADJ_CINCR);
                break;
            case CM_VOLT_PER_DIV_CHD_C:
                if(((LPNMUPDOWN)lParam)->iDelta > 0)
                    chDVoltDivChange(ADJ_CDECR);
                else
                    chDVoltDivChange(ADJ_CINCR);
                break;
            case CM_VOLT_OFFSET_CHA:
                if(((LPNMUPDOWN)lParam)->iDelta > 0)
                    chAOffsetChange(ADJ_FDECR);
                else
                    chAOffsetChange(ADJ_FINCR);
                break;
            case CM_VOLT_OFFSET_CHB:
                if(((LPNMUPDOWN)lParam)->iDelta > 0)
                    chBOffsetChange(ADJ_FDECR);
                else
                    chBOffsetChange(ADJ_FINCR);
                break;
            case CM_VOLT_OFFSET_CHC:
                if(((LPNMUPDOWN)lParam)->iDelta > 0)
                    chCOffsetChange(ADJ_FDECR);
                else
                    chCOffsetChange(ADJ_FINCR);
                break;
            case CM_VOLT_OFFSET_CHD:
                if(((LPNMUPDOWN)lParam)->iDelta > 0)
                    chDOffsetChange(ADJ_FDECR);
                else
                    chDOffsetChange(ADJ_FINCR);
                break;
            default:
                break;
            }
            break;
        default:
            break;
        }
        break;
    case WM_DESTROY:
        return TRUE;
    default:
        break;
    }
    return FALSE;
}

int populatePanel(HWND hPnl)
{
    /* Populate panel */
    SendMessage(GetDlgItem(hPnl, CB_CHA_SOURCE), CB_SETCURSEL, chAmakeup, 0);
    SendMessage(GetDlgItem(hPnl, CB_CHB_SOURCE), CB_SETCURSEL, chBmakeup, 0);
    SendMessage(GetDlgItem(hPnl, CB_CHC_SOURCE), CB_SETCURSEL, chCmakeup, 0);
    SendMessage(GetDlgItem(hPnl, CB_CHD_SOURCE), CB_SETCURSEL, chDmakeup, 0);

    SendMessage(GetDlgItem(hPnl, CM_CHA_ENABLED), BM_SETCHECK, getChannelEnabled(CHANNELA), 0);
    SendMessage(GetDlgItem(hPnl, CM_CHB_ENABLED), BM_SETCHECK, getChannelEnabled(CHANNELB), 0);
    SendMessage(GetDlgItem(hPnl, CM_CHC_ENABLED), BM_SETCHECK, getChannelEnabled(CHANNELC), 0);
    SendMessage(GetDlgItem(hPnl, CM_CHD_ENABLED), BM_SETCHECK, getChannelEnabled(CHANNELD), 0);

    SendMessage(GetDlgItem(hPnl, MATH_F1), CB_SETCURSEL, measureFunct[0]/4, 0);
    SendMessage(GetDlgItem(hPnl, MATH_F2), CB_SETCURSEL, measureFunct[1]/4, 0);
    SendMessage(GetDlgItem(hPnl, MATH_F3), CB_SETCURSEL, measureFunct[2]/4, 0);
    SendMessage(GetDlgItem(hPnl, MATH_F4), CB_SETCURSEL, measureFunct[3]/4, 0);

    SendMessage(GetDlgItem(hPnl, MATHSRC_F1), CB_SETCURSEL, measureFunct[0]%4, 0);
    SendMessage(GetDlgItem(hPnl, MATHSRC_F2), CB_SETCURSEL, measureFunct[1]%4, 0);
    SendMessage(GetDlgItem(hPnl, MATHSRC_F3), CB_SETCURSEL, measureFunct[2]%4, 0);
    SendMessage(GetDlgItem(hPnl, MATHSRC_F4), CB_SETCURSEL, measureFunct[3]%4, 0);

    refreshTrigger();

    if(getRepetitive())
    {
        SendMessage(GetDlgItem(hPnl, CM_CONFIG_SAMPLE_TIMEEQUIV) , BM_SETCHECK, TRUE, 0);
        CheckMenuItem(GetMenu(g_hMainWindow), CM_CONFIG_SAMPLE_TIMEEQUIV, MF_CHECKED);
    }
    else
    {
        SendMessage(GetDlgItem(hPnl, CM_CONFIG_SAMPLE_TIMEEQUIV) , BM_SETCHECK, FALSE, 0);
        CheckMenuItem(GetMenu(g_hMainWindow), CM_CONFIG_SAMPLE_TIMEEQUIV, MF_UNCHECKED);
    }

    refreshTimeDivHelper(GetDlgItem(hPnl, ED_TIME_PER_DIV), GetDlgItem(hPnl, ED_SAMPLE_RATE));
    refreshChOffsetHelper(GetDlgItem(hPnl, ED_VOLT_PER_DIV_CHA), chAVoltDiv);
    refreshChOffsetHelper(GetDlgItem(hPnl, ED_VOLT_PER_DIV_CHB), chBVoltDiv);
    refreshChOffsetHelper(GetDlgItem(hPnl, ED_VOLT_PER_DIV_CHC), chCVoltDiv);
    refreshChOffsetHelper(GetDlgItem(hPnl, ED_VOLT_PER_DIV_CHD), chDVoltDiv);
    refreshChOffsetHelper(GetDlgItem(hPnl, ED_VOLT_OFFSET_CHA), chAOffset);
    refreshChOffsetHelper(GetDlgItem(hPnl, ED_VOLT_OFFSET_CHB), chBOffset);
    refreshChOffsetHelper(GetDlgItem(hPnl, ED_VOLT_OFFSET_CHC), chCOffset);
    refreshChOffsetHelper(GetDlgItem(hPnl, ED_VOLT_OFFSET_CHD), chDOffset);
    refreshChOffsetHelper(GetDlgItem(hPnl, ED_TRIGGER_DELAY), getTriggerDelay());
    refreshXYChkbox(hPnl);
    return 0;
}

LRESULT CALLBACK EdProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static int a;
    char b[80];
    int id;

    switch (message)
    {
    case WM_CREATE:
         a = 0;
         tipTextFocus = -1;
         break;
    case WM_MOUSEMOVE:
         if(a == 0)
         {
              id = GetWindowLong(hwnd, GWL_ID);
              switch(id)
              {
              case ED_MATH_F1:
                   tipTextFocus = 0;
                   SendMessage(hTT[0], TTM_ACTIVATE, 1, 0);
                   break;
              case ED_MATH_F2:
                   tipTextFocus = 1;
                   SendMessage(hTT[1], TTM_ACTIVATE, 1, 0);
                   break;
              case ED_MATH_F3:
                   tipTextFocus = 2;
                   SendMessage(hTT[2], TTM_ACTIVATE, 1, 0);
                   break;
              case ED_MATH_F4:
                   tipTextFocus = 3;
                   SendMessage(hTT[3], TTM_ACTIVATE, 1, 0);
                   break;
              }
              SendMessage(g_hStatusBar, SB_SETTEXT, STATUSMSGBIN, (LPARAM) tipText[tipTextFocus]);
         }
         a = 1;
         break;
    case WM_MOUSELEAVE:
         SendMessage(g_hStatusBar, SB_SETTEXT, STATUSMSGBIN, (LPARAM) "");
         SendMessage(hTT[0], TTM_ACTIVATE, 0, 0);
         SendMessage(hTT[1], TTM_ACTIVATE, 0, 0);
         SendMessage(hTT[2], TTM_ACTIVATE, 0, 0);
         SendMessage(hTT[3], TTM_ACTIVATE, 0, 0);
         tipTextFocus = -1;
         a = 0;
         break;
    }
    return CallWindowProc(oldProc, hwnd, message, wParam, lParam);
}

HWND CreateToolTip(int toolID, HWND hDlg, WCHAR* pText)
{
    // toolID:  the resource ID of the control.
    // hDlg:    the handle of the dialog box.
    // pText:   the text that appears in the ToolTip.
    // g_hInst: the global instance handle.

    if (!toolID || !hDlg || !pText)
    {
        return FALSE;
    }
    // Get the window of the tool.
    HWND hwndTool = GetDlgItem(hDlg, toolID);

    // Create the ToolTip.
    HWND hwndTip = CreateWindowEx(NULL, TOOLTIPS_CLASS, NULL,
                              WS_POPUP |TTS_ALWAYSTIP,
                              CW_USEDEFAULT, CW_USEDEFAULT,
                              CW_USEDEFAULT, CW_USEDEFAULT,
                              hDlg, NULL,
                              (HINSTANCE) g_hMainWindow, NULL);

   if (!hwndTool || !hwndTip)
   {
       return hwndTip;
   }

    // Associate the ToolTip with the tool.
    TOOLINFO toolInfo = { 0 };
    toolInfo.cbSize = sizeof(toolInfo);
    toolInfo.hwnd = hDlg;
    toolInfo.uFlags = TTF_IDISHWND | TTF_SUBCLASS;
    toolInfo.uId = (UINT_PTR)hwndTool;
    toolInfo.lpszText = pText;
    SendMessage(hwndTip, TTM_ADDTOOL, 0, (LPARAM)&toolInfo);

    return hwndTip;
}

HWND ChangeToolTip(HWND hwndTool, HWND hwndTip, HWND hDlg, WCHAR* pText)
{
    // Associate the ToolTip with the tool.
    TOOLINFO toolInfo;
    SendMessage(hwndTip, TTM_GETTOOLINFO, 0, (LPARAM) &toolInfo);
    toolInfo.cbSize = sizeof(toolInfo);
    toolInfo.hwnd = hDlg;
    toolInfo.uFlags = TTF_CENTERTIP | TTF_IDISHWND | TTF_SUBCLASS;
    toolInfo.uId = (UINT_PTR)hwndTool;
    toolInfo.lpszText = pText;
    SendMessage(hwndTip, TTM_SETTOOLINFO, 0, (LPARAM) &toolInfo);
    return hwndTip;
}

int doMeasurementsHelper(HWND ed, char func, MEASURESTAT* s)
{
    double ans;
    int m;
    char a[80];
    char funcA, funcS;
    double *chan, *chFMag, *chFPhase;
    double chPer;
    funcA = func / 4;
    funcS = func % 4;
    m = getMaxSamplesPerChannel();

    switch(funcS)
    {
    case 1:
        chan = channelB[currentChannel];
        chFMag = chBfreqMag[currentChannel];
        chFPhase = chBfreqPhase[currentChannel];
        chPer = chBPeriod;
        break;
    case 2:
        chan = channelC[currentChannel];
        chFMag = chCfreqMag[currentChannel];
        chFPhase = chCfreqPhase[currentChannel];
        chPer = chCPeriod;
        break;
    case 3:
        chan = channelD[currentChannel];
        chFMag = chDfreqMag[currentChannel];
        chFPhase = chDfreqPhase[currentChannel];
        chPer = chDPeriod;
        break;
    case 0:
    default:
        chan = channelA[currentChannel];
        chFMag = chAfreqMag[currentChannel];
        chFPhase = chAfreqPhase[currentChannel];
        chPer = chAPeriod;
        break;
    }

    switch(funcA)
    {
    case SRMSAC:
        ans = sigRMS_AConly(chan, m);
        break;
    case SAVG:
        ans = sigAvg(chan, m);
        break;
    case SFREQ:
        ans = 1/chPer;
        break;
    case SMAX:
        ans = sigMax(chan, m);
        break;
    case SMIN:
        ans = sigMin(chan, m);
        break;
    case SPTP:
        ans = sigPeakToPeak(chan, m);
        break;
    case SRMS:
        ans = sigRMS(chan, m);
        break;
    case SDCYC:
        ans = sigDutyCycle(chan, m);
        break;
    case SFALLT:
        ans = sigFallTime(chan, m)/getSampleRate();
        break;
    case SMAGN:
        ans = sigMagn(chFMag, m/2);
        break;
    case SNDCYC:
        ans = sigNDutyCycle(chan, m);
        break;
    case SNPULSEW:
        ans = sigNPulseWidth(chan, m)/getSampleRate();
        break;
    case SPERIOD:
        ans = chPer;
        break;
    case SPERAVG:
        ans = sigPeriodAvg(chan, chPer*getSampleRate(), m);
        break;
    case SPERRMS:
        ans = sigPeriodRMS(chan, chPer*getSampleRate(), m);
        break;
    case SPERRMSAC:
        ans = sigPeriodRMS_ACOnly(chan, chPer*getSampleRate(), m);
        break;
    case SPHASE:
        ans = sigPhase(chFMag, chFPhase, m/2);
        break;
    case SPULSEW:
        ans = sigPulseWidth(chan, m)/getSampleRate();
        break;
    case SRISET:
        ans = sigRiseTime(chan, m)/getSampleRate();
        break;
    case SSNR:
        ans = sigSNR(chFMag, m/2);
        break;
    case STHD:
        ans = sigTHD(chFMag, m/2);
        break;
    case STHDN:
        ans = sigTHDN(chFMag, m/2);
        break;
    case STMAX:
        ans = sigTimeMax(chan, m)/getSampleRate();
        break;
    case STMIN:
        ans = sigTimeMin(chan, m)/getSampleRate();
        break;
    default:
        ans = 0;
        break;
    }
    NumToEngStr(ans, a);
    SendMessage(ed, WM_SETTEXT, 0, (LPARAM) a);
    IntegrateSample(ans, s);
}

int doMeasurements()
{
    HWND ctrl;

    ctrl = GetDlgItem(g_hPanel, ED_MATH_F1);
    doMeasurementsHelper(ctrl, measureFunct[0], (MEASURESTAT*) &mStat[0]);
    StatisticText(mStat[0], tipText[0]);
    ChangeToolTip(ctrl, hTT[0], g_hPanel, (WCHAR *) tipText[0]);

    ctrl = GetDlgItem(g_hPanel, ED_MATH_F2);
    doMeasurementsHelper(ctrl, measureFunct[1], &mStat[1]);
    StatisticText(mStat[1], tipText[1]);
    ChangeToolTip(ctrl, hTT[1], g_hPanel, (WCHAR *) tipText[1]);

    ctrl = GetDlgItem(g_hPanel, ED_MATH_F3);
    doMeasurementsHelper(ctrl, measureFunct[2], &mStat[2]);
    StatisticText(mStat[2], tipText[2]);
    ChangeToolTip(ctrl, hTT[2], g_hPanel, (WCHAR *) tipText[2]);

    ctrl = GetDlgItem(g_hPanel, ED_MATH_F4);
    doMeasurementsHelper(ctrl, measureFunct[3], &mStat[3]);
    StatisticText(mStat[3], tipText[3]);
    ChangeToolTip(ctrl, hTT[3], g_hPanel, (WCHAR *) tipText[3]);

    if(tipTextFocus >= 0)
        SendMessage(g_hStatusBar, SB_SETTEXT, STATUSMSGBIN, (LPARAM) tipText[tipTextFocus]);
    return 0;
}

int IntegrateSample(double x, MEASURESTAT* s)
{
    if(s == NULL)
        return 1;
    if(s->NumSamples == 0)
	{
        s->average = x;
		s->NumSamples = 1;
		s->q = 0;
		s->max = x;
		s->min = x;
		s->last = x;
		return 0;
	}

	double delta;

	s->NumSamples++;
	delta = x - s->average;
	s->average = s->average + delta / s->NumSamples;
	s->q = s->q + delta*(x - s->average);
	s->stddev = sqrt(s->q/s->NumSamples);
	if(s->min > x) s->min = x;
	if(s->max < x) s->max = x;
	s->last = x;
    return 0;
}

int StatisticText(MEASURESTAT s, char* toRet)
{
    char a[80];
    NumToEngStr(s.max, a);
    sprintf(toRet, "Max=%s  Avg=", a);
    NumToEngStr(s.average, a);
    sprintf(toRet, "%s%s  Std=", toRet, a);
    NumToEngStr(s.stddev, a);
    sprintf(toRet, "%s%s  Min=", toRet, a);
    NumToEngStr(s.min, a);
    sprintf(toRet, "%s%s", toRet, a);
    return 0;
}
