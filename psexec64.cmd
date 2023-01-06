:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Author:		David Geeraerts
:: Location:	Olympia, Washington USA
:: E-Mail:		geeraerd@evergreen.edu
::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Copyleft License(s)
:: GNU GPL (General Public License)
:: https://www.gnu.org/licenses/gpl-3.0.en.html
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:::::::::::::::::::::::::::
@Echo Off
setlocal enableextensions
:::::::::::::::::::::::::::

::#############################################################################
::							#DESCRIPTION#
::	SCRIPT STYLE: Intelligent Wrapper
::		Wrapper for psexec64
::
::	Developed for console output.
::#############################################################################

::::::::::::::::::::::::::::::::::
:: VERSIONING INFORMATION		::
::  Semantic Versioning used	::
::   http://semver.org/			::
::::::::::::::::::::::::::::::::::
::	Major.Minor.Revision
::	Added BUILD number which is used during development and testing.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: Initialize the terminal	:::::::::::::::::::::::::::::::::::::::::::::::::::
SET $SCRIPT_NAME=module_tool_PSEXEC64
SET $SCRIPT_VERSION=0.1.0
SET $SCRIPT_BUILD=20230106 1000
Title %$SCRIPT_NAME% Version: %$SCRIPT_VERSION%
prompt PSEXEC64$G
color 03
mode con:cols=80
mode con:lines=45
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Declare Global variables
::	All User variables are set within here.
::		(configure variables)
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: Use a password file. Leave blank to type password in console.
SET "$PASSWORD_FILE="
REM If there's a space in the path use this format:
::	SET "$PASSWORD_FILE=<path with spaces>"

:: Use a computer list for remote computers
SET $COMPUTER_LIST=
REM If there's a space in the path use this format:
::	SET "$COMPUTER_LIST=<path with spaces>"

:: location of cache directory
IF NOT EXIST "%TEMP%\cache" MKDIR "%TEMP%\cache"


:: Default switch to use --can be changed
REM to use built in commands {getmac, ipconfig}, can just use -i switch
SET "$SWITCH=-h -i -d -c -f -n 10"

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
::##### Everything below here is 'hard-coded' [DO NOT MODIFY] #####
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: Set the default user one time
::	NOTES:
REM	psexec dosn't work with -u <UPN>
REM e.g. -u <userName@evergreen.edu>
REM Wants legacy format: <domain>\<user>
REM Executable should be copied to local machine for execution.
SET "$USER_ACCOUNT=%USERDOMAIN%\%USERNAME%"


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Banner
SET $BANNER=0
SET $COMMAND=
SET $PSEXEC64_VERSION=
SET $PATH=

:banner
cls
:: CONSOLE OUTPUT 
echo   ****************************************************************
echo		%DATE% %TIME%
echo.
IF DEFINED $USER_ACCOUNT echo		User Account: %$USER_ACCOUNT%
IF DEFINED $PASSWORD_FILE echo		User password file: %$PASSWORD_FILE%
IF DEFINED $PSEXEC64_VERSION echo		PsExec Version: %$PSEXEC64_VERSION%
IF DEFINED $PATH echo		PsExec path: %$PATH%
IF DEFINED $SWITCH echo		PsExec switch: %$SWITCH%
echo		Command: %$COMMAND%
IF DEFINED $COMPUTER_LIST echo 	Computer List file: %$COMPUTER_LIST%
IF DEFINED $COMPUTERS echo		Computers: %$COMPUTERS%
echo.
echo   ****************************************************************
echo.
IF %$BANNER% EQU 1 GoTo :EOF
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SET $BANNER=1
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


::	Set the path to psexec64.exe
where psexec64.exe 2> nul > %temp%\cache\where_psexec64.txt && SET /P $PATH= < %temp%\cache\where_psexec64.txt
IF DEFINED $PATH dir "%$PATH%" | FIND /I "Directory of"> "%temp%\cache\dir_psexec64.txt"
FOR /F "tokens=3 delims= " %%P IN (%temp%\cache\dir_psexec64.txt) DO ECHO %%P> %temp%\cache\path_psexec64.txt
SET /P $PATH= < %temp%\cache\path_psexec64.txt
:SETPATH
IF DEFINED $PATH (echo Default path:
					echo %$PATH%
					GoTo skipPATH)
IF NOT DEFINED $PATH @powershell Write-Host "Path to Psexec64 must be defined:" -ForegroundColor Red
echo.
SET /P $PATH=Path to psexec64:
IF NOT EXIST %$PATH%\psexec64.exe GoTo SETPATH
echo.
:skipPATH
cd /D %$PATH%
CALL :banner


:: Psexec Version
@powershell (Get-command "%$PATH%\psexec64.exe").FileVersionInfo.FileVersion > "%TEMP%\cache\psexec64_version.txt"
SET /P $PSEXEC64_VERSION= < "%TEMP%\cache\psexec64_version.txt"
CALL :banner


:rerun
CALL :banner


