' Copyright (c) 2012, EnterpriseDB Corporation.  All rights reserved
Option Explicit
' Postgres Plus Advanced Server server control script for Windows

'The name of the log file
Const FILE_NAME_LOG = "serverctl.log"

Const ForAppending  = 8

Dim objFSO
Dim strFile_Log
Dim objFile_Log
Dim objWSHShell
Dim strTempDir, strServiceName, strAction
Dim intWaitTimeout, iRet
Dim bIsWScript, bIsDebug, bHasError, bWait

bIsWScript = false
bIsDebug = false
bHasError = false

If InStr(Ucase(WScript.FullName), "WSCRIPT.EXE") Then
  'WScript.Echo "Please use CScript to run this script"
  bIsWScript = true
End If


'The amount of time that the script will wait for a service to change state.
'I.E. How long to wait for a service to go from Started to Stopped.
'Possible values
'   > 0 is wait that many seconds
'   = 0 is do not wait
'   < 0 is wait indefinitely
intWaitTimeout = 300     'seconds, 300 = 5 minutes

Set objFSO      = CreateObject("Scripting.FileSystemObject")
Set objWSHShell = CreateObject("Wscript.Shell")

'Get the location of the WinDir environment variable
strTempDir = objWshShell.ExpandEnvironmentStrings("%Temp%")

'Build the log file path
strFile_Log = strTempDir & "\" & FILE_NAME_LOG

'Open the log file
Set objFile_Log = objFSO.OpenTextFile(strFile_Log, ForAppending, True)

Sub Usage()
  LogError "USAGE: serverctl.vbs <start|stop|restart|reload> <wait>"
  WScript.Quit 127
End Sub

If WScript.Arguments.Count = 0 OR WScript.Arguments.Count > 2 Then
    Usage
End If

bWait = False
If WScript.Arguments.Count = 2 Then
    If WScript.Arguments.Item(1) = "wait" Then
        bWait = True
    Else
        Usage
    End If
End If

strServiceName = "pphq"
strAction      = WScript.Arguments.Item(0)


If NOT (strAction = "start" OR strAction = "stop" OR strAction = "restart" OR strAction = "reload") Then
  Usage
End If
Select Case strAction
  Case "restart"
    Call WMI_Service_Restart(".", "", "", strServiceName, 300)
    If bHasError = true Then
      ShowMessage l_strErr
    End If
  Case "start"
    Call WMI_Service_Start(".", "", "", strServiceName, 300)
  Case "stop"
    Call WMI_Service_Stop(".", "", "", strServiceName, 300)
End Select

If bWait = True Then
    If iRet <> 0 Then
        WScript.Echo "The " & strAction & " command returned an error (" & iRet & ")"
    End If
    WScript.StdOut.Write vbCrLf & "Press <return> to continue..."
    WScript.StdIn.ReadLine
End If

'Close the log file
objFile_Log.Close

' Execute a command
Function DoCmd(cmd)
    Dim objShell
    Dim objOutput
    Dim strOutput
    Set objShell = WScript.CreateObject("WScript.Shell")
    Set objOutput = objShell.Exec(cmd)
    Do While Not objOutput.StdOut.AtEndOfStream
        If Not objOutput.StdOut.AtEndOfStream Then
           strOutput = strOutput & vbCrLf & objOutput.StdOut.ReadLine
        End If
    Loop
    Do While Not objOutput.StdErr.AtEndOfStream
        If Not objOutput.StdErr.AtEndOfStream Then
           strOutput = strOutput & vbCrLf & objOutput.StdErr.ReadLine
        End If
    Loop
    WScript.Echo strOutput
    DoCmd = objOutput.ExitCode
    Set objOutput = Nothing
    Set objShell = Nothing
