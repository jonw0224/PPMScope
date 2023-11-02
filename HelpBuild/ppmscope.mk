[Make]
file=ppmscope.html
directory=<!--#main.dat:directory#-->
template=main.tpl

[title]
PPM Oscilloscope

[keywords]
Free Digital Oscilloscope PC Freeware Open Source PowerBasic PIC assembly

[description]
A PIC microcontroller and ADC are used to create a digital oscilloscope connected to the PC with a sample rate of 1MHz.  The schematics and source code are available as free software under the GPL.

[javascript]
<!--#index.mk:javascript#-->
<script type="text/javascript">
//<!--
var current = 0;
var cstep = 2;

var myDoc = new Array();
myDoc[0] = "subAimg"
myDoc[1] = "subBimg"
myDoc[2] = "subCimg"

var myCaption = new Array();
myCaption[0] = "Screenshot of the Oscilloscope program.  You can <a href=ppmscope.html#top#download>download</a> the program here"
myCaption[1] = "Original oscilloscope build.  A function generator was later added on a daughter board"
myCaption[2] = "View from the front.  Most of the knobs and switches are for the function generator"
myCaption[3] = "Assembly showing bottom of perfboard"
myCaption[4] = "View from the back.  I got carried away cutting the slots for the fan"
myCaption[5] = "Overall view of the oscilloscope build"
myCaption[6] = "Using the oscilloscope version 1.05 to troubleshoot version 1.20 on the breadboard"
myCaption[7] = "Build by Tiago Rocha"
myCaption[8] = "Version 1.0 PCB build by Tiago Rocha (no parallel port buffer on the right)"
myCaption[9] = "Version 1.05 PCB build by Karoly Simon (with buffer on the right)"
myCaption[10] = "Working oscilloscope screenshot by Karoly Simon"
myCaption[11] = "Build by Karoly Simon"
myCaption[12] = "Version 1.05 PCB build by Ivan Atlas"
myCaption[13] = "Key components built by Ivan Atlas"
myCaption[14] = "Front panel by Ger Van den Hoek"
myCaption[15] = "Custom layout build by Ger Van den Hoek"
myCaption[16] = "Perfboard layout build by David de Boer (<a href=<!--#main.dat:countlink#-->DaveDeBoer_Perfboard.zip>download</a>)"
myCaption[17] = "Perfboard layout from bottom by David de Boer (<a href=<!--#main.dat:countlink#-->DaveDeBoer_Perfboard.zip>download</a>)"
myCaption[18] = "Build by David de Boer (<a href=<!--#main.dat:countlink#-->DaveDeBoer_Perfboard.zip>download</a>)"

var myImg = new Array();
myImg[0] = "ppmscope1.jpg"
myImg[1] = "ppmscope2.jpg"
myImg[2] = "ppmscope3.jpg"
myImg[3] = "ppmscope4.jpg"
myImg[4] = "ppmscope5.jpg"
myImg[5] = "ppmscope6.jpg"
myImg[6] = "ppmscope7.jpg"
myImg[7] = "TiagoRocha1.jpg"
myImg[8] = "TiagoRocha2.jpg"
myImg[9] = "karolysimon2.jpg"
myImg[10] = "karolysimon5.jpg"
myImg[11] = "karolysimon7.jpg"
myImg[12] = "IvanAtlas1.jpg"
myImg[13] = "IvanAtlas2.jpg"
myImg[14] = "GerVanDenHoek1.jpg"
myImg[15] = "GerVanDenHoek2.jpg"
myImg[16] = "DavidDeBoer1.jpg"
myImg[17] = "DavidDeBoer2.jpg"
myImg[18] = "DavidDeBoer3.jpg"

