@echo off
echo Initializing WinPE, please be patient...
wpeinit

set Path=%Path%%SystemDrive%\SDRState;
cd %SystemDrive%\SDRState
cmd.exe /K initSS.cmd