End Function
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Name:    WMI_Service_Restart
'
' Purpose: To initiate actions required to restart a service
'
' Inputs:  strComputer    = The name of the computer to manage
'          strUserName    = The name of the user to connect as
'          strPassword    = The password for strUserName
'          strServiceName = The name of the service to manage
'          intWaitTimeout = The amount of time to wait for a service
'                           to change its State
'
' Outputs: No direct output
'
' Usage:   Call WMI_Service_Restart(".", "", "", "Spooler", 300)
'          Will, on the local system, restart the Print Spooler service,
'          all its antecedents, all its dependencies, and  will
'          wait 300 seconds for each service to change its State.
'
'          Call WMI_Service_Restart("SMSServer01", _
'                                   "TheSMSAdminName", _
'                                   "TheSMSAdminPassword", _
'                                   "SMS_EXECUTIVE", _
'                                   300)
'          Will, on the SMSServer01 system, using the specified user
'          credentials, restart the SMS_EXECUTIVE service, all its
'          antecedents, and all its dependencies.
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Public Sub WMI_Service_Restart(strComputer, _
                               strUserName, _
                               strPassword, _
                               strServiceName, _
                               intWaitTimeout)
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

  'This needs to be expanded to fully regression handle antecedent
  'and dependent services.
  'The code currently only goes one level up (antecedent) and down (dependent).

  On Error Resume Next
  
  Dim objServices
  Dim colServiceList, objService
  Dim intReturnCode
  Dim dtmStart
  Dim strServiceState
  Dim strServiceStartMode

  LogMessage ""
  LogMessage "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  LogMessage "Starting management of the " & strServiceName & " service on " & strComputer & "."
  LogMessage "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

  'This code is based on WMI. Therefore, we cannot stop the WMI service

  'This check could be removed and the code will stop all services that
  'are dependent on the WMI service, it will be sure all services that
  'WMI depends on are started, and will then start all services that
  'depend on the WMI service.
  If UCase(strServiceName) = "WINMGMT" Then
    LogError "ERROR: Cannot restart the " & strServiceName & " service."
    Exit Sub
  End If

  'Be sure the strComputer is online before proceeding
  If Not WMI_Ping(strComputer) Then
    LogMessage "  " & strComputer & " is Offline"
    Exit Sub
  End If

  'Instantiate a reference to SWbemLocator
  If Not IsObject(objLocator) Then
    Dim objLocator
    Err.Clear
    Set objLocator = CreateObject("WbemScripting.SWbemLocator")

    'Error check
    If (Err.Number <> 0) And Not IsObject(objLocator) Then
      LogError "ERROR#" & Err.Number & ": " & Err.Description & VbCrLf & _
               "  Source : "   & Err.Source
      Exit Sub
    End If
  End If

  'Instantiate a connection to WMI
  'Were alternate credentials supplied?
  'Note: Cannot use alternate credentials when connecting to the local system
  LogMessage "Connecting to WMI on " & strComputer
  Err.Clear
  If (strUserName <> "") And (strPassword <> "") And (strComputer <> ".") Then
    LogMessage "  Using alternate credentials (" & strUserName & ")."
    Set objServices = objLocator.ConnectServer(strComputer, "Root/CimV2", strUserName, strPassword)
  Else
    Set objServices = objLocator.ConnectServer(strComputer, "Root/CimV2")
  End If

  'Error check
  If (Err.Number <> 0) And Not IsObject(objServices) Then
    LogError "ERROR#" & Err.Number & ": " & Err.Description & VbCrLf & _
               "  Source : "   & Err.Source

    'Look up WMI errors
    Call WMI_Services_Error_Lookup(Err.Number)

    Set objServices = Nothing    
    'Set objLocator = Nothing
    Exit Sub
  End If

  'Set the Impersonatin Level
  objServices.Security_.ImpersonationLevel = 3

  'Determine if the specified service exists
  LogMessage ""
  LogMessage "-----------------------------------------------------------------------------"
  LogMessage "Checking if the " & strServiceName & " service exists on " & strComputer & "."
  LogMessage "-----------------------------------------------------------------------------"
  If Not WMI_Service_Exists(objServices, strServiceName) Then
    LogError "ERROR# The service " & strServiceName & " does not exist."
    Exit Sub
  End If


  'Check to see if the specified service can accept a Stop or Pause command

  'This check could be removed and the code will stop all services that
  'are dependent on the WMI service, it will be sure all services that
  'WMI depends on are started, and will then start all services that
  'depend on the WMI service.
  LogMessage ""
  LogMessage "-----------------------------------------------------------------------------"
  LogMessage "Checking if the " & strServiceName & " service can accept a Stop control command."
  LogMessage "-----------------------------------------------------------------------------"
  If Not WMI_Service_CanAcceptCmd(objServices, strServiceName, "Stop") Then
    LogError "Error: The service " & strServiceName & " can not be stopped."
    Exit Sub
  End If

  'Get the state of the specified service
  LogMessage ""
  LogMessage "-----------------------------------------------------------------------------"
  LogMessage "Checking the state of the " & strServiceName & " service."
  LogMessage "-----------------------------------------------------------------------------"
  strServiceState = WMI_Service_State_Get(objServices, strServiceName)

  'Wait for the service to stabilize if the service state is changing
  If Instr(1, "Start Pending, Continue Pending, Stop Pending, Pause Pending", strServiceState, vbTextCompare) Then
    Call WMI_Service_State_WaitOnChange(objServices, strServiceName, "Paused, Running, Stopped", intWaitTimeout)
    strServiceState = WMI_Service_State_Get(objServices, strServiceName)
  End If

  'The service is in an 'Unknown' state
  If strServiceState = "Unknown" Then
    LogError "The " & strServiceName & " service is in an unknown state."
    Exit Sub
  End If

  '*****************************************************************************
  'Is the service in one of the running states?
  'If yes, stop the antecedents, the user specified service, and the dependents
  If Instr(1, "Running, Paused", strServiceState, vbTextCompare) Then
    'Instantiate a reference to a collection that contains services that are
    'dependent on the user specified service (Dependent services).
    Err.Clear
    Set colServiceList = objServices.ExecQuery("Associators of " & _
                          "{Win32_Service.Name='" & strServiceName & "'} " & _
                          "Where AssocClass=Win32_DependentService " & _
                          "Role=Antecedent")

    'Error check
    If (Err.Number <> 0) And Not IsObject(colServiceList) Then
      LogError "ERROR#" & Err.Number & ": " & Err.Description & VbCrLf & _
               "  Source: " & Err.Source

      'Lookup WMI errors
      Call WMI_Services_Error_Lookup(Err.Number)
    Else

      'There are services that depend on the user specified service if the count is greater than 0
      If colServiceList.Count > 0 Then
        LogMessage "Stopping services that depend on the " & strServiceName & " service."
        LogMessage "-----------------------------------------------------------------------------"
        'Loop through the collection and send a Stop command to each service
        For Each objService in colServiceList
          LogMessage ""
          LogMessage objService.Name & " service."
          'Is the service already stopped?
          If objService.State = "Stopped" Then
            LogMessage "  The " & objService.Name & " service is already Stopped."
          Else
            'Call the procedure to send the command
            strServiceState = WMI_Service_State_Set(objServices, objService.Name, "Stop", intWaitTimeout)
          End If
        Next
      End If
    End If
    LogMessage "-----------------------------------------------------------------------------"
    ShowMessage "Stopping the " & strServiceName & " service."
    LogMessage "-----------------------------------------------------------------------------"

    'Call the procedure to send the command to the user specified service
    strServiceState = WMI_Service_State_Set(objServices, strServiceName, "Stop", intWaitTimeout)
  End If
  '*****************************************************************************

  '*****************************************************************************
  'Is the service in a stopped states?
  'If yes, start the antecedents, the user specified service, and the dependents

  If strServiceState = "Stopped" Then

    'Instantiate a reference to a collection that contains services that the
    'user specified service depends on (Antecedent services).
    Err.Clear
    Set colServiceList = objServices.ExecQuery("Associators of " & _
                          "{Win32_Service.Name='" & strServiceName & "'} " & _
                          "Where AssocClass=Win32_DependentService " & _
                          "Role=Dependent")

    'Error check
    If (Err.Number <> 0) And Not IsObject(colServiceList) Then
      LogError "ERROR#" & Err.Number & ": " & Err.Description & VbCrLf & _
               "  Source: " & Err.Source
      'Lookup WMI errors
      Call WMI_Services_Error_Lookup(Err.Number)
    Else
      'The user specified service does depend on other services if the count is greater than 0
      If colServiceList.Count > 0 Then
        LogMessage "Starting services that the " & strServiceName & " service depends on."
        LogMessage "-----------------------------------------------------------------------------"
        For Each objService in colServiceList
          LogMessage objService.Name & " service."
          'Get the service StartMode
          strServiceStartMode = objService.StartMode
          'Skip the service if the StartMode is Disabled or Manual
          If Instr(1, "Disabled, Manual", strServiceStartMode, vbTextCompare) Then
            LogMessage "  !Skipping a Start since the service is set to " & strServiceStartMode & "."
          Else
            'Call the procedure to send the command to the antecedent service
            strServiceState = WMI_Service_State_Set(objServices, objService.Name, "Start", intWaitTimeout)
          End If
        Next
      End If
    End If

    ShowMessage "Starting the " & strServiceName & " service."
    LogMessage "-----------------------------------------------------------------------------"

    'LogMessage ""
    'LogMessage strServiceName & " service."
    'Call the procedure to send the command to the user specified service
    strServiceState = WMI_Service_State_Set(objServices, strServiceName, "Start", intWaitTimeout)

    'Instantiate a reference to a collection that contains services that are
    'dependent on the user specified service (Dependent services).
    Err.Clear
    Set colServiceList = objServices.ExecQuery("Associators of " & _
                          "{Win32_Service.Name='" & strServiceName & "'} " & _
                          "Where AssocClass=Win32_DependentService " & _
                          "Role=Antecedent")

    'Error check
    If (Err.Number <> 0) And Not IsObject(colServiceList) Then
      LogError "ERROR#" & Err.Number & Err.Description & VbCrLf & _
               "  Source: " & Err.Source

      'Lookup WMI errors
      Call WMI_Services_Error_Lookup(Err.Number)
    Else
      'There are services that depend on the user specified service if the count is greater than 0
      If colServiceList.Count > 0 Then
        LogMessage "-----------------------------------------------------------------------------"
        LogMessage "Starting services that depend on the " & strServiceName & " service."
        LogMessage "-----------------------------------------------------------------------------"
        For Each objService in colServiceList
          LogMessage ""
          LogMessage objService.Name & " service."
          'Get the service StartMode
          strServiceStartMode = objService.StartMode
          'Skip the service if the StartMode is Disabled or Manual
          If Instr(1, "Disabled, Manual", strServiceStartMode, vbTextCompare) Then
            LogMessage "  !Skipping a Start for " & objService.Name & " since it is set to " & strServiceStartMode & "."
          Else
            'Call the procedure to send the command to the dependent service
            strServiceState = WMI_Service_State_Set(objServices, objService.Name, "Start", intWaitTimeout)
          End If
        Next
      End If
    End If
  End If
  '*****************************************************************************
  
  LogMessage "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  LogMessage "Done managing the " & strServiceName & " service."
  LogMessage "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  If bHasError = false Then
      ShowMessage "The " & strServiceName & " service restared successfully."
  End If
