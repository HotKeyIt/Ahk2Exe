;
; File encoding:  UTF-8
;
; Script description:
;	Ahk2Exe - AutoHotkey Script Compiler
;	Written by fincs - Interface based on the original Ahk2Exe
;

;@Ahk2Exe-SetName         Ahk2Exe
;@Ahk2Exe-SetDescription  AutoHotkey Script Compiler
;@Ahk2Exe-SetCopyright    Copyright (c) since 2004
;@Ahk2Exe-SetCompanyName  AutoHotkey
;@Ahk2Exe-SetOrigFilename Ahk2Exe.ahk
;@Ahk2Exe-SetMainIcon     Ahk2Exe.ico

#NoTrayIcon
#SingleInstance Off
#Include %A_ScriptDir%
#Include Compiler.ahk

TraySetIcon(A_AhkPath,2)

global DEBUG := !A_IsCompiled, CLIMode:=0

UseEncrypt:=UseInclude := UseIncludeResource := Error_ForceExit := CustomBinFile := 0
AhkFile:=ExeFile:=IcoFile:=LastAhkFile:=LastExeFile:=LastIcoFile:=""
BinNames := ["Please Select"]

BuildBinFileList()
LoadSettings()
ParseCmdLine()

if CLIMode
{
	If UseEncrypt && !UsePassword
  {
    FileAppend "Error compiling`, no password supplied: " ExeFile "`n", "*"
    return
  }
  AhkCompile(AhkFile, ExeFile, IcoFile, BinFile, UseMpress, UseCompression, UseInclude, UseIncludeResource, UseEncrypt?UsePassword:"")
  FileAppend "Successfully compiled: " ExeFile "`n", "*"
	ExitApp
}

AhkFile := LastAhkFile,ExeFile := LastExeFile,IcoFile := LastIconFile,BinFileId := FindBinFile(LastBinFile)

