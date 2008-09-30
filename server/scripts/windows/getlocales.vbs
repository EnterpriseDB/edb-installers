On Error Resume Next

' PostgreSQL server locales script for Linux (returns valid locales on the system)
' Dave Page, EnterpriseDB

' Check the command line
If WScript.Arguments.Count <> 0 Then
 Wscript.Echo "Usage: installruntimes.vbs"
 Wscript.Quit 127
End If




WScript.Echo "getlocales.vbs ran to completion"
WScript.Quit 0