End Sub

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Name:    WMI_Service_Start
'
' Purpose: To initiate actions required to start a service
'
' Inputs:  strComputer    = The name of the computer to manage
'          strUserName    = The name of the user to connect as
'          strPassword    = The password for strUserName
'          strServiceName = The name of the service to manage
'          intWaitTimeout = The amount of time to wait for a service
'                           to change its State
'
' Outputs: No direct output
'
' Usage:   Call WMI_Service_Restart(".", "", "", "Spooler", 300)
'          Will, on the local system, start the Print Spooler service,
'          all its antecedents, all its dependencies, and  will
'          wait 300 seconds for each service to change its State.
'
'          Call WMI_Service_Start("SMSServer01", _
'                                   "TheSMSAdminName", _
'                                   "TheSMSAdminPassword", _
'                                   "SMS_EXECUTIVE", _
'                                   300)
'          Will, on the SMSServer01 system, using the specified user
'          credentials, start the SMS_EXECUTIVE service, all its
'          antecedents, and all its dependencies.
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Public Sub WMI_Service_Start(strComputer, _
                               strUserName, _
                               strPassword, _
                               strServiceName, _
                               intWaitTimeout)
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

  'This needs to be expanded to fully regression handle antecedent
  'and dependent services.
  'The code currently only goes one level up (antecedent) and down (dependent).

  On Error Resume Next
  
  Dim objServices
  Dim colServiceList, objService
  Dim intReturnCode
  Dim dtmStart
  Dim strServiceState
  Dim strServiceStartMode

  LogMessage ""
  LogMessage "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  LogMessage "Starting management of the " & strServiceName & " service on " & strComputer & "."
  LogMessage "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

  'This code is based on WMI. Therefore, we cannot stop the WMI service

  'This check could be removed and the code will stop all services that
  'are dependent on the WMI service, it will be sure all services that
  'WMI depends on are started, and will then start all services that
  'depend on the WMI service.
  If UCase(strServiceName) = "WINMGMT" Then
    LogError "ERROR: Cannot restart the " & strServiceName & " service."
    Exit Sub
  End If

  'Be sure the strComputer is online before proceeding
  If Not WMI_Ping(strComputer) Then
    LogMessage "  " & strComputer & " is Offline"
    Exit Sub
  End If

  'Instantiate a reference to SWbemLocator
  If Not IsObject(objLocator) Then
    Dim objLocator
    Err.Clear
    Set objLocator = CreateObject("WbemScripting.SWbemLocator")

    'Error check
    If (Err.Number <> 0) And Not IsObject(objLocator) Then
      LogError "ERROR#" & Err.Number & ": " & Err.Description & VbCrLf & _
               "  Source : "   & Err.Source
      Exit Sub
    End If
  End If

  'Instantiate a connection to WMI
  'Were alternate credentials supplied?
  'Note: Cannot use alternate credentials when connecting to the local system
  LogMessage "Connecting to WMI on " & strComputer
  Err.Clear
  If (strUserName <> "") And (strPassword <> "") And (strComputer <> ".") Then
    LogMessage "  Using alternate credentials (" & strUserName & ")."
    Set objServices = objLocator.ConnectServer(strComputer, "Root/CimV2", strUserName, strPassword)
  Else
    Set objServices = objLocator.ConnectServer(strComputer, "Root/CimV2")
  End If

  'Error check
  If (Err.Number <> 0) And Not IsObject(objServices) Then
    LogError "ERROR#" & Err.Number & ": " & Err.Description & VbCrLf & _
             "  Source : "   & Err.Source

    'Look up WMI errors
    Call WMI_Services_Error_Lookup(Err.Number)

    Set objServices = Nothing    
    'Set objLocator = Nothing
    Exit Sub
  End If

  'Set the Impersonatin Level
  objServices.Security_.ImpersonationLevel = 3

  'Determine if the specified service exists
  LogMessage ""
  LogMessage "-----------------------------------------------------------------------------"
  LogMessage "Checking if the " & strServiceName & " service exists on " & strComputer & "."
  LogMessage "-----------------------------------------------------------------------------"
  If Not WMI_Service_Exists(objServices, strServiceName) Then
    LogError "ERROR# The service " & strServiceName & " does not exist."
    Exit Sub
  End If

  'Get the state of the specified service
  LogMessage ""
  LogMessage "-----------------------------------------------------------------------------"
  LogMessage "Checking the state of the " & strServiceName & " service."
  LogMessage "-----------------------------------------------------------------------------"
  strServiceState = WMI_Service_State_Get(objServices, strServiceName)

  'Wait for the service to stabilize if the service state is changing
  If Instr(1, "Start Pending, Continue Pending, Stop Pending, Pause Pending, Paused, Running", strServiceState, vbTextCompare) Then
    Call WMI_Service_State_WaitOnChange(objServices, strServiceName, "Paused, Running, Stopped", intWaitTimeout)
    strServiceState = WMI_Service_State_Get(objServices, strServiceName)
  End If

  'The service is in an 'Unknown' state
  If NOT (strServiceState = "Stopped") Then
    LogError "The " & strServiceName & " service can not be started. It's current state is (" & strServiceState & ")."
    Exit Sub
  End If

  ShowMessage "Starting the " & strServiceName & " service."
  LogMessage "-----------------------------------------------------------------------------"

  'Call the procedure to send the command to the user specified service
  strServiceState = WMI_Service_State_Set(objServices, strServiceName, "Start", intWaitTimeout)
      
  LogMessage "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  LogMessage "Done starting the " & strServiceName & " service."
  LogMessage "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  
  If bHasError = false Then
      ShowMessage "The " & strServiceName & " service stared successfully."
  End If
