' Copyright (c) 2012-2015, EnterpriseDB Corporation.  All rights reserved

If WScript.Arguments.Count <> 1 Then
 Wscript.Quit 127
End If

strInstallDir = WScript.Arguments.Item(0)

Set objShell = WScript.CreateObject("Shell.Application")

strRunFile  = strInstallDir & "\bin\runRepConsole.bat"
objShell.ShellExecute strRunFile, "", strInstallDir & "\bin", "open", 0
WScript.Quit 0
