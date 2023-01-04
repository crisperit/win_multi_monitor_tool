#Requires AutoHotkey v2.0
#SingleInstance Force
ProcessSetPriority("High")
CoordMode "Mouse", "Screen"
DetectHiddenWindows(1)
OriginalContext := DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr")

MonitorInfos := GetMonitorInfos()
TaskbarIconSize := 45
TaskbarLeftPadding := 10

RegisterHooks() 

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

GetMonitorInfos() {
   local monitorCount := MonitorGetCount()
   local monitorPrimary := MonitorGetPrimary()
   local monitorInfos := []
   Loop monitorCount
   {
      scaling := GetScaling(A_Index)
      MonitorGet A_Index, &l, &t, &r, &b
      MonitorGetWorkArea A_Index, &wl, &wt, &wr, &wb
      monitorInfo := {StartX: l, Width: r-l, Height: b-t, Scaling: scaling}
      monitorInfos.Push(monitorInfo)
   } 
return monitorInfos
}

GetScaling(monitorIndex) {
   primaryScaling := Round(A_ScreenDPI*100 / 96)
   scaling := primaryScaling
   if(monitorIndex != MonitorGetPrimary()) {
      DllCall("SetThreadDpiAwarenessContext", "ptr", OriginalContext, "ptr")
      MonitorGet(monitorIndex, &l,, &r,)
      scaledWidth := r-l

      DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr")
      MonitorGet(monitorIndex, &l,, &r,)
      originalWidth := r-l

      scaling := Round(primaryScaling * originalWidth / scaledWidth)
   }
return scaling
}

RegisterHooks(){
   DllCall( "RegisterShellHookWindow", "UInt", A_ScriptHwnd)
   MsgNum := DllCall("RegisterWindowMessage", "Str", "SHELLHOOK")
   OnMessage(MsgNum, OnShellMessage)

   OnMessage(0x7E, OnMonitorChange)
return
}

OnMonitorChange(wParam, lParam, msg, hwnd)
{
   MonitorInfos := GetMonitorInfos()
}

OnShellMessage(wParam, lParam, msg, hwnd)
{
   if ( wParam = 1 ) { 
      windowID := "ahk_id " lParam
      if WinWaitActive(windowID, , 5) {
         try {
            cl := WinGetClass(windowID)
            MouseGetPos &mouseStartX, &mouseStartY
            monitorData := GetMonitorDataByPosX(mouseStartX)
            WinGetPos(&windowX, &windowY, &windowWidth, &windowHeight, windowID)
            local minMax := WinGetMinMax(windowID)

            if minMax == 1 {
               WinRestore(windowID)
            }
            if cl != "RAIL_WINDOW" {
               newWindowX := Round(monitorData.startX+(monitorData.width - windowWidth)/2)
               newWindowY := Round((monitorData.height - windowHeight)/2)

               WinMove(newWindowX,newWindowY,,, windowID)
            }

            if minMax == 1 {
               WinMaximize(windowID)
            }
         } catch Error as err {
         }
      }
   }

}

ShowStartOnCursorMonitor()
{
   local mouseStartX, mouseStartY
   MouseGetPos &mouseStartX, &mouseStartY
   monitorData := GetMonitorDataByPosX(mouseStartX)

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
   monitorData := GetMonitorDataByPosX(mouseStartX)

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
   monitorData := GetMonitorDataByPosX(mouseStartX)

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
   monitorData := GetMonitorDataByPosX(mouseStartX)

   if(MonitorInfos.Length == monitorData.index+1) {
      return
   }

   DllCall("SetCursorPos", "int", (monitorData.index+1)*monitorData.width+monitorData.width/2, "int", monitorData.height/2)
}

MoveCursorToPreviousMonitor()
{
   local mouseStartX, mouseStartY
   MouseGetPos &mouseStartX, &mouseStartY
   monitorData := GetMonitorDataByPosX(mouseStartX)

   if(monitorData.index == 0) {
      return
   }

   DllCall("SetCursorPos", "int", (monitorData.index-1)*monitorData.width+monitorData.width/2, "int", monitorData.height/2)
}

GetMonitorDataByPosX(posX) {
   local monitorStartX := 0
   local monitorIndex := 0
   local monitorWidth := 0
   local monitorHeight := 0
   local monitorScaling := 100
   local monitorTaskbarLeftPadding := taskbarLeftPadding
   local monitorTaskbarIconSize := taskbarIconSize

   for i, monitorInfo in MonitorInfos {
      monitorStartX := monitorInfo.StartX
      monitorIndex := i - 1
      monitorWidth := monitorInfo.Width
      monitorHeight := monitorInfo.Height
      monitorScaling := monitorInfo.Scaling

      if posX >= monitorStartX && posX < monitorStartX+monitorWidth {
         break
      }
   }
return {startX:monitorStartX, index:monitorIndex, width:monitorWidth, height:monitorHeight, taskbarLeftPadding: monitorTaskbarLeftPadding, taskbarIconSize: monitorTaskbarIconSize, scaling: monitorScaling}
}