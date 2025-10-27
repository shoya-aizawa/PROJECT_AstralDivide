# フォント変更用のWin32 API呼び出し
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class ConsoleFont {
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr GetStdHandle(int nStdHandle);

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern bool SetCurrentConsoleFontEx(
        IntPtr consoleOutput,
        bool maximumWindow,
        ref CONSOLE_FONT_INFOEX lpConsoleCurrentFontEx);

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct CONSOLE_FONT_INFOEX {
        public uint cbSize;
        public uint nFont;
        public SHORT_COORD dwFontSize;
        public int FontFamily;
        public int FontWeight;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string FaceName;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct SHORT_COORD {
        public short X;
        public short Y;
    }
}
"@

# フォント設定を変更する関数
function Set-ConsoleFont {
    param(
        [string]$FontName = "Consolas",
        [int]$FontSize = 16
    )

    $handle = [ConsoleFont]::GetStdHandle(-11) # STD_OUTPUT_HANDLE
    $fontInfo = New-Object ConsoleFont+CONSOLE_FONT_INFOEX
    $fontInfo.cbSize = [System.Runtime.InteropServices.Marshal]::SizeOf($fontInfo)
    $fontInfo.FaceName = $FontName
    $fontInfo.dwFontSize = New-Object ConsoleFont+SHORT_COORD
    $fontInfo.dwFontSize.X = 0  # 幅は自動
    $fontInfo.dwFontSize.Y = $FontSize  # 高さを指定

    [ConsoleFont]::SetCurrentConsoleFontEx($handle, $false, [ref]$fontInfo)
}

# フォントを変更（例：Consolas, サイズ16）
Set-ConsoleFont -FontName "Consolas" -FontSize 16