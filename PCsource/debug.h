/* ==============================================================================
 * Author:  Jonathan Weaver, jonw0224@aim.com
 * E-mail Contact: jonw0224@aim.com
 * Description:  Debug routines
 * Version: 1.0
 * Date: 11/18/2009
 * Filename:  debug.c, debug.h
 *
 * Versions History:  
 *      1.0 - 11/18/2009 - Added header to files
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

//& dOpen opens a file for output for use as a debugging tool
//& *dfile:  a character string for the filename
//& returns:  0 if successful, EOF if fails
int dOpen(char *dfile);

//& dClose closes the debugging stream
//& returns:  0 if successful, EOF if fails 
int dClose();

//& dPrStr prints a string to the debug file excluding the terminating null
//& *toPrint:  a pointer to the null terminated string to print
//& returns:  0 if successful, EOF if fails
int dPrStr(char *toPrint);

//& dPrInt prints an integer to the debug file
//& *toPrint:  an integer to print
//& returns:  0 if successful, EOF if fails
int dPrInt(int toPrint);

//& dPrFlt prints an float to the debug file
//& toPrint:  an float to print
//& returns:  0 if successful, EOF if fails
int dPrFlt(double toPrint);