#include *i __debug.ahk
FileMenu:=Menu.New(),HelpMenu:=Menu.New(),Bar:=MenuBar.New()
FileMenu.Add("&Convert", "Convert")
FileMenu.Add()
FileMenu.Add("E&xit`tAlt+F4", "GuiClose")
HelpMenu.Add("&Help", "Help")
HelpMenu.Add()
HelpMenu.Add("&About", "About")
Bar.Add("&File", FileMenu)
Bar.Add("&Help", HelpMenu)
Ahk2Exe :=Gui.New("+Resize +MinSize594X400")
ToolTip:=TT(Ahk2Exe.Hwnd)
Ahk2Exe.OnEvent("Close","GuiClose")
Ahk2Exe.OnEvent("DropFiles","GuiDropFiles")
Ahk2Exe.MenuBar := Bar
Ahk2Exe.AddLink "x287 y10",
(
"©2004-2009 Chris Mallet
©2008-2011 Steve Gray (Lexikos)
©2011-" A_Year "  fincs
©2012-" A_Year " HotKeyIt
<a href=`"http://ahkscript.org`">http://ahkscript.org</a>
Note: Compiling does not guarantee source code protection."
)
Ahk2Exe.AddText "x11 y97 w570 h2 +0x1007"
Ahk2Exe.SetFont("Bold")
Ahk2Exe.AddGroupBox "x11 y104 w570 h81 aw1", "Required Parameters"
Ahk2Exe.SetFont(,"Normal")
Ahk2Exe.AddText "x17 y126", "&Source (script file)"
GuiBrowseAhk:=Ahk2Exe.AddEdit("x147 y121 w315 h23 aw1 +ReadOnly -WantTab vAhkFile", AhkFile)
ToolTip.Add("Edit1","Select path of AutoHotkey Script to compile")
(GuiButton2:=Ahk2Exe.AddButton("x465 y121 w53 h23 ax1", "&Browse")).OnEvent("Click","BrowseAhk")
ToolTip.Add("Button2","Select path of AutoHotkey Script to compile")
Ahk2Exe.AddText "x17 y155", "&Destination (.exe file)"
GuiBrowseExe:=Ahk2Exe.AddEdit("x147 y151 w315 h23 awr aw1 +ReadOnly -WantTab vExeFile", Exefile)
ToolTip.Add("Edit2","Select path to resulting exe / dll")
(GuiButton3:=Ahk2Exe.AddButton("x465 y151 w53 h23 axr ax1", "B&rowse")).OnEvent("Click","BrowseExe")
ToolTip.Add("Button3","Select path to resulting exe / dll")
Ahk2Exe.SetFont("Bold")
Ahk2Exe.AddGroupBox "x11 y187 w570 h148 awr aw1", "Optional Parameters"
Ahk2Exe.SetFont(,"Normal")
Ahk2Exe.AddText "x18 y208", "Custom Icon (.ico file)"
GuiBrowseIco:=Ahk2Exe.AddEdit("x147 y204 w315 h23 awr aw1 +ReadOnly vIcoFile", IcoFile)
ToolTip.Add("Edit3","Select Icon to use in resulting exe / dll")
(GuiButton4:=Ahk2Exe.AddButton("x465 y204 w53 h23 axr ax1", "Br&owse")).OnEvent("Click","BrowseIco")
ToolTip.Add("Button5","Select Icon to use in resulting exe / dll")
Ahk2Exe.AddButton("x519 y204 w53 h23 axr ax1", "D&efault").OnEvent("Click","DefaultIco")
ToolTip.Add("Button6","Use default Icon")
Ahk2Exe.AddText "x18 y237 awr aw1", "Base File (.bin)"
Ahk2Exe.AddDDL "x147 y233 w425 h23 awr aw1 R10 AltSubmit vBinFileId Choose" BinFileId, BinNames
ToolTip.Add("ComboBox1","Select AutoHotkey binary file to use for compilation")
(GuiUseCompression:=Ahk2Exe.AddCheckBox("x10 y260 w430 h20 vUseCompression Checked" LastUseCompression, "Use compression to reduce size of resulting executable")).OnEvent("Click","CheckCompression")
ToolTip.Add("Button7","Compress all resources")
(GuiUseEncrypt:=Ahk2Exe.AddCheckBox("x10 y282 w280 h20 vUseEncrypt Checked" LastUseEncrypt, "Encrypt. Enter password used in executable:")).OnEvent("Click","CheckCompression")
ToolTip.Add("Button8","Use AES encryption for resources (requires a Password)")
Ahk2Exe.AddEdit "x312 y282 w150 h20 Password vUsePassword", "AutoHotkey"
ToolTip.Add("Edit4","Enter password for encryption (default = AutoHotkey).`nAutoHotkey binary must be using this password internally")
(GuiUseMPRESS:=Ahk2Exe.AddCheckBox("x10 y304 w330 h20 vUseMpress Checked" LastUseMPRESS, "Use MPRESS (if present) to compress resulting exe")).OnEvent("Click","CheckCompression")
ToolTip.Add("Button9","MPRESS makes executables smaller and decreases start time when loaded from slow media")
Ahk2Exe.AddButton("x235 y338 w160 h28 +Default axr ax0.5", "> &Compile Executable <").OnEvent("Click","Convert")
ToolTip.Add("Button10","Convert script to executable file")
GuiStatusBar:=Ahk2Exe.AddStatusBar(, "Ready")
;@Ahk2Exe-IgnoreBegin
Ahk2Exe.AddPic "x30 y5 +0x801000", A_ScriptDir "\logo.png"
;@Ahk2Exe-IgnoreEnd
/*@Ahk2Exe-Keep
AddPicture()
*/
Ahk2Exe.Title:="Ahk2Exe for AutoHotkey v" A_AhkVersion " -- Script to EXE Converter"
Ahk2Exe.Show "w594 h400"
GuiButton2.Focus()
Return:
return

CheckCompression(c,p*){
  global
  GuiSubMit := c.Gui.SubMit(0)
  If c.name="UseCompression" && !GuiSubMit.UseCompression{
    GuiUseEncrypt.value := false
    GuiUseCompression.value := false
  } else If c.Name="UseEncrypt" && GuiSubMit.UseEncrypt{
    GuiUseCompression := true
  }
}

