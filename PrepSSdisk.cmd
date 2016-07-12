@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
cls
set timeout=0
set vhdDrive=C:
set peDrive=%~d0
set cVol="VHD Files"
set thisScript=%~dpfx0
set osLabel1="Windows 7a"
set osLabel2="Windows 7b"
set bootDir=%vhdDrive%\Boot
set bcdFile=%bootDir%\BcD
set mediaVolName=STDYR-STATE
set libChk=%peDrive%\MediaID.txt
set setupLog=%peDrive%\ssSetup.log
set bootDif1=[%vhdDrive%]\bootDif1.vhd
set bootDif2=[%vhdDrive%]\bootDif2.vhd
set bcdGuids=%vhdDrive%\Boot\osBootGuids.ini
set unBooted={99999999-9999-9999-9999-999999999999}

:: Adjust these values as necessary, but do not reduce to zero,
:: even if you don't indend on  dual booting.  These partitions
:: WILL be created, even if they are very small.  If you reduce 
:: these to zero this script may not work correctly.
set linuxRootSize=12000
set linuxSwapSize=4000

:: Insure that we're running from the root of the boot device.
if /I not "%peDrive%"=="X:" goto :pleaseBootPeFirst

%peDrive%
cd \SDRState

:: Verify correct PE version by existence of a specific file.
if exist %libChk% goto :step1

echo.
echo **************************************************************
echo You don't appear to be running the WinPE-SS customized for use
echo with Steadier State as I don't see a specific file that should
echo be there. Is this the correct media? I'll list the %peDrive% folder 
echo and pause here so you can double check the files. Double check 
echo them NOW... before we go on. Abort with ctrl-C if not correct.
echo **************************************************************
echo.
dir %peDrive%
pause
goto :step1

:pleaseBootPeFirst
echo.
echo **************************************************************
echo This  command file will not run properly unless it is run from 
echo a WinPE boot device (USB|DVD|CD) customized for Steadier State.
echo.
echo Please set up your bootable WinPE USB or CD as explained in the
echo documentation, and run %thisScript% from that drive.
echo.
echo Thanks, and we hope you find Steadier State useful.
echo **************************************************************
echo.
goto :done

:step1
:: If this system has only 1 disk skip asking the user for it
set pipeline="echo list disk | diskpart | find /C "Disk""
for /F "usebackq delims=" %%? in (`!pipeline!`) do (
    set /A disks=%%? / 3
)
if !disks! EQU 1 (
   set /A hdd= 0
   echo Skipping step 1 since drive 0 is the only drive I see...
   goto :hddEntered
)

cls
echo STEP 1
echo ===============================================================
echo             DETERMINE WHICH DRIVE IS PHYSICAL HDD
echo.
echo YOU must determine which drive number (not drive letter) is the 
echo system's actual, physical HDD.   This is extremely difficult to 
echo do programatically, so it is up to you to enter the right value 
echo here.  I have listed the drives on this system with diskpart so
echo hopefully you can look at this list and be certain which disk #
echo is the one to partition. If only one disk is shown it's simple.
echo.
echo          DO NOT PROCEED UNLESS YOU ARE SURE OF IT!!!
echo.
echo The drive you designate here will be  partitioned and formated,
echo so if you're not sure that's OK to do, abort this script before
echo you destroy data you wish to keep. What I need here is a single
echo digit for the physical disk drive of this system or  Control-c.
echo ===============================================================
echo.
echo list disk | diskpart
set /P resp=What is your answer (type end or control-C to exit)? 
if a%resp%==aend goto :done

set hdd=none
for /L %%? in (0,1,9) do ( if a%resp%==a%%? set hdd=%resp% )
if not %hdd%==none goto :hddEntered

echo.
echo ***************************************************************
echo I didn't see a valid drive entered (0 - 9), so you must want to 
echo abort. OK! Aborting by your request. Bye!
echo ***************************************************************
echo.
goto :done

