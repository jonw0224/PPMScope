/* ==============================================================================
 * Author:  Jonathan Weaver, jonw0224@aim.com
 * E-mail Contact: jonw0224@aim.com
 * Description:  Side panel window.
 * Version: 2.15
 * Date: 7/20/2012
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
    SendMessage(ctrl, WM_SETTEXT, 0, a);
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

/* Limits offset */
double limitOffset(double offset)
{
    if(offset >= 100)
        return 100;
    if(offset <= -100)
        return -100;
    return offset;
}

/* Limits volt per division */
double limitVoltPerDiv(double voltPerDiv)
{
    if(voltPerDiv >= 100)
        return 100;
    if(voltPerDiv <= 0.1)
        return 0.1;
    return voltPerDiv;
}

/* Set the trigger positive */
int setTriggerPos()
{
    enableTrigger(1);
    triggerSlope(1);
    refreshTrigger();
    return 0;
}

/* Set the trigger negative */
int setTriggerNeg()
{
    enableTrigger(1);
    triggerSlope(0);
    refreshTrigger();
    return 0;
}

/* Set the trigger off */
int setTriggerOff()
{
    enableTrigger(0);
    refreshTrigger();
    return 0;
}

int setCursorInfo(int windowType, double xval[2], double cha[2], double chb[2])
{
    double deltaxval, deltacha, deltachb;
    char a[80];
    char *b;

    switch(windowType)
    {
    case SCOPE_SCREEN:
        /* Headings */
        SendMessage(GetDlgItem(g_hPanel, ST_LABA), WM_SETTEXT, 0, "T");
        SendMessage(GetDlgItem(g_hPanel, ST_LABB), WM_SETTEXT, 0, "1/T");
        SendMessage(GetDlgItem(g_hPanel, ST_LABC), WM_SETTEXT, 0, "Ch A");
        SendMessage(GetDlgItem(g_hPanel, ST_LABD), WM_SETTEXT, 0, "Ch B");
        /* Cursor 1 */
        NumToEngStr(xval[0], a);
        for(b = a; *b; b++);
        *b++ = 's';
        *b = '\0';
        SendMessage(GetDlgItem(g_hPanel, ST_T_CUR1), WM_SETTEXT, 0, a);
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
        SendMessage(GetDlgItem(g_hPanel, ST_P_CUR1), WM_SETTEXT, 0, a);
        NumToEngStr(cha[0], a);
        for(b = a; *b; b++);
        *b++ = 'V';
        *b = '\0';
        SendMessage(GetDlgItem(g_hPanel, ST_CHA_CUR1), WM_SETTEXT, 0, a);
        NumToEngStr(chb[0], a);
        for(b = a; *b; b++);
        *b++ = 'V';
        *b = '\0';
        SendMessage(GetDlgItem(g_hPanel, ST_CHB_CUR1), WM_SETTEXT, 0, a);
        /* Cursor 2 */
        NumToEngStr(xval[1], a);
        for(b = a; *b; b++);
        *b++ = 's';
        *b = '\0';
        SendMessage(GetDlgItem(g_hPanel, ST_T_CUR2), WM_SETTEXT, 0, a);
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
        SendMessage(GetDlgItem(g_hPanel, ST_P_CUR2), WM_SETTEXT, 0, a);
        NumToEngStr(cha[1], a);
        for(b = a; *b; b++);
        *b++ = 'V';
        *b = '\0';
        SendMessage(GetDlgItem(g_hPanel, ST_CHA_CUR2), WM_SETTEXT, 0, a);
        NumToEngStr(chb[1], a);
        for(b = a; *b; b++);
        *b++ = 'V';
        *b = '\0';
        SendMessage(GetDlgItem(g_hPanel, ST_CHB_CUR2), WM_SETTEXT, 0, a);
        /* Delta */
        deltaxval = xval[0] - xval[1];
        deltacha = cha[0] - cha[1];
        deltachb = chb[0] - chb[1];
        SendMessage(GetDlgItem(g_hPanel, ST_CHB_DELTA), WM_SETTEXT, 0, a);
        NumToEngStr(deltaxval, a);
        for(b = a; *b; b++);
        *b++ = 's';
        *b = '\0';
        SendMessage(GetDlgItem(g_hPanel, ST_T_DELTA), WM_SETTEXT, 0, a);
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
        SendMessage(GetDlgItem(g_hPanel, ST_P_DELTA), WM_SETTEXT, 0, a);
        NumToEngStr(deltacha, a);
        for(b = a; *b; b++);
        *b++ = 'V';
        *b = '\0';
        SendMessage(GetDlgItem(g_hPanel, ST_CHA_DELTA), WM_SETTEXT, 0, a);
        NumToEngStr(deltachb, a);
        for(b = a; *b; b++);
        *b++ = 'V';
        *b = '\0';
        SendMessage(GetDlgItem(g_hPanel, ST_CHB_DELTA), WM_SETTEXT, 0, a);
        break;
    case SCOPE_FREQMAG:
    case SCOPE_FREQPHASE:
        /* Headings */
        SendMessage(GetDlgItem(g_hPanel, ST_LABA), WM_SETTEXT, 0, "Freq");
        SendMessage(GetDlgItem(g_hPanel, ST_LABB), WM_SETTEXT, 0, "1/Freq");
        SendMessage(GetDlgItem(g_hPanel, ST_LABC), WM_SETTEXT, 0, "Magn");
        SendMessage(GetDlgItem(g_hPanel, ST_LABD), WM_SETTEXT, 0, "Phase");
        /* Cursor 1 */
        NumToEngStr(xval[0], a);
        for(b = a; *b; b++);
        *b++ = 'H';
        *b++ = 'z';
        *b = '\0';
        SendMessage(GetDlgItem(g_hPanel, ST_T_CUR1), WM_SETTEXT, 0, a);
        if(xval[0] == 0)
            sprintf(a, "NAN");
        else
        {
            NumToEngStr(1/xval[0], a);
            for(b = a; *b; b++);
            *b++ = 's';
            *b = '\0';
        }
        SendMessage(GetDlgItem(g_hPanel, ST_P_CUR1), WM_SETTEXT, 0, a);
        NumToEngStr(cha[0], a);
        for(b = a; *b; b++);
        *b++ = 'V';
        *b = '\0';
        SendMessage(GetDlgItem(g_hPanel, ST_CHA_CUR1), WM_SETTEXT, 0, a);
        NumToEngStr(chb[0], a);
        SendMessage(GetDlgItem(g_hPanel, ST_CHB_CUR1), WM_SETTEXT, 0, a);
        /* Cursor 2 */
        NumToEngStr(xval[1], a);
        for(b = a; *b; b++);
        *b++ = 'H';
        *b++ = 'z';
        *b = '\0';
        SendMessage(GetDlgItem(g_hPanel, ST_T_CUR2), WM_SETTEXT, 0, a);
        if(xval[1] == 0)
            sprintf(a, "NAN");
        else
        {
            NumToEngStr(1/xval[1], a);
            for(b = a; *b; b++);
            *b++ = 's';
            *b = '\0';
        }
        SendMessage(GetDlgItem(g_hPanel, ST_P_CUR2), WM_SETTEXT, 0, a);
        NumToEngStr(cha[1], a);
        for(b = a; *b; b++);
        *b++ = 'V';
        *b = '\0';
        SendMessage(GetDlgItem(g_hPanel, ST_CHA_CUR2), WM_SETTEXT, 0, a);
        NumToEngStr(chb[1], a);
        SendMessage(GetDlgItem(g_hPanel, ST_CHB_CUR2), WM_SETTEXT, 0, a);
        /* Delta */
        deltaxval = xval[0] - xval[1];
        deltacha = cha[0] - cha[1];
        deltachb = chb[0] - chb[1];
        SendMessage(GetDlgItem(g_hPanel, ST_CHB_DELTA), WM_SETTEXT, 0, a);
        NumToEngStr(deltaxval, a);
        for(b = a; *b; b++);
        *b++ = 'H';
        *b++ = 'z';
        *b = '\0';
        SendMessage(GetDlgItem(g_hPanel, ST_T_DELTA), WM_SETTEXT, 0, a);
        if(deltaxval == 0)
            sprintf(a, "NAN");
        else
        {
            NumToEngStr(1/deltaxval, a);
            for(b = a; *b; b++);
            *b++ = 's';
            *b = '\0';
        }
        SendMessage(GetDlgItem(g_hPanel, ST_P_DELTA), WM_SETTEXT, 0, a);
        NumToEngStr(deltacha, a);
        for(b = a; *b; b++);
        *b++ = 'V';
        *b = '\0';
        SendMessage(GetDlgItem(g_hPanel, ST_CHA_DELTA), WM_SETTEXT, 0, a);
        NumToEngStr(deltachb, a);
        SendMessage(GetDlgItem(g_hPanel, ST_CHB_DELTA), WM_SETTEXT, 0, a);
        break;
    }
    return 0;
}

