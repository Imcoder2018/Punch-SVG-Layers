@echo off
setlocal enabledelayedexpansion

echo ========================================
echo    Clone Repository
echo ========================================
echo.

echo Enter repository URL to clone:
echo (Supports HTTPS and SSH URLs)
echo.
set /p "REPO_URL=Repository URL: "

if "%REPO_URL%"=="" (
    echo ERROR: Repository URL cannot be empty
    pause
    exit /b 1
)

echo.
set /p "TARGET_DIR=Enter target directory name (press Enter for auto): "

echo.
echo Clone options:
echo [1] Clone normally
echo [2] Clone with specific branch
echo [3] Shallow clone (latest commit only)
echo [4] Clone with submodules
echo [5] Cancel
echo.
set /p "CLONE_TYPE=Enter choice (1-5): "

if "%CLONE_TYPE%"=="1" (
    echo.
    echo Cloning repository...
    if "%TARGET_DIR%"=="" (
        git clone %REPO_URL%
    ) else (
        git clone %REPO_URL% "%TARGET_DIR%"
    )
    
) else if "%CLONE_TYPE%"=="2" (
    set /p "BRANCH_NAME=Enter branch name: "
    if "!BRANCH_NAME!"=="" (
        echo ERROR: Branch name cannot be empty
        pause
        exit /b 1
    )
    echo.
    echo Cloning repository (branch: !BRANCH_NAME!)...
    if "%TARGET_DIR%"=="" (
        git clone -b !BRANCH_NAME! %REPO_URL%
    ) else (
        git clone -b !BRANCH_NAME! %REPO_URL% "%TARGET_DIR%"
    )
    
) else if "%CLONE_TYPE%"=="3" (
    echo.
    echo Performing shallow clone (latest commit only)...
    if "%TARGET_DIR%"=="" (
        git clone --depth 1 %REPO_URL%
    ) else (
        git clone --depth 1 %REPO_URL% "%TARGET_DIR%"
    )
    
) else if "%CLONE_TYPE%"=="4" (
    echo.
    echo Cloning repository with submodules...
    if "%TARGET_DIR%"=="" (
        git clone --recurse-submodules %REPO_URL%
    ) else (
        git clone --recurse-submodules %REPO_URL% "%TARGET_DIR%"
    )
    
) else if "%CLONE_TYPE%"=="5" (
    echo Operation cancelled.
    pause
    exit /b 0
    
) else (
    echo Invalid choice.
    pause
    exit /b 1
)

if errorlevel 1 (
    echo.
    echo ERROR: Clone failed
    echo Please check:
    echo 1. Repository URL is correct
    echo 2. You have access to the repository
    echo 3. Internet connection is working
    echo 4. Git credentials are configured
    pause
    exit /b 1
)

echo.
echo ========================================
echo Repository cloned successfully!
echo ========================================
echo.

REM Get the cloned directory name
if "%TARGET_DIR%"=="" (
    for %%F in ("%REPO_URL%") do set "REPO_NAME=%%~nF"
    set "REPO_NAME=!REPO_NAME:.git=!"
) else (
    set "REPO_NAME=%TARGET_DIR%"
)

echo Cloned to: !REPO_NAME!
echo.

set /p "OPEN_DIR=Open cloned directory? (Y/N): "
if /i "%OPEN_DIR%"=="Y" (
    if exist "!REPO_NAME!" (
        cd "!REPO_NAME!"
        echo.
        echo Repository information:
        echo.
        git remote -v
        echo.
        git branch -a
        echo.
        start .
    )
)

pause
