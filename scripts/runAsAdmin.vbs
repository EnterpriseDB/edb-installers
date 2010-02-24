' Postgres Plus installer script (extract-only mode) for windows
' Ashesh Vashi, EnterpriseDB

'Initialization
Dim WSI, FSO, WshShell, WshApp, TempFolder, LogFile, WMIService, Services, Locator
Dim strSuperUser, strSuperPassword, strServiceAccount, strServicePassword, strDataDir, strInstallDir, strLocale, strServiceName, iPbPort
Dim bUnattended, bWScript, bInstallRuntimes, bDebug
Dim strExitMsg, strVCRedistFile, strLogFile

Dim iStatus, strScriptOutput, strScriptError
Dim objDevServer

Dim bInstallPostGIS, bInstallSlony, bInstallPgAgent, bInstallPsqlODBC, bInstallPgBouncer, bInstallSBP
Dim CONSTADMINDATABASE, CONSTPGAGENTSERVICE
CONSTADMINDATABASE = "postgres"

const HKCU = &H80000001
const HKLM = &H80000002

LogFile = NULL
SET WSI = WScript.StdIn
SET WMIService = GetObject("winmgmts:\\.\root\cimv2")
SET FSO = CreateObject("Scripting.FileSystemObject")
Set WshShell = CreateObject("WScript.Shell")
Set WshSystemEnv = WshShell.Environment("SYSTEM")
Set WshApp   = CreateObject("Shell.Application")
Set TempFolder = FSO.GetSpecialFolder(2)
strTempName = FSO.GetTempName
strLogFile = TempFolder.Path & "\" & Left(strTempName, Len(strTempName) - 4) & "_rar.log"

' TODO: We need to take care about 64 bit windows too in future.
strVCRedistFile = "\installer\vcredist_x86.exe"

strInstallDir      = FSO.GetAbsolutePathName(".")
strSuperUser       = "postgres"
strSuperPassword   = "postgres"
strServicePassword = "postgres"
strLocale          = "DEFAULT"
strServiceName     = ""
iPort              = 5432
bUnattended        = false
bInstallRuntimes   = true
bDebug             = false
bWScript           = false
iPbPort            = 6543
strCompList        = "postgis,slony,pgagent,psqlodbc,pgbouncer,sbp"

bInstallPostGIS    = "Y"
bInstallSlony      = "Y"
bInstallPgAgent    = "Y"
bInstallPsqlODBC   = "Y"
bInstallPgBouncer  = "Y"
bInstallSBP        = "Y"

Sub ResetComponentSelection()
  bInstallPostGIS    = "N"
  bInstallSlony      = "N"
  bInstallPgAgent    = "N"
  bInstallPsqlODBC   = "N"
  bInstallPgBouncer  = "N"
  bInstallSBP        = "N"
End Sub

Sub SelectComponents(p_strComponentList)
  Dim l_iIndex, l_iLBound, l_iUBound, l_arrayComponents
  Call ResetComponentSelection
  If TRIM(p_strComponentList) = "" Then
    Usage 1
  End If
  l_arrayComponents = split(p_strComponentList, ",")
  l_iLBound = LBound(l_arrayComponents)
  l_iUBound = UBound(l_arrayComponents)

  For l_iIndex = iLBound To iUBound Step 1
    Select Case l_arrayComponents(l_iIndex)
      Case "postgis"
        bInstallPostGIS = "Y"
      Case "slony"
        bInstallSlony = "Y"
      Case "pgagent"
        bInstallPgAgent = "Y"
      Case "psqlodbc"
        bInstallPsqlODBC = "Y"
      Case "pgbouncer"
        bInstallPgBouncer = "Y"
      Case "sbp"
        bInstallSBP = "Y"
      Case Else
        strExitMsg = "Unknown component : " & l_arrayComponents(l_iIndex)
        Usage 1
    End Select
  Next
End Sub

Sub Init()
  If NOT bUnattended Then
    WScript.Echo "NOTE: " & VBCRLF & _
                 "This script should be running with the administrator rights." & VBCRLF & _
                 "Please press enter to continue or press Ctrl+C to exit and rerun the script appropriately." & VBCRLF & VBCRLF & _
                 "You must ensure that the admin user account running this script has full permissions on all directories in the installation path. Permissions inherited through group membership will not suffice."
    WSI.ReadLine
  End If
  ' Open Log File
  SET LogFile = FSO.CreateTextFile(strLogFile, True)
  Err.Clear

  'Instantiate a reference to SWbemLocator
  Set Locator = CreateObject("WbemScripting.SWbemLocator")

  'Error check
  If (Err.Number <> 0) And Not IsObject(Locator) Then
    LogWarn "Error instantiating an object reference." & VBCRLF & _
            "       Number (dec) : "   & Err.Number & VBCRLF & _
            "       Number (hex) : &H" & Hex(Err.Number) & VBCRLF & _
            "       Description  : "   & Err.Description & VBCRLF & _
            "       Source       : "   & Err.Source
    Call WMI_Services_Error_Lookup(Err.Number)
    Set Services = Nothing
    Call Finish
    Exit Sub
  End If

  Err.Clear
  Set Services = Locator.ConnectServer(".", "Root/CimV2")
  'Error check
  If (Err.Number <> 0) And Not IsObject(Services) Then
    LogWarn " Error connecting to WMI." & VBCRLF & _
            "         Number (dec) : "   & Err.Number & VBCRLF & _
            "         Number (hex) : &H" & Hex(Err.Number) & VBCRLF & _
            "         Description  : "   & Err.Description & VBCRLF & _
            "         Source       : "   & Err.Source

    'Look up WMI errors
    Call WMI_Services_Error_Lookup(Err.Number)
    Set Services = Nothing
    Call Finish
    Exit Sub
  End If
  'Set the Impersonatin Level
  Services.Security_.ImpersonationLevel = 3
End Sub

Sub Finish(p_iRetCode)
  If IsObject(LogFile) Then
    WScript.Echo "Logs is saved in: " & strLogFile
    LogFile.Close
  End If
  SET WSI = Nothing
  SET FSO = Nothing
  SET WshShell = Nothing
  SET WshApp = Nothing
  SET TempFolder = Nothing
  SET LogFile = Nothing
  SET WMIService = Nothing
  SET Services = Nothing
  SET Locator = Nothing
  WScript.Quit p_iRetCode
End Sub

Function IsFileExists(ByVal p_strPath, ByVal p_strFileName, ByRef p_strErrMsg)
  Dim l_bFolderVal
  l_bFolderVal = true
  IsFileExists = true
  If p_strPath = NULL OR Trim(p_strPath) = "" Then
    l_bFolderVal = false
    l_strFilePath = p_strFileName
  Else
    l_strFilePath = p_strPath & "\" & p_strFileName
  End If

  If NOT FSO.FileExists(l_strFilePath) Then
    If l_bFolderVal Then
      p_strErrMsg = "File (" & p_strFileName & ") couldn't be found."
    Else
      p_strErrMsg = "File (" & p_strFileName & ") couldn't find in the given path (" & p_strPath & ")."
    End If
    IsFileExists = false
  End If
End Function

Sub CopyFile(p_strSrcFile, p_strDestFile, p_bOverWriteExists)
On Error Resume Next
  FSO.CopyFile p_strSrcFile, p_strDestFile, p_bOverWriteExists
End Sub

Sub BackupFile (ByVal p_strFilePath)
  LogMessage "Backing up file : " & p_strFilePath
  If IsFileExists(NULL, p_strFilePath, l_strDummy) Then
    l_iIndex = 0
    While IsFileExists(NULL, p_strFilePath & ".bak_" & l_iIndex, l_strDummy)
      l_iIndex = l_iIndex + 1
    Wend
    CopyFile p_strFilePath, p_strFilePath & ".bak_" & l_iIndex, false
  End If
End Sub

Sub BackupNUseOriginalFile(ByVal p_strFilePath)
  LogMessage "BackupNUserOriginalFile: Backup a file with .orig extension and " & _
             "a file exists with the same name, than use it instead of the current one."
  If IsFileExists(NULL, p_strFilePath & ".orig", l_strDummy) Then
    ' If Backup file Exists, we will use that while configuration
    FSO.CopyFile p_strFilePath & ".orig", p_strFilePath, true
  Else
    ' And If Backup File Does not exists, we will make a backup of it
    FSO.CopyFile p_strFilePath, p_strFilePath & ".orig", true
  End If
End Sub

Sub ShowMessage(p_strMsg)
  If NOT bWScript Then
    WScript.Echo p_strMsg
  End If
  If IsObject(LogFile) Then
    LogFile.WriteLine p_strMsg
  End If
End Sub

Sub LogMessage(p_strMsg)
  If bDebug And NOT bWScript Then
    WScript.Echo p_strMsg
  End If
  If IsObject(LogFile) Then
    LogFile.WriteLine p_strMsg
  Else
    If NOT bDebug And NOT bWScript Then
      WScript.Echo p_strMsg
    End If
  End If
End Sub

Sub LogError(p_strErrMsg)
  WScript.Echo vbCRLF & "FATAL ERROR: " & p_strErrMsg & vbCRLF
  If IsObject(LogFile) Then
    LogFile.WriteLine vbCRLF & "FATAL ERROR: " & p_strErrMsg & vbCRLF
  End If
  Call Finish(-1)
End Sub

Sub LogWarn(p_strMsg)
  If NOT bWScript Then
    WScript.Echo vbCRLF & "WARNING: " & p_strMsg & vbCRLF
  End If
  LogFile.WriteLine vbCRLF & "WARNING: " & p_strMsg & vbCRLF
End Sub

Sub LogNote(p_strNote)
  If NOT bWScript AND NOT bUnattended Then
    WScript.Echo vbCRLF & "NOTE: " & p_strNote & vbCRLF
  End If
  If IsObject(LogFile) Then
    LogFile.WriteLine vbCRLF & "NOTE: " & p_strNote & vbCRLF
  Else
    If NOT bUnattended And NOT bWScript Then
      WScript.Echo vbCRLF & "NOTE: " & p_strNote & vbCRLF
    End If
  End If
End Sub

Sub SetVariableFromScriptOutput(ByVal p_strCmd, ByVal p_aCmdArgs, ByRef pl_strVariable, ByRef pl_strErr, ByRef pl_iStatus)
  Dim l_iLArgs, l_iUArgs, lExec, l_strCmdArgs, l_strStdOut, l_strStdErr
  pl_strVariable = ""
  pl_iStatusCode = 127

  If p_strCmd = NULL OR Trim(p_strCmd) = "" Then
    LogError "SetVariableFromScriptOutput: Provide command to execute."
  End If

  If NOT IsArray(p_aCmdArgs) Then
    If NOT p_aCmdArgs = "" Then
      l_strCmdArgs = """" & p_aCmdArgs & """"
    End If
  Else
    l_iLArgs = LBound(p_aCmdArgs)
    l_iUArgs = UBound(p_aCmdArgs)
    For l_index = l_iLArgs To l_iUArgs Step 1
      l_strCmdArgs = l_strCmdArgs & " """ & p_aCmdArgs(l_index) & """"
    Next
  End If
  p_strCmd = Trim("""" & Trim(p_strCmd) & """ " & Trim(l_strCmdArgs))

  'The tool is launched
  LogMessage "SetVariableFromScriptOutput: " & vbCRLF & p_strCmd
  set lExec = WshShell.Exec(p_strCmd)

  If lExec.Status = 0 Then
    lExec.Terminate()
  End If

  pl_iStatusCode = lExec.ExitCode
  Do While lExec.StdOut.AtEndOfStream <> True
    If pl_strVariable = "" Then
      pl_strVariable = lExec.StdOut.ReadLine
    Else
      pl_strVariable = pl_strVariable & vbCRLF & lExec.StdOut.ReadLine
    End If
  Loop
  LogMessage vbCRLF & "Script Output: " & _
             vbCRLF & "---------------" & _
             vbCRLF & pl_strVariable

  Do While lExec.StdErr.AtEndOfStream <> True
    l_strStdErr = l_strStdErr & vbCRLF & lExec.StdErr.ReadLine
  Loop

  LogMessage vbCRLF & "Script Error : " & _
             vbCRLF & "---------------" & _
             vbCRLF & l_strStdErr
End Sub

