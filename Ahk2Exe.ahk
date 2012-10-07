;
; File encoding:  UTF-8
;
; Script description:
;	Ahk2Exe - AutoHotkey Script Compiler
;	Written by fincs - Interface based on the original Ahk2Exe
;

#NoEnv
#NoTrayIcon
#SingleInstance Off
#Include %A_ScriptDir%
#Include Compiler.ahk
SendMode Input

DEBUG := !A_IsCompiled

if A_IsUnicode
	FileEncoding, UTF-8

gosub BuildBinFileList
gosub LoadSettings

if 0 != 0
	goto CLIMain

IcoFile := LastIcon
BinFileId := FindBinFile(LastBinFile)

#include *i __debug.ahk

Menu, FileMenu, Add, &Convert, Convert
Menu, FileMenu, Add
Menu, FileMenu, Add, E&xit`tAlt+F4, GuiClose
Menu, HelpMenu, Add, &Help, Help
Menu, HelpMenu, Add
Menu, HelpMenu, Add, &About, About
Menu, MenuBar, Add, &File, :FileMenu
Menu, MenuBar, Add, &Help, :HelpMenu
Gui, Menu, MenuBar

Gui, +LastFound
GuiHwnd := WinExist("")
Gui, Add, Text, x287 y34,
(
©2004-2009 Chris Mallet
©2008-2011 Steve Gray (Lexikos)
©2011-2012 fincs
©2012-2012 HotKeyIt
http://www.autohotkey.com
Note: Compiling does not guarantee source code protection.
)
Gui, Add, Text, x11 y117 w570 h2 +0x1007
Gui, Add, GroupBox, x11 y124 w570 h86, Required Parameters
Gui, Add, Text, x17 y151, &Source (script file)
Gui, Add, Edit, x137 y146 w315 h23 +Disabled vAhkFile, %AhkFile%
Gui, Add, Button, x459 y146 w53 h23 gBrowseAhk, &Browse
Gui, Add, Text, x17 y180, &Destination (.exe file)
Gui, Add, Edit, x137 y176 w315 h23 +Disabled vExeFile, %Exefile%
Gui, Add, Button, x459 y176 w53 h23 gBrowseExe, B&rowse
Gui, Add, GroupBox, x11 y219 w570 h128, Optional Parameters
Gui, Add, Text, x18 y245, Custom Icon (.ico file)
Gui, Add, Edit, x138 y241 w315 h23 +Disabled vIcoFile, %IcoFile%
Gui, Add, Button, x461 y241 w53 h23 gBrowseIco, Br&owse
Gui, Add, Button, x519 y241 w53 h23 gDefaultIco, D&efault
Gui, Add, Text, x18 y274, Base File (.bin)
Gui, Add, DDL, x138 y270 w315 h23 R10 AltSubmit vBinFileId Choose%BinFileId%, %BinNames%
Gui, Add, CheckBox, x138 y298 w315 h20 gCheckCompression vUseCompression Checked%LastUseCompression%, Use compression to reduce size of resulting exe
Gui, Add, CheckBox, x138 y320 w315 h20 gCheckCompression vUseMpress Checked%LastUseMPRESS%, Use MPRESS (if present) to compress resulting exe
Gui, Add, Button, x258 y351 w75 h28 +Default gConvert, > &Convert <
Gui, Add, Statusbar,, Ready
if !A_IsCompiled
	Gui, Add, Pic, x40 y5 +0x801000, %A_ScriptDir%\logo.gif
else
	gosub AddPicture
Gui, Show, w594 h405, Ahk2Exe for AutoHotkey v%A_AhkVersion% -- Script to EXE Converter
return

CheckCompression:
Gui,Submit,NoHide
If (A_GuiControl="UseCompression" && %A_GuiControl%)
	GuiControl,,UseMPress,0
else if (A_GuiControl="UseMPress" && %A_GuiControl%)
	GuiControl,,UseCompression,0
Return

GuiClose:
Gui, Submit
gosub SaveSettings
ExitApp

GuiDropFiles:
if A_EventInfo > 2
	Util_Error("You cannot drop more than one file into this window!")
GuiControl,, AhkFile, %A_GuiEvent%
return

AddPicture:
; Code based on http://www.autohotkey.com/forum/viewtopic.php?p=147052
Gui, Add, Text, x40 y5 +0x80100E hwndhPicCtrl

hRSrc := DllCall("FindResource", "ptr", 0, "str", "LOGO.GIF", "ptr", 10, "ptr")
sData := DllCall("SizeofResource", "ptr", 0, "ptr", hRSrc, "uint")
hRes  := DllCall("LoadResource", "ptr", 0, "ptr", hRSrc, "ptr")
pData := DllCall("LockResource", "ptr", hRes, "ptr")
hGlob := DllCall("GlobalAlloc", "uint", 2, "uint", sData, "ptr") ; 2=GMEM_MOVEABLE
pGlob := DllCall("GlobalLock", "ptr", hGlob, "ptr")
DllCall("msvcrt\memcpy", "ptr", pGlob, "ptr", pData, "uint", sData, "CDecl")
DllCall("GlobalUnlock", "ptr", hGlob)
DllCall("ole32\CreateStreamOnHGlobal", "ptr", hGlob, "int", 1, "ptr*", pStream)

hGdip := DllCall("LoadLibrary", "str", "gdiplus")
VarSetCapacity(si, 16, 0), NumPut(1, si, "UChar")
DllCall("gdiplus\GdiplusStartup", "ptr*", gdipToken, "ptr", &si, "ptr", 0)
DllCall("gdiplus\GdipCreateBitmapFromStream", "ptr", pStream, "ptr*", pBitmap)
DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "ptr", pBitmap, "ptr*", hBitmap, "uint", 0)
SendMessage, 0x172, 0, hBitmap,, ahk_id %hPicCtrl% ; 0x172=STM_SETIMAGE, 0=IMAGE_BITMAP

DllCall("gdiplus\GdipDisposeImage", "ptr", pBitmap)
DllCall("gdiplus\GdiplusShutdown", "ptr", gdipToken)
DllCall("FreeLibrary", "ptr", hGdip)
ObjRelease(pStream)
return

Never:
FileInstall, logo.gif, NEVER
return

BuildBinFileList:
BinFiles := ["AutoHotkeySC.bin"]
BinNames = (Default)
Loop, %A_ScriptDir%\..\*.bin,0,1
{
	SplitPath, A_LoopFileFullPath,,d,, n
	FileGetVersion, v, %A_LoopFileFullPath%
	; Listvars
	; MsgBox % SubStr(d,StrLen(A_ScriptDir)+2)
	; If (d:=SubStr(d,StrLen(A_ScriptDir)+2))
		; BinFiles._Insert(d "\" n ".bin")
	; else 
	BinFiles._Insert(A_LoopFileFullPath)
	BinNames .= "|v" v " " n ".bin (..\" SubStr(d,InStr(d,"\",1,0)+1) ")"
}
Loop, %A_ScriptDir%\..\*.exe,0,1
{
  SplitPath, A_LoopFileFullPath,,d,, n
	FileGetVersion, v, %A_LoopFileFullPath%
	; If (d:=SubStr(d,StrLen(A_ScriptDir)+2))
		; BinFiles._Insert(d "\" n ".exe")
	; else 
	BinFiles._Insert(A_LoopFileFullPath)
	BinNames .= "|v" v " " n ".exe" " (..\" SubStr(d,InStr(d,"\",1,0)+1) ")"
}
Loop, %A_ScriptDir%\..\*.dll,0,1
{
  SplitPath, A_LoopFileFullPath,,d,, n
	FileGetVersion, v, %A_LoopFileFullPath%
	; If (d:=SubStr(d,StrLen(A_ScriptDir)+2))
		; BinFiles._Insert(d "\" n ".dll")
	; else 
	BinFiles._Insert(A_LoopFileFullPath)
	BinNames .= "|v" v " " n ".dll" " (..\" SubStr(d,InStr(d,"\",1,0)+1) ")"
}

return

FindBinFile(name)
{
	global BinFiles
	for k,v in BinFiles
		if (v = name)
			return k
	return 1
}

CLIMain:
Error_ForceExit := true

p := []
Loop, %0%
{
	if %A_Index% = /NoDecompile
		Util_Error("Error: /NoDecompile is not supported.")
	else p._Insert(%A_Index%)
}

if Mod(p._MaxIndex(), 2)
	goto BadParams

Loop, % p._MaxIndex() // 2
{
	p1 := p[2*(A_Index-1)+1]
	p2 := p[2*(A_Index-1)+2]
	
	if p1 not in /in,/out,/icon,/pass,/bin,/mpress
		goto BadParams
	
	if p1 = /pass
		Util_Error("Error: Password protection is not supported.")
	
	if p2 =
		goto BadParams
	
	StringTrimLeft, p1, p1, 1
	gosub _Process%p1%
}

if !AhkFile
	goto BadParams

if !IcoFile
	IcoFile := LastIcon

if !BinFile
	BinFile := A_ScriptDir "\" LastBinFile

if UseMPRESS =
	UseMPRESS := LastUseMPRESS

CLIMode := true
gosub ConvertCLI
ExitApp

BadParams:
Util_Info("Command Line Parameters:`n`n" A_ScriptName " /in infile.ahk [/out outfile.exe] [/icon iconfile.ico] [/bin AutoHotkeySC.bin]")
ExitApp

_ProcessIn:
AhkFile := p2
return

_ProcessOut:
ExeFile := p2
return

_ProcessIcon:
IcoFile := p2
return

_ProcessBin:
CustomBinFile := true
BinFile := p2
return

_ProcessMPRESS:
UseMPRESS := p2
return

BrowseAhk:
Gui, +OwnDialogs
FileSelectFile, ov, 1, %LastScriptDir%, Open, AutoHotkey files (*.ahk)
if ErrorLevel
	return
GuiControl,, AhkFile, %ov%
return

BrowseExe:
Gui, +OwnDialogs
FileSelectFile, ov, S16, %LastExeDir%, Save As, Executable files (*.exe;*.dll)
if ErrorLevel
	return
GuiControl,, ExeFile, %ov%
return

BrowseIco:
Gui, +OwnDialogs
FileSelectFile, ov, 1, %LastIconDir%, Open, Icon files (*.ico)
if ErrorLevel
	return
GuiControl,, IcoFile, %ov%
return

DefaultIco:
GuiControl,, IcoFile
return

Convert:
Gui, +OwnDialogs
Gui, Submit, NoHide
BinFile := BinFiles[BinFileId]
ConvertCLI:
AhkCompile(AhkFile, ExeFile, IcoFile, BinFile, UseMpress,UseCompression)
if !CLIMode
	Util_Info("Conversion complete.")
else
	FileAppend, Successfully compiled: %ExeFile%`n, *
