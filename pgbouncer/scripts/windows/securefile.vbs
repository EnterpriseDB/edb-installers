On Error Resume Next

strFilename = WScript.Arguments.Item(0)
strUsername = WScript.Arguments.Item(1)

' Get temporary filenames
Set objShell = WScript.CreateObject("WScript.Shell")
Set objFso = CreateObject("Scripting.FileSystemObject")
Set objTempFolder = objFso.GetSpecialFolder(2)
strBatchFile = Replace(objFso.GetTempName, ".tmp", ".bat")
strOutputFile = objTempFolder.Path & "\" & objFso.GetTempName
Set objFso = CreateObject("Scripting.FileSystemObject")

' Is this Vista or above?
Function IsVistaOrNewer()
    Set objWMI = GetObject("winmgmts:\\.\root\cimv2")
    Set colItems = objWMI.ExecQuery("Select * from Win32_OperatingSystem",,48)

    For Each objItem In colItems
        strVersion = Left(objItem.Version, 3)
    Next

    If InStr(strVersion, ".") > 0 Then
        majorVersion = CInt(Left(strVersion,  InStr(strVersion, ".") - 1))
    ElseIf InStr(strVersion, ",") > 0 Then
        majorVersion = CInt(Left(strVersion,  InStr(strVersion, ",") - 1))
    Else
        majorVersion = CInt(strVersion)
    End If

    If majorVersion >= 6.0 Then
        IsVistaOrNewer = True
    Else
        IsVistaOrNewer = False
    End If
End Function

' Execute a command
Function DoCmd(strCmd)
    Set objBatchFile = objTempFolder.CreateTextFile(strBatchFile, True)
    objBatchFile.WriteLine "@ECHO OFF"
    objBatchFile.WriteLine strCmd & " > """ & strOutputFile & """ 2>&1"
    objBatchFile.WriteLine "EXIT /B %ERRORLEVEL%"
    objBatchFile.Close
    DoCmd = objShell.Run(objTempFolder.Path & "\" & strBatchFile, 0, True)
    If objFso.FileExists(objTempFolder.Path & "\" & strBatchFile) = True Then
        objFso.DeleteFile objTempFolder.Path & "\" & strBatchFile, True
    End If
    If objFso.FileExists(strOutputFile) = True Then
        Set objOutputFile = objFso.OpenTextFile(strOutputFile, ForReading)
        WScript.Echo objOutputFile.ReadAll
        objOutputFile.Close
        objFso.DeleteFile strOutputFile, True
    End If
End Function

Sub Warn(msg)
    WScript.Echo msg
    iWarn = 2
End Sub

If IsVistaOrNewer() = True Then
    WScript.Echo "Securing userlist.txt file (using icacls):"
    iRet = DoCmd("icacls """ & strFilename & """ /T /grant:r *S-1-5-32-544:M /grant:r """ & strUsername & """:M")
Else
    WScript.Echo "Securing userlist.txt file (using cacls): " & strFilename & " " & strUsername
    iRet = DoCmd("echo y|cacls """ & strFilename & """ /T /G Administrators:F """ & strUsername & """:C")
End If
if iRet <> 0 Then
    Warn "Failed to secure the data directory (" & strFilename & ")"
End If

