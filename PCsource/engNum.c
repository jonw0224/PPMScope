/* ==============================================================================
 * Author:  Jonathan Weaver, jonw0224@aim.com
 * E-mail Contact: jonw0224@aim.com
 * Description:  Handles English representation numeric strings.
 * Version: 2.01
 * Date: 8/19/2006
 * Filename:  engnum.c, engnum.h
 *
 * Versions History:
 *      2.01 - 8/19/2006 - Created file
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

#include <stdio.h>
#include <stdlib.h>

// Converts an string number in english notation to a double
// engStr: a string containing an english notation number and whitespace
//         The string can be a scientific notation number, or a regular number
//         OR the string can include the postfixes T, G, M, k, m, u, n, p, f
//         notating multiply by 10e12, 10e9, 10e6, 10e3, 10e-3, 10e-6, 10e-9,
//         10e-12, and 10e-15 repectively.
// returns: a double containing the numberical value of engStr
double EngStrToNum(char *engStr)
{
    double a;
    char* endptr;
    a = strtod(engStr, &endptr);
    switch(*endptr)
    {
    case 'T':
        return a * 1.0e12;
    case 'G':
        return a * 1.0e9;
    case 'M':
        return a * 1.0e6;
    case 'k':
        return a * 1.0e3;
    case 'm':
        return a * 1.0e-3;
    case 'u':
        return a * 1.0e-6;
    case 'n':
        return a * 1.0e-9;
    case 'p':
        return a * 1.0e-12;
    case 'f':
        return a * 1.0e-15;
    default:
        return a;
    }
}

// Converts double to a string number in english notation
// num: the double to convert
// engStr: an output string containing an english notation number and whitespace
//         The string can be a scientific notation number, or a regular number
//         OR the string can include the postfixes T, G, M, k, m, u, n, p, f
//         notating multiply by 10e12, 10e9, 10e6, 10e3, 10e-3, 10e-6, 10e-9,
//         10e-12, and 10e-15 repectively.
// returns: 0
int NumToEngStr(double num, char *engStr)
{
    if (num >= 1.0e15 || num <= -1.0e15)
        sprintf(engStr, "%.3E", num);              //Use scientific notation
    else if (num >= 1.0e12 || num <= -1.0e12)
        sprintf(engStr, "%.3fT", num/1.0e12);      //Units in Terra
    else if (num >= 1.0e9 || num <= -1.0e9)
        sprintf(engStr, "%.3fG", num/1.0e9);       //Units in Giga
    else if (num >= 1.0e6 || num <= -1.0e6)
        sprintf(engStr, "%.3fM", num/1.0e6);       //Units in Mega
    else if (num >= 1000.0 || num <= -1000.0)
        sprintf(engStr, "%.3fk", num/1000.0);      //Units in kilo
    else if (num >= 1.0 || num <= -1.0)
        sprintf(engStr, "%.3f", num);              //Units in ones
    else if (num >= 0.001 || num <= -0.001)
        sprintf(engStr, "%.3fm", num*1000.0);      //Units in milli
    else if (num >= 1.0e-6 || num <= -1.0e-6)
        sprintf(engStr, "%.3fu", num*1.0e6);       //Units in micro
    else if (num >= 1.0e-9 || num <= -1.0e-9)
        sprintf(engStr, "%.3fn", num*1.0e9);       //Units in nano
    else if (num >= 1.0e-12 || num <= -1.0e-12)
        sprintf(engStr, "%.3fp", num*1.0e12);      //Units in pico
    else if (num >= 1.0e-15 || num <= -1.0e-15)
        sprintf(engStr, "%.3ff", num*1.0e15);      //Units in fempta
    else if (num == 0.0)
        sprintf(engStr, "%.3f", num);      //Units in fempta
    else
        sprintf(engStr, "%.3E", num);              //Use scientific notation
    return 0;
}