return

LoadSettings:
RegRead, LastScriptDir, HKCU, Software\AutoHotkey\Ahk2Exe, LastScriptDir
RegRead, LastExeDir, HKCU, Software\AutoHotkey\Ahk2Exe, LastExeDir
RegRead, LastIconDir, HKCU, Software\AutoHotkey\Ahk2Exe, LastIconDir
RegRead, LastIcon, HKCU, Software\AutoHotkey\Ahk2Exe, LastIcon
RegRead, LastBinFile, HKCU, Software\AutoHotkey\Ahk2Exe, LastBinFile
RegRead, LastUseCompression, HKCU, Software\AutoHotkey\Ahk2Exe, LastUseCompression
RegRead, LastUseMPRESS, HKCU, Software\AutoHotkey\Ahk2Exe, LastUseMPRESS
if LastBinFile =
	LastBinFile = AutoHotkeySC.bin
if LastUseMPRESS
	LastUseMPRESS := true
return

SaveSettings:
SplitPath, AhkFile,, AhkFileDir
if ExeFile
	SplitPath, ExeFile,, ExeFileDir
else
	ExeFileDir := LastExeDir
if IcoFile
	SplitPath, IcoFile,, IcoFileDir
else
	IcoFileDir := ""
RegWrite, REG_SZ, HKCU, Software\AutoHotkey\Ahk2Exe, LastScriptDir, %AhkFileDir%
RegWrite, REG_SZ, HKCU, Software\AutoHotkey\Ahk2Exe, LastExeDir, %ExeFileDir%
RegWrite, REG_SZ, HKCU, Software\AutoHotkey\Ahk2Exe, LastIconDir, %IcoFileDir%
RegWrite, REG_SZ, HKCU, Software\AutoHotkey\Ahk2Exe, LastIcon, %IcoFile%
RegWrite, REG_SZ, HKCU, Software\AutoHotkey\Ahk2Exe, LastUseCompression, %UseCompression%
RegWrite, REG_SZ, HKCU, Software\AutoHotkey\Ahk2Exe, LastUseMPRESS, %UseMPRESS%
if !CustomBinFile
	RegWrite, REG_SZ, HKCU, Software\AutoHotkey\Ahk2Exe, LastBinFile, % BinFiles[BinFileId]
