[Make]
file=compile.html
directory=<!--#main.dat:ppmhelpdir#-->
template=main.tpl
default=PPMHelpIndex.mk

[title]
Compiling the PPMScope Source Code

[file]
PPMHelp/compile.html

[description]
Compiling the PPMScope Source Code.  PPMScope online help.

[content]
<h1>Compiling the PPMScope Source Code</h1>

<h1>Compiling the PC Source Code</h1>

<p>The PC Source code is compiled using the MinGW C Compiler from within the <a href= "#" 
 onClick="window.open('http://www.bloodshed.net/dev/devcpp.html',
'Sample','toolbar=yes,width=640,height=480,left=0,top=0,status=yes,scrollbars=yes,resize=yes');return false">Dev-Cpp IDE</a>.  In 2006, the developers of Dev-Cpp stopped supporting the program, so I recommend using the <a href=<a href= "#" 
 onClick="window.open('http://www.codeblocks.org/',
'Sample','toolbar=yes,width=640,height=480,left=0,top=0,status=yes,scrollbars=yes,resize=yes');return false">CodeBlocks IDE</a> with the MinGW C Compiler.  The PC Source Code comes with a project file for Dev-Cpp and can be imported into CodeBlocks easily.</p>

<p>The include file commctrl.h that is distributed with the MinGW Compiler will need to be modified to utilize components of Internet Explorer 5 commonly shipped with Windows.  The commctrl.h file is located at:</p>

<p>For Dev-Cpp,</p>
<p><code>c:\Dev-Cpp\include\commctrl.h</code></p>

<p>For CodeBlocks on Windows XP and Vista,</p>
<p><code> c:\Program Files\CodeBlocks\MinGW\include\commctrl.h</code></p>
<p>or on Windows 7,</p>
<p><code>c:\Program Files (x86)\CodeBlocks\MinGW\include\commctrl.h</code></p>

<p>The edits are minor and are shown below:</p>

<img border=0 alt="" src="compile.jpg" width="590" height="286"><br><br>

<p>In addition, in the CodeBlocks environment, you will need to update the library file.  You can do this by selecting &quot;Project&quot; -&gt; &quot;Build Options&quot; from the main menu.  And then you should select the "Linker Settings" tab and edit the path to the library to match your install.</p>

<img border=0 alt="" src="library.jpg" width="590" height="314"><br><br>

<p>The path in the project file is the default path for Windows 7:</p>
<p><code>c:\Program Files (x86)\CodeBlocks\MinGW\lib\libcomctl32.a</code></p>
<p>The path for Windows XP and Vista would be:</p>
<p><code>c:\Program Files\CodeBlocks\MinGW\lib\libcomctl32.a</code></p>

<p>Once the edits are made, the project should compile.  All project files, source files, and header files are in the PCSource directory</p>

<a name="help"></a>
<h1>Building the Help file</h1>

<p>The help file is created using the <a href="#" 
 onClick="window.open('http://www.microsoft.com/download/en/details.aspx?displaylang=en&id=21138',
'Sample','toolbar=yes,width=640,height=480,left=0,top=0,status=yes,scrollbars=yes,resize=yes');return false">HTMLHelp</a> tool from Microsoft.  All project files, HTML files, and other sources for the help file are in the PCSource\Help directory</p>

<a name="firmware"></a>
<h1>Assembling the Firmware Source Code</h1>

<p>The firmware is assembled using the <a href="#" 
 onClick="window.open('http://www.microchip.com/stellent/idcplg?IdcService=SS_GET_PAGE&nodeId=1406&dDocName=en019469&part=SW007002',
'Sample','toolbar=yes,width=640,height=480,left=0,top=0,status=yes,scrollbars=yes,resize=yes');return false">MPLAB</a> toolset from Microchip.  All include files and assembly files are included under the Picasm directory.</p>