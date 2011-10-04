On Error Resume Next

' PostgreSQL server cluster init script for Windows
' Dave Page, EnterpriseDB

' Findings (ASHESH):
' - http://support.microsoft.com/kb/951978
' - http://social.msdn.microsoft.com/Forums/en-US/vssetup/thread/ca9c69e6-9b75-462f-b2e5-92198e584981

Const ForReading = 1
Const ForWriting = 2

' Check the command line
If WScript.Arguments.Count <> 7 Then
 Wscript.Echo "Usage: initcluster.vbs <OSUsername> <SuperUsername> <Password> <Install dir> <Data dir> <Port> <Locale>"
 Wscript.Quit 127
End If

strOSUsername = WScript.Arguments.Item(0)
strUsername = WScript.Arguments.Item(1)
strPassword = WScript.Arguments.Item(2)
strInstallDir = WScript.Arguments.Item(3)
strDataDir = WScript.Arguments.Item(4)
lPort = CLng(WScript.Arguments.Item(5))
strLocale = WScript.Arguments.Item(6)

' Remove any trailing \'s from the data dir - they will confuse cacls
If Right(strDataDir, 1) = "\" Then
    strDataDir = Left(strDataDir, Len(strDataDir)-1)
End IF

Dim strInitdbPass
iWarn = 0

Dim objShell, objFso, objTempFolder, objWMI
' Get temporary filenames
Set objShell = WScript.CreateObject("WScript.Shell")
If objShell Is Nothing Then
  WScript.Echo "Couldn't create WScript.Shell object..."
ElseIF IsObject(objShell) Then
  WScript.Echo "WScript.Shell Initialized..."
Else
  WScript.Echo "WScript.Shell not initialized..."
End If

Set objFso = CreateObject("Scripting.FileSystemObject")
If objFso Is Nothing Then
  WScript.Echo "Couldn't create Scripting.FileSystemObject object..."
ElseIf IsObject(objFso) Then
  WScript.Echo "Scripting.FileSystemObject initialized..."
Else
  WScript.Echo "Scripting.FileSystemObject not initialized..."
End If

Set objTempFolder = objFso.GetSpecialFolder(2)
strBatchFile = Replace(objFso.GetTempName, ".tmp", ".bat")
strOutputFile = objTempFolder.Path & "\" & objFso.GetTempName

' Change the current directory to the installation directory
' This is important, because initdb will drop Administrative
' permissions and may lose access to the current working directory
objShell.CurrentDirectory = strInstallDir

' Is this Vista or above?
Function IsVistaOrNewer()
    WScript.Echo "Called IsVistaOrNewer()..."
    Set objWMI = GetObject("winmgmts:\\.\root\cimv2")
    If objWMI Is Nothing Then
        WScript.Echo "    Couldn't create 'winmgmts:\\.\root\cimv2' object"
        IsVistaOrNewer=false
    ElseIF IsObject(objWMI) Then
        WScript.Echo "    'winmgmts' object initialized..."
    Else
        WScript.Echo "    'winmgmts' object not initialized..."
    End If
    Set colItems = objWMI.ExecQuery("Select * from Win32_OperatingSystem",,48)
	
    For Each objItem In colItems
        strVersion = Left(objItem.Version, 3)
    Next
    WScript.Echo "    Version:" & strVersion
	
    If InStr(strVersion, ".") > 0 Then
        majorVersion = CInt(Left(strVersion,  InStr(strVersion, ".") - 1))
    ElseIf InStr(strVersion, ",") > 0 Then
        majorVersion = CInt(Left(strVersion,  InStr(strVersion, ",") - 1))
    Else
        majorVersion = CInt(strVersion)
    End If

    WScript.Echo "    MajorVersion:" & majorVersion
	
    If majorVersion >= 6.0 Then
        IsVistaOrNewer = True
    Else
        IsVistaOrNewer = False
    End If
End Function

