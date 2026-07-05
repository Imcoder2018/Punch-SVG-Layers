@echo off
setlocal enabledelayedexpansion

echo ========================================
echo    Delete Branch
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

echo Available local branches:
echo.
git branch
echo.

echo Select deletion type:
echo [1] Delete local branch
echo [2] Delete remote branch
echo [3] Delete both local and remote branch
echo [4] Cancel
echo.
set /p "DELETE_TYPE=Enter choice (1-4): "

if "%DELETE_TYPE%"=="4" (
    echo Operation cancelled.
    pause
    exit /b 0
)

echo.
set /p "BRANCH_NAME=Enter branch name to delete: "

if "%BRANCH_NAME%"=="" (
    echo ERROR: Branch name cannot be empty
    pause
    exit /b 1
)

REM Check if trying to delete current branch
if "%BRANCH_NAME%"=="%CURRENT_BRANCH%" (
    echo ERROR: Cannot delete the currently checked out branch
    echo Please switch to a different branch first
    pause
    exit /b 1
)

REM Protect main branches
if "%BRANCH_NAME%"=="main" (
    echo WARNING: You are about to delete the main branch!
    set /p "CONFIRM_MAIN=Type 'DELETE MAIN' to confirm: "
    if not "!CONFIRM_MAIN!"=="DELETE MAIN" (
        echo Operation cancelled.
        pause
        exit /b 0
    )
)

if "%BRANCH_NAME%"=="master" (
    echo WARNING: You are about to delete the master branch!
    set /p "CONFIRM_MASTER=Type 'DELETE MASTER' to confirm: "
    if not "!CONFIRM_MASTER!"=="DELETE MASTER" (
        echo Operation cancelled.
        pause
        exit /b 0
    )
)

if "%DELETE_TYPE%"=="1" (
    REM Delete local branch
    echo.
    echo Deleting local branch: %BRANCH_NAME%
    
    REM Check if branch exists locally
    git show-ref --verify --quiet refs/heads/%BRANCH_NAME%
    if errorlevel 1 (
        echo ERROR: Branch '%BRANCH_NAME%' does not exist locally
        pause
        exit /b 1
    )
    
    REM Check if branch has unmerged changes
    git branch --merged | find "%BRANCH_NAME%" >nul
    if errorlevel 1 (
        echo WARNING: Branch has unmerged changes
        set /p "FORCE_DELETE=Force delete anyway? (Y/N): "
        if /i "!FORCE_DELETE!"=="Y" (
            git branch -D %BRANCH_NAME%
        ) else (
            echo Operation cancelled.
            pause
            exit /b 0
        )
    ) else (
        git branch -d %BRANCH_NAME%
    )
    
    if errorlevel 1 (
        echo ERROR: Failed to delete local branch
        pause
        exit /b 1
    )
    
    echo Local branch deleted successfully!
    
) else if "%DELETE_TYPE%"=="2" (
    REM Delete remote branch
    echo.
    echo Deleting remote branch: %BRANCH_NAME%
    echo.
    set /p "CONFIRM_REMOTE=Are you sure? This affects the remote repository! (Y/N): "
    if /i not "!CONFIRM_REMOTE!"=="Y" (
        echo Operation cancelled.
        pause
        exit /b 0
    )
    
    git push origin --delete %BRANCH_NAME%
    if errorlevel 1 (
        echo ERROR: Failed to delete remote branch
        echo The branch might not exist on remote or you lack permissions
        pause
        exit /b 1
    )
    
    echo Remote branch deleted successfully!
    
) else if "%DELETE_TYPE%"=="3" (
    REM Delete both local and remote branch
    echo.
    echo Deleting both local and remote branch: %BRANCH_NAME%
    echo.
    set /p "CONFIRM_BOTH=Are you sure? This affects local and remote! (Y/N): "
    if /i not "!CONFIRM_BOTH!"=="Y" (
        echo Operation cancelled.
        pause
        exit /b 0
    )
    
    REM Delete local branch
    git show-ref --verify --quiet refs/heads/%BRANCH_NAME%
    if not errorlevel 1 (
        echo Deleting local branch...
        git branch --merged | find "%BRANCH_NAME%" >nul
        if errorlevel 1 (
            git branch -D %BRANCH_NAME%
        ) else (
            git branch -d %BRANCH_NAME%
        )
        
        if errorlevel 1 (
            echo WARNING: Failed to delete local branch
        ) else (
            echo Local branch deleted successfully!
        )
    ) else (
        echo Branch does not exist locally.
    )
    
    REM Delete remote branch
    echo.
    echo Deleting remote branch...
    git push origin --delete %BRANCH_NAME% 2>nul
    if errorlevel 1 (
        echo WARNING: Failed to delete remote branch or it doesn't exist
    ) else (
        echo Remote branch deleted successfully!
    )
    
) else (
    echo Invalid choice.
    pause
    exit /b 1
)

echo.
echo ========================================
echo Branch deletion completed!
echo ========================================
echo.
echo Remaining local branches:
git branch
echo.
pause
