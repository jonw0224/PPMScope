/* ==============================================================================
 * Author:  Jonathan Weaver, jonw0224@aim.com
 * E-mail Contact: jonw0224@aim.com
 * Description:  Collection of functions to perform signal measurements
 * Version: 1.0
 * Date: 4/28/2009
 * Filename:  func.c, func.h
 *
 * Versions History:
 *      4/28/2009 - Created file
 *
 * Copyright (C) 2009 Jonathan Weaver
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

#include "func.h"

/* Returns the maximum value of the signal
 * arr[]: array in which to find the maximum value
 * len: length of the array
 */
double sigMax(double arr[], int len)
{
    int i;
    double max;
    max = arr[0];
    for(i = 1; i < len; i++)
        if(max < arr[i])
            max = arr[i];
    return max;
}

/* Returns the minimum value of the signal
 * arr[]: array in which to find the minimum value
 * len: length of the array
 */
double sigMin(double arr[], int len)
{
    int i;
    double min;
    min = arr[0];
    for(i = 1; i < len; i++)
        if(min > arr[i])
            min = arr[i];
    return min;
}

/* Returns the peak to peak, difference between the maximum to the minimum value, of the signal
 * arr[]: array in which to find the peak to peak value
 * len: length of the array
 */
double sigPeakToPeak(double arr[], int len)
{
    return sigMax(arr, len) - sigMin(arr, len);
}

/* Returns the sum of all values in the signal
 * arr[]: array in which to sum all of the values
 * len: length of the array
 */
double sigSum(double arr[], int len)
{
    int i;
    double sum = 0;
    for(i = 0; i < len; i++)
        sum+=arr[i];
    return sum;
}

/* Returns the average value of the signal
 * arr[]: array in which to find the average value
 * len: length of the array
 */
double sigAvg(double arr[], int len)
{
    return sigSum(arr, len) / len;
}

/* Returns the sum of the squares of the values in the signal
 * arr[]: array in which to find the sum of the squares
 * len: length of the array
 */
double sigSumSq(double arr[], int len)
{
    int i;
    double sumsq;
    sumsq = 0;
    for(i = 0; i < len; i++)
          sumsq+=arr[i]*arr[i];
    return sumsq;
}

/* Returns the RMS value of the signal
 * arr[]: array in which to find the RMS value
 * len: length of the array
 */
double sigRMS(double arr[], int len)
{
    return (sqrt(sigSumSq(arr, len) / len));
}

/* Returns the RMS value without the DC component of the signal
 * arr[]: array in which to find the RMS value
 * len: length of the array
 */
double sigRMS_AConly(double arr[], int len)
{
    int i;
    double avg, sumsq, val;
    avg = sigAvg(arr, len);
    sumsq = 0;
    for(i = 0; i < len; i++)
    {
        val = arr[i] - avg;
        sumsq+=(val*val);
    }
    return (sqrt(sumsq / len));
}

/* A Helper function.
 * Find the fundamental frequency bin, assumes no peak merging
 */
int fundFreqBin(double magn[], int len)
{
    double avg, a;
    int i;

    avg = sigMax(&magn[1], len-1)/2;

    i = 0;
    a = magn[i];
    while(magn[++i] < a)
        a = magn[i];
    a = magn[i];
    while(magn[++i] > a || a < avg)
        a = magn[i];
    i--;

    if(i >= len - 1)
         return 0;
    return i;
}

/* Returns the fundamental frequency of the signal
 * arr[]: array in which to find the fundamental frequency
 * len: length of the array
 */
double sigFreq(double arr[], int len)
{
    /* Frequency measurement algorithm explained by M. Gasior, J.L. Gonzalez
     * in "Improving FFT Frequency Measurement Resolution by Parabolic and
     * Gaussian Spectrum Interpolation", CERN, CH-1211,Geneva 23, Switzerland
     * dated May 2004 and found at
     * http://mgasior.web.cern.ch/mgasior/pap/biw2004.pdf
     */

    int i;
    double arrwin[MAX_SAMPLE];
    double magn[MAX_SAMPLE], phase[MAX_SAMPLE];
    double avg = sigAvg(arr, len);

    /* Apply a Hann window to the time domain data */
    for(i = 0; i < len; i++)
        arrwin[i] = (arr[i]-avg) * 0.5 * (1-cos(2*M_PI*i/(len - 1)));

    /* Take the Fourier transform */
    faFourier(arrwin, magn, phase, len);

    i = fundFreqBin(magn, len);

    if(i == 0)
        return 0.0001;

    /* Interpolate using gaussian frequency interpolation, again no peak merging */
    return ((double) i + log(magn[i+1]/magn[i-1]) / 2 /
           log(magn[i]*magn[i]/magn[i+1]/magn[i-1]));
}

