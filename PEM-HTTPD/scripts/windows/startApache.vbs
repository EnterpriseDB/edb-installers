' Copyright (c) 2012-2017, EnterpriseDB Corporation.  All rights reserved

If WScript.Arguments.Count <> 1 Then
 Wscript.Quit 127
End If

strInstallDir= WScript.Arguments.Item(0)

Set objShell = WScript.CreateObject("Shell.Application")

strInstallFile  = strInstallDir & "\installer\PEM-HTTPD\start-apache.bat"
objShell.ShellExecute strInstallFile, "", strInstallDir & "\installer\PEM-HTTPD", "open", 0
WScript.Quit 0
