rem This file runs all of the script commands to publish the PPMScope Project to the website directory (falls short of issuing FTP commands)
rem Jonathan Weaver
rem Updated 8/28/2014

set pgpath=c:\Program Files (x86)
set prpath=c:\OneDrive\projects\PPMScope

rem Build Local Help
cd %prpath%
xcopy PCB\WiringOfPCB.jpg %prpath%\PCSource\Help /y
xcopy PCB\"Version 1.20"\*.pdf %prpath%\PCSource\Help /y
xcopy Schematics\"Version 1.20"\*.pdf %prpath%\PCSource\Help /y
xcopy Schematics\"USBToSerial Daughterboard"\*.pdf %prpath%\PCSource\Help\ /y
xcopy PCB\"USBToSerial Daughterboard"\*.pdf %prpath%\PCSource\Help\ /y
cd HelpBuild
build
cd %prpath%

rem Compile Help File
rem Requires an installation of HTML Help Workshop
"%pgpath%\HTML Help Workshop\hhc" "%prpath%\PCSource\Help\ppmscope.hhp"
xcopy PCSource\Help\ppmscope.chm %prpath% /y

rem Rebuild PC Program
"%pgpath%\Codeblocks\codeblocks" /na /nd --no-splash-screen --rebuild %prpath%\PCSource\PPMScope.cbp

rem Update PC Program
xcopy PCSource\PPMScope.exe %prpath% /y
xcopy PCSource\PPMScope.exe.manifest %prpath% /y
xcopy PCSource\default.cfg %prpath% /y

rem Update Firmware files
xcopy "Picasm\Version 1.05\Osc1MHz_v1_0.HEX" PicHex\ /y
xcopy "Picasm\Version 1.20\Osc1MHz_v1_2.HEX" PicHex\ /y
xcopy "Picasm\Version 1.20\Osc1MHz_v1_2 for PIC16F887.HEX" PicHex\ /y

rem Clean Directories
del /s picasm\*.mcs
del /s picasm\*.o
del /s picasm\*.cof
del /s picasm\*.err
del /s picasm\*.cod
del /s picasm\*.lst
del /s picasm\*.map
del /s picasm\*.hex
del PCSource\*.o
del PCSource\*.csv
del PCSource\PPMScope.exe
del PCSource\inpout32.dll
del PCSource\Makefile.win
del PCSource\PPMScope_private.res
del PCSource\PPMScope_private.rc
del PCSource\PPMScope_private.h
del PCSource\classfolders.dcf
del /q PCSource\.objs\*.*
rmdir PCSource\.objs
del /s Spice\*.raw
del /s Schematics\*.backup
del /s Spice\*.log
del /s Schematics\*.dsn.autosave
del /s PCB\*.bak 
del /s PCB\*.png
del debug.txt
del PCSource\debug.txt
del PCSource\ppmscope.chm
del PCSource\Help\ppmscope.chm
del /s PCSource\*.zip
del /s picasm\*.zip
del /s Schematics\*.zip
del /s Spice\*.zip
del /s PCB\*.zip
del /s PicHex\*.zip

rem Create Zip File
rem Requires an installation of 7Zip
del PPMScopeWin.zip
"%pgpath%"\7-Zip\7z a %prpath%\PPMScopeWin.zip PCB\
"%pgpath%"\7-Zip\7z a %prpath%\PPMScopeWin.zip PCSource\
"%pgpath%"\7-Zip\7z a %prpath%\PPMScopeWin.zip Picasm\
"%pgpath%"\7-Zip\7z a %prpath%\PPMScopeWin.zip PicHex\
"%pgpath%"\7-Zip\7z a %prpath%\PPMScopeWin.zip Schematics\
"%pgpath%"\7-Zip\7z a %prpath%\PPMScopeWin.zip Spice\
"%pgpath%"\7-Zip\7z a %prpath%\PPMScopeWin.zip InstallDriver.exe
"%pgpath%"\7-Zip\7z a %prpath%\PPMScopeWin.zip cc-by-sa-30.txt
"%pgpath%"\7-Zip\7z a %prpath%\PPMScopeWin.zip default.cfg
"%pgpath%"\7-Zip\7z a %prpath%\PPMScopeWin.zip gpl.txt
"%pgpath%"\7-Zip\7z a %prpath%\PPMScopeWin.zip inpout32.dll
"%pgpath%"\7-Zip\7z a %prpath%\PPMScopeWin.zip ppmscope.chm
"%pgpath%"\7-Zip\7z a %prpath%\PPMScopeWin.zip PPMScope.exe
"%pgpath%"\7-Zip\7z a %prpath%\PPMScopeWin.zip PPMScope.exe.manifest
"%pgpath%"\7-Zip\7z a %prpath%\PPMScopeWin.zip Readme.txt

rem Copy files back to development directory
xcopy PPMScope.exe PCSource\ /y
xcopy ppmscope.chm PCSource\ /y
xcopy inpout32.dll PCSource\ /y
