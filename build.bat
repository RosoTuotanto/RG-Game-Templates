@echo off
setlocal
cd /d "%~dp0"

:menu
echo.
echo RG Game Templates: build into dst\
echo.
echo   [1] All templates
echo   [2] visual-novel
echo   [3] platformer
echo   [4] top-down
echo   [5] Exit
echo.
choice /c 12345 /n /m "Press a number: "

rem choice sets errorlevel to the number pressed. "if errorlevel N" is true for N and above, so the highest number is checked first.
if errorlevel 5 goto :end
if errorlevel 4 goto :topdown
if errorlevel 3 goto :platformer
if errorlevel 2 goto :visualnovel
if errorlevel 1 goto :all
goto :end

:all
call :build visual-novel
call :build platformer
call :build top-down
goto :menu

:visualnovel
call :build visual-novel
goto :menu

:platformer
call :build platformer
goto :menu

:topdown
call :build top-down
goto :menu

rem Copies each game\ and developmentFiles\ folder of src\core and then src\templates\[name] on top of it into dst\[name].
:build
set "target=dst\%~1"
set "template=src\templates\%~1"

if exist "%target%" rmdir /s /q "%target%"
if exist "%target%" goto :deletefail

mkdir "%target%\game"
mkdir "%target%\developmentFiles"

rem Robocopy exit codes 0 to 7 mean success, 8 and above mean failure.
robocopy "src\core\game" "%target%\game" /e /nfl /ndl /njh /njs >nul
if errorlevel 8 goto :copyfail

rem /is and /it make every template file replace the core file with the same name, even when robocopy classes the two as the same file.
robocopy "%template%\game" "%target%\game" /e /is /it /nfl /ndl /njh /njs >nul
if errorlevel 8 goto :copyfail

robocopy "src\core\developmentFiles" "%target%\developmentFiles" /e /nfl /ndl /njh /njs >nul
if errorlevel 8 goto :copyfail

if exist "%template%\developmentFiles" (
	robocopy "%template%\developmentFiles" "%target%\developmentFiles" /e /is /it /nfl /ndl /njh /njs >nul
	if errorlevel 8 goto :copyfail
)

echo Built %target%
exit /b 0

:deletefail
echo ERROR: could not delete %target%. Close every program that has it open, then build again.
exit /b 1

:copyfail
echo ERROR: copying files to %target% failed.
exit /b 1

:end
endlocal
