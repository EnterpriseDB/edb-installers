' Copyright (c) 2012-2020, EnterpriseDB Corporation.  All rights reserved
Option Explicit

Dim WSHShell, shellApp, strRegKey, strApachePort, strURL, strArgs, strArch, objShell, strWinDir, cmd
Set WSHShell=CreateObject("WScript.Shell")

strArch = WshShell.RegRead("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\PROCESSOR_ARCHITECTURE")
If strArch = "x86" Then
   strRegKey = "HKEY_LOCAL_MACHINE\SOFTWARE\EnterpriseDB\PEM-HTTPD\"
Else
   strRegKey = "HKEY_LOCAL_MACHINE\SOFTWARE\wow6432node\EnterpriseDB\PEM-HTTPD\"
End If

strApachePort = WSHShell.RegRead(strRegKey & "APACHE_HPORT")

strURL="http://localhost:" & strApachePort
strArgs= "url.dll,FileProtocolHandler " & strURL


Set objShell = WScript.CreateObject("WScript.Shell")
If objShell Is Nothing Then
  WScript.Echo "Couldn't create WScript.Shell object..."
End If

strWinDir = objShell.ExpandEnvironmentStrings("%WINDIR%")
cmd = strWinDir & "\System32\" & "rundll32.exe"

Set shellApp = WScript.CreateObject("Shell.Application")
shellApp.ShellExecute cmd, strArgs, "", "open", 0