/*******************************************************************************
 ******************************************************************************/

/* Returns the period of the signal
 * arr[]: array in which to find the period
 * len: length of the array
 */
double sigPeriod(double arr[], int len)
{
    double freq;
    freq = sigFreq(arr, len);
    if(freq == 0)
    {
        freq = 1e-6;
    }
    return (1/freq);
}

/* Returns the phase of the signal
 * arr[]: array in which to find the maximum value
 * len: length of the array
 */
double sigPhase(double magn[], double phase[], int len)
{
    return phase[fundFreqBin(magn, len)];
}

/* Returns the average value of a periodic signal over all sampled periods
 * arr: the array of digitized values
 * period: the period of the signal captured in the array
 * len: the length of the array
 */
double sigPeriodAvg(double arr[], double period, int len)
{
    int i;
    double sigSum;
    if(period==0)
    {
        period = len;
    }
    else
    {
        i = len / period;
        period = i * period;
        if(period==0)
            return (sigAvg(arr,len));
    }
    sigSum = 0.5*arr[0];
    for(i=1; i < period; i++)
        sigSum+= arr[i];
    sigSum+= (arr[i+1] - arr[i]) * (period - i);
    return (sigSum / period);
}

/* Returns the RMS value of a period signal over all sampled periods
 * arr: the array of digitized values
 * period: the period of the signal captured in the array
 * len: the length of the array
 */
double sigPeriodRMS(double arr[], double period, int len)
{
    int i;
    double sigSumSq;
    if(period==0)
    {
        period = len;
    }
    else
    {
        i = len / period;
        period = i * period;
        if(period ==0)
            return (sigRMS(arr,len));
    }
    sigSumSq = 0.5*arr[0]*arr[0];
    for(i=1; i < period; i++)
        sigSumSq+= arr[i]*arr[i];
    sigSumSq+= (period - i) * (arr[i+1]*arr[i+1] - arr[i]*arr[i]);
    return (sqrt(sigSumSq / period));
}

/* Returns the AC RMS value (RMS value without the DC component) of a periodic signal over all sampled periods
 * arr: the array of digitized values
 * period: the period of the signal captured in the array
 * len: the length of the array
 */
double sigPeriodRMS_ACOnly(double arr[], double period, int len)
{
    int i;
    double avg, sumsq, val;
    avg = sigPeriodAvg(arr, period, len);
    if(period==0)
    {
        period = len;
    }
    else
    {
        i = len / period;
        period = i * period;
        if(period==0)
            return (sigRMS_AConly(arr,len));
    }
    sumsq = arr[0] - avg;
    sumsq*= sumsq;
    for(i = 1; i < period; i++)
    {
        val = arr[i] - avg;
        sumsq+= val*val;
    }
    avg = arr[i+1] - avg;
    avg*= avg;
    sumsq+= (period - i)*(avg - val*val);
    return (sqrt(sumsq / period));
}

/* Returns the average time of the positive slope transition between 20% and 80%
 * of the difference between the minimum and maximum value
 * arr: signal to analyze
 * len: number of samples in the signal
 */
double sigRiseTime(double arr[], int len)
{
   double max, min, maxLevel, minLevel, tTime, tCount, xMinLevel, xMaxLevel;
   int state, i;

   max = sigMax(arr, len);
   min = sigMin(arr, len);
   maxLevel = 0.2*min + 0.8*max;
   minLevel = 0.8*min + 0.2*max;
   state = 0;
   tTime = 0;
   tCount = 0;
   for(i = 0; i < len; i++)
   {
       switch(state)
       {
       case 0:
           if(arr[i] <= minLevel)
               state = 1;
           break;
       case 1:
           if(arr[i] > minLevel)
           {
               xMinLevel = (minLevel - arr[i-1]) / (arr[i] - arr[i-1]) + i-1;
               state = 2;
           }
           break;
       case 2:
           if(arr[i] > maxLevel)
           {
               xMaxLevel = (maxLevel - arr[i-1]) / (arr[i] - arr[i-1]) + i-1;
               tTime+= xMaxLevel - xMinLevel;
               tCount++;
               state = 0;
           }
           break;
       }
   }
   if(tCount ==0) tCount++;
   return (tTime / tCount);
}

