@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
:: The VHD files are stored on C: under WinPE, but Windows booted from VHD sees 
:: the physical drive for the VHD files as D: ---- NOTE ---- this value must be 
:: determined for your own system as it depends on the devices / drives it has.

set debug=false
set bootDriv=X:
set vhdDrive=none
set cVol="VHD Files"
set libChk=MediaID.txt
set thisScript=%~dpfx0
set parentVHD=image.vhd
set blankDif=blankDif.vhd
set ini=Boot\osBootGuids.ini
set errorlevel=0

:: Helpful while testing
if %debug%==true (
   set diff1=
   set diff2=
   set lastBooted=
)

:: First, make sure this script is being run from WinPE-SS
if NOT %thisScript%==%bootDriv%\SDRState\merge.cmd goto :notWinPEss

:: Verify correct PE version by existence of a specific file.
if NOT exist %bootDriv%\%libChk% goto :notWinPEss

:: Loop through all of the active (i.e. device is ready) volumes 
:: looking for the osBootGuids.ini file.
for /F "tokens=1 delims=\ " %%? in ('MOUNTVOL.EXE ^|FIND ":\"') do (
   call :chkReady %%? ready
   if !ready!==true if exist %%?\%ini% set vhdDrive=%%?
)
:: Did we find it?
if /I %vhdDrive%==none goto :missingINI
set parentVHD=%vhdDrive%\%parentVHD%
set blankDif=%vhdDrive%\%blankDif%
set ini=%vhdDrive%\%ini%

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

:: Make sure the VHD files to be merged are present
if NOT exist %lastVHD% goto :missingVHD
if NOT exist %parentVHD% goto :missingVHD

echo.
echo XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
echo                      MERGE %lastVHD% FILE with %parentVHD%
echo.
echo Warning: this script will merge what's in the previously booted difference VHD
echo file  (bootDif1.vhd or bootDif2.vhd) into the parent %parentVHD% file on this
echo computer. This isn't reversible, so you should double-check to see that's what
echo you want. Enter "y" (lowercase only please) and press enter to merge,  or type
echo anything else to abort and NOT merge the files. Looks like %lastVHD% was
echo the last VHD file booted, so that's what will be merged.
echo XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
echo.
set /p response=Enter "y" to merge, anything else to leave things untouched? 
echo.
if not %response%==y ((echo Exiting...)&(goto :theExit))

echo Okay, then let's continue.
echo.

:: Validated that an %parentVHD% and %lastVHD% exist on %vhdDrive% and that we are 
:: running WinPE. If we got here, time to get to work: merge the files then create 
:: a new differencing VHD file.
X:
echo.
echo 
echo =========================================================================
echo Found  base  image  and difference files on %vhdDrive%.  Merging files, please be
echo patient... Diskpart will offer 100 percent for progress information,  BUT
echo the wait to finish merging the VHDs AFTER that 100 percent message can be 
echo seven minutes depending on disk speeds, memory, volume of changes etc.)
echo =========================================================================
echo.

:: Do the merge
(   echo select vdisk file="%lastVHD%" 
    echo merge vdisk depth=1
) | diskpart

:: Delete the old blankDif.vhd file
del %blankDif% /Q  >NUL

:: Now create a new, blank difference file (child VHD with differences from parent)
echo create vdisk file="%blankDif%" parent="%parentVHD%" | diskpart >NUL

:: ...and overwrite the VHD difference file to be booted next
copy %blankDif% %nextVHD% /Y >nul

echo.
echo =========================================================================
echo Complete.  %parentVHD% has now been updated to include changes made when
echo %lastVHD% was used last.  That information cannot be lost by future
echo rollbacks (done on every system shutdown). It's safe to reboot now.
echo =========================================================================
echo.

:: Normal exit
goto :theExit

:iniError
set /A errorlevel=%errorlevel% + 1
echo ************************************************************************
echo An error occurred setting the values from the ini file. (exit code: %errorlevel%)
echo ************************************************************************
goto :msgOut

:guidError
set /A errorlevel=%errorlevel% + 2
echo.
echo ************************************************************************
echo I found the  %ini% file, but it doesn't contain valid
echo data (it failed GUID validation checks). There's not much I can do until
echo this is fixed. Bye^^! (exit code: %errorlevel%)
echo ************************************************************************
goto :msgOut

:missingINI
set /A errorlevel=%errorlevel% + 4
echo. 
echo ************************************************************************
echo Hmmmmmmm... I can't find %ini% so I can't determine which                  
echo files to merge. I suggest you proceed with caution. The lastBooted value
echo in that file should have the GUID of the NEXT bootmgr entry to be booted
echo but you probably want to merge the other one.  It  might  be best if you
echo first correct the %ini% file and rerun this script. (exit code: %errorlevel% )
echo ************************************************************************
goto :msgOut

:notWinPEss
set /A errorlevel=%errorlevel% + 8
echo.
echo ************************************************************************
echo   You don't appear to be running the WinPE-SS  customized for use with 
echo   Steadier State as I  don't see a specific file that should be there. 
echo   Is this the correct media? Not much I can do. Bye^^! (exit code: %errorlevel%)
echo ************************************************************************
goto :msgOut

:missingVHD
set /A errorlevel=%errorlevel% + 16
echo.
echo ************************************************************************
echo It looks like you finished the initial setup, however one or both of the
echo files to be merged  (%lastVHD% and/or %parentVHD%)  do not exist,
echo so there's nothing for me to do now.  As Roy Batty said in Blade Runner:  
echo "Time to die". (exit code: %errorlevel%)
echo ************************************************************************

:msgOut
goto :theExit


REM *** functions *************************************************************
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

