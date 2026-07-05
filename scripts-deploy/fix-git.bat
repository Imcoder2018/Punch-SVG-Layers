@echo off
setlocal enabledelayedexpansion

echo ========================================
echo    Fix Git Connectivity Issues
echo ========================================
echo.

REM Navigate to project root
cd /d "%~dp0.."

echo Diagnosing Git issues...
echo.

REM Check if git is installed
git --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Git is not installed or not in PATH
    echo Please install Git from: https://git-scm.com/downloads
    pause
    exit /b 1
)

echo Git version:
git --version
echo.

REM Check if git is initialized
if not exist ".git" (
    echo WARNING: Git repository not initialized in this directory
    set /p "INIT_NOW=Initialize Git repository now? (Y/N): "
    if /i "!INIT_NOW!"=="Y" (
        git init
        echo Git repository initialized.
    )
    echo.
)

echo ========================================
echo Select an issue to fix:
echo ========================================
echo.
echo [1] Fix remote connection issues
echo [2] Reset Git credentials
echo [3] Fix SSH key issues
echo [4] Clear Git cache
echo [5] Fix line ending issues
echo [6] Recover from detached HEAD
echo [7] Fix merge conflicts
echo [8] Clean untracked files
echo [9] Repair corrupted repository
echo [10] Test GitHub connectivity
echo [11] Fix all common issues (recommended)
echo [12] Cancel
echo.
set /p "CHOICE=Enter choice (1-12): "