:hddEntered
echo.
echo STEP 2
echo ===============================================================
echo           REPARTITION and FORMAT THE PHYSICAL DRIVE
echo.
echo I will wipe the physical drive you designated in step 1 (or THE
echo disk if there is only one) and repartition it like this:
echo.
echo           PARTIITION #   SIZE               PURPOSE
echo                      1:  %linuxRootSize%              Linux Op Sys
echo                      2:  %linuxSwapSize%               Linux Swap
echo                      3:  Remainder of disk  SS / VHD Files
echo.
echo The  Linux  partitions  use diskpart's setid command so Windows 
echo will not assign a drive letter to them. When you install  Linux
echo.
echo (This version of Steadier State uses Linux's  grub2 bootloader
echo  to launch Windows 7, WinPE-SS and Linux directly from a grub2
echo  customized, graphical theme menu.  If  you don't want to dual
echo  boot or use  Linux  you  might  consider  using the  original
echo  Steadier State by  Mark Minasi,  or,  try Sami Laiho's Wioski)
echo.
echo on the first partition it will of course install the grub2 boot
echo loader into the MBR,  which  will need to be configured to boot
echo WinPE-SS from a Windows IMage format (WIM) file. That aspect of
echo the  SS  setup process is performed by  manually  editing a few 
echo files under Linux.  Those steps are described in the additional
echo docs provided by Thomas Freedman,  who produced this version of
echo steadier state.  Most  modern Linux distros will also install a
echo grub2 menu item to boot Windows automatically with os-prober.
echo ===============================================================
echo.
pause
echo STEP 2 continued...
echo ===============================================================
echo NOTE:  You  do not  need to install  linux or grub2 to use this 
echo        version of  Steadier State.  When this process completes
echo        the Windows  Boot Manager  will be installed on C:\ with
echo        boot entries for your Windows VHD image.  It will have a 
echo        timeout of  0  so it will boot Windows without showing a
echo        menu of any kind.  You will need your  WinPE-SS bootable
echo        media to perform routine maintenance and merge changes.
echo.
echo After wiping the disk,  it will install 2  partitions for Linux
echo and the remaining space as one large C:  partition to store the
echo Windows VHD and a few Steadier State files. 
echo.
echo For this command file to work you must run this from a WinPE-SS
echo USB stick or CD created with the  BUILDPE.CMD command file that 
echo is included in the SS archive you downloaded.
echo ===============================================================
echo.
pause
cls
echo.
echo Step 3: Last chance to abort before I wipe the drive clean...
echo XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
echo         W A R N I N G ^^!^^!^^!^^!^^!^^!       W A R N I N G ^^!^^!^^!^^!^^!^^!
echo.
echo This command file prepares this PC to receive a  Steadier State
echo ready  image.vhd file,  and  provides the support files to make
echo Steadier State work. To do so, this file will totally and fully
echo. 
echo             WIPE THIS COMPUTER'S drive %hdd% CLEAN!
echo             Do I now have your complete attention?
echo.
echo Specifically this script wipes disk %hdd%, the  drive determined in
echo Step 1.  If you aren't sure  %hdd%  is the correct,  physical drive
echo or don't know what that that means, or if you are even slightly
echo unsure about whether there's data on drive  %hdd%  you would regret 
echo losing, then  press  ctrl-C now to stop this script. Otherwise, 
echo press some other key to continue...
echo.
echo If you're sure that you want to wipe drive %hdd%  clean and install
echo a few small Steadier State support files,  then please type the 
echo eighth word in this paragraph (4 letter word starting with "w")
echo and then press Enter to begin the repartitioning process.
echo XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
echo.
set /p response=Please type the word in lowercase and press Enter. 
echo.
if not "%response%" == "wipe" ((echo Exiting.) & (goto :done))
echo.
echo Ok then, here we go... Please be patient :)
echo.
:: 
:: ASSUMPTIONS:
::    -You want to wipe and rebuild drive %hdd% in (chk diskpart)
::    -You are running this batch file from the root of your USB 
::     stick or CD
::    -I can set the new VHD storage drive to C:
::    -Successful completion of these diskpart operations need to
::     be verified by the user manually
::
:: If drive C: currently exists I'll just unassign whatever drive 
:: has C: assigned to it so I can assign C: to the last partition
:: in our new, repartitioned physical drive.
echo.> %setupLog%
if exist c:\ (
   echo C: exists, so I'll need to rearrange drive letters...
   ( echo select disk %hdd% 
     echo sel vol c 
     echo assign 
    ) | diskpart >> %setupLog%
)
(
 echo select disk %hdd%
 echo clean
 echo cre par pri size=%linuxRootSize% 
 echo set ID=83
 echo cre par pri size=%linuxSwapSize%
 echo set ID=82
 echo cre par pri
 echo format fs=ntfs quick label=%cVol%
 echo assign letter=%vhdDrive:~0,1%
 echo active
 echo rescan
 echo exit
) | diskpart >> %setupLog%

