[Make]
file=index.html
directory=<!--#main.dat:ppmhelpdir#-->
template=main.tpl

[title]
PPMScope Online Help

[description]
Main Index for PPMScope online help.

[file]
PPMHelp/index.html

[javascript]
<!--#main.dat:javascript#-->

[sideadd]
<!--#ppmscope.mk:sideadd#-->

[sidebar]
<center><h3>PPMScope Help</h3></center>
<!--#main.dat:sidebarst#-->
<a href="<!--#main.dat:url#-->/ppmscope.html#top">PPMScope Project Page</a>
<!--#main.dat:tb#-->
<a href=index.html#about>PPMScope Online Help Index</a>
<!--#main.dat:tb#-->
<a href=intro.html#about>Introduction</a>
<!--#main.dat:tb#-->
<a href="picprog.html#top">PIC Programmer</a>
<!--#main.dat:tb#-->
<a href="build.html#top">Build the oscilloscope</a> 
<!--#main.dat:tb#-->
<a href="test.html#top">Test the oscilloscope and connect to the PC</a> 
<!--#main.dat:tb#-->
<a href="calibrate.html#top">Calibrate the oscilloscope</a> 
<!--#main.dat:tb#-->
<a href="screen.html#top">Screen Identification</a>
<!--#main.dat:tb#-->
<a href="scrmenu.html#top">Menu Index</a>
<!--#main.dat:tb#-->
<a href="scope.html#top">Using Oscilloscope Windows</a>
<!--#main.dat:tb#-->
<a href="files.html#top">Saving Waveforms</a>
<!--#main.dat:tb#-->
<a href="files.html#settings">Settings Files</a>
<!--#main.dat:tb#-->
<a href="panel.html#gains">Analog Gain and Coupling</a>
<!--#main.dat:tb#-->
<a href="compile.html#top">Compiling the Sources</a>
<!--#main.dat:sidebarsp#-->
<center><h3>Read More</h3></center>
<!--#main.dat:sidebarst#-->
<!--#index.mk:sidebarmid#-->
<!--#main.dat:sidebarstop#-->

[content]
<h1>PPMScope Online Help</h1>

<h2>PPMScope Introduction</h2>

<UL>
	<LI><a href=intro.html#about>About</a>
	<li><a href=intro.html#release>Release Notes</a>
	<li><a href=intro.html#revisions>Future Revisions</a>
	<li><a href=intro.html#support>Support</a>
	<LI><a href=intro.html#license>License</a>
	<li><a href=intro.html#credits>Acknowledgements</a>
</UL>

	<h2>Oscilloscope Construction</h2>

	<p>The construction of the oscilloscope consists of four steps:</p>

	<ul>
		<li>Buy or <a href="picprog.html#top">build</a> a PIC programmer and <a href="picprog.html#winpic">program</a> the PIC
		<li><a href="build.html#top">Build</a> the oscilloscope
		<li><a href="test.html#top">Test</a> the oscilloscope and connect to the PC
		<li><a href="calibrate.html#top">Calibrate</a> the oscilloscope
	</ul>
	
<h2>PPMScope PC Program Overview</h2>

<ul>
	<li><a href="screen.html#top">Screen Identification</a>
	<li><a href="scrmenu.html#top">Menu Index</a>
	<li><a href="scope.html#top">Using Oscilloscope Windows</a>
	<li><a href="scope.html#winmodes">Oscilloscope Window Modes</a>
	<li><a href="scope.html#channel">Channel Display Settings and Scaling</a>
	<li><a href="scope.html#reconst">Waveform Reconstruction Modes</a>
	<li><a href="scope.html#capture">Oscilloscope Capture Modes</a>
	<li><a href="scope.html#trigger">Trigger Modes and Configuration</a>
	<li><a href="scope.html#sample">Sampling modes</a>
	<li><a href="scope.html#automeasure">Auto-measurements</a>
	<li><a href="files.html#top">Saving Waveforms</a>
	<li><a href="files.html#settings">Saving and Opening Settings Files</a>
</ul>

<h2>Using the Oscilloscope Front Panel</h2>

<p>There are two adjustments for each channel:

<ul>
	<li><a href="panel.html#gains">Analog Gain</a>
	<li><a href="panel.html#coupling">Channel Coupling</a>
</ul>

<h2>Using PPMScope on Linux under Wine</h2>

<ul><li><a href="linux.html#fedora">Fedora 19</a>
</ul>

<h2>Compiling the PPMScope Source Code</h2>
<ul>
	<li><a href="compile.html#top">Compiling PC Source Code</a>
	<li><a href="compile.html#help">Building the Help file</a>
	<li><a href="compile.html#firmware">Assembling the Firmware Source Code</a>
</ul>