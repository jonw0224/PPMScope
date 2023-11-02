/* ==============================================================================
 * Author:  Jonathan Weaver, jonw0224@aim.com
 * E-mail Contact: jonw0224@aim.com
 * Description:  Header file for oscilloscope graphs.
 * Version: 2.20
 * Date: 01/27/2014
 * Filename:  oscDisp.c, oscDisp.h
 *
 * Versions History:
 *      2.01 - 09/20/2006 - Created file
 *      2.02 - 02/19/2010 - Modified code to draw traces no matter what mode in
 *                          response to WM_PAINT message.  Before modification
 *                          traces were only drawn at a trigger event.
 *      2.14 - 01/31/2011 - Modified code to generalize colors.
 *      2.14 - 03/17/2011 - Added channel weight support
 *      2.151  07/20/2012 - Modified for continous Time Per Division
 *      2.17 - 05/29/2013 - Modified for pretrigger and incorporates trigger
 *                          delay in cursors/mouseover readouts
 *      2.18 - 11/27/2013 - Modified code for SINC reconstruction and increased
 *                          performance to be at least equal to other methods
 *      2.18 - 01/17/2014 - Added code to handle displaying the trigger level
 *                          for ChA and ChB instead of Ch1 and Ch2.
 *      2.18 - 01/27/2014 - Fixed a nasty bug that prevented the program from
 *                          running correctly under Code::Blocks (13.12) or
 *                          Dev-Cpp (5.3.3).  I was referencing several arrays
 *                          with an out of bounds index.
 *      2.19 - 03/12/2014 - Changed the Spectrum voltage scale logic to handle
 *                          the display more intelligently.
 *      2.20 - 06/20/2014 - Added a range of persistence.
 *
 * Copyright (C) 2006-2014 Jonathan Weaver
 *
 * This file is part of PPMScope.
 *
 * PPMScope is free software: you can redistribute it and/or modify
 * it under the terms of t        if((dispmode & MODE_CHBENABLED) && (chDraw & DRAWFREQPHASE))
            drawSpectPhase(rect, hdcBuffer, chBfreqPhase[currentChannel], chBColor,weight[1]);
he GNU General Public License as published by
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
#include "oscDisp.h"
#include <math.h>
#include "debug.h"
#include <stdio.h>

#define DIMCOLOR(rgbcolor, bgcolor) ((0xFF0000 & (((0xFF0000 & rgbcolor) + (0xFF0000 & bgcolor)) >> 1)) + (0xFF00 & (((0xFF00 & rgbcolor) + (0xFF00 & bgcolor)) >> 1)) + (0xFF & (((0xFF & rgbcolor) + (0xFF & bgcolor)) >> 1)))

/* Colors */
int gridColor, chAColor, chBColor, chCColor, chDColor, curColor[2], bColor, trigColor;

/* Channel Draw Weight */
int weight[4];

/* Persistence setting */
int persistence;

/* Keep up with three windows and their functions */
HWND windowHandles[3];
char windowTypes[3];
char windowCount = 0;

int cursorWindow = 0;

/* Channel drawing for holds */
char chDraw;
#define DRAWSCR             1
#define DRAWFREQMAG         2
#define DRAWFREQPHASE       4
#define DRAWNONE            0
#define DRAWOLDSCR          8
#define DRAWOLDFREQMAG      16
#define DRAWOLDFREQPHASE    32

/* Cursors */
double xCurPos[2], yCurPos[2];

/* Time per division */
double timePerDivision;

#define TOL             10

/* For double buffering of screens */
HDC hdcBuffers[3];
HBITMAP hbmBuffers[3];

/* For Alpha blending of screens */
HDC hdcTemp[3];
HBITMAP hbmTemp[3];

/* Gets the weight for drawing the channels
 * channel: 0 for channel A, 1 for channel B, 2 for channel C, and 3 for channel D
 * returns: weight in pixels */
int getPenWeight(int channel)
{
    return weight[channel];
}

/* Sets the weight for drawing the channels
 * channel: 0 for channel A, 1 for channel B, 2 for channel C, and 3 for channel D
 * w: weight to use in pixels
 * returns: 0  */
int setPenWeight(int channel, int w)
{
    weight[channel] = w;
    return 0;
}

/* Returns an oscilloscope display color
 * whichColor: 1 = Background Color, 2 = Grid Color, 3 = Channel A Color, 4 = Channel B Color, 5 = Cursor 1 Color, 6 = Cursor 2 Color, 7 = Trigger Color
 * return: the color as an int, or -1 if whichColor is invalid */
int oscGetColor(int whichColor)
{
    switch (whichColor)
    {
    case GETCOLORBG:
        return bColor;
    case GETCOLORGR:
        return gridColor;
    case GETCOLORCHA:
        return chAColor;
    case GETCOLORCHB:
        return chBColor;
    case GETCOLORCUR1:
        return curColor[0];
    case GETCOLORCUR2:
        return curColor[1];
    case GETCOLORTRIG:
        return trigColor;
    case GETCOLORCHC:
        return chCColor;
    case GETCOLORCHD:
        return chDColor;
    }
    return -1;
}

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
int oscSetColors(int scrbgcolor, int scrfgcolor, int channelAColor, int channelBColor, int channelCColor, int channelDColor, int cur1color, int cur2color, int triggerColor)
{
    bColor = scrbgcolor;
    gridColor = scrfgcolor;
    chAColor = channelAColor;
    chBColor = channelBColor;
    chCColor = channelCColor;
    chDColor = channelDColor;
    curColor[0] = cur1color;
    curColor[1] = cur2color;
    trigColor = triggerColor;
    return 1;
}

/* Gets the display configuration
 * windowMode:  three character array representing the window modes
 *     (SCOPE_SCREEN, SCOPE_FREQMAG, SCOPE_FREQPHASE)
 * returns: 1 */
int oscDispGetConfig(char windowMode[])
{
    windowMode[0] = windowTypes[0];
    windowMode[1] = windowTypes[1];
    windowMode[2] = windowTypes[2];
}

/* Sets the display configuration
 * windowMode:  three character array representing the window modes
 *     (SCOPE_SCREEN, SCOPE_FREQMAG, SCOPE_FREQPHASE)
 * returns: 1 */
int oscDispSetConfig(char windowMode[])
{
    windowTypes[0] = windowMode[0];
    windowTypes[1] = windowMode[1];
    windowTypes[2] = windowMode[2];
}

int drawScopeGrid(HWND hwnd, HDC hdc)
{
    double xdiv, ydiv, i, mid, pos;
    int j;
    RECT rect;
    HPEN hPen;

    GetClientRect(hwnd, &rect);
    ydiv = ((double) (rect.bottom - 1)) / DIVISIONSY;
    xdiv = ((double) (rect.right - 1)) / DIVISIONSX;
    if(ydiv <= 0) ydiv = 1;
    if(xdiv <= 0) xdiv = 1;
    hPen = CreatePen(PS_SOLID, 0, gridColor);
    SelectObject(hdc, hPen);
   /* Draw the vertical lines */
    for (i = 0.5; i < rect.right; i = i + xdiv)
    {
        MoveToEx(hdc, i, rect.bottom, NULL);
        LineTo(hdc, i, 0);
    }
    /* Draw the horizontal lines */
    for (i = 0.5; i < rect.bottom; i = i + ydiv)
    {
        MoveToEx(hdc, 0, i, NULL);
        LineTo(hdc, rect.right, i);
    }
    /* Draw the high precision tick marks if necessary */
    if(xdiv > 20)
    {
        mid = (double) (rect.bottom - 1) / 2 + 0.5;
        pos = 0;
        for(i = 0.5; i < rect.right; i = i + xdiv)
        {
            for(j = 0; j < 9; j++)
            {
                pos = pos + (double) xdiv / 10;
                MoveToEx(hdc, pos, 0, NULL);
                if(j==4)
                {
                    LineTo(hdc, pos, 6);
                    MoveToEx(hdc, pos, mid - 5, NULL);
                    LineTo(hdc, pos, mid + 6);
                    MoveToEx(hdc, pos, rect.bottom-1, NULL);
                    LineTo(hdc, pos, rect.bottom-7);
                }
                else
                {
                    LineTo(hdc, pos, 3);
                    MoveToEx(hdc, pos, mid - 2, NULL);
                    LineTo(hdc, pos, mid + 3);
                    MoveToEx(hdc, pos, rect.bottom-1, NULL);
                    LineTo(hdc, pos, rect.bottom-4);
                }
            }
            pos = pos + (double) xdiv / 10;
        }
    }
    if(ydiv > 20)
    {
        mid = (double) (rect.right - 1) / 2 + 0.5;
        pos = 0;
        for(i = 0.5; i < rect.bottom; i = i + ydiv)
        {
            for(j = 0; j < 9; j++)
            {
                pos = pos + (double) ydiv / 10;
                MoveToEx(hdc, 0, pos,NULL);
                if(j==4)
                {
                    LineTo(hdc, 6, pos);
                    MoveToEx(hdc, mid - 5, pos, NULL);
                    LineTo(hdc, mid + 6, pos);
                    MoveToEx(hdc, rect.right-1, pos, NULL);
                    LineTo(hdc, rect.right-7, pos);
                }
                else
                {
                    LineTo(hdc, 3, pos);
                    MoveToEx(hdc, mid - 2, pos, NULL);
                    LineTo(hdc, mid + 3, pos);
                    MoveToEx(hdc, rect.right-1, pos, NULL);
                    LineTo(hdc, rect.right-4, pos);
                }
            }
            pos = pos + (double) ydiv / 10;
        }
    }

    SelectObject(hdc, GetStockObject(BLACK_PEN));
    DeleteObject(hPen);
    return 0;
}

