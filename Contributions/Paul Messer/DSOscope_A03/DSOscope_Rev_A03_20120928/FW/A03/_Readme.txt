DSOscope firmware:

April 30, 2012

The firmware located in this directory
is identical to Jonathan Weaver's
(http://jonathanweaver.net/ppmscope.html)
firmware.  The only change has been to re-target
the CPU device to the newer PIC16F887 instead of
the older PIC16F877A device he originally used.

May 21, 2012

The PIC16F887 used in the DSOscope version has
several differences in the setup for serial port
communications.  Started making those changes.

May 28, 2012

Removed all ifdef's relating to various older
hardware versions of Jonathan Weaver's.  This
code is strictly targeted for the Rev Axx
DSOscope SMT layout.
Removed all references to "i2c" and replaced
with "sp" (serial port).

June 3, 2012
Did a source file clean-up of mixed space and tab
separators to using all tabs... at least where
practical.  A few spelling corrections.
