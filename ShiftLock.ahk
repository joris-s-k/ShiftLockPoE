#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.

GroupAdd, PoEWindowGrp, Path of Exile ahk_class POEWindowClass ahk_exe PathOfExile.exe
GroupAdd, PoEWindowGrp, Path of Exile ahk_class POEWindowClass ahk_exe PathOfExileSteam.exe
GroupAdd, PoEWindowGrp, Path of Exile ahk_class POEWindowClass ahk_exe PathOfExile_x64.exe
GroupAdd, PoEWindowGrp, Path of Exile ahk_class POEWindowClass ahk_exe PathOfExile_x64Steam.exe
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance force

Menu, Tray, Icon, %A_ScriptDir%\ShiftLock.ico

#UseHook On
shiftPreset := readStateFromIni("preset") ;contains preset for ctrl + shift + p
keyStrings := [] ;mapping: skill index to keyname
shiftState := {} ;mapping: key name to shift state
shiftPrevious := readStateFromIni("previous")

;temp copy of productionconfig due to encoding, read skill bindings
productionPath := A_MyDocuments . "\My Games\Path of Exile\production_Config.ini"
FileRead, tempIni, %productionPath%
FileAppend, %tempIni%, tempConfig.ini
;prodConf := FileOpen(%productionPath%, "r")
IniRead, disableLMB, Config.ini, General, disableLMB
blockList := Object()

#If WinActive("ahk_group PoEWindowGrp")

;read keynames, read preset

skillIndex := 1
while(skillIndex < 9){
	skillName := "use_bound_skill" . skillIndex
	
	IniRead, kValue, tempConfig.ini, ACTION_KEYS, %skillName%
	IniRead, kName, Config.ini, Code_to_Name, %kValue%, NONE
	
	if(kName == "NONE"){
		Transform, kName, Chr, kValue
		StringLower, kName, kName
	}
	
	keyStrings[skillIndex] := kName
	shiftState[kName] := shiftPrevious[skillIndex]
	
	Hotkey, +!%kName% ,switchLabel
	if(shiftState[kName] == true){
		Hotkey, *$%kName% ,lockLabel, On	
	} 
	else{
		Hotkey, *$%kName% ,lockLabel, Off
	}
	skillIndex++
}
FileDelete, tempConfig.ini

if(disableLMB == true){
	Hotkey, +!LButton, Off
	shiftState["LButton"] := false
}

return

switchLabel:
	tempKey := SubStr(A_ThisHotkey, 3)
	Hotkey, *$%tempKey%, Toggle
	switchState(tempKey)
	displayState()
return

lockLabel:
	lockKey(SubStr(A_ThisHotkey, 3))
return

;+!d::reload

+!s::Suspend
/*{
*global active
*x = 1148
*y = 977
*SplashImage, 10:Off
*if(active == true) 
*	SplashImage, 10:OffButton.png, b x%x% y%y%
*else
*	SplashImage, 10:OnButton.png, b x%x% y%y%
*active := !active
*for index, KeyCode in keyStrings
*	{
*		Hotkey, +!%keyCode% ,Toggle
*		Hotkey, *$%keyCode% ,Toggle
*	}
*return
*}
*/

+!a::displayState()

+!n::
{
	SoundBeep, 300, 400
	global shiftState
	for keyCode, value in shiftState
	{
		shiftState[keyCode] := false
		Hotkey, *$%keyCode%, Off
				
	}
	writeStateToIni("previous")
	return
}

+!p::
{
	global shiftState
	global keyStrings
	global shiftPreset
	global disableLMB
	SoundBeep, 500, 400
	for index, keyCode in keyStrings
	{
		if(shiftPreset[index] == true){
			Hotkey, *$%keyCode%, On
		}
		else{
			Hotkey, *$%keyCode%, Off
		}
		shiftState[keyCode] := shiftPreset[index]
	}
	if(disableLMB == true){
		Hotkey, +!LButton, Off
		shiftState["LButton"] := false
	}
	displayState()
	return
}

^!#p::
{	
	SoundBeep, 600, 400
	writeStateToIni("preset")
}


lockKey(key)
{
	Send {Shift down}{%key% down}
	KeyWait, %key%
	Send {Shift up}{%key% up}
	return
}


switchState(keyCode)
{
	global shiftState
	if(shiftState[keyCode] == false){
		SoundBeep, 500, 150 
	} 
	else{
		SoundBeep, 300, 150 
	}
	shiftState[keyCode] := !shiftState[keyCode]
	return
}

displayState()
{
	global shiftState
	global keyStrings
	global blockDisplay
	global skillPrefix
	global blockList
	
	for index, keyCode in keyStrings
	{
		if (shiftState[keyCode] == true){
			IniRead, iCoord, Config.ini, Skill_to_Coord, %index%
			SysGet, monRes, Monitor
			xScale := monResRight / 1680
			yScale := monResBottom / 1050
			StringSplit, xyCoords, iCoord, `,
			xyCoords1 := xyCoords1 * xScale
			xyCoords2 := xyCoords2 * yScale
			
			SplashImage, %index%:shiftArrow48TG.gif, b x%xyCoords1% y%xyCoords2% ,,, Image%index%
			WinSet, TransColor, White, Image%index%
		}
		else{
			SplashImage, %index%:Off
		}
	}
	writeStateToIni("previous")
	blockList.Push(1)
	Sleep, 1000
	blockList.Pop()
	if(blockList.length() == 0){
		for index, keyCode in keyStrings
		{
			SplashImage, %index%:Off
		}
	}
	return
}

writeStateToIni(key)
{
	global shiftState
	global keyStrings
	global skillPrefix
	global shiftPreset

	saveStr := ""
	for index, keyCode in keyStrings
	{
		saveStr := saveStr . shiftState[keyCode]
		if(key == "preset"){
			shiftPreset[index] := shiftState[keyCode]
		}
	}
	IniWrite, %saveStr%, Config.ini, Saved, %key%
	return
}

readStateFromIni(key)
{
	IniRead, strState, Config.ini, Saved, %key%, 00000000
	toArray := StrSplit(strState)
	return toArray
}

readPreset()
{

}



