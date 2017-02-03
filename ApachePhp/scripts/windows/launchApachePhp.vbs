' Copyright (c) 2012-2017, EnterpriseDB Corporation.  All rights reserved
Option Explicit

Dim WSHShell, shellApp, strRegKey, strApachePort, strURL, strArgs, strArch
Set WSHShell=CreateObject("WScript.Shell")

strArch = WshShell.RegRead("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\PROCESSOR_ARCHITECTURE")
If strArch = "x86" Then
   strRegKey = "HKEY_LOCAL_MACHINE\SOFTWARE\EnterpriseDB\ApachePhp\"
Else
   strRegKey = "HKEY_LOCAL_MACHINE\SOFTWARE\wow6432node\EnterpriseDB\ApachePhp\"
End If

strApachePort = WSHShell.RegRead(strRegKey & "APACHE_PORT")

strURL="http://localhost:" & strApachePort
strArgs= "url.dll,FileProtocolHandler " & strURL

Set shellApp = WScript.CreateObject("Shell.Application")
shellApp.ShellExecute "rundll32.exe", strArgs, "", "open", 0

