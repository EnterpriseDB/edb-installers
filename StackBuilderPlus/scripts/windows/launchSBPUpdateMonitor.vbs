''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' launch the Stack-Builder Plus Monitoring Agent script
' Ashesh Vashi, EnterpriseDB

Option Explicit
On Error Resume Next

Dim WSHShell, objFSO, shellApp, strRegKey, strServer, strSBPInstallDir, strArch, strUpdateMonitorPath, strArgs
Set WSHShell = CreateObject( "WScript.Shell" )
Set objFSO    = CreateObject("Scripting.FileSystemObject")

strArch = WSHShell.RegRead( "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\PROCESSOR_ARCHITECTURE" )

If strArch = "x86" Then
  strRegKey = "HKEY_LOCAL_MACHINE\SOFTWARE\EnterpriseDB\StackBuilderPlus\"
Else
  strRegKey = "HKEY_LOCAL_MACHINE\SOFTWARE\wow6432node\EnterpriseDB\StackBuilderPlus\"
End If

strServer = WSHShell.RegRead( strRegKey & "MonitorServer" )

' Could not find the location of the UpdateManager
strSBPInstallDir = WSHShell.RegRead( strRegKey & "Location" )

strUpdateMonitorPath = "INSTALL_DIR\bin\UpdateManager.exe"

If IsEmpty( strServer ) Then
  strArgs = "--server " & strServer & " --execute ""INSTALL_DIR\bin\stackbuilderplus.exe"""
Else
  strArgs = "--execute ""INSTALL_DIR\bin\stackbuilderplus.exe """
EndIf

Set shellApp = WScript.CreateObject( "Shell.Application" )
shellApp.ShellExecute strUpdateMonitorPath, strArgs, "", "open", 0