Sub RunProgram(ByVal p_strCmd, ByRef p_aCmdArgs, ByRef pl_strStdOut, ByRef pl_strStdErr, ByRef pl_iStatusCode)
  Dim lExec
  Dim l_iLArgs, l_iUArgs, l_strCmdArgs
  L_CONST_TIMEOUT = 5000
  pl_strStdOut   = ""
  pl_strStdErr   = ""
  pl_iStatusCode = 0

  If p_strCmd = NULL OR Trim(p_strCmd) = "" Then
    LogError "RunProgram : Provide command to execute."
  End If

  If NOT IsArray(p_aCmdArgs) Then
    If NOT p_aCmdArgs = "" Then
      l_strCmdArgs = """" & p_aCmdArgs & """"
    End If
  Else
    l_iLArgs = LBound(p_aCmdArgs)
    l_iUArgs = UBound(p_aCmdArgs)
    For l_index = l_iLArgs To l_iUArgs Step 1
      l_strCmdArgs = l_strCmdArgs & " """ & p_aCmdArgs(l_index) & """"
    Next
  End If
  p_strCmd = Trim( """" & p_strCmd & """ " & Trim(l_strCmdArgs))

  LogMessage "RunProgram: " & p_strCmd

  Set lExec = WshShell.Exec(p_strCmd)

  l_iWaitCount = 0
  Do
    WScript.Sleep 100
    l_iWaitCount = l_iWaitCount + 1
    If lExec.StdOut.AtEndOfStream <> True Then
      pl_strStdOut = pl_strStdOut & vbCRLF & lExec.StdOut.ReadLine
    End If
  Loop Until lExec.Status <> 0 OR l_iWaitCount >= L_CONST_TIMEOUT

  l_bTerminateAbnormally = false
  If l_iWaitCount >= L_CONST_TIMEOUT AND lExec.Status = 0 Then
    lExec.Terminate()
    l_bTerminateAbnormally = true
  End If

  pl_iStatusCode = lExec.ExitCode
  Do While lExec.StdOut.AtEndOfStream <> True
    pl_strStdOut = pl_strStdOut & vbCRLF & lExec.StdOut.ReadLine
  Loop
  LogMessage vbCRLF & "Script Output: " & _
             vbCRLF & "---------------" & _
             vbCRLF & pl_strStdOut

  Do While lExec.StdErr.AtEndOfStream <> True
    pl_strStdErr = pl_strStdErr & vbCRLF & lExec.StdErr.ReadLine
  Loop

  LogMessage vbCRLF & "Script Error : " & _
             vbCRLF & "---------------" & _
             vbCRLF & pl_strStdErr
  If l_bTerminateAbnormally Then
    LogError "Couldn't complete execution of the command (" & p_strCmd & ")"
  End If
End Sub

Function Usage(exitcode)
  Dim strUsage
  strUsage = "USAGE: " & VBCRLF & _
    "  " & WScript.FullName & " //nologo " & WScript.ScriptFullName & " <options> " & VBCRLF & _
    "options:" & VBCRLF &  _
    "-su  | --superuser <superuser> # Database Super User" & VBCRLF & _
    "         Default: postgres" & VBCRLF & _
    "-sp  | --superpassword <superpassword> # Database Super Password" & VBCRLF & _
    "         Default: postgres" & VBCRLF & _
    "-sa  | --serviceaccount <username> # Service Account (OS User)" & VBCRLF & _
    "-sn  | --servicename <service-name> # Name of PostgreSQL Service" & VBCRLF & _
    "         Default: pgsql-<PG_VERSION>" & VBCRLF & _
    "-sap | --servicepassword <password> # Password for the service account" & VBCRLF & _
    "         Default: postgres" & VBCRLF & _
    "-d   | --datadir <directory> # Data Directory" & VBCRLF & _
    "         Defalut: <Installation-Directory>\data" & VBCRLF & _
    "-i   | --installdir <directory> # Installation Directory" & VBCRLF & _
    "         Default: <curernt working directory>" & VBCRLF & _
    "-l   | --locale <locale> # Locale" & VBCRLF & _
    "         Defualt: DEFAULT" & VBCRLF & _
    "-p   | --port <port> # Port" & VBCRLF & _
    "         Default: 5432" & VBCRLF & _
    "-pb  | --pgbouncer-port # Port for pgbouncer" & VBCRLF & _
    "         Default: 6543" & VBCRLF & _
    "-c   | --components-list # Comma seperated comma list" & VBCRLF & _
    "         Default: " & strCompList & VBCRLF & _
    "-u   | --unattended # Unattended Mode" & VBCRLF & _
    "-r   | --install-runtimes <1|0> # Install Runtimes" & VBCRLF & _
    "         Default: 1" & VBCRLF & _
    "-h   | --help # Show usage"
  If exitcode <> 0 Then
    LogError strExitMsg & VBCRLF & VBCRLF & strUsage
  End If
  WScript.Echo strUsage
  WScript.Quit(exitcode)
End Function

'----------------------------- INI Read -----------------------------------
' USAGE:
'   INIRead ( INI_FILE_PATH, SECTION, VARIABLE)
' Example:
'    - To read a variable from global section
'      INIRead("c:\test.ini", "", "superuser")
'    - To read a variable from the particular section (here: SEC1)
'      INIRead("c:\test.ini", "SEC1", "superuser")
Function INIRead(strFile,strSection,strKey)
  Dim objReadFile,strLine,blnFoundSect,blnReadAll,intKeySize
  If Not FSO.FileExists(strFile) Then
    INIRead = "" : Exit Function
  End if
  Set objReadFile = FSO.OpenTextFile(strFile,1)
  blnFoundSect = False : blnReadAll=False : intKeySize = Len(strKey)+1
  If strSection = "" Then
    blnFoundSect = true
  End If
  Do While Not objReadFile.AtEndOfStream
    strLine= objReadFile.ReadLine
    If blnFoundSect Then
    If Left(strLine,1)="[" Then
      If blnReadAll=False then INIRead = ""
        objReadFile.close : Exit Function
      End if
      If blnReadAll then
        INIRead = IniRead & strLine & VBCRLF
      Else
        If Left(strLine,intKeySize) = strKey & "=" then
          INIRead=Right(strLine,Len(strLine)-intKeySize)
          objReadFile.close : Exit Function
        End if
      End if
    Else
      If Left(strLine,1)="[" Then
        If strLine = "[" & strSection & "]" Then
          blnFoundSect=True : if strKey="" then blnReadAll=True
        End if
      End if
    End if
  Loop
  If blnReadAll=False then
    If blnFoundSect Then
      INIRead = ""
    Else
      INIRead = ""
    End If
  End If
  objReadFile.close
End Function

'----------------------------- INI Write -----------------------------------
' USAGE:
'   INIWrite ( INI_FILE_PATH, SECTION, VARIABLE, VALUE)
' Example:
'    - To write/update a variable in the global section
'      INIWrite("c:\test.ini", "", "superuser", "test")
'    - To write a variable in the particular section (here: SEC1)
'      INIWrite("c:\test.ini", "SEC1", "superuser", test)

Sub INIWrite(strFile,strSection,strKey,strValue)
  Dim objReadFile,objWriteFile,strLine,blnChanging,blnFoundSect, blnFoundKey,blnSkipWrite,intKeySize
  If Instr(strKey,"=") then Exit Sub
  If Instr(strValue,VBCR) or Instr(strValue,VBLF) then Exit Sub
  If strSection <>"" and strKey="" and strValue<>"" then Exit Sub
  If Not FSO.FileExists(strFile) Then
    If strKey="" or strValue="" Then Exit sub
    Set objWriteFile = FSO.CreateTextFile(strFile,2)
    If strSection <> "" Then
      objWriteFile.WriteLine "[" & strSection & "]"
    End If
    objWriteFile.WriteLine strKey & "=" & strValue
    objWriteFile.close : Exit Sub
  End if
  Set objReadFile = FSO.OpenTextFile(strFile,1)
  Set objWriteFile = FSO.CreateTextFile(strFile & "INITMP",2)
  blnChanging = True : blnFoundSect = False : blnFoundKey = False
  blnSkipWrite = False : intKeySize = Len(strKey)+1
  If strSection = "" Then
    blnFoundSect = True
  End If
  Do While Not objReadFile.AtEndOfStream
    strLine= objReadFile.ReadLine
    If blnChanging Then
      If blnFoundSect Then
        If Left(strLine,intKeySize) = strKey & "=" then
          If strValue="" then
            strLine="="
          Else
            strLine = strKey & "=" & strValue
          End if
          blnFoundKey=True : blnChanging = False
        End if
        If Left(strLine,1)="[" Then
          If blnFoundKey=False and strValue<>"" Then
            objWriteFile.WriteLine strKey & "=" & strValue
            blnFoundKey=True : blnChanging = False
          End if
        End if
      Else
        If Left(strLine,1)="[" Then
          blnSkipWrite=False
          If strLine = "[" & strSection & "]" Then
            If strKey="" Then
              blnSkipWrite=True
            Else
              blnFoundSect=True
            End if
          End if
        End if
      End if
    End If
    If strLine<>"=" and blnSkipWrite=False then objWriteFile.WriteLine strLine
  Loop
  If blnFoundSect=False and strKey<>"" and strValue<>"" Then
    objWriteFile.WriteLine ""
    objWriteFile.WriteLine "[" & strSection & "]"
    objWriteFile.WriteLine strKey & "=" & strValue
  Else
    If blnFoundKey=False and strValue<>"" Then
      objWriteFile.WriteLine strKey & "=" & strValue
    End if
  End if
  objReadFile.close : objWriteFile.close : FSO.DeleteFile strFile,True
  FSO.MoveFile strFile & "INITMP",strFile
End Sub

' Handle Command line arguments
Dim argCount, argIndex
Set cmdArguments = WScript.Arguments
argCount = WScript.Arguments.Count
argIndex = 0

Do While argIndex<argCount
  ' Super User
  If cmdArguments(argIndex) = "-su" OR cmdArguments(argIndex) = "--superuser" Then
    argIndex = argIndex + 1
    If argIndex >= argCount Then
        Usage 1
    End If
    strSuperUser = cmdArguments(argIndex)
  ' Super Password
  ElseIf cmdArguments(argIndex) = "-sp" OR cmdArguments(argIndex) = "--superpassword" Then
    argIndex = argIndex + 1
    If argIndex >= argCount Then
        Usage 1
    End If
    strSuperPassword = cmdArguments(argIndex)
  ' Service Account (OS User)
  ElseIf cmdArguments(argIndex) = "-sa" OR cmdArguments(argIndex) = "--serviceaccount" Then
    argIndex = argIndex + 1
    If argIndex >= argCount Then
        Usage 1
    End If
    strServiceAccount = cmdArguments(argIndex)
  ElseIf cmdArguments(argIndex) = "-sn" OR cmdArguments(argIndex) = "--servicename" Then
    argIndex = argIndex + 1
    If argIndex >= argCount Then
        Usage 1
    End If
    strServiceName = cmdArguments(argIndex)

  ' Password for the Service Account
  ElseIf cmdArguments(argIndex) = "-sap" OR cmdArguments(argIndex) = "--servicepassword" Then
    argIndex = argIndex + 1
    If argIndex >= argCount Then
        Usage 1
    End If
    strServicePassword = cmdArguments(argIndex)
  ' Data Directory
  ElseIf cmdArguments(argIndex) = "-d" OR cmdArguments(argIndex) = "--datadir" Then
    argIndex = argIndex + 1
    If argIndex >= argCount Then
        Usage 1
    End If
    strDataDir = cmdArguments(argIndex)
  ' Installation Directory
  ElseIf cmdArguments(argIndex) = "-i" OR cmdArguments(argIndex) = "--installdir" Then
    argIndex = argIndex + 1
    If argIndex >= argCount Then
        Usage 1
    End If
    strInstallDir = cmdArguments(argIndex)
  ' Port
  ElseIf cmdArguments(argIndex) = "-p" OR cmdArguments(argIndex) = "--port" Then
    argIndex = argIndex + 1
    If argIndex >= argCount Then
        Usage 1
    End If
    iPort = cmdArguments(argIndex)
  ElseIf cmdArguments(argIndex) = "-pb" OR cmdArguments(argIndex) = "--pgbouncer-port"  Then
    argIndex = argIndex + 1
    If argIndex >= argCount Then
        Usage 1
    End If
    iPbPort = cmdArguments(argIndex)
  ElseIf cmdArguments(argIndex) = "-c" OR cmdArguments(argIndex) = "--components-list"  Then
    argIndex = argIndex + 1
    If argIndex >= argCount Then
        Usage 1
    End If
    Call SelectComponents(cmdArguments(argIndex))
  ' Locale
  ElseIf cmdArguments(argIndex) = "-l" OR cmdArguments(argIndex) = "--locale" Then
    argIndex = argIndex + 1
    If argIndex >= argCount Then
        Usage 1
    End If
    strLocale = cmdArguments(argIndex)
  ' Install Runtimes
  ElseIf cmdArguments(argIndex) = "-r" OR cmdArguments(argIndex) = "--install-runtimes" Then
    argIndex = argIndex + 1
    If argIndex >= argCount Then
        Usage 1
    End If
    If Trim(cmdArguments(argIndex)) <> "1" Then
      bInstallRuntimes = false
    End If
  ' Unattended Mode
  ElseIf cmdArguments(argIndex) = "-u" OR cmdArguments(argIndex) = "--unattended" Then
    bUnattended = true
  ElseIf cmdArguments(argIndex) = "--debug" Then
    bDebug = true
  ElseIf cmdArguments(argIndex) = "-h" OR cmdArguments(argIndex) = "--help" Then
    Usage 0
  Else
    strExitMsg = "'" & cmdArguments(argIndex) & "' is not a supported command-line argument."
    Usage 1
  End If
  argIndex = argIndex + 1