GuiClose(p*){
  global
  guiSubMit:=Ahk2Exe.SubMit(0)
  SplitPath guiSubMit.AhkFile,, AhkFileDir
  if guiSubMit.ExeFile
    SplitPath guiSubMit.ExeFile,, ExeFileDir
  else
    ExeFileDir := LastExeDir
  if guiSubMit.IcoFile
    SplitPath guiSubMit.IcoFile,, IcoFileDir
  else
    IcoFileDir := ""
  try RegWrite AhkFileDir, "REG_SZ", "HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe_H", "LastScriptDir"
  try RegWrite ExeFileDir, "REG_SZ", "HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe_H", "LastExeDir"
  try RegWrite IcoFileDir, "REG_SZ", "HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe_H", "LastIconDir"
  try RegWrite guiSubMit.AhkFile, "REG_SZ", "HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe_H", "LastAhkFile"
  try RegWrite guiSubMit.ExeFile, "REG_SZ", "HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe_H", "LastExeFile"
  try RegWrite guiSubMit.IcoFile, "REG_SZ", "HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe_H", "LastIconFile"
  try RegWrite guiSubMit.UseCompression, "REG_SZ", "HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe_H", "LastUseCompression"
  try RegWrite guiSubMit.UseMPRESS, "REG_SZ", "HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe_H", "LastUseMPRESS"
  try RegWrite guiSubMit.UseEncrypt, "REG_SZ", "HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe_H", "LastUseEncrypt"
  if !CustomBinFile
    RegWrite BinFiles[guiSubMit.BinFileId], "REG_SZ", "HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe_H", "LastBinFile"
  ExitApp
}

GuiDropFiles(gui,ctrl,file,p*){
  global
  if file.Length > 2
    Util_Error("You cannot drop more than one file into this window!")
  SplitPath file[1],,, dropExt
  if (dropExt = "ahk")
    GuiBrowseAhk.text :=file[1]
  else if (dropExt = "ico")
    GuiBrowseIco.text :=file[1]
  else if InStr(".exe.dll.","." dropExt ".")
    GuiBrowseExe.text := file[1]
}

/*@Ahk2Exe-Keep

AddPicture(){
  ; Code based on http://www.autohotkey.com/forum/viewtopic.php?p=147052
  GuiPicCtrl:=Ahk2Exe.AddText("x40 y5 +0x80100E")

  ;@Ahk2Exe-AddResource logo.png
  hRSrc := FindResource(0, "LOGO.PNG", 10)
  sData := SizeofResource(0, hRSrc)
  hRes  := LoadResource(0, hRSrc)
  pData := LockResource(hRes)
  If NumGet(pData,"UInt")=0x04034b50
    sData:=UnZipRawMemory(pData,sData,resLogo),pData:=&resLogo
  hGlob := GlobalAlloc(2, sData) ; 2=GMEM_MOVEABLE
  pGlob := GlobalLock(hGlob)
  #DllImport memcpy,msvcrt\memcpy,ptr,,ptr,,ptr,,CDecl
  memcpy(pGlob, pData, sData)
  GlobalUnlock(hGlob)
  CreateStreamOnHGlobal(hGlob, 1, getvar(pStream:=0))

  hGdip := LoadLibrary("gdiplus")
  si:=BufferAlloc(16, 0), NumPut("UChar", 1, si)
  GdiplusStartup(getvar(gdipToken:=0), si.Ptr)
  GdipCreateBitmapFromStream(pStream, getvar(pBitmap:=0))
  GdipCreateHBITMAPFromBitmap(pBitmap, getvar(hBitmap:=0))
  SendMessage 0x172, 0, hBitmap,, "ahk_id " GuiPicCtrl.hwnd ; 0x172=STM_SETIMAGE, 0=IMAGE_BITMAP
  GuiPicCtrl.Move("w240 h78")

  GdipDisposeImage(pBitmap)
  GdiplusShutdown(gdipToken)
  FreeLibrary(hGdip)
  ObjRelease(pStream)
}

*/

