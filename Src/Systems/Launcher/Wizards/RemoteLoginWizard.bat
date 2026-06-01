@echo off
::------------------------------------------------------------------------------
:: RemoteLoginWizard.bat
::------------------------------------------------------------------------------
if defined RCSU call "%RCSU%" -trace INFO "Splash/Remote" "Remote Connection Portal opened. Prompting user authentication."
:: Redraw outer GUI frame
echo !esc![2J
call "%PROJECT_ROOT%\Src\Systems\Launcher\Splash.Border.bat"

:: Render setup screen text
echo !esc![5;21H!C_TEXT!Remote Connection Portal  /  リモート接続!C_RESET!
call "%PROJECT_ROOT%\Src\Systems\Launcher\Splash.Border.bat" Separator 6

:: Create helper scripts to avoid CMD backtick parsing crashes
set "helper_hash=%TEMP%\ad_mask_hash.ps1"
echo param([string]$OutPath)> "%helper_hash%"
echo [Console]::Write("$([char]27)[15;12H")>> "%helper_hash%"
echo $password = "">> "%helper_hash%"
echo while ($true) {>> "%helper_hash%"
echo     $key = [System.Console]::ReadKey($true)>> "%helper_hash%"
echo     if ($key.Key -eq [System.ConsoleKey]::Enter) { break }>> "%helper_hash%"
echo     if ($key.Key -eq [System.ConsoleKey]::Backspace) {>> "%helper_hash%"
echo         if ($password.Length -gt 0) {>> "%helper_hash%"
echo             $password = $password.Substring(0, $password.Length - 1)>> "%helper_hash%"
echo             [Console]::Write("$([char]8) $([char]8)")>> "%helper_hash%"
echo         }>> "%helper_hash%"
echo     } else {>> "%helper_hash%"
echo         if ($key.KeyChar -ne [char]0) {>> "%helper_hash%"
echo             $password += $key.KeyChar>> "%helper_hash%"
echo             [Console]::Write("*")>> "%helper_hash%"
echo         }>> "%helper_hash%"
echo     }>> "%helper_hash%"
echo }>> "%helper_hash%"
echo if ($password.Trim() -eq '') { exit 1 }>> "%helper_hash%"
echo $sha = [System.Security.Cryptography.SHA256]::Create()>> "%helper_hash%"
echo $bytes = [System.Text.Encoding]::UTF8.GetBytes($password)>> "%helper_hash%"
echo $hash = $sha.ComputeHash($bytes)>> "%helper_hash%"
echo $hex = ($hash ^| ForEach-Object { $_.ToString('x2') }) -join ''>> "%helper_hash%"
echo [System.IO.File]::WriteAllText($OutPath, $hex)>> "%helper_hash%"

set "helper_join=%TEMP%\ad_join.ps1"
echo $body = @{> "%helper_join%"
echo   action = 'request_join'>> "%helper_join%"
echo   user_id = $env:REMOTE_USER>> "%helper_join%"
echo   pass_hash = $env:REMOTE_PASS_HASH>> "%helper_join%"
echo   host = "$env:USERNAME@$env:COMPUTERNAME">> "%helper_join%"
echo }>> "%helper_join%"
echo try {>> "%helper_join%"
echo   $res = Invoke-RestMethod -Uri $env:REMOTE_GAS_URL -Method POST -Body $body -ContentType 'application/x-www-form-urlencoded; charset=utf-8'>> "%helper_join%"
echo   if ($res.ok) {>> "%helper_join%"
echo     Write-Output "ok=1">> "%helper_join%"
echo     Write-Output "req_id=$($res.req_id)">> "%helper_join%"
echo   } else {>> "%helper_join%"
echo     Write-Output "ok=0">> "%helper_join%"
echo     Write-Output "reason=$($res.reason)">> "%helper_join%"
echo   }>> "%helper_join%"
echo } catch {>> "%helper_join%"
echo   Write-Output "ok=0">> "%helper_join%"
echo   Write-Output "reason=$($_.Exception.Message)">> "%helper_join%"
echo }>> "%helper_join%"

set "helper_poll=%TEMP%\ad_poll.ps1"
echo try {> "%helper_poll%"
echo   $url = "$($env:REMOTE_GAS_URL)?action=join_status&req_id=$($env:REQ_req_id)">> "%helper_poll%"
echo   $res = Invoke-RestMethod -Uri $url -Method GET>> "%helper_poll%"
echo   if ($res.ok) {>> "%helper_poll%"
echo     Write-Output "status=$($res.status)">> "%helper_poll%"
echo     if ($res.status -eq 'APPROVED') {>> "%helper_poll%"
echo       Write-Output "token=$($res.session_token)">> "%helper_poll%"
echo     }>> "%helper_poll%"
echo   } else {>> "%helper_poll%"
echo     Write-Output "status=ERROR">> "%helper_poll%"
echo   }>> "%helper_poll%"
echo } catch {>> "%helper_poll%"
echo   Write-Output "status=ERROR">> "%helper_poll%"
echo }>> "%helper_poll%"

:InputUserLoop
echo !esc![9;10H!esc![K!C_TEXT!Enter User ID / デバッガーIDを入力してください:!C_RESET!
echo !esc![11;10H!esc![K!C_RESET!
set "REMOTE_USER="
set /p "REMOTE_USER=!esc![11;10H!C_TEXT!^> !C_RESET!"
if not defined REMOTE_USER (
    del "%helper_hash%" "%helper_join%" "%helper_poll%" >nul 2>&1
    goto InputUserLoop
)
if exist "%PLAY_SE%" call "%PLAY_SE%" "%SE_ENTER%"

:InputPassLoop
echo !esc![13;10H!esc![K!C_TEXT!Enter Password / パスワードを入力してください (非表示):!C_RESET!
echo !esc![15;10H!esc![K!C_RESET!
echo !esc![15;10H!C_TEXT!^> !C_RESET!

set "REMOTE_PASS_HASH="
set "hash_out=%TEMP%\ad_pass_hash.tmp"
if exist "!hash_out!" del "!hash_out!" >nul 2>&1

:: Execute synchronously - stdin/stdout are not redirected, so ReadKey works perfectly in conhost!
powershell -NoProfile -ExecutionPolicy Bypass -File "%helper_hash%" "!hash_out!"

:: Read the resulting hash from the temporary file
if exist "!hash_out!" (
    for /f "usebackq delims=" %%H in ("!hash_out!") do (
        set "REMOTE_PASS_HASH=%%H"
    )
    del "!hash_out!" >nul 2>&1
)
if not defined REMOTE_PASS_HASH goto InputPassLoop
if exist "%PLAY_SE%" call "%PLAY_SE%" "%SE_ENTER%"

:: Request join connection
if defined RCSU call "%RCSU%" -trace INFO "Splash/Remote" "Sending connection request to GAS for user: !REMOTE_USER!"
echo !esc![18;10H!esc![K!esc![93mConnecting to developer / 開発者へ接続中...!C_RESET!

set "REQ_ok="
set "REQ_req_id="
set "REQ_reason="
for /f "usebackq tokens=1,2 delims==" %%A in (`powershell -NoProfile -ExecutionPolicy Bypass -File "%helper_join%"`) do (
    set "REQ_%%A=%%B"
)

:: Clean up password and hashing scripts immediately for security
del "%helper_hash%" "%helper_join%" >nul 2>&1

if not "!REQ_ok!"=="1" (
    if defined RCSU call "%RCSU%" -trace ERR "Splash/Remote" "Connection request failed. Reason: !REQ_reason!"
    del "%helper_poll%" >nul 2>&1
    if exist "%PLAY_SE%" call "%PLAY_SE%" "%SE_CANCEL%"
    echo !esc![18;10H!esc![K!esc![91m[ERROR] Connection failed: !REQ_reason!!C_RESET!
    echo !esc![20;10H!C_TEXT!接続要求が失敗しました。ID/PWやネット環境をご確認ください。!C_RESET!
    echo !esc![22;10H!C_TEXT!Press any key to exit...!C_RESET!
    pause >nul
    exit /b 1
)

:: Clear the screen inside the border to return to twinkling background
if defined RCSU call "%RCSU%" -trace INFO "Splash/Remote" "Connection request accepted. Request ID: !REQ_req_id!. Waiting for approval."
echo !esc![2J
call "%PROJECT_ROOT%\Src\Systems\Launcher\Splash.Border.bat"
exit /b