End Sub

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Name:    WMI_Service_Stop
'
' Purpose: To initiate actions required to stop a service
'
' Inputs:  strComputer    = The name of the computer to manage
'          strUserName    = The name of the user to connect as
'          strPassword    = The password for strUserName
'          strServiceName = The name of the service to manage
'          intWaitTimeout = The amount of time to wait for a service
'                           to change its State
'
' Outputs: No direct output
'
' Usage:   Call WMI_Service_Stop(".", "", "", "Spooler", 300)
'          Will, on the local system, stop the Print Spooler service,
'          all its antecedents, all its dependencies, and  will
'          wait 300 seconds for each service to change its State.
'
'          Call WMI_Service_Stop("SMSServer01", _
'                                   "TheSMSAdminName", _
'                                   "TheSMSAdminPassword", _
'                                   "SMS_EXECUTIVE", _
'                                   300)
'          Will, on the SMSServer01 system, using the specified user
'          credentials, stop the SMS_EXECUTIVE service, all its
'          antecedents, and all its dependencies.
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Public Sub WMI_Service_Stop(strComputer, _
                               strUserName, _
                               strPassword, _
                               strServiceName, _
                               intWaitTimeout)
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

  'This needs to be expanded to fully regression handle antecedent
  'and dependent services.
  'The code currently only goes one level up (antecedent) and down (dependent).

  On Error Resume Next
  
  Dim objServices
  Dim colServiceList, objService
  Dim intReturnCode
  Dim dtmStart
  Dim strServiceState
  Dim strServiceStartMode

  LogMessage ""
  LogMessage "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  LogMessage "Starting management of the " & strServiceName & " service on " & strComputer & "."
  LogMessage "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

  'This code is based on WMI. Therefore, we cannot stop the WMI service

  'This check could be removed and the code will stop all services that
  'are dependent on the WMI service, it will be sure all services that
  'WMI depends on are started, and will then start all services that
  'depend on the WMI service.
  If UCase(strServiceName) = "WINMGMT" Then
    LogError "ERROR: Cannot stop the " & strServiceName & " service."
    Exit Sub
  End If

  'Be sure the strComputer is online before proceeding
  If Not WMI_Ping(strComputer) Then
    LogMessage "  " & strComputer & " is Offline"
    Exit Sub
  End If

  'Instantiate a reference to SWbemLocator
  If Not IsObject(objLocator) Then
    Dim objLocator
    Err.Clear
    Set objLocator = CreateObject("WbemScripting.SWbemLocator")

    'Error check
    If (Err.Number <> 0) And Not IsObject(objLocator) Then
      LogError "ERROR#" & Err.Number & ": " & Err.Description & VbCrLf & _
               "  Source : "   & Err.Source
      Exit Sub
    End If
  End If

  'Instantiate a connection to WMI
  'Were alternate credentials supplied?
  'Note: Cannot use alternate credentials when connecting to the local system
  LogMessage "Connecting to WMI on " & strComputer
  Err.Clear
  If (strUserName <> "") And (strPassword <> "") And (strComputer <> ".") Then
    LogMessage "  Using alternate credentials (" & strUserName & ")."
    Set objServices = objLocator.ConnectServer(strComputer, "Root/CimV2", strUserName, strPassword)
  Else
    Set objServices = objLocator.ConnectServer(strComputer, "Root/CimV2")
  End If

  'Error check
  If (Err.Number <> 0) And Not IsObject(objServices) Then
    LogError "ERROR#" & Err.Number & ": " & Err.Description & VbCrLf & _
             "  Source : " & Err.Source

    'Look up WMI errors
    Call WMI_Services_Error_Lookup(Err.Number)

    Set objServices = Nothing    
    'Set objLocator = Nothing
    Exit Sub
  End If

  'Set the Impersonatin Level
  objServices.Security_.ImpersonationLevel = 3

  'Determine if the specified service exists
  LogMessage ""
  LogMessage "-----------------------------------------------------------------------------"
  LogMessage "Checking if the " & strServiceName & " service exists on " & strComputer & "."
  LogMessage "-----------------------------------------------------------------------------"
  If Not WMI_Service_Exists(objServices, strServiceName) Then
    LogError "ERROR# The service " & strServiceName & " does not exist."
    Exit Sub
  End If


  'Get the state of the specified service
  LogMessage ""
  LogMessage "-----------------------------------------------------------------------------"
  LogMessage "Checking the state of the " & strServiceName & " service."
  LogMessage "-----------------------------------------------------------------------------"
  strServiceState = WMI_Service_State_Get(objServices, strServiceName)

  'Wait for the service to stabilize if the service state is changing
  If Instr(1, "Start Pending, Continue Pending, Stop Pending, Pause Pending", strServiceState, vbTextCompare) Then
    Call WMI_Service_State_WaitOnChange(objServices, strServiceName, "Paused, Running, Stopped", intWaitTimeout)
    strServiceState = WMI_Service_State_Get(objServices, strServiceName)
  End If

  'The service is in an 'Unknown' state
  If strServiceState = "Unknown" Then
    LogError "The " & strServiceName & " service is in an Uknown state."
    Exit Sub
  End If

  '*****************************************************************************
  'Is the service in one of the running states?
  'If yes, stop the antecedents, the user specified service, and the dependents
  If Instr(1, "Running, Paused", strServiceState, vbTextCompare) Then
    'Instantiate a reference to a collection that contains services that are
    'dependent on the user specified service (Dependent services).
    Err.Clear
    Set colServiceList = objServices.ExecQuery("Associators of " & _
                          "{Win32_Service.Name='" & strServiceName & "'} " & _
                          "Where AssocClass=Win32_DependentService " & _
                          "Role=Antecedent")

    'Error check
    If (Err.Number <> 0) And Not IsObject(colServiceList) Then
      LogError "ERROR#" & Err.Number & ": " & Err.Description & VbCrLf & _
               "  Source: " & Err.Source

      'Lookup WMI errors
      Call WMI_Services_Error_Lookup(Err.Number)
    Else

      'There are services that depend on the user specified service if the count is greater than 0
      If colServiceList.Count > 0 Then
        LogMessage "Stopping services that depend on the " & strServiceName & " service."
        LogMessage "-----------------------------------------------------------------------------"
        'Loop through the collection and send a Stop command to each service
        For Each objService in colServiceList
          LogMessage ""
          LogMessage objService.Name & " service."
          'Is the service already stopped?
          If objService.State = "Stopped" Then
            LogMessage "  The " & objService.Name & " service is already Stopped."
          Else
            'Call the procedure to send the command
            strServiceState = WMI_Service_State_Set(objServices, objService.Name, "Stop", intWaitTimeout)
          End If
        Next
      End If
    End If
    LogMessage "-----------------------------------------------------------------------------"
    ShowMessage "Stopping the " & strServiceName & " service."
    LogMessage "-----------------------------------------------------------------------------"

    'Call the procedure to send the command to the user specified service
    strServiceState = WMI_Service_State_Set(objServices, strServiceName, "Stop", intWaitTimeout)
  Else
    LogError "The " & strServiceName & " service is not running."
  End If
  
  LogMessage "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  LogMessage "Done stopping the " & strServiceName & " service."
  LogMessage "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  If bHasError = false Then
      ShowMessage "The " & strServiceName & " service stopped successfully."
  End If
