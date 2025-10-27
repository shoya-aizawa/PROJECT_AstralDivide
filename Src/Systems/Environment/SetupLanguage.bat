@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem ============================================================================
rem SetupLanguage.bat  (RCS-integrated version)
rem Role: Language selection / profile.env synchronization
rem ============================================================================
rem RC MAP:
rem 1-06-90-000 : OK
rem 8-06-01-002 : User canceled
rem 9-06-11-011 : profile.env parse failure
rem 9-06-10-012 : I/O write failure
rem ============================================================================



call "%RCSU%" -trace INFO "%~n0" "setup start"



rem --- Arguments --------------------------------------------------------------
set "ARG_LANG="
set "ARG_AUTO=0"

for %%a in (%*) do (
	set "tok=%%a"
    if /i "!tok!"=="/auto" set "ARG_AUTO=1"
    if /i "!tok:~0,6!"=="/lang=" set "ARG_LANG=!~a:~6!"
)

:: Verify the validity of the value if specified
if defined ARG_LANG (
	if /i not "%ARG_LANG%"=="ja-JP" (
		if /i not "%ARG_LANG%"=="en-US" (
			call "%RCSU%" -throw %RCS_S_ERR% %RCS_D_SYS% %RCS_R_VALID% 013 "invalid /lang" "value=%ARG_LANG%"
			exit /b !errorlevel!
			rem why not use errorlevel? in deep nest cant be used %errorlevel% variable.
		)
	)
	set "LANGUAGE=%ARG_LANG%"
)

:: Defaults to ja-JP if /auto and /lang are not specified.
if "%ARG_AUTO%"=="1" if not defined LANGUAGE set "LANGUAGE=ja-JP"

rem --- Interactive UI (not /auto and no /lang) --------------------------------
if "%ARG_AUTO%"=="0" (
	if not defined ARG_LANG (
		for /f %%a in ('cmd /k prompt $e^<nul') do set "ESC=%%a"
		chcp 65001 >nul
		for /l %%i in (90,-1,40) do (
			mode con cols=%%i lines=35
		)
		for /l %%j in (35,-1,15) do (
			mode con cols=40 lines=%%j
		)

		:UI
		cls
		echo.
		echo. ======================================
		echo. =        Language Setup v0.1a
		echo. ======================================
		echo. = [1] 日本語 (ja-JP)
		echo. = [2] English (en-US)
		echo. = [0] Cancel / キャンセル
		echo. =-------------------------------------
		echo. = %esc%[36mPlease select your language:%esc%[0m
		echo. ======================================
		set /p "pick=> "

		if "%pick%"=="0" (
			rem TODO: [1]
			rem call "%RCSU%" -trace INFO "%~n0" "user pressed [0](cancel)"
			call :ConfirmCancel
			if "!confirm_cancel!"=="YES" (
				call "%RCSU%" -return %RCS_S_CANCEL% %RCS_D_SYS% %RCS_R_SELECT% 002 "user canceled setup"
				exit /b !errorlevel!
			) else (
				rem TODO: [1]
				rem call "%RCSU%" -trace INFO "%~n0" "cancel aborted, returning to selection"
				goto :UI
			)

			:ConfirmCancel
			rem TODO: [1]
			rem call "%RCSU%" -trace INFO "%~n0" "asking for cancel confirmation"
			cls
			echo.
			echo. =------------------------------------=
			echo. = セットアップを中断しますか?
			echo. = Do u really want cancel setup?
			echo. =    [Y]es / はい 
			echo. =    [N]o  / いいえ 
			echo. =------------------------------------=
			echo. = [^^!] Select Yes to %esc%[32mexit%esc%[0m.
			echo. =------------------------------------=
			choice /c YN /n /m "> "
			if "%errorlevel%"=="1" (set "confirm_cancel=YES") else (set "confirm_cancel=NO")
			exit /b

		) else if "%pick%"=="1" (
			set "LANGUAGE=ja-JP"
		) else if "%pick%"=="2" (
			set "LANGUAGE=en-US"
		) else (
			@powershell -Command "[console]::Beep(130.82,200)" 2>nul
			echo. Invalid selection. / 無効な選択です.
			timeout /t 1 >nul
			goto :UI
		)
	)
)
if "%ARG_AUTO%"=="1" (
	call "%RCSU%" -trace INFO "%~n0" "auto mode, skipping UI"
)

set "lang_temp=%LANGUAGE%"
endlocal & set LANGUAGE=%lang_temp%
call "%RCSU%" -trace INFO "%~n0" "user selected language=[%LANGUAGE%]"
call "%RCSU%" -return %RCS_S_FLOW% %RCS_D_SYS% %RCS_R_SELECT% 000 "Language setup complete"
exit /b %errorlevel%



rem TODO [1] DEBUG 変数で粒度制御を導入する