int drawSpectMagGrid(HWND hwnd, HDC hdc)
{
    double xdiv, ydiv, i, mid, pos;
    double minmagn, maxmagn, yDec;
    int j, k, temp;
    RECT rect;
    HPEN hPen, hPenB;

    GetClientRect(hwnd, &rect);
    ydiv = ((double) (rect.bottom - 1)) / SPECTDIVY;
    xdiv = ((double) (rect.right - 1)) / DIVISIONSX;
    if(ydiv <= 0) ydiv = 1;
    if(xdiv <= 0) xdiv = 1;
    hPen = CreatePen(PS_SOLID, 0, gridColor);
    hPenB = CreatePen(PS_DOT, 0, gridColor);
    SelectObject(hdc, hPen);

   /* Draw the vertical lines */
    for (i = 0.5; i < rect.right; i = i + xdiv)
    {
        MoveToEx(hdc, i, rect.bottom, NULL);
        LineTo(hdc, i, 0);
    }

    if(dispmode & MODE_FREQMAGLOG)
    {
        /* logrithmic magnitude */
        if(chAVoltDiv > chBVoltDiv)
        {
            maxmagn = chAVoltDiv*10;
            minmagn = chBVoltDiv/1000;
        }
        else
        {
            maxmagn = chBVoltDiv*10;
            minmagn = chAVoltDiv/1000;
        }
        if(minmagn < 0.0001) minmagn = 0.0001;

        temp = GetBkMode(hdc);
        SetBkMode(hdc, TRANSPARENT);
        yDec = (rect.bottom - 2)/(log10(maxmagn/minmagn));
        for(k = log10(minmagn)-0.5; k <= log10(maxmagn); k++)
        {
            SelectObject(hdc, hPen);
            pos = (rect.bottom - 1) - yDec*(k-log10(minmagn));
            MoveToEx(hdc, 0, pos, NULL);
            LineTo(hdc, rect.right, pos);
            SelectObject(hdc, hPenB);
            for(j = 2; j < 10; j++)
            {
                pos = (rect.bottom - 1) - yDec*(k+log10(j)-log10(minmagn));
                MoveToEx(hdc, 0, pos, NULL);
                LineTo(hdc, rect.right, pos);
            }
        }
        SetBkMode(hdc, temp);
        /* Draw the horizontal lines at top and bottom */
        SelectObject(hdc, hPen);
        MoveToEx(hdc, 0, 0, NULL);
        LineTo(hdc, rect.right, 0);
        MoveToEx(hdc, 0, rect.bottom-1, NULL);
        LineTo(hdc, rect.right, rect.bottom-1);
    }
    else
    {
        /* Scalar magnitude */
        if(chAVoltDiv > chBVoltDiv)
            maxmagn = 10*chAVoltDiv;
        else
            maxmagn = 10*chBVoltDiv;
        minmagn = 0;
        yDec = (rect.bottom - 2)/maxmagn*5;
        /* Draw the horizontal lines */
        for (i = 0.5; i < rect.bottom; i = i + ydiv)
        {
            MoveToEx(hdc, 0, i, NULL);
            LineTo(hdc, rect.right, i);
        }
    }
    SelectObject(hdc, GetStockObject(BLACK_PEN));
    DeleteObject(hPen);
    DeleteObject(hPenB);
    return 0;
}

/* Helper function for the spectrum magnitude, returns the y coordinate for the magnitude value
 * rect: rectangle of the window
 * yDec: distance between divisions
 * maxmagn: top of scale
 * minmagn: bottom of scale
 * y: magnitude value to return the y coordinate for
 * return: the y coordinate for the magnitude value
 */
double spectMagn(RECT rect, double yDec, double maxmagn, double minmagn, double y)
{
    if(dispmode & MODE_FREQMAGLOG)
    {
        /* logrithmic magnitude */
        if(y <= 0) y = minmagn/10;
        return rect.bottom - 1 - yDec*log10(y/minmagn);
    }
    else
    {
        /* Scalar magnitude */
        return (rect.bottom - 1) - yDec*y;
    }
}

/* Find the approximate sinc function given an angle.
 * Error is between -0.0029 and 0.00096 or less than 0.5% error.
 * Included for optimization of sinc reconstruction.
 * Slightly faster than using
 * if(angle == 0) return 1; else return sin(angle)/angle;
 */
double mySinc(double angle)
{
    int i;
    double twopi, sangle, est, sanglePwr2, sanglePwr3, sanglePwr5;

    if(angle == 0)
        return 1;
    twopi = 2 * M_PI;
    i = angle / twopi;
    sangle = angle - i*twopi;
    if(sangle < 0)
        sangle = sangle + twopi;
    if(sangle > M_PI_2)
        sangle = M_PI - sangle;
    if(sangle < - M_PI_2)
        sangle = -M_PI - sangle;

    sanglePwr2 = sangle*sangle;
    sanglePwr3 = sangle*sanglePwr2;
    sanglePwr5 = sanglePwr3*sanglePwr2;

    est = sangle - sanglePwr3/6.0 + sanglePwr5/120.0;
    return est/angle;
}

/* Find the cosine of an angle.  Less than 0.1% error.
 * Included for optimization of speed for sinc reconstruction.
 * Sacrifices precision and accuracy, but less than 0.1% error is good enough
 * for drawing on a screen.
 */
float myCos(float angle)
{
    int i;
    float twopi, m, est, anglePwr, anglePwrInc;
    twopi = 2 * M_PI;
    i = angle / twopi;
    angle = angle - i * twopi;
    if(angle < 0)
        angle = angle + twopi;
    if(angle > M_PI)
        angle = angle - twopi;

    m = 1;
    if (angle > M_PI_2)
    {
        angle = angle - M_PI;
        m = -1;
    }
    else if(angle < -M_PI_2)
    {
        angle = angle + M_PI;
        m = -1;
    }

    anglePwr = angle*angle;
    anglePwrInc = anglePwr*anglePwr;
    return (m*(1 - anglePwr / 2 + anglePwrInc / 24 - anglePwr*anglePwrInc / 720));
}

/* Draws the spectrum magnitude channel
 * rect: the rectangle of the window
 * hdc: the hdc of the window
 * channel[]: spectrum magnitude information
 * return: 0
 */
int drawSpectMagn(RECT rect, HDC hdc, double channel[], int cColor, int pWidth)
{
    POINT ppt[BUFFER_MAX*3];
    HPEN hPen;
    double deltaX, deltaY;
    double y, x, s, b, q, bst, sst;
    int ubc, i, c, a, st, en;
    double minmagn, maxmagn, yDec;
    double chPhase[BUFFER_MAX], chFreq[BUFFER_MAX];

    ubc = getMaxSamplesPerChannel();                   /* Set up dimensions */
//    deltaX = ((double) (rect.right - 2)) / ((double) ubc / 2 - 1);
    deltaX = ((double) (rect.right - 2)) / ((double) ubc / 2);

    if(dispmode & MODE_FREQMAGLOG)
    {
        /* logrithmic magnitude */
        maxmagn = chAVoltDiv;
        if(getChannelEnabled(CHANNELB) && (chBVoltDiv > maxmagn))
            maxmagn = chBVoltDiv;
        if(getChannelEnabled(CHANNELC) && (chCVoltDiv > maxmagn))
            maxmagn = chCVoltDiv;
        if(getChannelEnabled(CHANNELD) && (chDVoltDiv > maxmagn))
            maxmagn = chDVoltDiv;
        maxmagn*=10;

        minmagn = chAVoltDiv;
        if(getChannelEnabled(CHANNELB) && (chBVoltDiv < minmagn))
            minmagn = chBVoltDiv;
        if(getChannelEnabled(CHANNELC) && (chCVoltDiv < minmagn))
            minmagn = chCVoltDiv;
        if(getChannelEnabled(CHANNELC) && (chCVoltDiv < minmagn))
            minmagn = chDVoltDiv;
        minmagn/=1000;

        if(minmagn < 0.0001) minmagn = 0.0001;
        yDec = (rect.bottom - 2)/(log10(maxmagn/minmagn));
    }
    else
    {
        /* Scalar magnitude */
        maxmagn = chAVoltDiv;
        if(getChannelEnabled(CHANNELB) && (chBVoltDiv > maxmagn))
            maxmagn = chBVoltDiv;
        if(getChannelEnabled(CHANNELC) && (chCVoltDiv > maxmagn))
            maxmagn = chCVoltDiv;
        if(getChannelEnabled(CHANNELD) && (chDVoltDiv > maxmagn))
            maxmagn = chDVoltDiv;
        maxmagn*=DIVISIONSY;

        minmagn = 0;
        yDec = (rect.bottom - 2)/maxmagn*2;
    }

    hPen = CreatePen(PS_SOLID, pWidth, cColor);        /* Pick line color */
    SelectObject(hdc, hPen);
    y = spectMagn(rect, yDec, maxmagn, minmagn, channel[0]);
    x = 1;
    MoveToEx(hdc, x, y, NULL);

    switch(reconst)
    {
    case RECONST_SQUARE:
        for(i=1; i < ubc; i++)
        {
            x += deltaX / 2;
            LineTo(hdc, x, y);
            y = spectMagn(rect, yDec, maxmagn, minmagn, channel[i]);
            LineTo(hdc, x, y);
            x += deltaX / 2;
            LineTo(hdc, x, y);
        }
        break;
    case RECONST_POINT:
        for(i=1; i < ubc; i++)
        {
            LineTo(hdc, x+1, y);
            y = spectMagn(rect, yDec, maxmagn, minmagn, channel[i]);
            x += deltaX;
            MoveToEx(hdc, x, y, NULL);
        }
        break;
    case RECONST_TRIANGLE:
        for(i=1; i < ubc; i++)
        {
            y = spectMagn(rect, yDec, maxmagn, minmagn, channel[i]);
            x += deltaX;
            LineTo(hdc, x, y);
        }
        break;
    case RECONST_BEZIER:
        ppt[0].y = y;
        ppt[0].x = x;
        a = 3;
        for(i=1; i < ubc; i++)
        {
            x += deltaX;
            ppt[a].y = spectMagn(rect, yDec, maxmagn, minmagn, channel[i]);
            ppt[a].x = x;
            a += 3;
        }
        ppt[1].x = 1+deltaX/3;
        ppt[2].x = 1+deltaX*2/3;
        ppt[2].y = (ppt[3].y + 2*ppt[0].y)/3;
        ppt[1].y = (2*ppt[3].y + ppt[0].y)/3;
        for(i=6;i < (ubc-1)*3; i+=3)
        {
            ppt[i-2].y = (4.0*ppt[i-3].y - ppt[i-6].y)/3.0;
            ppt[i-1].x = 1 + deltaX*(i-1.0)/3.0;
            ppt[i-1].y = (4.0*ppt[i].y - ppt[i+3].y)/3.0;
            ppt[i-2].x = 1 + deltaX*(i-2.0)/3.0;
        }
        i = (ubc-1)*3;

        if(i>=3)
        {
            ppt[i-1].x = 1 + deltaX*(i-1)/3;
            ppt[i-2].x = 1 + deltaX*(i-2)/3;
            ppt[i-2].y = (2*ppt[i-3].y + ppt[i].y)/3;
            ppt[i-1].y = (ppt[i-3].y + 2*ppt[i].y)/3;
        }

        PolyBezierTo(hdc, &ppt[1], i);

        break;
    case RECONST_SINC:
        a = rect.right - 1;
        if((ubc-1)*deltaX < a)
            a = (ubc-1)*deltaX;
        b = 1/deltaX;
        bst = 2*b;
        s = M_PI*b;
        sst = 2*s;
        for(x=1; x < a; x+=2)
        {
            y = 0;
            b += bst;
            c = floor(b);
            s += sst;
            st = c - 8;
            en = c + 9;
            if(st < 0) st = 0;
            if(en > ubc) en = ubc;
            q = st*M_PI - s;
            for(i = st; i < en; i++)
            {
                y += channel[i]*mySinc(q);
                q += M_PI;
            }
            y = spectMagn(rect, yDec, maxmagn, minmagn, y);
            LineTo(hdc, x, y);
        }
        break;
    }

    SelectObject(hdc, GetStockObject(BLACK_PEN));
    DeleteObject(hPen);
    return 0;
}

