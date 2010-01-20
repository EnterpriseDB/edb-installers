' Postgres Plus installer script (extract-only mode) for windows
' Ashesh Vashi, EnterpriseDB

'Initialization
Dim WSO, WSI, FSO, WshShell, WshApp
Dim strSuperUser, strSuperPassword, strServiceAccount, strServicePassword, strDataDir, strInstallDir, strLocale, strPort, strServiceName
Dim bUnattended, bWScript, bInstallRuntimes, bDebug
Dim strExitMsg, strVCRedistFile

Dim iStatus, strScriptOutput, strScriptError

SET WSO = WScript.StdOut
SET WSI = WScript.StdIn
SET FSO = CreateObject("Scripting.FileSystemObject")
Set WshShell = CreateObject("WScript.Shell")
Set WshApp   = CreateObject("Shell.Application")

' TODO: We need to take care about 64 bit windows too in future.
strVCRedistFile = "\installer\vcredist_x86.exe"

strInstallDir      = FSO.GetAbsolutePathName(".")
strSuperUser       = "postgres"
strSuperPassword   = "postgres"
strServicePassword = "postgres"
strLocale          = "DEFAULT"
strServiceName     = "PgSQL"
iPort              = 5432
bUnattended        = false
bInstallRuntimes   = true
bDebug             = true