' Execute a command
Function DoCmd(strCmd)
    Dim objBatchFile
    Set objBatchFile = objTempFolder.CreateTextFile(strBatchFile, True)
    objBatchFile.WriteLine "@ECHO OFF"
    objBatchFile.WriteLine strCmd & " > """ & strOutputFile & """ 2>&1"
	objBatchFile.WriteLine "EXIT /B %ERRORLEVEL%"
    objBatchFile.Close
    WScript.Echo "    Executing batch file '" & strBatchFile & "'..."
    DoCmd = objShell.Run(objTempFolder.Path & "\" & strBatchFile, 0, True)
    If objFso.FileExists(objTempFolder.Path & "\" & strBatchFile) = True Then
        objFso.DeleteFile objTempFolder.Path & "\" & strBatchFile, True
    Else
        WScript.Echo "    Batch file '" & strBatchFile & "' does not exist..."
    End If
    If objFso.FileExists(strOutputFile) = True Then
        Dim objOutputFile
        Set objOutputFile = objFso.OpenTextFile(strOutputFile, ForReading)
        WScript.Echo "    " & objOutputFile.ReadAll
        objOutputFile.Close
        objFso.DeleteFile strOutputFile, True
    Else
        WScript.Echo "    Output file does not exists..."
    End If
End Function

Sub Die(msg)
    WScript.Echo "Called Die(" & msg & ")..."
    If objFso.FileExists(strInitdbPass) = True Then
        objFso.DeleteFile strInitdbPass, True
    End If
    WScript.Echo msg
    WScript.Quit 1
End Sub

Sub Warn(msg)
    WScript.Echo msg
    iWarn = 2
End Sub

Function CreateDirectory(DirectoryPath)
    WScript.Echo "Called CreateDirectory(" & DirectoryPath & ")..."
    If objFso.FolderExists(DirectoryPath) Then Exit Function

    Call CreateDirectory(objFso.GetParentFolderName(DirectoryPath))
    objFso.CreateFolder(DirectoryPath)
End Function

' Create a password file
strInitdbPass = strInstallDir & "\" & objFso.GetTempName
Dim objInitdbPass
Set objInitdbPass = objFso.OpenTextFile(strInitdbPass, ForWriting, True)
WScript.Echo Err.description
objInitdbPass.WriteLine(strPassword)
objInitdbPass.Close

' Create the data directory
If objFso.FolderExists(strDataDir) <> True Then
    CreateDirectory(strDataDir)
    If Err.number <> 0 Then
        Die "Failed to create the data directory (" & strDataDir & ")"
    End If
End If

Dim objNetwork
Set objNetwork = CreateObject("WScript.Network")
If objNetwork Is Nothing Then
    WScript.Echo "Couldn't create WScript.Network object"
ElseIf IsObject(objNetwork) Then
    WScript.Echo "WScript.Network initialized..."
Else
    WScript.Echo "WScript.Network not initialized..."
End If

' Loop up the directory path, and ensure we have read permissions
' on the entire path leading to the data directory
arrDirs = Split(strDataDir, "\")
nDirs = UBound(arrDirs)
strThisDir = ""

For d = 0 To nDirs
    strThisDir = strThisDir & arrDirs(d)

    If IsVistaOrNewer() = True Then
        WScript.Echo "Ensuring we can read the path " & strThisDir & " (using icacls) to " & objNetwork.Username & ":"
        IF d <> 0 Then
            iRet = DoCmd("icacls """ & strThisDir & """ /grant """ & objNetwork.Username & """:(NP)(RX)")
        ELSE
            ' Drive letter must not be surronded by double-quotes and ends with slash (\)
            iRet = DoCmd("icacls " & strThisDir & "\ /grant """ & objNetwork.Username & """:(NP)(RX)")
        END IF
    Else
        WScript.Echo "Ensuring we can read the path " & strThisDir & " (using cacls):"
        IF d <> 0 Then
            iRet = DoCmd("echo y|cacls """ & strThisDir & """ /E /G """ & objNetwork.Username & """:R")
        ELSE
            ' Drive letter must not be surronded by double-quotes and ends with slash (\)
            iRet = DoCmd("echo y|cacls " & strThisDir & "\ /E /G """ & objNetwork.Username & """:R")
        END IF
    End If
    if iRet <> 0 Then
        WScript.Echo "Failed to ensure the path " * strThisDir & " is readable"
    End If

    strThisDir = strThisDir & "\"
Next

If IsVistaOrNewer() = True Then
    WScript.Echo "Ensuring we can write to the data directory (using icacls) to  " & objNetwork.Username & ":"
    iRet = DoCmd("icacls """ & strDataDir & """ /T /grant:r """ & objNetwork.Username & """:(OI)(CI)F")
Else
    WScript.Echo "Ensuring we can write to the data directory (using cacls):"
    iRet = DoCmd("echo y|cacls """ & strDataDir & """ /E /T /G """ & objNetwork.Username & """:F")
End If
if iRet <> 0 Then
    WScript.Echo "Failed to ensure the data directory is accessible (" & strDataDir & ")"
End If


' Initialise the database cluster, and set the appropriate permissions/ownership
if strLocale = "DEFAULT" Then
    iRet = DoCmd("""" & strInstallDir & "\bin\initdb.exe"" --pwfile """ & strInitdbPass & """ --encoding=UTF-8 -A md5 -U " & strUsername & " -D """ & strDataDir & """")
