/* ==============================================================================
 * Author:  Jonathan Weaver, jonw0224@aim.com
 * E-mail Contact: jonw0224@aim.com
 * Description:  Settings for compiling
 * Version: 1.0
 * Date: 3/30/2012
 * Filename:  settings.h
 *
 * Versions History:
 *      1.0 - 1/24/2012 Created header
 *
 * Copyright (C) 2012 Jonathan Weaver
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

#define NOHARDWARE
//#define DEBUGON
//#define SINGLEINSTANCE

#define VERSIONTEXT      "Version 2.20 build 10/6/2016"

#ifdef DEBUGON
    #ifdef NOHARDWARE
        #define WINDOWTEXT          "PPMScope v.2.20 (DEBUG ON - NO HARDWARE)"
    #else
        #define WINDOWTEXT       "PPMScope v.2.20 (DEBUG ON)"
    #endif
#else
    #ifdef NOHARDWARE
        #define WINDOWTEXT          "PPMScope v.2.20 (NO HARDWARE)"
    #else
        #define WINDOWTEXT       "PPMScope v.2.20"
    #endif
#endif

#define COPYRIGHTTEXT    "(C) Copyright 2006-2014, Jonathan Weaver"
