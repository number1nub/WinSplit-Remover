#NoEnv
#SingleInstance, Force
SetWorkingDir, %A_ScriptDir%
WinGetClass, wClass, A
WinGet, wProc, ProcessName, A

;______________________________________________________________________________
;******************************************************************************
; SET APP INFO & COMILER DIRECTIVES
;******************************************************************************
AppName    := "WinSplit Window Remove"
;@Ahk2Exe-Let AppName = %A_PriorLine~U)^(.+"){1}(.+)".*$~$2%

AppVersion := "1.4.0"
;@Ahk2Exe-Let AppVersion = %A_PriorLine~U)^(.+"){1}(.+)".*$~$2%

AppCompany := "WSNHapps"
;@Ahk2Exe-Let AppCompany = %A_PriorLine~U)^(.+"){1}(.+)".*$~$2%

AppDesc    := "A simple utility that allows for quickly removing entries from WinSplit Revolution's Auto-Placement windows list"
;@Ahk2Exe-Let AppDesc = %A_PriorLine~U)^(.+"){1}(.+)".*$~$2%

;@Ahk2Exe-ExeName %A_ScriptDir%\build\%U_AppName%.exe
;@Ahk2Exe-Let IcoPath = %A_ScriptDir%\res\%A_ScriptName~\.[^\.]+$~.ico%
;@Ahk2Exe-SetMainIcon %U_IcoPath%
;@Ahk2Exe-Bin %A_ScriptDir%\res\compiler\AutoHotkeySC.bin
;@Ahk2Exe-SetProductName %U_AppName%
;@Ahk2Exe-SetOrigFilename %U_AppName%
;@Ahk2Exe-SetInternalName %U_AppName%
;@Ahk2Exe-SetVersion %U_AppVersion%
;@Ahk2Exe-SetCompanyName %U_AppCompany%
;@Ahk2Exe-SetDescription %U_AppDesc%
;@Ahk2Exe-Obey U_year, FormatTime U_year`,`, yyyy
;@Ahk2Exe-SetCopyright Copyright © %U_year% %U_AppCompany%
;______________________________________________________________________________
;******************************************************************************

global wsConfig:=new xml("WinSplit_AutoPlacement", A_AppData "\Winsplit Revolution\auto_placement.xml")
if (!wsConfig.FileExists) {
	m("ico:!", "Couldn't load the WinSplit XML")
	ExitApp
}

;{=========== CHECK WIN / GET USER INPUT ==========>>>
	
	if (remNode:=wsConfig.ssn("//Application[@Name='" wProc "::" wClass "']")) {
		if (m("ico:?", "btn:ync", "Delete entry for """ wsConfig.ea(remNode).Name """?") = "YES")
			RemoveNode(remNode)
		ExitApp
	}
	
	InputBox, winLabel,, Enter the Window Class to be removed from the Auto Placements`n`nCASE SENSITIVE!,,, 150,,,,, %wProc%::%wClass%
	if (ErrorLevel || !winLabel) {
		(ErrorLevel < 1) ? m("ico:!", "Invalid input!", "time:1.5") : ""
		ExitApp
	}
;}


;{============= FIND MATCHING WINDOWS ============>>>
	
	list:="", count:=0, matchNodes:=wsConfig.sn("//Application[@Name[contains(.,'" winLabel "')]]")
	while node:=matchNodes.Item[A_Index-1], ea:=wsConfig.ea(node) {
		list .= (list ? "`n" : "") (matchNodes.Item[1] ? A_Index ")`t" : "") ea.Name
		count++
	}
	
	if (!list ) {			;~ No matches found
		m("ico:!", "No match found")
		ExitApp
	} else if (count=1) {	;~ Single match found
		remWin := list
	} else {				;~ Multiple matches found
		;~ if (!winList:=ListGUI(list))
		;~ ExitApp
		
		InputBox, selWin,, Enter the number of the window to remove`n`n%list%
		if (ErrorLevel || !selWin)
			exitapp
		else if selWin is not number
		{
			m("ico:!", "Invalid input")
			exitapp
		}
		else if (selWin > count || selWin < 0) {
			m("ico:!", "Invalid input")
			ExitApp
		}
		if (!RegExMatch(list, selWin "\)\t(?P<Win>\S+)", rem)) {
			m("ico:!", "Error parsing the selection")
			exitapp
		}
	}
	
	if  (m("ico:?", "btn:yn", "Remove setting for """ remWin """?") != "YES")
		ExitApp
	
	if (!remNode:=wsConfig.ssn("//Application[@Name='" remWin "']"))
		m("ico:!", "Error removing the node from the XML")
	else
		RemoveNode(remNode)
;}
ExitApp

RemoveNode(remNode) {
	try {
		Run, taskkill /F /IM WinSplit*
		wsConfig.remove(remNode)
		wsConfig.save(1)
		TrayTip, WinSplit Window Remover, Done! Window removed..., 1.5
		sleep 700
		Run, %wsPath%
	}
	catch e 
		m("ico:!", "Something went wrong...`n", e.what, "`n" e.message)
}


ListGUI(listItems) {
	global
	
	Gui, ListGUI:+LastFound
	Gui, Font, s14 w600, Arial	
	Gui, Color, FFFFFF, FFFFFF
	Gui,  +toolwindow +alwaysontop
	
	Gui, Add, Text, x20 y5 w460 h22 +center, Windows to be Closed
	
	Gui, Font, s10, Arial
	Gui, Add, ListBox, x20 y30 w460 h308 +Multi hwndListHWND vList_Selection gselectionChange, %listItems%
	
	Gui, Add, Button, x130 y350 w120 h40 +default vcloseBtn, Close Windows
	Gui, Add, Button, x260 y350 w120 h40, Cancel
	
	Gui, Show, w500 h401, Close Windows
	
	;;; Select all listbox items
	loop, parse, listItems, |
	{
		GuiControl, choose, list_selection, %A_Index%
		found := A_Index
	}
	GuiControl,, closeBtn, Close %found% Windows
	return
	
	
	selectionChange:
	Gui, ListGUI:Submit, NoHide
	StringSplit, selWins, list_selection, |
	if (selWins0)
		GuiControl,, closeBtn, % "Close " (selWins0 ? selWins0 " " : "") "Windows"
	GuiControl, % "Enable" selWins0, closeBtn
	return
	
	
	ButtonCloseWindows:
	gui, ListGUI:submit
	if (list_selection)
		loop, Parse, list_selection, |
			WinClose, % Trim(A_LoopField)		
	ExitApp
	
	
	ButtonCancel:
	ListGUIGuiClose:
	ListGUIGuiEscape:
	return
}


m(info*) {
	static icons:={"x":16,"?":32,"!":48,"i":64}, btns:={c:1,oc:1,co:1,ari:2,iar:2,ria:2,rai:2,ync:3,nyc:3,cyn:3,cny:3,yn:4,ny:4,rc:5,cr:5,ctc:6}
	for c, v in info
		(RegExMatch(v, "imS)^(?:btn:(?P<btn>c|\w{2,3})|(?:ico:)?(?P<ico>x|\?|\!|i)|title:(?P<title>.+)|def:(?P<def>\d+)|time:(?P<time>\d+(?:\.\d{1,2})?|\.\d{1,2}))$", m_)) ? (mBtns:=m_btn?btns[m_btn]:mBtns, mTitle:=m_title?m_title:mTitle, mTimeout:=m_time?m_time:mTimeout, mIcon:=m_ico?icons[m_ico]:mIcon, mDefault:=m_def?(m_def-1)*256:mDefault) : (txt .= (txt ? "`n":"") v)
	MsgBox, % 262144+(mBtns?mBtns:0)+(mIcon?mIcon:0)+(mDefault?mDefault:0), %mTitle%, %txt%, %mTimeout%
	IfMsgBox, OK
		return (mBtns ? "OK":"")
	else IfMsgBox, Yes
		return "YES"
	else IfMsgBox, No
		return "NO"
	else IfMsgBox, Cancel
		return "CANCEL"
	else IfMsgBox, Retry
		return "RETRY"
	else IfMsgBox, Continue
		return "CONTINUE"
	else IfMsgBox, TryAgain
		return "TRY AGAIN"
}