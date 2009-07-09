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

'taken host as localhost as the application is installed in the local machine only
strURL="http://localhost:" & strApachePort & "/phpPgAdmin"
strArgs= "url.dll,FileProtocolHandler " & strURL

Set shellApp = WScript.CreateObject("Shell.Application")
shellApp.ShellExecute "rundll32.exe", strArgs, "", "open", 0
