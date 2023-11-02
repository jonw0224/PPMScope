[Make]
file=linux.html
directory=<!--#main.dat:ppmhelpdir#-->
template=main.tpl
default=PPMHelpIndex.mk

[title]
Running PPMScope on Linux

[description]
Running PPMScope on Linux.  PPMScope online help.

[file]
linux.html

[content]
<h1>Running on Linux under Wine</h1>

<p>PPMScope can be run on Linux under Wine using the Serial port or USB port connections.  The Parallel port connection hasn't been tested.  The Linux distributions below have been tested.</p>

<a name="fedora"></a>
<h1>Fedora 19</h1>

<p>Start with a clean Fedora 19 install. Run the software update and restart as necessary. The device driver for the FT232R is included with Fedora Linux, so there is no need to install/compile a driver to use the scope with USB.</p>

<p>Setup from a terminal window:</p>

<ol>
<li>Login to the root user:<br><br>

<code>su<br>
&lt;key password&gt;</code><br><br>

<li>Install wine:<br><br>

<code>yum install wine</code><br><br>

</li>
<li>Allow wine to have low level access to the port.<br><br>

<code>setsebool -P mmap_low_allowed 1</code><br><br>

</li>
<li>Determine the USB port terminal with the scope plugged in the USB port.<br><br>

<code>dmseg | grep tty</code>

<p>This command lists the tty ports. The scope is the Ftdi device. Mine was at ttyUSB0. I'm going to assume ttyUSB0 for the rest of this e-mail.</p>

</li>
<li>Map the USB port to a COM port available to wine.<br><br>

<code>ln -s /dev/ttyUSB0 ~/.wine/dosdevices/com1<br>
ln -s /dev/ttyUSB0 /com1</code><br><br>

</li>

<li>Copy the PPMScope directory (I put it in the Home directory).</li>
</ol>

<p>To run the application:</p>

<ol>
<li>Log into root.<br><br>

<code>su<br>
&lt;key password&gt;</code><br><br>

</li>
<li> Run the program<br><br>

<code>cd PPMScope<br>
wine PPMScope.exe</code>
</li>
</ol>

<p>Initially, setup the program to talk to a DSOScope on COM1 with an RX timeout of 10 ms. Save the configuration.</p>

<p>You can setup an icon to run the program, but those instructions are beyond the scope of this help file.</p>
