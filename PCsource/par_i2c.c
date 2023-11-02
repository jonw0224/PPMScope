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
 *      1.01 - 8/28/2006 - Edited some functions for timing and added comments
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

#include "par_i2c.h"

/* Releases the bus by putting sda and clk high */
int releaseBus()
{
    setBit(lptPort, sdaControl, sda, sdaSet);
    setBit(lptPort, clkControl, clk, clkSet);    
    waitTime();
    return 0;
}

/* Send a start signal to the slave device */
int sendStart()
{
    releaseBus();
    setBit(lptPort, sdaControl, sda, sdaReset);
    waitTime();
    setBit(lptPort, clkControl, clk, clkReset);
    waitTime();
    return 0;
}

/* Send a stop signal to the slave device */
int sendStop()
{
    setBit(lptPort, clkControl, clk, clkReset);
    waitTime();
    setBit(lptPort, sdaControl, sda, sdaReset);
    waitTime();
    setBit(lptPort, clkControl, clk, clkSet);
    waitTime();
    releaseBus();
    return 0;
}

/* Send a zero signal to the slave device */
int sendZero()
{
    setBit(lptPort, sdaControl, sda, sdaReset);
    waitTime();
    setBit(lptPort, clkControl, clk, clkSet);
    waitTime();
    setBit(lptPort, clkControl, clk, clkReset);
    waitTime();
    return 0;
}

/* Send a one signal to the slave device */
int sendOne()
{
    setBit(lptPort, sdaControl, sda, sdaSet);
    waitTime();
    setBit(lptPort, clkControl, clk, clkSet);
    waitTime();
    setBit(lptPort, clkControl, clk, clkReset);
    waitTime();
    return 0;
}

/* Send a byte to the slave device
 * theByte:  a byte to send
 * returns: 1 if the slave device acknowledges, 0 if the slave device does not
 */
short sendByte(char theByte)
{
    int i;
    for(i = 0; i < 8; i++)
    {
        if (theByte & 128)
            sendOne();
        else
            sendZero();
        theByte = theByte << 1;
    }
    releaseBus();
    i = getBit(lptPort, sdainControl, sdain);
    if(sdainSet)
        i = i ^ 1;
    setBit(lptPort, clkControl, clk, clkReset);
    return i;
}

/* Recieve a byte from the slave device
 * ack: nonzero indicates send acknowledge, zero indicates don't send acknowledge
 * returns: the byte recieved
 */
short recieveByte(char ack)
{
    short toRet = 0;
    int i;
    setBit(lptPort, sdaControl, sda, sdaSet);
    waitTime();
    setBit(lptPort, clkControl, clk, clkReset);
    waitTime();
    for(i = 0; i < 8; i++)
    {
        setBit(lptPort, clkControl, clk, clkSet);
        waitTime();
        toRet = (toRet << 1) + getBit(lptPort, sdainControl, sdain);
        setBit(lptPort, clkControl, clk, clkReset);
        waitTime();
    }
    if(sdainReset)
    {
        toRet = toRet ^ 0x00FF;
    }
    if(ack)
        setBit(lptPort, sdaControl, sda, sdaReset);
    else
        setBit(lptPort, sdaControl, sda, sdaSet);
    waitTime();
    setBit(lptPort, clkControl, clk, clkSet);
    waitTime();
    setBit(lptPort, clkControl, clk, clkReset);
    waitTime();
    return toRet;
}

/* Waits a number of ticks indicated by wTime to control timing.
 * Note: timing is processor dependent, timing is controlled by a for loop
 */
int waitTime()
{
    int i;
    for(i = 0; i < wTime; i++) ;
    return 0;
}           
        
