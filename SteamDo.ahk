#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, force
#Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

Menu, Tray, Icon, Shell32.dll, 266

global stmLib := "SteamLibrary"
global stmApps := "steamapps\"
global stmLibDownloads := "downloading\"

stmLibs := ""
stmAction := ""
stmDownload := false
libsFound := 0

RegRead, stmLoc, HKCU, Software\Valve\Steam, SteamPath
stmLoc := RegExReplace(stmLoc, "/", "\")
stmLibs .= stmLoc . "\" . "`n"
gosub, QuickCheckStmLibs
Process, Exist, Steam.exe
stmPID := ErrorLevel
libsFound := LineCount(stmLibs)

StringLower, stmLibs, stmLibs, T

Menu, Tray, Click, 1
Menu, Tray, NoStandard
Menu, Tray, Add, Show GUI, ShowGui
Menu, Tray, Add, Cancel, Cancel
Menu, Tray, Add, Restart, Restart
Menu, Tray, Disable, Restart
Menu, Tray, Disable, Cancel
Menu, Tray, Disable, Show Gui
Menu, Tray, Add, Close, Exit
gui, Add, Edit, r%libsFound% ReadOnly vLibraries, %stmLibs%
gui, Add, DropDownList, vSteamActions gActions x+m, ShutDown|Hibernate|LogOff|Reboot|Run
gui, Add, Button, vAddLib xs, Add Library
gui, Add, Button, vLSteam gLSteam x+m, Launch Steam
gui, Add, Button, vGo gGo x+m, Go
if(stmPID)
	GuiControl, Disable, LSteam
GuiControl, Focus, SteamActions
gui, show, AutoSize

return
ShowGui:
{
    gui, show,, MyGui
	Menu, Tray, Disable, Show Gui
}return
Cancel:
{
	SetTimer, CheckLibDownloads, Off
	Menu, Tray, Icon, Shell32.dll, 220
	Menu, Tray, Disable, Cancel
	Menu, Tray, Enable, Restart
}return
Exit:
{
	ExitApp
}return
Restart:
{
	SetTimer, CheckLibDownloads, 5000
	Menu, Tray, Icon, Shell32.dll, 266
	Menu, Tray, Enable, Cancel
	Menu, Tray, Disable, Restart
}return

QuickCheckStmLibs:
{
	DriveGet, sysDrives, List, FIXED
	sysDrives := StrSplit(sysDrives)
	for index, dLetter in sysDrives
	{
		libLoc := FindFolder(dLetter . ":\", "SteamLibrary")
		if(strLen(libLoc))
			stmLibs .= trim(libLoc, " `t`r`n") . "\`n"
	}
	stmLibs := trim(stmLibs, " `t`r`n")
}return
LSteam:
{
	run, %stmLoc%\steam.exe
}return
Actions:
{
	gui, Submit, NoHide
	gosub, %SteamActions%
}return

Go:
{
	Menu, Tray, Enable, Show Gui
	Menu, Tray, Enable, Cancel
	Menu, Tray, Icon, Shell32.dll, 266
	gui, hide
	stmDownloading := (IsSteamDownloading(stmLibs)) ? true : false
	SetTimer, CheckLibDownloads, 5000
}return

ShutDown:
{
	stmAction := "shutdown /p /f"
}return
Hibernate:
{
	stmAction := "shutdown /h /f"
}return
LogOff:
{
	stmAction := "shutdown /l /f"
}return
Reboot:
{
	stmAction := "shutdown /r /f"
}return
Run:
{
	gui, run: new
	gui, run: add, text, xm ym, Target        :
	gui, run: add, edit, vRunTarget x+m
	gui, run: add, button, gRunTarget x+m, Browse
	gui, run: add, text, xm, 	Parameters :
	gui, run: add, edit, vRunParameters x+m
	gui, run: add, button, gAccept xm, Accept
	gui, run: show, AutoSize
}return

RunTarget:
{
	FileSelectFile, RunTarget, 2, %A_MyDocuments%
	if(RunTarget)
	{
		GuiControl, +ReadOnly, RunTarget
		SplitPath, RunTarget, shortRunTarget
		GuiControl, , RunTarget, %shortRunTarget%
	}
	else
	{
		GuiControl, -ReadOnly, RunTarget
		GuiControl, , RunTarget
	}
}
return
Accept:
stmAction := RunTarget
gui, run: submit
stmAction .= " " . trim(RunParameters, " `t`r`n")
runGuiClose:
Gui, run: Destroy
return
GuiClose:
ExitApp

CheckLibDownloads:
{
	Process, Exist, Steam.exe
	if(!ErrorLevel)
	{
		SetTimer, CheckLibDownloads, Off
		Menu, Tray, Disable, Cancel
		Menu, Tray, Enable, Restart
		Menu, Tray, Icon, Shell32.dll, 220
	}
	SoundBeep, 5000, 500
	if(!stmDownloading)
	{
		stmDownloading := IsSteamDownloading(stmLibs)
		return
	}
	if(!IsSteamDownloading(stmLibs))
	{
		;~ run, %stmAction%
		ExitApp
	}
}return

FindFolder(rootPath, sString, Recurse := false)
{
	sMode := (Recurse == true) ? "DR" : "D"
	oStr := ""
	if(InStr(FileExist(rootPath), "D") && StrLen(sString))
	{
		if(SubStr(rootPath, 0) != "\")
			rootPath .= "\"
		loop, Files, %rootPath%*, %sMode%
		{
			if(InStr(A_LoopFileName, sString))
				return A_LoopFileLongPath
		}
	}
	else
	{
		return ""
	}
}
GetFolderContents(path, recurse := false)
{
	oStr := ""
	sMode := "DF"
	
	sMode .= (recurse) ? "R"
	loop, Files, %path%*, %sMode%
	{
		oStr .= A_LoopFileLongPath . "`n"
	}
	return trim(oStr, " `t`r`n")
}
LineCount(string)
{
	count := 0
	loop, parse, string, `n
		count := a_index
	return count
}
IsSteamDownloading(strSteamLibraries)
{
	downloading := 0
	loop, parse, strSteamLibraries, `n
		downloading += LineCount(GetFolderContents(A_LoopField . stmApps . stmLibDownloads))
	return (downloading) ? true : false
}