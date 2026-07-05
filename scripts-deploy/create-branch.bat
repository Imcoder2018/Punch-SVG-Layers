@echo off
setlocal enabledelayedexpansion

echo ========================================
echo    Create New Branch
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

REM Show existing branches
echo Existing branches:
git branch
echo.

REM Get new branch name
set /p "BRANCH_NAME=Enter new branch name: "

if "%BRANCH_NAME%"=="" (
    echo ERROR: Branch name cannot be empty
    pause
    exit /b 1
)

REM Check if branch already exists
git show-ref --verify --quiet refs/heads/%BRANCH_NAME%
if not errorlevel 1 (
    echo ERROR: Branch '%BRANCH_NAME%' already exists
    echo.
    set /p "SWITCH_TO=Switch to existing branch? (Y/N): "
    if /i "!SWITCH_TO!"=="Y" (
        git checkout %BRANCH_NAME%
        if errorlevel 1 (
            echo ERROR: Failed to switch branch
            pause
            exit /b 1
        )
        echo Switched to branch: %BRANCH_NAME%
    )
    pause
    exit /b 0
)

REM Ask which branch to create from
echo.
echo Create branch from:
echo [1] Current branch (%CURRENT_BRANCH%)
echo [2] Main/Master branch
echo [3] Specific commit
echo.
set /p "SOURCE_CHOICE=Enter choice (1-3): "

if "%SOURCE_CHOICE%"=="2" (
    REM Try main first, then master
    git show-ref --verify --quiet refs/heads/main
    if not errorlevel 1 (
        set "SOURCE_BRANCH=main"
    ) else (
        git show-ref --verify --quiet refs/heads/master
        if not errorlevel 1 (
            set "SOURCE_BRANCH=master"
        ) else (
            echo ERROR: Neither main nor master branch exists
            pause
            exit /b 1
        )
    )
    echo Creating branch from: !SOURCE_BRANCH!
    git checkout !SOURCE_BRANCH!
    git checkout -b %BRANCH_NAME%
    
) else if "%SOURCE_CHOICE%"=="3" (
    set /p "COMMIT_HASH=Enter commit hash: "
    if "!COMMIT_HASH!"=="" (
        echo ERROR: Commit hash cannot be empty
        pause
        exit /b 1
    )
    echo Creating branch from commit: !COMMIT_HASH!
    git checkout -b %BRANCH_NAME% !COMMIT_HASH!
    
) else (
    echo Creating branch from current branch...
    git checkout -b %BRANCH_NAME%
)

if errorlevel 1 (
    echo ERROR: Failed to create branch
    pause
    exit /b 1
)

echo.
echo Branch '%BRANCH_NAME%' created successfully!
echo.

REM Ask if user wants to push to remote
set /p "PUSH_REMOTE=Push new branch to remote? (Y/N): "
if /i "%PUSH_REMOTE%"=="Y" (
    echo Pushing to remote...
    git push -u origin %BRANCH_NAME%
    if errorlevel 1 (
        echo WARNING: Failed to push to remote
        echo You can push later using: git push -u origin %BRANCH_NAME%
    ) else (
        echo Branch pushed to remote successfully!
    )
)

echo.
echo ========================================
echo Current branch: %BRANCH_NAME%
echo ========================================
echo.
pause
