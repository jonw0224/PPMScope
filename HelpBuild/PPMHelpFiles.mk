[Make]
file=files.html
directory=<!--#main.dat:ppmhelpdir#-->
template=main.tpl
default=PPMHelpIndex.mk

[title]
Waveform and Settings Files

[description]
Saving waveforms and settings.  PPMScope online help.

[file]
PPMHelp/files.html

[content]
<h1>Waveform and Settings Files</h1>

<h1>Saving Waveforms</h1>

<p>Waveforms can be saved using the program menu or toolbar.  The sample data and the frequency data are saved to a CSV file for use with a spreadsheet program.</p>

<a name="settings"></a>
<h1>Settings Files</h1>

<p>Settings include the sample mode, display modes, waveform settings, and reconstruction settings for the oscilloscope program.  Settings files are useful when the same experiment is repeated a number of times or over an extended period.</p>

<p>Settings can be opened and saved using the program menu or toolbar.  The settings file is an ASCII text file and should be fairly readable with the exception of the following fields used by the oscilloscope firmware directly:</p>

<ul>
	<li>CONFIGLOC1 - 8 bit value
		<ul>
			<li>Bit 7 - 1 for trigger positive slope, 0 for trigger negative slope
			<li>Bit 6 - 1 for trigger enabled, 0 for trigger disabled
			<li>Bit 5 - Clock Freq bit (always 1 for 20 Mhz)
			<li>Bit 4 - Channel bit (always 0 for Channel 1)
			<li>Bits 3 thru 0 - Sample mode
			<ul>
				<li>0 -> 1 Mhz Normal mode
				<li>1 -> 833 kHz Normal mode
				<li>2 -> 625 kHz Normal mode
				<li>3 -> 417 kHz Normal mode
				<li>4 -> 250 kHz Normal mode
				<li>5 -> Variable rate Normal mode
				<li>11 -> Variable rate Interlaced mode
			</ul>
		</ul>
	<li>TRIGGERDELAY1, TRIGGERDELAY2, TRIGGERDELAY3 - three 8 bit numbers that set the trigger delay as 
	(13 + 3*TRIGGERDELAY3 + 770*TRIGGERDELAY2 + 197122*TRIGGERDELAY1) * 4 / 20e6 seconds
	<li>SAMPLERATE1, SAMPLERATE2 - two 8 bit numbers that set the sample rate for the variable rate modes as 5e6 / (19 + 7 * (SAMPLERATE1*256 +  SAMPLERATE2) + 3 * SAMPLERATE1) Hz for Normal mode and as 5e6 / (26 + 7 * (SAMPLERATE1 * 256 + SAMPLERATE2) + 3 * SAMPLERATE1) Hz for Interlaced mode
</ul>