Loop

Function Question(ByVal que, ByVal validator, ByVal defVal, ByVal actualVal, ByVal stopInstallOnError, ByVal loopUntilRes)
  Dim bRes, strAnswer, strErrMsg
  Question = ""
  bRes = false
  If actualVal <> "" Then
    defVal = actualVal
  End If
  If NOT validator = "" Then
    ExecuteGlobal "Function RAA_DYN_QUESTION(strInput, ByRef errMsg) :" & _
                  "  RAA_DYN_QUESTION = " & validator & "(strInput, errMsg) :" & _
                  "End Function"
  End If
  Do
    If NOT bUnattended Then
      ShowMessage que & " [" & defVal & "] : "
      strAnswer = Trim(WSI.ReadLine())
    End If
    If strAnswer = "" Then
      strAnswer = defVal
    End If
    If NOT validator = "" Then
      bRes = RAA_DYN_QUESTION(strAnswer, strErrMsg)
    Else
      bRes = true
    End If
    ' bRes = CallByName(obj, validator, vbMethod, strAnswer, strErrMsg)

    If NOT bRes AND bUnattended AND stopInstallOnError Then
      LogError strErrMsg
    End If
    If NOT bRes AND loopUntilRes AND NOT stopInstallOnError Then
      ShowMessage "NOTE: " & strErrMsg
    End If
  Loop Until bRes AND loopUntilRes
  Question = strAnswer
End Function

Function AskYesNo(ByVal que, ByVal defVal)

  Dim strAnswer
  AskYesNo = false

  If NOT bUnattended Then
    ShowMessage que & " [" & defVal &"] : "
    strAnswer = Trim(WSI.ReadLine)
  End If

  If strAnswer = "" Then
    strAnswer = defVal
  End If
  If strAnswer = "Y" OR strAnswer = "Y" Then
    AskYesNo = true
  End If

End Function

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Name:    WMI_Service_Restart
' Purpose: To initiate actions required to restart a service
' Inputs:  strServiceName = The name of the service to manage
'          intWaitTimeout = The amount of time to wait for a service
'                           to change its State
' Outputs: No direct output
' Usage:   Call WMI_Service_Restart("Spooler", 300)
'          Will, on the local system, restart the Print Spooler service,
'          all its antecedents, all its dependencies, and  will
'          wait 300 seconds for each service to change its State.
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Public Sub WMI_Service_Restart(p_strServiceName, _
                               intWaitTimeout)
  On Error Resume Next

  Dim colServiceList, objService
  Dim intReturnCode
  Dim dtmStart
  Dim strServiceState
  Dim strServiceStartMode
  LogMessage "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" & VBCRLF & _
             "Starting management of the " & p_strServiceName & " service." & VBCRLF & _
             "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  'This code is based on WMI. Therefore, we cannot stop the WMI service

  'This check could be removed and the code will stop all services that
  'are dependent on the WMI service, it will be sure all services that
  'WMI depends on are started, and will then start all services that
  'depend on the WMI service.
  If UCase(Trim(p_strServiceName)) = "WINMGMT" Then
    LogMessage "Cannot restart the " & p_strServiceName & " service."
    Exit Sub
  End If
  Err.Clear
  'Determine if the specified service exists
  LogMessage "--------------------------------------------------------" & VBCRLF & _
             "Checking if the " & p_strServiceName & " service exists." & VBCRLF & _
             "--------------------------------------------------------"
  If Not WMI_Service_Exists(p_strServiceName) Then
    Exit Sub
  End If
  'Check to see if the specified service can accept a Stop or Pause command

  'This check could be removed and the code will stop all services that
  'are dependent on the WMI service, it will be sure all services that
  'WMI depends on are started, and will then start all services that
  'depend on the WMI service.
  LogMessage "-----------------------------------------------------------------------------------" & VBCRLF & _
             "Checking if the " & p_strServiceName & " service can accept a Stop control command." & VBCRLF & _
             "-----------------------------------------------------------------------------------"
  If Not WMI_Service_CanAcceptCmd(p_strServiceName, "Stop") Then
    Exit Sub
  End If

  'Get the state of the specified service
  LogMessage "----------------------------------------------------------------" & VBCRLF & _
             "Checking the state of the " & p_strServiceName & " service." & VBCRLF & _
             "----------------------------------------------------------------"
  strServiceState = WMI_Service_State_Get(p_strServiceName)

  'Wait for the service to stabilize if the service state is changing
  If Instr(1, "Start Pending, Continue Pending, Stop Pending, Pause Pending", strServiceState, vbTextCompare) Then
    Call WMI_Service_State_WaitOnChange(p_strServiceName, "Paused, Running, Stopped", intWaitTimeout)
    strServiceState = WMI_Service_State_Get(p_strServiceName)
  End If

  'The service is in an 'Unknown' state
  If strServiceState = "Unknown" Then
    LogWarn " The " & p_strServiceName & " service is in an Uknown state."
    Exit Sub
  End If

  '*****************************************************************************
  'Is the service in one of the running states?
  'If yes, stop the antecedents, the user specified service, and the dependents
  If Instr(1, "Running, Paused", strServiceState, vbTextCompare) Then
    'Instantiate a reference to a collection that contains services that are
    'dependent on the user specified service (Dependent services).
    Err.Clear
    Set colServiceList = Services.ExecQuery("Associators of " & _
                          "{Win32_Service.Name='" & p_strServiceName & "'} " & _
                          "Where AssocClass=Win32_DependentService " & _
                          "Role=Antecedent")
    'Error check
    If (Err.Number <> 0) And Not IsObject(colServiceList) Then
      LogWarn " Error querying WMI." & VBCRLF & _
              "         Number (dec) : "   & Err.Number & VBCRLF & _
              "  Number (hex) : &H" & Hex(Err.Number) & VBCRLF & _
              "  Description  : "   & Err.Description & VBCRLF & _
              "  Source       : "   & Err.Source
      'Lookup WMI errors
      Call WMI_Services_Error_Lookup(Err.Number)
    Else
      'There are services that depend on the user specified service if the count is greater than 0
      If colServiceList.Count > 0 Then
        LogMessage "-----------------------------------------------------------------------------" & VBCRLF & _
                   "Stopping services that depend on the " & p_strServiceName & " service." & VBCRLF & _
                   "-----------------------------------------------------------------------------"
        'Loop through the collection and send a Stop command to each service
        For Each objService in colServiceList
          LogMessage objService.Name & " service."
          'Is the service already stopped?
          If objService.State = "Stopped" Then
            LogMessage "  The " & objService.Name & " service is already Stopped."
          Else
            'Call the procedure to send the command
            strServiceState = WMI_Service_State_Set(objService.Name, "Stop", intWaitTimeout)
          End If
        Next
      End If
    End If
    LogMessage "-----------------------------------------------------------------------------" & VBCRLF & _
               "Stopping the " & p_strServiceName & " service." & VBCRLF & _
               "-----------------------------------------------------------------------------"
    'Call the procedure to send the command to the user specified service
    strServiceState = WMI_Service_State_Set(p_strServiceName, "Stop", intWaitTimeout)
  End If

  '*****************************************************************************
  'Is the service in a stopped states?
  'If yes, start the antecedents, the user specified service, and the dependents
  If strServiceState = "Stopped" Then
    'Instantiate a reference to a collection that contains services that the
    'user specified service depends on (Antecedent services).
    Err.Clear
    Set colServiceList = Services.ExecQuery("Associators of " & _
                          "{Win32_Service.Name='" & p_strServiceName & "'} " & _
                          "Where AssocClass=Win32_DependentService " & _
                          "Role=Dependent")
    'Error check
    If (Err.Number <> 0) And Not IsObject(colServiceList) Then
      LogWarn " Error querying WMI." & VBCRLF & _
              "         Number (dec) : "   & Err.Number & VBCRLF & _
              "         Number (hex) : &H" & Hex(Err.Number) & VBCRLF & _
              "         Description  : "   & Err.Description & VBCRLF & _
              "         Source       : "   & Err.Source

      'Lookup WMI errors
      Call WMI_Services_Error_Lookup(Err.Number)
    Else
      'The user specified service does depend on other services if the count is greater than 0
      If colServiceList.Count > 0 Then
        LogMessage "-----------------------------------------------------------------------------" & VBCRLF & _
                   "Starting services that the " & p_strServiceName & " service depends on." & VBCRLF & _
                   "-----------------------------------------------------------------------------"
        For Each objService in colServiceList
          LogMessage objService.Name & " service."
          'Get the service StartMode
          strServiceStartMode = objService.StartMode
          'Skip the service if the StartMode is Disabled or Manual
          If Instr(1, "Disabled, Manual", strServiceStartMode, vbTextCompare) Then
            LogMessage "  !Skipping a Start since the service is set to " & strServiceStartMode & "."
          Else
            'Call the procedure to send the command to the antecedent service
            strServiceState = WMI_Service_State_Set(objService.Name, "Start", intWaitTimeout)
          End If
        Next
      End If
    End If
    LogMessage "-----------------------------------------------------------------------------" & VBCRLF & _
               "Starting the " & p_strServiceName & " service." & VBCRLF & _
               "-----------------------------------------------------------------------------"
    'Call the procedure to send the command to the user specified service
    strServiceState = WMI_Service_State_Set(p_strServiceName, "Start", intWaitTimeout)

    'Instantiate a reference to a collection that contains services that are
    'dependent on the user specified service (Dependent services).
    Err.Clear
    Set colServiceList = Services.ExecQuery("Associators of " & _
                          "{Win32_Service.Name='" & p_strServiceName & "'} " & _
                          "Where AssocClass=Win32_DependentService " & _
                          "Role=Antecedent")

    'Error check
    If (Err.Number <> 0) And Not IsObject(colServiceList) Then
      LogWarn  "Error querying WMI." & VBCRLF & _
               "        Number (dec) : "   & Err.Number & VBCRLF & _
               "        Number (hex) : &H" & Hex(Err.Number) & VBCRLF & _
               "        Description  : "   & Err.Description & VBCRLF & _
               "        Source       : "   & Err.Source
      'Lookup WMI errors
      Call WMI_Services_Error_Lookup(Err.Number)
    Else
      'There are services that depend on the user specified service if the count is greater than 0
      If colServiceList.Count > 0 Then
        LogMessage "-----------------------------------------------------------------------------" & VBCRLF & _
                   "Starting services that depend on the " & p_strServiceName & " service." & VBCRLF & _
                   "-----------------------------------------------------------------------------"
        For Each objService in colServiceList
          LogMessage objService.Name & " service."
          'Get the service StartMode
          strServiceStartMode = objService.StartMode
          'Skip the service if the StartMode is Disabled or Manual
          If Instr(1, "Disabled, Manual", strServiceStartMode, vbTextCompare) Then
            LogMessage "  !Skipping a Start for " & objService.Name & " since it is set to " & strServiceStartMode & "."
          Else
            'Call the procedure to send the command to the dependent service
            strServiceState = WMI_Service_State_Set(objService.Name, "Start", intWaitTimeout)
          End If
        Next
      End If
    End If
  End If
  ShowMessage "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" & VBCRLF & _
              "Done managing the " & p_strServiceName & " service." & VBCRLF & _
              "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