int drawSpectPhaseGrid(HWND hwnd, HDC hdc)
{
    double xdiv, ydiv, i, mid, pos;
    int j;
    RECT rect;
    HPEN hPen;

    GetClientRect(hwnd, &rect);
    ydiv = (double) (rect.bottom - 1) / SPECTPHDIVY;
    xdiv = (double) (rect.right - 1) / DIVISIONSX;
    if(ydiv <= 0) ydiv = 1;
    if(xdiv <= 0) xdiv = 1;
    hPen = CreatePen(PS_SOLID, 0, gridColor);
    SelectObject(hdc, hPen);
   /* Draw the vertical lines */
    for (i = 0.5; i < rect.right; i = i + xdiv)
    {
        MoveToEx(hdc, i, rect.bottom, NULL);
        LineTo(hdc, i, 0);
    }
    /* Draw the horizontal lines */
    for (i = 0.5; i < rect.bottom; i = i + ydiv)
    {
        MoveToEx(hdc, 0, i, NULL);
        LineTo(hdc, rect.right, i);
    }
    SelectObject(hdc, GetStockObject(BLACK_PEN));
    DeleteObject(hPen);
    return 0;
}

/* Draws the phase for the spectrum graph
 * rect: rectangle of the window
 * hdc: hdc of the window
 * channel[]: spectrum phase data
 * cColor: pin color to draw with
 * pWidth: width of the pin in pixels */
int drawSpectPhase(RECT rect, HDC hdc, double channel[], int cColor, int pWidth)
{
    POINT ppt[BUFFER_MAX*3];
    HPEN hPen;
    double deltaX, deltaY;
    double y, x, s, b, q, bst, sst;
    int ubc, i, a, c, en, st;
    double chFreq[BUFFER_MAX], chPhase[BUFFER_MAX];

    ubc = getMaxSamplesPerChannel();                   /* Set up dimensions */
//    deltaX = ((double) (rect.right - 2)) / ((double) ubc / 2 - 1);
    deltaX = ((double) (rect.right - 2)) / ((double) ubc / 2);
    deltaY = ((double) (rect.bottom - 1)) / SPECTPHDIVY;
    hPen = CreatePen(PS_SOLID, pWidth, cColor);        /* Pick line color */
    SelectObject(hdc, hPen);
    y = deltaY*SPECTPHDIVY/2-deltaY*(channel[0])/M_PI*2;
    x = 1;
    MoveToEx(hdc, x, y, NULL);
    switch(reconst)
    {
    case RECONST_SQUARE:
        for(i=1; i < ubc; i++)
        {
            x += deltaX / 2;
            LineTo(hdc, x, y);
            y = deltaY*SPECTPHDIVY/2-deltaY*(channel[i])/M_PI*2;
            LineTo(hdc, x, y);
            x += deltaX / 2;
            LineTo(hdc, x, y);
        }
        break;
    case RECONST_POINT:
        for(i=1; i < ubc; i++)
        {
            LineTo(hdc, x+1, y);
            y = deltaY*SPECTPHDIVY/2-deltaY*(channel[i])/M_PI*2;
            x += deltaX;
            MoveToEx(hdc, x, y, NULL);
        }
        break;
    case RECONST_BEZIER:
        ppt[0].y = y;
        ppt[0].x = x;
        a = 3;
        for(i=1; i < ubc; i++)
        {
            x += deltaX;
            ppt[a].y = deltaY*SPECTPHDIVY/2-deltaY*(channel[i])/M_PI*2;
            ppt[a].x = x;
            a += 3;
        }
        ppt[1].x = 1+deltaX/3;
        ppt[2].x = 1+deltaX*2/3;
        ppt[2].y = (ppt[3].y + 2*ppt[0].y)/3;
        ppt[1].y = (2*ppt[3].y + ppt[0].y)/3;
        for(i=6;i < (ubc-1)*3; i+=3)
        {
            ppt[i-2].y = (4.0*ppt[i-3].y - ppt[i-6].y)/3.0;
            ppt[i-1].x = 1 + deltaX*(i-1.0)/3.0;
            ppt[i-1].y = (4.0*ppt[i].y - ppt[i+3].y)/3.0;
            ppt[i-2].x = 1 + deltaX*(i-2.0)/3.0;
        }
        i = (ubc-1)*3;

        if(i>=3)
        {
            ppt[i-1].x = 1 + deltaX*(i-1)/3;
            ppt[i-2].x = 1 + deltaX*(i-2)/3;
            ppt[i-2].y = (2*ppt[i-3].y + ppt[i].y)/3;
            ppt[i-1].y = (ppt[i-3].y + 2*ppt[i].y)/3;
        }

        PolyBezierTo(hdc, &ppt[1], i);

        break;
    case RECONST_TRIANGLE:
        for(i=1; i < ubc; i++)
        {
            y = deltaY*SPECTPHDIVY/2-deltaY*(channel[i])/M_PI*2;
            x += deltaX;
            LineTo(hdc, x, y);
        }
        break;
    case RECONST_SINC:
        a = rect.right - 1;
        if((ubc-1)*deltaX < a)
            a = (ubc-1)*deltaX;
        b = 1/deltaX;
        bst = 2*b;
        s = M_PI*b;
        sst = 2*s;
        for(x=1; x < a; x+=2)
        {
            y = 0;
            b += bst;
            c = floor(b);
            s += sst;
            st = c - 8;
            en = c + 9;
            if(st < 0) st = 0;
            if(en > ubc) en = ubc;
            q = st*M_PI - s;
            for(i = st; i < en; i++)
            {
                y += channel[i]*mySinc(q);
                q += M_PI;
            }
            y = deltaY*(SPECTPHDIVY/2-y/M_PI*2);
            LineTo(hdc, x, y);
        }
        break;
    }

    SelectObject(hdc, GetStockObject(BLACK_PEN));
    DeleteObject(hPen);
    return 0;
}

/* Draw the channel on the oscilloscope
 * rect: rectangle of the window
 * hdc: hdc of the window
 * channel[]: time domain data for the signal
 * chOffset: offset from zero
 * chVoltDiv: vertical scale
 * chDelay: post trigger delay
 * cChannel: currentChannel
 * cColor: color of the pin to use
 * pWidth: width of the pin in pixels */
int drawChannel(RECT rect, HDC hdc, double channel[], double chFreq[],
    double chPhase[], double chOffset, double chVoltDiv, char cChannel, int cColor, int pWidth)
{
    POINT ppt[BUFFER_MAX*3];
    HPEN hPen;
    double deltaX, deltaY;
    double y, x, s, b, q, sst, bst;
    int ubc, i, a, c, st, en;

    ubc = sampleCount[cChannel];
    /* Set up dimensions */
    deltaX = ((double) (rect.right - 2)) / getTimePerDivision() / DIVISIONSX / sampleRate[cChannel];
    deltaY = ((double) (rect.bottom - 2)) / DIVISIONSY;
    hPen = CreatePen(PS_SOLID, pWidth, cColor);        /* Pick line color */
    y = 1+deltaY*DIVISIONSY/2-deltaY*(channel[0] + chOffset)/chVoltDiv;
    x = 1;
    MoveToEx(hdc, x, y, NULL);
    SelectObject(hdc, hPen);
    switch(reconst)
    {
    case RECONST_SQUARE:
        for(i=1; i < ubc; i++)
        {
            x += deltaX / 2;
            LineTo(hdc, x, y);
            y = 1+deltaY*DIVISIONSY/2-deltaY*(channel[i] + chOffset)/chVoltDiv;
            LineTo(hdc, x, y);
            x += deltaX / 2;
            LineTo(hdc, x, y);
        }
        break;
    case RECONST_POINT:
        for(i=1; i < ubc; i++)
        {
            y = 1+deltaY*DIVISIONSY/2-deltaY*(channel[i] + chOffset)/chVoltDiv;
            x += deltaX;
            MoveToEx(hdc, x, y, NULL);
            LineTo(hdc, x+1, y);
        }
        break;
    case RECONST_BEZIER:
        ppt[0].y = y;
        ppt[0].x = x;
        a = 3;
        for(i=1; i < ubc; i++)
        {
            x += deltaX;
            ppt[a].y = 1+deltaY*DIVISIONSY/2-deltaY*(channel[i] + chOffset)/chVoltDiv;
            ppt[a].x = x;
            a += 3;
        }
        ppt[1].x = 1+deltaX/3;
        ppt[2].x = 1+deltaX*2/3;
        ppt[2].y = (ppt[3].y + 2*ppt[0].y)/3;
        ppt[1].y = (2*ppt[3].y + ppt[0].y)/3;
        for(i=6;i < (ubc-1)*3; i+=3)
        {
            ppt[i-2].y = (4.0*ppt[i-3].y - ppt[i-6].y)/3.0;
            ppt[i-1].x = 1 + deltaX*(i-1.0)/3.0;
            ppt[i-1].y = (4.0*ppt[i].y - ppt[i+3].y)/3.0;
            ppt[i-2].x = 1 + deltaX*(i-2.0)/3.0;
        }
        i = (ubc-1)*3;
        if(i>=3)
        {
            ppt[i-1].x = 1 + deltaX*(i-1)/3;
            ppt[i-2].x = 1 + deltaX*(i-2)/3;
            ppt[i-2].y = (2*ppt[i-3].y + ppt[i].y)/3;
            ppt[i-1].y = (ppt[i-3].y + 2*ppt[i].y)/3;
        }
        PolyBezierTo(hdc, &ppt[1], i);
        break;
    case RECONST_TRIANGLE:
        for(i=1; i < ubc; i++)
        {
            y = 1+deltaY*DIVISIONSY/2-deltaY*(channel[i] + chOffset)/chVoltDiv;
            x += deltaX;
            LineTo(hdc, x, y);
        }
        break;
    case RECONST_SINC:
        a = rect.right - 1;
        if((ubc-1)*deltaX < a)
            a = (ubc-1)*deltaX;
        b = 1/deltaX;
        bst = 2*b;
        s = M_PI*b;
        sst = 2*s;
        for(x=1; x < a; x+=2)
        {
            y = 0;
            b += bst;
            c = floor(b);
            s += sst;
            st = c - 8;
            en = c + 9;
            if(st < 0) st = 0;
            if(en > ubc) en = ubc;
            q = st*M_PI - s;
            for(i = st; i < en; i++)
            {
                y += channel[i]*mySinc(q);
                q += M_PI;
            }
            y = 1+deltaY*(DIVISIONSY/2 - (y + chOffset)/chVoltDiv);
            LineTo(hdc, x, y);
        }
        break;
    }

    SelectObject(hdc, GetStockObject(BLACK_PEN));
    DeleteObject(hPen);
    return 0;
}

/* Draws the channels for XY mode
 * rect: rectangle of the window
 * hdc: hdc of the window
 * channelA: channel A time domain information
 * channelB: channel B time domain information
 * cChannel: current channel
 * cColor: color to draw
 * pWidth: pixel width */
