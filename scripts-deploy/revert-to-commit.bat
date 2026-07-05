@echo off
setlocal enabledelayedexpansion

echo ========================================
echo    Revert Project to Past Commit
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

REM Check for uncommitted changes
git diff --quiet
set "HAS_CHANGES=0"
if errorlevel 1 set "HAS_CHANGES=1"

git diff --cached --quiet
if errorlevel 1 set "HAS_CHANGES=1"

if "%HAS_CHANGES%"=="1" (
    echo WARNING: You have uncommitted changes!
    echo.
    git status --short
    echo.
    echo These changes will be lost if you continue!
    echo.
    set /p "STASH_FIRST=Stash changes before reverting? (Y/N): "
    if /i "!STASH_FIRST!"=="Y" (
        echo Stashing changes...
        git stash push -m "Auto-stash before revert to commit"
        if errorlevel 1 (
            echo ERROR: Failed to stash changes
            pause
            exit /b 1
        )
        set "STASHED=1"
        echo Changes stashed successfully.
        echo.
    ) else (
        echo.
        echo WARNING: Uncommitted changes will be LOST!
        set /p "CONTINUE_ANYWAY=Type 'CONTINUE' to proceed: "
        if not "!CONTINUE_ANYWAY!"=="CONTINUE" (
            echo Operation cancelled.
            pause
            exit /b 0
        )
    )
)

echo.
echo ========================================
echo Recent Commits (Last 20):
echo ========================================
echo.
git log --oneline -20
echo.

echo ========================================
echo Select Revert Method:
echo ========================================
echo.
echo [1] Hard Reset - DANGEROUS! Completely revert to commit (loses all changes after)
echo [2] Soft Reset - Revert commits but keep all changes staged
echo [3] Mixed Reset - Revert commits but keep changes unstaged
echo [4] Create Revert Commit - Safe for pushed commits (creates new commit)
echo [5] View specific commit details
echo [6] Search commits by message
echo [7] Cancel
echo.
set /p "METHOD=Enter choice (1-7): "

if "%METHOD%"=="5" (
    echo.
    set /p "COMMIT_HASH=Enter commit hash to view: "
    if "!COMMIT_HASH!"=="" (
        echo ERROR: Commit hash cannot be empty
        pause
        exit /b 1
    )
    echo.
    echo Commit details:
    echo ========================================
    git show !COMMIT_HASH!
    echo.
    echo ========================================
    pause
    REM Return to menu
    call "%~0"
    exit /b 0
    
) else if "%METHOD%"=="6" (
    echo.
    set /p "SEARCH_TERM=Enter search term: "
    if "!SEARCH_TERM!"=="" (
        echo ERROR: Search term cannot be empty
        pause
        exit /b 1
    )
    echo.
    echo Matching commits:
    echo ========================================
    git log --oneline --grep="!SEARCH_TERM!"
    echo.
    echo ========================================
    pause
    REM Return to menu
    call "%~0"
    exit /b 0
    
) else if "%METHOD%"=="7" (
    echo Operation cancelled.
    if "%STASHED%"=="1" (
        echo.
        set /p "RESTORE=Restore stashed changes? (Y/N): "
        if /i "!RESTORE!"=="Y" (
            git stash pop
        )
    )
    pause
    exit /b 0
)

echo.
set /p "COMMIT_HASH=Enter commit hash to revert to: "

if "%COMMIT_HASH%"=="" (
    echo ERROR: Commit hash cannot be empty
    pause
    exit /b 1
)

REM Verify commit exists
git cat-file -e %COMMIT_HASH% 2>nul
if errorlevel 1 (
    echo ERROR: Commit '%COMMIT_HASH%' not found
    echo Please check the commit hash and try again
    pause
    exit /b 1
)

echo.
echo You are about to revert to commit: %COMMIT_HASH%
echo.
git log --oneline -1 %COMMIT_HASH%
echo.

