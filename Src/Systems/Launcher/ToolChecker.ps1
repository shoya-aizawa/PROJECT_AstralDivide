# ==============================================================================
# ToolChecker.ps1
# Diagnostics utility to verify if external tools are blocked or executable.
# Uses process startup and a 2-second timeout to prevent firewall/antivirus hangs.
# Line endings must be CRLF, Encoding must be UTF-8.
# ==============================================================================

param(
    [string]$ToolsDir = ""
)

# Resolve default Tools directory relative to Launcher directory (..\..\..\Tools)
if ([string]::IsNullOrEmpty($ToolsDir)) {
    $ToolsDir = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "..\..\..\Tools"
}

$ToolsDir = [System.IO.Path]::GetFullPath($ToolsDir)

# Define the target tools and their lightweight arguments for testing
$tools = @{
    "cmdwiz.exe"     = "version"
    "cmdgfx.exe"     = ""
    "cmdgfx_input.exe" = ""
    "cmdbkg.exe"     = ""
    "Insertbmp.exe"  = ""
}

$results = @()

foreach ($t in $tools.Keys) {
    $path = Join-Path $ToolsDir $t
    
    # 1. Static File Existence Check
    if (-not (Test-Path $path)) {
        $results += [PSCustomObject]@{
            Tool    = $t
            Status  = "MISSING"
            TimeMs  = 0
            Message = "File not found in Tools directory"
        }
        continue
    }

    $args = $tools[$t]
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        # Configure process launch options for a silent, background execution
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $path
        $psi.Arguments = $args
        $psi.UseShellExecute = $false
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.CreateNoWindow = $true
        
        $p = [System.Diagnostics.Process]::Start($psi)
        
        # 2. Dynamic Execution with 2-second Timeout
        if (-not $p.WaitForExit(2000)) {
            $p.Kill()
            $sw.Stop()
            $results += [PSCustomObject]@{
                Tool    = $t
                Status  = "TIMEOUT"
                TimeMs  = $sw.ElapsedMilliseconds
                Message = "Blocked by security scan or firewall (Timeout)"
            }
        } else {
            $sw.Stop()
            $exitCode = $p.ExitCode
            
            # Common DLL initialization crash / blocking exit codes
            if ($exitCode -eq -1073741515 -or $exitCode -eq 3221225781) {
                $results += [PSCustomObject]@{
                    Tool    = $t
                    Status  = "ERROR"
                    TimeMs  = $sw.ElapsedMilliseconds
                    Message = "Initialization error (DLL or dependencies missing)"
                }
            } else {
                $results += [PSCustomObject]@{
                    Tool    = $t
                    Status  = "OK"
                    TimeMs  = $sw.ElapsedMilliseconds
                    Message = "Executable responded (ExitCode: $exitCode)"
                }
            }
        }
    } catch {
        # Execution blocked immediately by antivirus or filesystem permissions
        $sw.Stop()
        $results += [PSCustomObject]@{
            Tool    = $t
            Status  = "BLOCKED"
            TimeMs  = 0
            Message = "Execution blocked immediately: $($_.Exception.Message)"
        }
    }
}

# Output format: Tool|Status|TimeMs|Message
foreach ($r in $results) {
    Write-Output "$($r.Tool)|$($r.Status)|$($r.TimeMs)|$($r.Message)"
}
