::    +=================================================================+
::    | edit.bat                                                          |
::    | Shortcut to open layout editor                                    |
::    +=================================================================+

@echo off
@if not "%~0"=="%~dp0.\%~nx0" start cmd /c,"%~dp0.\%~nx0" %* & goto :eof
call "%~dp0Src\Systems\Debug\ScriptLayoutEditor.bat" 2> EDIT.log