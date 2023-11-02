/* ==============================================================================
 * Author:  Jonathan Weaver, jonw0224@aim.com
 * E-mail Contact: jonw0224@aim.com
 * Description:  Serial interface to the oscilloscope
 * Version: 1.0
 * Date: 6/3/2010
 * Filename:  serial.h
 *
 * Versions History:
 *                    6/3/2010 -  Created file
 *
 * Copyright (C) 2010 Jonathan Weaver
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

/* Closes the serial port */
int serialPortClose();

/* Initializes and opens the serial port
 * portName: the name of the comm port to open (e.g. "COM1")
 * configString: configuration string for the port including baud rate, etc. (e.g. "57600,n,8,1")
 * returns:  1 if successful, -1 if port failed to open, -2 if failed to build DCM, -3 if failed to apply DCM to serial port, -4 if failed to set timeouts.
 */
int serialPortOpen(char portName[], char configStr[]);

/* Sets the port timeouts.
 * rdInterval: the timeout for each byte read in milliseconds
 * rdTotalMult: the multiplier for each byte read
 * rdTotalCosnt: an additional timeout to allow at the end of a recieve in milliseconds
 * wrTotalMult: the multiplier for each byte write
 * wrTotalConst: the additional timeout to allow at the end of transmit in milliseconds
 * returns: 1 if successful, 0 if unsuccessful */
int setPortTimeouts(int rdInterval, int rdTotalMult, int rdTotalConst, int wrTotalMult, int wrTotalConst);

/* Transmits a string over the serial port
 * strToWrite: the string to transmit
 * noOfBytesToWrite: the number of bytes of the string to transmit
 * returns: 0 if failed, number of bytes written if successful
 */
int serialTXString(char strToWrite[], int noOfBytesToWrite);

/* Transmits a character over the serial port
 * ch: the character to transmit
 * returns: 0 if failed, number of bytes written if successful
 */
int serialTXChar(char ch);

/* Recieves a string over the serial port
 * strToRead: a buffer for the string to recieve
 * noOfBytesToRead: the number of bytes of the string to recieve
 * returns: 0 if failed, number of bytes read if successful
 */
int serialRXString(char strToRead[], int noOfBytesToRead);

/* Recieves a character over the serial port
 * ch: a character to read
 * returns: 0 if failed, number of bytes read if successful
 */
int serialRXChar(char* ch);