End Sub

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Name:    WMI_Service_State_Set
' Purpose: To send a specified command to a service
' Inputs:  p_strServiceName = The name of the service to control
'          p_strServiceCmd  = The command to send to the service
'          p_intWaitTimeout = The amount of time to wait for the service to change
'                             state, in seconds.
'                             If negative, the wait will be indefinite.
'                             If zero, there will be no wait.
' Outputs: The state of the service after sending the control command and
'          optionally waiting for the service state to change.
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Private Function WMI_Service_State_Set(p_strServiceName, _
                                       p_strServiceCmd, _
                                       p_intWaitTimeout)
  On Error Resume Next
  Dim objService
  Dim intReturn, intReturnCode
  Dim strServiceState_Desired
  Dim blnExit

  'Default value to determine if certain procedural things should be skipped later
  blnExit = False
  LogMessage "Connecting to the " & p_strServiceName & " service."

  'Instantiate a reference to the service
  Err.Clear
  Set objService = Services.Get("Win32_Service='" & p_strServiceName & "'")

  'Error check
  If (Err.Number <> 0) And Not IsObject(objService) Then
    LogWarn "Error connecting to the " & p_strServiceName & " service." & VBCRLF & _
            "        Number (dec) : "   & Err.Number & VBCRLF & _
            "        Number (hex) : &H" & Hex(Err.Number) & VBCRLF & _
            "        Description  : "   & Err.Description & VBCRLF & _
            "        Source       : "   & Err.Source
    'Lookup WMI errors
    Call WMI_Services_Error_Lookup(Err.Number)
    Exit Function
  End If

  'Default service state to wait for if a wait is specified
  strServiceState_Desired = "Running"

  'What control command was specified?
  Select Case p_strServiceCmd
    Case "Stop"
      'This code depends on WMI. Therefore, we cannot control the WMI service
      If UCase(p_strServiceName) = "WINMGMT" Then
        LogMessage "Cannot stop the " & p_strServiceName & " service."
        blnExit = True
      Else
        'Can the service accept a stop?
        If objService.AcceptStop Then
          LogMessage "  Sending service command: "  & p_strServiceCmd
          'Send the specified service control
          intReturnCode = objService.StopService()
          'The service state to wait for if a wait is specified
          strServiceState_Desired = "Stopped"
        Else
          LogMessage "  The " & p_strServiceName & " cannot accept a " & p_strServiceCmd & " command."
          'Certain procedural tasks need to be skipped later
          blnExit = True
        End If
      End If
    Case "Start"
      LogMessage "  Sending service command: "  & p_strServiceCmd
      'Send the specified service control
      intReturnCode = objService.StartService()
    Case "Resume"
      LogMessage "  Sending service command: "  & p_strServiceCmd
      'Send the specified service control
      intReturnCode = objService.ResumeService()
    Case "Pause"
      If UCase(p_strServiceName) = "WINMGMT" Then
        logMessage "  Cannot pause the " & p_strServiceName & " service."
        'Certain procedural tasks need to be skipped later
        blnExit = True
      Else
        'Can the service accept a pause?
        If objService.AcceptPause Then
          LogMessage "  Sending service command: "  & p_strServiceCmd
          'Send the specified service control
          intReturnCode = objService.PauseService()
          'The service state to wait for if a wait is specified
          strServiceState_Desired = "Paused"
        Else
          LogMessage "The " & p_strServiceName & " cannot accept a " & p_strServiceCmd & " command."
          'Certain procedural tasks need to be skipped later
          blnExit = True
        End If
      End If
  End Select

  'Error check
  If Err.Number <> 0 Then
    LogWarn "Error sending the service command to the " & p_strServiceName & " service." & VBCRLF & _
            "         Number (dec) : "   & Err.Number & VBCRLF & _
            "         Number (hex) : &H" & Hex(Err.Number) & VBCRLF & _
            "         Description  : "   & Err.Description & VBCRLF & _
            "         Source       : "   & Err.Source
    'Certain procedural tasks need to be skipped later
    blnExit = True
  End If

  If Not blnExit Then
    'Lookup WMI errors
    Call WMI_Services_Error_Lookup(intReturnCode)
    'Was the service control successful?
    If intReturnCode = 0 Then
      WMI_Service_State_Set = WMI_Service_State_WaitOnChange(p_strServiceName, strServiceState_Desired, p_intWaitTimeout)
    End If
  End If
  If IsObject(objService) Then Set objService = Nothing
End Function

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Name:    WMI_Service_Exists
' Purpose: To determine if a service exists on the system
' Inputs:  p_strServiceName = The name of the service to check
' Outputs: True  = The service does exist
'          False = The service does not exist
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Private Function WMI_Service_Exists(p_strServiceName)
  On Error Resume Next
  Dim colServiceList
  LogMessage "  Query WMI for the " & p_strServiceName & " service."
  'Query WMI
  Err.Clear
  Set colServiceList = Services.ExecQuery("Select * From Win32_Service Where Name='" & _
                                             p_strServiceName & "'")
  'Error check
  If (Err.Number = 0) And IsObject(colServiceList) Then
    If colServiceList.Count > 0 Then
      LogMessage "    The " & p_strServiceName & " service exists."

      'Set the function return value
      WMI_Service_Exists = True
    Else
      'Set the function return value
      WMI_Service_Exists = False
      LogMessage "    The " & p_strServiceName & " service does not exist."
    End If
  Else
    'Output error details
    LogWarn "Error querying WMI for the " & p_strServiceName & " service." & VBCRLF & _
            "         Number (dec) : "   & Err.Number & VBCRLF & _
            "         Number (hex) : &H" & Hex(Err.Number) & VBCRLF & _
            "         Description  : "   & Err.Description & VBCRLF & _
            "         Source       : "   & Err.Source
    'Lookup WMI errors
    Call WMI_Services_Error_Lookup(Err.Number)
  End If
  Set colServiceList = Nothing
End Function


''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Name:    WMI_Service_State_Get
' Purpose: To get the state of a service
' Inputs:  p_strServiceName = The name of the service to check
' Outputs: The current state of the service
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Private Function WMI_Service_State_Get(p_strServiceName)
  On Error Resume Next
  Dim objService
  Dim l_strServiceState
  Dim l_iReturn
  LogMessage "  Connecting to the " & p_strServiceName & " service."
  'Instantiate a reference to the service
  Err.Clear
  Set objService = Services.Get("Win32_Service='" & p_strServiceName & "'")
  'Error check
  If (Err.Number = 0) And IsObject(objService) Then
    'I'm unsure if this is still needed
    'Tell the service to update its state in the service manager
    l_iReturn = objService.InterrogateService()
    'Get the current service state
    l_strServiceState = objService.State
    LogMessage "    The service state is: " & l_strServiceState
    'Set the function return value
    WMI_Service_State_Get = l_strServiceState
  Else
    'Output error details
    LogWarn "Error connecting to the " & p_strServiceName & " service." & VBCRLF & _
            "         Number (dec) : "   & Err.Number & VBCRLF & _
            "         Number (hex) : &H" & Hex(Err.Number) & VBCRLF & _
            "         Description  : "   & Err.Description & VBCRLF & _
            "         Source       : "   & Err.Source
    'Lookup WMI errors
    Call WMI_Services_Error_Lookup(Err.Number)
  End If
  If IsObject(objService) Then Set objService = Nothing
End Function


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Name:    WMI_Service_CanAcceptCmd
' Purpose: Check to see if a service can accept a Stop or Pause control command
' Inputs:  p_strServiceName = The name of the service to check
'          p_strCommand     = The control command to check for
' Outputs: True  - If the service can accept the control command
'          False - If the service cannot accept the control command
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Private Function WMI_Service_CanAcceptCmd(p_strServiceName, _
                                          p_strCommand)
  On Error Resume Next
  Dim objService
  'Set default value
  WMI_Service_CanAcceptCmd = False
  LogMessage "  Connecting to the " & p_strServiceName & " service."

  Err.Clear
  'Instantiate a reference to the service
  Set objService = Services.Get("Win32_Service='" & p_strServiceName & "'")
  'Error check
  If (Err.Number = 0) And IsObject(objService) Then
    'Select which check was requested and determine if the service can
    'accept the control command
    Select Case p_strCommand
      Case "Stop"
        'Do the check and set the function return value
        WMI_Service_CanAcceptCmd = objService.AcceptStop
      Case "Pause"
        'Do the check and set the function return value
        WMI_Service_CanAcceptCmd = objService.AcceptPause
    End Select
    'Output results
    If WMI_Service_CanAcceptCmd Then
      LogMessage "    The " & p_strServiceName & " can accept a " & p_strCommand & " command."
    Else
      LogMessage "    The " & p_strServiceName & " cannot accept a " & p_strCommand & " command."
    End If
  Else
    'Output error details
    LogWarn " Error connecting to the " & p_strServiceName & " service." & VBCRLF & _
            "         Number (dec) : "   & Err.Number & VBCRLF & _
            "         Number (hex) : &H" & Hex(Err.Number) & VBCRLF & _
            "         Description  : "   & Err.Description & VBCRLF & _
            "         Source       : "   & Err.Source
    'Lookup WMI errors
    Call WMI_Services_Error_Lookup(-1)
  End If

  If IsObject(objService) Then Set objService = Nothing

End Function


''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Name:    WMI_Service_State_WaitOnChange
' Purpose: To wait for a service to enter a specified state
' Inputs:  p_strServiceName          = The name of the service to wait for
'          p_strServiceState_Desired = The state to wait for
'          p_intWaitTimeout          = The amount of time to wait for the service to change
'                                    state, in seconds.
'                                    If negative, the wait will be indefinite.
'                                    If zero, there will be no wait.
' Outputs: The current state of the service
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Private Function WMI_Service_State_WaitOnChange(p_strServiceName, _
                                                p_strServiceState_Desired, _
                                                p_intWaitTimeout)
  On Error Resume Next
  Dim l_strServiceState
  Dim l_strWait
  Dim l_blnWait
  Dim l_dtmStart
  'The current Date and Time
  l_dtmStart = Now()
  'Set some text
  If p_intWaitTimeout > 0 Then
    l_strWait = "  *Wait " & p_intWaitTimeout & " seconds"
    l_blnWait = True
  ElseIf p_intWaitTimeout < 0 Then
    l_strWait = "  *Wait indefinitely"
    l_blnWait = True
  Else
    l_strWait = "  *Do not wait"
    l_blnWait = False
  End If
  LogMessage l_strWait & " for the " & p_strServiceName & " service to enter a " & p_strServiceState_Desired & " state."
  'Get the state of the service
  l_strServiceState = WMI_Service_State_Get(p_strServiceName)

  If l_blnWait Then
    'Loop while the service state is not equal to the desired service state
    Do While Instr(1, p_strServiceState_Desired, l_strServiceState, vbTextCompare) = 0
      'Check if the wait period has exceeded the timeout
      If p_intWaitTimeout > 0 Then
        'DateDiff comparison
        If DateDiff("s", l_dtmStart, Now()) > (p_intWaitTimeout / 2) Then
          LogMessage "  Timed out waiting for the " & p_strServiceName & " service to enter a " & p_strServiceState_Desired & " state."
          Exit Do
        End If
      End If
      'Pause for 1/2 second
      Wscript.Sleep(500)
      'Get the state of the service
      strServiceState = WMI_Service_State_Get(p_strServiceName)
    Loop
  End If
  'Return the current service state
  WMI_Service_State_WaitOnChange = l_strServiceState