Function FileExistsInFolder(ByVal pStrPath, ByVal pStrFileName, ByRef pStrMsg)
  FileExistsInFolder = true

  If NOT FSO.FileExists(pStrPath & "\" & pStrFileName) Then
    pStrMsg = "File (" & pStrFileName & ") couldn't find in the given path (" & pStrPath & ")."
    FileExistsInFolder = false
  End If
End Function

Sub ShowMessage(p_strMsg)
  If NOT bWScript Then
    WScript.Echo p_strMsg
  End If
  ' TODO: Please log the messages in the log file.
End Sub

Sub LogMessage(p_strMsg)
  If NOT bDebug And bWScript Then
    WScript.Echo p_strMsg
  End If
  ' TODO: Please log the messages in the log file
End Sub

Sub LogError(p_strErrMsg)
  WScript.Echo vbCRLF & "FATAL ERROR: " & p_strErrMsg & vbCRLF
  ' TODO: Please log the messages in the log file
  WScript.Quit(-1)
End Sub

Sub LogWarn(p_strMsg)
  WScript.Echo vbCRLF & "WARNING: " & p_strMsg & vbCRLF
  ' TODO: Please log the messages in the log file
End Sub

Sub LogNote(p_strNote)
  WScript.Echo vbCRLF & "NOTE: " & p_strNote
  ' TODO: Please log the messages in the log file
End Sub

Sub SetVariableFromScriptOutput(ByVal p_strCmd, ByVal p_aCmdArgs, ByRef pl_strVariable, ByRef pl_iStatus)
  Dim l_iLArgs, l_iUArgs, lExec, l_strCmdArgs, l_strStdOut, l_strStdErr
  pl_strVariable = ""
  pl_iStatusCode = 127

  If p_strCmd = NULL OR Trim(p_strCmd) = "" Then
    pl_iStatusCode = 127
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
  p_strCmd = Trim("""" & p_strCmd & """ " & Trim(l_strCmdArgs))

  'The tool is launched
  LogMessage "SetVariableFromScriptOutput: " & pStrCmd
  set lExec = WshShell.Exec(p_strCmd)

  If lExec.Status = 0 Then
    lExec.Terminate()
  End If

  pl_iStatusCode = lExec.ExitCode
  Do While lExec.StdOut.AtEndOfStream <> True
    l_strStdOut = l_strStdOut & vbCRLF & lExec.StdOut.ReadLine
  Loop
  LogMessage vbCRLF & "Script Output: " & _
             vbCRLF & "---------------" & _
             vbCRLF & l_strStdOut

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
  pl_strStdOut   = ""
  pl_strStdErr   = ""
  pl_iStatusCode = 0

  If p_strCmd = NULL OR Trim(p_strCmd) = "" Then
    pl_iStatusCode = -1 : pl_strStdErr   = "RunProgram : Provide command to execute." : Exit Sub
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
  p_strCmd = Trim(p_strCmd & " " & Trim(l_strCmdArgs))

  LogMessage "RunProgram: " & p_strCmd

  Set lExec = WshShell.Exec(p_strCmd)

  l_iWaitCount = 0
  Do
    WScript.Sleep 100
    l_iWaitCount = l_iWaitCount + 1
  Loop Until lExec.Status <> 0 OR l_iWaitCount >= 1000

  If l_iWaitCount >= 1000 AND lExec.Status = 0 Then
    lExec.Terminate()
    LogError "Couldn't complete execution of the command (" & p_strCmd & ")"
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
End Sub

Function Usage(exitcode)
  Dim strUsage
  strUsage = "USAGE: " & VBCRLF & _
    "  " & WScript.FullName & " //nologo " & WScript.ScriptFullName & " <options> " & VBCRLF & _
    "options:" & VBCRLF &  _
    "-su | --superuser <superuser> # Database Super User" & VBCRLF & _
    "-sp | --superpassword <superpassword> # Database Super Password" & VBCRLF & _
    "-sa | --serviceaccount <username> # Service Account (OS User)" & VBCRLF & _
    "-sn | --servicename <service-name> # Name of PostgreSQL Service" & VBCRLF & _
    "-sap | --servicepassword <password> # Password for the service account" & VBCRLF & _
    "-d | --datadir <directory> # Data Directory" & VBCRLF & _
    "-i | --installdir <directory> # Installation Directory" & VBCRLF & _
    "-l | --locale <locale> # Locale" & VBCRLF & _
    "-p | --port <port> # Port" & VBCRLF & _
    "-u | --unattended # Unattended Mode" & VBCRLF & _
    "-r | --install-runtimes <1|0> # Install Runtimes" & VBCRLF & _
    "-h | --help # Show usage"
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
    strPort = cmdArguments(argIndex)
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
  ElseIf cmdArguments(argIndex) = "-h" OR cmdArguments(argIndex) = "--help" Then
    Usage 0
  Else
    strExitMsg = "'" & cmdArguments(argIndex) & "' is not a supported command-line argument." 
    Usage 1
  End If
  argIndex = argIndex + 1
Loop

Sub Question(ByVal que, ByVal validator, ByVal defVal, ByVal actualVal, ByVal stopInstallOnError, ByVal loopUntilRes)
  Dim bRes, strAnswer, strErrMsg
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
      WSO.Write que & " [" & defVal & "] : "
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
    If NOT bRes AND loopUntilRes Then
      LogNote strErrMsg
    End If
  Loop Until bRes AND loopUntilRes
End Sub

Function AskYesNo(ByVal que, ByVal defVal)

  Dim strAnswer
  AskYesNo = false

  If NOT bUnattended Then
    WSO.Write que & " [" & defVal &"] : "
    strAnswer = Trim(WSI.ReadLine)
 End If

 If strAnswer = "" Then
   strAnswer = defVal
 End If
 If strAnswer = "Y" OR strAnswer = "Y" Then
   AskYesNo = true
 End If
  
End Function

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
    m_strServiceAccount = l_strServiceAccount
    m_strServiceDomain  = l_strServiceDomain
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
    Version = m_strVersion
  End Property

  Public Function validateServerPath(pStrInstallDir, ByRef pStrErrMsg)
    validateServerPath = false

    If FileExistsInFolder(pStrInstallDir, "bin\psql.exe", pStrErrMsg) AND _
       FileExistsInFolder(pStrInstallDir, "bin\postgres.exe", pStrErrMsg) AND _
       FileExistsInFolder(pStrInstallDir, "bin\pg_config.exe", pStrErrMsg) AND _
       FileExistsInFolder(pStrInstallDir, "bin\pg_ctl.exe", pStrErrMsg) AND _
       FileExistsInFolder(pStrInstallDir, "bin\pg_controldata.exe", pStrErrMsg) AND _
       FileExistsInFolder(pStrInstallDir, "bin\initdb.exe", pStrErrMsg) AND _
       FileExistsInFolder(pStrInstallDir, "installer\server\createuser.exe", pStrErrMsg) AND _
       FileExistsInFolder(pStrInstallDir, "installer\server\validateuser.exe", pStrErrMsg) AND _
       FileExistsInFolder(pStrInstallDir, "installer\server\getlocales.exe", pStrErrMsg) AND _
       FileExistsInFolder(pStrInstallDir, "installer\server\startupcfg.vbs", pStrErrMsg) AND _
       FileExistsInFolder(pStrInstallDir, "installer\server\createshortcuts.vbs", pStrErrMsg) AND _
       FileExistsInFolder(pStrInstallDir, "installer\server\startserver.vbs", pStrErrMsg) AND _
       FileExistsInFolder(pStrInstallDir, "installer\server\loadmodules.vbs", pStrErrMsg) AND _
       FileExistsInFolder(pStrInstallDir, "installer\server\initcluster.vbs", pStrErrMsg) AND _
       FileExistsInFolder(pStrInstallDir, "installer\vcredist_x86.exe", pStrErrMsg) AND _
       FileExistsInFolder(pStrInstallDir, "scripts\serverctl.vbs", pStrErrMsg) Then
      validateServerPath = true
      m_strInstallDir = pStrInstallDir
      SetVariableFromScriptOutput pStrInstallDir & "\installer\server\getlocales.exe", "", lStrLocales, l_iStatus
      SetVariableFromScriptOutput pStrInstallDir & "\bin\pg_config.exe", "--version", l_strVersion, l_iStatus

      If l_iStatus <> 0 Then
        LogError "PostgreSQL version could not be determined. Please check the log files for details."
      End If

      l_strVersion = Trim(l_strVersion)
      l_iPos = InStr(l_strVersion, " ")
      m_strVersion = Right(l_strVersion, Len(l_strVersion)-l_iPos)

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
      If FileExistsInFolder(pStrDataDir, "", lStrErrMsg) Then
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

    If NOT FileExistsInFolder(pStrDataDir, "postgresql.conf", lStrErrMsg) OR _
       NOT FileExistsInFolder(pStrDataDir, "PG_VERSION", lStrErrMsg) OR _
       NOT FileExistsInFolder(pStrDataDir, "global\pg_database", lStrErrMsg) OR _
       NOT FileExistsInFolder(pStrDataDir, "global\pg_auth", lStrErrMsg) Then
      pStrErrMsg = vbCRLF & "Not a Valid Data Directory." & lStrErrMsg
      Exit Function
    End If
 
    m_strDataDir = pStrDataDir
    validateDataDir = true

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
  End Function

  Public Function validatePort(pPort, ByRef pStrErrMsg)
    validatePort = false
    If NOT IsNumeric(pPort) OR NOT InStr(pPort, ".") = 0 Then
      pStrErrMsg = "'" & pPort & "' is not a valid port."
      Exit Function
    End If
    If piPort > 1000 AND pPort < 65535 Then
      pStrErrMsg = "'" & pPort & "' is not within valid range (Port < 1000 & > 65535)."
      Exit Function
    End If
    
    m_iPort = pPort
    validatePort = true
  End Function

  Public Function validateLocale(strLocale, ByRef pStrErrMsg)
    validateLocale = false
    If UCase(strLocale) = "DEFAULT" Then
      m_strLocale = "DEFAULT" : validateLocale = true : Exit Function
    End If
    If strLocale = NULL OR Trim(strLocale) = "" Then
      pStrErrMsg = "Not a valid locale." : Exit Function
    End If
    filteredArray = Filter(m_arrayLocales, LCase(strLocale))
    If NOT IsArray(filteredArray) OR _
       UBound(filteredArray) = -1 OR _
       NOT filteredArray(0) = LCase(strLocale) Then
      pStrErrMsg = "Not a valid locale." : Exit Function
    End If

    m_strLocale = strLocale
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
     Case 1
       LogNote "The password specified was incorrect. Please enter the correct password for the '" & ServiceAccount & "' windows user account."
       Exit Function
     Case 0
       ' Do Nothing
       ' Successfully validated
     Case Else
       LogError l_strScriptError
   End Select
   m_strServicePassword = p_strServicePassword
   validateServicePassword = true
  End Function
End Class

Set objDevServer            = new DevServer
objDevServer.SuperUser      = Trim(strSuperUser)
objDevServer.ServiceAccount = Trim(strServiceAccount)
objDevServer.ServiceName    = Trim(strServiceName)

Question "Please enter the installation directory", "objDevServer.validateServerPath", strInstallDir, "", bUnattended, true

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

Question "Please enter the data directory", "objDevServer.validateDataDir", strInstallDir & "\data", strDataDir, bUnattended, true
Question "Please enter the port", "objDevServer.validatePort", iPort, "", bUnattended, true
Question "Please enter the locale", "objDevServer.validateLocale", "DEFAULT", strLocale, bUnattended, true

WScript.Echo "INSTALL DIR     : " & objDevServer.InstallDir
WScript.Echo "DATA DIR        : " & objDevServer.DataDir
WScript.Echo "PORT            : " & objDevServer.Port
WScript.Echo "LOCALE          : " & objDevServer.Locale
WScript.Echo "Super User      : " & objDevServer.SuperUser
WScript.Echo "Serivce Account : " & objDevServer.ServiceAccount

Question "Please enter the Password for the SuperUser (" & objDevServer.SuperUser & ")", "", strSuperPassword, strSuperPassword, bUnattended, true
LogNote "Service Account (" & objDevServer.ServiceAccount & ") will be created with the provided password immediatedly"
Question "Please enter the Password for the ServiceAccount (" & objDevServer.ServiceAccount & ")", "objDevServer.validateServicePassword", strServicePassword, strServicePassword, bUnattended, true

If NOT FSO.FolderExists(objDevServer.DataDir) AND _
   NOT FileExistsInFolder(pStrDataDir, "postgresql.conf", lStrErrMsg) Then
  ShowMessage "Initializing Cluster..."
  FSO.CreateFolder objDevServer.DataDir
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
    LogError "The script was called with an invalid command line"
  Case 2
    LogWarn "A non-fatal error occured during startup configuration. Please check the installation log for details."
End Select

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
    LogError "The script was called with an invalid command line"
  Case Else
    LogError "Unknown Error calling createshortcuts.vbs script. Please check the installation log for details."
End Select

ShowMessage "Starting server..."
RunProgram WScript.FullName, _
           array("//nologo", objDevServer.InstallDir & "\scripts\serverctl.vbs", "start"), _
           strScriptOutput, strScriptError, iStatus
