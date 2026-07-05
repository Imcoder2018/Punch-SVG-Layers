@echo off
setlocal enabledelayedexpansion

echo ========================================
echo    Sync Forked Repository
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

echo Current remotes:
git remote -v
echo.

REM Check if upstream is already configured
git remote | find "upstream" >nul
if errorlevel 1 (
    echo Upstream remote not configured.
    echo.
    set /p "UPSTREAM_URL=Enter the original repository URL (upstream): "
    
    if "!UPSTREAM_URL!"=="" (
        echo ERROR: Upstream URL cannot be empty
        pause
        exit /b 1
    )
    
    echo Adding upstream remote...
    git remote add upstream !UPSTREAM_URL!
    if errorlevel 1 (
        echo ERROR: Failed to add upstream remote
        pause
        exit /b 1
    )
    
    echo Upstream remote added successfully!
    echo.
) else (
    echo Upstream remote is already configured.
    echo.
    
    set /p "UPDATE_UPSTREAM=Update upstream URL? (Y/N): "
    if /i "!UPDATE_UPSTREAM!"=="Y" (
        set /p "NEW_UPSTREAM=Enter new upstream URL: "
        if not "!NEW_UPSTREAM!"=="" (
            git remote set-url upstream !NEW_UPSTREAM!
            echo Upstream URL updated.
            echo.
        )
    )
)

echo Fetching from upstream...
git fetch upstream
if errorlevel 1 (
    echo ERROR: Failed to fetch from upstream
    echo Please check the upstream URL and your internet connection
    pause
    exit /b 1
)

echo.
echo Available upstream branches:
git branch -r | find "upstream/"
echo.

REM Determine which branch to sync
set /p "SYNC_BRANCH=Enter branch to sync (default: main): "
if "%SYNC_BRANCH%"=="" set "SYNC_BRANCH=main"

REM Check if upstream branch exists
git show-ref --verify --quiet refs/remotes/upstream/%SYNC_BRANCH%
if errorlevel 1 (
    REM Try master if main doesn't exist
    if "%SYNC_BRANCH%"=="main" (
        git show-ref --verify --quiet refs/remotes/upstream/master
        if not errorlevel 1 (
            set "SYNC_BRANCH=master"
            echo Using 'master' branch instead of 'main'.
        ) else (
            echo ERROR: Neither main nor master branch found in upstream
            pause
            exit /b 1
        )
    ) else (
        echo ERROR: Branch '%SYNC_BRANCH%' not found in upstream
        pause
        exit /b 1
    )
)

echo.
echo Syncing with upstream/%SYNC_BRANCH%...
echo.

REM Check for uncommitted changes
git diff --quiet
set "HAS_CHANGES=0"
if errorlevel 1 set "HAS_CHANGES=1"

git diff --cached --quiet
if errorlevel 1 set "HAS_CHANGES=1"

if "%HAS_CHANGES%"=="1" (
    echo WARNING: You have uncommitted changes!
    set /p "STASH_NOW=Stash changes before syncing? (Y/N): "
    if /i "!STASH_NOW!"=="Y" (
        git stash push -m "Auto-stash before upstream sync"
        set "STASHED=1"
    ) else (
        echo ERROR: Please commit or stash your changes first
        pause
        exit /b 1
    )
)

REM Switch to the sync branch if not already there
if not "%CURRENT_BRANCH%"=="%SYNC_BRANCH%" (
    echo Switching to %SYNC_BRANCH% branch...
    git checkout %SYNC_BRANCH%
    if errorlevel 1 (
        echo Creating %SYNC_BRANCH% branch from upstream...
        git checkout -b %SYNC_BRANCH% upstream/%SYNC_BRANCH%
        if errorlevel 1 (
            echo ERROR: Failed to checkout %SYNC_BRANCH% branch
            if "%STASHED%"=="1" (
                git stash pop
            )
            pause
            exit /b 1
        )
    )
)

echo Merging upstream changes...
git merge upstream/%SYNC_BRANCH%
if errorlevel 1 (
    echo.
    echo ERROR: Merge conflicts detected!
    echo Please resolve conflicts and then:
    echo 1. git add ^<resolved files^>
    echo 2. git commit
    echo 3. git push
    echo.
    echo Or abort merge: git merge --abort
    
    if "%STASHED%"=="1" (
        echo.
        echo Note: You have stashed changes. Use 'git stash pop' to restore them.
    )
    pause
    exit /b 1
)

echo.
echo Upstream changes merged successfully!
echo.

set /p "PUSH_NOW=Push changes to origin? (Y/N): "
if /i "%PUSH_NOW%"=="Y" (
    echo Pushing to origin/%SYNC_BRANCH%...
    git push origin %SYNC_BRANCH%
    if errorlevel 1 (
        echo WARNING: Failed to push to origin
        echo You can push later using: git push origin %SYNC_BRANCH%
    ) else (
        echo Pushed to origin successfully!
    )
)

REM Restore stashed changes if any
if "%STASHED%"=="1" (
    echo.
    set /p "RESTORE_STASH=Restore stashed changes? (Y/N): "
    if /i "!RESTORE_STASH!"=="Y" (
        git stash pop
        if errorlevel 1 (
            echo WARNING: Conflicts occurred while restoring stash
        )
    )
)

echo.
echo ========================================
echo Fork synced successfully!
echo ========================================
echo.
pause
