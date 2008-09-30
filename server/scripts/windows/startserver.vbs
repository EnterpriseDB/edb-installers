On Error Resume Next

' PostgreSQL server startup script for Windows
' Dave Page, EnterpriseDB

' Check the command line
If WScript.Arguments.Count <> 1 Then
 Wscript.Echo "Usage: startserver.vbs <Major.Minor version>"
 Wscript.Quit 127
End If

strVersion = WScript.Arguments.Item(0)

lServices = 0

Set objWMIService = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2")

' Find any service we require
Set colServiceList = objWMIService.ExecQuery("Associators of {Win32_Service.Name='postgresql-" & strVersion & "'} Where AssocClass=Win32_DependentService Role=Dependent")

' Start the dependencies
For Each objService in colServiceList
    If objService.State <> "Running" Then
        WScript.Echo "Starting " & objService.Name
        iRetval = objService.StartService()
        If iRetval = 0 Then
            WScript.Echo "Parent service " & objService.Name & " started successfully"
        Else
            WScript.Echo "Parent service " & objService.Name & " did not start (" & iRetVal & ")"
        End If
    End If
Next

' Find the service
Set objService = objWMIService.Get("Win32_Service.Name='postgresql-" & strVersion & "'")

' Start it (them)
If objService.State <> "Running" Then
    WScript.Echo "Starting " & objService.Name
    iRetval = objService.StartService()
    If iRetval = 0 Then
        WScript.Echo "Service " & objService.Name & " started successfully"
    Else
        WScript.Echo "Failed to start the database server (" & iRetVal & ")"
        WScript.Quit 1
    End If
Else
    WScript.Echo "Service " & objService.Name & " is already running"
End If

WScript.Echo "startserver.vbs ran to completion"
WScript.Quit 0