var mySmImg = new Array();
mySmImg[0] = "ppmscope1sm.jpg"
mySmImg[1] = "ppmscope2sm.jpg"
mySmImg[2] = "ppmscope3sm.jpg"
mySmImg[3] = "ppmscope4sm.jpg"
mySmImg[4] = "ppmscope5sm.jpg"
mySmImg[5] = "ppmscope6sm.jpg"
mySmImg[6] = "ppmscope7sm.jpg"
mySmImg[7] = "TiagoRocha1sm.jpg"
mySmImg[8] = "TiagoRocha2sm.jpg"
mySmImg[9] = "karolysimon2sm.jpg"
mySmImg[10] = "karolysimon5sm.jpg"
mySmImg[11] = "karolysimon7sm.jpg"
mySmImg[12] = "IvanAtlas1sm.jpg"
mySmImg[13] = "IvanAtlas2sm.jpg"
mySmImg[14] = "GerVanDenHoek1sm.jpg"
mySmImg[15] = "GerVanDenHoek2sm.jpg"
mySmImg[16] = "DavidDeBoer1sm.jpg"
mySmImg[17] = "DavidDeBoer2sm.jpg"
mySmImg[18] = "DavidDeBoer3sm.jpg"

var myMOvrImg = new Array();
myMOvrImg[0] = "ppmscope1ov.jpg"
myMOvrImg[1] = "ppmscope2ov.jpg"
myMOvrImg[2] = "ppmscope3ov.jpg"
myMOvrImg[3] = "ppmscope4ov.jpg"
myMOvrImg[4] = "ppmscope5ov.jpg"
myMOvrImg[5] = "ppmscope6ov.jpg"
myMOvrImg[6] = "ppmscope7ov.jpg"
myMOvrImg[7] = "TiagoRocha1ov.jpg"
myMOvrImg[8] = "TiagoRocha2ov.jpg"
myMOvrImg[9] = "karolysimon2ov.jpg"
myMOvrImg[10] = "karolysimon5ov.jpg"
myMOvrImg[11] = "karolysimon7ov.jpg"
myMOvrImg[12] = "IvanAtlas1ov.jpg"
myMOvrImg[13] = "IvanAtlas2ov.jpg"
myMOvrImg[14] = "GerVanDenHoek1ov.jpg"
myMOvrImg[15] = "GerVanDenHoek2ov.jpg"
myMOvrImg[16] = "DavidDeBoer1ov.jpg"
myMOvrImg[17] = "DavidDeBoer2ov.jpg"
myMOvrImg[18] = "DavidDeBoer3ov.jpg"

function enterRight()
{
	document.getElementById("rimg").src="rightov.gif";
	return false;
}

function exitRight()
{
	document.getElementById("rimg").src="right.gif";
	return false;
}

function enterLeft()
{
	document.getElementById("limg").src="leftov.gif";
	return false;
}

function exitLeft()
{
	document.getElementById("limg").src="left.gif";
	return false;	
}

function moveRight()
{
	current = current + cstep;
	if(current > mySmImg.length - 3)
	{
		current = mySmImg.length - 3;
	}
	populateBar();
	return false;
}
 
function moveLeft()
{
	current = current - cstep;
	if(current < 0)
	{
		current = 0;
	}
	populateBar();
	return false;
}

function populateBar()
{
	document.getElementById(myDoc[0]).src=mySmImg[current];
	document.getElementById(myDoc[1]).src=mySmImg[current+1];
	document.getElementById(myDoc[2]).src=mySmImg[current+2];	
	return false;
}

function setMain(a)
{
	document.getElementById("mainimg").src=myImg[current+a];
	document.getElementById("caption").innerHTML=myCaption[current+a];
	return false;
}

function enterPic(a)
{
	document.getElementById(myDoc[a]).src=myMOvrImg[current+a];
	return false;
}

function exitPic(a)
{
	document.getElementById(myDoc[a]).src=mySmImg[current+a];
	return false;
}

//-->
</script>

[sidebar]
<!--#main.dat:sidebarstart#-->
<a href="ppmscope.html#top">PPMScope - DIY Oscilloscope</a>
<!--#main.dat:tb#-->
<a href="PPMHelp/index.html#top">PPMScope Online Help Index</a>
<!--#main.dat:tb#-->
<a href="electronics.html#lcmeter">LC Meter</a>
<!--#main.dat:tb#-->
<a href="picasmlib.html#top">PIC Assembly Library</a>
<!--#main.dat:tb#-->
<a href="workshop.html#top">Machining and Woodworking</a>
<!--#main.dat:tb#-->
<a href="about.html#aboutme">About Me</a>
<!--#main.dat:tb#-->
<a href="links.html#top">Links</a>
<!--#main.dat:sidebarstop#-->

