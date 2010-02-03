Set fso=CreateObject("Scripting.FileSystemObject")

' Is object a file or folder?
If fso.FolderExists(WScript.Arguments(0)) Then
   'It's a folder
   Set objFolder = fso.GetFolder(WScript.Arguments(0))
   WScript.Echo objFolder.ShortPath
End If

If fso.FileExists(WScript.Arguments(0)) Then
   'It's a file
   Set objFile = fso.GetFile(WScript.Arguments(0))
   WScript.Echo objFile.ShortPath
End If
