@echo off
setlocal enabledelayedexpansion

echo ========================================
echo    Undo Last Commit
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

REM Show last 5 commits
echo Last 5 commits:
echo.
git log --oneline -5
echo.

REM Check if there are any commits
git rev-parse HEAD >nul 2>&1
if errorlevel 1 (
    echo ERROR: No commits found in repository
    pause
    exit /b 1
)

echo Select undo method:
echo.
echo [1] Soft reset - Undo commit, keep changes staged
echo [2] Mixed reset - Undo commit, keep changes unstaged (default)
echo [3] Hard reset - Undo commit, discard all changes (DANGEROUS!)
echo [4] Revert - Create new commit that undoes changes (safe for pushed commits)
echo [5] Cancel
echo.
set /p "UNDO_METHOD=Enter choice (1-5): "

if "%UNDO_METHOD%"=="" set "UNDO_METHOD=2"

if "%UNDO_METHOD%"=="1" (
    echo.
    echo Performing soft reset...
    echo This will undo the last commit but keep changes staged.
    echo.
    set /p "CONFIRM=Continue? (Y/N): "
    if /i "!CONFIRM!"=="Y" (
        git reset --soft HEAD~1
        if errorlevel 1 (
            echo ERROR: Reset failed
            pause
            exit /b 1
        )
        echo.
        echo Commit undone. Changes are still staged.
        git status --short
    ) else (
        echo Operation cancelled.
    )
    
) else if "%UNDO_METHOD%"=="2" (
    echo.
    echo Performing mixed reset...
    echo This will undo the last commit and unstage changes.
    echo.
    set /p "CONFIRM=Continue? (Y/N): "
    if /i "!CONFIRM!"=="Y" (
        git reset HEAD~1
        if errorlevel 1 (
            echo ERROR: Reset failed
            pause
            exit /b 1
        )
        echo.
        echo Commit undone. Changes are unstaged.
        git status --short
    ) else (
        echo Operation cancelled.
    )
    
) else if "%UNDO_METHOD%"=="3" (
    echo.
    echo WARNING: This will PERMANENTLY DELETE all changes!
    echo This action CANNOT be undone!
    echo.
    set /p "CONFIRM=Type 'DELETE' to confirm: "
    if "!CONFIRM!"=="DELETE" (
        git reset --hard HEAD~1
        if errorlevel 1 (
            echo ERROR: Reset failed
            pause
            exit /b 1
        )
        echo.
        echo Commit and all changes have been discarded.
    ) else (
        echo Operation cancelled.
    )
    
) else if "%UNDO_METHOD%"=="4" (
    echo.
    echo Performing revert...
    echo This will create a new commit that undoes the last commit.
    echo This is safe for commits that have already been pushed.
    echo.
    set /p "CONFIRM=Continue? (Y/N): "
    if /i "!CONFIRM!"=="Y" (
        git revert HEAD --no-edit
        if errorlevel 1 (
            echo.
            echo ERROR: Revert failed
            echo This might be due to conflicts.
            echo.
            echo To resolve:
            echo 1. Resolve conflicts in affected files
            echo 2. Run: git add ^<filename^>
            echo 3. Run: git revert --continue
            echo.
            echo Or to abort:
            echo   git revert --abort
            pause
            exit /b 1
        )
        echo.
        echo Revert commit created successfully.
        echo.
        set /p "PUSH_NOW=Push revert to remote? (Y/N): "
        if /i "!PUSH_NOW!"=="Y" (
            git push
            if errorlevel 1 (
                echo WARNING: Failed to push to remote
            ) else (
                echo Changes pushed successfully!
            )
        )
    ) else (
        echo Operation cancelled.
    )
    
) else if "%UNDO_METHOD%"=="5" (
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
echo Current status:
echo ========================================
git status --short
echo.
pause
