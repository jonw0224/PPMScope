/* ==============================================================================
 * Author:  Jonathan Weaver, jonw0224@aim.com
 * E-mail Contact: jonw0224@aim.com
 * Description:  Header file for oscilloscope graphs.
 * Version: 2.151
 * Date: 7/20/2012
 * Filename:  oscDisp.c, oscDisp.h
 *
 * Versions History:
 *      2.01 - 9/20/2006 - Created file
 *      2.02 - 2/19/2010 - Modified code to draw traces no matter what mode in
 *                         response to WM_PAINT message.  Before modification
 *                         traces were only drawn at a trigger event.
 *      2.14 - 1/31/2011 - Modified code to generalize colors.
 *      2.14 - 3/17/2011 - Added channel weight support
 *      2.151  7/20/2012 - Modified for continous Time Per Division
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
#include "oscDisp.h"
#include <math.h>
#include "debug.h"

#define DIMCOLOR(rgbcolor, bgcolor) ((0xFF0000 & (((0xFF0000 & rgbcolor) + (0xFF0000 & bgcolor)) >> 1)) + (0xFF00 & (((0xFF00 & rgbcolor) + (0xFF00 & bgcolor)) >> 1)) + (0xFF & (((0xFF & rgbcolor) + (0xFF & bgcolor)) >> 1)))

/* Colors */
int gridColor, chAColor, chBColor, curColor[2], bColor, trigColor;

/* Channel Draw Weight */
int weight[1];

/* Keep up with three windows and their functions */
HWND windowHandles[2];
char windowTypes[2];
char windowCount = 0;

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
double xCurPos[1], yCurPos[1];

/* Time per division */
double timePerDivision;

#define TOL             10

/* For double buffering of screens */
HDC hdcBuffers[2];
HBITMAP hbmBuffers[2];

/* Gets the weight for drawing the channels
 * channel: 0 for channel A and 1 for channel B
 * returns: weight in pixels */
int getPenWeight(int channel)
{
    return weight[channel];
}

/* Sets the weight for drawing the channels
 * channel: 0 for channel A and 1 for channel B
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
    case 1:
        return bColor;
    case 2:
        return gridColor;
    case 3:
        return chAColor;
    case 4:
        return chBColor;
    case 5:
        return curColor[0];
    case 6:
        return curColor[1];
    case 7:
        return trigColor;
    }
    return -1;
}

/* Sets the oscilloscope display colors
 * scrbgcolor: Screen Background Color
 * scrfgcolor: Grid Color
 * channelAColor: Channel A Color
 * channelBColor: Channel B Color
 * cur1color: Cursor 1 color
 * cur2color: Cursor 2 color
 * triggerColor: Trigger color
 * returns: 1*/
int oscSetColors(int scrbgcolor, int scrfgcolor, int channelAColor, int channelBColor, int cur1color, int cur2color, int triggerColor)
{
    bColor = scrbgcolor;
    gridColor = scrfgcolor;
    chAColor = channelAColor;
    chBColor = channelBColor;
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
            minmagn = chBVoltDiv/100;
            maxmagn = chAVoltDiv*10;
        }
        else
        {
            minmagn = chAVoltDiv/100;
            maxmagn = chBVoltDiv*10;
        }
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

/* Simplified find the cosine of an angle.  Less than 0.1% error.
 */
