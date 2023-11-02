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
 
#include <math.h>
#include "fourier.h"

/* Returns the maximum value of the signal
 * arr[]: array in which to find the maximum value
 * len: length of the array
 */
double sigMax(double arr[], int len);

/* Returns the minimum value of the signal
 * arr[]: array in which to find the minimum value
 * len: length of the array
 */
double sigMin(double arr[], int len);

/* Returns the peak to peak, difference between the maximum to the minimum value, of the signal
 * arr[]: array in which to find the peak to peak value
 * len: length of the array
 */
double sigPeakToPeak(double arr[], int len);

/* Returns the average value of the signal
 * arr[]: array in which to find the average value
 * len: length of the array
 */
double sigAvg(double arr[], int len);

/* Returns the RMS value of the signal
 * arr[]: array in which to find the RMS value
 * len: length of the array
 */
double sigRMS(double arr[], int len);

/* Returns the RMS value without the DC component of the signal
 * arr[]: array in which to find the RMS value
 * len: length of the array
 */
double sigRMS_AConly(double arr[], int len);

/* Returns the fundamental frequency of the signal
 * arr[]: array in which to find the fundamental frequency
 * len: length of the array
 */
double sigFreq(double arr[], int len);

/* Returns the period of the signal
 * arr[]: array in which to find the period
 * len: length of the array
 */
double sigPeriod(double arr[], int len);

/* Returns the phase of the signal
 * arr[]: array in which to find the maximum value
 * len: length of the array
 */
double sigPhase(double magn[], double phase[], int len);

/* Returns the average value of a periodic signal over all sampled periods
 * arr: the array of digitized values
 * period: the period of the signal captured in the array
 * len: the length of the array
 */
double sigPeriodAvg(double arr[], double period, int len);

/* Returns the RMS value of a period signal over all sampled periods
 * arr: the array of digitized values
 * period: the period of the signal captured in the array
 * len: the length of the array
 */
double sigPeriodRMS(double arr[], double period, int len);

/* Returns the AC RMS value (RMS value without the DC component) of a periodic signal over all sampled periods
 * arr: the array of digitized values
 * period: the period of the signal captured in the array
 * len: the length of the array
 */
double sigPeriodRMS_ACOnly(double arr[], double period, int len);

/* Returns the average time of the positive slope transition between 20% and 80%
 * of the difference between the minimum and maximum value
 * arr: signal to analyze
 * len: number of samples in the signal
 */
double sigRiseTime(double arr[], int len);

/* Returns the average time of the negative slope transition between 80% and 20%
 * of the difference between the maximum and minimum value
 * arr: signal to analyze
 * len: number of samples in the signal
 */
double sigFallTime(double arr[], int len);

/* Time of the first occurance of the signal maximum relative to the first sample
 */
double sigTimeMax(double arr[], int len);

/* Time of the first occurance of the signal minimum relative to the first sample
 */
double sigTimeMin(double arr[], int len);

/* The pulsewidth of the signal.  The pulsewidth is measured as the amount of 
 * time the signal is atleast 80% of the difference between the maximum value
 * and the minimum value plus the minimum value. 
 */
double sigPulseWidth(double arr[], int len);

/* The negative pulsewidth of the signal.  The negative pulsewidth is measured 
 * as the amount of time the signal is atmost 20% of the difference between the
 * maximum value and the minimim value plus the minimum value. 
 */
double sigNPulseWidth(double arr[], int len);

/* Duty cycle is the pulsewidth divided by the period.
 */
double sigDutyCycle(double arr[], int len);

/* Negative duty cycle is the negative pulsewidth divided by the period.
 */
double sigNDutyCycle(double arr[], int len);

/* Returns the Total Harmonic Distortion (THD) of a signal (represented by a spectrum).  
 */
double sigTHD(double magn[], int len);

/* Returns the Total Harmonic Distortion plus Noise (THDN) of a signal (represented 
 * by a spectrum).  
 */
double sigTHDN(double magn[], int len);

/* Returns the magnitude of the fundamental frequency of a signal (represented by a 
 * spectrum).
 */
double sigMagn(double magn[], int len);

/* Signal to Noise Ratio 
 * Ratio of the sum of all signal and harmonic power to the noise power in the 
 * signal.
 * SNR = Power of Signal / Power of Noise = (Amplitude of Signal / Amplitude of Noise)^2
 */
double sigSNR(double magn[], int len); 

/* Signal to Distortion ratio
 */
double sigSDR(double magn[], int len);

/* Signal peak noise to signal ratio
 */
double sigSPN(double magn[], int len);
