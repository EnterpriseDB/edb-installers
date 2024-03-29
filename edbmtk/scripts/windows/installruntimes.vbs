' Copyright (c) 2012-2022, EnterpriseDB Corporation.  All rights reserved
On Error Resume Next

' VC++ runtime installation script for Windows

' Check the command line
If WScript.Arguments.Count <> 1 Then
 Wscript.Echo "Usage: installruntimes.vbs <Runtime package>"
 Wscript.Quit 127
End If

strPackage = WScript.Arguments.Item(0)

Set objShell = WScript.CreateObject("WScript.Shell")
WScript.Echo "Executing the runtime installer: " & strPackage
iRet = objShell.Run("""" & strPackage & """ /q /c:""VCREDI~3.EXE /q:a /c:""""msiexec /i vcredist.msi /qb!""""""", 0, True)
Set objShell = Nothing

If iRet <> 0 Then
    WScript.Echo "The runtime package exited with error code: " & iRet
    WScript.Quit iRet
End If

WScript.Echo "installruntimes.vbs ran to completion"
WScript.Quit 0
