Option Explicit
Dim shell, files, folder, runtime, result
Set shell = CreateObject("WScript.Shell")
Set files = CreateObject("Scripting.FileSystemObject")
folder = files.GetParentFolderName(WScript.ScriptFullName)
shell.CurrentDirectory = folder
runtime = "py -3"
On Error Resume Next
result = shell.Run(runtime & " -c " & Chr(34) & "import sys" & Chr(34), 0, True)
If Err.Number <> 0 Or result <> 0 Then
    Err.Clear
    runtime = "python"
    result = shell.Run(runtime & " -c " & Chr(34) & "import sys" & Chr(34), 0, True)
    If Err.Number <> 0 Or result <> 0 Then WScript.Quit 1
End If
On Error GoTo 0
shell.Run runtime & " -u " & Chr(34) & folder & "\relay_metadata.py" & Chr(34) & " --managed", 0, False