double myCos(double angle)
{
    int i;
    double twopi, m, est, anglePwr, anglePwrInc;
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
    HPEN hPen;
    double deltaX, deltaY;
    double y, x, s, b, q;
    int ubc, i, c, a;
    double minmagn, maxmagn, yDec;
    double chPhase[BUFFER_MAX], chFreq[BUFFER_MAX];

    ubc = getMaxSamplesPerChannel();                   /* Set up dimensions */
//    deltaX = ((double) (rect.right - 2)) / ((double) ubc / 2 - 1);
    deltaX = ((double) (rect.right - 2)) / ((double) ubc / 2);

    if(dispmode & MODE_FREQMAGLOG)
    {
        /* logrithmic magnitude */
        if(chAVoltDiv > chBVoltDiv)
        {
            minmagn = chBVoltDiv/100;
            maxmagn = chAVoltDiv*10;
        }
        else
        {
            minmagn = chAVoltDiv/100;
            maxmagn = chBVoltDiv*10;
        }
        yDec = (rect.bottom - 2)/(log10(maxmagn/minmagn));
    }
    else
    {
        /* Scalar magnitude */
        if(chAVoltDiv > chBVoltDiv)
            maxmagn = DIVISIONSY*chAVoltDiv;
        else
            maxmagn = DIVISIONSY*chBVoltDiv;
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
    case RECONST_SINC:
        faFourier(channel, chFreq, chPhase, ubc);
        a = rect.right - 1;
        c = ubc / 2;
        b = 2*M_PI/deltaX/c;
        s = 0;
        for(x=1; x < a; x+=2)
        {
            y = 0;
            s+= b;
            q = 0;
            for(i = 0; i < c; i++)
            {
                y += chFreq[i]*cos(q-chPhase[i]);
                q += s;
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
    HPEN hPen;
    double deltaX, deltaY;
    double y, x, s, b, q;
    int ubc, i, a, c;
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
    case RECONST_TRIANGLE:
        for(i=1; i < ubc; i++)
        {
            y = deltaY*SPECTPHDIVY/2-deltaY*(channel[i])/M_PI*2;
            x += deltaX;
            LineTo(hdc, x, y);
        }
        break;
    case RECONST_SINC:
        faFourier(channel, chFreq, chPhase, ubc);
        a = rect.right - 1;
        s = 0;
        c = ubc / 2;
        b = 2*M_PI/deltaX/c;
        for(x=1; x < a; x+=2)
        {
            y = 0;
            s+=b;
            q = 0;
            for(i = 0; i < c; i++)
            {
                y += chFreq[i]*cos(q-chPhase[i]);
                q += s;
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
 * cChannel: currentChannel
 * cColor: color of the pin to use
 * pWidth: width of the pin in pixels */
int drawChannel(RECT rect, HDC hdc, double channel[], double chFreq[],
    double chPhase[], double chOffset, double chVoltDiv, char cChannel, int cColor, int pWidth)
{
    HPEN hPen;
    double deltaX, deltaY;
    double y, x, s, b, q;
    int ubc, i, a, c;

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
            LineTo(hdc, x+1, y);
            y = 1+deltaY*DIVISIONSY/2-deltaY*(channel[i] + chOffset)/chVoltDiv;
            x += deltaX;
            MoveToEx(hdc, x, y, NULL);
        }
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
        c = sampleMaxCount[cChannel] / 2;
        b = 2*M_PI/deltaX/c;
        s = 0;
        for(x=1; x < a; x+=2)
        {
            y = 0;
            s+= b;
            q = 0;
            for(i = 0; i < c; i++)
            {
                y += chFreq[i]*cos(q-chPhase[i]);
                q += s;
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
int drawXYChannel(RECT rect, HDC hdc, double chA[], double chB[],
    double chAFreq[], double chBFreq[], double chAPhase[], double chBPhase[],
    char cChannel, int cColor, int pWidth)
{
    HPEN hPen;
    double deltaX, deltaY;
    double y, x, t, s, b, q;
    int ubc, i, a ,c;

    ubc = sampleCount[cChannel];                   /* Set up dimensions */
    deltaX = ((double) (rect.right - 2)) / DIVISIONSX;
    deltaY = ((double) (rect.bottom - 2)) / DIVISIONSY;
    hPen = CreatePen(PS_SOLID, pWidth, cColor);        /* Pick line color */
    SelectObject(hdc, hPen);
    y = 1+deltaY*DIVISIONSY/2-deltaY*(chA[0] + chAOffset)/chAVoltDiv;
    x = deltaX*DIVISIONSX/2+deltaX*(chB[0] + chBOffset)/chBVoltDiv;
    MoveToEx(hdc, x, y, NULL);

    switch(reconst)
    {
    case RECONST_SQUARE:
        for(i=1; i < ubc; i++)
        {
            x = deltaX*DIVISIONSX/2+deltaX*(chB[i] + chBOffset)/chBVoltDiv;
            LineTo(hdc, x, y);
            y = 1+deltaY*DIVISIONSY/2-deltaY*(chA[i] + chAOffset)/chAVoltDiv;
            LineTo(hdc, x, y);
        }
        break;
    case RECONST_POINT:
        for(i=1; i < ubc; i++)
        {
            LineTo(hdc, x+1, y);
            y = 1+deltaY*DIVISIONSY/2-deltaY*(chA[i] + chAOffset)/chAVoltDiv;
            x = 1+deltaX*DIVISIONSX/2+deltaX*(chB[i] + chBOffset)/chBVoltDiv;
            MoveToEx(hdc, x, y, NULL);
        }
        break;
    case RECONST_TRIANGLE:
        for(i=1; i < ubc; i++)
        {
            y = 1+deltaY*DIVISIONSY/2-deltaY*(chA[i] + chAOffset)/chAVoltDiv;
            x = 1+deltaX*DIVISIONSX/2+deltaX*(chB[i] + chBOffset)/chBVoltDiv;
            LineTo(hdc, x, y);
        }
        break;
    case RECONST_SINC:
        a = rect.right - 1;
        c = sampleMaxCount[cChannel] / 2;
        b = M_PI/(a - 1)*(ubc - 1)/c;
		s = 0;
        for(t=1; t < a; t++)
        {
            x = 0;
            y = 0;
            s+= b;
            q = 0;
            for(i = 0; i < c; i++)
            {
                x += chBFreq[i]*cos(q-chBPhase[i]);
                y += chAFreq[i]*cos(q-chAPhase[i]);
                q += s;
            }
            x = 1+deltaX*(DIVISIONSX/2 + (x + chBOffset)/chBVoltDiv);
            y = 1+deltaY*(DIVISIONSY/2 - (y + chAOffset)/chAVoltDiv);
            LineTo(hdc, x, y);
        }
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

int drawScopeHelper(HWND hwnd, char wType, HDC hdcBuffer, HBITMAP hbmBuffer)
{
    HDC hdc;
    RECT rect;
    HBRUSH bBrush;

    hdc = GetDC(hwnd);
    GetClientRect(hwnd, &rect);

    HBITMAP hbmOldBuffer = SelectObject(hdcBuffer, hbmBuffer);
    // BitBlt(hdcBuffer, 0, 0, rect.right, rect.bottom, hdc, 0, 0, SRCCOPY);

    switch(wType)
    {
    case SCOPE_SCREEN:

        /* Erase channels */
        if(dispmode & MODE_XY)
        {
                if((dispmode & MODE_HOLD) && (chDraw & DRAWOLDSCR))
                    drawXYChannel(rect, hdcBuffer, channelA[!currentChannel],
                        channelB[!currentChannel], chAfreqMag[!currentChannel],
                        chBfreqMag[!currentChannel], chAfreqPhase[!currentChannel],
                        chBfreqPhase[!currentChannel], !currentChannel, DIMCOLOR(chAColor, bColor), weight[0]);
                else
                    drawXYChannel(rect, hdcBuffer, channelA[!currentChannel],
                        channelB[!currentChannel], chAfreqMag[!currentChannel],
                        chBfreqMag[!currentChannel], chAfreqPhase[!currentChannel],
                        chBfreqPhase[!currentChannel], !currentChannel, bColor, weight[0]);
        }
        else
        {
            if(dispmode & MODE_CHAENABLED)
                if((dispmode & MODE_HOLD) && (chDraw & DRAWOLDSCR))
                    drawChannel(rect, hdcBuffer, channelA[!currentChannel],
                        chAfreqMag[!currentChannel], chAfreqPhase[!currentChannel],
                        chAOffset, chAVoltDiv, !currentChannel, DIMCOLOR(chAColor, bColor),weight[0]);
                else
                    drawChannel(rect, hdcBuffer, channelA[!currentChannel],
                        chAfreqMag[!currentChannel], chAfreqPhase[!currentChannel],
                        chAOffset, chAVoltDiv, !currentChannel, bColor, weight[0]);

            if(dispmode & MODE_CHBENABLED)
                if((dispmode & MODE_HOLD) && (chDraw & DRAWOLDSCR))
                    drawChannel(rect, hdcBuffer, channelB[!currentChannel],
                        chBfreqMag[!currentChannel], chBfreqPhase[!currentChannel],
                        chBOffset, chBVoltDiv, !currentChannel, DIMCOLOR(chBColor, bColor),weight[1]);
                else
                    drawChannel(rect, hdcBuffer, channelB[!currentChannel],
                        chBfreqMag[!currentChannel], chBfreqPhase[!currentChannel],
                        chBOffset, chBVoltDiv, !currentChannel, bColor, weight[1]);
        }

        /* Draw grid */
        drawScopeGrid(hwnd, hdcBuffer);

        /* Draw channels */
        if((dispmode & MODE_XY) && (chDraw & DRAWSCR))
        {
            drawXYChannel(rect, hdcBuffer, channelA[currentChannel],
                channelB[currentChannel], chAfreqMag[currentChannel],
                chBfreqMag[currentChannel], chAfreqPhase[currentChannel],
                chBfreqPhase[currentChannel], currentChannel, chAColor,weight[0]);
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
        }

        if(chDraw & DRAWSCR) chDraw = chDraw | DRAWOLDSCR;
        chDraw = chDraw | DRAWSCR;

        break;
    case SCOPE_FREQMAG:
        /* Erase channels */
        if(dispmode & MODE_CHAENABLED)
            if((dispmode & MODE_HOLD) && (chDraw & DRAWOLDFREQMAG))
                drawSpectMagn(rect, hdcBuffer, chAfreqMag[!currentChannel], DIMCOLOR(chAColor, bColor),weight[0]);
            else
                drawSpectMagn(rect, hdcBuffer, chAfreqMag[!currentChannel], bColor,weight[0]);

        if(dispmode & MODE_CHBENABLED)
            if((dispmode & MODE_HOLD) && (chDraw & DRAWOLDFREQMAG))
                drawSpectMagn(rect, hdcBuffer, chBfreqMag[!currentChannel], DIMCOLOR(chBColor, bColor),weight[1]);
            else
                drawSpectMagn(rect, hdcBuffer, chBfreqMag[!currentChannel], bColor,weight[1]);

        /* Draw grid */
        drawSpectMagGrid(hwnd, hdcBuffer);

        /* Draw channels */
        if((dispmode & MODE_CHAENABLED) && (chDraw & DRAWFREQMAG))
            drawSpectMagn(rect, hdcBuffer, chAfreqMag[currentChannel], chAColor,weight[0]);
        if((dispmode & MODE_CHBENABLED) && (chDraw & DRAWFREQMAG))
            drawSpectMagn(rect, hdcBuffer, chBfreqMag[currentChannel], chBColor,weight[1]);

        if(chDraw & DRAWFREQMAG) chDraw |= DRAWOLDFREQMAG;
        chDraw = chDraw | DRAWFREQMAG;

        break;

    case SCOPE_FREQPHASE:
        /* Erase channels */
        if(dispmode & MODE_CHAENABLED)
            if((dispmode & MODE_HOLD) && (chDraw & DRAWOLDFREQPHASE))
                drawSpectPhase(rect, hdcBuffer, chAfreqPhase[!currentChannel], DIMCOLOR(chAColor, bColor),weight[0]);
            else
                drawSpectPhase(rect, hdcBuffer, chAfreqPhase[!currentChannel], bColor,weight[0]);

        if(dispmode & MODE_CHBENABLED)
            if((dispmode & MODE_HOLD) && (chDraw & DRAWOLDFREQPHASE))
                drawSpectPhase(rect, hdcBuffer, chBfreqPhase[!currentChannel], DIMCOLOR(chBColor, bColor),weight[1]);
            else
                drawSpectPhase(rect, hdcBuffer, chBfreqPhase[!currentChannel], bColor,weight[1]);

        if(chDraw & DRAWFREQPHASE) chDraw |= DRAWOLDFREQPHASE;

        /* Draw grid */
        drawSpectPhaseGrid(hwnd, hdcBuffer);

        /* Draw channels */
        if((dispmode & MODE_CHAENABLED) && (chDraw & DRAWFREQPHASE))
            drawSpectPhase(rect, hdcBuffer, chAfreqPhase[currentChannel], chAColor,weight[0]);
        if((dispmode & MODE_CHBENABLED) && (chDraw & DRAWFREQPHASE))
            drawSpectPhase(rect, hdcBuffer, chBfreqPhase[currentChannel], chBColor,weight[1]);

        if(chDraw & DRAWFREQPHASE) chDraw |= DRAWOLDFREQPHASE;
        chDraw = chDraw | DRAWFREQPHASE;

        break;
    }

    BitBlt(hdc, 0, 0, rect.right, rect.bottom, hdcBuffer, 0, 0, SRCCOPY);
    SelectObject(hdcBuffer, hbmOldBuffer);

    /* Draw the Cursors */
    if(hwnd == windowHandles[0]) drawCursors(rect, hdc);

    /* Draw the trigger Icon */
    if(wType == SCOPE_SCREEN)
        drawTrigger(rect, hdc);
    ReleaseDC(hwnd, hdc);
    return 0;
}

int drawTrigger(RECT rect, HDC hdc)
{
    double trig;
    trig = getTriggerLevel();

    HPEN hPen;
    double deltaY;
    double y;

    deltaY = ((double) (rect.bottom - 2)) / DIVISIONSY;
    hPen = CreatePen(PS_SOLID, 0, trigColor);        /* Pick line color */
    SelectObject(hdc, hPen);
    y = 1+deltaY*DIVISIONSY/2-deltaY*(trig + chAOffset)/chAVoltDiv;

    /* Draw Trigger Icon */
    MoveToEx(hdc, 1, y, NULL);
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
    LineTo(hdc, 10, y-1);

    SelectObject(hdc, GetStockObject(BLACK_PEN));
    DeleteObject(hPen);
    return 0;


}

/* Draws all the scope windows */
int drawScope()
{
    int i;
    for(i = 0; i < 3; i++)
        drawScopeHelper(windowHandles[i], windowTypes[i], hdcBuffers[i], hbmBuffers[i]);
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
 * ch: 0 is channel A, 1 is channel B
 * returns: 1 is enabled, 0 is disabled */
int getChannelEnabled(int ch)
{
    if(ch)
        return (MODE_CHBENABLED == (dispmode & MODE_CHBENABLED));
    else
        return (MODE_CHAENABLED == (dispmode & MODE_CHAENABLED));
}

/* Sets the channel to enabled or disabled
 * ch: 0 is channel A, 1 is channel B
 * en: 1 is enabled, 0 is disabled
 * returns: 0 */
int setChannelEnabled(int ch, int en)
{
    if(ch)
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
            a += 2;
        if((yscr > yCurPos[i] - TOL) && (yscr < yCurPos[i] + TOL))
            a += 4;
        if(a > aMax)
            aMax = a;
    }
    return aMax;
}

/* Displays the value under the cursor on the status bar
 */
int oscDispShowValue(RECT rect, int windowType, double xscr, double yscr)
{
    double valx, cha, chb;
    char a[3][80];
    char *b;
    oscDispValue(rect, windowType, xscr, yscr, &valx, &cha, &chb);
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
        break;
    case SCOPE_FREQMAG:
    case SCOPE_FREQPHASE:
        /* Create first message */
        sprintf(a[0],"Freq=");
        NumToEngStr(valx, &a[0][5]);
        for(b = &a[0][5]; *b; b++);
        *b++ = 'H';
        *b++ = 'z';
        *b = '\0';
        /* Create second message */
        sprintf(a[1], "Magn=");
        NumToEngStr(cha, &a[1][5]);
        for(b = &a[1][5]; *b; b++);
        *b++ = 'V';
        *b = '\0';
        /* Create third message */
        sprintf(a[2], "Phase=");
        NumToEngStr(chb, &a[2][6]);
        break;
    }
    SendMessage(g_hStatusBar, SB_SETTEXT, 2, (LPARAM) a[0]);
    SendMessage(g_hStatusBar, SB_SETTEXT, 3, (LPARAM) a[1]);
    SendMessage(g_hStatusBar, SB_SETTEXT, 4, (LPARAM) a[2]);
    return 0;
}

int oscDispValue(RECT rect, int windowType, double xscr, double yscr,
    double *valx, double *cha, double *chb)
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
                *valx = 0;
            }
            else
            {
                /* Scope screen in time mode */
                ubc = getSamplesPerChannel();                   /* Set up dimensions */
                deltaX = ((double) (rect.right - 2)) / DIVISIONSX;
                deltaY = ((double) (rect.bottom - 2)) / DIVISIONSY;
                temp = ((double) DIVISIONSY)/2 - (yscr-1)/deltaY;
                *valx = xscr*getTimePerDivision()/deltaX;
                *cha = temp*chAVoltDiv - chAOffset;
                *chb = temp*chBVoltDiv - chBOffset;
            }
            return 0;
        case SCOPE_FREQMAG:
            if(dispmode & MODE_FREQMAGLOG)
            {
                /* Spectrum screen in logrithmic mode */
                if(chAVoltDiv > chBVoltDiv)
                {
                    minmagn = chBVoltDiv/100;
                    maxmagn = chAVoltDiv*10;
                }
                else
                {
                    minmagn = chAVoltDiv/100;
                    maxmagn = chBVoltDiv*10;
                }
                yDec = (rect.bottom - 2)/(log10(maxmagn/minmagn));
                *cha = minmagn*pow(10.0, (rect.bottom - 1 - yscr)/yDec);
            }
            else
            {
                /* Spectrum screen in linear mode */
                if(chAVoltDiv > chBVoltDiv)
                    maxmagn = DIVISIONSY*chAVoltDiv;
                else
                    maxmagn = DIVISIONSY*chBVoltDiv;
                minmagn = 0;
                yDec = (rect.bottom - 2)/maxmagn*2;
                *cha = (rect.bottom - yscr - 1)/yDec;
            }
            ubc = getSamplesPerChannel();                   /* Set up dimensions */
//            deltaX = ((double) (rect.right - 2)) / ((double) ubc / 2-1);
//            *valx = ((double) (xscr - 1))/deltaX*getSampleRate()/2/(getMaxSamplesPerChannel()/2-1);        *chb = 0;
            deltaX = ((double) (rect.right - 2)) / ((double) ubc / 2);
            *valx = ((double) (xscr - 1))/deltaX*getSampleRate()/2/(getMaxSamplesPerChannel()/2);        *chb = 0;
            return 0;
        case SCOPE_FREQPHASE:
            /* Spectrum phase */
            ubc = getSamplesPerChannel();                   /* Set up dimensions */
//            deltaX = ((double) (rect.right - 2)) / ((double) ubc / 2 - 1);
            deltaX = ((double) (rect.right - 2)) / ((double) ubc / 2);
            *chb = (1 - yscr/(rect.bottom - 1)*2)*M_PI;
//            *valx = ((double) (xscr - 1))/deltaX*getSampleRate()/2/(getMaxSamplesPerChannel()/2 -1);
            *valx = ((double) (xscr - 1))/deltaX*getSampleRate()/2/(getMaxSamplesPerChannel()/2);
            *cha = 0;
            return 0;
        }
    }
    else
    {
        *valx = 0;
        *cha = 0;
        *chb = 0;
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
    static double xval[2], cha[2], chb[2];

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
            windowHandles[windowCount] = hwnd;
            windowTypes[windowCount] = windowCount;
            hdcBuffers[windowCount] = CreateCompatibleDC(GetDC(hwnd));
            GetClientRect(hwnd, &rect);
            hbmBuffers[windowCount] = CreateCompatibleBitmap(hdc, rect.right, rect.bottom);
            if(hwnd == windowHandles[0])
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
            break;
        case WM_LBUTTONDBLCLK:
            if(hwnd != windowHandles[0])
            {
                for(i = 0; (windowHandles[i] != hwnd) && (i < 3); i++);
                windowTypeTemp = windowTypes[0];
                windowTypes[0] = windowTypes[i];
                windowTypes[i] = windowTypeTemp;
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
            Rectangle(hdc, rect.left-1, rect.top-1, rect.right+1, rect.bottom+1);
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
            }
            HBITMAP hbmOldBuffer = SelectObject(hdcBuffers[i], hbmBuffers[i]);
            BitBlt(hdcBuffers[i], 0, 0, rect.right, rect.bottom, hdc, 0, 0, SRCCOPY);
            //if(dispmode & MODE_STOP)
                drawScopeHelper(windowHandles[i], windowTypes[i], hdcBuffers[i], hbmBuffers[i]);
            if(hwnd == windowHandles[0])
            {
                oscDispValue(rect, windowTypes[0], xCurPos[0],
                    yCurPos[0], &xval[0], &cha[0], &chb[0]);
                oscDispValue(rect, windowTypes[0], xCurPos[1],
                    yCurPos[1], &xval[1], &cha[1], &chb[1]);
                setCursorInfo(windowTypes[0], xval, cha, chb);
            }
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
            hdc = GetDC(hwnd);
            hdcBuffers[i] = CreateCompatibleDC(hdc);
            GetClientRect(hwnd, &rect);
            hbmBuffers[i] = CreateCompatibleBitmap(hdc, rect.right, rect.bottom);
            if(hwnd == windowHandles[0])
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
            if(hwnd == windowHandles[0])
            {
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
                    currentCur = oscSetCursor(x, y);
                else
                    currentCur = i;
                GetClientRect(hwnd, &rect);
                oscDispValue(rect, windowTypes[0], xCurPos[0],
                    yCurPos[0], &xval[0], &cha[0], &chb[0]);
                oscDispValue(rect, windowTypes[0], xCurPos[1],
                    yCurPos[1], &xval[1], &cha[1], &chb[1]);
                setCursorInfo(windowTypes[0], xval, cha, chb);
            }
            return 0;
        case WM_LBUTTONUP:
            if(hwnd == windowHandles[0])
            {
                GetClientRect(hwnd, &rect);
                if((rect.right <= x) || (x <= 0) || (y >= rect.bottom) || (y <= 0))
                {
                    oscDelCursor(currentCur & 1);
                }
                ReleaseCapture();
                SetCursor(spCursor);
                drawScopeHelper(windowHandles[0], windowTypes[0], hdcBuffers[0], hbmBuffers[0]);
                oscDispValue(rect, windowTypes[0], xCurPos[0],
                    yCurPos[0], &xval[0], &cha[0], &chb[0]);
                oscDispValue(rect, windowTypes[0], xCurPos[1],
                    yCurPos[1], &xval[1], &cha[1], &chb[1]);
                setCursorInfo(windowTypes[0], xval, cha, chb);
            }
            return 0;
        case WM_MOUSEMOVE:
            GetClientRect(hwnd, &rect);
            if(hwnd == windowHandles[0])
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
                    drawScopeHelper(windowHandles[0], windowTypes[0], hdcBuffers[0], hbmBuffers[0]);
                    oscDispValue(rect, windowTypes[0], xCurPos[0],
                        yCurPos[0], &xval[0], &cha[0], &chb[0]);
                    oscDispValue(rect, windowTypes[0], xCurPos[1],
                        yCurPos[1], &xval[1], &cha[1], &chb[1]);
                    setCursorInfo(windowTypes[0], xval, cha, chb);
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
