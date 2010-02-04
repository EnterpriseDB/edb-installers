Dim strCmd, strTempDir, strOutputFile, strErrorFile, bIsCommand

SET FSO       = CreateObject("Scripting.FileSystemObject")
SET WShell    = CreateObject("Wscript.Shell")
SET WSO       = WScript.StdOut
SET WSE       = WScript.StdErr
strTempDir    = FSO.GetSpecialFolder(2)
strOutputFile = strTempDir & "\" & FSO.GetTempName
strErrorFile  = strTempDir & "\" & FSO.GetTempName
bIsCommand    = false

' A function to facilitate the use command line utilities
'
Function CmdPrompt()
  If bIsCommand = true Then
    l_strCmdLine = """%comspec%"" /c " & strCmd & ">" & Chr(34) & strOutputFile & Chr(34) & _
       " 2>"  & Chr(34) & strErrorFile & Chr(34)
  Else
    l_strCmdLine = strCmd & " >" & Chr(34) & strOutputFile & Chr(34) & _
       " 2>"  & Chr(34) & strErrorFile & Chr(34)
  End If
  WScript.Echo l_strCmdLine

  nRes = WShell.Run(l_strCmdLine, 0, True)
  If FSO.FileExists(strOutputFile) Then
    With FSO.OpenTextFile(strOutputFile)
      Do While Not .AtEndOfStream
        WSO.WriteLine .ReadLine
      Loop
    End With
    FSO.DeleteFile strOutputFile 
  End if
  If FSO.FileExists(strErrorFile) Then
    With FSO.OpenTextFile(strErrorFile)
      Do While Not .AtEndOfStream
        WSE.WriteLine .ReadLine
      Loop
    End With
    FSO.DeleteFile strErrorFile 
  End if
  If Err.Number <> 0 Then
    WSE.WriteLine "ERROR:" & CStr(Err.Number) & Err.Description
  End If
  CmdPrompt = iRes
End Function 

If WScript.Arguments.Count < 1 Then
    WSE.WriteLine "runCmd: Please Provide the command/program to run..."
    WScript.Quit 127
End If

Dim iIndex, iStatus, currIndex
currIndex = 0

If WScript.Arguments.Item(currIndex) = "-c" Then
  bIsCommand = true
  currIndex = currIndex + 1
End If

' command provided
If WScript.Arguments.Count = currIndex Then
  WSE.WriteLine "runCmd: Please Provide the command/program to run..."
  WScript.Quit 127
End If

strQuote = """"
' Do not put quote around the command, but around it's arguments
If bIsCommand = True Then
  strQuote = ""
End If

For iIndex = currIndex To WScript.Arguments.Count - 1
  strCmd = strCmd & " " & strQuote &  WScript.Arguments.Item(iIndex) & strQuote
  strQuote = """"
Next

strCmd = Trim(strCmd)

WScript.Quit CmdPrompt()
