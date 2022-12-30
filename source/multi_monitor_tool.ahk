#Requires AutoHotkey v2.0
#SingleInstance Force
ProcessSetPriority("High")
CoordMode "Mouse", "Screen"
DetectHiddenWindows(1)

monitors := IniReadArrayOfObjects("config.ini", "multi_monitor_tool", "monitors")

IniReadArrayOfObjects(config_filename, section, key) {
   result := []
   raw_array := IniRead(config_filename, section, key)

   pos := 1
   array_of_raw_objects := []
   while found := RegExMatch(raw_array, "{.*?}", &match_data, pos) {
      array_of_raw_objects.Push(match_data["0"])
      pos := found + StrLen(match_data["0"])
   }

   for i, raw_object in array_of_raw_objects {
      obj := Map()
      obj.CaseSense := "Off"
      obj.__get := (this, p*) => this.get(p*)

      raw_object := LTrim(raw_object, "{")
      raw_object := RTrim(raw_object, "}")
      obj_pairs := StrSplit(raw_object, ",", " `t")
      for i, obj_pair in obj_pairs {
         obj_key_value := StrSplit(obj_pair, ":", " `t")
         key := obj_key_value[1]
         value := obj_key_value[2]
         obj[key] := value
      }
      result.Push(obj)
   }
   return result
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
      window_id := "ahk_id " lParam
      if WinWaitActive(window_id, , 5) {
         WinHide(window_id)
         MouseGetPos &mouse_start_x, &mouse_start_y
         monitor_data := GetMonitorDataUnderMouse(mouse_start_x)
         WinGetPos(&window_x, &window_y, &window_width, &window_height, window_id)
         min_max := WinGetMinMax(window_id)

         new_window_x := Floor(monitor_data.start_x+(monitor_data.width - window_width)/2)
         new_window_y := Floor((monitor_data.height - window_height)/2)
         if min_max == 1 {
            WinRestore(window_id)
         }
         WinMove(new_window_x,new_window_y,window_width,window_height, window_id)
         if min_max == 1 {
            WinMaximize(window_id)
         }
         WinShow(window_id)

      }
   }

}

for i, monitor in monitors {
   Hotkey "<#" . i, MoveCursorToMonitor
}

loop 7 {
   Hotkey "!" . A_Index, SwitchToTaskOnCursorMonitor
}

<#Right::MoveCursorToNextMonitor()
<#Left::MoveCursorToPreviousMonitor()

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
   local mouse_start_x, mouse_start_y
   MouseGetPos &mouse_start_x, &mouse_start_y
   monitor_data := GetMonitorDataUnderMouse(mouse_start_x)

   DllCall("SetCursorPos", "int", monitor_data.start_x + monitor_data.taskbar_left_padding + monitor_data.taskbar_icon_size/2, "int", monitor_data.height-monitor_data.taskbar_icon_size/2)
   MouseClick("left")
   DllCall("SetCursorPos", "int", mouse_start_x, "int", mouse_start_y)
}

ShowTaskViewOnCursorMonitor()
{
   local mouse_start_x, mouse_start_y
   MouseGetPos &mouse_start_x, &mouse_start_y
   monitor_data := GetMonitorDataUnderMouse(mouse_start_x)

   DllCall("SetCursorPos", "int", monitor_data.start_x + monitor_data.taskbar_left_padding + 1.5 * monitor_data.taskbar_icon_size , "int", monitor_data.height-monitor_data.taskbar_icon_size/2)
   MouseClick("left")
   DllCall("SetCursorPos", "int", mouse_start_x, "int", mouse_start_y)
}

SwitchToTaskOnCursorMonitor(hot_key)
{
   RegExMatch(hot_key, "[0-9]", &match_data)
   task_nr := Integer(match_data[0])
   local mouse_start_x, mouse_start_y
   MouseGetPos &mouse_start_x, &mouse_start_y
   monitor_data := GetMonitorDataUnderMouse(mouse_start_x)

   DllCall("SetCursorPos", "int", monitor_data.start_x + monitor_data.taskbar_left_padding + 1.5 * monitor_data.taskbar_icon_size + task_nr * monitor_data.taskbar_icon_size, "int", monitor_data.height-monitor_data.taskbar_icon_size/2)
   MouseClick("left")
   DllCall("SetCursorPos", "int", mouse_start_x, "int", mouse_start_y)
}

MoveCursorToMonitor(hot_key)
{
   RegExMatch(hot_key, "[0-9]", &match_data)
   monitor_index := Integer(match_data[0]) - 1
   local mouse_start_x, mouse_start_y
   MouseGetPos &mouse_start_x, &mouse_start_y
   monitor_data := GetMonitorDataUnderMouse(mouse_start_x)

   if(monitor_index == monitor_data.index) {
      return
   }

   DllCall("SetCursorPos", "int", monitor_index*monitor_data.width+monitor_data.width/2, "int", monitor_data.height/2)
}

MoveCursorToNextMonitor()
{
   local mouse_start_x, mouse_start_y
   MouseGetPos &mouse_start_x, &mouse_start_y
   monitor_data := GetMonitorDataUnderMouse(mouse_start_x)

   if(monitors.Length == monitor_data.index+1) {
      return
   }

   DllCall("SetCursorPos", "int", (monitor_data.index+1)*monitor_data.width+monitor_data.width/2, "int", monitor_data.height/2)
}

MoveCursorToPreviousMonitor()
{
   local mouse_start_x, mouse_start_y
   MouseGetPos &mouse_start_x, &mouse_start_y
   monitor_data := GetMonitorDataUnderMouse(mouse_start_x)

   if(monitor_data.index == 0) {
      return
   }

   DllCall("SetCursorPos", "int", (monitor_data.index-1)*monitor_data.width+monitor_data.width/2, "int", monitor_data.height/2)
}

GetMonitorDataUnderMouse(mouse_x) {
   monitor_start_x := 0
   monitor_index := 0
   monitor_width := 0
   monitor_height := 0
   monitor_height := 0
   monitor_height := 0
   monitor_taskbar_left_padding := 10
   monitor_taskbar_icon_size := 45

   for i, monitor in monitors {
      if mouse_x < monitor_start_x + monitor.width {
         monitor_index := i - 1
         monitor_width := monitor.width
         monitor_height := monitor.height
         monitor_taskbar_left_padding := monitor.taskbar_left_padding
         monitor_taskbar_icon_size := monitor.taskbar_icon_size
         break
      }
      monitor_start_x := monitor_start_x + monitor.width
   }
return {start_x:monitor_start_x, index:monitor_index, width:monitor_width, height:monitor_height, taskbar_left_padding: monitor_taskbar_left_padding, taskbar_icon_size: monitor_taskbar_icon_size}
}