End Sub

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Name:    WMI_Service_State_Set
' Purpose: To send a specified command to a service
' Inputs:  objServices    = A reference to a previously instantiated WMI reference
'          strServiceName = The name of the service to control
'          strServiceCmd  = The command to send to the service
'          intWaitTimeout = The amount of time to wait for the service to change
'                           state, in seconds.
'                           If negative, the wait will be indefinite.
'                           If zero, there will be no wait.
' Outputs: The state of the service after sending the control command and
'          optionally waiting for the service state to change.
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Private Function WMI_Service_State_Set(objServices, _
                                       strServiceName, _
                                       strServiceCmd, _
                                       intWaitTimeout)
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

  On Error Resume Next

  Dim objService
  Dim intReturn, intReturnCode
  Dim strServiceState_Desired
  Dim blnExit

  'Default value to determine if certain procedural things should be skipped later
  blnExit = False

  LogMessage "  Connecting to the " & strServiceName & " service."

  'Instantiate a reference to the service
  Err.Clear
  Set objService = objServices.Get("Win32_Service='" & strServiceName & "'")
  
  'Error check
  If (Err.Number <> 0) And Not IsObject(objService) Then
    LogError "ERROR: Could not connecting to the " & strServiceName & " service." & vbCrLf & _
             "Error#" & Err.Number & ": " & Err.Description & VbCrLf & _
             "  Source: " & Err.Source

    'Lookup WMI errors
    Call WMI_Services_Error_Lookup(Err.Number)
    Exit Function
  End If

  'Default service state to wait for if a wait is specified
  strServiceState_Desired = "Running"

  'What control command was specified?
  Select Case strServiceCmd
    Case "Stop"
      'This code depends on WMI. Therefore, we cannot control the WMI service
      If UCase(strServiceName) = "WINMGMT" Then
        LogError "  Cannot stop the " & strServiceName & " service."
        blnExit = True
      Else
        'Can the service accept a stop?
        If objService.AcceptStop Then
          LogMessage "  Sending service command: "  & strServiceCmd

          'Send the specified service control
          intReturnCode = objService.StopService()

          'The service state to wait for if a wait is specified
          strServiceState_Desired = "Stopped"
        Else
          LogMessage "  The " & strServiceName & " cannot accept a " & strServiceCmd & " command."
          
          'Certain procedural tasks need to be skipped later
          blnExit = True
        End If
      End If
    Case "Start"
      LogMessage "  Sending service command: "  & strServiceCmd

      'Send the specified service control
      intReturnCode = objService.StartService()
    Case "Resume"
      LogMessage "  Sending service command: "  & strServiceCmd
    
      'Send the specified service control
      intReturnCode = objService.ResumeService()
    Case "Pause"
      If UCase(strServiceName) = "WINMGMT" Then
        LogError "ERROR: Cannot pause the " & strServiceName & " service."
        'Certain procedural tasks need to be skipped later
        blnExit = True
      Else
        'Can the service accept a pause?
        If objService.AcceptPause Then
          LogMessage "  Sending service command: "  & strServiceCmd
        
          'Send the specified service control
          intReturnCode = objService.PauseService()

          'The service state to wait for if a wait is specified
          strServiceState_Desired = "Paused"
        Else
          LogMessage "  The " & strServiceName & " cannot accept a " & strServiceCmd & " command."

          'Certain procedural tasks need to be skipped later
          blnExit = True
        End If
      End If
  End Select

  'Error check
  If Err.Number <> 0 Then
    LogError "ERROR: Error sending the service command to the " & strServiceName & " service." & vbCrLf & _
             "ERROR#" & Err.Number & ": " & Err.Description & VbCrLf & _
             "  Source: " & Err.Source

    'Certain procedural tasks need to be skipped later
    blnExit = True
  End If

  If Not blnExit Then
    'Lookup WMI errors
    Call WMI_Services_Error_Lookup(intReturnCode)

    'Was the service control successful?
    If intReturnCode = 0 Then
      WMI_Service_State_Set = WMI_Service_State_WaitOnChange(objServices, strServiceName, strServiceState_Desired, intWaitTimeout)
    End If
  End If

  If IsObject(objService) Then Set objService = Nothing

