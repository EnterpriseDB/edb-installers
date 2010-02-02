Dim FSO, WSO, WshShell

CONST L_CONST_TIMEOUT = 10000
SET WshShell = CreateObject("WScript.Shell")
SET WSO      = WScript.StdOut
SET WSE      = WScript.StdErr

Sub RunProgram(ByVal p_strCmd, ByRef p_aCmdArgs, ByRef pl_iStatusCode)
  Dim lExec
  Dim l_iLArgs, l_iUArgs, l_strCmdArgs, l_strStdOut, l_strStdErr
  l_strStdOut   = ""
  l_strStdErr   = ""
  pl_iStatusCode = 0

  If p_strCmd = NULL OR Trim(p_strCmd) = "" Then
    WSE.WriteLine "RunProgram : Provide command to execute."
    WScript.Quit -127
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
  p_strCmd = Trim( """" & p_strCmd & """ " & Trim(l_strCmdArgs))

  WSO.WriteLine "RunProgram: " & p_strCmd

  Set lExec = WshShell.Exec(p_strCmd)

  l_iWaitCount = 0
  WSO.WriteLine "Script Output: " & vbCRLF & _
                "---------------"
  Do
    WScript.Sleep 100
    l_iWaitCount = l_iWaitCount + 1
    If lExec.StdOut.AtEndOfStream <> True Then
      WSO.WriteLine lExec.StdOut.ReadLine
      l_strStdOut = l_strStdOut & vbCRLF & lExec.StdOut.ReadLine
    End If

  Loop Until lExec.Status <> 0 OR l_iWaitCount >= L_CONST_TIMEOUT

  l_bTerminateAbnormally = false
  If l_iWaitCount >= L_CONST_TIMEOUT AND lExec.Status = 0 Then
    lExec.Terminate()
    l_bTerminateAbnormally = true
  End If

  pl_iStatusCode = lExec.ExitCode
  Do While lExec.StdOut.AtEndOfStream <> True
    WSO.WriteLine lExec.StdOut.ReadLine
  Loop

  Do While lExec.StdErr.AtEndOfStream <> True
    l_strStdErr = l_strStdErr & vbCRLF & lExec.StdErr.ReadLine
  Loop

  WSE.WriteLine vbCRLF & "Script Error : " & _
           vbCRLF & "---------------" & _
           l_strStdErr
  If l_bTerminateAbnormally Then
    WSE.WriteLine "Couldn't complete execution of the command (" & p_strCmd & ")"
  End If
End Sub

If WScript.Arguments.Count < 1 Then
    WSE.Echo "Please Provide the program to run..."
    WScript.Quit -127
End If

Dim strCmdLine, iIndex, arrCmdArgs(), iStatus
strCmdLine = WScript.Arguments.Item(0)

For iIndex = 1 To WScript.Arguments.Count - 1
  ReDim arrCmdArgs(iIndex - 1)
  arrCmdArgs(iIndex - 1) = WScript.Arguments.Item(iIndex)
Next

Call RunProgram(strCmdLine, arrCmdArgs, iStatus)

WScript.Quit iStatus
