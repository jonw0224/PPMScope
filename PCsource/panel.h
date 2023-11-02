/* ==============================================================================
 * Author:  Jonathan Weaver, jonw0224@aim.com
 * E-mail Contact: jonw0224@aim.com
 * Description:  Side panel window.
 * Version: 2.16
 * Date: 6/15/2012
 * Filename:  panel.c, panel.h
 *
 * Versions History:
 *      2.01 - 8/17/2006 - created files
 *      2.16 - 6/15/2012 - Modified to make time per div, volt per div, volt
 *                         offset, and trigger delay modifiers public for use
 *                         by the main program in handling hotkeys.
 *
 * Copyright (C) 2006 - 2012 Jonathan Weaver
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

#define WM_REFRESHPANEL   9001

//Panel Buttons
#define DLG_UNUSED                  0
#define ED_TIME_PER_DIV             9201

#define CM_TIME_PER_DIV_F          9202
#define CM_TIME_PER_DIV_C          9203
#define CM_TIME_PER_DIV_INC         9204
#define CM_TIME_PER_DIV_DEC         9205

#define ED_SAMPLE_RATE              9206
#define ST_TIME                     9207

#define CM_CHA_COLOR                9208
#define CM_CHA_ENABLED              9209
#define CB_CHA_SOURCE               9210
#define ED_VOLT_PER_DIV_CHA         9211
#define CM_VOLT_PER_DIV_CHA_FINC    9212
#define CM_VOLT_PER_DIV_CHA_CINC    9213
#define CM_VOLT_PER_DIV_CHA_FDEC    9214
#define CM_VOLT_PER_DIV_CHA_CDEC    9215
#define ED_VOLT_OFFSET_CHA          9216
#define CM_VOLT_OFFSET_CHA_INC      9217
#define CM_VOLT_OFFSET_CHA_DEC      9218
#define ST_CHA                      9219

#define CM_CHB_COLOR                9220
#define CM_CHB_ENABLED              9221
#define CB_CHB_SOURCE               9222
#define ED_VOLT_PER_DIV_CHB         9223
#define CM_VOLT_PER_DIV_CHB_FINC    9224
#define CM_VOLT_PER_DIV_CHB_CINC    9225
#define CM_VOLT_PER_DIV_CHB_FDEC    9226
#define CM_VOLT_PER_DIV_CHB_CDEC    9227
#define ED_VOLT_OFFSET_CHB          9228
#define CM_VOLT_OFFSET_CHB_INC      9229
#define CM_VOLT_OFFSET_CHB_DEC      9230
#define ST_CHB                      9231

#define CB_TRIGGER_MODE             9232
#define ED_TRIGGER_DELAY            9233
#define CM_TRIGGER_DELAY_INC        9234
#define CM_TRIGGER_DELAY_DEC        9235

#define ST_T_CUR1                   9236
#define ST_P_CUR1                   9237
#define ST_CHA_CUR1                 9238
#define ST_CHB_CUR1                 9239
#define ST_T_CUR2                   9240
#define ST_P_CUR2                   9241
#define ST_CHA_CUR2                 9242
#define ST_CHB_CUR2                 9243
#define ST_T_DELTA                  9244
#define ST_P_DELTA                  9245
#define ST_CHA_DELTA                9246
#define ST_CHB_DELTA                9247
#define ST_TRIG                     9248
#define ST_LABA                     9249
#define ST_LABB                     9250
#define ST_LABC                     9251
#define ST_LABD                     9252

#define MATH_F1                     9253
#define ED_MATH_F1                  9254
#define MATH_F2                     9255
#define ED_MATH_F2                  9256
#define MATH_F3                     9257
#define ED_MATH_F3                  9258
#define MATH_F4                     9259
#define ED_MATH_F4                  9260

#define CM_VOLT_PER_DIV_CHA_F       9261
#define CM_VOLT_PER_DIV_CHA_C       9262
#define CM_VOLT_OFFSET_CHA          9263
#define CM_VOLT_PER_DIV_CHB_F       9264
#define CM_VOLT_PER_DIV_CHB_C       9265
#define CM_VOLT_OFFSET_CHB          9266
#define CM_TRIGGER_DELAY            9267

#define DLG_OK                      9268
#define ST_TRIG_SRC                 9269

#define CM_CHC_COLOR                9270
#define CM_CHC_ENABLED              9271
#define CB_CHC_SOURCE               9272
#define ED_VOLT_PER_DIV_CHC         9273
#define CM_VOLT_PER_DIV_CHC_FINC    9274
#define CM_VOLT_PER_DIV_CHC_CINC    9275
#define CM_VOLT_PER_DIV_CHC_FDEC    9276
#define CM_VOLT_PER_DIV_CHC_CDEC    9277
#define ED_VOLT_OFFSET_CHC          9278
#define CM_VOLT_OFFSET_CHC_INC      9279
#define CM_VOLT_OFFSET_CHC_DEC      9280

#define CM_CHD_COLOR                9281
#define CM_CHD_ENABLED              9282
#define CB_CHD_SOURCE               9283
#define ED_VOLT_PER_DIV_CHD         9284
#define CM_VOLT_PER_DIV_CHD_FINC    9285
#define CM_VOLT_PER_DIV_CHD_CINC    9286
#define CM_VOLT_PER_DIV_CHD_FDEC    9287
#define CM_VOLT_PER_DIV_CHD_CDEC    9288
#define ED_VOLT_OFFSET_CHD          9289
#define CM_VOLT_OFFSET_CHD_INC      9290
#define CM_VOLT_OFFSET_CHD_DEC      9291

#define CM_VOLT_PER_DIV_CHC_F       9292
#define CM_VOLT_PER_DIV_CHC_C       9293
#define CM_VOLT_OFFSET_CHC          9294
#define CM_VOLT_PER_DIV_CHD_F       9295
#define CM_VOLT_PER_DIV_CHD_C       9296
#define CM_VOLT_OFFSET_CHD          9297

#define MATHSRC_F1                  9298
#define MATHSRC_F2                  9299
#define MATHSRC_F3                  9300
#define MATHSRC_F4                  9301

/* Panel combo box choices */
#define CB_CHOICE1                  2600
#define CB_CHOICE2                  2601
#define CB_CHOICE3                  2602
#define CB_CHOICE4                  2603
#define CB_CHOICE5                  2604
#define CB_CHOICE6                  2605
#define CB_CHOICE7                  2606
#define CB_CHOICE8                  2607
#define CB_CHOICE9                  2608
#define CB_CHOICE10                 2609
#define CB_CHOICE11                 2610
#define CB_CHOICE12                 2611
#define CB_CHOICE13                 2612
#define CB_CHOICE14                 2613
#define CB_CHOICE15                 2614
#define CB_CHOICE16                 2615
#define CB_CHOICE17                 2616
#define CB_CHOICE18                 2617
#define CB_CHOICE19                 2618
#define CB_CHOICE20                 2619
#define CB_CHOICE21                 2620
#define CB_CHOICE22                 2621
#define CB_CHOICE23                 2622