int drawXYChannel(RECT rect, HDC hdc, double chY[], double chX[],
    double chYFreq[], double chXFreq[], double chYPhase[], double chXPhase[],
    char cchannel, int cColor, int pWidth, double chYVoltDiv, double chXVoltDiv, double chYOffset, double chXOffset)
{
    HPEN hPen;
    double deltaX, deltaY;
    double y, x, t, s, b, q, bst, sst, d;
    int ubc, i, a ,c, st, en;
    POINT ppt[BUFFER_MAX*3];

    ubc = sampleCount[cchannel];                   /* Set up dimensions */
    deltaX = ((double) (rect.right - 2)) / DIVISIONSX;
    deltaY = ((double) (rect.bottom - 2)) / DIVISIONSY;
    hPen = CreatePen(PS_SOLID, pWidth, cColor);        /* Pick line color */
    SelectObject(hdc, hPen);
    y = 1+deltaY*DIVISIONSY/2-deltaY*(chY[0] + chYOffset)/chYVoltDiv;
    x = deltaX*DIVISIONSX/2+deltaX*(chX[0] + chXOffset)/chXVoltDiv;
    MoveToEx(hdc, x, y, NULL);

    switch(reconst)
    {
    case RECONST_SQUARE:
        for(i=1; i < ubc; i++)
        {
            x = deltaX*DIVISIONSX/2+deltaX*(chX[i] + chXOffset)/chXVoltDiv;
            LineTo(hdc, x, y);
            y = 1+deltaY*DIVISIONSY/2-deltaY*(chY[i] + chYOffset)/chYVoltDiv;
            LineTo(hdc, x, y);
        }
        break;
    case RECONST_POINT:
        for(i=1; i < ubc; i++)
        {
            LineTo(hdc, x+1, y);
            y = 1+deltaY*DIVISIONSY/2-deltaY*(chY[i] + chYOffset)/chYVoltDiv;
            x = 1+deltaX*DIVISIONSX/2+deltaX*(chX[i] + chXOffset)/chXVoltDiv;
            MoveToEx(hdc, x, y, NULL);
        }
        break;
    case RECONST_TRIANGLE:
        for(i=1; i < ubc; i++)
        {
            y = 1+deltaY*DIVISIONSY/2-deltaY*(chY[i] + chYOffset)/chYVoltDiv;
            x = 1+deltaX*DIVISIONSX/2+deltaX*(chX[i] + chXOffset)/chXVoltDiv;
            LineTo(hdc, x, y);
        }
        break;
    case RECONST_SINC:
        a = rect.right - 1;
        b = ((double) (ubc-1)) / ((double) (a - 1));
        bst = 2*b;
        s = M_PI*b;
        sst = 2*s;
        for(t=1; t < a; t+=2)
        {
            x = 0;
            y = 0;
            b += bst;
            c = floor(b);
            s += sst;
            st = c - 8;
            en = c + 9;
            if(st < 0) st = 0;
            if(en > ubc) en = ubc;
            q = st*M_PI - s;
            for(i = st; i < en; i++)
            {
                d = mySinc(q);
                y += chY[i]*d;
                x += chX[i]*d;
                q += M_PI;
            }
            x = 1+deltaX*(DIVISIONSX/2 + (x + chXOffset)/chXVoltDiv);
            y = 1+deltaY*(DIVISIONSY/2 - (y + chYOffset)/chYVoltDiv);
            LineTo(hdc, x, y);
        }
        break;
    case RECONST_BEZIER:
        ppt[0].y = y;
        ppt[0].x = x;
        a = 3;
        for(i=1; i < ubc; i++)
        {
            ppt[a].y = 1+deltaY*DIVISIONSY/2-deltaY*(chY[i] + chYOffset)/chYVoltDiv;
            ppt[a].x = 1+deltaX*DIVISIONSX/2+deltaX*(chX[i] + chXOffset)/chXVoltDiv;;
            a += 3;
        }
        ppt[2].x = (ppt[3].x + 2*ppt[0].x)/3;
        ppt[1].x = (2*ppt[3].x + ppt[0].x)/3;
        ppt[2].y = (ppt[3].y + 2*ppt[0].y)/3;
        ppt[1].y = (2*ppt[3].y + ppt[0].y)/3;
        for(i=6;i < (ubc-1)*3; i+=3)
        {
            ppt[i-2].y = (4.0*ppt[i-3].y - ppt[i-6].y)/3.0;
            ppt[i-1].x = (4.0*ppt[i].x - ppt[i+3].x)/3.0;
            ppt[i-1].y = (4.0*ppt[i].y - ppt[i+3].y)/3.0;
            ppt[i-2].x = (4.0*ppt[i-3].x - ppt[i-6].x)/3.0;
        }
        i = (ubc-1)*3;

        if(i>=3)
        {
            ppt[i-2].x = (2*ppt[i-3].x + ppt[i].x)/3;
            ppt[i-1].x = (ppt[i-3].x + 2*ppt[i].x)/3;
            ppt[i-2].y = (2*ppt[i-3].y + ppt[i].y)/3;
            ppt[i-1].y = (ppt[i-3].y + 2*ppt[i].y)/3;
        }

        PolyBezierTo(hdc, &ppt[1], i);

        break;
    }
    SelectObject(hdc, GetStockObject(BLACK_PEN));
    DeleteObject(hPen);
    return 0;
}

/* Draws the cursors on the main screen
 * rect: the rectangle of the window
 * hdc: the hdc of the window */
int drawCursors(RECT rect, HDC hdc)
{
    HPEN hPen;
    double x, y;
    int i;

    for(i = 0; i < 2; i++)
    {
        hPen = CreatePen(PS_SOLID, 0, curColor[i]);
        SelectObject(hdc, hPen);
        if(xCurPos[i] >= 0)
        {
            MoveToEx(hdc, xCurPos[i], 1, NULL);
            LineTo(hdc, xCurPos[i], rect.bottom-1);
            MoveToEx(hdc, 1, yCurPos[i], NULL);
            LineTo(hdc, rect.right-1, yCurPos[i]);
        }
        SelectObject(hdc, GetStockObject(BLACK_PEN));
        DeleteObject(hPen);
    }
    return 0;
}