if "%METHOD%"=="1" (
    echo ========================================
    echo HARD RESET - EXTREME DANGER!
    echo ========================================
    echo.
    echo This will:
    echo - DELETE all commits after %COMMIT_HASH%
    echo - DELETE all uncommitted changes
    echo - CANNOT be undone easily
    echo.
    echo Your entire project will be reverted to the state at this commit.
    echo.
    set /p "CONFIRM1=Type 'I UNDERSTAND' to continue: "
    if not "!CONFIRM1!"=="I UNDERSTAND" (
        echo Operation cancelled.
        pause
        exit /b 0
    )
    echo.
    set /p "CONFIRM2=Type the commit hash again to confirm: "
    if not "!CONFIRM2!"=="%COMMIT_HASH%" (
        echo Commit hash mismatch. Operation cancelled.
        pause
        exit /b 0
    )
    
    echo.
    echo Performing hard reset to %COMMIT_HASH%...
    git reset --hard %COMMIT_HASH%
    if errorlevel 1 (
        echo ERROR: Hard reset failed
        pause
        exit /b 1
    )
    
    echo.
    echo ========================================
    echo Project reverted successfully!
    echo ========================================
    echo.
    echo Your project is now at commit: %COMMIT_HASH%
    echo.
    
    set /p "FORCE_PUSH=Force push to remote? (WARNING: Affects everyone!) (Y/N): "
    if /i "!FORCE_PUSH!"=="Y" (
        echo.
        set /p "FINAL_CONFIRM=Type 'FORCE PUSH' to confirm: "
        if "!FINAL_CONFIRM!"=="FORCE PUSH" (
            echo Force pushing to remote...
            git push --force origin %CURRENT_BRANCH%
            if errorlevel 1 (
                echo WARNING: Force push failed
                echo You may need to push manually: git push --force origin %CURRENT_BRANCH%
            ) else (
                echo Force push successful!
            )
        ) else (
            echo Force push cancelled.
        )
    )
    
) else if "%METHOD%"=="2" (
    echo.
    echo Performing soft reset to %COMMIT_HASH%...
    echo This will keep all changes staged.
    echo.
    set /p "CONFIRM=Continue? (Y/N): "
    if /i not "!CONFIRM!"=="Y" (
        echo Operation cancelled.
        pause
        exit /b 0
    )
    
    git reset --soft %COMMIT_HASH%
    if errorlevel 1 (
        echo ERROR: Soft reset failed
        pause
        exit /b 1
    )
    
    echo.
    echo ========================================
    echo Soft reset successful!
    echo ========================================
    echo.
    echo Commits have been undone, but changes are still staged.
    echo You can now review and recommit the changes.
    echo.
    git status --short
    
) else if "%METHOD%"=="3" (
    echo.
    echo Performing mixed reset to %COMMIT_HASH%...
    echo This will keep all changes unstaged.
    echo.
    set /p "CONFIRM=Continue? (Y/N): "
    if /i not "!CONFIRM!"=="Y" (
        echo Operation cancelled.
        pause
        exit /b 0
    )
    
    git reset %COMMIT_HASH%
    if errorlevel 1 (
        echo ERROR: Mixed reset failed
        pause
        exit /b 1
    )
    
    echo.
    echo ========================================
    echo Mixed reset successful!
    echo ========================================
    echo.
    echo Commits have been undone, changes are unstaged.
    echo You can now review and selectively commit changes.
    echo.
    git status --short
    
) else if "%METHOD%"=="4" (
    echo.
    echo Creating revert commit...
    echo This is SAFE for commits that have been pushed.
    echo.
    set /p "CONFIRM=Continue? (Y/N): "
    if /i not "!CONFIRM!"=="Y" (
        echo Operation cancelled.
        pause
        exit /b 0
    )
    
    REM Get current commit
    for /f "delims=" %%i in ('git rev-parse HEAD 2^>nul') do set "CURRENT_COMMIT=%%i"
    
    REM Revert range of commits
    echo Reverting commits from %COMMIT_HASH% to %CURRENT_COMMIT%...
    git revert --no-commit %COMMIT_HASH%..HEAD
    if errorlevel 1 (
        echo.
        echo ERROR: Revert failed
        echo This might be due to conflicts.
        echo.
        echo To resolve:
        echo 1. Resolve conflicts in affected files
        echo 2. Run: git add ^<resolved files^>
        echo 3. Run: git revert --continue
        echo.
        echo Or to abort:
        echo   git revert --abort
        pause
        exit /b 1
    )
    
    echo.
    set /p "REVERT_MSG=Enter revert commit message (or press Enter for default): "
    if "!REVERT_MSG!"=="" (
        set "REVERT_MSG=Revert project to commit %COMMIT_HASH%"
    )
    
    git commit -m "!REVERT_MSG!"
    if errorlevel 1 (
        echo ERROR: Failed to create revert commit
        pause
        exit /b 1
    )
    
    echo.
    echo ========================================
    echo Revert commit created successfully!
    echo ========================================
    echo.
    
    set /p "PUSH_NOW=Push revert to remote? (Y/N): "
    if /i "!PUSH_NOW!"=="Y" (
        git push
        if errorlevel 1 (
            echo WARNING: Push failed
        ) else (
            echo Push successful!
        )
    )
    
) else (
    echo Invalid choice.
    pause
    exit /b 1
)

REM Restore stashed changes if any
if "%STASHED%"=="1" (
    echo.
    set /p "RESTORE_STASH=Restore stashed changes? (Y/N): "
    if /i "!RESTORE_STASH!"=="Y" (
        echo Restoring stashed changes...
        git stash pop
        if errorlevel 1 (
            echo WARNING: Conflicts occurred while restoring stash
            echo Please resolve conflicts manually
        ) else (
            echo Stashed changes restored successfully.
        )
    ) else (
        echo Stashed changes kept in stash list.
        echo Use stash-changes.bat to manage them.
    )
)

echo.
echo ========================================
echo Current project state:
echo ========================================
git log --oneline -5
echo.
echo ========================================
echo.
pause
