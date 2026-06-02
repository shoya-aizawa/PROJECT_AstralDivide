@echo off
::------------------------------------------------------------------------------
:: Splash.RemoteState.bat
::------------------------------------------------------------------------------
if not "%REMOTE_MODE%"=="1" exit /b 0

:: Trigger the Connection Portal at 40% progress
if "!pct!"=="40" (
    if not defined REMOTE_LOGGED_IN (
        :: Import temporary environment validation cache to the parent shell
        if exist "%TEMP%\ad_boot_diag_result.env" (
            for /f "usebackq eol=# tokens=1,2 delims==" %%A in (`type "%TEMP%\ad_boot_diag_result.env" 2^>nul`) do (
                set "%%A=%%B"
            )
            del "%TEMP%\ad_boot_diag_result.env" >nul 2>&1
        )
        call "%PROJECT_ROOT%\Src\Systems\Launcher\Wizards\RemoteLoginWizard.bat"
        set "REMOTE_LOGGED_IN=1"
        set "remote_timeout_frames=0"
    )
)

if "!state!"=="0" (
    if defined REMOTE_LOGGED_IN (
        if not defined REMOTE_TOKEN (
            set /a "poll_tick=frame %% 10"
            if "!poll_tick!"=="0" (
                set "POLL_status="
                set "POLL_token="
                for /f "usebackq eol=# tokens=1,2 delims==" %%A in (`powershell -NoProfile -ExecutionPolicy Bypass -File "%TEMP%\ad_poll.ps1"`) do (
                    set "POLL_%%A=%%B"
                )
                
                if "!POLL_status!"=="APPROVED" (
                    if defined POLL_token (
                        if defined RCSU call "%RCSU%" -trace INFO "Splash/Remote" "Remote connection request approved by admin. Launching log streamer."
                        del "%TEMP%\ad_poll.ps1" >nul 2>&1
                        set "REMOTE_TOKEN=!POLL_token!"
                        (
                            echo REMOTE_TOKEN=!POLL_token!
                            echo REMOTE_STREAMER_STARTED=1
                        ) > "%TEMP%\remote_session.env"
                        
                        :: Ensure the log directory and log file exist before tail starts
                        for %%D in ("!logfile!") do (
                            if not exist "%%~dpD" md "%%~dpD" >nul 2>&1
                        )
                        if not exist "!logfile!" type nul > "!logfile!" 2>nul
                        
                        :: Start background remote log streamer immediately upon approval
                        start "AstralDivide - Log Streamer" /b powershell -NoProfile -ExecutionPolicy Bypass -File "%PROJECT_ROOT%\Src\Systems\Debug\LogTailToGAS.ps1" -LogPath "!logfile!" -GasUrl "%REMOTE_GAS_URL%" -ClientName "%USERNAME%@%COMPUTERNAME%" -SessionToken "!POLL_token!" > "%PROJECT_ROOT%\Config\Logs\ad_streamer.log" 2>&1
                        if exist "%PLAY_SE%" call "%PLAY_SE%" "%SE_ENTER3%"
                        
                        :: Render connection established UI frame
                        echo !esc![2J
                        call "%PROJECT_ROOT%\Src\Systems\Launcher\Splash.Border.bat"
                        echo !esc![10;22H!esc![92m[SUCCESS] Connection Established successfully!C_RESET!
                        echo !esc![12;22H!C_TEXT!開発者による接続が承認されました。ロードを再開します。!C_RESET!
                        timeout /t 2 >nul
                    )
                )
                if "!POLL_status!"=="DENIED" (
                    if defined RCSU call "%RCSU%" -trace WARN "Splash/Remote" "Remote connection request denied by admin."
                    del "%TEMP%\ad_poll.ps1" >nul 2>&1
                    if exist "%PLAY_SE%" call "%PLAY_SE%" "%SE_CANCEL%"
                    echo !esc![2J
                    call "%PROJECT_ROOT%\Src\Systems\Launcher\Splash.Border.bat"
                    echo !esc![10;22H!esc![91m[DENIED] Connection request denied by admin.!C_RESET!
                    echo !esc![12;22H!C_TEXT!リモート接続申請が管理者によって拒否されました。!C_RESET!
                    echo !esc![15;22H!C_TEXT!Press any key to exit...!C_RESET!
                    pause >nul
                    exit /b 1
                )
            )
            
            :: Timeout check (600 frames = ~60 seconds)
            set /a "remote_timeout_frames+=1"
            if !remote_timeout_frames! GEQ 600 (
                if defined RCSU call "%RCSU%" -trace WARN "Splash/Remote" "Connection approval timed out after 60 seconds."
                del "%TEMP%\ad_poll.ps1" >nul 2>&1
                if exist "%PLAY_SE%" call "%PLAY_SE%" "%SE_CANCEL%"
                echo !esc![2J
                call "%PROJECT_ROOT%\Src\Systems\Launcher\Splash.Border.bat"
                echo !esc![10;24H!esc![91m[TIMEOUT] Connection request timed out.!C_RESET!
                echo !esc![12;22H!C_TEXT!承認待ちの制限時間（60秒）を超過しました。!C_RESET!
                echo !esc![15;22H!C_TEXT!Press any key to exit...!C_RESET!
                pause >nul
                exit /b 2
            )
            
            :: Force values to halt progress visually at 40%
            set "pct=40"
        )
    )
)
exit /b 0
