## Introduction
Set of hotkeys & tools to make Windows multi monitor work much better

## Installation
For now the app was tested only on Windows 11 with 3 monitors (each 1920 x 1080 with 100% of scale)

1. The script also requires specific Windows taskbar setting (mostly because the script is clicking at specific regions...):
- Search : Hide
- Task view : On
- Widgets : Off
- Chat : Off
- Taskbar behaviors:
    - Taskbar alignment : Left
    - Automatically hide the taskbar : Unchecked
    - When using multiple displays, show my taskbar apps on : Taskbar where window is open

2. Download the content of `release` directory.
3. Provide also the monitors config to `config.ini`
```
[multi_monitor_tool]
monitors = "[{width: 1920, height: 1080, taskbar_left_padding: 10, taskbar_icon_size: 45},{width: 1920, height: 1080, taskbar_left_padding: 10, taskbar_icon_size: 45},{width: 1920, height: 1080, taskbar_left_padding: 10, taskbar_icon_size: 45}]"
```
4. Run `multi_monitor_tool.exe` and test it out.

If more people will like to use that tool then we can work together to make it more flexible :D 

## Functionalities
- Moving the cursor between monitors via 
    - `Start + Left` - go to previous monitor
    - `Start + Right` - go to next monitor
    - `Start + N` - go to N`th monitor (generated basing on monitor count)
- Pressing `Start` toggle start menu always on the cursor monitor
- Pressing `Start + Tab` toggle task view always on the cursor monitor
- Pressing `Alt + N` toggle N'th task in taskbar
- All newly created windows are moved to the center of the cursor monitor