/* Returns the average time of the negative slope transition between 80% and 20%
 * of the difference between the maximum and minimum value
 * arr: signal to analyze
 * len: number of samples in the signal
 */
double sigFallTime(double arr[], int len)
{
   double max, min, maxLevel, minLevel, tTime, tCount, xMinLevel, xMaxLevel;
   int state, i;

   max = sigMax(arr, len);
   min = sigMin(arr, len);
   maxLevel = 0.2*min + 0.8*max;
   minLevel = 0.8*min + 0.2*max;
   state = 0;
   tTime = 0;
   tCount = 0;
   for(i = 0; i < len; i++)
   {
       switch(state)
       {
       case 0:
           if(arr[i] >= maxLevel)
               state = 1;
           break;
       case 1:
           if(arr[i] < maxLevel)
           {
               xMaxLevel = (maxLevel - arr[i-1]) / (arr[i] - arr[i-1]) + i-1;
               state = 2;
           }
           break;
       case 2:
           if(arr[i] < minLevel)
           {
               xMinLevel = (minLevel - arr[i-1]) / (arr[i] - arr[i-1]) + i-1;
               tTime+= xMinLevel - xMaxLevel;
               tCount++;
               state = 0;
           }
           break;
       }
   }
   if(tCount==0) tCount++;
   return (tTime / tCount);
}

/* Time of the first occurance of the signal maximum relative to the first sample
 */
double sigTimeMax(double arr[], int len)
{
    double max;
    int i;

    max = sigMax(arr, len);
    i = 0;
    while((i < len) && (arr[i] < max))
        i++;
    return i;
}

/* Time of the first occurance of the signal minimum relative to the first sample
 */
double sigTimeMin(double arr[], int len)
{
    double min;
    int i;

    min = sigMin(arr, len);
    i = 0;
    while((i < len) && (arr[i] > min))
        i++;
    return i;
}

/* The pulsewidth of the signal.  The pulsewidth is measured as the amount of
 * time the signal is atleast 80% of the difference between the maximum value
 * and the minimum value plus the minimum value.
 */
double sigPulseWidth(double arr[], int len)
{
   double maxLevel, tTime, tCount, xMinLevel, xMaxLevel;
   int state, i;

   maxLevel = 0.2*sigMin(arr, len) + 0.8*sigMax(arr, len);
   state = 0;
   tTime = 0;
   tCount = 0;
   for(i = 0; i < len; i++)
   {
       switch(state)
       {
       case 0:
           if(arr[i] < maxLevel)
               state = 1;
           break;
       case 1:
           if(arr[i] >= maxLevel)
           {
               xMaxLevel = (maxLevel - arr[i-1]) / (arr[i] - arr[i-1]) + i-1;
               state = 2;
           }
           break;
       case 2:
           if(arr[i] < maxLevel)
           {
               xMinLevel = (maxLevel - arr[i-1]) / (arr[i] - arr[i-1]) + i-1;
               tTime+= xMinLevel - xMaxLevel;
               tCount++;
               state = 0;
           }
           break;
       }
   }
   if(tCount ==0) tCount++;
   return (tTime / tCount);
}

/* The negative pulsewidth of the signal.  The negative pulsewidth is measured
 * as the amount of time the signal is atmost 20% of the difference between the
 * maximum value and the minimim value plus the minimum value.
 */
