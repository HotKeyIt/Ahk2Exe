
; This code is based on Ahk2Exe's changeicon.cpp

ReplaceAhkIcon(re, IcoFile, ExeFile, iconID := 159)
{
	global _EI_HighestIconID
	ids := EnumIcons(ExeFile, iconID)
	if !IsObject(ids)
		return false
	
	f := FileOpen(IcoFile, "r")
	if !IsObject(f)
		return false
	
	igh:=BufferAlloc(8), f.RawRead(igh.Ptr, 6)
	if NumGet("UShort", igh, 0) != 0 || NumGet("UShort", igh, 2) != 1
		return false
	
	wCount := NumGet(igh, 4, "UShort")
	
	rsrcIconGroup:=BufferAlloc(rsrcIconGroupSize := 6 + wCount*14)
	NumPut("Int64", NumGet(igh, "Int64"), rsrcIconGroup) ; fast copy
	
	ige := rsrcIconGroup.Ptr + 6
	
	; Delete all the images
	Loop ids.Length
		UpdateResource(re, 3, ids[A_Index], 0x409)
	
	Loop wCount
	{
		if !ids.Has(A_Index)
			thisID := ++ _EI_HighestIconID
		else thisID := ids[A_Index]
		f.RawRead(ige+0, 12) ; read all but the offset
		NumPut("UShort", thisID, ige+12)
		
		imgOffset := f.ReadUInt()
		oldPos := f.Pos
		f.Pos := imgOffset
		
		iconData:=BufferAlloc(iconDataSize := NumGet(ige+8, "UInt"))
		f.RawRead(iconData, iconDataSize)
		f.Pos := oldPos
		
		if !UpdateResource(re, 3, thisID, 0x409, iconData, iconDataSize)
			return false
		
		ige += 14
	}
	
	return !!UpdateResource(re, 14, iconID, 0x409, rsrcIconGroup, rsrcIconGroupSize)
}

EnumIcons(ExeFile, iconID)
{
	; RT_GROUP_ICON = 14
	; RT_ICON = 3
	global _EI_HighestIconID
	static pEnumFunc := CallbackCreate("EnumIcons_Enum")
	
	hModule := LoadLibraryEx(ExeFile, 0, 2)
	if !hModule
		return
	
	_EI_HighestIconID := 0
	if EnumResourceNames(hModule, 3, pEnumFunc) = 0
	{
		FreeLibrary(hModule)
		return
	}
	
	hRsrc := FindResource(hModule, iconID, 14)
	,hMem := LoadResource(hModule, hRsrc)
	,pDirHeader := LockResource(hMem)
	,pResDir := pDirHeader + 6
	
	wCount := NumGet(pDirHeader+4, "UShort")
	,iconIDs := []
	Loop wCount
	{
		pResDirEntry := pResDir + (A_Index-1)*14
		iconIDs.Push(NumGet(pResDirEntry+12, "UShort"))
	}
	
	FreeLibrary(hModule)
	return iconIDs
}

EnumIcons_Enum(hModule, type, name, lParam)
{
	global _EI_HighestIconID
	if (name < 0x10000) && name > _EI_HighestIconID
		_EI_HighestIconID := name
	return 1
}
