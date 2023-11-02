[Make]
file=picprog.html
directory=<!--#main.dat:ppmhelpdir#-->
template=main.tpl
default=PPMHelpIndex.mk

[title]
PIC Programmer and Programming

[description]
PIC Programmer and programming.  PPMScope online help.

[file]
picprog.html

[content]
<h1>PIC Programmer and Programming</h1>

<h1>Programmer</h1>

<p>There are many PIC programmers you can purchase or whose schematics (and software) you can find freely over the Internet</p>

<p>David Tait has a programmer with software and hardware schematics available <A HREF= "#" 
 onClick="window.open('http://www.dontronics.com/dtait/index.html',
'Sample','toolbar=yes,width=640,height=480,left=0,top=0, status=yes,scrollbars=yes,resize=yes');return false">
here</a>.
	If you read his documentation, you will find various programmer schematics.  I use the Classic &quot;Tait&quot; Programmer.  The schematic is below:</p>

<img border=0 alt="David Tait Programmer Schematic" src="pp.gif" width=590 height=408>

<p>I have modified my Tait programmer
	to include a programming header consisting of GND, MCLR, RB6 (CLOCK), and RB7 (DATA) for
	use in programming "in circuit".  Most of my microcontroller project schematics include a pull-up
	resistor on MCLR, so you can use the programmer with no further modifications.</p>

<a name="winpic"></a>
<h1>Programmer Software</h1>

<p>I don't use FPP, the software supplied by David Tait.  You can use it and program a PIC16F877 to
	run the oscilloscope firmware and everything should work just fine.  If you want to program
	the more readily available (and generally cheaper) PIC16F877A, FPP won't work.</p>

<p>Therefore, I use another free programmer software called
	<A HREF= "#" 
 onClick="window.open('http://www.winpic800.com/',
'Sample','toolbar=yes,width=640,height=480,left=0,top=0, status=yes,scrollbars=yes,resize=yes');return false">
WinPic800</a> (you can also use another program
	called IC PROG).  I prefer WinPic800 because it is easier to set up in Windows XP (you don't have
	to go download a separate driver), it is flexible enough to work with non-standard programmers,
	and I get consistently good results.</P>

<p>To help with the setup, here is a screen capture of the Hardware Settings dialog from WinPic800
	configured for use with the Tait Programmer on LPT1.  Notice the bit numbers and byte offsets for each 	signal and which signals are inverted.</p>

<img border=0 alt="Win Pic 800" src="WinPic800.gif" width=584 height=360>

<p>Once you've worked through these items above, you should now be ready to program the PIC!</p>
