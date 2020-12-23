#Include ScriptParser.ahk
#Include IconChanger.ahk
#Include Directives.ahk

AhkCompile(ByRef AhkFile, ExeFile := "", ByRef CustomIcon := "", BinFile := "", UseMPRESS := "",UseCompression := "", UseInclude := "", UseIncludeResource := "", UsePassword := "AutoHotkey")
{
	global ExeFileTmp, GuiStatusBar
	AhkFile := Util_GetFullPath(AhkFile)
	if (AhkFile = "")
		Util_Error("Error: Source file not specified.")
	SplitPath AhkFile,, AhkFile_Dir,, AhkFile_NameNoExt
	
	if (ExeFile = "")
		ExeFile := AhkFile_Dir "\" AhkFile_NameNoExt ".exe"
	else
		ExeFile := Util_GetFullPath(ExeFile)
	
	ExeFileTmp := ExeFile
	
	if (BinFile = "")
		BinFile := A_ScriptDir "\AutoHotkeySC.bin"
	SetCursor(LoadCursor(0, 32514)) ; Util_DisplayHourglass()
  try FileCopy(BinFile, ExeFile, 1)
  catch
		Util_Error("Error: Unable to copy AutoHotkeySC binary file to destination.")
	
	BundleAhkScript(ExeFile, AhkFile, CustomIcon, UseCompression, UsePassword)
	
	if FileExist(A_ScriptDir "\mpress.exe") && UseMPRESS
	{
		If !CLIMode
      GuiStatusBar.SetText("Compressing final executable...")
		if UseCompression ; do not compress resources
			RunWait "`"" A_ScriptDir "\mpress.exe`" -q -x -r `"" ExeFile "`"",, "Hide"
		else RunWait "`"" A_ScriptDir "\mpress.exe`" -q -x `"" ExeFile "`"",, "Hide"
	}
	
	SetCursor(LoadCursor(0, 32512)) ; Util_HideHourglass()
	If !CLIMode
      GuiStatusBar.SetText("")
}

BundleAhkScript(ExeFile, AhkFile, IcoFile := "", UseCompression := 0, UsePassword := "")
{
  global GuiStatusBar
	SplitPath AhkFile,, ScriptDir
	zip:=data:=""
	ExtraFiles := []
	,Directives := PreprocessScript(ScriptBody, AhkFile, ExtraFiles)
	,ScriptBody :=Trim(ScriptBody,"`n")
	If UseCompression {
		buf:=BufferAlloc(bufsz:=65536,00),totalsz:=0,buf1:=BufferAlloc(65536)
		Loop Parse,ScriptBody,"`n","`r"
		{
			If (A_LoopField=""){
				NumPut("Char", 10, buf.Ptr + totalsz)
				,totalsz+=1
				continue
			}
			data:=StrBuf(A_LoopField,"UTF-8")
			,zip:=UsePassword?ZipRawMemory(data,, UsePassword):ZipRawMemory(data)
			,CryptBinaryToStringA(zip, zip.size, 0x1|0x40000000, 0, getvar(cryptedsz:=0))
			,CryptBinaryToStringA(zip, zip.size, 0x1|0x40000000, buf1, getvar(cryptedsz))
			,NumPut("Char", 10, buf1.Ptr+cryptedsz)
			if (totalsz+cryptedsz+1>bufsz)
				newbuf:=BufferAlloc(bufsz*=2),RtlMoveMemory(newbuf,buf,totalsz),buf:=newbuf
			RtlMoveMemory(buf.Ptr + totalsz,buf1,cryptedsz+1)
			,totalsz+=cryptedsz+1
		}
		NumPut("UShort", 0, buf.Ptr + totalsz - 1)
		If !BinScriptBody := ZipRawMemory(buf.Ptr,totalsz,UsePassword)
			Util_Error("Error: Could not compress the source file.")
	} else
    BinScriptBody:=BufferAlloc(BinScriptBody_Len:=StrPut(ScriptBody, "UTF-8"))
    ,StrPut(ScriptBody, BinScriptBody, "UTF-8")
	
	module := BeginUpdateResource(ExeFile)
	if !module
		Util_Error("Error: Error opening the destination file.")
	
	tempWD := CTempWD.new(ScriptDir)
	dirState := ProcessDirectives(ExeFile, module, Directives, IcoFile, UseCompression, UsePassword)
	IcoFile := dirState.IcoFile
	
	if outPreproc := dirState.OutPreproc
	{
		f := FileOpen(outPreproc, "w", "UTF-8-RAW")
		f.RawWrite(BinScriptBody)
		f := ""
	}
	
	If !CLIMode
      GuiStatusBar.SetText("Adding: Master Script")
	if !UpdateResource(module, 10, "E4847ED08866458F8DD35F94B37001C0", 0x409, BinScriptBody, BinScriptBody.size)
		return (EndUpdateResource(module),Util_Error("Error adding script file:`n`n" AhkFile))
		
	for each,file in ExtraFiles
	{
		If !CLIMode
        GuiStatusBar.SetText("Adding: " file)
		resname:=StrUpper(file)
		
		If !FileExist(file)
			return (EndUpdateResource(module),Util_Error("Error adding FileInstall file:`n`n" file))
		If UseCompression{
			tempdata:=FileRead(file,"RAW")
			tempsize:=FileGetSize(file)
			If !filesize := ZipRawMemory(tempdata, tempsize, filedata)
				Util_Error("Error: Could not compress the file to: " file)
		} else {
			filedata:=FileRead(file,"RAW")
			filesize:=FileGetSize(file)
		}
		
		if !UpdateResource(module, 10, resname, 0x409, filedata, filesize)
			return (EndUpdateResource(module),Util_Error("Error adding FileInstall file:`n`n" file))
	}
	
	if !EndUpdateResource(module)
		Util_Error("Error: Error opening the destination file.")
	
	if dirState.ConsoleApp
	{
		If !CLIMode
        GuiStatusBar.SetText("Marking executable as a console application...")
		if !SetExeSubsystem(ExeFile, 3)
			Util_Error("Could not change executable subsystem!")
	}
	
	for each,cmd in dirState.PostExec
	{
		If !CLIMode
        GuiStatusBar.SetText("PostExec: " cmd)
		if ErrorLevel:=RunWait(cmd)
			Util_Error("Command failed with RC=" ErrorMessage(ErrorLevel) ":`n" cmd)
	}
}

class CTempWD
{
	__New(newWD)
	{
		this.oldWD := A_WorkingDir
		SetWorkingDir newWD
	}
	__Delete()
	{
		SetWorkingDir this.oldWD
	}
}

Util_GetFullPath(path)
{
	fullpath:=BufferAlloc(260 * 2,0)
	return GetFullPathName(path, 260, fullpath, 0) ? StrGet(fullpath) : ""
}