End Function

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Name:    WMI_Services_Error_Lookup
' Purpose: Lookup WMI error codes
' Inputs:  p_intError = The Err.Number or WMI service control result code
' Outputs: No direct output
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Private Sub WMI_Services_Error_Lookup(p_intError)
  On Error Resume Next
  Dim l_strErrMsg
  Select Case p_intError
    Case 0
      l_strErrMsg = "The request was accepted."
    Case 1
      l_strErrMsg = "The request is not supported."
    Case 2
      l_strErrMsg = "The user did not have the necessary access."
    Case 3
      l_strErrMsg = "The service cannot be stopped because other services that are running are dependent on it."
    Case 4
      l_strErrMsg = "The requested control code is not valid, or it is unacceptable to the service."
    Case 5
      l_strErrMsg = "The requested control code cannot be sent to the service because the state of the service (Win32_BaseService State property) is equal to 0, 1, or 2."
    Case 6
      l_strErrMsg = "The service has not been started."
    Case 7
      l_strErrMsg = "The service did not respond to the start request in a timely fashion."
    Case 8
      l_strErrMsg = "Interactive Process."
    Case 9
      l_strErrMsg = "The directory path to the service executable file was not found."
    Case 10
      l_strErrMsg = "The service is already running."
    Case 11
      l_strErrMsg = "The database to add a new service is locked."
    Case 12
      l_strErrMsg = "A dependency for which this service relies on has been removed from the system."
    Case 13
      l_strErrMsg = "The service failed to find the service required from a dependent service."
    Case 14
      l_strErrMsg = "The service has been disabled from the system."
    Case 15
      l_strErrMsg = "The service does not have the correct authentication to run on the system."
    Case 16
      l_strErrMsg = "This service is being removed from the system."
    Case 17
      l_strErrMsg = "There is no execution thread for the service."
    Case 18
      l_strErrMsg = "There are circular dependencies when starting the service."
    Case 19
      l_strErrMsg = "There is a service running under the same name."
    Case 20
      l_strErrMsg = "There are invalid characters in the name of the service."
    Case 21
      l_strErrMsg = "Invalid parameters have been passed to the service."
    Case 22
      l_strErrMsg = "The account which this service is to run under is either invalid or lacks the permissions to run the service."
    Case 23
      l_strErrMsg = "The service exists in the database of services available from the system."
    Case 24
      l_strErrMsg = "The service is currently paused in the system."
    Case Else
      l_strErrMsg = "Unknown"
  End Select

  If l_strErrMsg = "Unknown" Then
    'Call procedure to attempt to determine the error using SWbemLastError
    Call WMI_Error_Display()
  Else
    LogMessage "  WMI error lookup:" & vbCrLf & _
               "    Code:  " & p_intError & vbCrLf & _
               "    Description: " & l_strErrMsg
  End If
  Err.Clear
End Sub

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Name:    WMI_Error_Display
' Purpose: To attempt to use SWbemLastError to find the last WMI error that occurred
' Inputs:  None
' Outputs: No direct output
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Private Sub WMI_Error_Display()
  On Error Resume Next
  Dim objWMI_Error

  'Instantiate reference to the SWbemLastError object.
  Set objWMI_Error = CreateObject("WbemScripting.SWbemLastError")

  'Error check
  If (Err.Number = 0) And IsObject(objWMI_Error) Then
    LogMessage " Operation    : " &  objWMI_Error.Operation & VBCRLF & _
               " ParameterInfo: " &  objWMI_Error.ParameterInfo & VBCRLF & _
               " ProviderName : " &  objWMI_Error.ProviderName
    Set objWMI_Error = Nothing
  Else
    LogMessage "      !Could not retrieve 'SWbemLastError'."
  End If
  Err.Clear
End Sub

' Make sure the script is running using CScript.exe (unless unattended mode)
If InStr(Ucase(WScript.FullName), "WSCRIPT.EXE") AND bUnattended = false Then
  LogError("Please use CScript to run this script")
ElseIf InStr(Ucase(WScript.FullName), "WSCRIPT.EXE") Then
  bWScript = true
End If