/* Refreshes the XY check box and gives proper messages */
int refreshXYChkbox(HWND panel) {
    int a, i;
    HWND hctrl;
    hctrl = GetDlgItem(panel, CM_CONFIG_SAMPLE_INTERLACED);
/*    a = getTrueXY();
    if(a == 0)
        EnableWindow(hctrl, 0);
    else if(a == 1)
        EnableWindow(hctrl, 1);
    else
        EnableWindow(hctrl, 1);
*/
    i = SendMessage(hctrl, BM_GETCHECK, 0, 0);
    if(i == BST_CHECKED)
        SendMessage(GetDlgItem(panel, ST_TIME), WM_SETTEXT, 0, "Interlaced Sampling");
    else
        SendMessage(GetDlgItem(panel, ST_TIME), WM_SETTEXT, 0, "Sequential Sampling");
    return 0;
}

/* Updates the channel readouts using value returned by updateChannels */
int updateChannelMsg(int j)
{
    int ma, mb, dca, dcb;
    char a[50];
    dca = (j & (1 << 5)) >> 5;  /* DC bit for channel A */
    dcb = (j & (1 << 4)) >> 4;  /* DC bit for channel B */
    ma = (j & 0xf000) >> 12;    /* Multiplier for channel A */
    mb = (j & 0x0f00) >> 8;     /* Multiplier for channel B */

    if(dca)
        sprintf(a, "%iX   AC Coupled", ma);
    else
        sprintf(a, "%iX   DC Coupled", ma);
    SendMessage(GetDlgItem(g_hPanel, ST_CHA), WM_SETTEXT, 0, a);

    if(dcb)
        sprintf(a, "%iX   AC Coupled", mb);
    else
        sprintf(a, "%iX   DC Coupled", mb);
    SendMessage(GetDlgItem(g_hPanel, ST_CHB), WM_SETTEXT, 0, a);

    return 0;
}