[sideadd]
<font color=#73001C><center><h4>Oscilloscopes</h4>
<br>
<iframe src="http://rcm.amazon.com/e/cm?t=jonaweavdotne-20&o=1&p=8&l=as1&asins=B003MYND5A&ref=tf_til&fc1=000000&IS2=1&lt1=_blank&m=amazon&lc1=0000EE&bc1=8f8f8f&bg1=FFFFFF&f=ifr" style="width:120px;height:240px;" scrolling="no" marginwidth="0" marginheight="0" frameborder="0"></iframe>
<br>
<br>
<br>
<iframe src="http://rcm.amazon.com/e/cm?t=jonaweavdotne-20&o=1&p=8&l=as1&asins=B0007R8ZCG&ref=tf_til&fc1=000000&IS2=1&lt1=_blank&m=amazon&lc1=0000EE&bc1=8f8f8f&bg1=FFFFFF&f=ifr" style="width:120px;height:240px;" scrolling="no" marginwidth="0" marginheight="0" frameborder="0"></iframe>
<br>
<br>
<br>
<iframe src="http://rcm.amazon.com/e/cm?t=jonaweavdotne-20&o=1&p=8&l=as1&asins=B002Z34QUA&ref=tf_til&fc1=000000&IS2=1&lt1=_blank&m=amazon&lc1=0000EE&bc1=8f8f8f&bg1=FFFFFF&f=ifr" style="width:120px;height:240px;" scrolling="no" marginwidth="0" marginheight="0" frameborder="0"></iframe>
<br>
<br>
<br>
<iframe src="http://rcm.amazon.com/e/cm?lt1=_blank&bc1=8f8f8f&IS2=1&bg1=FFFFFF&fc1=000000&lc1=0000EE&t=jonaweavdotne-20&o=1&p=8&l=as1&m=amazon&f=ifr&ref=tf_til&asins=B004DE31U0" style="width:120px;height:240px;" scrolling="no" marginwidth="0" marginheight="0" frameborder="0"></iframe>
<br>
<br>
<br>
<iframe src="http://rcm.amazon.com/e/cm?lt1=_blank&bc1=8f8f8f&IS2=1&bg1=FFFFFF&fc1=000000&lc1=0000EE&t=jonaweavdotne-20&o=1&p=8&l=as1&m=amazon&f=ifr&ref=tf_til&asins=B004G2KQT8" style="width:120px;height:240px;" scrolling="no" marginwidth="0" marginheight="0" frameborder="0"></iframe>
<br>
<br>
<br>

[lastupdated]
2012 February 24

[content]
            <h3>PPM Scope for Windows <a href="ppmscope.html#download">(Download)</a></h3>
            			
            <p>PPMScope is a do-it-yourself oscilloscope design with a maximum sample rate of 1 MHz (bandwidth of 500 kHz).
				
				The hardware is based on the PIC16F877A
				                Microcontroller.  I am creating this
				                tool for my general use at home, but I thought others may benefit from
				                the software and schematics.
                The human interface to the oscilloscope is both a part of
                the box (knobs, switches, etc) and through a PC program
                written in C for Windows.</p>

				<p>The scope interfaces with the PC and communicates with the Windows software to
				display the captured waveform in the both the time and frequency domains.
				The design combines a high frequency analog stage with AC/DC coupling and three gains, a
				MAX118 digital to analog converter, a trigger circuit, a PIC16F877A microcontroller, and
				some PC interfacing hardware.</p>
				
				<p>Screenshots of the program and pictures of the oscilloscope are below.</p>
                
                <center>
<table width="550" border="0" cellspacing="0" cellpadding="0">
<tr>
	<td colspan="5">
		<img id="mainimg" src="ppmscope1.jpg">
		<center><p id="caption">Screenshot of the Oscilloscope program</p></center>
		</td>
