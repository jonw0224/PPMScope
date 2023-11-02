/* ==============================================================================
 * Author:  Jonathan Weaver, jonw0224@aim.com
 * E-mail Contact: jonw0224@aim.com
 * Description:  Hardware Test Dialog Box.
 * Version: 2.19
 * Date: 3/12/2014
 * Filename:  hdwtestdlg.c, hdwtestdlg.h
 *
 * Versions History:
 *      2.14 - 7/28/2010 - Added hardware test dialog
 *      2.19 - 3/12/2014 - Made the hardware test always disable the trigger
 *                         during the test.
 *
 * Copyright (C) 2010-2014 Jonathan Weaver
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
#include "hdwtestdlg.h"

/* Processes messages for the Hardware Test dialog box */
BOOL CALLBACK HdwTestDlgProc (HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
    int trigtemp;
    double sampleratetemp;

    switch (message)
    {
    case WM_INITDIALOG:
        trigtemp = getEnableTrigger();
        sampleratetemp = getSampleRate();
        enableTrigger(0);
        setSampleRate(getMaxSampleRate());
        hDriverInitialize();
        enableTrigger(trigtemp);
        setSampleRate(sampleratetemp);
        SetWindowText(GetDlgItem(hDlg, HDWTESTDLG_LOG), diagnostic);
        return TRUE;
    case WM_COMMAND:
        switch (LOWORD (wParam))
        {
        case HDWTESTDLG_OK:
        case HDWTESTDLG_CANCEL:
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
