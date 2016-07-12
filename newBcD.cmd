@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
:: The VHD files are stored on C: under WinPE, but Windows booted from VHD sees 
:: the physical drive for the VHD files as D: ---- NOTE ---- this value must be 
:: determined for your own system as it depends on the devices / drives it has.

set debug=false
set vhdDrive=none
set ini=Boot\osBootGuids.ini

if %debug%==true (
   :: Find the  osBootGuids.ini file. Do this first so this script will
   :: function properly whether debugging  under  WinPE-SS  or Windows.
   for /F "tokens=1 delims=\ " %%? in ('MOUNTVOL.EXE ^|FIND ":\"') do (
      call :chkReady %%? ready
      if !ready!==true if exist %%?\%ini% set vhdDrive=%%?
   )
  :: Did we find it?
  if /I !vhdDrive!==none goto :missingINI
  
) else set vhdDrive=D:

set cVol="VHD Files"
set libChk=MediaID.txt
set ini=%vhdDrive%\%ini%
set bcd=%vhdDrive%\boot\BcD
set blankDif=%vhdDrive%\blankDif.vhd
set noRollback=%vhdDrive%\Boot\noRebootRollback.flg
set errorlevel=0

:: Disable rollback on reboot if \Boot\noRebootRollback.flg exists
if exist %noRollback% goto :theExit

::This OS Shutdown script lives in: C:\Windows\System32\GroupPolicy\Machine\Scripts\Shutdown
::
::This System Shutdown Script will change the default boot option to a pristine  "rolled back"
::copy of the difference.vhd file. This script simply toggles between 2 boot entries,  one for
::the difference VHD we're currently booted under and the other BCD boot entry is for the next 
::boot cycle. We can't delete the current version due to a lock but we can boot a copy and the
::next time our current difference VHD will be replaced.
::
::This of course requires plenty of disk space. Although the pristine difference VHD files are 
::small initially (145KB),  they can grow once booted to their maximum size. Thus the space we 
::need is the parent VHD (22GB) + expanded difference VHD (40GB) + 2nd copy of an expanded dif
::file (40GB) yields a minimum space requirement of 100GB for a 40GB Windows filesystem.

:: The format of the ini file is:
:: [BootVHDs]
:: diff1={16161a75-3965-11e6-8a05-806e6f6e6963}
:: diff2={96161a76-3965-11e6-8a05-806e6f6e6963}
:: lastBooted={16161a75-3965-11e6-8a05-806e6f6e6963}

if not exist %ini% goto :missingINI

:: Helpful while testing
if %debug%==true (
   set diff1=
   set diff2=
   set lastBooted=
)

:: Parse the ini file and assign variables + values based on its contents.
:: Verify the assignment. Validate each GUID value. 
for /F "Tokens=1,2 delims==" %%A in ('type %ini% ^| find /V "["') do (
   set %%A=%%B
   if "!%%A!" NEQ "%%B" goto :iniError
   call :validateGUID %%A status
   if !status! NEQ 0 goto :guidError
)

:: Set the next  AND  last VHD files booted. In this shutdown script the
:: lastBooted GUID represents the bootmgr entry we are running under now.
if "%lastBooted%" == "%diff1%" (
   set nextVHD=%vhdDrive%\bootDif2.vhd
   set lastVHD=%vhdDrive%\bootDif1.vhd
   set nextGUID=%diff2%
) else (
   set nextVHD=%vhdDrive%\bootDif1.vhd
   set lastVHD=%vhdDrive%\bootDif2.vhd
   set nextGUID=%diff1%
)

if %debug%==true (
   echo.
   echo Last GUID booted=%lastBooted%
   echo Last VHD  booted=%lastVHD%
   echo Next VHD  to boot=%nextVHD%
   echo Next GUID to boot=%nextGUID%
   echo.
)

:: Update the last entry in the ini file to reflect the next entry to boot.
(
 echo [BootVHDs]
 echo diff1=%diff1%
 echo diff2=%diff2%
 echo lastBooted=%nextGUID%
)> %ini%

:: Update the bootmgr and switch the default boot entry
if %debug%==false bcdedit /store %bcd% /default %nextGUID%

:: Overwrite the differencing VHD we'll boot to next time with a blank one so
:: we'll reboot to a fresh, clean version identical to the parent (image.vhd).
if %debug%==false xcopy %blankDif% %nextVHD% /C /R /Y

:: Normal exit
goto :theExit

:iniError
set /A errorlevel=%errorlevel% + 1
goto :msgOut

:guidError
set /A errorlevel=%errorlevel% + 2
goto :msgOut

:missingINI
set /A errorlevel=%errorlevel% + 4

:msgOut
if %debug%==true echo Error validating %ini% or its contents (%errorlevel%)
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

