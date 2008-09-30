On Error Resume Next

' PostgreSQL server shortcut creation script for Windows
' Dave Page, EnterpriseDB

' Note that on Windows, the shortcuts themselves are created by the installer,
' we just hack up the various helper scripts here.

Const ForReading = 1
Const ForWriting = 2

' Check the command line
If WScript.Arguments.Count <> 5 Then
 Wscript.Echo "Usage: createshortcuts.vbs <Major.Minor version> <Username> <Port> <Install dir> <Data dir>"
 Wscript.Quit 127
End If

strVersion = WScript.Arguments.Item(0)
strUsername = WScript.Arguments.Item(1)
iPort = CInt(WScript.Arguments.Item(2))
strInstallDir = WScript.Arguments.Item(3)
strDataDir = WScript.Arguments.Item(4)

Set objShell = WScript.CreateObject("WScript.Shell")
Set objFso = WScript.CreateObject("Scripting.FileSystemObject")

' Substitute values into a file ($in)
Sub FixupFile(strFile)
    Set objFile = objFso.OpenTextFile(strFile, ForReading)
    strData = objFile.ReadAll
    objFile.Close

    strData = Replace(strData, "PG_MAJOR_VERSION", strVersion)
    strData = Replace(strData, "PG_USERNAME", strUsername)
    strData = Replace(strData, "PG_PORT", iPort)
    strData = Replace(strData, "PG_INSTALLDIR", strInstallDir)
    strData = Replace(strData, "PG_DATADIR", strDataDir)

    Set objFile = objFso.OpenTextFile(strFile, ForWriting)
    objFile.WriteLine strData
    objFile.Close
End Sub

' Fixup the scripts
FixupFile strInstallDir & "\scripts\serverctl.vbs"
FixupFile strInstallDir & "\scripts\runpsql.bat"

WScript.Echo "createshortcuts.vbs ran to completion"
WScript.Quit 0

