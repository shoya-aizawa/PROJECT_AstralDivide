@echo off
rem === Return/Error Code 定数群 (RC v1) ===
rem S
set rc_s_flow=1
set rc_s_cancel=8
set rc_s_err=9

rem DD
set rc_d_menu=01
set rc_d_save=02
set rc_d_display=03
set rc_d_env=04
set rc_d_audio=05
set rc_d_sys=06
set rc_d_net=07
set rc_d_story=08
set rc_d_debug=09

rem RR
set rc_r_select=01
set rc_r_io=10
set rc_r_parse=11
set rc_r_enc=12
set rc_r_net=20
set rc_r_valid=30
set rc_r_compat=50
set rc_r_other=90

rem PROJECT_ROOT規定済みを前提
if not defined PROJECT_ROOT (exit /b 1)
set "RCU=%PROJECT_ROOT%\Src\Systems\Debug\ReturnCodeUtil.bat"
set "RCC=%~f0"