Else
    iRet = DoCmd("""" & strInstallDir & "\bin\initdb.exe"" --pwfile """ & strInitdbPass & """ --locale=""" & strLocale & """ --encoding=UTF-8 -A md5 -U " & strUsername & " -D """ & strDataDir & """")
End If

if iRet <> 0 Then
    Die "Failed to initialise the database cluster with initdb"
End If

' Delete the password file
If objFso.FileExists(strInitdbPass) Then
    objFso.DeleteFile strInitdbPass, True
End If

' Edit the config files
' Set the following in postgresql.conf:
'      listen_addresses = '*'
'      port = $PORT
'      log_destination = 'stderr'
'      logging_collector = on
'      log_line_prefix = '%t '
Dim objConfFil
Set objConfFile = objFso.OpenTextFile(strDataDir & "\postgresql.conf", ForReading)
If objConfFile Is Nothing Then
   WScript.Echo "Reading:    objConfFile is nothing..."
ElseIf IsObject(objConfFile) Then
   WScript.Echo "Reading:    " & strDataDir & "\postgresql.conf exists..."
Else
   WScript.Echo "Reading:    " & strDataDir & "\postgresql.conf not exists..."
End If
strConfig = objConfFile.ReadAll
objConfFile.Close
strConfig = Replace(strConfig, "#listen_addresses = 'localhost'", "listen_addresses = '*'")
strConfig = Replace(strConfig, "#port = 5432", "port = " & lPort)
strConfig = Replace(strConfig, "#log_destination = 'stderr'", "log_destination = 'stderr'")
strConfig = Replace(strConfig, "#logging_collector = off", "logging_collector = on")
strConfig = Replace(strConfig, "#log_line_prefix = ''", "log_line_prefix = '%t '")
Set objConfFile = objFso.OpenTextFile(strDataDir & "\postgresql.conf", ForWriting)
If objConfFile Is Nothing Then
   WScript.Echo "Writing:    objConfFile is nothing..."
ElseIf IsObject(objConfFile) Then
   WScript.Echo "Writing:    " & strDataDir & "\postgresql.conf exists..."
Else
   WScript.Echo "Writing:    " & strDataDir & "\postgresql.conf not exists..."
End If
objConfFile.WriteLine strConfig
objConfFile.Close

' Loop up the directory path, and ensure the service account has read permissions
' on the entire path leading to the data directory
arrDirs = Split(strDataDir, "\")
nDirs = UBound(arrDirs)
strThisDir = ""

For d = 0 To nDirs
    strThisDir = strThisDir & arrDirs(d)

    If IsVistaOrNewer() = True Then
        WScript.Echo "Ensuring the service account can read the path " & strThisDir & " (using icacls) to " & strOSUsername & ":"
        If d <> 0 Then
            iRet = DoCmd("icacls """ & strThisDir & """ /grant """ & strOSUsername & """:(NP)(RX)")
        Else
            ' Drive letter must not be surronded by double-quotes and ends with slash (\)
            iRet = DoCmd("icacls " & strThisDir & "\ /grant """ & strOSUsername & """:(NP)(RX)")
        End If
    Else
        WScript.Echo "Ensuring the service account can read the path " & strThisDir & " (using cacls):"
        If d <> 0 Then
            iRet = DoCmd("echo y|cacls """ & strThisDir & """ /E /G """ & strOSUsername & """:R")
        Else
            ' Drive letter must not be surronded by double-quotes and ends with slash (\)
            iRet = DoCmd("echo y|cacls " & strThisDir & "\ /E /G """ & strOSUsername & """:R")
        End If
    End If
    if iRet <> 0 Then
        WScript.Echo "Failed to ensure the path " * strThisDir & " is readable by the service account"
    End If
    strThisDir = strThisDir & "\"
Next

' Create the <DATA_DIR>\pg_log directory (if not exists)
' Create it before updating the permissions, so that it will also get affected
If  Not objFso.FolderExists(strDataDir & "\pg_log") Then
    newfolder = objFso.CreateFolder (strDataDir & "\pg_log")
End If

' Secure the data directory
If IsVistaOrNewer() = True Then
    WScript.Echo "Granting service account access to the data directory (using icacls) to " & strOSUsername & ":"
    iRet = DoCmd("icacls """ & strDataDir & """ /T /C /grant """ & strOSUsername & """:(OI)(CI)(F)")
Else
    WScript.Echo "Granting service account access to the data directory (using cacls):"
    iRet = DoCmd("echo y|cacls """ & strDataDir & """ /E /T /C /G """ & strOSUsername & """:F")
End If
if iRet <> 0 Then
    Warn "Failed to grant service account access to the data directory (" & strDataDir & ")"
End If

WScript.Echo "initcluster.vbs ran to completion"
WScript.Quit iWarn

