@echo off
setlocal enabledelayedexpansion

echo ========================================
echo    Deploy to Production
echo ========================================
echo.
echo WARNING: This will deploy to production!
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

REM Confirm production deployment
set /p "CONFIRM=Are you sure you want to deploy to PRODUCTION? (YES/NO): "
if /i not "%CONFIRM%"=="YES" (
    echo Production deployment cancelled.
    pause
    exit /b 0
)

echo.
REM Show current status
echo Current changes:
git status --short
echo.

REM Get commit message from user
set /p "COMMIT_MSG=Enter commit message for production: "

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

echo Committing with message: [PROD] %COMMIT_MSG%
git commit -m "[PROD] %COMMIT_MSG%"
if errorlevel 1 (
    echo.
    echo No changes to commit or commit failed.
    set /p "PUSH_ANYWAY=Do you want to push anyway? (Y/N): "
    if /i not "!PUSH_ANYWAY!"=="Y" (
        pause
        exit /b 0
    )
)

REM Check if main/master branch exists
echo.
echo Checking for main/master branch...
git show-ref --verify --quiet refs/heads/main
if not errorlevel 1 (
    set "PROD_BRANCH=main"
) else (
    git show-ref --verify --quiet refs/heads/master
    if not errorlevel 1 (
        set "PROD_BRANCH=master"
    ) else (
        echo Neither main nor master branch exists.
        set /p "CREATE_MAIN=Create main branch for production? (Y/N): "
        if /i "!CREATE_MAIN!"=="Y" (
            echo Creating main branch...
            git checkout -b main
            if errorlevel 1 (
                echo ERROR: Failed to create main branch
                pause
                exit /b 1
            )
            set "PROD_BRANCH=main"
        ) else (
            echo Continuing with current branch: %CURRENT_BRANCH%
            set "PROD_BRANCH=%CURRENT_BRANCH%"
        )
    )
)

REM Switch to production branch if needed
if not "%CURRENT_BRANCH%"=="%PROD_BRANCH%" (
    echo.
    echo Switching to %PROD_BRANCH% branch...
    git checkout %PROD_BRANCH%
    if errorlevel 1 (
        echo ERROR: Failed to switch to %PROD_BRANCH% branch
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

echo.
echo Creating production tag...
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set YEAR=%datetime:~0,4%
set MONTH=%datetime:~4,2%
set DAY=%datetime:~6,2%
set HOUR=%datetime:~8,2%
set MINUTE=%datetime:~10,2%

set "TAG_NAME=prod-%YEAR%%MONTH%%DAY%-%HOUR%%MINUTE%"
git tag -a %TAG_NAME% -m "Production release: %COMMIT_MSG%"

echo.
echo Pushing to remote (%PROD_BRANCH%)...
git push -u origin %PROD_BRANCH%
if errorlevel 1 (
    echo.
    echo ERROR: Failed to push to remote
    echo Please check your internet connection and remote configuration.
    pause
    exit /b 1
)

echo Pushing tags...
git push --tags
if errorlevel 1 (
    echo WARNING: Failed to push tags
)

echo.
echo ========================================
echo Deployed to production successfully!
echo Branch: %PROD_BRANCH%
echo Tag: %TAG_NAME%
echo ========================================
echo.
pause
