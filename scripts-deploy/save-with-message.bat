@echo off
setlocal enabledelayedexpansion

echo ========================================
echo    Save with Custom Message
echo ========================================
echo.

REM Navigate to project root
cd /d "%~dp0.."

REM Check if git is initialized
if not exist ".git" (
    echo ERROR: Git repository not initialized
    echo Please run init-repo.bat first
    pause
    exit /b 1
)

REM Show current status
echo Current changes:
echo.
git status --short
echo.

REM Get commit message from user
set /p "COMMIT_MSG=Enter commit message: "

if "%COMMIT_MSG%"=="" (
    echo ERROR: Commit message cannot be empty
    pause
    exit /b 1
)

echo.
echo Staging all changes...
git add .
if errorlevel 1 (
    echo ERROR: Failed to stage changes
    pause
    exit /b 1
)

echo Committing with message: %COMMIT_MSG%
git commit -m "%COMMIT_MSG%"
if errorlevel 1 (
    echo.
    echo No changes to commit or commit failed.
    pause
    exit /b 0
)

echo.
echo Pushing to remote...
git push
if errorlevel 1 (
    echo.
    echo WARNING: Push failed. Checking remote configuration...
    
    REM Try to get current branch
    for /f "delims=" %%i in ('git branch --show-current 2^>nul') do set "CURRENT_BRANCH=%%i"
    
    if not "!CURRENT_BRANCH!"=="" (
        echo Setting upstream branch and pushing...
        git push -u origin !CURRENT_BRANCH!
        if errorlevel 1 (
            echo.
            echo ERROR: Failed to push to remote
            echo Please check your internet connection and remote configuration.
            pause
            exit /b 1
        )
    ) else (
        echo ERROR: Could not determine current branch
        pause
        exit /b 1
    )
)

echo.
echo ========================================
echo Changes saved and pushed successfully!
echo ========================================
echo.
pause