/* Measure combo box choices */
#define MEASURE_CHOICE0             2629
#define MEASURE_CHOICE1             2630
#define MEASURE_CHOICE2             2631
#define MEASURE_CHOICE3             2632
#define MEASURE_CHOICE4             2633
#define MEASURE_CHOICE5             2634
#define MEASURE_CHOICE6             2635
#define MEASURE_CHOICE7             2636
#define MEASURE_CHOICE8             2637
#define MEASURE_CHOICE9             2638
#define MEASURE_CHOICE10            2639
#define MEASURE_CHOICE11            2640
#define MEASURE_CHOICE12            2641
#define MEASURE_CHOICE13            2642
#define MEASURE_CHOICE14            2643
#define MEASURE_CHOICE15            2644
#define MEASURE_CHOICE16            2645
#define MEASURE_CHOICE17            2646
#define MEASURE_CHOICE18            2647
#define MEASURE_CHOICE19            2648
#define MEASURE_CHOICE20            2649
#define MEASURE_CHOICE21            2650
#define MEASURE_CHOICE22            2651
#define MEASURE_CHOICE23            2652
#define MEASURE_CHOICE24            2653

#define MEASURE_SRC_CH1             2700
#define MEASURE_SRC_CH2             2701
#define MEASURE_SRC_CH3             2702
#define MEASURE_SRC_CH4             2703

/* Measurements */
char measureFunct[4];

