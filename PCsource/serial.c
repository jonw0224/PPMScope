/* ==============================================================================
 * Author:  Jonathan Weaver, jonw0224@aim.com
 * E-mail Contact: jonw0224@aim.com
 * Description:  Serial interface
 * Version: 1.1
 * Date: 6/13/2012
 * Filename:  serial.c
 *
 * Versions History:
 *                    6/3/2010 -  Created file
 *       1.1          6/13/2012 - Modified to correct bugs.
 *       1.2          3/8/2013 - Added setPortRTS, setPortDTR
 *
 * Copyright (C) 2010-2012 Jonathan Weaver
 *
 * This file is free software: you can redistribute it and/or modify
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

#include <stdio.h>
#include <stdlib.h>
#include <windows.h>

   DCB dcb;                                  /* Communications object */
   HANDLE hComm;                             /* Port handle */

int serialPortClose()
{
    return CloseHandle(hComm);
}

/* Initializes and opens the serial port with all timeouts at 1 millisecond
 * portName: the name of the comm port to open (e.g. "COM1")
 * configString: configuration string for the port including baud rate, etc. (e.g. "baud=57600 parity=N data=8 stop=1")
 * returns:  1 if successful, -1 if port failed to open, -2 if failed to build DCM, -3 if failed to apply DCM to serial port, -4 if failed to set timeouts.
 */
int serialPortOpen(char portName[], char configStr[])
{
   /* Create the file handle for the port */
   hComm = CreateFile(portName,
                    GENERIC_READ | GENERIC_WRITE,
                    0,
                    0,
                    OPEN_EXISTING,
                    0,
                    0);
   if (hComm == INVALID_HANDLE_VALUE)
      return -1;

   /* Configure the serial port */
   FillMemory(&dcb, sizeof(dcb), 0);
   dcb.DCBlength = sizeof(dcb);
   if (!BuildCommDCB(configStr, &dcb))
      return -2;

   if(!SetCommState(hComm, &dcb))
      return -3;

   /* Set the port timeouts */
   COMMTIMEOUTS timeouts;

   timeouts.ReadIntervalTimeout = 1;
   timeouts.ReadTotalTimeoutMultiplier = 1;
   timeouts.ReadTotalTimeoutConstant = 1;
   timeouts.WriteTotalTimeoutMultiplier = 1;
   timeouts.WriteTotalTimeoutConstant = 1;

   if (!SetCommTimeouts(hComm, &timeouts))
      return -4;

   return 1;
}

/* Sets the RTS signal on the comm port
 * rts: 1 to set RTS, 0 to clear RTS
 * returns: nonzero if successful, 0 if unsuccessful */
int setPortRTS(int rts)
{
    if(rts)
        return EscapeCommFunction(hComm, SETRTS);
    else
        return EscapeCommFunction(hComm, CLRRTS);
}

/* Sets the DTR signal on the comm port
 * dtr: 1 to set DTR, 0 to clear DTR
 * returns: nonzero is successful, 0 if unsuccessful */
int setPortDTR(int dtr)
{
    if(dtr)
        return EscapeCommFunction(hComm, SETDTR);
    else
        return EscapeCommFunction(hComm, CLRDTR);
}

/* Sets the port timeouts.
 * rdInterval: the timeout for each byte read in milliseconds
 * rdTotalMult: the multiplier for each byte read
 * rdTotalCosnt: an additional timeout to allow at the end of a recieve in milliseconds
 * wrTotalMult: the multiplier for each byte write
 * wrTotalConst: the additional timeout to allow at the end of transmit in milliseconds
 * returns: 1 if successful, 0 if unsuccessful */
int setPortTimeouts(int rdInterval, int rdTotalMult, int rdTotalConst, int wrTotalMult, int wrTotalConst)
{
    /* Set the port timeouts */
    COMMTIMEOUTS timeouts;

    timeouts.ReadIntervalTimeout = rdInterval;
    timeouts.ReadTotalTimeoutMultiplier = rdTotalMult;
    timeouts.ReadTotalTimeoutConstant = rdTotalConst;
    timeouts.WriteTotalTimeoutMultiplier = wrTotalMult;
    timeouts.WriteTotalTimeoutConstant = wrTotalConst;

    if (!SetCommTimeouts(hComm, &timeouts))
       return 0;
    return 1;
}

/* Transmits a string over the serial port
 * strToWrite: the string to transmit
 * noOfBytesToWrite: the number of bytes of the string to transmit
 * returns: 0 if failed, number of bytes written if successful
 */
int serialTXString(char strToWrite[], int noOfBytesToWrite)
{
   int noOfBytesWritten;

   if(!(WriteFile(hComm, strToWrite, noOfBytesToWrite, (PDWORD) &noOfBytesWritten, NULL)))
        return 0;

   return noOfBytesWritten;
}

/* Transmits a character over the serial port
 * ch: the character to transmit
 * returns: 0 if failed, number of bytes written if successful
 */
int serialTXChar(char ch)
{
   int noOfBytesWritten;

   if(!(WriteFile(hComm, &ch, 1, (PDWORD) &noOfBytesWritten, NULL)))
        return 0;

   return noOfBytesWritten;
}

/* Recieves a string over the serial port
 * strToRead: a buffer for the string to recieve
 * noOfBytesToRead: the number of bytes of the string to recieve
 * returns: 0 if failed, number of bytes read if successful
 */
int serialRXString(char strToRead[], int noOfBytesToRead)
{
   int noOfBytesRead;

   if(!(ReadFile(hComm, strToRead, noOfBytesToRead, (PDWORD) &noOfBytesRead, NULL)))
       return 0;
   return noOfBytesRead;
}

/* Recieves a character over the serial port
 * ch: a character to read
 * returns: 0 if failed, number of bytes read if successful
 */
int serialRXChar(char* ch)
{
   DWORD noOfBytesRead;
   char returnVal;

   noOfBytesRead = 0;

   returnVal = ReadFile(hComm, ch, 1, &noOfBytesRead, NULL);

   return noOfBytesRead;
}
