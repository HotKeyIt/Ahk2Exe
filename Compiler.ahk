#Include ScriptParser.ahk
#Include IconChanger.ahk

AhkCompile(ByRef AhkFile, ExeFile:="", ByRef CustomIcon:="", BinFile:="", UseMPRESS:="",UseCompression:="")
{
	global ExeFileTmp
	AhkFile := Util_GetFullPath(AhkFile)
	if (AhkFile = "")
		Util_Error("Error: Source file not specified.")
	SplitPath,% AhkFile,, AhkFile_Dir,, AhkFile_NameNoExt
	
	if (ExeFile = "")
		ExeFile := AhkFile_Dir "\" AhkFile_NameNoExt ".exe"
	else
		ExeFile := Util_GetFullPath(ExeFile)
	
	ExeFileTmp := ExeFile
	
	if (BinFile = "")
		BinFile := A_ScriptDir "\AutoHotkeySC.bin"
	Util_DisplayHourglass()
	FileCopy, %BinFile%, %ExeFile%, 1
	if ErrorLevel
		Util_Error("Error: Unable to copy AutoHotkeySC binary file to destination.")
	
	BundleAhkScript(ExeFile, AhkFile, CustomIcon,UseCompression)
	
	if FileExist(A_ScriptDir "\mpress.exe") && UseMPRESS
	{
		Util_Status("Compressing final executable...")
		RunWait, "%A_ScriptDir%\mpress.exe" -q -x "%ExeFile%",, Hide
	}
	
	Util_HideHourglass()
	Util_Status("")
}

BundleAhkScript(ExeFile, AhkFile, IcoFile:="",UseCompression:=0)
{
	SplitPath,% AhkFile,, ScriptDir
	
	ExtraFiles := []
	PreprocessScript(ScriptBody, AhkFile, ExtraFiles)
	ScriptBody :=Trim(ScriptBody,"`n")
	StrReplace,ScriptBody,%ScriptBody%,`n,`r
	;FileDelete, %ExeFile%.ahk
	;FileAppend, % ScriptBody, %ExeFile%.ahk
	If UseCompression {
		VarSetCapacity(BinScriptBody, BinScriptBody_Len:=StrPut(ScriptBody, "UTF-8"))
		StrPut(ScriptBody, &BinScriptBody, "UTF-8")
		If !BinScriptBody_Len:=VarZ_Compress(BinScriptBody,StrPut(ScriptBody, "UTF-8")+2,0x102){
			VarSetCapacity(BinScriptBody, BinScriptBody_Len:=StrPut(ScriptBody, "UTF-8"))
			StrPut(ScriptBody, &BinScriptBody, "UTF-8")
		}
	} else {
		VarSetCapacity(BinScriptBody, BinScriptBody_Len:=StrPut(ScriptBody, "UTF-8"))
		StrPut(ScriptBody, &BinScriptBody, "UTF-8")
	}
	
	module := DllCall("BeginUpdateResource", "str", ExeFile, "uint", 0, "ptr")
	if !module
		Util_Error("Error: Error opening the destination file.")
	
	if IcoFile
	{
		Util_Status("Changing the main icon...")
		if !ReplaceAhkIcon(module, IcoFile, ExeFile)
		{
			; Error was already displayed
			gosub _EndUpdateResource
			Util_Error("Error changing icon: Unable to read icon or icon was of the wrong format.")
		}
	}
	
	Util_Status("Compressing and adding: Master Script")
	if !DllCall("UpdateResource", "ptr", module, "ptr", 10, "str", IcoFile ? ">AHK WITH ICON<" : ">AUTOHOTKEY SCRIPT<"
	          , "ushort", 0x409, "ptr", &BinScriptBody, "uint", BinScriptBody_Len, "uint")
		goto _FailEnd
	
	oldWD := A_WorkingDir
	SetWorkingDir, %ScriptDir%
	for each,file in ExtraFiles
	{
		Util_Status("Compressing and adding: " file)
		StrUpper, resname, %file%
		
		If !FileExist(file)
			goto _FailEnd2
		
		; This "old-school" method of reading binary files is way faster than using file objects.
		FileGetSize, filesize, %file%
		VarSetCapacity(filedata, filesize)
		FileRead, filedata, *c %file%
		If UseCompression {
			If !filesize:=VarZ_Compress(filedata,filesize,0x2) ; use simple compression for better speed
				FileGetSize, filesize, %file%
		}
		if !DllCall("UpdateResource", "ptr", module, "ptr", 10, "str", resname
				  , "ushort", 0x409, "ptr", &filedata, "uint", filesize, "uint")
			goto _FailEnd2
		VarSetCapacity(filedata, 0)
	}
	SetWorkingDir, %oldWD%
	
	gosub _EndUpdateResource
	return
	
_FailEnd:
	gosub _EndUpdateResource
	Util_Error("Error adding script file:`n`n" AhkFile)
	
_FailEnd2:
	gosub _EndUpdateResource
	Util_Error("Error adding FileInstall file:`n`n" file)
	
_EndUpdateResource:
	if !DllCall("EndUpdateResource", "ptr", module, "uint", 0)
		Util_Error("Error: Error opening the destination file.")
	return
}

Util_GetFullPath(path)
{
	VarSetCapacity(fullpath, 260 * (!!A_IsUnicode + 1))
	if DllCall("GetFullPathName", "str", path, "uint", 260, "str", fullpath, "ptr", 0, "uint")
		return fullpath
	else
		return ""
}
