[Make]
file=scrmenu.html
directory=<!--#main.dat:ppmhelpdir#-->
template=main.tpl
default=PPMHelpIndex.mk

[title]
Screen Menu and Identification

[file]
scrmenu.html

[description]
The main menu and screen identification for the PPMScope software.

[content]
<h1>Main Menu Index</h1>

<p><b>File</b></p>
<ul>
	<li>Save Waveform - Save waveform in a comma delimited file
	<li>Save Settings - Save settings in a configuration file
	<li>Open Settings - Open settings from a configuration file
	<li>Exit - Close the program
</ul>

<p><b>Configure</b></p>
<ul>
	<li>Hardware - Configure hardware and basic pin test (see <a href="test.html#digital">Testing</a>)
	<li>Hardware Test - More extensive communication troubleshooting - Not yet implemented
	<li>Calibrate - Calibrate Voltage per Bit of D/A conversion - Not yet implemented
	<li>Sampling Options -> Interlaced Channels - Not yet implemented on menu (use Oscilloscope Control Panel)
	<li>Sampling Options -> Time Equivalent - Not yet implemented
	<li>Trigger Options -> Positive Slope - Trigger on a low to high crossing of the trigger level
	<li>Trigger Options -> Negative Slope - Trigger on a high to low crossing of the trigger level
	<li>Trigger Options -> Trigger Off - Sample without regard to trigger level
</ul>

<p><b>Waveform</b></p>
<ul>
	<li>Reconstruction -> Triangle - Draw the waveform assuming reconstruction using triangular pulses.  Effectively, 		this draws the waveform by drawing a line between each sample point.  This is the best general mode 		of waveform reconstruction.
	<li>Reconstruction -> Square - Draw the waveform assuming reconstruction using square pulses.  Effectively, 		this draws the waveform in a sample and hold fashion.  This mode quickly reminds the observer of the
		digital nature of the data displayed.
	<li>Reconstruction - > Point - Draw only the sample points.  Just the facts.
	<li>Reconstruction -> Sinc - Draw the waveform assuming reconstruction using sinc function pulses.  Effectively,
		this draws the waveform in as a lowest frequency representation.  You may observe some extra 			oscillations in waveforms with sharp corners, etc.  Sinc reconstruction is the most CPU intensive method 		but also seems to yield the most accurate representation of the frequency spectrum plot.
	<li>Volt-time - Display the oscilloscope screen in a time versus voltage mode.
	<li>X-Y Mode - Display the oscilloscope screen in a Channel A versus Channel B mode.
	<li>Spectrum Linear - Display the frequency magnitude screen with a linear voltage scale.
	<li>Spectrum Log - Display the frequency magnitude screen with a logarithmic voltage scale.
</ul>

<p><b>Help</b></p>
<ul>
	<li>Help Menu - Display the help window.
	<li>About - Display the about dialog box.
</ul>