:: TODO: Find a way to determine if diskpart completed successfully
::       using a pipe as above without using a temporary file.
set /A dr1=0
if %dr1% == 0 (
  echo.
  echo ===============================================================
  echo Disk repartitioning is done.  Please verify drive C: has volume 
  echo name %cVol% and the linux partitions exist in the listings 
  echo below. If you don't intend on installing Linux or some other OS
  echo you can edit the partition sizes of this script above to  maxi-
  echo mize your Windows drive space.  If something goes wrong look at
  echo the %setupLog% for clues on what happened.
  echo ===============================================================
  echo.
)

:: Display a list of partitions and volumes. First the partitions...
set cmd="echo select disk %hdd%^&echo list partition | diskpart"
for /F "skip=7 usebackq delims=" %%? in (`!cmd!`) do (
   set line=%%?
   set cut=!line:~0,8!
   if NOT !cut!==DISKPART echo %%?
)
echo.
:: Now the volume listing
set cmd="echo select disk %hdd%^&echo list volume | diskpart"
for /F "skip=7 usebackq delims=" %%? in (`!cmd!`) do (
   set line=%%?
   set cut=!line:~0,8!
   if NOT !cut!==DISKPART echo %%?
)
echo.
pause
:step4
echo.
echo Step 3, the last step, begins...
echo ===============================================================
echo Now it is time to create the bootMgr BCD datastore for Windows.
echo It will create 2  bootable entries that are used alternately to
echo achieve a rolled back version of Windows on  every boot without
echo the need to first boot WinPE or anything else to get it ready.
echo.
echo The  "secret sauce"  of this algorithm is a new  Windows system
echo shutdown script that uses bcdedit to switch the default bootmgr
echo entry to be booted next.  It also copies the blankDif.vhd saved
echo by the last run of merge.cmd to  bootDif1.vhd and bootDif2.vhd, 
echo overwriting the one to be used next with an  empty differencing 
echo file which will be booted next to provide a rolled back Windows
echo identical to the parent/template image.vhd. The bootDif?.vhd in
echo use when  Windows  is  shutdown is locked and cannot be deleted
echo until the next boot cycle, when it will be overwritten.
echo.
echo To finish SS setup and install Windows Bootmgr press any key...
echo ===============================================================
echo.
pause
:: How is it possible that the mkdir below reports "There is already
:: a folder named Boot"? The disk is totally wiped and cleaned so it
:: should not exist, unless diskpart creates it. 
mkdir %bootDir%                                             >nul

bcdedit /createstore %bcdFile%.tmp                          >nul
bcdedit /import %bcdFile%.tmp                               >nul
del %bcdFile%.tmp /Q                                        >nul
bcdedit /create {bootmgr}                                   >nul
bcdedit /timeout %timeout%                                  >nul
bcdedit /set {bootmgr} device partition=%vhdDrive%          >nul

set guid=
for /f "tokens=2 delims={}" %%i in ('@bcdedit /create /d %osLabel1% -application osloader') do (set guid={%%i%})

if "%guid%" == "" goto :bcdError
echo [bootVHDs]>    %bcdGuids%
echo diff1=%guid%>> %bcdGuids%

