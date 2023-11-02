/* ==============================================================================
 * Author:  Jonathan Weaver, jonw0224@aim.com
 * E-mail Contact: jonw0224@aim.com
 * Description:  Hardware Dialog Box.
 * Version: 2.18
 * Date: 1/17/2014
 * Filename:  hardwaredlg.c, hardwaredlg.h
 *
 * Versions History:
 *      2.01 - 4/29/2007 - Added hardware dialog
 *      2.18 - 1/17/2014 - Added COM ports 10 thru 19
 *
 * Copyright (C) 2007-2014 Jonathan Weaver
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

#define HARDWAREDLG                 4050
#define HDWDLG_PORTTYPE             4051
#define HDWDLG_PORT                 4052
#define HDWDLG_IODELAY              4053
#define HDWDLG_PORTADDRESS          4068
#define HDWDLG_IODELAY_LABEL        4066
#define HDWDLG_VERSION              4067
#define HDWDLG_TESTEN               4054
#define HDWDLG_DATAHIGH             4055
#define HDWDLG_DATALOW              4056
#define HDWDLG_DATASTATE            4057
#define HDWDLG_DATAINHIGH           4058
#define HDWDLG_DATAINLOW            4059
#define HDWDLG_DATAINSTATE          4060
#define HDWDLG_CLOCKHIGH            4061
#define HDWDLG_CLOCKLOW             4062
#define HDWDLG_CLOCKSTATE           4063
#define HDWDLG_OK                   4064
#define HDWDLG_CANCEL               4065
#define HDWDLG_PORTADDRESS_LABEL    4069

#define HDWDLG_PORTTYPECHOICE1      4100
#define HDWDLG_PORTTYPECHOICE2      4101
#define HDWDLG_PORTTYPECHOICE3      4102
#define HDWDLG_PORT1NUM1            4103
#define HDWDLG_PORT1NUM2            4104
#define HDWDLG_PORT1NUM3            4105
#define HDWDLG_PORT1NUM4            4106
#define HDWDLG_PORT2NUM1            4107
#define HDWDLG_PORT2NUM2            4108
#define HDWDLG_PORT2NUM3            4109
#define HDWDLG_PORT2NUM4            4110
#define HDWDLG_PORT2NUM5            4111
#define HDWDLG_PORT2NUM6            4112
#define HDWDLG_PORT2NUM7            4113
#define HDWDLG_PORT2NUM8            4114
#define HDWDLG_PORT2NUM9            4115
#define HDWDLG_PORT2NUM10           4116
#define HDWDLG_PORT2NUM11           4117
#define HDWDLG_PORT2NUM12           4118
#define HDWDLG_PORT2NUM13           4119
#define HDWDLG_PORT2NUM14           4120
#define HDWDLG_PORT2NUM15           4121
#define HDWDLG_PORT2NUM16           4122
#define HDWDLG_PORT2NUM17           4123
#define HDWDLG_PORT2NUM18           4124
#define HDWDLG_PORT2NUM19           4125
#define HDWDLG_HDWTYPE1             4126
#define HDWDLG_HDWTYPE2             4127

/* Processes messages for the Hardware dialog box */
BOOL CALLBACK HardwareDlgProc (HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam);

