@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: バッチ処理
set "mode=%~1"
if /i "%mode%"=="up" (
    set "wheel=120"
) else if /i "%mode%"=="down" (
    set "wheel=-120"
) else (
    echo [ERROR] Usage: call ResizeFont.bat up^|down
    exit /b 1
)

:: 自分自身を文字列で読み込んでPowerShellへ渡す
powershell -NoProfile -ExecutionPolicy Bypass -Command "$code = Get-Content -Raw -Path '%~f0'; iex ($code -split '#<\#\s*: begin PowerShell block')[1]"

exit /b

#<: begin PowerShell block
param (
    [int]$wheel = %wheel%
)

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class InputSim {
    [DllImport("user32.dll")] public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);
    [DllImport("user32.dll")] public static extern void mouse_event(uint dwFlags, int dx, int dy, int dwData, UIntPtr dwExtraInfo);
    public const int KEYEVENTF_KEYDOWN = 0x0000;
    public const int KEYEVENTF_KEYUP = 0x0002;
    public const int MOUSEEVENTF_WHEEL = 0x0800;
    public const byte VK_CONTROL = 0x11;
}
"@

# Ctrl押下
[InputSim]::keybd_event([InputSim]::VK_CONTROL, 0, 0x0000, [UIntPtr]::Zero)
Start-Sleep -Milliseconds 100

# ホイール回転
[InputSim]::mouse_event(0x0800, 0, 0, $wheel, [UIntPtr]::Zero)
Start-Sleep -Milliseconds 100

# Ctrl離す
[InputSim]::keybd_event([InputSim]::VK_CONTROL, 0, 0x0002, [UIntPtr]::Zero)
