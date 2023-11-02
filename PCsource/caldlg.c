/* ==============================================================================
 * Author:  Jonathan Weaver, jonw0224@aim.com
 * E-mail Contact: jonw0224@aim.com
 * Description:  Refresh Rate Dialog Box.
 * Version: 2.14
 * Date: 3/21/2011
 * Filename:  refreshratedlg.c, refreshratedlg.h
 *
 * Versions History:  
 *      2.14 - 3/21/2011 - Added refresh rate dialog
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

#include "main.h"
#include "caldlg.h"

/* Processes messages for the Calibrate dialog box */
BOOL CALLBACK CalDlgProc (HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
        
    switch (message)
    {
    case WM_INITDIALOG:
        return TRUE;
    case WM_COMMAND:
        switch (LOWORD (wParam))
        {
        case CALDLG_OK:
        case CALDLG_CANCEL:
            EndDialog (hDlg, 0);
            return TRUE;
            break;
        }
        break;
    case WM_CLOSE:
        EndDialog(hDlg, 0);
        break;
    case WM_DESTROY:
        break;
    }
    return FALSE;
}    
