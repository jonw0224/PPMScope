/* ==============================================================================
 * Author:  Jonathan Weaver, jonw0224@aim.com
 * E-mail Contact: jonw0224@aim.com
 * Description:  Parallel Port Interface Wrapper.
 * Version: 1.01
 * Date: 8/22/2006
 * Filename:  parallel.c, parallel.h
 *
 * Versions History:  
 *      1.01 - 8/22/2006 - Created file
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

//Port bytes, offset from port base address
#define DATAPORT    0
#define STATUSPORT  1
#define CONTROLPORT 2

//Operations for use with setBit
#define BITRESET    0
#define BITSET      1
#define BITTOGGLE   2

//Constants to use to refer to ports
#define LPT1        0
#define LPT2        1
#define LPT3        2
#define LPTCUSTOM   3

//Default port addresses
#define LPT1ADR     0x00000378
#define LPT2ADR     0x00000278
#define LPT3ADR     0x000003BC

//Opens the parallel port library and sets up to use parallel ports
//return: 0 on fail, 1 on success
int parallelPortOpen();

//Return the address based on the port number 
//pt: the port number (LPT1=0, LPT2=1, LPT3=2, LPTCUSTOM=3)
//return: the address of the port number
int portAdr(short pt);

//Set the address based on the port number 
//pt: the port number (LPT1=0, LPT2=1, LPT3=2, LPTCUSTOM=3)
//ptAdr: the address of the port number
//returns: 1
short setPortAdr(short pt, int ptAdr);

//Return the byte of the port number and byte
//pt: the port number (LPT1=0, LPT2=1, LPT3=2)
//portByte: the port byte (DATAPORT=0, STATUSPORT=1, CONTROLPORT=2)
//return: value of the byte at the port byte
short getByte(short pt, short portByte);

//Set the byte of the port number and byte
//pt: the port number (LPT1=0, LPT2=1, LPT3=2)
//portByte: the port byte (DATAPORT=0, STATUSPORT=1, CONTROLPORT=2)
//value: value to set byte to
int setByte(short pt, short portByte, short value);

//Return the bit of the port number and byte
//pt: the port number (LPT1=0, LPT2=1, LPT3=2)
//portByte: the port byte (DATAPORT=0, STATUSPORT=1, CONTROLPORT=2)
//bitNo: the bit whose value to check
//return: 0 if bit is clear, 1 if bit is set
short getBit(short pt, short portByte, char bitNo);

//Set the bit of the port number and byte
//pt: the port number (LPT1=0, LPT2=1, LPT3=2)
//portByte: the port byte (DATAPORT=0, STATUSPORT=1, CONTROLPORT=2)
//bitNo: the bit whose value to check
//oper: the operation to perform (BITRESET=0, BITSET=1, BITTOGGLE=2)
//return: 0 
int setBit(short pt, short portByte, char bitNo, char oper);

//Close the parallel port library
int parallelPortClose();

//Defines a map from a physical pin (25 pin connector) to a bit on the port
//pinNo: pin to map (1 thru 17)
//*portByte: Recieve the portByte (offset from base address DATAPORT, STATUSPORT, 
//    or CONTROLPORT)
//*bitNo:  pointer to a char to recieve the bit in the portbyte
//*setVal:  the bit state corresponding to a +5 voltage of high Z output/input on the pin
//*resetVal:  the bit state corresponding to a 0 voltage output/input on the pin
//return: 1 if successful, 0 if not
int pinMap(short pinNo, short* portByte, char* bitNo, char* setVal, char* resetVal);