:: Default user account
::	NOTES:
REM	psexec dosn't work with -u <UPN>
REM e.g. -u <userName@evergreen.edu>
REM Wants legacy format: <domain>\<user>
REM Executable should be copied to local machine for execution.


@powershell Write-Host "User account. Hit enter to bypass...." -ForegroundColor White  
echo Current User: %$USER_ACCOUNT%
SET /p $USER_ACCOUNT=User Account ^<domain^>^\^<user^>:
CALL :banner



:: Password	:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
IF DEFINED $PASSWORD_FILE SET /P $PASSWORD= < "%$PASSWORD_FILE%"
echo Change the password for the user? Hit enter to bypass.
IF DEFINED $PASSWORD_FILE echo Using password file: %$PASSWORD_FILE%
SET /P $PASSWORD=Change password?:
:password
IF NOT DEFINED $PASSWORD ( echo Password must be provided...
							SET /P $PASSWORD=Provide password: 
						)
IF NOT DEFINED $PASSWORD GoTo password
CALL :banner

::###########################################################################::

:: Set the switch string	:::::::::::::::::::::::::::::::::::::::::::::::::::
::	-c	copy program to remote system
::	-d	Don't wait for process to terminate (non-interactive)
::	-e	Don't load specified account profile
::	-f	Copy the specified program even if the file already exists on the remote system.
::	-i	Run the program so that it interacts with the desktop of the specified session on the remote system. If no session is specified the process runs in the console session.
::	-h	If the target system is Vista or higher, has the process run with the account's elevated token, if available.
::	-l	Run process as limited user (strips the Administrators group and allows only privileges assigned to the Users group). On Windows Vista the process runs with Low Integrity.
::	-n	Specifies timeout in seconds connecting to remote computers.
REM -e Can cause issues if a program is using user variables such as %temp%
REM With PSEXEC version 2.30, it requires the -i switch

echo  -c copy program to remote system.
echo  -d Don't wait for process to terminate non-interactive.
echo  -e Don't load specified account profile.
echo  -f Copy the specified program even if the file already exists on the remote system.
echo  -i Run the program so that it interacts with the desktop.
echo  -h Admin priveleges.
echo  -l Run process as limited user.
echo  -n Specifies timeout in seconds connecting to remote computers.
echo.
echo  -e Can cause issues if a program is using user variables such as ^%temp^%.
echo.
echo Current switch:%$SWITCH%
echo.
echo Hit enter to accept current switch...
SET /P $SWITCH=Switch:
CALL :banner

::###########################################################################::



::Command	:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Set the comamnd to run
::	Examples
::	SET "$COMMAND=\\evergreen.edu\NETLOGON\SciComp\Software\install_QuickAndDirty.cmd"
SET /P $COMMAND=Command as full path:
IF NOT DEFINED $COMMAND PATH SET /P $COMMAND=Command as full path:
IF NOT DEFINED $COMMAND echo No command given, exiting...
IF NOT DEFINED $COMMAND GoTo exit
CALL :banner

::###########################################################################::


:: Define compuers with list or manually
echo Use a computer list file or enter manually?
	echo.
	echo [1] Computer List
	echo [2] Manuall
choice /c 12
	If ERRORLevel 2 GoTo Mlist
	If ERRORLevel 1 GoTo Clist
:Clist
:: Blank out manual computers if using file list
SET $COMPUTERS=
IF DEFINED $COMPUTER_LIST echo Current computer list file: %$COMPUTER_LIST%
@powershell Write-Host "Hit enter to accept current computer list file..." -ForegroundColor White
IF NOT DEFINED $COMPUTER_LIST @powershell Write-Host "No current computer list file!" -ForegroundColor Yellow
SET /P $COMPUTER_LIST=Computer list file full path:
IF NOT DEFINED $COMPUTER_LIST GoTo Clist
GoTo execute

:Mlist
:: Blank out computer list since using manuall entry
SET $COMPUTER_LIST=
@powershell Write-Host "Manually enter computers if not using a list..." -ForegroundColor DarkYellow
echo e.g. Computer1,Computer2, etc.
IF DEFINED $COMPUTERS echo Current computers: %$COMPUTERS% 
SET /P $COMPUTERS=Computers:
IF NOT DEFINED $COMPUTERS GoTo Mlist
GoTo execute
::###########################################################################::


:: Execute	:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:execute
CALL :banner
IF DEFINED $COMPUTER_LIST (psexec64.exe -accepteula @"%$COMPUTER_LIST%" %$SWITCH% -u %$USER_ACCOUNT% -p %$PASSWORD% "%$COMMAND%") ELSE (
							psexec64.exe -accepteula \\%$COMPUTERS% %$SWITCH% -u %$USER_ACCOUNT% -p %$PASSWORD% "%$COMMAND%")

timeout /t 60

:Menu
	echo What to do next?
	echo.
	echo [1] Run again
	echo [2] Exit
	echo.
	Choice /c 12
	echo.
	::
	If ERRORLevel 2 GoTo cleanup
	If ERRORLevel 1 GoTo rerun

:cleanup
	RMDIR /S /Q "%TEMP%\cache"

:exit
	exit