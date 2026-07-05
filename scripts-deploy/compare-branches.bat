@echo off
setlocal enabledelayedexpansion

echo ========================================
echo    Compare Branches
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

echo Available branches:
echo.
git branch -a
echo.

REM Get branches to compare
set /p "BRANCH1=Enter first branch (or press Enter for current: %CURRENT_BRANCH%): "
if "%BRANCH1%"=="" set "BRANCH1=%CURRENT_BRANCH%"

set /p "BRANCH2=Enter second branch to compare with: "

if "%BRANCH2%"=="" (
    echo ERROR: Second branch cannot be empty
    pause
    exit /b 1
)

REM Verify branches exist
git show-ref --verify --quiet refs/heads/%BRANCH1%
if errorlevel 1 (
    REM Try as remote branch
    git show-ref --verify --quiet refs/remotes/origin/%BRANCH1%
    if errorlevel 1 (
        echo ERROR: Branch '%BRANCH1%' not found
        pause
        exit /b 1
    ) else (
        set "BRANCH1=origin/%BRANCH1%"
    )
)

git show-ref --verify --quiet refs/heads/%BRANCH2%
if errorlevel 1 (
    REM Try as remote branch
    git show-ref --verify --quiet refs/remotes/origin/%BRANCH2%
    if errorlevel 1 (
        echo ERROR: Branch '%BRANCH2%' not found
        pause
        exit /b 1
    ) else (
        set "BRANCH2=origin/%BRANCH2%"
    )
)

echo.
echo ========================================
echo Comparing: %BRANCH1% with %BRANCH2%
echo ========================================
echo.

echo Select comparison type:
echo.
echo [1] Show commits in %BRANCH1% not in %BRANCH2%
echo [2] Show commits in %BRANCH2% not in %BRANCH1%
echo [3] Show both differences
echo [4] Show file differences
echo [5] Show detailed diff
echo [6] Show statistical summary
echo [7] Cancel
echo.
set /p "COMPARE_TYPE=Enter choice (1-7): "

if "%COMPARE_TYPE%"=="1" (
    echo.
    echo Commits in %BRANCH1% not in %BRANCH2%:
    echo ========================================
    git log %BRANCH2%..%BRANCH1% --oneline
    echo.
    
) else if "%COMPARE_TYPE%"=="2" (
    echo.
    echo Commits in %BRANCH2% not in %BRANCH1%:
    echo ========================================
    git log %BRANCH1%..%BRANCH2% --oneline
    echo.
    
) else if "%COMPARE_TYPE%"=="3" (
    echo.
    echo Commits in %BRANCH1% not in %BRANCH2%:
    echo ========================================
    git log %BRANCH2%..%BRANCH1% --oneline
    echo.
    echo.
    echo Commits in %BRANCH2% not in %BRANCH1%:
    echo ========================================
    git log %BRANCH1%..%BRANCH2% --oneline
    echo.
    
) else if "%COMPARE_TYPE%"=="4" (
    echo.
    echo Files changed between %BRANCH1% and %BRANCH2%:
    echo ========================================
    git diff --name-status %BRANCH1%..%BRANCH2%
    echo.
    
) else if "%COMPARE_TYPE%"=="5" (
    echo.
    echo Detailed differences between %BRANCH1% and %BRANCH2%:
    echo ========================================
    git diff %BRANCH1%..%BRANCH2%
    echo.
    
) else if "%COMPARE_TYPE%"=="6" (
    echo.
    echo Statistical summary:
    echo ========================================
    git diff --stat %BRANCH1%..%BRANCH2%
    echo.
    echo.
    echo Commit count in %BRANCH1% not in %BRANCH2%:
    for /f %%i in ('git rev-list --count %BRANCH2%..%BRANCH1% 2^>nul') do echo %%i commits
    echo.
    echo Commit count in %BRANCH2% not in %BRANCH1%:
    for /f %%i in ('git rev-list --count %BRANCH1%..%BRANCH2% 2^>nul') do echo %%i commits
    echo.
    
) else if "%COMPARE_TYPE%"=="7" (
    echo Operation cancelled.
    pause
    exit /b 0
    
) else (
    echo Invalid choice.
    pause
    exit /b 1
)

echo ========================================
echo.
set /p "MERGE_NOW=Merge %BRANCH2% into %BRANCH1%? (Y/N): "
if /i "%MERGE_NOW%"=="Y" (
    if not "%CURRENT_BRANCH%"=="%BRANCH1%" (
        echo Switching to %BRANCH1%...
        git checkout %BRANCH1%
    )
    echo Merging %BRANCH2% into %BRANCH1%...
    git merge %BRANCH2%
    if errorlevel 1 (
        echo ERROR: Merge failed. Please resolve conflicts.
    ) else (
        echo Merge successful!
    )
)

echo.
pause