bcdedit /default %guid%                                     >nul
bcdedit /set {default} device vhd=%bootDif1%                >nul
bcdedit /set {default} osdevice vhd=%bootDif1%              >nul
bcdedit /set {default} path \windows\system32\winload.exe   >nul
bcdedit /set {default} locale en-US                         >nul
bcdedit /set {default} inherit {bootloadersettings}         >nul
bcdedit /set {default} recoveryenabled no                   >nul
bcdedit /set {default} systemroot \windows                  >nul	
bcdedit /set {default} nx OptIn                             >nul
bcdedit /set {default} detecthal yes                        >nul
bcdedit /displayorder {default} /addlast                    >nul

:: The above code creates the BCD with bootmgr and the first OS boot entry.
:: Now continue and create the 2nd boot entry

set guid=
for /f "tokens=2 delims={}" %%i in ('@bcdedit /create /d %osLabel2% -application osloader') do (set guid={%%i%})

if "%guid%" == "" goto :bcdError
echo diff2=%guid%>>          %bcdGuids%
echo lastBooted=%unBooted%>> %bcdGuids%

bcdedit /set %guid% device vhd=%bootDif2%                   >nul
bcdedit /set %guid% osdevice vhd=%bootDif2%                 >nul
bcdedit /set %guid% path \windows\system32\winload.exe      >nul
bcdedit /set %guid% locale en-US                            >nul
bcdedit /set %guid% inherit {bootloadersettings}            >nul
bcdedit /set %guid% recoveryenabled no                      >nul
bcdedit /set %guid% systemroot \windows                     >nul	
bcdedit /set %guid% nx OptIn                                >nul
bcdedit /set %guid% detecthal yes                           >nul
bcdedit /displayorder %guid% /addlast                       >nul
bcdedit /export %vhdDrive%\Boot\BCD.bak                     >nul

:: Copy Other things we'll need to the vhdDrive
xcopy %peDrive%\SDRState\Other %vhdDrive%\Other  /Y /I /S   >nul

:: Last major item is to actually install bootmgr...
bootsect.exe /nt60 
copy %peDrive%\SDRState\Other\bootmgr %vhdDrive%\BOOTMGR /Y >nul
goto :finishLine

:bcdError
echo.
echo ***************************************************************
echo             ++++++ BCD CREATION FAILURE +++++++++
echo.
echo A problem occurred while attempting to create and configure the 
echo Windoze Boot Configuration Database file. That may mean bcdedit
echo (the Windows tool for manipulating BCD files)  got confused and 
echo wrote to the wrong drive,  or tried writing it to a nonexistent 
echo drive.
echo. 
echo The entire bcd "registry" boot process is more complicated than
echo it needs to be IMO. You can thank Micro$oft for that mess.
echo.
echo Ending %thisScript%.
echo ***************************************************************
echo.
goto :done

:: Finished configuring bootmgr! We're basically done...
:finishLine
cls
echo.
echo ===============================================================
echo Step 4 Complete, the disk repartitioned, bootmgr configured.
echo ===============================================================
echo.
echo               NEXT STEPS TO DEPLOY AN IMAGE.VHD:
echo.
echo   1) Assuming you've created the image.vhd file containing your 
echo      desired Windows image, please copy that file to the volume 
echo      (C: currently) labeled:
echo.
echo                          VHD Files
echo.
echo   2) Test it -- without  Linux or grub2 installed you should be
echo      able to run Windows now from the image.vhd file created by
echo      the buildpe.cmd script on this media.
echo.
echo   3) Merge newBcD.cmd into Windows -- you can skip this step if
echo      you do NOT want Windows rolled back on every boot.  Review
echo      the documentation if you need info on using merge.cmd.
echo.
echo   4) Optional -- Install Linux and configure grub2.  Review the 
echo      documentation provided by Thomas Freedman for this version
echo      of Steadier State to learn how to configure the grub2 boot
echo      loader to start Windows, WinPE-SS and of course Linux.
echo.
echo   Thats about it. We hope you find this useful. You can Contact 
echo   Thomas Freedman on reboot.pro  (user thomnet)  or Mark Minasi
echo   at help@minasi.com or www.steadierstate.com.
echo ===============================================================
echo.

:done