int drawScopeHelper(HWND hwnd, char wType, HDC hdcBuffer, HBITMAP hbmBuffer, HDC hdctemp, HBITMAP hbmtemp)
{
    HDC hdc;
    RECT rect;
    HBRUSH bBrush;
    BLENDFUNCTION bf;
    HFONT uFont;
    TEXTMETRIC tm;
    char a[100];


    hdc = GetDC(hwnd);
    GetClientRect(hwnd, &rect);

    //HBITMAP hbmOldBuffer = SelectObject(hdcBuffer, hbmBuffer);
    bf.BlendOp = AC_SRC_OVER;
    bf.BlendFlags = 0;
    bf.AlphaFormat = 0;
    bf.SourceConstantAlpha = persistence;

    bBrush = CreateSolidBrush(bColor);
    if (!(dispmode & MODE_HOLD) && wType != SCOPE_MEASUREMENTS)
    {
        /*bBrush = (HBRUSH) SelectObject(hdcBuffer, bBrush);
        Rectangle(hdcBuffer, rect.left, rect.top, rect.right, rect.bottom);
        AlphaBlend(        char* a = GetWindowText(GetDlgItem(hPnl, MATH_F1))
        TextOut(hdcBuffer, 5,5,a, strlen(a));
hdcBuffer, 0, 0, rect.right, rect.bottom, hdc, 0, 0, rect.right, rect.bottom, bf);*/
        SelectObject(hdctemp, hbmtemp);
        bBrush = (HBRUSH) SelectObject(hdctemp, bBrush);
        Rectangle(hdctemp, rect.left, rect.top, rect.right, rect.bottom);
        AlphaBlend(hdcBuffer, 0, 0, rect.right, rect.bottom, hdctemp, 0, 0, rect.right, rect.bottom, bf);
    }
    else
    {
        SelectObject(hdctemp, hbmtemp);
        BitBlt(hdctemp, 0, 0, rect.right, rect.bottom, hdcBuffer, 0, 0, SRCCOPY);
    }
    SelectObject(hdc, GetStockObject(BLACK_BRUSH));
    DeleteObject(bBrush);

    switch(wType)
    {
    case SCOPE_SCREEN:

        /* Erase channels */
        if(dispmode & MODE_XY)
        {
                if((dispmode & MODE_HOLD) && (chDraw & DRAWOLDSCR))
                {
                    if(dispmode & MODE_CHAENABLED)
                    {
                       if(dispmode & MODE_CHBENABLED)
                            drawXYChannel(rect, hdcBuffer, channelA[currentChannel],
                                channelB[currentChannel], chAfreqMag[currentChannel],
                                chBfreqMag[currentChannel], chAfreqPhase[currentChannel],
                                chBfreqPhase[currentChannel], !currentChannel, DIMCOLOR(chAColor, bColor),weight[0],
                                chAVoltDiv, chBVoltDiv, chAOffset, chBOffset);
                       else if(dispmode & MODE_CHDENABLED)
                            drawXYChannel(rect, hdcBuffer, channelA[currentChannel],
                                channelD[currentChannel], chAfreqMag[currentChannel],
                                chDfreqMag[currentChannel], chAfreqPhase[currentChannel],
                                chDfreqPhase[currentChannel], !currentChannel, DIMCOLOR(chAColor, bColor),weight[0],
                                chAVoltDiv, chDVoltDiv, chAOffset, chDOffset);
                    }
                    if(dispmode & MODE_CHCENABLED)
                    {
                       if(dispmode & MODE_CHDENABLED)
                            drawXYChannel(rect, hdcBuffer, channelC[currentChannel],
                                channelD[currentChannel], chCfreqMag[currentChannel],
                                chDfreqMag[currentChannel], chCfreqPhase[currentChannel],
                                chDfreqPhase[currentChannel], !currentChannel, DIMCOLOR(chCColor, bColor),weight[2],
                                chCVoltDiv, chDVoltDiv, chCOffset, chDOffset);
                       else if(dispmode & MODE_CHBENABLED)
                            drawXYChannel(rect, hdcBuffer, channelC[currentChannel],
                                channelB[currentChannel], chCfreqMag[currentChannel],
                                chBfreqMag[currentChannel], chCfreqPhase[currentChannel],
                                chBfreqPhase[currentChannel], !currentChannel, DIMCOLOR(chCColor, bColor),weight[2],
                                chCVoltDiv, chBVoltDiv, chCOffset, chBOffset);
                    }
                }
                /*else
                    drawXYChannel(rect, hdcBuffer, channelA[!currentChannel],
                        channelB[!currentChannel], chAfreqMag[!currentChannel],
                        chBfreqMag[!currentChannel], chAfreqPhase[!currentChannel],
                        chBfreqPhase[!currentChannel], !currentChannel, bColor, weight[0]);*/
        }
        else
        {
            if(dispmode & MODE_CHAENABLED)
                if((dispmode & MODE_HOLD) && (chDraw & DRAWOLDSCR))
                    drawChannel(rect, hdcBuffer, channelA[!currentChannel],
                        chAfreqMag[!currentChannel], chAfreqPhase[!currentChannel],
                        chAOffset, chAVoltDiv, !currentChannel, DIMCOLOR(chAColor, bColor),weight[0]);
                /*else
                    drawChannel(rect, hdcBuffer, channelA[!currentChannel],
                        chAfreqMag[!currentChannel], chAfreqPhase[!currentChannel],
                        chAOffset, chAVoltDiv, !currentChannel, bColor, weight[0]);*/

            if(dispmode & MODE_CHBENABLED)
                if((dispmode & MODE_HOLD) && (chDraw & DRAWOLDSCR))
                    drawChannel(rect, hdcBuffer, channelB[!currentChannel],
                        chBfreqMag[!currentChannel], chBfreqPhase[!currentChannel],
                        chBOffset, chBVoltDiv, !currentChannel, DIMCOLOR(chBColor, bColor),weight[1]);
                /*else
                    drawChannel(rect, hdcBuffer, channelB[!currentChannel],
                        chBfreqMag[!currentChannel], chBfreqPhase[!currentChannel],
                        chBOffset, chBVoltDiv, !currentChannel, bColor, weight[1]);*/

            if(dispmode & MODE_CHCENABLED)
                if((dispmode & MODE_HOLD) && (chDraw & DRAWOLDSCR))
                    drawChannel(rect, hdcBuffer, channelC[!currentChannel],
                        chCfreqMag[!currentChannel], chCfreqPhase[!currentChannel],
                        chCOffset, chCVoltDiv, !currentChannel, DIMCOLOR(chCColor, bColor),weight[2]);

            if(dispmode & MODE_CHDENABLED)
                if((dispmode & MODE_HOLD) && (chDraw & DRAWOLDSCR))
                    drawChannel(rect, hdcBuffer, channelD[!currentChannel],
                        chDfreqMag[!currentChannel], chDfreqPhase[!currentChannel],
                        chDOffset, chDVoltDiv, !currentChannel, DIMCOLOR(chDColor, bColor),weight[3]);

        }

        /* Draw grid */
        drawScopeGrid(hwnd, hdcBuffer);

        /* Draw channels */
        if((dispmode & MODE_XY) && (chDraw & DRAWSCR))
        {
            if(dispmode & MODE_CHAENABLED)
            {
               if(dispmode & MODE_CHBENABLED)
                    drawXYChannel(rect, hdcBuffer, channelA[currentChannel],
                        channelB[currentChannel], chAfreqMag[currentChannel],
                        chBfreqMag[currentChannel], chAfreqPhase[currentChannel],
                        chBfreqPhase[currentChannel], currentChannel, chAColor,weight[0],
                        chAVoltDiv, chBVoltDiv, chAOffset, chBOffset);
               else if(dispmode & MODE_CHDENABLED)
                    drawXYChannel(rect, hdcBuffer, channelA[currentChannel],
                        channelD[currentChannel], chAfreqMag[currentChannel],
                        chDfreqMag[currentChannel], chAfreqPhase[currentChannel],
                        chDfreqPhase[currentChannel], currentChannel, chAColor,weight[0],
                        chAVoltDiv, chDVoltDiv, chAOffset, chDOffset);
            }
            if(dispmode & MODE_CHCENABLED)
            {
               if(dispmode & MODE_CHDENABLED)
                    drawXYChannel(rect, hdcBuffer, channelC[currentChannel],
                        channelD[currentChannel], chCfreqMag[currentChannel],
                        chDfreqMag[currentChannel], chCfreqPhase[currentChannel],
                        chDfreqPhase[currentChannel], currentChannel, chCColor,weight[2],
                        chCVoltDiv, chDVoltDiv, chCOffset, chDOffset);
               else if(dispmode & MODE_CHBENABLED)
                    drawXYChannel(rect, hdcBuffer, channelC[currentChannel],
                        channelB[currentChannel], chCfreqMag[currentChannel],
                        chBfreqMag[currentChannel], chCfreqPhase[currentChannel],
                        chBfreqPhase[currentChannel], currentChannel, chCColor,weight[2],
                        chCVoltDiv, chBVoltDiv, chCOffset, chBOffset);

            }
        }
        else
        {
            if((dispmode & MODE_CHAENABLED) && (chDraw & DRAWSCR))
                drawChannel(rect, hdcBuffer, channelA[currentChannel],
                    chAfreqMag[currentChannel], chAfreqPhase[currentChannel],
                    chAOffset, chAVoltDiv, currentChannel, chAColor, weight[0]);
            if((dispmode & MODE_CHBENABLED) && (chDraw & DRAWSCR))
                drawChannel(rect, hdcBuffer, channelB[currentChannel],
                    chBfreqMag[currentChannel], chBfreqPhase[currentChannel],
                    chBOffset, chBVoltDiv, currentChannel, chBColor,weight[1]);
            if((dispmode & MODE_CHCENABLED) && (chDraw & DRAWSCR))
                drawChannel(rect, hdcBuffer, channelC[currentChannel],
                    chCfreqMag[currentChannel], chCfreqPhase[currentChannel],
                    chCOffset, chCVoltDiv, currentChannel, chCColor,weight[2]);
            if((dispmode & MODE_CHDENABLED) && (chDraw & DRAWSCR))
                drawChannel(rect, hdcBuffer, channelD[currentChannel],
                    chDfreqMag[currentChannel], chDfreqPhase[currentChannel],
                    chDOffset, chDVoltDiv, currentChannel, chDColor,weight[3]);
        }

        if(chDraw & DRAWSCR) chDraw = chDraw | DRAWOLDSCR;
        chDraw = chDraw | DRAWSCR;

        break;
    case SCOPE_FREQMAG:
        /* Erase channels */
        if(dispmode & MODE_CHAENABLED)
            if((dispmode & MODE_HOLD) && (chDraw & DRAWOLDFREQMAG))
                drawSpectMagn(rect, hdcBuffer, chAfreqMag[!currentChannel], DIMCOLOR(chAColor, bColor),weight[0]);
            /*else
                drawSpectMagn(rect, hdcBuffer, chAfreqMag[!currentChannel], bColor,weight[0]);*/

        if(dispmode & MODE_CHBENABLED)
            if((dispmode & MODE_HOLD) && (chDraw & DRAWOLDFREQMAG))
                drawSpectMagn(rect, hdcBuffer, chBfreqMag[!currentChannel], DIMCOLOR(chBColor, bColor),weight[1]);
            /*else
                drawSpectMagn(rect, hdcBuffer, chBfreqMag[!currentChannel], bColor,weight[1]);*/

        if(dispmode & MODE_CHCENABLED)
            if((dispmode & MODE_HOLD) && (chDraw & DRAWOLDFREQMAG))
                drawSpectMagn(rect, hdcBuffer, chCfreqMag[!currentChannel], DIMCOLOR(chCColor, bColor),weight[2]);

        if(dispmode & MODE_CHDENABLED)
            if((dispmode & MODE_HOLD) && (chDraw & DRAWOLDFREQMAG))
                drawSpectMagn(rect, hdcBuffer, chDfreqMag[!currentChannel], DIMCOLOR(chDColor, bColor),weight[3]);

        /* Draw grid */
        drawSpectMagGrid(hwnd, hdcBuffer);

        /* Draw channels */
        if((dispmode & MODE_CHAENABLED) && (chDraw & DRAWFREQMAG))
            drawSpectMagn(rect, hdcBuffer, chAfreqMag[currentChannel], chAColor,weight[0]);
        if((dispmode & MODE_CHBENABLED) && (chDraw & DRAWFREQMAG))
            drawSpectMagn(rect, hdcBuffer, chBfreqMag[currentChannel], chBColor,weight[1]);
        if((dispmode & MODE_CHCENABLED) && (chDraw & DRAWFREQMAG))
            drawSpectMagn(rect, hdcBuffer, chCfreqMag[currentChannel], chCColor,weight[2]);
        if((dispmode & MODE_CHDENABLED) && (chDraw & DRAWFREQMAG))
            drawSpectMagn(rect, hdcBuffer, chDfreqMag[currentChannel], chDColor,weight[3]);

        if(chDraw & DRAWFREQMAG) chDraw |= DRAWOLDFREQMAG;
        chDraw = chDraw | DRAWFREQMAG;

        break;

    case SCOPE_FREQPHASE:
        /* Erase channels */
        if(dispmode & MODE_CHAENABLED)
            if((dispmode & MODE_HOLD) && (chDraw & DRAWOLDFREQPHASE))
                drawSpectPhase(rect, hdcBuffer, chAfreqPhase[!currentChannel], DIMCOLOR(chAColor, bColor),weight[0]);
            /*else
                drawSpectPhase(rect, hdcBuffer, chAfreqPhase[!currentChannel], bColor,weight[0]);*/

        if(dispmode & MODE_CHBENABLED)
            if((dispmode & MODE_HOLD) && (chDraw & DRAWOLDFREQPHASE))
                drawSpectPhase(rect, hdcBuffer, chBfreqPhase[!currentChannel], DIMCOLOR(chBColor, bColor),weight[1]);
            /*else
                drawSpectPhase(rect, hdcBuffer, chBfreqPhase[!currentChannel], bColor,weight[1]);*/

        if(dispmode & MODE_CHCENABLED)
            if((dispmode & MODE_HOLD) && (chDraw & DRAWOLDFREQPHASE))
                drawSpectPhase(rect, hdcBuffer, chCfreqPhase[!currentChannel], DIMCOLOR(chCColor, bColor),weight[2]);

        if(dispmode & MODE_CHDENABLED)
            if((dispmode & MODE_HOLD) && (chDraw & DRAWOLDFREQPHASE))
                drawSpectPhase(rect, hdcBuffer, chDfreqPhase[!currentChannel], DIMCOLOR(chDColor, bColor),weight[3]);

        if(chDraw & DRAWFREQPHASE) chDraw |= DRAWOLDFREQPHASE;

        /* Draw grid */
        drawSpectPhaseGrid(hwnd, hdcBuffer);

        /* Draw channels */
        if((dispmode & MODE_CHAENABLED) && (chDraw & DRAWFREQPHASE))
            drawSpectPhase(rect, hdcBuffer, chAfreqPhase[currentChannel], chAColor,weight[0]);
        if((dispmode & MODE_CHBENABLED) && (chDraw & DRAWFREQPHASE))
            drawSpectPhase(rect, hdcBuffer, chBfreqPhase[currentChannel], chBColor,weight[1]);
        if((dispmode & MODE_CHCENABLED) && (chDraw & DRAWFREQPHASE))
            drawSpectPhase(rect, hdcBuffer, chCfreqPhase[currentChannel], chCColor,weight[2]);
        if((dispmode & MODE_CHDENABLED) && (chDraw & DRAWFREQPHASE))
            drawSpectPhase(rect, hdcBuffer, chDfreqPhase[currentChannel], chDColor,weight[3]);

        if(chDraw & DRAWFREQPHASE) chDraw |= DRAWOLDFREQPHASE;
        chDraw = chDraw | DRAWFREQPHASE;

        break;
    case SCOPE_MEASUREMENTS:
        bBrush = CreateSolidBrush(bColor);
        SelectObject(hdcBuffer, bBrush);
        Rectangle(hdcBuffer, rect.left, rect.top, rect.right, rect.bottom);
        SelectObject(hdcBuffer, GetStockObject(BLACK_BRUSH));
        DeleteObject(bBrush);

        uFont = CreateFont((rect.bottom - rect.top-10)/8, 0, 0, 0, 700, 0, 0, 0, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, FF_DONTCARE, "MS San Serif");
        SetBkColor(hdcBuffer, bColor);
        SetTextColor(hdcBuffer, gridColor);
        SelectObject(hdcBuffer, uFont);
        GetTextMetrics(hdcBuffer, &tm);
        GetWindowText(GetDlgItem(g_hPanel, MATH_F1), a, 100);

        int b = strlen(a);
        a[b++] = '(';
        GetWindowText(GetDlgItem(g_hPanel, MATHSRC_F1), &a[b], 100-b);
        b = strlen(a);
        a[b++] = ')';
        a[b++] = ':';
        a[b++] = ' ';
        GetWindowText(GetDlgItem(g_hPanel, ED_MATH_F1), &a[b], 100-b);
        TextOut(hdcBuffer, 5,5,a, strlen(a));

        GetWindowText(GetDlgItem(g_hPanel, MATH_F2), a, 100);
        b = strlen(a);
        a[b++] = '(';
        GetWindowText(GetDlgItem(g_hPanel, MATHSRC_F2), &a[b], 100-b);
        b = strlen(a);
        a[b++] = ')';
        a[b++] = ':';
        a[b++] = ' ';
        GetWindowText(GetDlgItem(g_hPanel, ED_MATH_F2), &a[b], 100-b);
        TextOut(hdcBuffer, 5,5+2*tm.tmHeight, a, strlen(a));

        GetWindowText(GetDlgItem(g_hPanel, MATH_F3), a, 100);
        b = strlen(a);
        a[b++] = '(';
        GetWindowText(GetDlgItem(g_hPanel, MATHSRC_F3), &a[b], 100-b);
        b = strlen(a);
        a[b++] = ')';
        a[b++] = ':';
        a[b++] = ' ';
        GetWindowText(GetDlgItem(g_hPanel, ED_MATH_F3), &a[b], 100-b);
        TextOut(hdcBuffer, 5,5+4*tm.tmHeight, a, strlen(a));

        GetWindowText(GetDlgItem(g_hPanel, MATH_F4), a, 100);
        b = strlen(a);
        a[b++] = '(';
        GetWindowText(GetDlgItem(g_hPanel, MATHSRC_F4), &a[b], 100-b);
        b = strlen(a);
        a[b++] = ')';
        a[b++] = ':';
        a[b++] = ' ';
        GetWindowText(GetDlgItem(g_hPanel, ED_MATH_F4), &a[b], 100-b);
        TextOut(hdcBuffer, 5,5+6*tm.tmHeight, a, strlen(a));

        SelectObject(hdcBuffer, GetStockObject(SYSTEM_FONT));
        DeleteObject(uFont);

        uFont = CreateFont((rect.bottom - rect.top - 10)/12, 0, 0, 0, 400, 0, 0, 0, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, FF_DONTCARE, "MS San Serif");
        SelectObject(hdcBuffer, uFont);
        StatisticText(mStat[0], a);
        TextOut(hdcBuffer, 7,7+tm.tmHeight, a, strlen(a));
        StatisticText(mStat[1], a);
        TextOut(hdcBuffer, 7,7+3*tm.tmHeight, a, strlen(a));
        StatisticText(mStat[2], a);
        TextOut(hdcBuffer, 7,7+5*tm.tmHeight, a, strlen(a));
        StatisticText(mStat[3], a);
        TextOut(hdcBuffer, 7,7+7*tm.tmHeight, a, strlen(a));

        SelectObject(hdcBuffer, GetStockObject(SYSTEM_FONT));
        DeleteObject(uFont);
        break;
    }

    if (!(dispmode & MODE_HOLD) || wType == SCOPE_MEASUREMENTS)
    {
        BitBlt(hdc, 0, 0, rect.right, rect.bottom, hdcBuffer, 0, 0, SRCCOPY);
    }
    else
    {
        bf.SourceConstantAlpha = 255 - bf.SourceConstantAlpha;
        AlphaBlend(hdcBuffer, 0,0,rect.right, rect.bottom, hdctemp, 0, 0, rect.right, rect.bottom, bf);
        BitBlt(hdc, 0, 0, rect.right, rect.bottom, hdcBuffer, 0, 0, SRCCOPY);
    }

    /* Draw the Cursors */
    if(hwnd == windowHandles[cursorWindow]) drawCursors(rect, hdc);

    /* Draw the trigger Icon */
    if(wType == SCOPE_SCREEN)
        drawTrigger(rect, hdc);
    ReleaseDC(hwnd, hdc);
    return 0;
}

