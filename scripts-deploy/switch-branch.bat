@echo off
setlocal enabledelayedexpansion

echo ========================================
echo    Switch Branch
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
    echo What would you like to do?
    echo [1] Stash changes and switch
    echo [2] Commit changes and switch
    echo [3] Discard changes and switch
    echo [4] Cancel
    echo.
    set /p "CHANGE_CHOICE=Enter choice (1-4): "
    
    if "!CHANGE_CHOICE!"=="1" (
        echo Stashing changes...
        git stash push -m "Auto-stash before branch switch"
        if errorlevel 1 (
            echo ERROR: Failed to stash changes
            pause
            exit /b 1
        )
        set "STASHED=1"
        echo Changes stashed successfully.
        echo.
        
    ) else if "!CHANGE_CHOICE!"=="2" (
        set /p "COMMIT_MSG=Enter commit message: "
        if "!COMMIT_MSG!"=="" (
            echo ERROR: Commit message cannot be empty
            pause
            exit /b 1
        )
        git add .
        git commit -m "!COMMIT_MSG!"
        if errorlevel 1 (
            echo ERROR: Failed to commit changes
            pause
            exit /b 1
        )
        echo Changes committed successfully.
        echo.
        
    ) else if "!CHANGE_CHOICE!"=="3" (
        set /p "DISCARD_CONFIRM=Are you sure? This cannot be undone! (YES/NO): "
        if /i "!DISCARD_CONFIRM!"=="YES" (
            git reset --hard
            echo Changes discarded.
            echo.
        ) else (
            echo Operation cancelled.
            pause
            exit /b 0
        )
        
    ) else (
        echo Operation cancelled.
        pause
        exit /b 0
    )
)

REM Fetch latest branches
echo Fetching latest branches from remote...
git fetch origin >nul 2>&1

REM Show available branches
echo.
echo Available branches:
echo.
echo Local branches:
git branch
echo.

REM Check for remote branches
git branch -r >nul 2>&1
if not errorlevel 1 (
    echo Remote branches:
    git branch -r
    echo.
)

REM Get target branch
set /p "TARGET_BRANCH=Enter branch name to switch to: "

if "%TARGET_BRANCH%"=="" (
    echo ERROR: Branch name cannot be empty
    pause
    exit /b 1
)

REM Check if switching to current branch
if "%TARGET_BRANCH%"=="%CURRENT_BRANCH%" (
    echo Already on branch: %TARGET_BRANCH%
    pause
    exit /b 0
)

REM Try to switch to branch
echo.
echo Switching to branch: %TARGET_BRANCH%
git checkout %TARGET_BRANCH%

if errorlevel 1 (
    REM Branch might not exist locally, try to create from remote
    echo.
    echo Branch not found locally. Checking remote...
    git checkout -b %TARGET_BRANCH% origin/%TARGET_BRANCH%
    
    if errorlevel 1 (
        echo ERROR: Branch '%TARGET_BRANCH%' not found locally or remotely
        
        REM Restore stashed changes if any
        if "%STASHED%"=="1" (
            echo.
            echo Restoring stashed changes...
            git stash pop
        )
        pause
        exit /b 1
    )
)

echo.
echo Switched to branch: %TARGET_BRANCH%

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
echo Current branch: %TARGET_BRANCH%
echo ========================================
echo.
pause
