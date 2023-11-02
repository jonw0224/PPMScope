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
 
 /* Declares the maximum length of channel.  Must be a power of 2. */
#define MAX_SAMPLE  256

/* Fast Fourier Transform, return result in polar.
 * Note:All frequency components are scaled so that
 * channel[i] = sum( magn[k]*cos(2*pi*i*k/n-phase[k] ) from k = 0 to k = n/2+1
 * channel[]: signal to to transform using the discrete fourier transform
 * magn[]: magnitude information returned
 * phase[]: phase information returned
 * n: number of samples in channel.  n must be an integer power of 2.
 * Returns: 0 */
int faFourier(double channel[], double magn[], double phase[], int n);

