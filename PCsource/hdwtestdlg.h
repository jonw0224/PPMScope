/* ==============================================================================
 * Author:  Jonathan Weaver, jonw0224@aim.com
 * E-mail Contact: jonw0224@aim.com
 * Description:  Hardware Test Dialog Box.
 * Version: 2.14
 * Date: 7/28/2010
 * Filename:  hdwtestdlg.c, hdwtestdlg.h
 *
 * Versions History:  
 *      2.14 - 7/28/2010 - Added hardware test dialog
 *
 * Copyright (C) 2010 Jonathan Weaver
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

#define HDWTESTDLG            4150
#define HDWTESTDLG_LOG        4151
#define HDWTESTDLG_OK         4152
#define HDWTESTDLG_CANCEL     4153

/* Processes messages for the Hardware dialog box */
BOOL CALLBACK HdwTestDlgProc (HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam);