double sigNPulseWidth(double arr[], int len)
{
   double minLevel, tTime, tCount, xMinLevel, xMaxLevel;
   int state, i;

   minLevel = 0.8*sigMin(arr, len) + 0.2*sigMax(arr, len);
   state = 0;
   tTime = 0;
   tCount = 0;
   for(i = 0; i < len; i++)
   {
       switch(state)
       {
       case 0:
           if(arr[i] > minLevel)
               state = 1;
           break;
       case 1:
           if(arr[i] <= minLevel)
           {
               xMaxLevel = (minLevel - arr[i-1]) / (arr[i] - arr[i-1]) + i-1;
               state = 2;
           }
           break;
       case 2:
           if(arr[i] > minLevel)
           {
               xMinLevel = (minLevel - arr[i-1]) / (arr[i] - arr[i-1]) + i-1;
               tTime+= xMinLevel - xMaxLevel;
               tCount++;
               state = 0;
           }
           break;
       }
   }
   if(tCount ==0) tCount++;
   return (tTime / tCount);
}

/* Duty cycle is the pulsewidth divided by the period.
 */
double sigDutyCycle(double arr[], int len)
{
    return (sigPulseWidth(arr, len) / sigPeriod(arr, len) / len);
}

/* Negative duty cycle is the negative pulsewidth divided by the period.
 */
double sigNDutyCycle(double arr[], int len)
{
    return (sigNPulseWidth(arr, len) / sigPeriod(arr, len) / len);
}

/* Helper function
 * Determines the bin width for the fundamental and each harmonic
 */
int binWidth(int fundBin)
{
    /* Determine bins on upper and lower side of fundamental */
    if(fundBin <= 2)
        return 0;
    if(fundBin <= 5)
        return 1;
    else
        return 2;
}

/* Helper function
 * Calculate fundamental frequency power
 */
double hPwr(double magn[], int bin, int bw)
{
    double pwr;
    int j;

    pwr = 0;
    for(j = bin - bw; j <= bin + bw; j++)
        pwr+= magn[j]*magn[j];
    return pwr;
}

/* Returns the Total Harmonic Distortion (THD) of a signal (represented by a spectrum).
 */
double sigTHD(double magn[], int len)
{
    int i, j, k, l, m, bw, h;
    double fpwr, pwr, peak;

    i = fundFreqBin(magn, len);
    if(i == 0)
        return 1;

    bw = binWidth(i);

    /* Calculate the power of the fundamental */
    fpwr = hPwr(magn, i, bw);

    /* Calculate power of the harmonic frequencies */
    pwr = 0;
    h = 2;
    l = 0;
    while(l < len)
    {
        k = (i - 0.5) * h;
        l = (i + 0.5) * h;
        h++;
        peak = 0;
        for(j = k; j < l; j++)
        {
            if(magn[j] > peak)
            {
                peak = magn[j];
                m = j;
            }
        }
        pwr+= hPwr(magn, m, bw);
    }

    /* Calculate THD including noise */
    return (pwr / fpwr);
}

/* Returns the Total Harmonic Distortion plus Noise (THDN) of a signal (represented
 * by a spectrum).
 */
double sigTHDN(double magn[], int len)
{
    int i, bw;
    double fpwr, pwr;

    i = fundFreqBin(magn, len);
    if(i == 0)
        return 1;

    bw = binWidth(i);

    /* Calculate the power of the fundamental */
    fpwr = hPwr(magn, i, bw);

    /* Calculate signal and noise power */
    pwr = 0;
    for(i = 0; i < len; i++)
        pwr+= magn[i]*magn[i];

    /* Calculate THD including noise */
    return ((pwr - fpwr) / fpwr);
}

/* Returns the magnitude of the fundamental frequency of a signal (represented by a
 * spectrum).
 */
double sigMagn(double magn[], int len)
{
    int i, bw;

    i = fundFreqBin(magn, len);
    if(i == 0)
        return 0;

    bw = binWidth(i);

    return sqrt(hPwr(magn, i, bw));
}

/* Signal to Noise Ratio
 * Ratio of the sum of all signal and harmonic power to the noise power in the
 * signal.
 * SNR = Power of Signal / Power of Noise = (Amplitude of Signal / Amplitude of Noise)^2
 */
double sigSNR(double magn[], int len)
{
    double td, tdn;
    td = sigTHD(magn, len);
    tdn = sigTHDN(magn, len);
    return (1 / ((td*td)/(tdn*tdn) - 1));
}

/******************************************************************************
 ******************************************************************************/

/* Signal to Distortion ratio
 */
double sigSDR(double magn[], int len)
{
    return 0;
}

/* Signal peak noise to signal ratio
 */
double sigSPN(double magn[], int len)
{
    return 0;
}
