@echo off
setlocal enabledelayedexpansion

echo ========================================
echo    Git Repository Status
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

echo Current Branch: %CURRENT_BRANCH%
echo.

REM Show remote URLs
echo Remote URLs:
git remote -v
echo.

REM Show status
echo Repository Status:
echo.
git status
echo.

REM Show last 5 commits
echo ========================================
echo Last 5 Commits:
echo ========================================
git log --oneline -5
echo.

REM Show branch list
echo ========================================
echo Local Branches:
echo ========================================
git branch
echo.

REM Show stash list
echo ========================================
echo Stashed Changes:
echo ========================================
git stash list
if errorlevel 1 (
    echo No stashed changes.
)
echo.

REM Check for uncommitted changes
git diff --quiet
if errorlevel 1 (
    echo WARNING: You have uncommitted changes!
) else (
    git diff --cached --quiet
    if errorlevel 1 (
        echo WARNING: You have staged but uncommitted changes!
    ) else (
        echo All changes are committed.
    )
)

echo.
pause