return

Help:
helpfile = %A_ScriptDir%\..\AutoHotkey.chm
IfNotExist, %helpfile%
	Util_Error("Error: cannot find AutoHotkey help file!")

VarSetCapacity(ak, ak_size := 8+5*A_PtrSize+4, 0) ; HH_AKLINK struct
NumPut(ak_size, ak, 0, "UInt")
name = Ahk2Exe
NumPut(&name, ak, 8)
DllCall("hhctrl.ocx\HtmlHelp", "ptr", GuiHwnd, "str", helpfile, "uint", 0x000D, "ptr", &ak) ; 0x000D: HH_KEYWORD_LOOKUP
return

About:
MsgBox, 64, About Ahk2Exe,
(
Ahk2Exe - Script to EXE Converter

Original version:
  Copyright ©1999-2003 Jonathan Bennett & AutoIt Team
  Copyright ©2004-2009 Chris Mallet
  Copyright ©2008-2011 Steve Gray (Lexikos)

Script rewrite:
  Copyright ©2011-2012 fincs
)
return

Util_Status(s)
{
	SB_SetText(s)
}

Util_Error(txt, doexit=1)
{
	global CLIMode, Error_ForceExit, ExeFileTmp
	
	if ExeFileTmp && FileExist(ExeFileTmp)
	{
		FileDelete, %ExeFileTmp%
		ExeFileTmp =
	}
	
	Util_HideHourglass()
	MsgBox, 16, Ahk2Exe Error, % txt
	
	if CLIMode
		FileAppend, Failed to compile: %ExeFile%`n, *
	
	Util_Status("Ready")
	
	if doexit
		if !Error_ForceExit
			Exit
		else
			ExitApp
}

Util_Info(txt)
{
	MsgBox, 64, Ahk2Exe, % txt
}

Util_DisplayHourglass()
{
	DllCall("SetCursor", "ptr", DllCall("LoadCursor", "ptr", 0, "ptr", 32514, "ptr"))
}

Util_HideHourglass()
{
	DllCall("SetCursor", "ptr", DllCall("LoadCursor", "ptr", 0, "ptr", 32512, "ptr"))
}

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__      __      ______
\ \    / /     |___  /           V A R Z  >>>  N A T I V E  D A T A  C O M P R E S S I O N
 \ \  / /_ _ _ __ / /            http://www.autohotkey.com/community/viewtopic.php?t=45559
  \ \/ / _` | '__/ /             Author: Suresh Kumar A N  (email: arian.suresh@gmail.com)
   \  / (_| | | / /__            Ver 2.0 | Created 19-Jun-2009 | Last Modified 27-Sep-2012
    \/ \__,_|_|/_____|           > http://tinyurl.com/skanbox/AutoHotkey/VarZ/2.0/VarZ.ahk
                                                  |
 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
*/

VarZ_Compress( ByRef Data, DataSize, CompressionMode = 0x102,RECURSIVE = 0 ) { ; 0x100 = COMPRESSION_ENGINE_MAXIMUM / 0x2 = COMPRESSION_FORMAT_LZNT1

 Static STATUS_SUCCESS := 0x0,   HdrSz := 18

 If ( NumGet( Data, "UInt" ) = 0x005F5A4C )                           ; "LZ_" + Chr(0)
    Return 0, ErrorLevel := -1                                ; already compressed

 DllCall( "ntdll\RtlGetCompressionWorkSpaceSize"
        , UInt,  CompressionMode
        , UIntP, CompressBufferWorkSpaceSize
        , UIntP, CompressFragmentWorkSpaceSize )

 VarSetCapacity( CompressBufferWorkSpace, CompressBufferWorkSpaceSize )

 TempSize := VarSetCapacity( TempData, DataSize )             ; Workspace for Compress

 NTSTATUS := DllCall( "ntdll\RtlCompressBuffer"
                    , UShort,  CompressionMode
                    , PTR,  &Data                            ; Uncompressed data
                    , UInt,  DataSize
                    , PTR,  &TempData                        ; Compressed data
                    , UInt,  TempSize
                    , UInt,  CompressFragmentWorkSpaceSize
                    , UIntP, FinalCompressedSize              ; Compressed data size
                    , PTR,  &CompressBufferWorkSpace
                          ,  UInt )

 If ( NTSTATUS <> STATUS_SUCCESS  ||  FinalCompressedSize + HdrSz > DataSize )
    Return 0, ErrorLevel := ( NTSTATUS ? NTSTATUS : -2 )      ; unable to compress data
 
 VarSetCapacity( Data, FinalCompressedSize + HdrSz, 0 )       ; Renew variable capacity

 NumPut( 0x005F5A4C, Data, "UInt" )                            ; "LZ_" + Chr(0)
 Numput( CompressionMode, Data, 8, "UShort" )                 ; actually "UShort"
 NumPut( DataSize, Data, 10, "UInt" )                          ; Uncompressed data size
 NumPut( FinalCompressedSize, Data, 14, "UInt" )               ; Compressed data size

 DllCall( "RtlMoveMemory", PTR,  &Data + HdrSz               ; Target pointer
                         , PTR,  &TempData                   ; Source pointer
                         , PTR,  FinalCompressedSize )       ; Data length in bytes

 DllCall( "shlwapi\HashData", PTR,  &Data + 8                ; Read data pointer
                            , UInt,  FinalCompressedSize + 10 ; Read data size
                            , PTR,  &Data + 4                ; Write data pointer
                            , UInt,  4 )                      ; Write data length in bytes
 If !RECURSIVE && NumPut( 0x315F5A4C, Data, "UInt" ) ; Try extra compression
  If MultiCompressedSize:= VarZ_Compress(Data,FinalCompressedSize + HdrSz,CompressionMode,1)
   return MultiCompressedSize
  else NumPut( 0x005F5A4C, Data, "UInt" )
 Return FinalCompressedSize + HdrSz
}

VarZ_Uncompress( ByRef D ) {  ; Shortcode version of VarZ_Decompress() of VarZ 2.0 wrapper
; VarZ 2.0 by SKAN, 27-Sep-2012. http://www.autohotkey.com/community/viewtopic.php?t=45559
 IfNotEqual, A_Tab, % ID:=NumGet(D,"UInt"), IfNotEqual, ID, 0x5F5A4C,  Return 0, ErrorLevel := -1
 savedHash := NumGet(D,4,"UInt"), TZ := NumGet(D,10,"UInt"), DZ := NumGet(D,14,"UInt")
 DllCall( "shlwapi\HashData", UInt,&D+8, UInt,DZ+10, UIntP,Hash, UInt,4 )
 IfNotEqual, Hash, %savedHash%, Return 0, ErrorLevel := -2
 VarSetCapacity( TD,TZ,0 ), NTSTATUS := DllCall( "ntdll\RtlDecompressBuffer", UShort
 , NumGet(D,8,"UShort"), PTR, &TD, UInt,TZ, PTR,&D+18, UInt,DZ, UIntP,Final, UInt )
 IfNotEqual, NTSTATUS, 0, Return 0, ErrorLevel := NTSTATUS
 VarSetCapacity( D,Final,0 ), DllCall( "RtlMoveMemory", PTR,&D, PTR,&TD, PTR,Final )
 If NumGet(D,"UInt")=0x315F5A4C && NumPut(0x005F5A4C,D,"UInt")
  Return VarZ_Uncompress( D )
Return Final, VarSetCapacity( D,-1 )
}

;- -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - --

VarZ_Load( ByRef Data, SrcFile ) {
 FileGetSize, DataSize, %SrcFile%
 If !ErrorLevel {
  FileRead, Data, *c %SrcFile%
  If !ErrorLevel
   Return DataSize
 }
}

;- -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - --

VarZ_Save( ByRef Data, DataSize, TrgFile ) {
 hFile :=  DllCall( "_lcreat", ( A_IsUnicode ? "AStr" : "Str" ),TrgFile, UInt,0,PTR )
 IfLess, hFile, 1, Return "", ErrorLevel := 1
 nBytes := DllCall( "_lwrite", PTR,hFile, PTR,&Data, UInt,DataSize, UInt )
 DllCall( "_lclose", PTR,hFile )
 Return nBytes
}
