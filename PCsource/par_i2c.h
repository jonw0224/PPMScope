/* ==============================================================================
 * Author:  Jonathan Weaver, jonw0224@aim.com
 * E-mail Contact: jonw0224@aim.com
 * Description:  Simulate I2C protocol on a parallel port.
 * Version: 1.01
 * Date: 8/28/2006
 * Filename:  par_i2c.c, par_i2c.h
 *
 * Versions History:  
 *      1.01 - 8/26/2006 - Created file
 *      1.01 - 8/28/2006 - Added comments
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

/* Use the parallel port wrapper to simulate I2C protocol */
#include "parallel.h"

/* Global variable to control timing within waitTime */
int wTime;

/* Parallel port, pin bytes, pin bits, and pin logic */
short lptPort;
char clk, sda, sdain;
short clkControl, sdaControl, sdainControl;
char sdaSet, sdaReset, clkSet, clkReset, sdainSet, sdainReset;

/* Releases the bus by putting sda and clk high */
int releaseBus();

/* Send a start signal to the slave device */
int sendStart();

/* Send a stop signal to the slave device */
int sendStop();

/* Send a zero signal to the slave device */
int sendZero();

/* Send a one signal to the slave device */
int sendOne();

/* Send a byte to the slave device
 * theByte:  a byte to send
 * returns: 1 if the slave device acknowledges, 0 if the slave device does not
 */
short sendByte(char theByte);

/* Recieve a byte from the slave device
 * ack: nonzero indicates send acknowledge, zero indicates don't send acknowledge
 * returns: the byte recieved
 */
short recieveByte(char ack);

/* Waits a number of ticks indicated by wTime to control timing.
 * Note: timing is processor dependent, timing is controlled by a for loop
 */
int waitTime();
