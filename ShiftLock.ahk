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
shiftPreset := [] ;contains preset for ctrl + shift + p
keyStrings := [] ;mapping: skill index to keyname
shiftState := {} ;mapping: key name to shift state

;temp copy of productionconfig due to encoding, read skill bindings
IniRead, productionPath, Config.ini, General, PathToConfig
FileRead, tempIni, %productionPath%
FileAppend, %tempIni%, tempConfig.ini
;prodConf := FileOpen(%productionPath%, "r")
IniRead, disableLMB, Config.ini, General, disableLMB
active := true
blockDisplay := false
skillPrefix := "use_bound_skill"

#If WinActive("ahk_group PoEWindowGrp")

;read keynames, read preset
skillIndex := 1
while(skillIndex < 9){
	skillName := skillPrefix . skillIndex
	
	IniRead, kValue, tempConfig.ini, ACTION_KEYS, %skillName%
	IniRead, kName, Config.ini, Code_to_Name, %kValue%, NONE
	IniRead, preset, Config.ini, Preset, %skillName% 
	IniRead, prevState, Config.ini, Saved, %skillName%, false
	
	if(kName == "NONE"){
		Transform, kName, Chr, kValue
		StringLower, kName, kName
	}
	
	keyStrings[skillIndex] := kName
	shiftPreset[skillIndex] := preset
	shiftState[kName] := prevState
	
	Hotkey, +!%kName% ,switchLabel
	if(prevState == true){
		Hotkey, *$%kName% ,lockLabel, On	
	} 
	else{
		Hotkey, *$%kName% ,lockLabel, Off
	}
	skillIndex++
}
FileDelete, tempConfig.ini



/*for index, keyCode in keyStrings
	{
		tempKey := skillPrefix . index
		IniRead, prevState, Config.ini, Saved, %tempKey%, false
		shiftState[keyCode] := prevState ;false
		
		Hotkey, +!%keyCode% ,switchLabel
		if(prevState == true){
			Hotkey, *$%keyCode% ,lockLabel, On	
		} 
		else{
			Hotkey, *$%keyCode% ,lockLabel, Off
		}
		
	}
*/
if(disableLMB == true){
	Hotkey, +!LButton, Off
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
	displayState()
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
	global shiftState
	global keyStrings
	global shiftPreset
	for index, keyCode in keyStrings
	{
		shiftPreset[index] := shiftState[keyCode]
		key := skillPrefix . index
		value := shiftState[keyCode]
		IniWrite, %value%, Config.ini, Preset, %key%
	}
	return
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
	
	for index, keyCode in keyStrings
	{
		if (shiftState[keyCode] == true){
			IniRead, iCoord, Config.ini, Skill_to_Coord, %index%
			StringSplit, xyCoords, iCoord, `,
			SplashImage, %index%:shiftArrow48TG.gif, b x%xyCoords1% y%xyCoords2% ,,, Image%index%
			WinSet, TransColor, White, Image%index%
		}
		;Write current status to ini
		value := shiftState[keyCode]
		tempKey := skillPrefix . index
		IniWrite, %value%, Config.ini, Saved, %tempKey%
	}
	if(blockDisplay == false){
		blockDisplay := true
		Sleep, 1500
		for index, keyCode in keyStrings
		{
			SplashImage, %index%:Off
		}
		blockDisplay := false
	}
	return
}



