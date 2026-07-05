@echo off
echo.
echo ========================================
echo    IMMEDIATE DIAGNOSTIC
echo ========================================
echo.
echo Checking why scripts are closing...
echo.
pause
echo.

echo [1/4] Checking Git installation...
where git >nul 2>&1
if errorlevel 1 (
    echo.
    echo ❌ PROBLEM FOUND: Git is NOT installed or not in PATH
    echo.
    echo This is why your scripts close immediately!
    echo.
    echo SOLUTION:
    echo 1. Download Git from: https://git-scm.com/downloads
    echo 2. Install with default settings
    echo 3. RESTART your computer
    echo 4. Try scripts again
    echo.
    pause
    exit /b 1
) else (
    echo ✓ Git is installed
    git --version
)
echo.
pause

echo [2/4] Checking GitHub CLI...
where gh >nul 2>&1
if errorlevel 1 (
    echo.
    echo ⚠️ GitHub CLI is NOT installed (this is optional)
    echo.
    echo Scripts will work without it, but you'll need to:
    echo - Create repositories manually on GitHub.com
    echo - Enter repository URLs when prompted
    echo.
    echo To install GitHub CLI (optional):
    echo Download from: https://cli.github.com/
    echo.
) else (
    echo ✓ GitHub CLI is installed
    gh --version
)
echo.
pause

echo [3/4] Testing pause command...
echo If you can read this, pause works!
echo.
pause

echo [4/4] Testing script navigation...
cd /d "%~dp0.."
echo Current directory: %CD%
echo.
echo This should be your project folder (NOT scripts-deploy)
echo.
pause

echo.
echo ========================================
echo    DIAGNOSTIC COMPLETE
echo ========================================
echo.
echo SUMMARY:
echo.

where git >nul 2>&1
if errorlevel 1 (
    echo ❌ Git: NOT INSTALLED - This is the problem!
    echo    Install from: https://git-scm.com/downloads
    echo    Then RESTART your computer
) else (
    echo ✓ Git: Installed and working
)

where gh >nul 2>&1
if errorlevel 1 (
    echo ⚠️ GitHub CLI: Not installed (optional)
    echo    Scripts will work without it
) else (
    echo ✓ GitHub CLI: Installed
)

echo.
echo ========================================
echo.

where git >nul 2>&1
if errorlevel 1 (
    echo NEXT STEPS:
    echo 1. Install Git from: https://git-scm.com/downloads
    echo 2. Restart your computer
    echo 3. Run this diagnostic again
    echo 4. Then try your scripts
) else (
    echo Your system is ready!
    echo.
    echo Try running:
    echo - change-account.bat
    echo - init-repo.bat
    echo.
    echo They should work now.
)

echo.
echo ========================================
echo.
pause
