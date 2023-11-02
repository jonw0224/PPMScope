/* ==============================================================================
 * Author:  Jonathan Weaver, jonw0224@aim.com
 * E-mail Contact: jonw0224@aim.com
 * Description:  Initialization File Input/Output
 * Version: 1.0
 * Date: 12/22/2011
 * Filename:  ini_io.c, ini_io.h
 *
 * Versions History:
 *      1.0 - 12/22/2011 - Added header to files
 *
 * Copyright (C) 2011 Jonathan Weaver
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

#define RECCNT      100
#define COLCNT      2
#define RECLENGTH   100

int readConfigFile(char* fileName);

char* getConfigPar(char* parName);

int enumeratePrint();

int clearConfig();

int setConfigPar(char* parName, char* parValue);



