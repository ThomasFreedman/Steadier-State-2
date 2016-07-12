@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
:: echo Initializing WinPE, please be patient...
:: wpeinit
echo Initialization complete. 

:: For use with winpeshl.ini which doesn't work as expected with CMD.exe, /K
:: set Path=%Path%%SystemDrive%\SDRState;
:: cd %SystemDrive%\SDRState

set debug=false

set peDrive=%SystemDrive%
set vhdDrive=none
set ini=Boot\osBootGuids.ini

:: Find the osBootGuids.ini file if it exists.
for /F "tokens=1 delims=\ " %%? in ('MOUNTVOL.EXE ^|FIND ":\"') do (
   call :chkReady %%? ready
   if !ready!==true if exist %%?\%ini% set vhdDrive=%%?
)
:: Did we find it?
if /I %vhdDrive%==none goto :missingINI
set ini=%vhdDrive%\%ini%
  
set lastVHD=none
set cVol="VHD Files"
set libChk=MediaID.txt
set thisScript=%~dpfx0-
set mediaVolName=STDYR-STATE

:: ===================================================================
:: THIS SCRIPT RUNS WHEN WinPE STEADIER STATE STARTS UP,
:: but where was it booted from-  USB, ISO or WIM  file?
::
:: With Thomas Freedman's modifications that question is
:: no longer important.  All that is required to utilize
:: Steadier State is right here on this very media!
::
:: NOTE:
:: Changing the system's drives or partitions may affect 
:: Steadier State's operation, especially after Steadier
:: state is installed. Also note WinPE may use different
:: drive definitions than are used by the Windows OS. X:
:: will always be the drive  WinPE-SS  runs on no matter
:: what media it was booted from.

:: First, lets figure out our operating context. Lets see
:: if things are where they should be...

:: Helpful while testing
if %debug%==true (
   set diff1=
   set diff2=
   set lastBooted=
)

:: First, make sure this script is being run from WinPE-SS.
:: Verify correct PE version by existence of a specific file.
if NOT exist %peDrive%\%libChk% goto :notWinPEss

:: if setup is complete we know where our files are, no need to search
:: for them.  Determining if setup is complete is a matter of checking 
:: if the ini file exists. The only reason to do this when starting PE
:: is to provide some basic info about Steadier State's status.
if NOT exist %ini% goto :missingINI

:: Parse the ini file and assign variables + values based on its contents.
:: Verify the assignment. Validate each GUID value. 
for /F "Tokens=1,2 delims==" %%A in ('type %ini% ^| find /V "["') do (
   set %%A=%%B
   if "!%%A!" NEQ "%%B" goto :iniError
   call :validateGUID %%A status
   if !status! NEQ 0 goto :guidError
)

:: Set the next  AND  last VHD files booted.  When Windows was shutdown
:: last it set the value of lastBooted in the ini file to the NEXT GUID
:: to be booted. Merge needs to process the "other" one.
if "%lastBooted%" == "%diff1%" (
   set nextVHD=%vhdDrive%\bootDif1.vhd
   set lastVHD=%vhdDrive%\bootDif2.vhd
   set nextGUID=%diff1%
) else (
   set nextVHD=%vhdDrive%\bootDif2.vhd
   set lastVHD=%vhdDrive%\bootDif1.vhd
   set nextGUID=%diff2%
)

if %debug%==true (
   echo.
   echo Last VHD  booted=%lastVHD%
   echo Next VHD  to boot=%nextVHD%
   echo Next GUID to boot=%nextGUID%
   echo.
)

:showshell
echo.
echo =========================================================================
echo Hi^^!  You're here because you booted your system and chose  "Admins Only^!" 
echo or  you are in the initial process of setting things up.   Welcome to SS^^!
echo.
echo This VHD management system is based on Mark Minasi's "Steadier State" but 
echo does not require WinPE for rolling back Windows to its "steady state" and 
echo thus eliminates an extra boot cycle (first boots WinPE to do the rollback
echo then another restart is required to boot Windows in the steady state). 
echo.
echo The modifications to Steadier State were created by Thomas Freedman after
echo he studied Sami Laiho's Wioski VHD management system which didn't require 
echo WinPE or 2 boot cycles to return the system to its "steady state". Thomas
echo Had difficulty using Wioski due to issues related to Windows Setup.exe so
echo he then tried  Mark Minasi's  SS which worked for him but was not as fast 
echo as Wioski.  This system is essentially a hybrid of those two, which still
echo is implemeted entirely with Windows CMD shell scripts.
echo.
echo If you're here to update your Windows "master" template (C:\image.vhd) be
echo sure you see a "last booted" filename below. If you do, updating the base
echo image.vhd  to  keep any changes that were made to the system while logged
echo into Windows last time is as simple as running:
echo.
echo                                  merge
echo.
echo Reboot once  merge is done by typing exit at the command prompt or simply
echo close the command window. WinPE is ONLY required for setup and merge now,
echo and it will always restart to a pristine, rolled back state automatically
echo if the system shutdown script (newBcD.cmd) created by Thomas is used.
echo.
echo You may Contact Thomas Freedman on  http://reboot.pro/  (user thomnet) or 
echo Mark Minasi at help@minasi.com or http://www.steadierstate.com/.  We hope 
echo you find this useful! 
echo =========================================================================
echo.
echo WinPE-SS on %peDrive%, VHD files on %vhdDrive% and last VHD booted: %lastVHD%
echo.
goto :EOF

