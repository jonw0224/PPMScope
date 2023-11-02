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

#define CALDLG            4249
#define CALDLG_MVN12      4250
#define CALDLG_MVN11      4251
#define CALDLG_MVN10      4252
#define CALDLG_MVN9       4253
#define CALDLG_MVN8       4254
#define CALDLG_MV0        4255
#define CALDLG_MV8        4256
#define CALDLG_MV9        4257
#define CALDLG_MV10       4258
#define CALDLG_MV11       4259
#define CALDLG_MV12       4260
#define CALDLG_CH1N12     4261
#define CALDLG_CH1N11     4262
#define CALDLG_CH1N10     4263
#define CALDLG_CH1N9      4264
#define CALDLG_CH1N8      4265
#define CALDLG_CH10       4266
#define CALDLG_CH18       4267
#define CALDLG_CH19       4268
#define CALDLG_CH110      4269
#define CALDLG_CH111      4270
#define CALDLG_CH112      4271
#define CALDLG_CH2N12     4272
#define CALDLG_CH2N11     4273
#define CALDLG_CH2N10     4274
#define CALDLG_CH2N9      4275
#define CALDLG_CH2N8      4276
#define CALDLG_CH20       4277
#define CALDLG_CH28       4278
#define CALDLG_CH29       4279
#define CALDLG_CH210      4280
#define CALDLG_CH211      4281
#define CALDLG_CH212      4282
#define CALDLG_IMG        4283
#define CALDLG_OK         4284
#define CALDLG_CANCEL     4285

/* Processes messages for the Hardware dialog box */
BOOL CALLBACK CalDlgProc (HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam);

