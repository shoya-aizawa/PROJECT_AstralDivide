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

call "%RCSU%" -trace INFO "SetupLanguage" "setup start"


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
			exit /b 90300013
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
		mode con cols=40 lines=15

		:UI
		cls
		echo.
		echo. ======================================
		echo. =        Language Setup v0.1a        =
		echo. ======================================
		echo. = [1] 日本語 (ja-JP)
		echo. = [2] English (en-US)
		echo. = [0] Cancel / キャンセル
		echo. =-------------------------------------
		echo. = %esc%[36mPlease select your language:%esc%[0m
		echo. ======================================
		set /p "pick=> "

		if "%pick%"=="0" (
			call "%RCSU%" -trace INFO "SetupLanguage" "user canceled"
			call "%RCSU%" -return %RCS_S_CANCEL% %RCS_D_SYS% %RCS_R_SELECT% 002 "user canceled"
			exit /b !errorlevel!
			rem I'm using errorlevel experimentally, but it may not work in deep nests, so I tested it here.
		) else if "%pick%"=="1" (
			set "LANGUAGE=ja-JP"
		) else if "%pick%"=="2" (
			set "LANGUAGE=en-US"
		) else (
			powershell -Command "[console]::Beep(130.82,100)" 2>nul
			powershell -Command "[console]::Beep(130.82,200)" 2>nul
			echo Invalid selection. / 無効な選択です.
			timeout /t -1 >nul
			goto :UI
		)
	)
)
if "%ARG_AUTO%"=="1" (
	call "%RCSU%" -trace INFO "SetupLanguage" "auto mode, skipping UI"
)

set "lang_temp=%LANGUAGE%"
endlocal & set LANGUAGE=%lang_temp%
call "%RCSU%" -trace INFO "SetupLanguage" "user selected language=[%LANGUAGE%]"
call "%RCSU%" -return %RCS_S_FLOW% %RCS_D_SYS% %RCS_R_OTHER% 000 "SetupLanguage OK"
exit /b %errorlevel%