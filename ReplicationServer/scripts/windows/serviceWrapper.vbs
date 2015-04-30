' Copyright (c) 2012-2015, EnterpriseDB Corporation.  All rights reserved

If WScript.Arguments.Count <> 1 Then
 Wscript.Quit 127
End If

strTempDir = WScript.Arguments.Item(0)

Set objShell = WScript.CreateObject("Shell.Application")

strServiceFile  = strTempDir & "\servicewrapper.bat"
objShell.ShellExecute strServiceFile, "", strTempDir, "open", 0
WScript.Quit 0
