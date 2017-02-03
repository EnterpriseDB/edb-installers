' Copyright (c) 2012-2017, EnterpriseDB Corporation.  All rights reserved
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' launch the Update Monitoring Agent script

Option Explicit
On Error Resume Next

Dim shellApp, strUpdateMonitorPath, strArgs

strUpdateMonitorPath = "INSTALL_DIR\bin\UpdManager.exe"
strArgs = " --execute ""STACKBUILDER_DIR\bin\stackbuilder.exe"""

Set shellApp = WScript.CreateObject( "Shell.Application" )
shellApp.ShellExecute strUpdateMonitorPath, strArgs, "", "open", 0

