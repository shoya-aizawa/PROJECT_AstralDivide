:: [Encoding] UTF-8 (without BOM) required
@echo off
rem ===========================================================
rem  Astral Divide Return Code System Const (v0.1a)
rem  by HedgeHogSoft / PROJECT_AstralDivide
rem  Dependency: RCS_Util v0.3a+
rem ===========================================================

:: Section (S)
set RCS_S_FLOW=1
set RCS_S_CANCEL=8
set RCS_S_ERR=9
set RCS_S_INFO=2
set RCS_S_WARN=3

:: Domain (DD)
set RCS_D_MENU=01
set RCS_D_SAVE=02
set RCS_D_DISPLAY=03
set RCS_D_ENV=04
set RCS_D_AUDIO=05
set RCS_D_SYS=06
set RCS_D_NET=07
set RCS_D_STORY=08
set RCS_D_DEBUG=09

:: Reason (RR)
set RCS_R_SELECT=01
set RCS_R_IO=10
set RCS_R_PARSE=11
set RCS_R_ENC=12
set RCS_R_NET=20
set RCS_R_VALID=30
set RCS_R_COMPAT=50
set RCS_R_OTHER=90


:: [MIGRATION INFO] Internal references only; not used during Const load.
set "RCSU=%PROJECT_ROOT%\Src\Systems\Debug\RCS_Util.bat"
set "RCSC=%~f0"

exit /b 0