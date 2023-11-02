[Make]
file=test.html
directory=<!--#main.dat:ppmhelpdir#-->
template=main.tpl
default=PPMHelpIndex.mk

[title]
Testing the Oscilloscope

[description]
Testing the PPMScope DIY Oscilloscope

[file]
test.html

[content]
<h1>Testing the PPMScope</h1>

<ul>
	<li><a href="test.html#analog">Testing the analog signal conditioning stage</a>
	<li><a href="test.html#digital">Testing the digital interface and connecting PPMScope to the PC</a>
	<li><a href="test.html#signal">Testing with a signal generator</a>
	<li><a href="test.html#trigger">Testing trigger modes</a>
	<li><a href="test.html#indicate">Testing gains and coupling indication</a>
</ul>

<a name="analog"></a>
<h1>Testing the analog signal conditioning stage</h1>

	<p>First, wire the circuit below, and connect the center of the potentiometer to both Channel 1 and
		Channel 2 inputs (labeled Ch1_In and Ch2_In on the schematic) on the oscilloscope.  You will need a 		Voltmeter to measure the DC voltage applied on the inputs as well as in various positions in the analog 		signal conditioning stage.</p>

<center><img border=0 alt="PPMScope Testing" src="testa.jpg"></center>

		<p>Make sure the coupling switch is in the <i>AC</i> position and the gain switch is in the <i>1X</i> 		position.  Now, sweep the inputs from +12 Volts to -12 Volts using the potentiometer.  Pins 1 and 7 on U3 		should follow the inputs up to -10 Volts to +10 Volts.   Pins 1 and 7 on U4 should remain at 0 Volts 			(perhaps drifting off zero as you turn the potentiometer).  Pins 1 and 7 on U5 should be have around 2.5 		Volts on them.  If they do not, adjust the position of R24 until the voltage is 2.5 Volts.</p>

		<p>Next, set the coupling switch in the <i>DC</i> position and leave the gain switch in the <i>1X</i> 		position.  Again, sweep the inputs from +12 Volts to -12 Volts using the potentiometer.				This time, Pins 1 and 7 on U4 should follow the negative of the input voltage.  Pins 1 and 7 on U5 should 		sweep from +5 to 0 Volts.</p>

		<p>Next, sweep the potentiometer so that the Channel 1 and Channel 2 inputs are at 1 Volt.  Pins 1 and 7 		on U4 should read -1 Volt.  Set the gain switch to the <i>2X</i> position.  Pins 1 and 7 on U4 should read
		-2 Volts.  Set the gain switch to the <i>5X</i> position.  Pins 1 and 7 on U4 should read -5 Volts.</p>

<a name="digital"></a>
<h1>Testing the digital interface and connecting with the PC</h1>

<p>Connect the PPMScope to the PC.  Start the PPMScope program, and on the main menu click <i>Configure</i> and then <i>Hardware</i>.  The window pictured below will show up.</p>

<center><img alt="" border=0 src="parallel_conn_1.jpg" width=241 height=353 border=0></center>

<h3>Parallel Port Setup</h3>

<ol><li>From the Configuration->Hardware Dialog make sure:
<ul>
<li>You have selected the correct device (PPMScope or DSOScope) depending on the firmware used.
</li><li>You have selected the Parallel Port Type
</li><li>You have selected the correct port number (e.g. LPT Port 1, etc)
</li><li>You have the IO Delay set at 500 (you can experiment with lower values if you'd like.  I've found that I can set this value to 0 and everything still works properly).
</li></ul>
</li>
</ol>

<p>If you are using a Parallel Port PCI Card that has nonstandard addresses for the LPT Port:
</p>

<ol><li>You can find the Parallel Port Address using Device Manager (right click on the printer port, select properties, resources, and note the starting resource address).</li><br><br>

<center><img border=0 src="parallel_conn_2.jpg" width=550 height=399 border=0><br>
<small>Device Manager, right click, select properties...</small>
<br>
<br>
<img border=0 src="parallel_conn_3.jpg" width=422 height=461 border=0><br>
<small>Resource tab, note the port address (circled above)</small>
<br><br></center>

<li>From the Configuration->Hardware Dialog, you can select Custom LPT Port and then type the address in manually as a HEX number (e.g. 0x0378 is the default address for LPT1).</li><br><br>

