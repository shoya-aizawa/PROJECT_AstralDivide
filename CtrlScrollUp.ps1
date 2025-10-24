Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class InputSimulator {
  [DllImport("user32.dll")]
  public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);

  [DllImport("user32.dll")]
  public static extern void mouse_event(uint dwFlags, int dx, int dy, int dwData, UIntPtr dwExtraInfo);

  public const int KEYEVENTF_KEYDOWN = 0x0000;
  public const int KEYEVENTF_KEYUP   = 0x0002;

  public const int MOUSEEVENTF_WHEEL = 0x0800;
  public const byte VK_CONTROL       = 0x11;
}
"@

# Ctrl押下
[InputSimulator]::keybd_event([InputSimulator]::VK_CONTROL, 0, [InputSimulator]::KEYEVENTF_KEYDOWN, [UIntPtr]::Zero)
Start-Sleep -Milliseconds 100

# マウスホイールアップ（dwData = +120）
[InputSimulator]::mouse_event([InputSimulator]::MOUSEEVENTF_WHEEL, 0, 0, +120, [UIntPtr]::Zero)
Start-Sleep -Milliseconds 100

# Ctrl離す
[InputSimulator]::keybd_event([InputSimulator]::VK_CONTROL, 0, [InputSimulator]::KEYEVENTF_KEYUP, [UIntPtr]::Zero)
