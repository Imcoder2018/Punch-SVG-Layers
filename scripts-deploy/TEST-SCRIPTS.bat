@echo off
echo ========================================
echo    Script Testing Tool
echo ========================================
echo.
echo This will help diagnose why scripts aren't working.
echo.
pause
echo.

echo [TEST 1] Checking if Git is installed...
git --version
if errorlevel 1 (
    echo.
    echo ERROR: Git is NOT installed!
    echo Download from: https://git-scm.com/downloads
    echo.
    pause
    exit /b 1
) else (
    echo SUCCESS: Git is installed!
)
echo.
pause

echo [TEST 2] Checking if GitHub CLI is installed...
gh --version
if errorlevel 1 (
    echo.
    echo WARNING: GitHub CLI is NOT installed.
    echo This is optional but recommended.
    echo Download from: https://cli.github.com/
    echo.
    echo Scripts will still work without it!
) else (
    echo SUCCESS: GitHub CLI is installed!
)
echo.
pause

echo [TEST 3] Checking GitHub CLI authentication...
gh auth status 2>&1
if errorlevel 1 (
    echo.
    echo You are NOT logged in to GitHub CLI.
    echo This is normal if you haven't logged in yet.
    echo.
    echo To login, you can:
    echo 1. Run change-account.bat
    echo 2. Or run: gh auth login
) else (
    echo SUCCESS: You are logged in!
)
echo.
pause

echo [TEST 4] Checking current directory...
echo Current directory: %CD%
echo.
cd ..
echo Parent directory: %CD%
echo.
cd scripts-deploy
echo.
pause

echo [TEST 5] Checking Git configuration...
echo Git user name:
git config --global user.name
echo.
echo Git user email:
git config --global user.email
echo.
pause

echo [TEST 6] Testing if this script pauses correctly...
echo If you can read this, the pause command works!
echo.
pause

echo ========================================
echo    Test Results Summary
echo ========================================
echo.
echo If all tests passed, your scripts should work.
echo.
echo Common issues:
echo 1. Git not installed - Install from git-scm.com
echo 2. GitHub CLI not installed - Optional, but helpful
echo 3. Not logged in to GitHub CLI - Run: gh auth login
echo.
echo Next steps:
echo 1. If Git is missing, install it and restart computer
echo 2. Try running change-account.bat again
echo 3. Try running init-repo.bat again
echo.
echo ========================================
echo.
echo Press any key to exit...
pause >nul