End Function

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Name:    WMI_Service_Exists
' Purpose: To determine if a service exists on the system
' Inputs:  objServices    = A reference to a previously instantiated WMI reference
'          strServiceName = The name of the service to check
' Outputs: True  = The service does exist
'          False = The service does not exist
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Private Function WMI_Service_Exists(objServices, _
                                    strServiceName)
  On Error Resume Next
  
  Dim colServiceList

  LogMessage "  Query WMI for the " & strServiceName & " service."

  'Query WMI
  Err.Clear
  Set colServiceList = objServices.ExecQuery("Select * From Win32_Service Where Name='" & _
                                             strServiceName & "'")
  'Error check
  If (Err.Number = 0) And IsObject(colServiceList) Then
    If colServiceList.Count > 0 Then
      LogMessage "    The " & strServiceName & " service exists."

      'Set the function return value
      WMI_Service_Exists = True
    Else
      'Set the function return value
      WMI_Service_Exists = False
    
      LogMessage "    The " & strServiceName & " service does not exist."
    End If
  Else
    'Output error details
    LogError "ERROR#" & Err.Number & ": " & Err.Description & VbCrLf & _
             "  Source: " & Err.Source

    'Lookup WMI errors
    Call WMI_Services_Error_Lookup(Err.Number)
  End If
  
  Set colServiceList = Nothing

