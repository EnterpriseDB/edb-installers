' System/Properties/Advanced/Environment Variables/User variables


'Start of Script
'VBRUNAS.VBS
'v1.2 March 2001
'Jeffery Hicks
'jhicks@quilogy.com http://www.quilogy.com
'USAGE: cscript|wscript VBRUNAS.VBS Username Password Command
'DESC: A RUNAS replacement to take password at a command prompt.
'NOTES: This is meant to be used for local access. If you want to run a command
'across the network as another user, you must add the /NETONLY switch to the RUNAS
'command.

' *********************************************************************************
' * THIS PROGRAM IS OFFERED AS IS AND MAY BE FREELY MODIFIED OR ALTERED AS *
' * NECESSARY TO MEET YOUR NEEDS. THE AUTHOR MAKES NO GUARANTEES OR WARRANTIES, *
' * EXPRESS, IMPLIED OR OF ANY OTHER KIND TO THIS CODE OR ANY USER MODIFICATIONS. *
' * DO NOT USE IN A PRODUCTION ENVIRONMENT UNTIL YOU HAVE TESTED IN A SECURED LAB *
' * ENVIRONMENT. USE AT YOUR OWN RISK. *
' *********************************************************************************

On Error Resume Next
dim WshShell,oArgs,FSO

set oArgs=wscript.Arguments

if InStr(oArgs(0),"?")<>0 then
wscript.echo VBCRLF & "? HELP ?" & VBCRLF
Usage
end if

if oArgs.Count <3 then
wscript.echo VBCRLF & "! Usage Error !" & VBCRLF
Usage
end if

sUser=oArgs(0)
sPass=oArgs(1)&VBCRLF
sCmd=oArgs(2)

set WshShell = CreateObject("WScript.Shell")
set WshEnv = WshShell.Environment("Process")
WinPath = WshEnv("SystemRoot")&"\System32\runas.exe"
set FSO = CreateObject("Scripting.FileSystemObject")

if FSO.FileExists(winpath) then
'wscript.echo winpath & " " & "verified"
else
wscript.echo "!! ERROR !!" & VBCRLF & "Can't find or verify " & winpath &"." & VBCRLF & "You must be running Windows 2000 for this script to work."
set WshShell=Nothing
set WshEnv=Nothing
set oArgs=Nothing
set FSO=Nothing
wscript.quit
end if

rc=WshShell.Run("runas /user:" & sUser & " " & CHR(34) & sCmd & CHR(34), 2, FALSE)

DO WHILE WshShell.AppActivate(WinPath) = 0
    Wscript.Sleep 10 'need to give time for window to open.
LOOP
WshShell.SendKeys sPass 'send the password to the waiting window.

set WshShell=Nothing
set oArgs=Nothing
set WshEnv=Nothing
set FSO=Nothing

wscript.quit

'************************
'* Usage Subroutine *
'************************
Sub Usage()
On Error Resume Next
msg="Usage: cscript|wscript vbrunas.vbs Username Password Command" & VBCRLF & VBCRLF & "You should use the full path where necessary and put long file names or commands" & VBCRLF & "with parameters in quotes"

wscript.echo msg

wscript.quit

end sub
'End of Script 
