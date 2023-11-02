/* ==============================================================================
 * Author:  Jonathan Weaver, jonw0224@aim.com
 * E-mail Contact: jonw0224@aim.com
 * Description:  Implementation of the Fast Fourier Transform
 * Version: 1.0
 * Date: 10/18/2006
 * Filename:  fourier.c, fourier.h
 *
 * Versions History:
 *      10/18/2006 - Created and tested FFT
 *      4/23/2009 - Performance improvements, code optimization
 *
 * Copyright (C) 2006 Jonathan Weaver
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

#include <math.h>
#include "fourier.h"

int channelMap[MAX_SAMPLE];
double reW[MAX_SAMPLE], imW[MAX_SAMPLE];
double reB[MAX_SAMPLE], imB[MAX_SAMPLE];

/* Fast Fourier Transform, return result in polar.
 * Note:All frequency components are scaled so that
 * channel[i] = sum( magn[k]*cos(2*pi*i*k/n-phase[k] ) from k = 0 to k = n/2+1
 * channel[]: signal to to transform using the discrete fourier transform
 * magn[]: magnitude information returned
 * phase[]: phase information returned
 * n: number of samples in channel.  n must be an integer power of 2.
 * Returns: 0 */
int faFourier(double channel[], double magn[], double phase[], int n)
{
    static int oldlogN;
    int u_freq;
    int i_step, inc_step, i, j, start, k, ks, invinc_step;
    int logn;
    double reTemp, imTemp;

    /* Calculate the upperbound frequency */
    u_freq = n >> 1;

    /* redimension fourier transform  in necessary */
    logn = logB2(n);
    if(oldlogN != logn)
    {
        fourierDim(n);
        fourierMap(n);
        oldlogN = logn;
    }

    /* Calculate the fourier transformer in rectangular format */
    i_step = 1;
    invinc_step = u_freq;
    for(i = 0; i < n; i++)
    {
        reB[i] = channel[channelMap[i]];
        imB[i] = 0;
    }

    for(i = 0; i < logn; i++)
    {
        inc_step = i_step << 1;
        start = 0;
        for(j = 0; j < i_step; j++)
        {
            for(k = j; k < n; k+=inc_step)
            {
                ks = k + i_step;
                reTemp = reW[start] * reB[ks] - imW[start] * imB[ks];
                imTemp = reW[start] * imB[ks] + imW[start] * reB[ks];
                reB[ks] = reB[k] - reTemp;
                imB[ks] = imB[k] - imTemp;
                reB[k] = reB[k] + reTemp;
                imB[k] = imB[k] + imTemp;
            }
            start+= invinc_step;
        }
        i_step = inc_step;
        invinc_step >>= 1;
    }
    /* convert to polar and scale */
    for(i = 0; i < n; i++)
    {
        magn[i] = sqrt(reB[i]*reB[i]+imB[i]*imB[i])/n;
        if(reB[i] == 0)
            if(imB[i] > 0)
                phase[i] = M_PI_2;
            else
                phase[i] = -M_PI_2;
        else
            phase[i] = atan(imB[i] / reB[i]);
        if(reB[i] < 0)
            if(phase[i] > 0)
                phase[i] = phase[i] - M_PI;
            else
                phase[i] = phase[i] + M_PI;
        if((i != 0) && (i != u_freq))
            magn[i]*=2;
    }
    return 0;
}

int logB2(int n)
{
    int i = 0;
    while(n > 0)
    {
        n >>= 1;
        i++;
    }
    return --i;
}

int fourierDim(int n)
{
    double angleStep, angleCal;
    int i;
    angleStep = 2*M_PI/n;
    angleCal = 0;
    for(i = 0; i < n; i++)
    {
        reW[i] = cos(angleCal);
        imW[i] = sin(angleCal);
        angleCal+=angleStep;
    }
    return 0;
}

int fourierMap(int n)
{
    int i, b, d;
    for(i = 0; i < n; i++)
    {
        channelMap[i] = 0;
        b = n >> 1;
        d = 0;
        while(b > 0)
        {
            if(i & b)
                channelMap[i] = (channelMap[i] | (1 << d));
            b >>= 1;
            d++;
        }
    }
    return 0;
}