int drawTrigger(RECT rect, HDC hdc)
{
    double trigA, trigB, trig;
    trigA = getTriggerLevel(1);
    trigB = getTriggerLevel(2);

    HPEN hPen;
    double deltaY;
    double y;

    deltaY = ((double) (rect.bottom - 2)) / DIVISIONSY;

    /* Draw Trigger Icon for channel A if enabled*/
    if(getChannelEnabled(0))
    {
        if(chAmakeup == CH1ONLY)
            trig = trigA;
        else if(chAmakeup == CH2ONLY)
            trig = trigB;
        else if(chAmakeup == NEGCH1ONLY)
            trig = -trigA;
        else if(chAmakeup == NEGCH2ONLY)
            trig = -trigB;
        else
            trig = getTriggerLevel(0);

        if(chAmakeup == CH1ONLY || chAmakeup == CH2ONLY || chAmakeup == NEGCH1ONLY || chAmakeup == NEGCH2ONLY)
            hPen = CreatePen(PS_SOLID, 0, chAColor);        /* Pick line color */
        else
            hPen = CreatePen(PS_SOLID, 0, trigColor);

        SelectObject(hdc, hPen);
        y = 1+deltaY*DIVISIONSY/2-deltaY*(trig + chAOffset)/chAVoltDiv;
        /* Draw "<-Tr" */
        MoveToEx(hdc, 1, y, NULL);
        LineTo(hdc, 2, y + 1);
        LineTo(hdc, 2, y - 1);
        LineTo(hdc, 3, y - 2);
        LineTo(hdc, 3, y + 2);
        LineTo(hdc, 4, y + 3);
        LineTo(hdc, 4, y - 3);
        LineTo(hdc, 5, y - 4);
        LineTo(hdc, 5, y + 5);

        /*MoveToEx(hdc, 1, y, NULL);
        LineTo(hdc, 5, y);
        MoveToEx(hdc, 3, y-2, NULL);
        LineTo(hdc, 1, y);
        LineTo(hdc, 4, y+3);
        MoveToEx(hdc, 5, y-2, NULL);
        LineTo(hdc, 7, y-2);
        LineTo(hdc, 6, y-2);
        LineTo(hdc, 6, y+2);
        MoveToEx(hdc, 8, y+1, NULL);
        LineTo(hdc, 8, y-1);
        LineTo(hdc, 10, y-1); */

        SelectObject(hdc, GetStockObject(BLACK_PEN));
        DeleteObject(hPen);
    }

    /* Draw Trigger Icon for channel B if enabled*/
    if(getChannelEnabled(1))
    {

        if(chBmakeup == CH1ONLY)
            trig = trigA;
        else if(chBmakeup == CH2ONLY)
            trig = trigB;
        else if(chBmakeup == NEGCH1ONLY)
            trig = -trigA;
        else if(chBmakeup == NEGCH2ONLY)
            trig = -trigB;
        else
            trig = getTriggerLevel(0);

        if(chBmakeup == CH1ONLY || chBmakeup == CH2ONLY || chBmakeup == NEGCH1ONLY || chBmakeup == NEGCH2ONLY)
            hPen = CreatePen(PS_SOLID, 0, chBColor);        /* Pick line color */
        else
            hPen = CreatePen(PS_SOLID, 0, trigColor);

        SelectObject(hdc, hPen);
        if(dispmode & MODE_XY)
        {
            deltaY = ((double) (rect.right - 2)) / DIVISIONSX;
            y = 1 + deltaY*DIVISIONSX/2+deltaY*(trig+chBOffset)/chBVoltDiv;
            MoveToEx(hdc, y, 1, NULL);
            LineTo(hdc, y + 1, 2);
            LineTo(hdc, y - 1, 2);
            LineTo(hdc, y - 2, 3);
            LineTo(hdc, y + 2, 3);
            LineTo(hdc, y + 3, 4);
            LineTo(hdc, y - 3, 4);
            LineTo(hdc, y - 4, 5);
            LineTo(hdc, y + 5, 5);

        }
        else
        {
            y = 1+deltaY*DIVISIONSY/2-deltaY*(trig + chBOffset)/chBVoltDiv;
            /* Draw "<-Tr" */
            MoveToEx(hdc, 1, y, NULL);
            LineTo(hdc, 2, y + 1);
            LineTo(hdc, 2, y - 1);
            LineTo(hdc, 3, y - 2);
            LineTo(hdc, 3, y + 2);
            LineTo(hdc, 4, y + 3);
            LineTo(hdc, 4, y - 3);
            LineTo(hdc, 5, y - 4);
            LineTo(hdc, 5, y + 5);


            /*MoveToEx(hdc, 1, y, NULL);
            LineTo(hdc, 5, y);
            MoveToEx(hdc, 3, y-2, NULL);
            LineTo(hdc, 1, y);
            LineTo(hdc, 4, y+3);
            MoveToEx(hdc, 5, y-2, NULL);
            LineTo(hdc, 7, y-2);
            LineTo(hdc, 6, y-2);
            LineTo(hdc, 6, y+2);
            MoveToEx(hdc, 8, y+1, NULL);
            LineTo(hdc, 8, y-1);
            LineTo(hdc, 10, y-1);*/
        }
        SelectObject(hdc, GetStockObject(BLACK_PEN));
        DeleteObject(hPen);

    }

    // Draw the negative trigger location at the top if necessary
    trig = getTriggerDelay();
    if(trig < 0)
    {
        if((dispmode & MODE_XY) == 0)
        {
            hPen = CreatePen(PS_SOLID, 0, trigColor);        /* Pick line color */
            SelectObject(hdc, hPen);
            deltaY = ((double) (rect.right - 2)) / DIVISIONSX;
            y = 1 + deltaY*(-trig)/timePerDivision;
            MoveToEx(hdc, y, 1, NULL);
            LineTo(hdc, y + 1, 2);
            LineTo(hdc, y - 1, 2);
            LineTo(hdc, y - 2, 3);
            LineTo(hdc, y + 2, 3);
            LineTo(hdc, y + 3, 4);
            LineTo(hdc, y - 3, 4);
            LineTo(hdc, y - 4, 5);
            LineTo(hdc, y + 5, 5);
            SelectObject(hdc, GetStockObject(BLACK_PEN));
            DeleteObject(hPen);

        }
    }

    return 0;


}

/* Draws all the scope windows */
int drawScope()
{
    int i;
    for(i = 0; i < 3; i++)
        drawScopeHelper(windowHandles[i], windowTypes[i], hdcBuffers[i], hbmBuffers[i], hdcTemp[i], hbmTemp[i]);
    if(dispmode & MODE_STOP)
        dispmode = (dispmode & ~MODE_RUN);
    return 0;
}

/* Clears and redraws all the scope windows
 * invld: if 1 then invalidates the channel data and isn't drawn.  If 0 then channel data is drawn.
 * returns: 0 */
int refreshScopeWindows(char invld)
{
    InvalidateRect(g_hScreenMain, NULL, TRUE);
    InvalidateRect(g_hScreenA, NULL, TRUE);
    InvalidateRect(g_hScreenB, NULL, TRUE);
    if(invld)
        chDraw = DRAWNONE;
    return 0;
}

/* Returns the time per division */
double getTimePerDivision()
{
    return timePerDivision;
    //return (getSamplesPerChannel() - 1) / getSampleRate() / ((double) DIVISIONSX);
}

/* Sets the time per division */
int setTimePerDivision(double tpd)
{
    timePerDivision = tpd;
    return 0;
}




