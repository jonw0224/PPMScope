PPMScope (PC-PIC-MaximADC Scope)
===============================================================================

Date:  4/17/2014
Author:  Jonathan Weaver, jonw0224@aim.com, http://jonw0224.tripod.com
Version:  2.19 for Windows
Copyright (C) 2014 Jonathan Weaver

PPMScope is a do-it-yourself oscilloscope with an open source design.  The
intent is that the project can be constructed by an electronics hobbiest using
the instructions included.  The design is a compromise between features and
cost.  The bandwidth is lower than a commercial scope, so it's use is limited
to signals of 500 kHz and below.  It's sample buffer is also smaller than
a commercial scope, however sufficient for most oscilloscope functions.

This is a version based on the PIC16F877A microcontroller running with a 20MHz 
clock.  The maximum sampling rate is 1 MHz with a 5 Mhz equivalent sampling
mode.  Currently, the only computer interface supported is the serial port 
and the parallel port.  I have plans to support USB in the future.

Good luck on the construction and I hope you enjoy your oscilloscope.  I am
happy to answer any questions or provide technical support for this design.

See help file, ppmscope.chm, for details on the construction, calibration, 
operation, and software use for the oscilloscope.

Installation of INPOUT to communicate with the parallel port
===============================================================================

This software uses third party software to communicate to the parallel port.  
Inpout is a DLL written originally by Logix4U.net and later adapted for use on
Windows 7 and 64 bit versions of XP and Vista by Phillip Gibbons 
(Phil@highrez.co.uk).  It can be downloaded at 
http://www.highrez.co.uk/downloads/inpout32/

I have included the software in the folder InpOutBinaries_1500

To install the parallel port driver under Windows 7 or Vista, either 

(1) Run PPMScope.exe with administrator privilages the first time it is used, 
    to allow PPMScope to automatically install the driver, or

(2) Run the executable InstallDriver.exe

FOLDER CONTENTS:
===============================================================================

Datasheets -
The manufacturer Datasheets for integrated circuits used.

PCsource -
The source files for the PC, written in C and compiled using dev-cpp v.4.9.9.2
(www.bloodshed.net) or Code::Blocks (www.codeblocks.org).

PICasm -
The PIC assembly source files.

PIChex -
The compiled hex file for the PIC16F877 or PIC16F877A microcontroller.  The 
file was compiled using MPLAB IDE v.8.85 (www.microchip.com).

Schematics -
The schematics for the Oscilloscope in PDF format and TINYCAD 
(tinycad.sourceforge.net) format.

PCB -
The printed circuit board layouts in PDF format and FreePCB 
(www.freepcb.com) format.

Spice - 
LTSpiceIV (http://www.linear.com/designtools/software/#LTspice) model for the
analog portions of the circuit.

REVISION HISTORY:
===============================================================================

Version 2.19 for Windows
-------------------------------------------------------------------------------

See help file for details on the software.


LICENSE AND COPYRIGHT NOTICE FOR SOFTWARE AND FIRMWARE:
===============================================================================

Copyright (C) 2014 Jonathan Weaver

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.


HARDWARE DESIGN LICENSE:
===============================================================================

Copyright (C) 2014 Jonathan Weaver

The hardware design is licensed under the (cc) Creative Commons 
Attribution-ShareAlike 3.0 Unported (CC BY-SA 3.0) license.  

You are free:

 to Share — to copy, distribute and transmit the work 
 
 to Remix — to adapt the work 

 to make commercial use of the work 

Under the following conditions:

 Attribution — You must attribute the work in the manner specified by the 
   author or licensor (but not in any way that suggests that they endorse 
   you or your use of the work). 

 Share Alike — If you alter, transform, or build upon this work, you may 
   distribute the resulting work only under the same or similar license to this
   one. 

With the understanding that: 

 Waiver— Any of the above conditions can be waived if you get permission from 
   the copyright holder. 

 Public Domain— Where the work or any of its elements is in the public domain 
   under applicable law, that status is in no way affected by the license. 

Other Rights— In no way are any of the following rights affected by the 
license:

 * Your fair dealing or fair use rights, or other applicable copyright 
   exceptions and limitations; 

 * The author's moral rights; 

 * Rights other persons may have either in the work itself or in how the work 
   is used, such as publicity or privacy rights. 

See the Creative Commons License for more details (cc-by-sa-30.txt or 
http://creativecommons.org/licenses/by-sa/3.0/).