:iniError
call :showshell
set /A errorlevel=%errorlevel% + 1
echo ************************************************************************
echo An error occurred setting the values from the ini file. (exit code: %errorlevel%)
echo ************************************************************************
goto :msgOut

:guidError
call :showshell
set /A errorlevel=%errorlevel% + 2
echo.
echo ************************************************************************
echo I found the %ini% file, but it doesn't contain valid data
echo (it failed GUID validation checks). There's not much I can do until this 
echo is fixed. Bye! (exit code: %errorlevel%)
echo ************************************************************************
goto :msgOut

:missingINI
call :showshell
set /A errorlevel=%errorlevel% + 4
echo. 
echo ************************************************************************
echo I can't find  %ini% so  I  can't  provide any information
echo about Steadier State on your system.  Maybe you're in the initial stages
echo of setting your system up for Steadier State, or perhaps this is the 1st
echo time to run this script.  However you found yourself here,  you  need to 
echo resolve this error, which may simply be a matter of completing the setup
echo process. (exit code: %errorlevel%)
echo ************************************************************************
goto :msgOut

:notWinPEss
call :showshell
set /A errorlevel=%errorlevel% + 8
echo.
echo ************************************************************************
echo   You don't appear to be running the WinPE-SS  customized for use with 
echo   Steadier State as I  don't see a specific file that should be there. 
echo   Is this the correct media? Not much I can do. Bye! (exit code: %errorlevel%)
echo ************************************************************************

:msgOut
goto :theExit


:: **** functions *************************************************************
::      "library" There are techniques whereby the following functions could be
::                included or imported into this batch as an external  library,
::                however its a substantial amount of overhead for 3 functions.
::                Never-the-less, it is not optimal to have to maintain changes
::                to these functions in all of the places that use them.

:validateGUID -- Validate the input is a valid GUID ---------------------------
::                  1) Is length of string == 38 characters?
::                  2) Are the characters in it valid?
::                  3) Is the GUID enclosed in braces?
::                  4) Is the hyphen spacing correct?
::               Parameters:
::               -- %~1: Name of the variable with GUID (not the GUID value)
::               -- %~2: Name of variable to return results in
::               Returns:
::               -- 0 for a valid GUID and -1 for an invalid GUID 
set /A valid= -1
call :strlen %1 length 38
if NOT %length% == 38 goto :returnValidity
for /F "delims={0123456789-ABCDEFabcdef}" %%A in ("!%~1!") do goto :returnValidity
set pattern="!%~1:~0,1!!%~1:~9,1!!%~1:~14,1!!%~1:~19,1!!%~1:~24,1!!%~1:~37,1!"
if NOT %pattern%=="{----}" goto :returnValidity
set /A valid= 0
:returnValidity
if "%~2" NEQ "" set /A %~2= %valid%
goto :EOF

:strlen -------- Find the length of a string ----------------------------------
::               Parameters:
::               -- %~1: The name of the variable (not the string value)
::               -- %~2: Name of variable to return results in
::               -- %~3: The maximum anticipated string length value (not ref)
::               Returns:
::               -- the string length or -1 for an invalid string or one
::                  that exceeds the maximum length parameter
for /L %%L in (1,1,%3) do (
   if "!%1!" == "!%1:~0,%%L!" set %2=%%L && goto :EOF
)
if "%~2" NEQ "" set /A %~2= -1
goto :EOF

:chkReady ------ Determine if a drive is active -------------------------------
::               Parameters:
::               -- %~1: The drive to be checked (value not reference)
::               -- %~2: Name of variable to return results in
::               Returns:
::               -- true if the drive is active, false if missing or not ready
set result=false
dir %~1 1>NUL 2>&1 || goto :returnResult
set result=true
:returnResult
if "%~2" NEQ "" set %~2=%result%
goto :EOF

:theExit

