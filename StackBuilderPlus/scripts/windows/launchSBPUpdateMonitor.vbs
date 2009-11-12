''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' launch the Stack-Builder Plus Monitoring Agent script
' Ashesh Vashi, EnterpriseDB

Option Explicit
On Error Resume Next

Dim shellApp, strUpdateMonitorPath, strArgs

strUpdateMonitorPath = "INSTALL_DIR\bin\UpdManager.exe"
strArgs = " --server MONITOR_SERVER --execute ""INSTALL_DIR\bin\stackbuilderplus.exe"""

Set shellApp = WScript.CreateObject( "Shell.Application" )
shellApp.ShellExecute strUpdateMonitorPath, strArgs, "", "open", 0

