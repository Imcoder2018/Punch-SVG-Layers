@echo off
echo ========================================
echo   GIT DEPLOYMENT SCRIPTS - WELCOME!
echo ========================================
echo.
echo Thank you for using Git Deployment Scripts!
echo.
echo GETTING STARTED:
echo ----------------
echo.
echo For new projects:
echo   1. Run "menu.bat" and select option [1]
echo   2. Or directly run "init-repo.bat"
echo.
echo For daily work:
echo   - Quick saves: Run "quick-save.bat"
echo   - Custom commits: Run "save-with-message.bat"
echo   - Full menu: Run "menu.bat"
echo.
echo Need help?
echo   - Read "README.md" for complete documentation
echo   - Run "fix-git.bat" if you encounter any issues
echo.
echo ========================================
echo.
echo What would you like to do?
echo.
echo [1] Open Full Menu (Recommended)
echo [2] Initialize New Repository
echo [3] View Repository Status
echo [4] Quick Save Changes
echo [5] Read Documentation
echo [6] Test Scripts (Diagnose Issues)
echo [7] Exit
echo.
set /p "CHOICE=Enter choice (1-7): "

if "%CHOICE%"=="1" (
    call "%~dp0menu.bat"
) else if "%CHOICE%"=="2" (
    call "%~dp0init-repo.bat"
    pause
) else if "%CHOICE%"=="3" (
    call "%~dp0status.bat"
) else if "%CHOICE%"=="4" (
    call "%~dp0quick-save.bat"
) else if "%CHOICE%"=="5" (
    start "" "%~dp0README.md"
    echo Opening documentation...
    timeout /t 2 >nul
) else if "%CHOICE%"=="6" (
    call "%~dp0TEST-SCRIPTS.bat"
) else if "%CHOICE%"=="7" (
    echo Goodbye!
    timeout /t 1 >nul
    exit /b 0
) else (
    echo Invalid choice.
    timeout /t 2 >nul
    call "%~dp0menu.bat"
)
