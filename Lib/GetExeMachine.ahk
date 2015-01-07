;
; File encoding:  UTF-8
;

GetExeMachine(exepath){
	if exe := FileOpen(exepath, "r")
		return exe.Seek(60), exe.Seek(exe.ReadUInt()+4), exe.ReadUShort()
}
