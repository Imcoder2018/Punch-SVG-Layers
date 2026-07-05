@echo off
setlocal enabledelayedexpansion

:MENU
cls
echo ========================================
echo       GIT DEPLOYMENT SCRIPTS MENU
echo ========================================
echo.
echo REPOSITORY MANAGEMENT
echo [1]  Initialize New Repository
echo [2]  Clone Existing Repository
echo [3]  View Repository Status
echo.
echo COMMITTING ^& SAVING
echo [4]  Quick Save (Auto-commit)
echo [5]  Save with Custom Message
echo.
echo DEPLOYMENT
echo [6]  Deploy to Development
echo [7]  Deploy to Production
echo.
echo BRANCH MANAGEMENT
echo [8]  Create New Branch
echo [9]  Switch Branch
echo [10] Merge Branches
echo [11] Delete Branch
echo [12] Compare Branches
echo.
echo HISTORY ^& CHANGES
echo [13] View Commit History
echo [14] Undo Last Commit
echo [15] Revert to Any Past Commit (Full Project Restore)
echo [16] Stash Changes
echo [17] Pull Latest Changes
echo.
echo ACCOUNT ^& CONFIGURATION
echo [18] Change GitHub Account
echo [19] Fix Git Connectivity Issues
echo.
echo ADVANCED
echo [20] Sync Forked Repository
echo.
echo [0]  Exit
echo ========================================
echo.
set /p "CHOICE=Enter your choice (0-20): "

if "%CHOICE%"=="0" (
    echo Exiting...
    timeout /t 1 >nul
    exit /b 0
)

if "%CHOICE%"=="1" (
    call "%~dp0init-repo.bat"
    goto MENU
)

if "%CHOICE%"=="2" (
    call "%~dp0clone-repo.bat"
    goto MENU
)

if "%CHOICE%"=="3" (
    call "%~dp0status.bat"
    goto MENU
)

if "%CHOICE%"=="4" (
    call "%~dp0quick-save.bat"
    goto MENU
)

if "%CHOICE%"=="5" (
    call "%~dp0save-with-message.bat"
    goto MENU
)

if "%CHOICE%"=="6" (
    call "%~dp0deploy-dev.bat"
    goto MENU
)

if "%CHOICE%"=="7" (
    call "%~dp0deploy-prod.bat"
    goto MENU
)

if "%CHOICE%"=="8" (
    call "%~dp0create-branch.bat"
    goto MENU
)

if "%CHOICE%"=="9" (
    call "%~dp0switch-branch.bat"
    goto MENU
)

if "%CHOICE%"=="10" (
    call "%~dp0merge-branch.bat"
    goto MENU
)

if "%CHOICE%"=="11" (
    call "%~dp0delete-branch.bat"
    goto MENU
)

if "%CHOICE%"=="12" (
    call "%~dp0compare-branches.bat"
    goto MENU
)

if "%CHOICE%"=="13" (
    call "%~dp0view-history.bat"
    goto MENU
)

if "%CHOICE%"=="14" (
    call "%~dp0undo-commit.bat"
    goto MENU
)

if "%CHOICE%"=="15" (
    call "%~dp0revert-to-commit.bat"
    goto MENU
)

if "%CHOICE%"=="16" (
    call "%~dp0stash-changes.bat"
    goto MENU
)

if "%CHOICE%"=="17" (
    call "%~dp0pull-latest.bat"
    goto MENU
)

if "%CHOICE%"=="18" (
    call "%~dp0change-account.bat"
    goto MENU
)

if "%CHOICE%"=="19" (
    call "%~dp0fix-git.bat"
    goto MENU
)

if "%CHOICE%"=="20" (
    call "%~dp0sync-fork.bat"
    goto MENU
)

echo.
echo Invalid choice. Please enter a number between 0 and 20.
timeout /t 2 >nul
goto MENU
