Set WshShell = CreateObject("WScript.Shell")
Set Shortcut = WshShell.CreateShortcut(WshShell.SpecialFolders("Desktop") & "\YT汉化工具.lnk")
Shortcut.TargetPath = "wscript.exe"
Shortcut.Arguments = """D:\YouTube汉化工具\start.vbs"""
Shortcut.WorkingDirectory = "D:\YouTube汉化工具"
Shortcut.Description = "YouTube汉化工具"
Shortcut.IconLocation = "shell32.dll,45"
Shortcut.Save
WScript.Echo "快捷方式已创建到桌面"