/* Update the Triggerlevel readout */
int updateTriggerLevel()
{
    double trig;
    char a[50];
    trig = getTriggerLevel();
    sprintf(a, "Trig lvl=");
    NumToEngStr(trig, &a[9]);
    SendMessage(GetDlgItem(g_hPanel, ST_TRIG), WM_SETTEXT, 0, a);
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

    if(tpd < (getMaxSamplesPerChannel() - 1) / getMaxSampleRate() / DIVISIONSX)
    {
        sr = setSampleRate(getMaxSampleRate());
        setSamplesPerChannel(tpd*sr*DIVISIONSX+2);
    }
    else
    {
        setSamplesPerChannel(getMaxSamplesPerChannel());
        sr = setSampleRate((getSamplesPerChannel()-1)/tpd/DIVISIONSX);
        if((sr*tpd*((double) DIVISIONSX)) > getMaxSamplesPerChannel() - 1)
        {
            sampleRateChange(ADJ_FDECR);
            sr = getSampleRate();
        }
        setSamplesPerChannel(tpd*sr*DIVISIONSX+2);
    }
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
    switch(adjust)
    {
    case ADJ_FINCR:
       setTimePerDiv(getTimePerDivision()*9/10);
       break;
    case ADJ_FDECR:
       setTimePerDiv(getTimePerDivision()*11/10);
       break;
    case ADJ_CINCR:
       setTimePerDiv(getTimePerDivision()/2);
       break;
    case ADJ_CDECR:
       setTimePerDiv(getTimePerDivision()*2);
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
    switch(adjust)
    {
    case ADJ_FDECR:
        *voltDiv = ((double) ((int) (9.0*(*voltDiv)+0.5)))/10.0;
        if((tpd - *voltDiv) < 0.05)
        *voltDiv = tpd - 0.1;
        break;
    case ADJ_FINCR:
        *voltDiv = ((double) ((int) (11.0*(*voltDiv)+0.5)))/10.0;
        if((*voltDiv - tpd) < 0.05)
            *voltDiv = tpd + 0.1;
        break;
    case ADJ_CDECR:
        *voltDiv = ((double) ((int) (5.0*(*voltDiv)+0.5)))/10.0;
        break;
    case ADJ_CINCR:
        *voltDiv = ((double) ((int) (20.0*(*voltDiv)+0.5)))/10.0;
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
        for(i = MEASURE_CHOICE0; i <= MEASURE_CHOICE48; i++)
        {
            LoadString(hInstance, i, userStr, 80);
            for(j = 0; j < 4; j++)
            {
                SendMessage(hctrl[j], CB_ADDSTRING, 0, (LPARAM) userStr);
            }
        }
        for(i = 0; i < 4; i++)
        {
            SendMessage(hctrl[i], CB_SETDROPPEDWIDTH, 150, 0);
            // SendMessage(hctrl[i], CB_SETMINVISIBLE, 10, 0);
        }

        oldProc = (WNDPROC) SetWindowLong(GetDlgItem(hPnl, ED_MATH_F1), GWL_WNDPROC,
                      (LONG) EdProc);
        oldProc = (WNDPROC) SetWindowLong(GetDlgItem(hPnl, ED_MATH_F2), GWL_WNDPROC,
                      (LONG) EdProc);
        oldProc = (WNDPROC) SetWindowLong(GetDlgItem(hPnl, ED_MATH_F3), GWL_WNDPROC,
                      (LONG) EdProc);
        oldProc = (WNDPROC) SetWindowLong(GetDlgItem(hPnl, ED_MATH_F4), GWL_WNDPROC,
                      (LONG) EdProc);

        for(i = 0; i < 4; i++)
            resetMStat(i);

        hTT[0] = CreateToolTip(ED_MATH_F1, hPnl, tipText[0]);
        hTT[1] = CreateToolTip(ED_MATH_F2, hPnl, tipText[1]);
        hTT[2] = CreateToolTip(ED_MATH_F3, hPnl, tipText[2]);
        hTT[3] = CreateToolTip(ED_MATH_F4, hPnl, tipText[3]);

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
        case ED_TRIGGER_DELAY:
            if(HIWORD(wParam) == EN_KILLFOCUS)
            {
                hctrl[0] = GetDlgItem(hPnl, LOWORD(wParam));
                i = GetWindowTextLength(hctrl[0]);
                GetWindowText(hctrl[0], inputStr, i + 1);
                setTriggerDelay(EngStrToNum(inputStr));
                refreshTriggerDelay();
                refreshScopeWindows(0);
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
        case ED_VOLT_PER_DIV_CHA:
            if(HIWORD(wParam) == EN_KILLFOCUS)
            {
                hctrl[0] = GetDlgItem(hPnl, LOWORD(wParam));
                i = GetWindowTextLength(hctrl[0]);
                GetWindowText(hctrl[0], inputStr, i + 1);
                tpd = chAVoltDiv;
                chAVoltDiv = limitVoltPerDiv(((double) ((int) (10.0*EngStrToNum(inputStr)+0.5))) / 10.0);
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
                chBVoltDiv = limitVoltPerDiv(((double) ((int) (10.0*EngStrToNum(inputStr)+0.5))) / 10.0);
                chBOffset = limitOffset(chBOffset * chBVoltDiv / tpd);
                RefreshChBVoltDiv();
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
                hctrl[0] = GetDlgItem(hPnl, ED_TIME_PER_DIV);
                i = GetWindowTextLength(hctrl[0]);
                GetWindowText(hctrl[0], inputStr, i + 1);
                tpd = EngStrToNum(inputStr);
                setTimePerDiv(tpd);
                RefreshTimeDiv();
                refreshScopeWindows(0);
            }
            break;
        case CB_CHA_SOURCE:
            if (HIWORD(wParam) == CBN_SELENDOK)
            {
                chAmakeup = SendMessage(GetDlgItem(hPnl, LOWORD(wParam)), CB_GETCURSEL, 0, 0);
                for(i = 0; i < 4; i++)
                {
                    if((measureFunct[i] % 2) == 1)
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
                    if((measureFunct[i] % 2) == 0)
                        resetMStat(i);
                }
            }
            break;
        case MATH_F1:
            if (HIWORD(wParam) == CBN_SELENDOK)
            {
                measureFunct[0] = SendMessage(GetDlgItem(hPnl, LOWORD(wParam)), CB_GETCURSEL, 0, 0);
                resetMStat(0);
                doMeasurements();
            }
            break;
        case MATH_F2:
            if (HIWORD(wParam) == CBN_SELENDOK)
            {
                measureFunct[1] = SendMessage(GetDlgItem(hPnl, LOWORD(wParam)), CB_GETCURSEL, 0, 0);
                resetMStat(1);
                doMeasurements();
            }
            break;
        case MATH_F3:
            if (HIWORD(wParam) == CBN_SELENDOK)
            {
                measureFunct[2] = SendMessage(GetDlgItem(hPnl, LOWORD(wParam)), CB_GETCURSEL, 0, 0);
                resetMStat(2);
                doMeasurements();
            }
            break;
        case MATH_F4:
            if (HIWORD(wParam) == CBN_SELENDOK)
            {
                measureFunct[3] = SendMessage(GetDlgItem(hPnl, LOWORD(wParam)), CB_GETCURSEL, 0, 0);
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

    SendMessage(GetDlgItem(hPnl, CM_CHA_ENABLED), BM_SETCHECK, getChannelEnabled(0), 0);
    SendMessage(GetDlgItem(hPnl, CM_CHB_ENABLED), BM_SETCHECK, getChannelEnabled(1), 0);

    SendMessage(GetDlgItem(hPnl, MATH_F1), CB_SETCURSEL, measureFunct[0], 0);
    SendMessage(GetDlgItem(hPnl, MATH_F2), CB_SETCURSEL, measureFunct[1], 0);
    SendMessage(GetDlgItem(hPnl, MATH_F3), CB_SETCURSEL, measureFunct[2], 0);
    SendMessage(GetDlgItem(hPnl, MATH_F4), CB_SETCURSEL, measureFunct[3], 0);

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
    refreshChOffsetHelper(GetDlgItem(hPnl, ED_VOLT_OFFSET_CHA), chAOffset);
    refreshChOffsetHelper(GetDlgItem(hPnl, ED_VOLT_OFFSET_CHB), chBOffset);
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
              SendMessage(g_hStatusBar, SB_SETTEXT, STATUSMSGBIN, tipText[tipTextFocus]);
         }
         a = 1;
         break;
    case WM_MOUSELEAVE:
         SendMessage(g_hStatusBar, SB_SETTEXT, STATUSMSGBIN, "");
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
                              g_hMainWindow, NULL);

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
    SendMessage(hwndTip, TTM_SETTOOLINFO, 0, (LPARAM)&toolInfo);
    return hwndTip;
}

int doMeasurementsHelper(HWND ed, char func, MEASURESTAT* s)
{
    double ans;
    int m;
    char a[80];

    m = getMaxSamplesPerChannel();

    switch(func)
    {
    case SRMSACA:
        ans = sigRMS_AConly(channelA[currentChannel], m);
        break;
    case SRMSACB:
        ans = sigRMS_AConly(channelB[currentChannel], m);
        break;
    case SAVGA:
        ans = sigAvg(channelA[currentChannel], m);
        break;
    case SAVGB:
        ans = sigAvg(channelB[currentChannel], m);
        break;
    case SFREQA:
        ans = 1/chAPeriod;
        break;
    case SFREQB:
        ans = 1/chBPeriod;
        break;
    case SMAXA:
        ans = sigMax(channelA[currentChannel], m);
        break;
    case SMAXB:
        ans = sigMax(channelB[currentChannel], m);
        break;
    case SMINA:
        ans = sigMin(channelA[currentChannel], m);
        break;
    case SMINB:
        ans = sigMin(channelB[currentChannel], m);
        break;
    case SPTPA:
        ans = sigPeakToPeak(channelA[currentChannel], m);
        break;
    case SPTPB:
        ans = sigPeakToPeak(channelB[currentChannel], m);
        break;
    case SRMSA:
        ans = sigRMS(channelA[currentChannel], m);
        break;
    case SRMSB:
        ans = sigRMS(channelB[currentChannel], m);
        break;
    case SDCYCA:
        ans = sigDutyCycle(channelA[currentChannel], m);
        break;
    case SDCYCB:
        ans = sigDutyCycle(channelB[currentChannel], m);
        break;
    case SFALLTA:
        ans = sigFallTime(channelA[currentChannel], m)/getSampleRate();
        break;
    case SFALLTB:
        ans = sigFallTime(channelB[currentChannel], m)/getSampleRate();
        break;
    case SMAGNA:
        ans = sigMagn(chAfreqMag[currentChannel], m/2);
        break;
    case SMAGNB:
        ans = sigMagn(chBfreqMag[currentChannel], m/2);
        break;
    case SNDCYCA:
        ans = sigNDutyCycle(channelA[currentChannel], m);
        break;
    case SNDCYCB:
        ans = sigNDutyCycle(channelB[currentChannel], m);
        break;
    case SNPULSEWA:
        ans = sigNPulseWidth(channelA[currentChannel], m)/getSampleRate();
        break;
    case SNPULSEWB:
        ans = sigNPulseWidth(channelB[currentChannel], m)/getSampleRate();
        break;
    case SPERIODA:
        ans = chAPeriod;
        break;
    case SPERIODB:
        ans = chBPeriod;
        break;
    case SPERAVGA:
        ans = sigPeriodAvg(channelA[currentChannel], chAPeriod*getSampleRate(), m);
        break;
    case SPERAVGB:
        ans = sigPeriodAvg(channelB[currentChannel], chBPeriod*getSampleRate(), m);
        break;
    case SPERRMSA:
        ans = sigPeriodRMS(channelA[currentChannel], chAPeriod*getSampleRate(), m);
        break;
    case SPERRMSB:
        ans = sigPeriodRMS(channelB[currentChannel], chBPeriod*getSampleRate(), m);
        break;
    case SPERRMSACA:
        ans = sigPeriodRMS_ACOnly(channelA[currentChannel], chAPeriod*getSampleRate(), m);
        break;
    case SPERRMSACB:
        ans = sigPeriodRMS_ACOnly(channelB[currentChannel], chBPeriod*getSampleRate(), m);
        break;
    case SPHASEA:
        ans = sigPhase(chAfreqMag[currentChannel], chAfreqPhase[currentChannel], m/2);
        break;
    case SPHASEB:
        ans = sigPhase(chBfreqMag[currentChannel], chBfreqPhase[currentChannel], m/2);
        break;
    case SPULSEWA:
        ans = sigPulseWidth(channelA[currentChannel], m)/getSampleRate();
        break;
    case SPULSEWB:
        ans = sigPulseWidth(channelB[currentChannel], m)/getSampleRate();
        break;
    case SRISETA:
        ans = sigRiseTime(channelA[currentChannel], m)/getSampleRate();
        break;
    case SRISETB:
        ans = sigRiseTime(channelB[currentChannel], m)/getSampleRate();
        break;
    case SSNRA:
        ans = sigSNR(chAfreqMag[currentChannel], m/2);
        break;
    case SSNRB:
        ans = sigSNR(chBfreqMag[currentChannel], m/2);
        break;
    case STHDA:
        ans = sigTHD(chAfreqMag[currentChannel], m/2);
        break;
    case STHDB:
        ans = sigTHD(chBfreqMag[currentChannel], m/2);
        break;
    case STHDNA:
        ans = sigTHDN(chAfreqMag[currentChannel], m/2);
        break;
    case STHDNB:
        ans = sigTHDN(chBfreqMag[currentChannel], m/2);
        break;
    case STMAXA:
        ans = sigTimeMax(channelA[currentChannel], m)/getSampleRate();
        break;
    case STMAXB:
        ans = sigTimeMax(channelB[currentChannel], m)/getSampleRate();
        break;
    case STMINA:
        ans = sigTimeMin(channelA[currentChannel], m)/getSampleRate();
        break;
    case STMINB:
        ans = sigTimeMin(channelB[currentChannel], m)/getSampleRate();
        break;
    default:
        ans = 0;
        break;
    }
    NumToEngStr(ans, a);
    SendMessage(ed, WM_SETTEXT, 0, a);
    IntegrateSample(ans, s);
}

int doMeasurements()
{
    HWND ctrl;

    ctrl = GetDlgItem(g_hPanel, ED_MATH_F1);
    doMeasurementsHelper(ctrl, measureFunct[0], (MEASURESTAT*) &mStat[0]);
    StatisticText(mStat[0], tipText[0]);
    ChangeToolTip(ctrl, hTT[0], g_hPanel, tipText[0]);

    ctrl = GetDlgItem(g_hPanel, ED_MATH_F2);
    doMeasurementsHelper(ctrl, measureFunct[1], &mStat[1]);
    StatisticText(mStat[1], tipText[1]);
    ChangeToolTip(ctrl, hTT[1], g_hPanel, tipText[1]);

    ctrl = GetDlgItem(g_hPanel, ED_MATH_F3);
    doMeasurementsHelper(ctrl, measureFunct[2], &mStat[2]);
    StatisticText(mStat[2], tipText[2]);
    ChangeToolTip(ctrl, hTT[2], g_hPanel, tipText[2]);

    ctrl = GetDlgItem(g_hPanel, ED_MATH_F4);
    doMeasurementsHelper(ctrl, measureFunct[3], &mStat[3]);
    StatisticText(mStat[3], tipText[3]);
    ChangeToolTip(ctrl, hTT[3], g_hPanel, tipText[3]);

    if(tipTextFocus >= 0)
        SendMessage(g_hStatusBar, SB_SETTEXT, STATUSMSGBIN, tipText[tipTextFocus]);
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