/* Gets the enabled status of the channel
 * ch: 0 is channel A, 1 is channel B, 2 is channel C, 3 is channel D
 * returns: 1 is enabled, 0 is disabled */
int getChannelEnabled(int ch)
{
    if(ch == 3)
        return (MODE_CHDENABLED == (dispmode & MODE_CHDENABLED));
    else if(ch == 2)
        return (MODE_CHCENABLED == (dispmode & MODE_CHCENABLED));
    else if(ch == 1)
        return (MODE_CHBENABLED == (dispmode & MODE_CHBENABLED));
    else
        return (MODE_CHAENABLED == (dispmode & MODE_CHAENABLED));
}

/* Sets the channel to enabled or disabled
 * ch: 0 is channel A, 1 is channel B, 2 is channel C, 3 is channel D
 * en: 1 is enabled, 0 is disabled
 * returns: 0 */
int setChannelEnabled(int ch, int en)
{
    if(ch == 3)
        if(en)
            dispmode = dispmode | MODE_CHDENABLED;
        else
            dispmode = dispmode & (~MODE_CHDENABLED);
    else if(ch == 2)
        if(en)
            dispmode = dispmode | MODE_CHCENABLED;
        else
            dispmode = dispmode & (~MODE_CHCENABLED);
    else if(ch == 1)
        if(en)
            dispmode = dispmode | MODE_CHBENABLED;
        else
            dispmode = dispmode & (~MODE_CHBENABLED);
    else
        if(en)
            dispmode = dispmode | MODE_CHAENABLED;
        else
            dispmode = dispmode & (~MODE_CHAENABLED);
    refreshScopeWindows(0);
    return 0;
}

/* Set the persistence
 * p: a number between  0 and 255 representing the persistence.  Numbers below 0 will set persistence to 0.  Numbers above 255 will set persistence to 255.
 */
int oscSetPersistence(int p)
{
    if(p > 255)
        p = 255;
    else if (p < 0)
        p = 0;
    persistence = p;
}

/* Get the persistence setting
 * returns: a number between 0 and 255 representing the persistence.  0 is full persistence, 255 is no persistence
 */
int oscGetPersistence()
{
    return persistence;
}

/* Delete a scope cursor
 * ind: index to the cursor to delete */
int oscDelCursor(int ind)
{
    xCurPos[ind] = -20;
    yCurPos[ind] = -20;
    return 0;
}

/* Create a scope cursor
 * xscr: x position of the window to create the cursor on
 * yscr: y position of the window to create the cursor on */
int oscSetCursor(int xscr, int yscr)
{
    int i;
    i = 1;
    if((xCurPos[0] <= 0) || (oscOverCursor(xscr, yscr) == 0)) i = 0;
    xCurPos[i] = xscr;
    yCurPos[i] = yscr;
    return i;
}

/* Returns a number indicating where the mouse is relative to the cursors.
 * The number is the index of the cursor plus 2 if the x coordinate matches and
 * plus 4 if the y coordinate matches.
 * xscr: x position of the window to check
 * yscr: y position of the window to check */
int oscOverCursor(int xscr, int yscr)
{
    int i, aMax, a;
    aMax = 0;
    for(i = 0; i < 2; i++)
    {
        a = i;
        if((xscr > xCurPos[i] - TOL) && (xscr < xCurPos[i] + TOL))
            a = a+2;
        if((yscr > yCurPos[i] - TOL) && (yscr < yCurPos[i] + TOL))
            a = a+4;
        if(a > aMax)
            aMax = a;
    }
    return aMax;
}

/* Displays the value under the cursor on the status bar
 */
int oscDispShowValue(RECT rect, int windowType, double xscr, double yscr)
{
    double valx, cha, chb, chc, chd;
    char a[5][80];
    char *b;
    oscDispValue(rect, windowType, xscr, yscr, &valx, &cha, &chb, &chc, &chd);
    switch(windowType)
    {
    case SCOPE_SCREEN:
        /* Create first message */
        sprintf(a[0], "T=");
        NumToEngStr(valx, &a[0][2]);
        for(b = &a[0][2]; *b; b++);
        *b++ = 's';
        *b = '\0';
        /* Create second message */
        sprintf(a[1], "ChA=");
        NumToEngStr(cha, &a[1][4]);
        for(b = &a[1][4]; *b; b++);
        *b++ = 'V';
        *b = '\0';
        /* Create third message */
        sprintf(a[2], "ChB=");
        NumToEngStr(chb, &a[2][4]);
        for(b = &a[2][4]; *b; b++);
        *b++ = 'V';
        *b = '\0';
        /* Create forth message */
        sprintf(a[3], "ChC=");
        NumToEngStr(chc, &a[3][4]);
        for(b = &a[3][4]; *b; b++);
        *b++ = 'V';
        *b = '\0';
        /* Create fifth message */
        sprintf(a[4], "ChD=");
        NumToEngStr(chd, &a[4][4]);
        for(b = &a[4][4]; *b; b++);
        *b++ = 'V';
        *b = '\0';
        break;
    case SCOPE_FREQMAG:
    case SCOPE_FREQPHASE:
        /* Create first message */
        a[0][0] = '\0';
        a[1][0] = '\0';
        sprintf(a[2],"Freq=");
        NumToEngStr(valx, &a[2][5]);
        for(b = &a[2][5]; *b; b++);
        *b++ = 'H';
        *b++ = 'z';
        *b = '\0';
        /* Create second message */
        sprintf(a[3], "Magn=");
        NumToEngStr(cha, &a[3][5]);
        for(b = &a[3][5]; *b; b++);
        *b++ = 'V';
        *b = '\0';
        /* Create third message */
        sprintf(a[4], "Phase=");
        NumToEngStr(chb, &a[4][6]);
        break;
    case SCOPE_MEASUREMENTS:
        a[0][0] = '\0';
        a[1][0] = '\0';
        a[2][0] = '\0';
        a[3][0] = '\0';
        a[4][0] = '\0';
    }
    SendMessage(g_hStatusBar, SB_SETTEXT, 2, (LPARAM) a[0]);
    SendMessage(g_hStatusBar, SB_SETTEXT, 3, (LPARAM) a[1]);
    SendMessage(g_hStatusBar, SB_SETTEXT, 4, (LPARAM) a[2]);
    SendMessage(g_hStatusBar, SB_SETTEXT, 5, (LPARAM) a[3]);
    SendMessage(g_hStatusBar, SB_SETTEXT, 6, (LPARAM) a[4]);
    return 0;
}

int oscDispValue(RECT rect, int windowType, double xscr, double yscr,
    double *valx, double *cha, double *chb, double *chc, double *chd)
{
    double deltaX, deltaY;
    double minmagn, maxmagn, yDec;
    double temp;
    int ubc;

    if(xscr >= 0 && yscr >= 0)
    {
        switch (windowType)
        {
        case SCOPE_SCREEN:
            if(dispmode & MODE_XY)
            {
                /* Scope screen in x-y mode */
                deltaX = ((double) (rect.right - 2)) / DIVISIONSX;
                deltaY = ((double) (rect.bottom - 2)) / DIVISIONSY;
                *cha = (DIVISIONSY/2-(yscr-1)/deltaY)*chAVoltDiv-chAOffset;
                *chb = (-DIVISIONSX/2+xscr/deltaX)*chBVoltDiv-chBOffset;
                *chc = (DIVISIONSY/2-(yscr-1)/deltaY)*chCVoltDiv-chCOffset;
                *chd = (-DIVISIONSX/2+xscr/deltaX)*chDVoltDiv-chDOffset;
                *valx = 0;
            }
            else
            {
                /* Scope screen in time mode */
                ubc = getSamplesPerChannel();                   /* Set up dimensions */
                deltaX = ((double) (rect.right - 2)) / DIVISIONSX;
                deltaY = ((double) (rect.bottom - 2)) / DIVISIONSY;
                temp = ((double) DIVISIONSY)/2 - (yscr-1)/deltaY;
                *valx = xscr*getTimePerDivision()/deltaX+getTriggerDelay();
                *cha = temp*chAVoltDiv - chAOffset;
                *chb = temp*chBVoltDiv - chBOffset;
                *chc = temp*chCVoltDiv - chCOffset;
                *chd = temp*chDVoltDiv - chDOffset;
            }
            return 0;
        case SCOPE_FREQMAG:
            if(dispmode & MODE_FREQMAGLOG)
            {
                /* Spectrum screen in logrithmic mode */
                maxmagn = chAVoltDiv;
                if(chBVoltDiv > maxmagn)
                    maxmagn = chBVoltDiv;
                if(chCVoltDiv > maxmagn)
                    maxmagn = chCVoltDiv;
                if(chDVoltDiv > maxmagn)
                    maxmagn = chDVoltDiv;
                maxmagn*=10;

                minmagn = chAVoltDiv;
                if(chBVoltDiv < minmagn)
                    minmagn = chBVoltDiv;
                if(chCVoltDiv < minmagn)
                    minmagn = chBVoltDiv;
                if(chDVoltDiv < minmagn)
                    minmagn = chBVoltDiv;
                minmagn/=1000;

                if(minmagn < 0.0001) minmagn = 0.0001;
                yDec = (rect.bottom - 2)/(log10(maxmagn/minmagn));
                *cha = minmagn*pow(10.0, (rect.bottom - 1 - yscr)/yDec);
            }
            else
            {
                /* Spectrum screen in linear mode */
                maxmagn = chAVoltDiv;
                if(chBVoltDiv > maxmagn)
                    maxmagn = chBVoltDiv;
                if(chCVoltDiv > maxmagn)
                    maxmagn = chCVoltDiv;
                if(chDVoltDiv > maxmagn)
                    maxmagn = chDVoltDiv;
                maxmagn*=DIVISIONSY;
                minmagn = 0;
                yDec = (rect.bottom - 2)/maxmagn*2;
                *cha = (rect.bottom - yscr - 1)/yDec;
            }
            ubc = getMaxSamplesPerChannel();                   /* Set up dimensions */
//            deltaX = ((double) (rect.right - 2)) / ((double) ubc / 2-1);
//            *valx = ((double) (xscr - 1))/deltaX*getSampleRate()/2/(getMaxSamplesPerChannel()/2-1);        *chb = 0;
            deltaX = ((double) (rect.right - 2)) / ((double) ubc / 2);
            *valx = ((double) (xscr - 1))/deltaX*getSampleRate()/2/(getMaxSamplesPerChannel()/2);        *chb = 0;
            return 0;
        case SCOPE_FREQPHASE:
            /* Spectrum phase */
            ubc = getMaxSamplesPerChannel();                   /* Set up dimensions */
//            deltaX = ((double) (rect.right - 2)) / ((double) ubc / 2 - 1);
            deltaX = ((double) (rect.right - 2)) / ((double) ubc / 2);
            *chb = (1 - yscr/(rect.bottom - 1)*2)*M_PI;
//            *valx = ((double) (xscr - 1))/deltaX*getSampleRate()/2/(getMaxSamplesPerChannel()/2 -1);
            *valx = ((double) (xscr - 1))/deltaX*getSampleRate()/2/(getMaxSamplesPerChannel()/2);
            *cha = 0;
            return 0;
        case SCOPE_MEASUREMENTS:
            *valx = 0;
            *cha = 0;
            *chb = 0;
            *chc = 0;
            *chd = 0;
            return 0;
        }
    }
    else
    {
        *valx = 0;
        *cha = 0;
        *chb = 0;
        *chc = 0;
        *chd = 0;
        return 0;
    }
    return 1;
}

