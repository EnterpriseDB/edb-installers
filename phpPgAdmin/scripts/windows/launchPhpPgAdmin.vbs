Option Explicit

Dim WSHShell, shellApp, strRegKey, strApachePort, strURL, strArgs
Set WSHShell=CreateObject("WScript.Shell")
strRegKey = "HKEY_LOCAL_MACHINE\SOFTWARE\EnterpriseDB\ApachePhp\"
strApachePort = WSHShell.RegRead(strRegKey & "APACHE_PORT")

'taken host as localhost as the application is installed in the local machine only
strURL="http://localhost:" & strApachePort & "/phpPgAdmin"
strArgs= "url.dll,FileProtocolHandler " & strURL

Set shellApp = WScript.CreateObject("Shell.Application")
shellApp.ShellExecute "rundll32.exe", strArgs, "", "open", 0
