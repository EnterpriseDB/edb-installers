Option Explicit

Dim WSHShell, shellApp, strRegKey, strApachePort, strURL, strArgs
Set WSHShell=CreateObject("WScript.Shell")
strRegKey = "HKEY_LOCAL_MACHINE\SOFTWARE\EnterpriseDB\ApachePhp\"
strApachePort = WSHShell.RegRead(strRegKey & "APACHE_PORT")

strURL="http://localhost:" & strApachePort & "/Drupal"
strArgs= "url.dll,FileProtocolHandler " & strURL

Set shellApp = WScript.CreateObject("Shell.Application")
shellApp.ShellExecute "rundll32.exe", strArgs, "", "open", 0