</tr>
<tr>
	<td width="30" height="125" valign="center">
		<img onclick="moveLeft();" onmouseover="enterLeft();" onmouseout="exitLeft();" id="limg" src="left.gif" width="30" height="100">
	</td>
	<td height="150" valign="center">
		<center>
		<img onclick="setMain(0);" onmouseover="enterPic(0);" onmouseout="exitPic(0);" id="subAimg" 
			src="ppmscope1sm.jpg">
		</center>
	</td>
	<td height="150" valign="center">
		<center>
		<img onclick="setMain(1);" onmouseover="enterPic(1);" onmouseout="exitPic(1);" id="subBimg"
			src="ppmscope2sm.jpg">
		</center>
	</td>
	<td height="150" valign="center">
		<center>
		<img onclick="setMain(2);" onmouseover="enterPic(2);" onmouseout="exitPic(2);" id="subCimg"
			src="ppmscope3sm.jpg">
		</center>
	</td>
	<td height="150" valign="center">
		<img onclick="moveRight();" onmouseover="enterRight();" onmouseout="exitRight();" id="rimg" src="right.gif" width="30" height="100">
	</td>
</tr>
<tr>
	<td colspan="5">
		<center><small>Click on small image to enlarge</small></center>
	</td>
</tr>
</table>				</center>    
									
				<h4>Specifications and Goal Feature List</h4>
			
	<table width=100% border=0 cellspacing=0 style="BORDER-LEFT: #8f8f8f 1px solid;BORDER-RIGHT: #8f8f8f 1px solid; BORDER-TOP: #8f8f8f 1px solid; BORDER-BOTTOM: #8f8f8f 1px solid">
	<tr>
		<td bgcolor="#EFEFEF"><p></td>
		<td bgcolor="#EFEFEF"><p><b>Current Version (v.2.14)</b></td>
		<td bgcolor="#EFEFEF"><p>    <b>Goal Version</b></td>
	</tr><tr>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p><b>Sample Rate</b></td>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p>Variable, single shot 1 MHz max, interlaced 417 kHz max, time equivalent 5 MHz max</td>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p>Variable, single shot 1 MHz max, interlaced 500 kHz max, time equivalent 5 MHz max</td>
	</tr><tr>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p><b>Bandwidth</b></td>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p>500 kHz</td>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p>500 kHz</td>
	</tr><tr>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p><b>Number of Channels</b></td>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p>Two</td>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p>Two</td>
	</tr><tr>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p><b>Sample Depth</b></td>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p>256 bytes per channel, 128 bytes per channel when interlaced</td>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p>256 bytes per channel, 128 bytes per channel when interlaced</td>
	</tr><tr>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p><b>Sample Modes</b></td>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p>Single shot, interlaced channel, and time equivalent</td>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p>Single shot, interlaced channel, and time equivalent</td>
	</tr><tr>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p><b>Calibration</b></td>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p>Voltage offset</td>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p>Voltage per division and voltage offset calibration</td>
	</tr><tr>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p><b>Configuration Settings</b></td>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p>Configuration of default and saving of settings for future use</td>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p>Configuration of default and saving of settings for future use</td>
	</tr><tr>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p><b>Hardware Connection</b></td>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p>Any parallel or serial port</td>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p>Any parallel, serial, or USB port</td>
	</tr><tr>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p><b>Coupling</b></td>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p>AC and DC, reflected on PC</td>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p>AC and DC, reflected on PC</td>
	</tr><tr>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p><b>Channel gain</b></td>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p>Gain of 1, 2, and 5, reflected on PC</td>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p>Gain of 1, 2, and 5, reflected on PC</td>
	</tr><tr>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p><b>Trigger</b></td>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p>Variable level, slope, and timing</td>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p>Variable level, slope, and timing</td>
	</tr><tr>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p><b>Frequency Spectrum</b></td>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p>Yes</td>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p>Yes with user selected sampling windows</td>
	</tr><tr>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p><b>Waveform Reconstruction</b></td>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p>Triangle, square, point, and sinc</td>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p>Triangle, square, point, and sinc</td>
	</tr><tr>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p><b>XY view</b></td>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p>Yes</td>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p>Yes</td>
	</tr><tr>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p><b>Channel offset and volt per division settings</b>
		</td><td  style="BORDER-TOP: #8f8f8f 1px solid;"><p>Yes</td>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p>Yes</td>
	</tr><tr>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p><b>Cursors</b></td>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p>Yes</td>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p>Yes</td>
	</tr><tr>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p><b>Math functions</b></td>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p>Addition, subtraction, auto period, auto peak-to-peak, etc.</td>
		<td  style="BORDER-TOP: #8f8f8f 1px solid;"><p>Addition, subtraction, auto period, auto peak-to-peak, etc.</td>
	</tr><tr>
		 <td  style="BORDER-TOP: #8f8f8f 1px solid;"><p><b>Waveform export</b></td>
		 <td  style="BORDER-TOP: #8f8f8f 1px solid;"><p>Comma delimited</td>
		 <td  style="BORDER-TOP: #8f8f8f 1px solid;"><p>Bitmap and comma delimited</td>
	</tr><tr>
		 <td  style="BORDER-TOP: #8f8f8f 1px solid;"><p><b>Waveform logging</b></td>
		 <td  style="BORDER-TOP: #8f8f8f 1px solid;"><p>Comma delimited  logfile containing waveform and measurement information</td>
		 <td  style="BORDER-TOP: #8f8f8f 1px solid;"><p>Comma delimited  logfile containing waveform and measurement information</td>
	</tr>
	</table>
            