/* constants for channel makeup */
#define CH1ONLY          0
#define CH2ONLY          1
#define NEGCH1ONLY       2
#define NEGCH2ONLY       3
#define CH1PLUSCH2       4
#define NEGCH1PLUSCH2    5
#define CH1LESSCH2       6
#define CH2LESSCH1       7
#define CH1TIMESCH2      8
#define NEGCH1TIMESCH2   9

/* constants for measurement function */
#define SRMSAC               1
#define SAVG                 2
#define SDCYC                3
#define SFALLT               4
#define SFREQ                5
#define SMAGN                6
#define SMAX                 7
#define SMIN                 8
#define SNDCYC               9
#define SNPULSEW             10
#define SPERIOD              11
#define SPERAVG              12
#define SPERRMS              13
#define SPERRMSAC            14
#define SPHASE               15
#define SPTP                 16
#define SPULSEW              17
#define SRISET               18
#define SRMS                 19
#define SSNR                 20
#define STHD                 21
#define STHDN                22
#define STMAX                23
#define STMIN                24

#define SRCCHA               0
#define SRCCHB               0
#define SRCCHC               0
#define SRCCHD               0


/* Statistics on sampling */
typedef struct tagMEASURESTAT {
	double average;
	double q;
	double stddev;
	double max;
	double min;
	double last;
    int NumSamples;
  } MEASURESTAT;

MEASURESTAT mStat[4];

/* Declare Panel procedure */
BOOL CALLBACK PanelProc (HWND hPnl, UINT message, WPARAM wParam, LPARAM lParam);

/* Public procedures */

/* Set the trigger positive */
int setTriggerPos();

/* Set the trigger negative */
int setTriggerNeg();

/* Set the trigger off */
int setTriggerOff();

/* Display the cursor information */
int setCursorInfo(int windowType, double xval[], double cha[], double chb[], double chc[], double chd[]);

/* Update the Triggerlevel readout */
int updateTriggerLevel();

/* Update the TriggerChannel readout */
int updateTriggerChannel();

/* Updates the channel readouts */
int updateChannelMsg(int j);

/* Updates measurements on the panel */
int doMeasurements();

/* Change the channel A offset based on the buttons
   adjust: Can be ADJ_FDECR, ADJ_FINCR, ADJ_CDECR, or ADJ_CINCR */
int chAOffsetChange(char adjust);

/* Change the channel B offset based on the buttons
   adjust: Can be ADJ_FDECR, ADJ_FINCR, ADJ_CDECR, or ADJ_CINCR */
int chBOffsetChange(char adjust);

/* Change the channel C offset based on the buttons
   adjust: Can be ADJ_FDECR, ADJ_FINCR, ADJ_CDECR, or ADJ_CINCR */
int chCOffsetChange(char adjust);

/* Change the channel D offset based on the buttons
   adjust: Can be ADJ_FDECR, ADJ_FINCR, ADJ_CDECR, or ADJ_CINCR */
int chDOffsetChange(char adjust);

/* Changes the Channel A Volts per Div based on the push buttons
   adjust: Can be ADJ_FDECR, ADJ_FINCR, ADJ_CDECR, or ADJ_CINCR */
int chAVoltDivChange(char adjust);

/* Changes the Channel B Volts per Div based on the push buttons
   adjust: Can be ADJ_FDECR, ADJ_FINCR, ADJ_CDECR, or ADJ_CINCR */
int chBVoltDivChange(char adjust);

/* Changes the Channel C Volts per Div based on the push buttons
   adjust: Can be ADJ_FDECR, ADJ_FINCR, ADJ_CDECR, or ADJ_CINCR */
int chCVoltDivChange(char adjust);

/* Changes the Channel D Volts per Div based on the push buttons
   adjust: Can be ADJ_FDECR, ADJ_FINCR, ADJ_CDECR, or ADJ_CINCR */
int chDVoltDivChange(char adjust);

/* Changes the time per division based on the push buttons
   adjust: Can be ADJ_FDECR, ADJ_FINCR, ADJ_CDECR, or ADJ_CINCR */
int timePerDivChange(char adjust);

/* Refreshes the trigger delay */
int refreshTriggerDelay();

/* Displays the Statistic Text */
int StatisticText(MEASURESTAT s, char* toRet);