BOOL CALLBACK oscDispProc (HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    HDC hdc;
    PAINTSTRUCT ps;
    int i;
    char windowTypeTemp;
    RECT rect;
    static short int x, y, currentCur;
    static double xsize, ysize;
    static double xval[2], cha[2], chb[2], chc[2], chd[2];

    char a[80];

    switch (message)                  /* handle the messages */
    {
        case WM_CREATE:
            gridColor = SCRLINES;
            chAColor = CHACOLOR;
            chBColor = CHBCOLOR;
            bColor = SCRCOLOR;
            trigColor = TRGCOLOR;
            curColor[0] = CUR1COLOR;
            curColor[1] = CUR2COLOR;
			weight[0] = WEIGHTA;
			weight[1] = WEIGHTB;
			persistence = NOPERSISTENCE;
            windowHandles[windowCount] = hwnd;
            windowTypes[windowCount] = windowCount;
            hdcBuffers[windowCount] = CreateCompatibleDC(GetDC(hwnd));
            GetClientRect(hwnd, &rect);
            hbmBuffers[windowCount] = CreateCompatibleBitmap(GetDC(hwnd), rect.right, rect.bottom);
            hdcTemp[windowCount] = CreateCompatibleDC(hdcBuffers[windowCount]);
            hbmTemp[windowCount] = CreateCompatibleBitmap(hdcBuffers[windowCount], rect.right, rect.bottom);
            if(hwnd == windowHandles[cursorWindow])
            {
                xsize = rect.right;
                ysize = rect.bottom;
            }
            windowCount++;
            xCurPos[0] = -20;
            yCurPos[0] = -20;
            xCurPos[1] = -20;
            yCurPos[1] = -20;
            break;
        case WM_CLOSE:
            break;
        case WM_DESTROY:
            for(i = 0; (windowHandles[i] != hwnd) && (i < 3); i++);
            DeleteDC(hdcBuffers[i]);
            DeleteObject(hbmBuffers[i]);
            DeleteDC(hdcTemp[i]);
            DeleteObject(hbmTemp[i]);
            break;
        case WM_LBUTTONDBLCLK:
            if(hwnd != windowHandles[0])
            {
                for(i = 0; (windowHandles[i] != hwnd) && (i < 3); i++);
                windowTypeTemp = windowTypes[0];
                windowTypes[0] = windowTypes[i];
                windowTypes[i] = windowTypeTemp;
                oscDelCursor(0);
                oscDelCursor(1);
                cursorWindow = 0;
                currentCur = 0;
                refreshScopeWindows(0);
            }
            break;
        case CM_SETSCREENTYPE:
            for(i = 0; (windowHandles[i] != hwnd) && (i < 3); i++);
            windowTypes[i] = wParam;
            break;
        case CM_GETSCREENTYPE:
            for(i = 0; (windowHandles[i] != hwnd) && (i < 3); i++);
            return windowTypes[i];
            break;
        case WM_PAINT:
            hdc = BeginPaint(hwnd, &ps);
            GetClientRect(hwnd, &rect);
            HBRUSH hBrush;
            hBrush = CreateSolidBrush(bColor);
            hBrush = (HBRUSH) SelectObject(hdc, hBrush);
            Rectangle(hdc, rect.left, rect.top, rect.right, rect.bottom);
            for(i = 0; (windowHandles[i] != hwnd) && (i < 3); i++);
            switch(windowTypes[i])
            {
            case SCOPE_SCREEN:
                drawScopeGrid(hwnd, hdc);
                break;
            case SCOPE_FREQMAG:
                drawSpectMagGrid(hwnd, hdc);
                break;
            case SCOPE_FREQPHASE:
                drawSpectPhaseGrid(hwnd, hdc);
                break;
            case SCOPE_MEASUREMENTS:
                break;
            }

            HBITMAP hbmOldBuffer = SelectObject(hdcBuffers[i], hbmBuffers[i]);
            BitBlt(hdcBuffers[i], 0, 0, rect.right, rect.bottom, hdc, 0, 0, SRCCOPY);
            //if(dispmode & MODE_STOP)
                drawScopeHelper(windowHandles[i], windowTypes[i], hdcBuffers[i], hbmBuffers[i], hdcTemp[i], hbmTemp[i]);
            if(hwnd == windowHandles[cursorWindow])
            {
                oscDispValue(rect, windowTypes[cursorWindow], xCurPos[0],
                    yCurPos[0], &xval[0], &cha[0], &chb[0], &chc[0], &chd[0]);
                oscDispValue(rect, windowTypes[cursorWindow], xCurPos[1],
                    yCurPos[1], &xval[1], &cha[1], &chb[1], &chc[1], &chd[1]);
                setCursorInfo(windowTypes[cursorWindow], xval, cha, chb, chc, chd);
            }
            SelectObject(hdc, GetStockObject(BLACK_PEN));
            DeleteObject(hBrush);
            EndPaint(hwnd, &ps);

            return 0;
        case WM_COMMAND:
            switch (LOWORD(wParam))
            {
                default:
                    break;
            }
            break;
        case WM_SIZE:
            for(i = 0; (windowHandles[i] != hwnd) && (i < 3); i++);
            DeleteDC(hdcBuffers[i]);
            DeleteObject(hbmBuffers[i]);
            DeleteObject(hdcTemp[i]);
            hdc = GetDC(hwnd);
            hdcBuffers[i] = CreateCompatibleDC(hdc);
            GetClientRect(hwnd, &rect);
            hbmBuffers[i] = CreateCompatibleBitmap(hdc, rect.right, rect.bottom);
            hdcTemp[i] = CreateCompatibleDC(hdc);
            hbmTemp[i] = CreateCompatibleBitmap(hdc, rect.right, rect.bottom);
            if(hwnd == windowHandles[cursorWindow])
            {
                if(xsize == 0) xsize = 1;
                if(ysize == 0) ysize = 1;
                for(i = 0; i < 2; i++)
                {
                    if(xCurPos[i] >= 0)
                    {
                        xCurPos[i] = xCurPos[i] * rect.right / xsize;
                        yCurPos[i] = yCurPos[i] * rect.bottom / ysize;
                    }
                }
                xsize = rect.right;
                ysize = rect.bottom;
            }
            return 0;
        case WM_LBUTTONDOWN:
            for(i = 0; (windowHandles[i] != hwnd) && (i < 3); i++);
            if(windowTypes[i] == SCOPE_MEASUREMENTS) return 0;          // Don't allow cursors on the Measurements screen
            if(windowHandles[cursorWindow] != hwnd)
            {
                InvalidateRect(windowHandles[cursorWindow], NULL, TRUE);
                cursorWindow = i;
                xCurPos[0] = -20;
                yCurPos[0] = -20;
                xCurPos[1] = -20;
                yCurPos[1] = -20;
                currentCur = 0;
                GetClientRect(hwnd, &rect);
                xsize = rect.right;
                ysize = rect.bottom;
            }
            x = LOWORD(lParam);
            y = HIWORD(lParam);
            SetCapture(hwnd);
            i = oscOverCursor(x,y);
            if((i & 6) == 6)
                SetCursor(spbCursor);
            else if(i & 4)
                SetCursor(spcCursor);
            else if(i & 2)
                SetCursor(spdCursor);
            else
                SetCursor(spbCursor);
            if(i < 2)
                currentCur = oscSetCursor(x, y)+6;
            else
                currentCur = i;
            GetClientRect(hwnd, &rect);
            oscDispValue(rect, windowTypes[cursorWindow], xCurPos[0],
                yCurPos[0], &xval[0], &cha[0], &chb[0], &chc[0], &chd[0]);
            oscDispValue(rect, windowTypes[cursorWindow], xCurPos[1],
                yCurPos[1], &xval[1], &cha[1], &chb[1], &chc[1], &chd[1]);
            setCursorInfo(windowTypes[cursorWindow], xval, cha, chb, chc, chd);
            return 0;
        case WM_LBUTTONUP:
            if(hwnd == windowHandles[cursorWindow])
            {
                x = LOWORD(lParam);
                y = HIWORD(lParam);
                GetClientRect(hwnd, &rect);
                if((rect.right <= x) || (x <= 0) || (y >= rect.bottom) || (y <= 0))
                {
                    oscDelCursor(currentCur & 1);
                }
                ReleaseCapture();
                SetCursor(spCursor);
                i = persistence;
                persistence = 0;
                drawScopeHelper(windowHandles[cursorWindow], windowTypes[cursorWindow], hdcBuffers[cursorWindow], hbmBuffers[cursorWindow], hdcTemp[cursorWindow], hbmTemp[cursorWindow]);
                persistence = i;
                oscDispValue(rect, windowTypes[cursorWindow], xCurPos[0],
                    yCurPos[0], &xval[0], &cha[0], &chb[0], &chc[0], &chd[0]);
                oscDispValue(rect, windowTypes[cursorWindow], xCurPos[1],
                    yCurPos[1], &xval[1], &cha[1], &chb[1], &chc[1], &chd[1]);
                setCursorInfo(windowTypes[cursorWindow], xval, cha, chb, chc, chd);
            }
            return 0;
        case WM_MOUSEMOVE:
            GetClientRect(hwnd, &rect);
            if(hwnd == windowHandles[cursorWindow])
            {
                x = LOWORD(lParam);
                y = HIWORD(lParam);
                if (GetKeyState(VK_LBUTTON) < 0)
                {
                    i = currentCur & 1;
                    if(currentCur & 4)
                        yCurPos[i] = y;
                    if(currentCur & 2)
                        xCurPos[i] = x;
                    i = persistence;
                    persistence = 0;
                    drawScopeHelper(windowHandles[cursorWindow], windowTypes[cursorWindow], hdcBuffers[cursorWindow], hbmBuffers[cursorWindow], hdcTemp[cursorWindow], hbmTemp[cursorWindow]);
                    persistence = i;
                    oscDispValue(rect, windowTypes[cursorWindow], xCurPos[0],
                        yCurPos[0], &xval[0], &cha[0], &chb[0], &chc[0], &chd[0]);
                    oscDispValue(rect, windowTypes[cursorWindow], xCurPos[1],
                        yCurPos[1], &xval[1], &cha[1], &chb[1], &chc[1], &chd[1]);
                    setCursorInfo(windowTypes[cursorWindow], xval, cha, chb, chc, chd);
                }
                else
                {
                    i = oscOverCursor(x,y);
                    if((i & 6) == 6)
                        SetCursor(spbCursor);
                    else if(i & 4)
                        SetCursor(spcCursor);
                    else if(i & 2)
                        SetCursor(spdCursor);
                    else
                        SetCursor(spCursor);
                }
            }
            for(i = 0; (windowHandles[i] != hwnd) && (i < 3); i++);
            oscDispShowValue(rect, windowTypes[i], LOWORD(lParam), HIWORD(lParam));
            return 0;
        default:                      /* for messages that we don't deal with */
            return DefWindowProc (hwnd, message, wParam, lParam);
    }
    return 0;
}
