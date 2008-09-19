dim objShell
strPath = WScript.Arguments.Item(0)
strApp = WScript.Arguments.Item(1)
strArguments = WScript.Arguments.Item(2)
strWD = WScript.Arguments.Item(3)
set objShell = CreateObject("Shell.Application")
If strCmd <> nil Then
   strCmd = strPath & "\\" & strApp
Else
   strCmd = strApp
End If
objShell.ShellExecute strCmd, strArguments, strWD, "open", 0
set objShell = nothing
