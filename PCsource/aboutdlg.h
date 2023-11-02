/* ==============================================================================
 * Author:  Jonathan Weaver, jonw0224@aim.com
 * E-mail Contact: jonw0224@aim.com
 * Description:  About Dialog Box
 * Version: 2.01
 * Date: 8/17/2006
 * Filename:  aboutdlg.c, aboutdlg.h
 *
 * Versions History:  
 *      2.01 - 8/6/2006 - Added about dialog
 *      2.01 - 8/17/2006 - Separated into aboutdlg.c, .h
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

/* About Dialog */
#define ABOUTDLG            4000
#define ABTDLG_OK           4001
#define ABTDLG_BMP          4003
#define ABTDLG_TITLE        4004
#define ABTDLG_LICENSE      4005
#define ABOUTBMP            4006
#define ABT_LICENSE_MISSING 4007
#define ABTDLG_LIC          4008

/* Declare About Dialog Procedure */
BOOL CALLBACK AboutDlgProc (HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam);
