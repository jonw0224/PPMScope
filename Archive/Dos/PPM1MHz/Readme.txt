PPMScope (PC-PIC-MaximADC Scope)
===============================================================================

Date:  1/23/2006
Author:  Jonathan Weaver, jonw0224@netscape.net, http:\\jonw0224.tripod.com
Version:  0.101 Alpha for DOS
Copyright (C) 2006 Jonathan Weaver

PIC16F877A version with 20MHz clock (1 MHz maximum sample rate) to
interface with the parallel port (LPT1).

This version of PPMScope is an incomplete version.  It is not meant to be a
final product, but only to illustrate some of the principle of building a
PC platform oscilloscope.  The circuit schematic is fairly stable at this
point.

There is a more final version of PPMScope currently being developed.  It will
support repetitive waveform sampling up to 5 MHz and be able to sample 
repetitive waveforms up to 2 MHz.

I do not anticipate the circuit schematic will change much in the next
generation, however, I have MUCH work to do developing the software and 
firmware.

In the end, I want to have a DOS version of the software and a Java 
cross-platform version.  The reason for a DOS version is simplicity and speed.
The DOS version can be used on a slower PC without major performance hits.
I have not begun development of the Java software.


FOLDER CONTENTS:
===============================================================================

Datasheets -
The manufacturer Datasheets for integrated circuits used.

PCbin -
The compiled computer program to interface with the PPMScope.  The program
was compiled with PowerBASIC v.3.2 Compiler for DOS (www.powerbasic.com).
The program is a graphics based DOS interface.  Oscillo.exe is the compiled
program which tries to establish communication with the PPMScope hardware
connect to LPT1.  OscDemo.exe is the compiled program which simulates the 
hardware and is simply a demo.

PCsource -
The PowerBASIC source files.

PICasm -
The PIC assembly source files.

PIChex -
The compiled hex file for the PIC16F877A microcontroller.  The file was
compiled using MPLAB IDE v.6.2 (www.microchip.com).

Schematics -
The schematics for the Oscilloscope in PDF format and TINYCAD format.

REVISION HISTORY:
===============================================================================

Version 0.102 alpha for DOS - Released
-------------------------------------------------------------------------------

New Features:

Implementation of interrupt based trigger to reduce the trigger jitter.  New 
feature added on 3/28/2006.

Lengthening of the channel buffer from 64 samples to 256 samples for all sample
modes.  New feature added on 3/28/2006 thru 4/12/2006.

Bug fixes:

A correction to the schematic.  RE1 on the PIC was shown wired to RB1 instead
of RB2, which is correct.  4/12/2006.

Version 0.101 alpha for DOS - Released January 23, 2006
-------------------------------------------------------------------------------

A correction to the schematic.

Version 0.1 alpha for DOS - Released January 14, 2006
-------------------------------------------------------------------------------

Initial release.  Generally, the code was changed to work with a PIC16F877A and 
sample at 1 Mhz.


LICENSE AND COPYRIGHT NOTICE FOR SOFTWARE:
===============================================================================

Copyright (C) 2006 Jonathan Weaver

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details (gpl.txt).

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

HARDWARE DESIGN TERMS AND CONDITIONS:
===============================================================================

Hardware designs (including schematics, instructions, and techniques) are
presented in hopes that they will be useful and under the following
conditions:

By downloading or using the hardware design, you accept the conditions
below. If you do not agree, you should not download or use the hardware
design.

You are given permission to use the hardware design without royalty.

You may redistribute the hardware designs provided that you keep the author
and copyright information intact and that you distribute the hardware
design with an unmodified copy of these terms and conditions.

You may modify the hardware designs, but a prominent notice including the
author, the date, and a brief description of the modification should
accompany any modification. You may not remove references to these terms
and conditions or any copyright notices.

If you distribute a device created using the hardware design, you must
distribute the hardware design under these terms and conditions.

The copyright holders are under no obligation to provide maintenance,
updates, or technical support for the hardware design.

BECAUSE THE HARDWARE DESIGN IS LICENSED FREE OF CHARGE, THERE IS NO
WARRANTY FOR THE DESIGN, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE DESIGN "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED
OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO
THE QUALITY AND PERFORMANCE OF THE DESIGN IS WITH YOU. SHOULD THE DESIGN
PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR OR
CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL
ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE
THE DESIGN AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OR INABILITY TO USE THE DESIGN (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THIS MATERIAL TO OPERATE WITH ANY OTHER SYSTEMS OR
SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

You agree not to download or use the hardware designs or related software
in any state or country that does not allow the exclusion or limitation of
liability for consequential or incidental damages.

The ideas for the hardware licensing are taken from the GNU General Pubic
license for software. The agreement not to download in any state or country
that does not allow exclusion or limitation of liability was copied from
Metachip (Australia) Pty. Ltd. (Bitscope).