<a name="release"></a>
<h4>Release Notes</h4>

<p>Release Notes for version 2.141 build 3/30/2012</p>

<ul>
	<li>Correction of bug.  The program would sometimes freeze when turning the trigger off.</li>
	<li>Fine tuning of waveform and measurement logging.</li>
	<li>Feedback of modes on the toolbar using depressed buttons.</li>
	<li>Upgrade of software license to GPL v3.</li>
	<li>Ground plane added to PCB layout.</li>
	<li>Parts list added for version 1.2 of the hardware.</li>
</ul>

<p>Release Notes for version 2.14 build 12/12/2011</p>

<ul>
	<li>Addition of user configurable parallel port.</li>
	<li>Addition of serial port interface.</li>
	<li>Addition of hardware testing dialog.</li>
	<li>Change to the firmware and software to correct yet another triggering bug.  On single capture trigger events,
		the scope had to be triggered twice to capture one waveform.  Now every event is captured.</li>
	<li>Addition of user defined refresh rate.</li>
	<li>Implementation of all configuration file options.</li>
	<li>Addition of waveform and measurement logging.  This adds data recorder capability to the oscilloscope program
		which could be helpful for capturing behavior like battery discharge curves or filter bode plots.</li>
	<li>PCB layout drawn in FreePCB and exported as Gerbers and PDF files.</li>
	<li>Modifications to hardware for future USB interface (now hardware version 1.2).  Prior versions of the 
		hardware are still supported in	software and firmware updates.</li>
</ul>
	
<p>Release Notes for version 2.131 build 2/1/2011</p>

<ul>
	<li>Change to the firmware to correct yet another triggering bug.  Thanks to Ger Van Den Hoek for his help in discovering and troubleshooting the bug.</li>
</ul>

<p>Release Notes for version 2.13 build 11/18/2009</p>

<ul>
	<li>Change to the firmware to correct a triggering bug.  At slower trigger intervals, the software would attempt communication during a trigger event.  The trigger event would cause the communication to be interrupted.  Periodically, the interruption of communication would leave the communication lines in an invalid state and the oscilloscope would quit responding to further communications.  This bug has been corrected in the firmware.
	<li>Added auto measurements (auto peak to peak, rise time, fall time, period, frequency, signal rms, signal average, duty cycle, etc.).
</ul>


<p>Release Notes for version 2.12 build 4/1/2009</p>

