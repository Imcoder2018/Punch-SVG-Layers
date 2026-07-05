@echo off
setlocal enabledelayedexpansion

echo ========================================
echo    Deploy to Development
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

REM Show current status
echo Current changes:
git status --short
echo.

REM Get commit message from user
set /p "COMMIT_MSG=Enter commit message for development: "

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

echo Committing with message: [DEV] %COMMIT_MSG%
git commit -m "[DEV] %COMMIT_MSG%"
if errorlevel 1 (
    echo.
    echo No changes to commit or commit failed.
    set /p "PUSH_ANYWAY=Do you want to push anyway? (Y/N): "
    if /i not "!PUSH_ANYWAY!"=="Y" (
        pause
        exit /b 0
    )
)

REM Check if development branch exists
echo.
echo Checking for development branch...
git show-ref --verify --quiet refs/heads/development
if errorlevel 1 (
    echo Development branch does not exist.
    set /p "CREATE_DEV=Create development branch? (Y/N): "
    if /i "!CREATE_DEV!"=="Y" (
        echo Creating development branch...
        git checkout -b development
        if errorlevel 1 (
            echo ERROR: Failed to create development branch
            pause
            exit /b 1
        )
    ) else (
        echo Continuing with current branch: %CURRENT_BRANCH%
    )
) else (
    REM Ask if user wants to switch to development branch
    if not "%CURRENT_BRANCH%"=="development" (
        set /p "SWITCH_DEV=Switch to development branch? (Y/N): "
        if /i "!SWITCH_DEV!"=="Y" (
            echo Switching to development branch...
            git checkout development
            if errorlevel 1 (
                echo ERROR: Failed to switch to development branch
                pause
                exit /b 1
            )
            
            echo Merging changes from %CURRENT_BRANCH%...
            git merge %CURRENT_BRANCH% --no-edit
            if errorlevel 1 (
                echo.
                echo WARNING: Merge conflicts detected
                echo Please resolve conflicts and run this script again
                pause
                exit /b 1
            )
        )
    )
)

REM Get current branch again (might have changed)
for /f "delims=" %%i in ('git branch --show-current 2^>nul') do set "CURRENT_BRANCH=%%i"

echo.
echo Pushing to remote (%CURRENT_BRANCH%)...
git push -u origin %CURRENT_BRANCH%
if errorlevel 1 (
    echo.
    echo ERROR: Failed to push to remote
    echo Please check your internet connection and remote configuration.
    pause
    exit /b 1
)

echo.
echo ========================================
echo Deployed to development successfully!
echo Branch: %CURRENT_BRANCH%
echo ========================================
echo.
pause