End Function

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Name:    WMI_Service_State_Get
' Purpose: To get the state of a service
' Inputs:  objServices    = A reference to a previously instantiated WMI reference
'          strServiceName = The name of the service to check
' Outputs: The current state of the service
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Private Function WMI_Service_State_Get(objServices, _
                                       strServiceName)
  On Error Resume Next
  
  Dim objService
  Dim strServiceState
  Dim intReturn

  LogMessage "  Connecting to the " & strServiceName & " service."

  'Instantiate a reference to the service
  Err.Clear
  Set objService = objServices.Get("Win32_Service='" & strServiceName & "'")
  
  'Error check
  If (Err.Number = 0) And IsObject(objService) Then
    'I'm unsure if this is still needed
    'Tell the service to update its state in the service manager
    intReturn = objService.InterrogateService()

    'Get the current service state
    strServiceState = objService.State

    LogMessage "    The service state is: " & strServiceState

    'Set the function return value
    WMI_Service_State_Get = strServiceState
  Else
    'Output error details
    LogError "ERROR#" & Err.Number & ": " & Err.Description & VbCrLf & _
             "  Source: " & Err.Source

    'Lookup WMI errors
    Call WMI_Services_Error_Lookup(Err.Number)
  End If

  If IsObject(objService) Then Set objService = Nothing
End Function


''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Name:    WMI_Service_CanAcceptCmd
' Purpose: Check to see if a service can accept a Stop or Pause control command
' Inputs:  objServices    = A reference to a previously instantiated WMI reference
'          strServiceName = The name of the service to check
'          strCommand     = The control command to check for
' Outputs: True  - If the service can accept the control command
'          False - If the service cannot accept the control command
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Private Function WMI_Service_CanAcceptCmd(objServices, _
                                          strServiceName, _
                                          strCommand)
  On Error Resume Next
  Dim objService

  'Set default value
  WMI_Service_CanAcceptCmd = False

  LogMessage "  Connecting to the " & strServiceName & " service."

  Err.Clear
  'Instantiate a reference to the service
  Set objService = objServices.Get("Win32_Service='" & strServiceName & "'")
  
  'Error check
  If (Err.Number = 0) And IsObject(objService) Then
    'Select which check was requested and determine if the service can
    'accept the control command
    Select Case strCommand
      Case "Stop"
        'Do the check and set the function return value
        WMI_Service_CanAcceptCmd = objService.AcceptStop
      Case "Pause"
        'Do the check and set the function return value
        WMI_Service_CanAcceptCmd = objService.AcceptPause
    End Select

    'Output results
    If WMI_Service_CanAcceptCmd Then
      LogMessage "    The " & strServiceName & " can accept a " & strCommand & " command."
    Else
      LogMessage "    The " & strServiceName & " cannot accept a " & strCommand & " command."
    End If
  Else
    'Output error details
    LogError "ERROR#" & Err.Number & ": " & Err.Description & VbCrLf & _
             "  Source : "   & Err.Source

    'Lookup WMI errors
    Call WMI_Services_Error_Lookup(-1)
  End If

  If IsObject(objService) Then Set objService = Nothing

End Function


''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Name:    WMI_Service_State_WaitOnChange
' Purpose: To wait for a service to enter a specified state
' Inputs:  objServices             = A reference to a previously instantiated WMI reference
'          strServiceName          = The name of the service to wait for
'          strServiceState_Desired = The state to wait for
'          intWaitTimeout          = The amount of time to wait for the service to change
'                                    state, in seconds.
'                                    If negative, the wait will be indefinite.
'                                    If zero, there will be no wait.
' Outputs: The current state of the service
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Private Function WMI_Service_State_WaitOnChange(objServices, _
                                                strServiceName, _
                                                strServiceState_Desired, _
                                                intWaitTimeout)
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

  On Error Resume Next
  
  Dim strServiceState
  Dim strWait
  Dim blnWait
  Dim dtmStart

  'The current Date and Time
  dtmStart = Now()

  'Set some text
  If intWaitTimeout > 0 Then
    strWait = "  - Wait " & intWaitTimeout & " seconds"
    blnWait = True
  ElseIf intWaitTimeout < 0 Then
    strWait = "  - Wait indefinitely"
    blnWait = True
  Else
    strWait = "  - Do not wait"
    blnWait = False
  End If

  LogMessage strWait & " for the " & strServiceName & " service to enter a " & strServiceState_Desired & " state."

  'Get the state of the service
  strServiceState = WMI_Service_State_Get(objServices, strServiceName)

  If blnWait Then
    'Loop while the service state is not equal to the desired service state
    Do While Instr(1, strServiceState_Desired, strServiceState, vbTextCompare) = 0
  
      'Check if the wait period has exceeded the timeout
      If intWaitTimeout > 0 Then
  
        'DateDiff comparison
        If DateDiff("s", dtmStart, Now()) > (intWaitTimeout / 2) Then
          LogMessage "  Timed out waiting for the " & strServiceName & " service to enter a " & strServiceState_Desired & " state."
          Exit Do
        End If
  
      End If
  
      'Pause for 1/2 second
      Wscript.Sleep(500)
  
      'Get the state of the service
      strServiceState = WMI_Service_State_Get(objServices, strServiceName)
  
    Loop
  End If

  'Return the current service state
  WMI_Service_State_WaitOnChange = strServiceState