BuildBinFileList(){
  global
  BinFiles := ["Please Select"]
  ; If FileExist(A_AhkDir "\AutoHotkeySC.bin"){
    ; BinFiles.1:=A_AhkDir "\AutoHotkeySC.bin"
    ; SplitPath BinFiles.1,,d,, n
    ; v:=FileGetVersion(BinFiles.1)
    ; BinNames.Push("v" v " " n ".bin (..\" SubStr(d,InStr(d,"\",1,-1)+1) ")")
  ; }

  Loop Files, A_ScriptDir "\..\*.bin","FR"
  {
    SplitPath A_LoopFileFullPath,,d,, n
    v :=FileGetVersion(A_LoopFileFullPath)
    BinFiles.Push(A_LoopFileFullPath)
    BinNames.Push("v" v " " n ".bin (" StrReplace(A_LoopFileDir,A_AhkDir "\")) ;SubStr(d,InStr(d,"\",1,-1)+1) ")")
  }
  Loop Files, A_ScriptDir "\..\*.exe","FR"
  {
    SplitPath A_LoopFileFullPath,,d,, n
    v:=FileGetVersion(A_LoopFileFullPath)
    If !InStr(FileGetInfo(A_LoopFileFullPath,"FileDescription"),"AutoHotkey")
      continue
    BinFiles.Push(A_LoopFileFullPath)
    BinNames.Push("v" v " " n ".exe" " (" StrReplace(A_LoopFileDir,A_AhkDir "\")) ;SubStr(d,InStr(d,"\",1,-1)+1) ")")
  }
  Loop Files, A_ScriptDir "\..\*.dll","FR"
  {
    SplitPath A_LoopFileFullPath,,d,, n
    v:=FileGetVersion(A_LoopFileFullPath)
    If !InStr(FileGetInfo(A_LoopFileFullPath,"FileDescription"),"AutoHotkey")
      continue
    BinFiles.Push(A_LoopFileFullPath)
    BinNames.Push("v" v " " n ".dll" " (" StrReplace(A_LoopFileDir,A_AhkDir "\")) ;SubStr(d,InStr(d,"\",1,-1)+1) ")")
  }
}

FindBinFile(name)
{
	global BinFiles
	for k,v in BinFiles
		if (v = name)
			return k
	return 1
}

ParseCmdLine(){
  global
  if !A_Args.Length
    return

  Error_ForceExit := true

  p := []
  Loop A_Args.Length
  {
    ; if (A_Args[A_Index] = "/NoDecompile")
      ; Util_Error("Error: /NoDecompile is not supported.")
    ; else 
    p.Push(A_Args[A_Index])
  }

  if Mod(p.Length, 2)
    MsgBox("Command Line Parameters:`n`n%A_ScriptName% /in infile.ahk [/out outfile.exe] [/icon iconfile.ico] [/bin AutoHotkeySC.bin]", "Ahk2Exe", 64),ExitApp()

  Loop p.Length // 2
  {
    p1 := p[2*(A_Index-1)+1]
    p2 := p[2*(A_Index-1)+2]
    
    if !InStr(",/in,/out,/icon,/pass,/bin,/mpress,","," p1 ",")
      MsgBox("Command Line Parameters:`n`n%A_ScriptName% /in infile.ahk [/out outfile.exe] [/icon iconfile.ico] [/bin AutoHotkeySC.bin]", "Ahk2Exe", 64),ExitApp()
    
    ;~ if (p1 = "/pass")
      ;~ Util_Error("Error: Password protection is not supported.")
    
    if (p2 = "")
      MsgBox("Command Line Parameters:`n`n%A_ScriptName% /in infile.ahk [/out outfile.exe] [/icon iconfile.ico] [/bin AutoHotkeySC.bin]", "Ahk2Exe", 64),ExitApp()
    
    %"_Process" SubStr(p1,2)%()
  }

  if !AhkFile
    MsgBox("Command Line Parameters:`n`n%A_ScriptName% /in infile.ahk [/out outfile.exe] [/icon iconfile.ico] [/bin AutoHotkeySC.bin]", "Ahk2Exe", 64),ExitApp()

  if !IcoFile
    IcoFile := LastIconFile

  if !BinFile
    BinFile := LastBinFile

  if (UseMPRESS = "")
    UseMPRESS := LastUseMPRESS

  global CLIMode := true
}

_ProcessIn(){
  global
  AhkFile := p2
}

_ProcessOut(){
  global
  ExeFile := p2
}

_ProcessIcon(){
  global
  IcoFile := p2
}

_ProcessBin(){
  global
  CustomBinFile := true,BinFile := p2
}

_ProcessPass(){
  global
  UseEncrypt := true,UseCompression := true,UsePassword := p2
}

_ProcessNoDecompile(){
  global
  UseEncrypt := true,UseCompression := true
}

_ProcessMPRESS(){
  global
  UseMPRESS := p2
}

BrowseAhk(p*){
  global
  ov := FileSelect(1, LastScriptDir, "Open", "AutoHotkey files (*.ahk)")
  if !ov
    return
  GuiBrowseAhk.text:=ov
}

BrowseExe(p*){
  global
  ov :=FileSelect("S16", LastExeDir, "Save As", "Executable files (*.exe;*.dll)")
  if !ov
    return
  SplitPath ov,,, ovExt
  if !StrLen(ovExt) ;~ append a default file extension is none specified
    ov .= ".exe"
  GuiBrowseExe.text:=ov
}

BrowseIco(p*){
  global
  ov:=FileSelect(1, LastIconDir, "Open", "Icon files (*.ico)")
  if !ov
    return
  GuiBrowseIco.text:= ov
}

DefaultIco(p*){
  global
  GuiBrowseIco.text :=IcoFile
}

Convert(p*){
  global
  guiSubMit := Ahk2Exe.SubMit(0)
  BinFile := BinFiles[guiSubMit.BinFileId]
  
  If guiSubMit.UseEncrypt && !guiSubMit.UsePassword
  {
    MsgBox "Error compiling`, no password supplied: " ExeFile, "Ahk2Exe", 64
    return
  }
  ; else If UseEncrypt && SubStr(BinFile,-4)!=".bin"
  ; {
    ; if !CLIMode
      ; MsgBox, 64, Ahk2Exe, Resulting exe will not be protected properly, use AutoHotkeySC.bin file to have more secure protection.
    ; else
      ; FileAppend, Warning`, Resulting exe will not be protected properly`, use AutoHotkeySC.bin file to have more secure protection.: %ExeFile%`n, *
  ; }
  AhkCompile(guiSubMit.AhkFile, guiSubMit.ExeFile, guiSubMit.IcoFile, BinFile, guiSubMit.UseMpress, guiSubMit.UseCompression, 0, 0, guiSubMit.UseEncrypt?guiSubMit.UsePassword:"")
  MsgBox "Conversion complete.", "Ahk2Exe", 64
}

LoadSettings(){
  global
  LastScriptDir:=RegRead("HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe_H", "LastScriptDir")
  LastExeDir:=RegRead("HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe_H", "LastExeDir")
  LastIconDir:=RegRead("HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe_H", "LastIconDir")
  LastAhkFile:=RegRead("HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe_H", "LastAhkFile")
  LastExeFile:=RegRead("HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe_H", "LastExeFile")
  LastIconFile:=RegRead("HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe_H", "LastIconFile")
  LastBinFile:=RegRead("HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe_H", "LastBinFile")
  LastUseCompression:=RegRead("HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe_H", "LastUseCompression")
  LastUseMPRESS:=RegRead("HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe_H", "LastUseMPRESS")
  LastUseEncrypt:=RegRead("HKEY_CURRENT_USER\Software\AutoHotkey\Ahk2Exe_H", "LastUseEncrypt")

  if !FileExist(LastAhkFile)
    LastahkFile := ""
  if !FileExist(LastIconFile)
    LastIconFile := ""
  if (LastBinFile = "") || !FileExist(LastBinFile)
    LastBinFile := "..\x64w\AutoHotkey.exe"

  if LastUseMPRESS
    LastUseMPRESS := true
}

Help(p*){
  global Ahk2Exe
  If !FileExist(helpfile := A_ScriptDir "\..\AutoHotkey.chm")
    Util_Error("Error: cannot find AutoHotkey help file!")

  #DllImport HtmlHelp,hhctrl.ocx\HtmlHelp,PTR,,Str,,UInt,,PTR,
  ak:=BufferAlloc(ak_size := 8+5*A_PtrSize+4, 0) ; HH_AKLINK struct
  ,NumPut("UInt", ak_size, ak, 0),name := "Ahk2Exe",NumPut("PTR",StrPtr(name), ak, 8)
  ,HtmlHelp(Ahk2Exe.Hwnd, helpfile, 0x000D, ak) ; 0x000D: HH_KEYWORD_LOOKUP
}

About(p*){
  MsgBox "
  (Q
  Ahk2Exe - Script to EXE Converter

  Original version:
    Copyright @1999-2003 Jonathan Bennett & AutoIt Team
    Copyright @2004-2009 Chris Mallet
    Copyright @2008-2011 Steve Gray (Lexikos)

  Script rewrite:
    Copyright @2011-" A_Year " fincs
    Copyright @2012-" A_Year " HotKeyIt
  )", "About Ahk2Exe", 64
}

Util_Error(txt, doexit := 1, extra := "")
{
	global CLIMode, Error_ForceExit, ExeFileTmp, GuiStatusBar, ExeFile
	
	if ExeFileTmp && FileExist(ExeFileTmp)
	{
		FileDelete ExeFileTmp
		ExeFileTmp := ""
	}
	
	if extra
		txt .= "`n`n" extra
	
	SetCursor(LoadCursor(0, 32512)) ;Util_HideHourglass()
	MsgBox txt, "Ahk2Exe Error", 16
	
	if CLIMode
		FileAppend "Failed to compile: " ExeFile "`n", "*"
	else	GuiStatusBar.SetText("Ready")
	
	if doexit
		if !Error_ForceExit
			Exit
		else
			ExitApp
}