<ul>
	<li>Added Repetitive sampling, "time equivalent" modes for sampling waveforms up to a 5 MHz sample rate
	<li>Expanded interlaced sampling mode to 417 kHz maximum sample rate
	<li>Changed trigger functionality so that when the trigger is turned off, the scope reconfigures without a trigger
		event (before the scope would not update until a trigger occurred.  This caused some confusion, because the 
		user turned the trigger off and had to toggle the power on the oscilloscope or force a trigger event
		to see the screen update.
	<li>Shortened minimum trigger delay to 2.6 us, improved trigger delay resolution, and extended maximum trigger delay
	<li>Changed the panel incremental buttons to spinner buttons.  This change adds keyboard arrow and mouse scroll wheel 
		functionality to selecting the Time-per-Div, Volts-per-Div for each channel, Voltage Offset for each channel, and the Trigger Delay
	<li>Program Menu enhancements, the addition of radio buttons and check boxes to indicate oscilloscope settings
	<li>Other interface enhancements such as larger buttons for toolbar, changing of mouse cursors with "see thru hole" for better measurement
		on the scope screen
	<li>Correction of bug that was causing the Time-per-Div reported by the scope panel to be slightly in error
	<li>Correction of bug that was causing incorrect behavior when sampling at less than 9,000 Hz.  The oscilloscope software was always assuming
		that data was recieved whenever requested.  However, at the lower sampling rates, data wasn't aways ready to be reported to the PC
	<li>Correction of bug that was causing the voltages to be scaled incorrectly by 23 percent
	<li>Clarification on note for R24 on the Schematic
	<li>Additional topics added to the help system
	<li>Additional wiring diagram added to the PCB directory showing how components are connected to the PCB that are mounted on the front or
		back panels of the oscilloscope enclosure
</ul>
	
<a name="revisions"></a>
<h4>Future Revisions</h4>

<p>Here are my plans for future revisions of the hardware and software including:

<ul>
	<li>Computer interfacing on the USB port
	<li>Hardware calibration (voltage per division)
	<li>Extended math functions and math function graphing
	<li>User selectable windowing functions (Rectangular [default - included in software now], Hanns, Hamming, Gauss, Blackman, etc)
	<li>User interface enhancements, color choices, etc (fun stuff)
	<li>Multi-language support
</ul>

<a name="support"></a>
<h4>Support</h4>

<p>I'd be glad to help with the installation of this software, the construction of
   the oscilloscope hardware, the understanding of the source code, the addition
   of functionality to the software, or the accepting of bug reports and the repairing of bugs.
   If you just need someone to e-mail every now and then, I don't mind making friends.
   I am not nearly as enthusiastic about doing your homework or helping on
   some unrelated project unless I find it interesting.  That said, you can ask,
   but I don't give any promises about my expertise in anything except matters
   directly relating to the software and hardware schematics delivered here.</p>

            <a name="download"></a>
			<h4>Files for download:</h4>

            <table width=100% border=0 cellspacing=0 cellpadding=5 style="BORDER-LEFT: #8f8f8f 1px solid;BORDER-RIGHT: #8f8f8f 1px solid; BORDER-TOP: #8f8f8f 1px solid; BORDER-BOTTOM: #8f8f8f 1px solid">
            <tr>
                <td style="BORDER-BOTTOM: #8f8f8f 1px solid;" colspan=5>
                    <h5>PPM Scope for Windows version 2.14</b></td>
            </tr>
            <tr>
                <td><img src="img.gif" width="10" height="1"></td>
                <td width="98%" style="BORDER-LEFT white 10px solid" colspan=4>
                    <p>A DIY (do it yourself) oscilloscope with a maximum sample rate of 1 MHz and an equivalent maximum sample rate of 5 MHz.
                </td>
            </tr>
            <tr>
                <td height="30px">&nbsp;</td>
                <td width=150 valign="bottom" colspan=2><p><b>Filename</td>
				<td width=500 valign="bottom"><p><b>Description</td>
                <td width=150 valign="bottom"><p><b>Size/Date</td>
            </tr>
            <tr>
                <td bgcolor="#EFEFEF" style="BORDER-TOP: #8f8f8f 1px solid;">&nbsp;</td>
                <td bgcolor="#EFEFEF" style="BORDER-TOP: #8f8f8f 1px solid;"><p><a href="<!--#main.dat:countlink#-->PPMScopeWin.zip"><font color="black">PPMScopeWin.zip&nbsp;v.2.141</a></td>
				<td bgcolor="#EFEFEF" style="BORDER-TOP: #8f8f8f 1px solid;" width="30"><a href="<!--#main.dat:countlink#-->PPMScopeWin.zip"><img border=0 width="25" height="23" src="zip.gif"></a></td>
                <td bgcolor="#EFEFEF" style="BORDER-TOP: #8f8f8f 1px solid;"><p>Includes a description, source code, executable files, hex files, schematics, and PCB layout.</td>
                <td bgcolor="#EFEFEF" style="BORDER-TOP: #8f8f8f 1px solid;"><p>4.29 MB - 4/4/2012</td>
            </tr>
            <tr>
                <td style="BORDER-TOP: #8f8f8f 1px solid;">&nbsp;</td>
                <td style="BORDER-TOP: #8f8f8f 1px solid;" valign="top"><p><a href="<!--#main.dat:countlink#-->PPMScopeDatasheets.zip"><font color="black">PPMScopeDatasheets.zip</a></td>
				<td style="BORDER-TOP: #8f8f8f 1px solid;" width="30"><a href="<!--#main.dat:countlink#-->PPMScopeDatasheets.zip"><img border=0 width="25" height="23" src="zip.gif"></a></nobr></td>
                <td style="BORDER-TOP: #8f8f8f 1px solid;"><p>The component datasheets for the PPMScope.</td>
                <td style="BORDER-TOP: #8f8f8f 1px solid;"><p>3.72 MB - 12/12/2011</td>
            </tr>
			<tr>
				<td bgcolor="#EFEFEF" style="BORDER-TOP: #8f8f8f 1px solid;">&nbsp;</td>
				<td bgcolor="#EFEFEF" style="BORDER-TOP: #8f8f8f 1px solid;" valign="top"><p><a href="<!--#main.dat:countlink#-->DaveDeBoer_Perfboard.zip"><font color="black">DaveDeBoer_Perfboard.zip</a></td>					
				<td bgcolor="#EFEFEF" style="BORDER-TOP: #8f8f8f 1px solid;"><a href="<!--#main.dat:countlink#-->DaveDeBoer_Perfboard.zip"><img border=0 width="25" height="23" src="zip.gif"></a></nobr></td>
				<td bgcolor="#EFEFEF" style="BORDER-TOP: #8f8f8f 1px solid;"><p>A perfboard layout with an integrated power supply on a 4&quot;x6&quot; board designed and contributed by Dave de Boer.</p></td>
				<td bgcolor="#EFEFEF" style="BORDER-TOP: #8f8f8f 1px solid;"><p>2.97 MB - 1/10/2012</td>
			</tr>
            <tr>
                <td style="BORDER-TOP: #8f8f8f 1px solid;">&nbsp;</td>
                <td style="BORDER-TOP: #8f8f8f 1px solid;" valign="top"><p><a href="<!--#main.dat:countlink#-->Chris_PCB.zip"><font color="black">Chris_PCB.zip</a></td>
				<td style="BORDER-TOP: #8f8f8f 1px solid;" width="30"><a href="<!--#main.dat:countlink#-->Chris_PCB.zip"><img border=0 width="25" height="23" src="zip.gif"></a></nobr></td>
                <td style="BORDER-TOP: #8f8f8f 1px solid;"><p>An alternative PCB layout optimized for easy etching on a single sided copper board.  Designed and contributed by Krzysztof Passowicz.</td>
                <td style="BORDER-TOP: #8f8f8f 1px solid;"><p>1.22 MB - 3/30/2012</td>
            </tr>			
            <tr>
                <td bgcolor="#EFEFEF" style="BORDER-TOP: #8f8f8f 1px solid;">&nbsp;</td>
                <td bgcolor="#EFEFEF" style="BORDER-TOP: #8f8f8f 1px solid;" valign="top"><p><a href="<!--#main.dat:countlink#-->PPMHelp/index.html"><font color="black">Online Help File</a>&nbsp;&nbsp;</td>
				<td bgcolor="#EFEFEF" style="BORDER-TOP: #8f8f8f 1px solid;" width="30">&nbsp;</td>
                <td bgcolor="#EFEFEF" style="BORDER-TOP: #8f8f8f 1px solid;"><p>Read the online help file for introduction, construction, and operation instructions.</td>
                <td bgcolor="#EFEFEF" style="BORDER-TOP: #8f8f8f 1px solid;">&nbsp;</td>
            </tr>
            </table>

                <p>Please see the <a href="aboutsite.html#termsConditions">terms and conditions</a> before
                    downloading.</p>
                
                
                <p>If you would like to be notified when I update the project, please 
				<a href="index.html#emaillist">join the mailing list.</a>
                    Click <a href="contact.html#top">here</A> to send me comments or suggestions.</p>
                
                            
                            <br>
							<br>
							<br>

[webring]
<!--#main.dat:webring#-->

