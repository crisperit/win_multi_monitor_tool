#Requires AutoHotkey v2.0
#SingleInstance Force
ProcessSetPriority("High")
CoordMode "Mouse", "Screen"
DetectHiddenWindows(1)

MonitorInfos := GetMonitorInfos()
TaskbarIconSize := 45
TaskbarLeftPadding := 10

GetMonitorInfos() {
   local monitorCount := MonitorGetCount()
   local monitorPrimary := MonitorGetPrimary()
   local monitorInfos := []
   Loop monitorCount
   {
      MonitorGet A_Index, &l, &t, &r, &b
      MonitorGetWorkArea A_Index, &wl, &wt, &wr, &wb
      monitorInfo := {StartX: l, Width: r-l, Height: b-t}
      monitorInfos.Push(monitorInfo)
   } 
   return monitorInfos
}

HookShellEvent() 

HookShellEvent(){
   DllCall( "RegisterShellHookWindow", "UInt", A_ScriptHwnd)

   MsgNum := DllCall("RegisterWindowMessage", "Str", "SHELLHOOK")

   OnMessage(MsgNum, CaptureShellMessage)
}

; called each time a window created
CaptureShellMessage(wParam, lParam, msg, hwnd)
{
   if ( wParam = 1 ) { 
      windowID := "ahk_id " lParam
      if WinWaitActive(windowID, , 5) {
         try {
            cl := WinGetClass(windowID)
            MouseGetPos &mouseStartX, &mouseStartY
            monitorData := GetMonitorDataUnderMouse(mouseStartX)
            WinGetPos(&windowX, &windowY, &windowWidth, &windowHeight, windowID)
            local minMax := WinGetMinMax(windowID)

            newWindowX := Floor(monitorData.startX+(monitorData.width - windowWidth)/2)
            newWindowY := Floor((monitorData.height - windowHeight)/2)
            if minMax == 1 {
               WinRestore(windowID)
            }
            if cl != "RAIL_WINDOW" {
               WinMove(newWindowX,newWindowY,windowWidth,windowHeight, windowID) 
            }

            if minMax == 1 {
               WinMaximize(windowID)
            }
         } catch Error as err {

         }
      }
   }

}

loop 7 {
   Hotkey "<#" . A_Index, SwitchToTaskOnCursorMonitor
}

<#F3::MoveCursorToNextMonitor()
<#F2::MoveCursorToPreviousMonitor()

~LWin::Send "{Blind}{vkE8}"

<#Tab::ShowTaskViewOnCursorMonitor()

~LWin Up::
   { 
      if (A_PriorKey = "LWin") {
         ShowStartOnCursorMonitor()

      } 
   }
return

ShowStartOnCursorMonitor()
{
   local mouseStartX, mouseStartY
   MouseGetPos &mouseStartX, &mouseStartY
   monitorData := GetMonitorDataUnderMouse(mouseStartX)

   DllCall("ShowCursor", "uint",0)
   DllCall("SetCursorPos", "int", monitorData.startX + monitorData.taskbarLeftPadding + monitorData.taskbarIconSize/2, "int", monitorData.height-monitorData.taskbarIconSize/2)
   MouseClick("left")
   DllCall("SetCursorPos", "int", mouseStartX, "int", mouseStartY)
   DllCall("ShowCursor", "uint",1)
}

ShowTaskViewOnCursorMonitor()
{
   local mouseStartX, mouseStartY
   MouseGetPos &mouseStartX, &mouseStartY
   monitorData := GetMonitorDataUnderMouse(mouseStartX)

   DllCall("ShowCursor", "uint",0)
   DllCall("SetCursorPos", "int", monitorData.startX + monitorData.taskbarLeftPadding + 1.5 * monitorData.taskbarIconSize , "int", monitorData.height-monitorData.taskbarIconSize/2)
   MouseClick("left")
   DllCall("SetCursorPos", "int", mouseStartX, "int", mouseStartY)
   DllCall("ShowCursor", "uint",1)
}

SwitchToTaskOnCursorMonitor(shortcut)
{
   RegExMatch(shortcut, "[0-9]", &matchingData)
   taskNR := Integer(matchingData[0])
   local mouseStartX, mouseStartY
   MouseGetPos &mouseStartX, &mouseStartY
   monitorData := GetMonitorDataUnderMouse(mouseStartX)

   DllCall("ShowCursor", "uint",0)
   DllCall("SetCursorPos", "int", monitorData.startX + monitorData.taskbarLeftPadding + 1.5 * monitorData.taskbarIconSize + taskNR * monitorData.taskbarIconSize, "int", monitorData.height-monitorData.taskbarIconSize/2)
   MouseClick("left")
   DllCall("SetCursorPos", "int", mouseStartX, "int", mouseStartY)
   DllCall("ShowCursor", "uint",1)
}

MoveCursorToNextMonitor()
{
   local mouseStartX, mouseStartY
   MouseGetPos &mouseStartX, &mouseStartY
   monitorData := GetMonitorDataUnderMouse(mouseStartX)

   if(MonitorInfos.Length == monitorData.index+1) {
      return
   }

   DllCall("SetCursorPos", "int", (monitorData.index+1)*monitorData.width+monitorData.width/2, "int", monitorData.height/2)
}

MoveCursorToPreviousMonitor()
{
   local mouseStartX, mouseStartY
   MouseGetPos &mouseStartX, &mouseStartY
   monitorData := GetMonitorDataUnderMouse(mouseStartX)

   if(monitorData.index == 0) {
      return
   }

   DllCall("SetCursorPos", "int", (monitorData.index-1)*monitorData.width+monitorData.width/2, "int", monitorData.height/2)
}

GetMonitorDataUnderMouse(mouseX) {
   local monitorStartX := 0
   local monitorIndex := 0
   local monitorWidth := 0
   local monitorHeight := 0
   local monitorTaskbarLeftPadding := taskbarLeftPadding
   local monitorTaskbarIconSize := taskbarIconSize

   for i, monitorInfo in MonitorInfos {
      monitorStartX := monitorInfo.StartX
      monitorIndex := i - 1
      monitorWidth := monitorInfo.Width
      monitorHeight := monitorInfo.Height

      if mouseX < monitorStartX+monitorWidth {
         break
      }
   }
return {startX:monitorStartX, index:monitorIndex, width:monitorWidth, height:monitorHeight, taskbarLeftPadding: monitorTaskbarLeftPadding, taskbarIconSize: monitorTaskbarIconSize}
}