<center><img border=0 src="parallel_conn_4.jpg" width=241 height=353 border=0><br>
<small>Custom LPT setting with device address of 0xc400</small></center>

</ol>

<p>To test the Parallel Port connections, click the <i>Pin Test Enabled</i> checkbox.  With the device installed, toggle the <i>Data</i> signal high and low.  You should see a corresponding high and low in the state column for the <i>Data</i> signal and the <i>Data In</i> signal.  Also, toggling the <i>Clock</i> signal should produce a corresponding high and low in the state column.  If you get bored, you should observe a corresponding voltage transition on the microcontroller pins using a Voltmeter.  Close the hardware dialog by clicking <i>OK</i> and the hardware will be configured.</p>

<h3>Serial Port Setup</h3>

<ol><li>From the Configuration->Hardware Dialog make sure:
<ul><li>You have selected the correct device (PPMScope or DSOScope) depending on the firmware used.
</li><li>You have selected the Serial Port Type
</li><li>You have selected the correct port number (e.g. COM4 etc)
</li><li>You have the RX Timeout set at 10 ms (you can experiment with lower values if you'd like).
</li></ul>
</li>
</ol>
<br>

<center><img border=0 alt="Serial setup" src="serial_conn_1.jpg" width=241 height=353 border=0><br>
<small>Serial Port Setup using COM5</small></center>

<h3>USB Communication Setup</h3>

<ol><li>Set up for serial port operation.  From the Configuration->Hardware Dialog make sure:
<ul><li>You have selected the correct device (PPMScope or DSOScope) depending on the firmware used.
</li><li>You have selected the Serial Port Type
</li><li>You have selected the correct port number (e.g. COM4 etc).  You can get the correct port number from the Device Manager.
</li><li>You have the RX Timeout set at 10 ms
</li>
</ul>
	
</li><li>To increase the waveform update rate even more, you need to change a driver setting.  Go to the Device Manager and select the Virtual Comm Port for the device.  Change an advanced setting (right click on the comm port, select properties, then the Port Settings Tab, click advanced) called the Latency Timer to 1 mS.  You may need to reboot the PC.  Power down and then power up the oscilloscope.  Restart the oscilloscope software and reconnect.  Now, you can go back to the Configuration->Hardware Dialog, you can experiment with lower values for the RX Timeout.
</li></ol>
<br>

<center><img border=0 alt="PPMScope USB Setup" src="usb_conn_1.jpg" width=550 height=402 border=0><br>
<small>Device Manager, right click on the virtual comm port, properties...</small><br><br>
<img border=0 alt="PPMScope USB Setup" src="usb_conn_2.jpg" width=422 height=461 border=0><br>
<small>Port Settings, advanced...</small><br><br>
<img border=0 alt="PPMScope USB Setup" src="usb_conn_3.jpg" width=550 height=389 border=0><br>
<small>Change Latency Timer to 1 mS</small></center><br>

<h3>Connection Testing</h3>

<p>From the main menu, select <i>Configure</i> and then <i>Hardware Test</i>.  The Hardware Test Dialog will send a test configuration message to the oscilloscope and give you a transcript of the communications for troubleshooting.</p>

<h3>Capturing your first waveform</h3>

<p>Hold your breath.  Make sure the trigger is turned off.  Press the play button on the toolbar.  If the program is communicating properly, the circle in the lower left corner should turn green and the screen should display the voltage at the input.  If you've left the inputs connected to the potentiometer, you should be able to see the voltage level at the input change as you turn it.</p>

<a name="signal"></a>
<h1>Testing with a signal generator</h1>

<p>Now for the fun part!  You can test the oscilloscope with a function generator or by constructing a 555 timer circuit or other oscillator circuit.  My personal favorite oscillator generates both a triangle and square wave.  The schematic is below:</p>

<img border=0 alt="Test circuit, oscillator" src="testc.jpg" width=439 height=348>

<a name="trigger"></a>
<h1>Testing trigger modes</h1>

<p>Connect a triangle waveform to Channel 1.  Place the trigger mode into a positive slope trigger.  As you sweep the trigger level, you should see a corresponding change in the phase shift of the triangle waveform.  Similarly, as you adjust the trigger delay and trigger slope, you should see a corresponding change in the phase shift of the triangle waveform.</p>

<a name="indicate"></a>
<h1>Testing gains and coupling indication</h1>

<p>You should see the position of the gain switches and the coupling updated on the screen at the bottom of the channel information.</p>
