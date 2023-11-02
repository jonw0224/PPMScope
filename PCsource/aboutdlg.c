/* ==============================================================================
 * Author:  Jonathan Weaver, jonw0224@aim.com
 * E-mail Contact: jonw0224@aim.com
 * Description:  About Dialog Box.
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

#include "main.h"
#include "aboutdlg.h"

/* Processes messages for the About dialog box */
BOOL CALLBACK AboutDlgProc (HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
    HWND hAbtBitmap, hAbtLicense, hAbtOK;
    HANDLE hImage;
    char noLicTxt[750];   

    switch (message)
    {
    case WM_INITDIALOG:
        hAbtBitmap = GetDlgItem(hDlg, ABTDLG_BMP);
        hAbtLicense = GetDlgItem(hDlg, ABTDLG_LICENSE);
        hAbtOK = GetDlgItem(hDlg, ABTDLG_OK);
        hImage = LoadImage(hInstance, MAKEINTRESOURCE(ABOUTBMP), IMAGE_BITMAP, 0, 0, 0);
        SendMessage(hAbtBitmap, STM_SETIMAGE, (WPARAM) IMAGE_BITMAP, (LPARAM) hImage);  
        LoadString(hInstance, ABT_LICENSE_MISSING, noLicTxt, 750);
        SetWindowText(hAbtLicense, noLicTxt);
        return TRUE;
    case WM_COMMAND:
        switch (LOWORD (wParam))
        {
        case ABTDLG_OK:
            EndDialog (hDlg, 0);
            return TRUE;
        case ABTDLG_LIC:
             ShellExecute(0, "open", "notepad.exe", "gpl.txt", "" , SW_SHOWNORMAL);
             return TRUE;
        }
        break;
    case WM_CLOSE:
        EndDialog(hDlg, 0);
        break;
    case WM_DESTROY:
        DeleteObject(hImage);    
        break;
    }
    return FALSE;
}    
