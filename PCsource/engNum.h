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

// Converts an string number in english notation to a double
// engStr: a string containing an english notation number and whitespace
//         The string can be a scientific notation number, or a regular number
//         OR the string can include the postfixes T, G, M, k, m, u, n, p, f
//         notating multiply by 10e12, 10e9, 10e6, 10e3, 10e-3, 10e-6, 10e-9,
//         10e-12, and 10e-15 repectively.
// returns: a double containing the numberical value of engStr
double EngStrToNum(char *engStr);

// Converts double to a string number in english notation
// num: the double to convert
// engStr: an output string containing an english notation number and whitespace
//         The string can be a scientific notation number, or a regular number
//         OR the string can include the postfixes T, G, M, k, m, u, n, p, f
//         notating multiply by 10e12, 10e9, 10e6, 10e3, 10e-3, 10e-6, 10e-9,
//         10e-12, and 10e-15 repectively.
// returns: 0
int NumToEngStr(double num, char *engStr);
