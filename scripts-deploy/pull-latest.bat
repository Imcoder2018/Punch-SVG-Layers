@echo off
setlocal enabledelayedexpansion

echo ========================================
echo    Pull Latest Changes
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

REM Get current branch
for /f "delims=" %%i in ('git branch --show-current 2^>nul') do set "CURRENT_BRANCH=%%i"

echo Current branch: %CURRENT_BRANCH%
echo.

REM Check for uncommitted changes
git diff --quiet
set "HAS_CHANGES=0"
if errorlevel 1 set "HAS_CHANGES=1"

git diff --cached --quiet
if errorlevel 1 set "HAS_CHANGES=1"

if "%HAS_CHANGES%"=="1" (
    echo WARNING: You have uncommitted changes!
    echo.
    git status --short
    echo.
    set /p "STASH_CONFIRM=Stash changes before pulling? (Y/N): "
    if /i "!STASH_CONFIRM!"=="Y" (
        echo Stashing changes...
        git stash push -m "Auto-stash before pull"
        if errorlevel 1 (
            echo ERROR: Failed to stash changes
            pause
            exit /b 1
        )
        set "STASHED=1"
        echo Changes stashed successfully.
        echo.
    ) else (
        echo Continuing without stashing...
        echo.
    )
)

REM Fetch latest changes
echo Fetching latest changes from remote...
git fetch origin
if errorlevel 1 (
    echo ERROR: Failed to fetch from remote
    echo Please check your internet connection
    pause
    exit /b 1
)

echo.
echo Pulling latest changes...
git pull origin %CURRENT_BRANCH%
if errorlevel 1 (
    echo.
    echo ERROR: Pull failed
    echo This might be due to merge conflicts or network issues.
    
    if "%STASHED%"=="1" (
        echo.
        set /p "RESTORE_STASH=Restore stashed changes? (Y/N): "
        if /i "!RESTORE_STASH!"=="Y" (
            git stash pop
        )
    )
    pause
    exit /b 1
)

echo.
echo Pull completed successfully!

REM Restore stashed changes if any
if "%STASHED%"=="1" (
    echo.
    set /p "RESTORE_STASH=Restore stashed changes? (Y/N): "
    if /i "!RESTORE_STASH!"=="Y" (
        echo Restoring stashed changes...
        git stash pop
        if errorlevel 1 (
            echo WARNING: Conflicts occurred while restoring stash
            echo Please resolve conflicts manually
        ) else (
            echo Stashed changes restored successfully.
        )
    )
)

echo.
echo ========================================
echo Latest changes pulled successfully!
echo ========================================
echo.
pause
