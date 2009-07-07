On Error Resume Next
' PostgreSQL server module load script for Windows
' Dave Page, EnterpriseDB

Const ForReading = 1
Const ForWriting = 2

' Check the command line
If WScript.Arguments.Count <> 6 Then
 Wscript.Echo "Usage: loadmodules.vbs <Username> <Password> <Install dir> <Data dir> <Port> <install_plpgsql>"
 Wscript.Quit 127
End If

strUsername = WScript.Arguments.Item(0)
strPassword = WScript.Arguments.Item(1)
strInstallDir = WScript.Arguments.Item(2)
strDataDir = WScript.Arguments.Item(3)
iPort = WScript.Arguments.Item(4)
strInstallPlPgsql = WScript.Arguments.Item(5)

'Escape the '%' as '%%', if present in the password
Set regExp = new regexp
regExp.Pattern = "[%]"
strFormattedPassword = regExp.Replace(strPassword, "%%")

iWarn = 0

' Get a temporary filenames
Set objShell = WScript.CreateObject("WScript.Shell")
Set objFso = CreateObject("Scripting.FileSystemObject")
Set objTempFolder = objFso.GetSpecialFolder(2)
strBatchFile = Replace(objFso.GetTempName, ".tmp", ".bat")
strOutputFile = objTempFolder.Path & "\" & objFso.GetTempName

' Execute a command. Note that we use Shell.Run here to prevent spawning DOS boxes.
' Unfortunately that means we have to hack things about to get the command output
Function DoCmd(strCmd)
    Set objBatchFile = objTempFolder.CreateTextFile(strBatchFile, True)
    objBatchFile.WriteLine "@ECHO OFF"
    objBatchFile.WriteLine "SET PGPASSWORD=" & strFormattedPassword
    objBatchFile.WriteLine strCmd & " > """ & strOutputFile & """ 2>&1"
    objBatchFile.WriteLine "SET PGPASSWORD="
	objBatchFile.WriteLine "EXIT /B %ERRORLEVEL%"
    objBatchFile.Close
    DoCmd = objShell.Run(objTempFolder.Path & "\" & strBatchFile, 0, True)
    If objFso.FileExists(objTempFolder.Path & "\" & strBatchFile) = True Then
        objFso.DeleteFile objTempFolder.Path & "\" & strBatchFile, True
    End If
    If objFso.FileExists(strOutputFile) = True Then
        Set objOutputFile = objFso.OpenTextFile(strOutputFile, ForReading)
        WScript.Echo objOutputFile.ReadAll
        objOutputFile.Close
        objFso.DeleteFile strOutputFile, True
    End If
End Function

Sub Warn(msg)
    WScript.Echo msg
    iWarn = 2
End Sub

if strInstallPlPgsql = "1" Then
    ' Create the plpgsql language
    WScript.Echo "Installing pl/pgsql in the template1 databases..."
    iRet = DoCmd("""" & strInstallDir & "\bin\psql.exe"" -p " & iPort & " -U " & strUsername & " -c ""CREATE LANGUAGE plpgsql;"" template1")
    if iRet <> 0 Then warn "Failed to install pl/pgsql in the 'template1' database"
End if

' Install adminpack in the postgres database
WScript.Echo "Installing the adminpack module in the postgres database..."
iRet = DoCmd("""" & strInstallDir & "\bin\psql.exe"" -p " & iPort & " -U " & strUsername & " -f """ & strInstallDir & "\share\contrib\adminpack.sql"" postgres")
if iRet <> 0 Then warn "Failed to install the 'adminpack' module in the 'postgres' database"

' All done!!
WScript.Echo "loadmodules.vbs ran to completion"
WScript.Quit iWarn