if "%CHOICE%"=="1" (
    echo.
    echo Fixing remote connection issues...
    echo.
    
    REM Check current remote
    git remote -v
    echo.
    
    set /p "FIX_REMOTE=Do you want to update the remote URL? (Y/N): "
    if /i "!FIX_REMOTE!"=="Y" (
        set /p "NEW_URL=Enter new remote URL: "
        git remote set-url origin !NEW_URL!
        echo Remote URL updated.
    )
    
    echo.
    echo Testing connection...
    git ls-remote origin
    if errorlevel 1 (
        echo ERROR: Cannot connect to remote
        echo Please check your internet connection and remote URL
    ) else (
        echo Connection successful!
    )
    
) else if "%CHOICE%"=="2" (
    echo.
    echo Resetting Git credentials...
    echo.
    
    REM Clear credential cache
    git config --global --unset credential.helper
    git config --system --unset credential.helper
    
    REM Set credential helper
    git config --global credential.helper wincred
    
    echo Credentials reset. You will be prompted for credentials on next push/pull.
    echo.
    
) else if "%CHOICE%"=="3" (
    echo.
    echo Checking SSH configuration...
    echo.
    
    if exist "%USERPROFILE%\.ssh\id_rsa.pub" (
        echo SSH key found at: %USERPROFILE%\.ssh\id_rsa.pub
        echo.
        echo Your public SSH key:
        type "%USERPROFILE%\.ssh\id_rsa.pub"
        echo.
        set /p "OPEN_GITHUB=Open GitHub SSH settings in browser? (Y/N): "
        if /i "!OPEN_GITHUB!"=="Y" (
            start https://github.com/settings/keys
        )
    ) else (
        echo No SSH key found.
        set /p "CREATE_SSH=Create new SSH key? (Y/N): "
        if /i "!CREATE_SSH!"=="Y" (
            set /p "SSH_EMAIL=Enter your email: "
            ssh-keygen -t rsa -b 4096 -C "!SSH_EMAIL!"
            echo.
            echo SSH key created successfully!
            echo.
            echo Your public SSH key:
            type "%USERPROFILE%\.ssh\id_rsa.pub"
            echo.
            echo Please add this key to your GitHub account.
            start https://github.com/settings/keys
        )
    )
    
) else if "%CHOICE%"=="4" (
    echo.
    echo Clearing Git cache...
    echo.
    
    git rm -r --cached . >nul 2>&1
    git add .
    
    echo Git cache cleared and files re-staged.
    
) else if "%CHOICE%"=="5" (
    echo.
    echo Fixing line ending issues...
    echo.
    
    git config --global core.autocrlf true
    echo Configured to automatically handle line endings (Windows style).
    echo.
    
    set /p "NORMALIZE=Normalize all files now? (Y/N): "
    if /i "!NORMALIZE!"=="Y" (
        git add --renormalize .
        echo Files normalized.
    )
    
) else if "%CHOICE%"=="6" (
    echo.
    echo Recovering from detached HEAD state...
    echo.
    
    for /f "delims=" %%i in ('git branch --show-current 2^>nul') do set "CURRENT_BRANCH=%%i"
    
    if "!CURRENT_BRANCH!"=="" (
        echo You are in detached HEAD state.
        echo.
        set /p "BRANCH_NAME=Enter branch name to create/switch to (or 'main' for default): "
        if "!BRANCH_NAME!"=="" set "BRANCH_NAME=main"
        
        git checkout -b !BRANCH_NAME!
        if errorlevel 1 (
            git checkout !BRANCH_NAME!
        )
        echo Recovered to branch: !BRANCH_NAME!
    ) else (
        echo Not in detached HEAD state. Current branch: !CURRENT_BRANCH!
    )
    
) else if "%CHOICE%"=="7" (
    echo.
    echo Checking for merge conflicts...
    echo.
    
    git status | find "both modified" >nul
    if not errorlevel 1 (
        echo Merge conflicts detected:
        echo.
        git status --short
        echo.
        echo To resolve:
        echo 1. Open conflicted files and resolve conflicts
        echo 2. Run: git add ^<filename^>
        echo 3. Run: git commit
        echo.
        set /p "ABORT_MERGE=Abort merge and return to previous state? (Y/N): "
        if /i "!ABORT_MERGE!"=="Y" (
            git merge --abort
            echo Merge aborted.
        )
    ) else (
        echo No merge conflicts detected.
    )
    
) else if "%CHOICE%"=="8" (
    echo.
    echo Untracked files:
    git clean -n
    echo.
    set /p "CLEAN_CONFIRM=Delete these files? (Y/N): "
    if /i "!CLEAN_CONFIRM!"=="Y" (
        git clean -fd
        echo Untracked files removed.
    )
    
) else if "%CHOICE%"=="9" (
    echo.
    echo WARNING: This will attempt to repair repository corruption.
    set /p "REPAIR_CONFIRM=Continue? (Y/N): "
    if /i "!REPAIR_CONFIRM!"=="Y" (
        echo Verifying repository...
        git fsck
        echo.
        echo Running garbage collection...
        git gc --prune=now
        echo.
        echo Repository repair completed.
    )
    
) else if "%CHOICE%"=="10" (
    echo.
    echo Testing GitHub connectivity...
    echo.
    
    echo Testing HTTPS connection...
    git ls-remote https://github.com/github/gitignore.git HEAD >nul 2>&1
    if errorlevel 1 (
        echo HTTPS connection: FAILED
    ) else (
        echo HTTPS connection: SUCCESS
    )
    echo.
    
    echo Testing SSH connection...
    ssh -T git@github.com 2>&1 | find "successfully authenticated" >nul
    if errorlevel 1 (
        echo SSH connection: FAILED or not configured
    ) else (
        echo SSH connection: SUCCESS
    )
    echo.
    
) else if "%CHOICE%"=="11" (
    echo.
    echo Running comprehensive fix...
    echo.
    
    echo [1/6] Configuring line endings...
    git config --global core.autocrlf true
    
    echo [2/6] Setting credential helper...
    git config --global credential.helper wincred
    
    echo [3/6] Clearing cache...
    git rm -r --cached . >nul 2>&1
    git add . >nul 2>&1
    
    echo [4/6] Running garbage collection...
    git gc --prune=now >nul 2>&1
    
    echo [5/6] Verifying repository...
    git fsck >nul 2>&1
    
    echo [6/6] Testing connection...
    git ls-remote origin >nul 2>&1
    if errorlevel 1 (
        echo WARNING: Cannot connect to remote
    ) else (
        echo Remote connection: OK
    )
    
    echo.
    echo All fixes applied!
    
) else if "%CHOICE%"=="12" (
    echo Operation cancelled.
    pause
    exit /b 0
    
) else (
    echo Invalid choice.
    pause
    exit /b 1
)

echo.
echo ========================================
echo.
pause
