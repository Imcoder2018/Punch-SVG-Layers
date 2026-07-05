@echo off
setlocal enabledelayedexpansion

echo ========================================
echo    Merge Branch
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
echo This branch will receive the merge.
echo.

REM Check for uncommitted changes
git diff --quiet
set "HAS_CHANGES=0"
if errorlevel 1 set "HAS_CHANGES=1"

git diff --cached --quiet
if errorlevel 1 set "HAS_CHANGES=1"

if "%HAS_CHANGES%"=="1" (
    echo WARNING: You have uncommitted changes!
    echo Please commit or stash your changes before merging.
    echo.
    git status --short
    echo.
    pause
    exit /b 1
)

REM Show available branches
echo Available branches to merge from:
echo.
git branch
echo.

REM Get source branch
set /p "SOURCE_BRANCH=Enter branch name to merge FROM: "

if "%SOURCE_BRANCH%"=="" (
    echo ERROR: Branch name cannot be empty
    pause
    exit /b 1
)

REM Check if source branch exists
git show-ref --verify --quiet refs/heads/%SOURCE_BRANCH%
if errorlevel 1 (
    echo ERROR: Branch '%SOURCE_BRANCH%' does not exist
    pause
    exit /b 1
)

REM Check if trying to merge same branch
if "%SOURCE_BRANCH%"=="%CURRENT_BRANCH%" (
    echo ERROR: Cannot merge a branch into itself
    pause
    exit /b 1
)

echo.
echo Merge Strategy:
echo [1] Regular merge (creates merge commit)
echo [2] Squash merge (combines all commits into one)
echo [3] Fast-forward only (fails if not possible)
echo.
set /p "MERGE_STRATEGY=Enter choice (1-3, default=1): "

if "%MERGE_STRATEGY%"=="" set "MERGE_STRATEGY=1"

echo.
echo You are about to merge:
echo   FROM: %SOURCE_BRANCH%
echo   INTO: %CURRENT_BRANCH%
echo.
set /p "CONFIRM=Continue with merge? (Y/N): "

if /i not "%CONFIRM%"=="Y" (
    echo Merge cancelled.
    pause
    exit /b 0
)

echo.
echo Merging %SOURCE_BRANCH% into %CURRENT_BRANCH%...

if "%MERGE_STRATEGY%"=="1" (
    git merge %SOURCE_BRANCH% --no-ff
) else if "%MERGE_STRATEGY%"=="2" (
    git merge %SOURCE_BRANCH% --squash
    if not errorlevel 1 (
        echo.
        set /p "SQUASH_MSG=Enter commit message for squashed merge: "
        if "!SQUASH_MSG!"=="" set "SQUASH_MSG=Merge %SOURCE_BRANCH% into %CURRENT_BRANCH% (squashed)"
        git commit -m "!SQUASH_MSG!"
    )
) else if "%MERGE_STRATEGY%"=="3" (
    git merge %SOURCE_BRANCH% --ff-only
) else (
    echo Invalid merge strategy, using default...
    git merge %SOURCE_BRANCH% --no-ff
)

if errorlevel 1 (
    echo.
    echo ========================================
    echo MERGE CONFLICT DETECTED!
    echo ========================================
    echo.
    echo Conflicted files:
    git status --short | find "both modified"
    echo.
    echo To resolve:
    echo 1. Open each conflicted file
    echo 2. Resolve the conflicts (look for ^<^<^<^<^<^<^< markers)
    echo 3. Run: git add ^<filename^>
    echo 4. Run: git commit
    echo.
    echo Or to abort the merge:
    echo   git merge --abort
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo Merge completed successfully!
echo ========================================
echo.

REM Ask if user wants to push
set /p "PUSH_NOW=Push changes to remote? (Y/N): "
if /i "%PUSH_NOW%"=="Y" (
    echo Pushing to remote...
    git push
    if errorlevel 1 (
        echo WARNING: Failed to push to remote
        echo You can push later using: git push
    ) else (
        echo Changes pushed successfully!
    )
)

echo.
pause
