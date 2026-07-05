@echo off
setlocal enabledelayedexpansion

echo ========================================
echo    GitHub Repository Initializer
echo ========================================
echo.

REM Get parent folder name as default repo name
for %%I in ("%~dp0..") do set "PROJECT_NAME=%%~nxI"
echo Detected project name: %PROJECT_NAME%
echo.

REM Ask for repository name
set /p "REPO_NAME=Enter repository name (press Enter for '%PROJECT_NAME%'): "
if "%REPO_NAME%"=="" set "REPO_NAME=%PROJECT_NAME%"

echo.
echo Select repository visibility:
echo [1] Public
echo [2] Private
set /p "VISIBILITY_CHOICE=Enter choice (1 or 2): "

if "%VISIBILITY_CHOICE%"=="1" (
    set "VISIBILITY=public"
) else if "%VISIBILITY_CHOICE%"=="2" (
    set "VISIBILITY=private"
) else (
    echo Invalid choice. Defaulting to private.
    set "VISIBILITY=private"
)

echo.
echo Creating %VISIBILITY% repository: %REPO_NAME%
echo.

REM Navigate to project root (parent of scripts-deploy)
cd /d "%~dp0.."

REM Check if git is initialized
if not exist ".git" (
    echo Initializing Git repository...
    git init
    if errorlevel 1 (
        echo ERROR: Failed to initialize Git repository
        pause
        exit /b 1
    )
    echo Git repository initialized successfully!
    echo.
)

REM Create .gitignore if it doesn't exist
if not exist ".gitignore" (
    echo Creating .gitignore...
    (
        echo node_modules/
        echo .env
        echo .env.local
        echo dist/
        echo build/
        echo *.log
        echo .DS_Store
        echo Thumbs.db
        echo *.swp
        echo *.swo
        echo *~
    ) > .gitignore
)

REM Check if GitHub CLI is installed
set "GH_INSTALLED=0"
gh --version >nul 2>&1
if not errorlevel 1 set "GH_INSTALLED=1"

if "%GH_INSTALLED%"=="0" (
    echo.
    echo ========================================
    echo ⚠️ GitHub CLI is NOT installed
    echo ========================================
    echo.
    echo OPTION 1: Create repository manually (Recommended)
    echo   1. Go to: https://github.com/new
    echo   2. Create a %VISIBILITY% repository named: %REPO_NAME%
    echo   3. Copy the repository URL
    echo   4. Paste it below
    echo.
    echo OPTION 2: Install GitHub CLI
    echo   Download from: https://cli.github.com/
    echo   Then run this script again
    echo.
    echo ========================================
    echo.
    echo Opening GitHub in browser to create repository...
    start https://github.com/new
    echo.
    set /p "MANUAL_URL=Enter GitHub repository URL (or press Enter to skip): "
    if not "!MANUAL_URL!"=="" (
        echo.
        echo Adding remote origin...
        git remote add origin !MANUAL_URL! 2>nul
        if errorlevel 1 (
            echo Updating existing remote origin...
            git remote set-url origin !MANUAL_URL!
        )
        echo.
        echo ✓ Remote origin set to: !MANUAL_URL!
        echo.
        echo Now committing and pushing initial files...
        git add .
        git commit -m "Initial commit"
        echo.
        echo Pushing to GitHub...
        git branch -M main
        git push -u origin main
        if errorlevel 1 (
            echo.
            echo ⚠️ Push failed. You may need to authenticate.
            echo Try running: git push -u origin main
            echo.
        ) else (
            echo.
            echo ✓ Repository initialized and pushed successfully!
            echo.
        )
        pause
        exit /b 0
    ) else (
        echo.
        echo Repository initialization incomplete.
        echo Please create a repository on GitHub and run this script again.
        echo.
        pause
        exit /b 1
    )
)

REM Check if user is logged in to GitHub CLI
echo Checking GitHub CLI authentication...
gh auth status >nul 2>&1
if errorlevel 1 (
    echo.
    echo You are not logged in to GitHub CLI.
    echo Opening browser for authentication...
    gh auth login
    if errorlevel 1 (
        echo ERROR: GitHub authentication failed
        pause
        exit /b 1
    )
)

REM Create repository using GitHub CLI
echo.
echo Creating repository on GitHub...
gh repo create %REPO_NAME% --%VISIBILITY% --source=. --remote=origin
if errorlevel 1 (
    echo.
    echo ERROR: Failed to create repository
    echo The repository might already exist or there was a network issue.
    echo.
    set /p "MANUAL_URL=Enter existing repository URL (or press Enter to cancel): "
    if not "!MANUAL_URL!"=="" (
        git remote add origin !MANUAL_URL! 2>nul
        if errorlevel 1 (
            git remote set-url origin !MANUAL_URL!
        )
        echo Remote origin set to: !MANUAL_URL!
    ) else (
        pause
        exit /b 1
    )
) else (
    echo.
    echo ========================================
    echo Repository created successfully!
    echo ========================================
)

REM Get repository URL
for /f "delims=" %%i in ('gh repo view --json url -q .url 2^>nul') do set "REPO_URL=%%i"
if "%REPO_URL%"=="" (
    for /f "delims=" %%i in ('git remote get-url origin 2^>nul') do set "REPO_URL=%%i"
)

if not "%REPO_URL%"=="" (
    echo.
    echo Repository URL: %REPO_URL%
    echo.
)

REM Initial commit
echo Performing initial commit...
git add .
git commit -m "Initial commit - Repository setup" >nul 2>&1

REM Get default branch name
for /f "delims=" %%i in ('git branch --show-current 2^>nul') do set "CURRENT_BRANCH=%%i"
if "%CURRENT_BRANCH%"=="" set "CURRENT_BRANCH=main"

echo Pushing to remote repository...
git push -u origin %CURRENT_BRANCH%
if errorlevel 1 (
    echo.
    echo WARNING: Push failed. Trying to set upstream and push again...
    git branch -M main
    git push -u origin main
    if errorlevel 1 (
        echo.
        echo ERROR: Failed to push to remote repository
        echo Please check your internet connection and try again.
        pause
        exit /b 1
    )
)

echo.
echo ========================================
echo Repository initialized and pushed successfully!
echo ========================================
echo.
if not "%REPO_URL%"=="" (
    echo View your repository at: %REPO_URL%
)
echo.
pause
