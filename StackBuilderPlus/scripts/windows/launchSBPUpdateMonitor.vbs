' Copyright (c) 2012-2014, EnterpriseDB Corporation.  All rights reserved
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' launch the Stack-Builder Plus Monitoring Agent script

Option Explicit
On Error Resume Next

Dim shellApp, strUpdateMonitorPath, strArgs

strUpdateMonitorPath = "INSTALL_DIR\bin\UpdManager.exe"
strArgs = " --execute ""INSTALL_DIR\bin\stackbuilderplus.exe"""

Set shellApp = WScript.CreateObject( "Shell.Application" )
shellApp.ShellExecute strUpdateMonitorPath, strArgs, "", "open", 0

