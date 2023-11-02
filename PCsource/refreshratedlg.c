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
#include "refreshratedlg.h"
#include "engNum.h"

char inputStr[20];
int inputNum;
int srr;

int updateRefreshRate(HWND hDlg)
{
    HWND hctrl;
    hctrl = GetDlgItem(hDlg, REFRESHRATEDLG_ENTRY);
    inputNum = GetWindowTextLength(hctrl);  
    GetWindowText(hctrl, inputStr, inputNum + 1);
    inputNum = EngStrToNum(inputStr);
    if(inputNum == 0)
    {
        /* Invalid, get default */
        srr = 100;
    }
    else
    {
        srr = 1000/inputNum;
        if(srr < 10)
            srr = 10;
    }
    NumToEngStr(1000/srr, inputStr);
    SetWindowText(hctrl, inputStr);

}

/* Processes messages for the Hardware Test dialog box */
BOOL CALLBACK RefreshRateDlgProc (HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
        
    switch (message)
    {
    case WM_INITDIALOG:
        srr = scopeRefreshRate;
        NumToEngStr(1000/srr, inputStr);
        SetWindowText(GetDlgItem(hDlg, REFRESHRATEDLG_ENTRY), inputStr);    
        return TRUE;
    case WM_COMMAND:
        switch (LOWORD (wParam))
        {
        case REFRESHRATEDLG_ENTRY:
            if(HIWORD(wParam) == EN_KILLFOCUS)
            {
                updateRefreshRate(hDlg);
            }
            return TRUE;
        case REFRESHRATEDLG_OK:
            updateRefreshRate(hDlg);          
            scopeRefreshRate = srr;
        case REFRESHRATEDLG_CANCEL:
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
