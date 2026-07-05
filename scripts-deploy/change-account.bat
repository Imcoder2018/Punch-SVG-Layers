@echo off
setlocal enabledelayedexpansion

echo ========================================
echo    Change GitHub Account
echo ========================================
echo.

REM Check if GitHub CLI is installed
set "GH_INSTALLED=0"
gh --version >nul 2>&1
if not errorlevel 1 set "GH_INSTALLED=1"

if "%GH_INSTALLED%"=="0" (
    echo ⚠️ GitHub CLI is NOT installed
    echo.
    echo This script can still help you configure Git!
    echo.
) else (
    echo ✓ GitHub CLI is installed
    echo.
    echo Current GitHub CLI status:
    echo.
    gh auth status 2>&1
    if errorlevel 1 (
        echo.
        echo Not currently logged in to GitHub CLI.
    )
    echo.
)
echo ========================================
echo.

echo What would you like to do?
echo [1] Login to a different account
echo [2] Logout from current account
echo [3] View current account details
echo [4] Configure Git user details
echo [5] Open GitHub in browser
echo [6] Cancel
echo.
set /p "CHOICE=Enter choice (1-6): "

if "%CHOICE%"=="1" (
    echo.
    if "%GH_INSTALLED%"=="0" (
        echo GitHub CLI is not installed.
        echo.
        echo To login to GitHub:
        echo 1. Install GitHub CLI from: https://cli.github.com/
        echo 2. Or login via browser: https://github.com/login
        echo.
        echo Opening GitHub login page...
        start https://github.com/login
        echo.
        echo After logging in, use option [4] to configure Git user details.
        echo.
    ) else (
        echo Logging in to GitHub...
        echo You will be prompted to authenticate in your browser.
        gh auth login
        if errorlevel 1 (
            echo ERROR: Login failed
            pause
            exit /b 1
        )
        echo.
        echo Login successful!
        echo.
        echo Current user:
        gh auth status 2>&1
        echo.
        
        REM Update git config with new user
        for /f "delims=" %%i in ('gh api user -q .login 2^>nul') do set "GH_USER=%%i"
        for /f "delims=" %%i in ('gh api user -q .email 2^>nul') do set "GH_EMAIL=%%i"
        
        if not "!GH_USER!"=="" (
            git config --global user.name "!GH_USER!"
            echo Git username set to: !GH_USER!
        )
        if not "!GH_EMAIL!"=="" (
            git config --global user.email "!GH_EMAIL!"
            echo Git email set to: !GH_EMAIL!
        )
    )
    
) else if "%CHOICE%"=="2" (
    echo.
    if "%GH_INSTALLED%"=="0" (
        echo GitHub CLI is not installed.
        echo Cannot logout without GitHub CLI.
        echo.
    ) else (
        set /p "CONFIRM=Are you sure you want to logout? (Y/N): "
        if /i "!CONFIRM!"=="Y" (
            echo Logging out from GitHub...
            gh auth logout
            echo Logout successful!
        ) else (
            echo Logout cancelled.
        )
    )
    
) else if "%CHOICE%"=="3" (
    echo.
    echo Current account details:
    echo.
    if "%GH_INSTALLED%"=="1" (
        echo GitHub CLI status:
        gh auth status 2>&1
        if errorlevel 1 (
            echo Not logged in to GitHub CLI.
        )
        echo.
    )
    echo Current Git configuration:
    echo.
    echo Name: 
    git config --global user.name 2>nul
    echo Email: 
    git config --global user.email 2>nul
    echo.
    
) else if "%CHOICE%"=="4" (
    echo.
    echo Configure Git user details:
    echo.
    set /p "GIT_NAME=Enter your name: "
    set /p "GIT_EMAIL=Enter your email: "
    
    if not "!GIT_NAME!"=="" (
        git config --global user.name "!GIT_NAME!"
        echo Git username set to: !GIT_NAME!
    )
    if not "!GIT_EMAIL!"=="" (
        git config --global user.email "!GIT_EMAIL!"
        echo Git email set to: !GIT_EMAIL!
    )
    echo.
    echo Configuration updated successfully!
    
) else if "%CHOICE%"=="5" (
    echo.
    echo Opening GitHub in browser...
    start https://github.com
    echo.
    
) else if "%CHOICE%"=="6" (
    echo Operation cancelled.
    pause
    exit /b 0
    
) else (
    echo Invalid choice.
    pause
    exit /b 1
)

echo.
pause
