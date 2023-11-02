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

#include <windows.h>
#include "parallel.h"

int portAddress[] = {LPT1ADR, LPT2ADR, LPT3ADR, 0};
/* short controlport[2]; */
HINSTANCE hPortLib;

typedef int _stdcall (*inpfuncPtr)(int portaddr);
typedef void _stdcall (*oupfuncPtr)(int portaddr, short datum);

inpfuncPtr inp32;
oupfuncPtr oup32;

//Opens the parallel port library and sets up to use parallel ports
//return: 0 on fail, 1 on success
int parallelPortOpen()
{
    /* Load the library */
    hPortLib = LoadLibrary("inpout32.dll");
    //hPortLib = LoadLibrary("inpoutx64.dll");
    if (hPortLib == NULL) {
        return 0;
    }
    inp32 = (inpfuncPtr) GetProcAddress(hPortLib, "Inp32");
    if (inp32 == NULL) {
        return 0;
    }
    oup32 = (oupfuncPtr) GetProcAddress(hPortLib, "Out32");
    if (oup32 == NULL) {
        return 0;
    }
/*    controlport[0] = 1 << 2;
    controlport[1] = 1 << 2;
    controlport[2] = 1 << 2; */
    return 1;
}

//Return the address based on the port number
//pt: the port number (LPT1=0, LPT2=1, LPT3=2)
//return: the address of the port number
int portAdr(short pt)
{
    return portAddress[pt];
}

//Set the address based on the port number
//pt: the port number (LPT1=0, LPT2=1, LPT3=2, LPTCUSTOM=3)
//ptAdr: the address of the port number
//returns: 1
short setPortAdr(short pt, int ptAdr)
{
      portAddress[pt] = ptAdr;
      return 1;
}

//Return the byte of the port number and byte
//pt: the port number (LPT1=0, LPT2=1, LPT3=2)
//portByte: the port byte (DATAPORT=0, STATUSPORT=1, CONTROLPORT=2)
//return: value of the byte at the port byte
short getByte(short pt, short portByte)
{
    return (inp32)((int) (portAddress[pt] + portByte));
}

//Set the byte of the port number and byte
//pt: the port number (LPT1=0, LPT2=1, LPT3=2)
//portByte: the port byte (DATAPORT=0, STATUSPORT=1, CONTROLPORT=2)
//value: value to set byte to
int setByte(short pt, short portByte, short value)
{
    (oup32)(portAddress[pt] + portByte, value);
    return 0;
}

//Return the bit of the port number and byte
//pt: the port number (LPT1=0, LPT2=1, LPT3=2)
//portByte: the port byte (DATAPORT=0, STATUSPORT=1, CONTROLPORT=2)
//bitNo: the bit whose value to check
//return: 0 if bit is clear, 1 if bit is set
short getBit(short pt, short portByte, char bitNo)
{
    if(((inp32)(portAddress[pt] + portByte)) & (1 << bitNo))
        return 1;
    return 0;
}

//Set the bit of the port number and byte
//pt: the port number (LPT1=0, LPT2=1, LPT3=2)
//portByte: the port byte (DATAPORT=0, STATUSPORT=1, CONTROLPORT=2)
//bitNo: the bit whose value to check
//oper: the operation to perform (BITRESET=0, BITSET=1, BITTOGGLE=2)
//return: 0
int setBit(short pt, short portByte, char bitNo, char oper)
{
    int addr = portAddress[pt] + portByte;
    short i;
/*    if(portByte == 2)
        i = controlport[pt];
    else */
        i = (inp32)(addr);
    switch(oper)
    {
    case BITRESET:
        i = i & (~(1 << bitNo));
        break;
    case BITSET:
        i = i | (1 << bitNo);
        break;
    case BITTOGGLE:
        i = i ^ (1 << bitNo);
        break;
    }
    (oup32)(addr, i);
/*    if(portByte == 2)
        controlport[pt] = i; */
    return 0;
}

//Close the parallel port library
int parallelPortClose()
{
     if(!(hPortLib == NULL))     FreeLibrary(hPortLib);
}

//Defines a map from a physical pin (25 pin connector) to a bit on the port
//pinNo: pin to map (1 thru 17)
//*portByte: Recieve the portByte (offset from base address DATAPORT, STATUSPORT,
//    or CONTROLPORT)
//*bitNo:  pointer to a char to recieve the bit in the portbyte
//*setVal:  the bit state corresponding to a +5 voltage of high Z output/input on the pin
//*resetVal:  the bit state corresponding to a 0 voltage output/input on the pin
//return: 1 if successful, 0 if not
int pinMap(short pinNo, short* portByte, char* bitNo, char* setVal, char* resetVal)
{
    *setVal = BITSET;     //Assumes non-inverted
    *resetVal = BITRESET;
    switch(pinNo)
    {
    case 1:
        *setVal = BITRESET;
        *resetVal = BITSET;
        *portByte = CONTROLPORT;
        *bitNo = 0;
        return 1;
    case 2:
    case 3:
    case 4:
    case 5:
    case 6:
    case 7:
    case 8:
    case 9:
        *portByte = DATAPORT;
        *bitNo = pinNo - 2;
        return 1;
    case 10:
        *portByte = STATUSPORT;
        *bitNo = 6;
        return 1;
    case 11:
        *setVal = BITRESET;
        *resetVal = BITSET;
        *portByte = STATUSPORT;
        *bitNo = 7;
        return 1;
    case 12:
        *portByte = STATUSPORT;
        *bitNo = 5;
        return 1;
    case 13:
        *portByte = STATUSPORT;
        *bitNo = 4;
        return 1;
    case 14:
        *setVal = BITRESET;
        *resetVal = BITSET;
        *portByte = CONTROLPORT;
        *bitNo = 1;
        return 1;
    case 15:
        *portByte = STATUSPORT;
        *bitNo = 3;
        return 1;
    case 16:
        *portByte = CONTROLPORT;
        *bitNo = 2;
        return 1;
    case 17:
        *setVal = BITRESET;
        *resetVal = BITSET;
        *portByte = CONTROLPORT;
        *bitNo = 3;
        return 1;
    default:
        return 0;
    }
}