End Function

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Name:    WMI_Services_Error_Lookup
' Purpose: Lookup WMI error codes
' Inputs:  intError = The Err.Number or WMI service control result code
' Outputs: No direct output
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Private Sub WMI_Services_Error_Lookup(intError)
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

  On Error Resume Next
  
  Dim strError

  Select Case intError
    Case 0
      strError = "The request was accepted."
    Case 1
      strError = "The request is not supported."
    Case 2
      strError = "The user did not have the necessary access."
    Case 3
      strError = "The service cannot be stopped because other services that are running are dependent on it."
    Case 4
      strError = "The requested control code is not valid, or it is unacceptable to the service."
    Case 5
      strError = "The requested control code cannot be sent to the service because the state of the service (Win32_BaseService State property) is equal to 0, 1, or 2."
    Case 6
      strError = "The service has not been started."
    Case 7
      strError = "The service did not respond to the start request in a timely fashion."
    Case 8
      strError = "Interactive Process."
    Case 9
      strError = "The directory path to the service executable file was not found."
    Case 10
      strError = "The service is already running."
    Case 11
      strError = "The database to add a new service is locked."
    Case 12
      strError = "A dependency for which this service relies on has been removed from the system."
    Case 13
      strError = "The service failed to find the service required from a dependent service."
    Case 14
      strError = "The service has been disabled from the system."
    Case 15
      strError = "The service does not have the correct authentication to run on the system."
    Case 16
      strError = "This service is being removed from the system."
    Case 17
      strError = "There is no execution thread for the service."
    Case 18
      strError = "There are circular dependencies when starting the service."
    Case 19
      strError = "There is a service running under the same name."
    Case 20
      strError = "There are invalid characters in the name of the service."
    Case 21
      strError = "Invalid parameters have been passed to the service."
    Case 22
      strError = "The account which this service is to run under is either invalid or lacks the permissions to run the service."
    Case 23
      strError = "The service exists in the database of services available from the system."
    Case 24
      strError = "The service is currently paused in the system."
    Case Else
      strError = "Unknown"
  End Select

  If strError = "Unknown" Then
    'Call procedure to attempt to determine the error using SWbemLastError
    Call WMI_Error_Display()
  ElseIf bHasError = true Then
    LogError "     " & strError
  Else
    LogMessage " CODE#" & intError & ": " & strError
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
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

  On Error Resume Next
  Dim objWMI_Error
  'Instantiate reference to the SWbemLastError object.
  Set objWMI_Error = CreateObject("WbemScripting.SWbemLastError")

  'Error check
  If (Err.Number = 0) And IsObject(objWMI_Error) Then
    LogError " Operation    : " &  objWMI_Error.Operation & VbCrLf & _
             " ParameterInfo: " &  objWMI_Error.ParameterInfo & VbCrLf & _
             " ProviderName : " &  objWMI_Error.ProviderName

    Set objWMI_Error = Nothing
  Else
    LogError "      !Could not retrieve 'SWbemLastError'."
  End If
  Err.Clear

End Sub

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Name:    LogMessage
' Purpose: To write text to screen
' Inputs:  strMessage
' Outputs: Nothing
' Notes:   Expand this procedure to write output to file or other destination
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Private Sub LogMessage(strMessage)
  On Error Resume Next
  If IsObject(objFile_Log) Then
    objFile_Log.WriteLine strMessage
  End If
  If bIsDebug = true Then
    WScript.Echo strMessage
  End If
End Sub

Private Sub LogError(strErrMsg)
  bHasError = true
  If bIsWScript = true Then
    WScript.Echo strErrMsg
  Else
    WScript.StdErr.WriteLine strErrMsg
  End If
  If IsObject(objFile_Log) Then
    objFile_Log.WriteLine strErrMsg
  End If
End Sub

Private Sub ShowMessage(strMessage)
  If IsObject(objFile_Log) Then
    objFile_Log.WriteLine strMessage
  End If
  WScript.Echo strMessage
End Sub

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Name:    WMI_Ping
' Purpose: To determine if a system is online or offline
' Inputs:  strComputer
' Outputs: True  - The specified system is Online
'          False - The specified system is Offline
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Private Function WMI_Ping(strComputer)
  On Error Resume Next
  
  Dim objWMIService
  Dim colPings
  Dim objStatus

  'Set default function return value
  WMI_Ping = True

  'The local computer was specified..exit
  If strComputer = "." Then Exit Function

  'Is there a reference to the local WMI service?
  If Not IsObject(objWMIService) Then
    'Instantiate a reference to the local WMI service
    Set objWMIService = GetObject("winmgmts:" & _
                                  "{impersonationLevel=impersonate}!" & _
                                  "\\.\Root\CimV2")
    
    'Error check
    If (Err.Number <> 0) And Not IsObject(objWMIService) Then
      LogMessage "  Error connecting to WMI for ping testing."
      LogMessage "    Number (dec) : "   & Err.Number & VbCrLf & _
               "    Number (hex) : &H" & Hex(Err.Number) & VbCrLf & _
               "    Description  : "   & Err.Description & VbCrLf & _
               "    Source       : "   & Err.Source

      'Lookup WMI errors
      Call WMI_Services_Error_Lookup(Err.Number)
    End If
  End If

  'Instantiate a reference to the WMI Ping provider
  Err.Clear
  Set colPings = objWMIService.ExecQuery("Select * From Win32_PingStatus1 " & _
                                         "Where Address = '" & strComputer & "'")
  
  'Error check
  If (Err.Number = 0) And IsObject(colPings) Then
    'Loop through the results
    For Each objStatus in colPings
      If IsNull(objStatus.StatusCode) Or (objStatus.StatusCode <> 0) Then
        'Set the function return value to False
        WMI_Ping = False
      'ElseIf objStatus.StatusCode = 0 Then
      '  WMI_Ping = True
      End If
    Next

    Set colPings = Nothing
  Else
    'Output error details
    LogMessage "  Error trying to ping " & strComputer
    LogMessage "    Number (dec) : "   & Err.Number & VbCrLf & _
             "    Number (hex) : &H" & Hex(Err.Number) & VbCrLf & _
             "    Description  : "   & Err.Description & VbCrLf & _
             "    Source       : "   & Err.Source

    'Lookup WMI errors
    Call WMI_Services_Error_Lookup(Err.Number)
  End If

End Function