' Declaration of classes
Class DevServer
  Private m_strInstallDir
  Private m_strDataDir
  Private m_strLocale
  Private m_strSuperUser
  Private m_strSuperPassword
  Private m_strServiceAccount
  Private m_strServiceDomain
  Private m_strServicePassword
  Private m_strServiceName
  Private m_iPort
  Private m_strVersion
  Private m_iMajoVersion
  Private m_iMinorVersion
  Private m_arrayLocales()

  Private Sub Class_Initialize
    ' Initializing class
  End Sub

  Public Property Get InstallDir
    InstallDir = m_strInstallDir
  End Property

  Public Property Let InstallDir(strInstallDir)
    m_strInstallDir = strInstallDir
  End Property

  Public Property Get DataDir
    DataDir = m_strDataDir
  End Property

  Public Property Let DataDir(strDataDir)
    m_strDataDir = strDataDir
  End Property

  Public Property Get Locale
    Locale = m_strLocale
  End Property

  Public Property Let Locale(strLocale)
    m_strLocale = strLocale
  End Property

  Public Property Get SuperUser
    SuperUser = m_strSuperUser
  End Property

  Public Property Let SuperUser(strSuperUser)
    m_strSuperUser = strSuperUser
  End Property

  Public Property Get SuperPassword
    SuperPassword = m_strSuperPassword
  End Property

  Public Property Let SuperPassword(strSuperPassword)
    m_strSuperPassword = strSuperPassword
  End Property

  Public Property Get ServiceAccount
    ServiceAccount = m_strServiceDomain & "\" & m_strServiceAccount
  End Property

  Public Property Get ServiceAccountWODomain
    ServiceAccountWODomain = m_strServiceAccount
  End Property

  Public Property Get ServiceDomain
    ServiceDomain = m_strServiceDomain
  End Property

  Public Property Let ServiceAccount(p_strServiceAccount)
    Dim l_strServiceAccount, l_strServiceDomain

    l_strServiceAccount = p_strServiceAccount
    l_strServiceDomain = "."

    iEscapePos = InStr(p_strServiceAccount, "\")
    If NOT iEscapePos = 0 Then
      l_strServiceAccount = Right(p_strServiceAccount,Len(p_strServiceAccount)-iEscapePos)
      l_strServiceDomain  = Left(p_strServiceAccount, iEscapePos - 1)
    End If
    iEscapePos = InStr(l_strServiceAccount, "\")
    If NOT iEscapePos = 0 Then
      LogError "Not valid service account (" & p_strServiceAccount & ")."
    End If

    If Trim(l_strServiceDomain) = "." Then
      Set l_colSystems = WMIService.ExecQuery("Select * From Win32_ComputerSystem")
      For Each l_objSystem in l_colSystems
        l_strServiceDomain = l_objSystem.Name
      Next
    End If
    m_strServiceAccount = Trim(l_strServiceAccount)
    m_strServiceDomain  = Trim(l_strServiceDomain)
  End Property

  Public Property Get ServicePassword
    ServicePassword = m_strServicePassword
  End Property

  Public Property Let ServicePassword(strServicePassword)
    m_strServicePassword = strServicePassword
  End Property

  Public Property Get ServiceName
    ServiceName = m_strServiceName
  End Property

  Public Property Let ServiceName(strServiceName)
    m_strServiceName = strServiceName
  End Property

  Public Property Get Port
    Port = m_iPort
  End Property

  Public Property Let Port(iPort)
    m_iPort = iPort
  End Property

  Public Property Get Version
    Version = m_iMajoVersion & "." & m_iMinorVersion
  End Property

  Public Property Get MajorVersion
    MajorVersion = m_iMajoVersion
  End Property

  Public Property Get MinorVersion
    MinorVersion = m_iMinorVersion
  End Property

  Public Property Get FullVerion
    FullVerion = m_strVersion
  End Property
  Public Function validateServerPath(p_strInstallDir, ByRef p_strErrMsg)
    validateServerPath = false

    If IsFileExists(p_strInstallDir, "bin\psql.exe", p_strErrMsg) AND _
       IsFileExists(p_strInstallDir, "bin\postgres.exe", p_strErrMsg) AND _
       IsFileExists(p_strInstallDir, "bin\pg_config.exe", p_strErrMsg) AND _
       IsFileExists(p_strInstallDir, "bin\pg_ctl.exe", p_strErrMsg) AND _
       IsFileExists(p_strInstallDir, "bin\pg_controldata.exe", p_strErrMsg) AND _
       IsFileExists(p_strInstallDir, "bin\initdb.exe", p_strErrMsg) AND _
       IsFileExists(p_strInstallDir, "installer\server\createuser.exe", p_strErrMsg) AND _
       IsFileExists(p_strInstallDir, "installer\server\validateuser.exe", p_strErrMsg) AND _
       IsFileExists(p_strInstallDir, "installer\server\getlocales.exe", p_strErrMsg) AND _
       IsFileExists(p_strInstallDir, "installer\server\startupcfg.vbs", p_strErrMsg) AND _
       IsFileExists(p_strInstallDir, "installer\server\createshortcuts.vbs", p_strErrMsg) AND _
       IsFileExists(p_strInstallDir, "installer\server\startserver.vbs", p_strErrMsg) AND _
       IsFileExists(p_strInstallDir, "installer\server\loadmodules.vbs", p_strErrMsg) AND _
       IsFileExists(p_strInstallDir, "installer\server\initcluster.vbs", p_strErrMsg) AND _
       IsFileExists(p_strInstallDir, "installer\vcredist_x86.exe", p_strErrMsg) AND _
       IsFileExists(p_strInstallDir, "scripts\serverctl.vbs", p_strErrMsg) Then
      validateServerPath = true
      m_strInstallDir = p_strInstallDir
      ' Find out PostgreSQL Version
      SetVariableFromScriptOutput p_strInstallDir & "\bin\pg_config.exe", "--version", l_strVersion, l_strErrMsg, l_iStatus

      If l_iStatus <> 0 Then
        LogError "PostgreSQL version could not be determined. Please check the log files for details."
      End If

      l_strVersion = Trim(l_strVersion)
      l_iPos = InStr(l_strVersion, " ")
      m_strVersion = Trim(Right(l_strVersion, Len(l_strVersion)-l_iPos))
      l_arrayVersion = split(m_strVersion, ".")

      l_iUBound = -1
      If IsArray(l_arrayVersion) Then
        l_iUBound = UBound(l_arrayVersion)
      End If
      If l_iUBound >= 0 Then
        m_iMajoVersion = l_arrayVersion(0)
        If l_iUBound >= 1 Then
          m_iMinorVersion = l_arrayVersion(1)
        End If
      End If

      If strServiceName = "" Then
        strServiceName = "pgsql-" & Version
      End If
      If CONSTPGAGENTSERVICE = "" Then
        CONSTPGAGENTSERVICE = "pgagent_" & CONSTADMINDATABASE & "_" & m_iMajoVersion & "_" & m_iMinorVersion
      End If

      ' Fetch locale array
      SetVariableFromScriptOutput p_strInstallDir & "\installer\server\getlocales.exe", "", lStrLocales, l_strErrMsg, l_iStatus
      lArrayLocale = split(lStrLocales, vbCRLF)

      iLBound = LBound(lArrayLocale)
      iUBound = UBound(lArrayLocale)
      ReDim m_arrayLocales(iUBound)
      For index = iLBound To iUBound Step 1
        lPos = 0
        lStrLocale = LCase(Trim(lArrayLocale(index)))
        lPos = InStr(lStrLocale, "=")
        If NOT lPos = 0 Then
          lStrLocale=Right(lStrLocale,Len(lStrLocale)-lPos)
          m_arrayLocales(index) = lStrLocale
        End If
      Next
    End If
  End Function

  Public Function validateDataDir(pStrDataDir, ByRef pStrErrMsg)
    validateDataDir = false

    If NOT FSO.FolderExists(pStrDataDir) Then
      If IsFileExists(pStrDataDir, "", lStrErrMsg) Then
        pStrErrMsg = "'" & pStrDataDir & "' is a file, could not be a valid data directory."
        Exit Function
      End If
      m_strDataDir = pStrDataDir
      validateDataDir = true

      ' Fetch owner of pg_ctl.exe
      If m_strServiceAccount = NULL OR m_strServiceAccount = "" Then
         Set objBinDir = WshApp.NameSpace (m_strInstallDir & "\bin")
         l_iOwner = 8
         For l_iIndex = 0 to 13
           If UCase(objBinDir.GetDetailsOf(objBinDir.Items, l_iIndex)) = "OWNER" Then
             l_iOwner = l_iIndex
           End If
         Next
         For Each l_objFile in objBinDir.Items
           l_strFile = "" & LCase(objBinDir.GetDetailsOf (l_objFile, 0))
           If l_strFile = "pg_ctl" Then
             ServiceAccount = objBinDir.GetDetailsOf (l_objFile, l_iOwner)
           End If
         Next
      End If
      Exit Function
    End If

    set objDataFolder = FSO.GetFolder(pStrDataDir)
    If NOT IsFileExists(pStrDataDir, "postgresql.conf", lStrErrMsg) OR _
       NOT IsFileExists(pStrDataDir, "PG_VERSION", lStrErrMsg) OR _
       NOT IsFileExists(pStrDataDir, "global\pg_database", lStrErrMsg) OR _
       NOT IsFileExists(pStrDataDir, "global\pg_auth", lStrErrMsg) Then
       If NOT objDataFolder.Files.Count = 0 Then
         pStrErrMsg = vbCRLF & "Not a Valid Data Directory." & lStrErrMsg
         Exit Function
       End If
    End If

    m_strDataDir = pStrDataDir
    validateDataDir = true

    If NOT objDataFolder.Files.Count = 0 Then

      ' Over-write the value provided by user by the actual data-dir\postgresql.conf file owner
      Set objDataDir = WshApp.NameSpace (m_strDataDir)
      l_iOwner = 8
      For l_iIndex = 0 to 13
        If UCase(objDataDir.GetDetailsOf(objDataDir.Items, l_iIndex)) = "OWNER" Then
          l_iOwner = l_iIndex
        End If
      Next
      For Each l_objFile in objDataDir.Items
        l_strFile = "" & LCase(objDataDir.GetDetailsOf (l_objFile, 0))
        If l_strFile = "postgresql.conf" Then
          ServiceAccount = objDataDir.GetDetailsOf (l_objFile, l_iOwner)
        End If
      Next
    Else
      ' Fetch owner of pg_ctl.exe
      If m_strServiceAccount = NULL OR m_strServiceAccount = "" Then
         Set objBinDir = WshApp.NameSpace (m_strInstallDir & "\bin")
         l_iOwner = 8
         For l_iIndex = 0 to 13
           If UCase(objBinDir.GetDetailsOf(objBinDir.Items, l_iIndex)) = "OWNER" Then
             l_iOwner = l_iIndex
           End If
         Next
         For Each l_objFile in objBinDir.Items
           l_strFile = "" & LCase(objBinDir.GetDetailsOf (l_objFile, 0))
           If l_strFile = "pg_ctl" Then
             ServiceAccount = objBinDir.GetDetailsOf (l_objFile, l_iOwner)
           End If
         Next
      End If
    End If
  End Function

  Public Function validatePort(p_iPort, ByRef p_strErrMsg)
    validatePort = false
    If NOT IsNumeric(p_iPort) OR NOT InStr(p_iPort, ".") = 0 Then
      pStrErrMsg = "'" & pPort & "' is not a valid port."
      Exit Function
    End If
    If p_iPort < 1000 OR p_iPort > 65535 Then
      p_strErrMsg = "'" & p_iPort & "' is not within valid range (Port < 1000 & > 65535)."
      Exit Function
    End If

    m_iPort = p_iPort
    validatePort = true
  End Function

  Public Function validateLocale(p_strLocale, ByRef p_strErrMsg)
    validateLocale = false
    If UCase(p_strLocale) = "DEFAULT" Then
      m_strLocale = "DEFAULT" : validateLocale = true : Exit Function
    End If
    If p_strLocale = NULL OR Trim(p_strLocale) = "" Then
      p_strErrMsg = "Not a valid locale." : Exit Function
    End If
    filteredArray = Filter(m_arrayLocales, LCase(p_strLocale))
    If NOT IsArray(filteredArray) Then
      p_strErrMsg = "Not a valid locale." : Exit Function
    End If

    If UBound(filteredArray) = -1 Then
      p_strErrMsg = "Not a valid locale." : Exit Function
    End If

    If NOT filteredArray(0) = LCase(p_strLocale) Then
      p_strErrMsg = "Not a valid locale." : Exit Function
    End If

    m_strLocale = p_strLocale
    validateLocale = true
  End Function

  Public Function validateServicePassword(p_strServicePassword, ByRef p_lpStrErrMsg)
    Dim l_iRes, l_strScriptOutput, l_strScriptError
    validateServicePassword = false

    Call RunProgram(m_strInstallDir & "\installer\server\createuser.exe",  _
                    array(m_strServiceDomain, m_strServiceAccount, p_strServicePassword), _
                    l_strScriptOutput, l_strScriptError, l_iRes)

    Select Case l_iRes
      Case 0
      Case 2203
        LogError "The password specified does not meet the local or domain policy. Check the minimum password length, password complexity and password history requirements."
      Case 2245
        LogError "The password specified does not meet the local or domain policy. Check the minimum password length, password complexity and password history requirements."
      Case 2224
      Case else
        LogError l_strScriptError
   End Select

   Call RunProgram(m_strInstallDir & "\installer\server\validateuser.exe",  _
                    array(m_strServiceDomain, m_strServiceAccount, p_strServicePassword), _
                    l_strScriptOutput, l_strScriptError, l_iRes)
   Select Case l_iRes
     Case 0
       ' Do Nothing
       ' Successfully validated
     Case 1
       p_lpStrErrMsg = "The password specified was incorrect. Please enter the correct password for the '" & ServiceAccount & "' windows user account."
       Exit Function
     Case Else
       LogError l_strScriptError
   End Select
   m_strServicePassword = p_strServicePassword
   validateServicePassword = true
  End Function
End Class

Class PsqlODBC
  Private m_strPath

  Public Property Get Path
    Path = m_strPath
  End Property

  Public Property Let Path(p_strPath)
    m_strPath = p_strPath
  End Property
End Class

Class PGBouncer
  Private m_iPort
  Private m_strPath

  Public Property Get Path
    Path = m_strPath
  End Property

  Public Property Let Path(p_strPath)
    m_strPath = p_strPath
  End Property

  Public Property Get Port
    Port = m_iPort
  End Property

  Public Property Let Port(p_iPort)
    m_iPort = p_iPort
  End Property

  Public Function validatePort(p_iPort, p_strErrMsg)
    validatePort = false
    If NOT IsNumeric(p_iPort) OR NOT InStr(p_iPort, ".") = 0 Then
      p_strErrMsg = "'" & p_iPort & "' is not a valid port."
      Exit Function
    End If
    If p_iPort < 1000 OR p_iPort > 65535 Then
      p_strErrMsg = "'" & p_iPort & "' is not within valid range (Port < 1000 & > 65535)."
      Exit Function
    End If
    If p_iPort = objDevServer.Port Then
      p_strErrMsg = "The given port for the pgbouncer is same as the server port."
      Exit Function
    End If

    m_iPort = p_iPort
    validatePort = true
  End Function
End Class

Function RunPsql(p_bRunCmd, p_strCmdOpts, p_bIsSql, p_strSql, p_strDatabase)
  If p_strDatabase = "" Then
    p_strDatabase = "template1"
  End If
  l_strTmpFile     = Replace(FSO.GetTempName, ".tmp", ".bat")
  l_strTmpFilePath = TempFolder.Path & "\" & l_strTmpFile
  Set objTmpBatch  = TempFolder.CreateTextFile(l_strTmpFile, True)
  objTmpBatch.WriteLine "@ECHO OFF"
  objTmpBatch.WriteLine "SET PATH=%PATH%;" & objDevServer.InstallDir & "\bin"
  objTmpBatch.WriteLine "SET PGDATA=" & objDevServer.DataDir
  objTmpBatch.WriteLine "SET PGUSER=" & objDevServer.SuperUser
  objTmpBatch.WriteLine "SET PGPORT=" & objDevServer.Port
  objTmpBatch.WriteLine "SET PGLOCALEDIR=" & objDevServer.InstallDir & "\share\locale"
  objTmpBatch.WriteLine "SET PGDATABASE=" & p_strDatabase
  objTmpBatch.WriteLine "SET PGPASSWORD=" & objDevServer.SuperPassword
  objTmpBatch.WriteLine ""
  If p_bIsSql Then
    l_strExtCmd = " -c """ & p_strSql & """"
  Else
    l_strExtCmd = " -f """ & p_strSql & """"
  End If
  objTmpBatch.WriteLine """" & objDevServer.InstallDir & "\bin\psql.exe"" " & p_strCmdOpts & l_strExtCmd
  objTmpBatch.Close

  If p_bRunCmd Then
    RunProgram l_strTmpFilePath, "", strScriptOutput, strScriptError, iStatus
    RunPsql=""
    If FSO.FileExists(l_strTmpFilePath) Then
      FSO.DeleteFile(l_strTmpFilePath)
    End If
  Else
    RunPsql=l_strTmpFilePath
  End If
End Function

Function SetVariableFrompsqlOutput(ByRef pl_strVar, ByVal p_strSql, ByVal p_strDatabase)
  Dim l_strCmdFile, l_strVar, l_strErrMsg, l_iStatus
  SetVariableFrompsqlOutput = 0
  pl_strVar = ""
  l_strCmdFile = RunPsql(false, "-t", true, p_strSql, p_strDatabase)
  SetVariableFromScriptOutput l_strCmdFile, "", l_strVar, l_strErrMsg, l_iStatus
  If FSO.FileExists(l_strCmdFile) Then
    FSO.DeleteFile(l_strCmdFile)
  End If
  If l_iStatus = 0 Then
    pl_strVar = l_strVar
  End If
  SetVariableFrompsqlOutput = l_iStatus
End Function

Function IsPostGISPresent()
  Dim l_strErrMsg
  IsPostGISPresent = false
  LogMessage "IsPostGISPresent: Checking for the presense of PostGIS..."
  If FSO.FolderExists(objDevServer.InstallDir & "\PostGIS") AND _
     IsFileExists(objDevServer.InstallDir, "share\contrib\postgis.sql", l_strErrMsg) AND _
     IsFileExists(objDevServer.InstallDir, "share\contrib\spatial_ref_sys.sql", l_strErrMsg) AND _
     IsFileExists(objDevServer.InstallDir, "share\contrib\postgis_comments.sql", l_strErrMsg) AND _
     IsFileExists(objDevServer.InstallDir, "share\contrib\postgis_upgrade.sql", l_strErrMsg) Then

     Set objBinFolder = FSO.GetFolder(objDevServer.InstallDir & "\bin")
     For Each objBinFiles In objBinFolder.Files
       l_strFileName = objBinFiles.Name
       If Left(l_strFileName, 8) = "postgis-" Then
         CopyFile objDevServer.InstallDir & "\bin\" & l_strFileName, _
                  objDevServer.InstallDir & "\lib\" & l_strFileName, false
         IsPostGISPresent = true : Exit For
       End If
     Next
     If NOT IsPostGISPresent Then
       Set objLibFolder = FSO.GetFolder(objDevServer.InstallDir & "\lib")
       For Each objLibFiles In objLibFolder.Files
         l_strFileName = objLibFiles.Name
         If Left(l_strFileName, 8) = "postgis-" Then
           IsPostGISPresent = true : Exit For
         End If
       Next
     End If

     If IsPostGISPresent Then
       SetVariableFrompsqlOutput l_strTemplatePostGIS, _
           "SELECT d.datname FROM pg_catalog.pg_database d WHERE d.datname='template_postgis'", CONSTADMINDATABASE
       If NOT Trim(l_strTemplatePostGIS) = "" Then
         ' It seems 'temaplate_postgis' already been present. No need to configure PostGIS
         IsPostGISPresent = false
       End If
     End If
  End If
End Function

Sub ConfigurePostGIS
  ' Create postgis template database
  RunPsql true, "-t", true, "CREATE DATABASE template_postgis", ""
  ' Mark teh the database as a template
  RunPsql true, "-t", true, "UPDATE pg_database SET datistemplate='t' WHERE datname='template_postgis'", ""
  ' Installing postgis script
  RunPsql true, "-t", false, objDevServer.InstallDir & "\share\contrib\postgis.sql", "template_postgis"
  ' Installing spantial script
  RunPsql true, "-t", false, objDevServer.InstallDir & "\share\contrib\spatial_ref_sys.sql", "template_postgis"
  ' Installing postgis comments
  RunPsql true, "-t", false, objDevServer.InstallDir & "\share\contrib\postgis_comments.sql", "template_postgis"
End Sub

Function IsSlonyPresent
  Dim l_strErrMsg
  IsSlonyPresent = false
  If FSO.FolderExists(objDevServer.InstallDir & "\Slony") AND _
     IsFileExists(objDevServer.InstallDir, "Slony\installer\Slony\configureslony.bat", l_strErrMsg) AND _
     IsFileExists(objDevServer.InstallDir, "lib\slony1_funcs.dll", l_strErrMsg) AND _
     IsFileExists(objDevServer.InstallDir, "lib\slevent.dll", l_strErrMsg) AND _
     IsFileExists(objDevServer.InstallDir, "bin\slonik.exe", l_strErrMsg) AND _
     IsFileExists(objDevServer.InstallDir, "bin\slon.exe", l_strErrMsg) Then
    If IsFileExists(objDevServer.InstallDir, "Slony\installer\Slony\removeFiles.bat", l_strErrMsg) Then
      Exit Function
    End If
    IsSlonyPresent = true : Exit Function
  End If
End Function

Sub ConfigureSlony
  LogMessage "ConfigureSlony:"
  l_strConfFile = objDevServer.InstallDir & "\Slony\installer\Slony\configureslony.bat"
  l_strRemoveFile = objDevServer.InstallDir & "\Slony\installer\Slony\removeFiles.bat"
  SetVariableFromScriptOutput objDevServer.InstallDir & "\bin\pg_config.exe", "--pkglibdir", l_strPkgLibDir, l_strErrMsg, l_iStatus
  SetVariableFromScriptOutput objDevServer.InstallDir & "\bin\pg_config.exe", "--sharedir", l_strShareDir, l_strErrMsg, l_iStatus

  l_strPkgLibDir = Replace(l_strPkgLibDir, "/", "\")
  l_strShareDir  = Replace(l_strShareDir, "/", "\")

  ' Open the configuration file and replace the place holders
  Set l_objConfFile = FSO.OpenTextFile(l_strConfFile, 1)
  l_strData = l_objConfFile.ReadAll
  l_objConfFile.Close

  l_strData = Replace(l_strData, "@@PKG_LIBDIR@@", l_strPkgLibDir)
  l_strData = Replace(l_strData, "@@SHARE_DIR@@", l_strShareDir)

  Set l_objConfFile = FSO.OpenTextFile(l_strConfFile, 2)
  l_objConfFile.WriteLine l_strData
  l_objConfFile.Close

  ' Run the configuration file
  RunProgram l_strConfFile, objDevServer.InstallDir, strScriptOutput, strScriptError, iStatus

  Set l_objRemoveFile = FSO.OpenTextFile(l_strRemoveFile, 1)
  l_strData = l_objRemoveFile.ReadAll
  l_objRemoveFile.Close

  l_strData = Replace(l_strData, """", "")

  Set l_objRemoveFile = FSO.OpenTextFile(l_strRemoveFile, 2)
  l_objRemoveFile.WriteLine l_strData
  l_objRemoveFile.Close

End Sub

Function IsPgAgentPresent
  IsPgAgentPresent = false
  If FSO.FolderExists(objDevServer.InstallDir & "\pgAgent") AND _
     IsFileExists(objDevServer.InstallDir, "share\pgagent.sql", l_strErrMsg) AND _
     IsFileExists(objDevServer.InstallDir, "bin\pgagent.exe", l_strErrMsg) AND _
     IsFileExists(objDevServer.InstallDir, "bin\pgaevent.dll", l_strErrMsg) AND _
     IsFileExists(objDevServer.InstallDir, "installer\pgAgent\pgaevent.dll", l_strErrMsg) Then
    SetVariableFrompsqlOutput l_strHasSchema, "SELECT has_schema_privilege('pgagent', 'USAGE')", CONSTADMINDATABASE
    ' pgAgent component present, but we will configure it only if 'pgagent' schema does not exists
    If l_strHasSchema = "" Then
      IsPgAgentPresent = true
    End If
  End If
End Function

Sub CreatePGPassConfig
  Set l_objServiceUser = WMIService.Get("Win32_UserAccount.Name='" & objDevServer.ServiceAccountWODomain & "',Domain='" & _
                                        objDevServer.ServiceDomain & "'")
  l_strServiceUserSID = l_objServiceUser.SID

  Set l_objReg = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\default:StdRegProv")
  l_objReg.GetStringValue HKLM, "SOFTWARE\MicroSoft\Windows NT\CurrentVersion\\ProfileList\" & l_strServiceUserSID, "ProfileImagePath", l_strUserProfile

  ' User has never logged in to the system using this user. :(
  ' TODO: Find a way to call LoadUserProfile from VBScript or Make sure CreatePgPassConfForUser.exe utility exists
  '       in user directory
  If l_strUserProfile = "" Then
    Exit Sub
  End IF

  If NOT FSO.FolderExists(l_strUserProfile & "\postgresql") Then
    FSO.CreateFolder l_strUserProfile & "\postgresql"
  End If

  l_strConfData = ""
  l_strConfMatch = "localhost:" & objDevServer.Port & ":" & CONSTADMINDATABASE & ":" & _
                  objDevServer.SuperUser
  l_strConfLine = l_strConfMatch & ":" & objDevServer.SuperPassword

  If IsFileExists(l_strUserProfile, "postgresql\pgpass.conf", l_strDummy) Then
    l_iLenMatch = Len(l_strConfMatch)
    l_bMatched = false
    Set objReadFile = FSO.OpenTextFile(l_strUserProfile & "\postgresql\pgpass.conf",1)
    Do While Not objReadFile.AtEndOfStream
      l_strCurrLine = objReadFile.ReadLine
      If NOT l_bMatched AND Left(l_strCurrLine, l_iLenMatch) = l_strConfMatch Then
        l_bMatched = true
        l_strConfData = l_strConfData & vbCRLF & l_strCurrLine
      Else
        l_strConfData = l_strConfData & vbCRLF & l_strCurrLine
      End If
    Loop
  Else
    l_strConfData = l_strConfLine
  End If

  Set objWriteFile = FSO.OpenTextFile(l_strUserProfile & "\postgresql\pgpass.conf", 2)
  objWriteFile.Write l_strConfData
  objWriteFile.Close
End Sub

Sub ConfigurepgAgent
  RunPsql true, "-t", true, "CREATE SCHEMA pgagent", CONSTADMINDATABASE
  RunPsql true, "-t", false, objDevServer.InstallDir & "\pgAgent\share\pgagent.sql"

  CreatePGPassConfig
  If NOT WMI_Service_Exists(CONSTPGAGENTSERVICE) Then
    RunProgram objDevServer.InstallDir & "\pgAgent\bin\pgagent.exe" , _
               array("INSTALL", CONSTPGAGENTSERVICE, "-u", objDevServer.ServiceAccount, "-p", _
                   objDevServer.ServicePassword, "host=localhost port=" & objDevServer.Port & _
                   " user=" & objDevServer.SuperUser & " dbname=" & CONSTADMINDATABASE), _
               l_strScriptOutput, l_strScriptError, l_iStatus
  Else
    ShowMessage "The pgAgent Service (" & CONSTPGAGENTSERVICE & ") already exists."
  End If
  Call WMI_Service_Restart(CONSTPGAGENTSERVICE, 300)
End Sub

'************************************
'* Registry Item Exists (Function)
'* Returns a value (true / false)
'************************************
'This function checks to see if a passed registry key/value exists, and
'returns true if it does
'
'Requirements: The registry key/value you are looking for (RegistryItem)
'Note: RegistryItem MUST end in a backslash (\) if you are looking for a key
'      RegistryItem's without a backslash (\) will assume you are looking for a value
Function RegistryItemExists (RegistryItem)
  'If there isnt the item when we read it, it will return an error, so we need to resume
  On Error Resume Next

  'Find out if we are looking for a key or a value
  If (Right(RegistryItem, 1) = "\") Then
    'It's a registry key we are looking for
    'Try reading the key
    WshShell.RegRead RegistryItem

    'Catch the error
    Select Case Err
      'Error Code 0 = 'success'
      Case 0:
        RegistryItemExists = true
      'This checks for the (Default) value existing (but being blank); as well as key's not existing at all (same error code)
      Case &h80070002:
        'Read the error description, removing the registry key from that description
        ErrDescription = Replace(Err.description, RegistryItem, "")

        'Clear the error
        Err.clear

        'Read in a registry entry we know doesn't exist (to create an error description for something that doesnt exist)
        WshShell.RegRead "HKEY_ERROR\"

        'The registry key exists if the error description from the HKEY_ERROR RegRead attempt doesn't match the error
        'description from our RegistryKey RegRead attempt
        If (ErrDescription <> Replace(Err.description, "HKEY_ERROR\", "")) Then
          RegistryItemExists = true
        Else
          RegistryItemExists = false
        End If
      'Any other error code is a failure code
      Case Else:
        RegistryItemExists = false
    End Select
  Else
    'It's a registry value we are looking for
    'Try reading the value
    WshShell.RegRead RegistryItem

    'Catch the error
    Select Case Err
      Case 0:
        'Error Code 0 = 'success'
        RegistryItemExists = true
      Case Else
        'Any other error code is a failure code
        RegistryItemExists = false
    End Select
  End If
  'Turn error reporting back on
  On Error Goto 0
End Function

Function IsPsqlODBCPresent
  IsPsqlODBCPresent = false
  If RegistryItemExists("HKLM\SOFTWARE\ODBC\ODBCINST.INI\ODBC Drivers\PostgreSQL " & objDevServer.Version & " (UNICODE)") Then
    If WshShell.RegRead("HKLM\SOFTWARE\ODBC\ODBCINST.INI\ODBC Drivers\PostgreSQL " & objDevServer.Version & " (UNICODE)") = "Installed" Then
      ShowMessage "PostgreSQL " & objDevServer.MajorVersion & " (UNICODE) Driver is already been installed."
      Exit Function
    End If
  End If
  If RegistryItemExists("HKLM\SOFTWARE\ODBC\ODBCINST.INI\ODBC Drivers\PostgreSQL " & objDevServer.Version & " (ANSI)") Then
    If WshShell.RegRead("HKLM\SOFTWARE\ODBC\ODBCINST.INI\ODBC Drivers\PostgreSQL " & objDevServer.Version & " (ANSI)") = "Installed" Then
      ShowMessage "PostgreSQL " & objDevServer.MajorVersion & " (ANSI) Driver is already been installed."
      Exit Function
    End If
  End If
  If FSO.FolderExists(objDevServer.InstallDir & "\psqlODBC") Then
    Set l_subDirs = FSO.GetFolder(objDevServer.InstallDir & "\psqlODBC").SubFolders
    For Each l_subDir in l_subDirs
      objODBC.Path = l_subDir.Path
      If IsFileExists(l_subDir.Path, "\bin\psqlodbc35w.dll", l_strDummy) AND _
         IsFileExists(l_subDir.Path, "\bin\psqlodbc30a.dll", l_strDummy) Then
         IsPsqlODBCPresent = true : Exit Function
      End If
    Next
  End If
End Function

Sub ConfigurepgsqlODBC
  l_strTmpFile     = Replace(FSO.GetTempName, ".tmp", ".bat")
  l_strTmpFilePath = TempFolder.Path & "\" & l_strTmpFile
  Set objTmpBatch  = TempFolder.CreateTextFile(l_strTmpFile, True)
  ShowMessage "Configuring PostgreSQL (Unicode) Driver ..."
  objTmpBatch.WriteLine "odbcconf.exe /A {INSTALLDRIVER  ""PostgreSQL " & objDevServer.Version & " (Unicode)|Driver=" & objODBC.Path & "\bin\psqlodbc35w.dll|Setup=" & objODBC.Path & "\bin\psqlodbc35w.dll|APILevel=2|ConnectFunctions=YYY|DriverODBCVer=" & objDevServer.Version & "|FileUsage=0|SQLLevel=1""}"
  objTmpBatch.Close
  RunProgram l_strTmpFilePath, "", l_strScriptOutput, l_strScriptError, l_iStatus
  If NOT l_iStatus = 0 Then
    LogWarn "Couldn't install psqlODBC (Unicode) Driver" & vbCRLF & "Error Message:" & vbCRLF & l_strScriptError
  End If

  ShowMessage "Configuring PostgreSQL (ANSI) Driver ..."
  Set objTmpBatch  = TempFolder.CreateTextFile(l_strTmpFile, True)
  objTmpBatch.WriteLine "odbcconf.exe /A {INSTALLDRIVER  ""PostgreSQL " & objDevServer.Version & " (ANSI)|Driver=" & objODBC.Path & "\bin\psqlodbc30a.dll|Setup=" & objODBC.Path & "\bin\psqlodbc30w.dll|APILevel=2|ConnectFunctions=YYY|DriverODBCVer=" & objDevServer.Version & "|FileUsage=0|SQLLevel=1""}"
  objTmpBatch.Close
  RunProgram l_strTmpFilePath, "", l_strScriptOutput, l_strScriptError, l_iStatus
  If NOT l_iStatus = 0 Then
    LogWarn "Couldn't install psqlODBC (ANSI) Driver" & vbCRLF & "Error Message:" & vbCRLF & l_strScriptError
  End If
End Sub

Function IsPgBouncerPresent
  IsPgBouncerPresent = true
  If FSO.FolderExists(objDevServer.InstallDir & "\pgbouncer") AND _
     IsFileExists(objDevServer.InstallDir, "\pgbouncer\bin\pgbouncer.exe", l_strErrMsg) AND _
     IsFileExists(objDevServer.InstallDir, "\pgbouncer\installer\pgbouncer\securefile.vbs", l_strErrMsg) AND _
     IsFileExists(objDevServer.InstallDir, "\pgbouncer\installer\pgbouncer\startupcfg.bat", l_strErrMsg) AND _
     IsFileExists(objDevServer.InstallDir, "\pgbouncer\share\pgbouncer.ini", l_strErrMsg) Then
    IsPgBouncerPresent = true
    objPGBouncer.Path = objDevServer.InstallDir & "\pgbouncer"
  End If
End Function

Sub ConfigurePgBouncer
  If NOT FSO.FolderExists(objPGBouncer.Path & "\log") Then
    FSO.CreateFolder objPGBouncer.Path & "\log"
  End If
  If NOT FSO.FolderExists(objPGBouncer.Path & "\etc") Then
    FSO.CreateFolder objPGBouncer.Path & "\etc"
  End If

  Question "Please enter the data directory", "objPGBouncer.validatePort", iPbPort, iPbPort, bUnattended, true
  BackupFile objPGBouncer.Path & "\share\pgbouncer.ini"
  BackupNUseOriginalFile objPGBouncer.Path & "\share\pgbouncer.ini"
  Set objFile = FSO.OpenTextFile(objPGBouncer.Path & "\share\pgbouncer.ini", 1)
  l_strData = objFile.ReadAll
  objFile.Close

  l_strData = Replace(l_strData, "@@CON@@", "postgres = host=127.0.0.1 port=" & objDevServer.Port)
  l_strData = Replace(l_strData, "@@LISTENADDR@@", "*")
  l_strData = Replace(l_strData, "@@LISTENPORT@@", objPGBouncer.Port)
  l_strData = Replace(l_strData, "@@ADMINUSERS@@", objDevServer.SuperUser)
  l_strData = Replace(l_strData, "@@STATSUSERS@@", objDevServer.SuperUser)
  l_strData = Replace(l_strData, "@@LOGFILE@@", objPGBouncer.Path & "\log\pgbouncer.log")
  l_strData = Replace(l_strData, "@@PIDFILE@@", objPGBouncer.Path & "\log\pgbouncer.pid")
  l_strData = Replace(l_strData, "@@AUTHFILE@@", objPGBouncer.Path & "\etc\userlist.txt")

  Set objFile = FSO.OpenTextFile(objPGBouncer.Path & "\share\pgbouncer.ini", 2)
  objFile.WriteLine l_strData
  objFile.Close

  BackupFile objPGBouncer.Path & "\ect\userlist.txt"
  Set objFile = FSO.OpenTextFile(objPGBouncer.Path & "\etc\userlist.txt", 2)
  objFile.WriteLine """" & objDevServer.SuperUser & """ """ & objDevServer.SuperPassword & """"
  objFile.Close

  If NOT WMI_Service_Exists("pgbouncer") Then
    RunProgram objPGBouncer.Path & "\installer\pgbouncer\startupcfg.bat", _
             objPGBouncer.Path, l_strStdOut, l_strStrErr, l_iStatus
  Else
    LogMessage "The service pgbouncer already exists."
  End If

  RunProgram WScript.FullName, _
             array("//nologo", objPGBouncer.Path & "\installer\pgbouncer\securefile.vbs", _
                   objPGBouncer.Path & "\etc\userlist.txt", objDevServer.ServiceAccount), _
             l_strStdOut, l_strStrErr, l_iStatus

  Call WMI_Service_Restart("pgbouncer", 300)

End Sub

' Initialize
Call Init

Set objDevServer            = new DevServer
Question "Please enter the installation directory", "objDevServer.validateServerPath", strInstallDir, "", bUnattended, true

objDevServer.SuperUser      = Trim(strSuperUser)
objDevServer.ServiceAccount = Trim(strServiceAccount)
objDevServer.ServiceName  = Trim(strServiceName)

If bInstallRuntimes Then
  ShowMessage "Installing VC Runtimes..."
  RunProgram WScript.FullName, _
             array("//nologo", objDevServer.InstallDir & "\installer\installruntimes.vbs", _
                   objDevServer.InstallDir & strVCRedistFile), _
             strScriptOutput, strScriptError, iStatus
  If iStatus <> 0 Then
    LogError "Failed to install vc runtimes..." & strScriptError
  End If
End If

Question "Please enter the data directory", "objDevServer.validateDataDir", objDevServer.InstallDir & "\data", strDataDir, bUnattended, true
Question "Please enter the port", "objDevServer.validatePort", iPort, iPort, bUnattended, true
Question "Please enter the locale", "objDevServer.validateLocale", "DEFAULT", strLocale, bUnattended, true

LogNote "We won't be able to check the superuser - database password. Hence, there will no be validation done."
objDevServer.SuperPassword = Question("Please enter the Password for the SuperUser (" & objDevServer.SuperUser & ")", "", strSuperPassword, strSuperPassword, bUnattended, true)
LogNote "Service Account (" & objDevServer.ServiceAccount & ") will be created (only if not present, otherwise validated) with the provided password immediatedly"
Question "Please enter the Password for the ServiceAccount (" & objDevServer.ServiceAccount & ")", "objDevServer.validateServicePassword", strServicePassword, strServicePassword, bUnattended, true

ShowMessage "INSTALL DIR     : " & objDevServer.InstallDir
ShowMessage "DATA DIR        : " & objDevServer.DataDir
ShowMessage "PORT            : " & objDevServer.Port
ShowMessage "LOCALE          : " & objDevServer.Locale
ShowMessage "Super User      : " & objDevServer.SuperUser
ShowMessage "Super Password  : " & objDevServer.SuperPassword
ShowMessage "Serivce Account : " & objDevServer.ServiceAccount
ShowMessage "Serivce Password: " & objDevServer.ServicePassword

If NOT FSO.FolderExists(objDevServer.DataDir) OR _
   NOT IsFileExists(objDevServer.DataDir, "postgresql.conf", lStrErrMsg) Then
  ShowMessage "Initializing Cluster..."
  If NOT FSO.FolderExists(objDevServer.DataDir) Then
    FSO.CreateFolder objDevServer.DataDir
  End If
  LogNote "This can take some time..."
  RunProgram WScript.FullName, _
             array("//nologo", objDevServer.InstallDir & "\installer\server\initcluster.vbs", _
                   objDevServer.ServiceAccount, objDevServer.SuperUser, objDevServer.SuperPassword, _
                   objDevServer.InstallDir, objDevServer.DataDir, objDevServer.Port, objDevServer.Locale), _
             strScriptOutput, strScriptError, iStatus

  Select Case iStatus
    Case 1
      LogError "The database cluster initialisation failed."
    Case 2
      LogWarn  "A non-fatal error occured during cluster initialisation. Please check the installation log for details."
    Case 0
      LogNote  "The database cluster initialisation done successfully."
    Case else
      LogError "Unknow Error (while cluster initialisation)" & vbCRLF & strScriptError
  End Select
End If

If NOT WMI_Service_Exists(objDevServer.ServiceName) Then
  ShowMessage "Registering/Recreating the server service (" & objDevServer.ServiceName & ")..."
  RunProgram WScript.FullName, _
             array("//nologo", objDevServer.InstallDir & "\installer\server\startupcfg.vbs", _
                   objDevServer.Version, objDevServer.ServiceAccount, objDevServer.ServicePassword, _
                   objDevServer.InstallDir, objDevServer.DataDir, objDevServer.ServiceName), _
             strScriptOutput, strScriptError, iStatus
  Select Case iStatus
    Case 0
      ' Do nothing. Successfully done
    Case 1
      LogError "Failed to configure the database to auto-start at boot time."
    Case 127
      LogError "The script was called with the invalid command line arguments."
    Case 2
      LogWarn "A non-fatal error occured during startup configuration. Please check the installation log for details."
  End Select
Else
  ShowMessage "The Service " & objDevServer.ServiceName & " already exists."
End If

BackupNUseOriginalFile objDevServer.InstallDir & "\scripts\serverctl.vbs"
BackupNUseOriginalFile objDevServer.InstallDir & "\scripts\runpsql.bat"

RunProgram WScript.FullName, _
           array("//nologo", objDevServer.InstallDir & "\installer\server\createshortcuts.vbs", _
                 objDevServer.Version, objDevServer.SuperUser, objDevServer.Port, g_strBranding, _
                 objDevServer.InstallDir, objDevServer.DataDir, objDevServer.ServiceName), _
           strScriptOutput, strScriptError, iStatus
Select Case iStatus
  Case 0
    ' Do nothing. Successfully done
  Case 1
    LogWarn "A non-fatal error occured during configuring shortcuts. Please check the installation log for details."
  Case 127
    LogError "The script was called with the invalid command line arguments"
  Case Else
    LogError "Unknown Error calling createshortcuts.vbs script. Please check the installation log for details."
End Select
FSO.CopyFile objDevServer.InstallDir & "\scripts\serverctl.vbs", objDevServer.InstallDir & "\scripts\serverctl_" & objDevServer.ServiceName & ".vbs", true
FSO.CopyFile objDevServer.InstallDir & "\scripts\runpsql.bat", objDevServer.InstallDir & "\scripts\runpsql_" & objDevServer.ServiceName & ".bat", true

ShowMessage "Starting server..."
RunProgram WScript.FullName, _
           array("//nologo", objDevServer.InstallDir & "\scripts\serverctl.vbs", "start"), _
           strScriptOutput, strScriptError, iStatus

If NOT iStatus = 0 Then
  LogError "Couldn't start the server service (" & objDevServer.ServiceName & ")."
End If

ShowMessage "Loading Modules..."
RunProgram WScript.FullName, _
           array("//nologo", objDevServer.InstallDir & "\installer\server\loadmodules.vbs", _
                 objDevServer.SuperUser, objDevServer.SuperPassword, objDevServer.InstallDir, _
                 objDevServer.DataDir, objDevServer.Port, "1"), _
           strScriptOutput, strScriptError, iStatus
Select Case iStatus
  Case 0
    ' Do nothing. Successfully done
  Case 1
    LogWarn "A non-fatal error occured during configuring shortcuts. Please check the installation log for details."
  Case 127
    LogError "The script(loadmodules.vbs) was called with the invalid command line arguments"
  Case Else
    LogError "Unknown Error calling createshortcuts.vbs script. Please check the installation log for details."
End Select

ShowMessage "Createing pg_env.bat..."
BackupFile objDevServer.InstallDir & "\pg_env.bat"
If NOT IsFileExists(NULL, objDevServer.InstallDir & "\pg_env.bat", l_strDummy) Then
  Set objpgEnvFile = FSO.CreateTextFile(objDevServer.InstallDir & "\pg_env.bat", True)
Else
  Set objpgEnvFile = FSO.OpenTextFile(objDevServer.InstallDir & "\pg_env.bat", 2)
End If
objpgEnvFile.WriteLine _
  "@ECHO OFF" & vbCRLF & _
  "REM The script sets environment variables helpful for PostgreSQL" & vbCRLF & _
  "SET PATH=%PATH%;" & objDevServer.InstallDir & "\bin" & vbCRLF & _
  "SET PGDATA=" & objDevServer.DataDir & vbCRLF & _
  "SET PGUSER=" & objDevServer.SuperUser & vbCRLF & _
  "SET PGPORT=" & objDevServer.Port & vbCRLF & _
  "SET PGLOCALEDIR=" & objDevServer.InstallDir & "\share\locale" & vbCRLF
objpgEnvFile.Close
Set objpgEnvFile = Nothing

WshSystemEnv("PGDATABASE") = "template1"
WshSystemEnv("PGPASSWORD") = objDevServer.SuperPassword

If IsPostGISPresent Then
  If AskYesNo("PostGIS Found. Do you want to configure? (Y/N) ", bInstallPostGIS) Then
    ConfigurePostGIS
  End If
End If

If IsSlonyPresent Then
  If AskYesNo("Slony Found. Do you want to configure? (Y/N) ", bInstallSlony) Then
    ConfigureSlony
  End If
End If

If IsPgAgentPresent Then
  If AskYesNo("pgAgent Found. Do you want to configure? (Y/N) ", bInstallPgAgent) Then
    ConfigurepgAgent
  End If
End If

SET objODBC = new PsqlODBC
If IsPsqlODBCPresent Then
   If AskYesNo("psqlodbc Found. Do you want to configure? (Y/N) ", bInstallPsqlODBC) Then
     ConfigurepgsqlODBC
   End If
End If

SET objPGBouncer = new PGBouncer
If IsPgBouncerPresent Then
   If AskYesNo("pgbouncer Found. Do you want to configure? (Y/N) ", bInstallPgBouncer) Then
     ConfigurePgBouncer
   End If
End If

' Always call this file at the end
Call Finish(1)
