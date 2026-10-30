@echo off
if not exist "G:\Codex\tools\Godot-4.7.2\Godot_v4.7.2-stable_win64.exe" goto missing
start "" "G:\Codex\tools\Godot-4.7.2\Godot_v4.7.2-stable_win64.exe" --path "%~dp0"
exit /b 0
:missing
echo Godot executable was not found at G:\Codex\tools\Godot-4.7.2
pause
exit /b 1
