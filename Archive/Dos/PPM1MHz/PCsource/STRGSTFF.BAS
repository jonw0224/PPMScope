'====================================================================================
'*Author:  Jonathan Weaver
'*Date:    6/6/2001
'*Version: 1.1
'*         1.1 build # 2 - 5/21/2005 - added loadFilebuffer() and fileBufferNum()
'*Filename:  strgstff.bas
'*Description:  A collection of subroutines used to edit and parse strings.
'
'Copyright (C) 2005 Jonathan Weaver
'
'This program is free software; you can redistribute it and/or modify it under 
'the terms of the GNU General Public License as published by the Free Software 
'Foundation; either version 2 of the License, or (at your option) any later 
'version.
'
'This program is distributed in the hope that it will be useful, but WITHOUT 
'ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
'FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more 
'details.
'
'You should have received a copy of the GNU General Public License along with 
'this program; if not, write to the Free Software Foundation, Inc., 
'51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
'
'====================================================================================


$compile unit "strgstff.pbu"

'====================================================================================
' B U I L D   F U N C T I O N
'====================================================================================

'*Returns the build and version number of this unit library
'*RETURN: the number of the build
function verStrgstff$() public
verStrgstff$ = "String stuff Ver 1.0, build #1:  strgstff.pbu"
end function

'====================================================================================
' P U B L I C  S U B R O U T I N E S
'====================================================================================

'*Parses a word from a string
'*toParse$: the string to parse
'*tokenChar$: the character which separates words
'*wordNo%: the nth word to parse out of a the string.  For example wordNo% = 1 parses the first word from the string, etc.
'*RETURN: the value of the word
function parseword$(toParse$, tokenChar$, wordNo%) public
beginWord% = 1
endWord% = instr(toParse$, tokenChar$)
i% = 1
while i% < wordNo% and endWord% <> 0
beginWord% = endWord%+len(tokenChar$)
endWord% = instr(beginWord%, toParse$, tokenChar$)
incr i%
wend
if i% < wordNo% then
toRet$ = ""
elseif (endWord% = 0) then
toRet$ = right$(toParse$, len(toParse$) - beginWord%+1)
else
toRet$ = mid$(toParse$, beginWord%, endWord% - beginWord%)
end if
parseWord$ = toRet$
end function

'*Loads the contents of a file into a string
'*filename$:  the name of the file to load
'*RETURN:  a string containing the contents of the file
function loadFile$(filename$) public
fileNo% = freefile
open filename$ for binary as fileNo%
leng& = lof(fileNo%)
a$ = string$(leng&, " ")
get fileNo%,0,a$
loadFile$ = a$
close fileNo%
end function

'*Loads a section of the contents of a file into a string
'*filename$:  the name of the file to load
'*bufferNum%: a number indicating the section of the file to load, starting with zero and ending with fileBufferNum(filename$) - 1
'*RETURN:  a string containing the contents of the file
function loadFileBuffer$(filename$, bufferNum%) public
fileNo% = freefile
open filename$ for binary as fileNo%
leng& = max(0,min(32000, lof(fileNo%)-bufferNum%*32000))
if leng& > 0 then
    a$ = string$(leng&, " ")
    get fileNo%, 32000*bufferNum%, a$
else
    a$ = ""
end if
loadFileBuffer$ = a$
close fileNo%
end function

'*Returns the number of buffers a file will be split into by loadFileBuffer$
'*filename$:  the name of the file to load with loadFileBuffer$
'*return:  an integer indicating the number of buffers in the file
function fileBufferNum%(filename$) public
fileNo% = freefile
open filename$ for binary as fileNo%
leng% = ceil(lof(fileNo%) / 32000)
close fileNo%
fileBufferNum = leng%
end function

'*Returns the number of words that can be made in a string.
'*toParse$:  string to parse
'*tokenChar$:  the character which separates words
'*RETURN: an integer containing the number of words in the string
function wordNum%(toParse$, tokenChar$) public
endWord% = instr(toParse$, tokenChar$)
i% = 1
while endWord% <> 0
endWord% = instr(endWord%+len(tokenChar$), toParse$, tokenChar$)
incr i%
wend
wordNum% = i%
end function

'*Returns the number of times a substring appears in a string.
'*mainStr$: the string to search
'*subStr$: the string to count the occurances of
'*return: an integer containing the occurance of subStr$ in mainStr$
function stringNum%(mainStr$, subStr$) public
stringNum% = wordNum(mainStr$, subStr$) - 1
end function