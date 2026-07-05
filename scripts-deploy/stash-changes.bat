@echo off
setlocal enabledelayedexpansion

echo ========================================
echo    Stash Changes Manager
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

echo Current stashes:
echo.
git stash list
echo.

echo Select action:
echo.
echo [1] Stash current changes
echo [2] Stash with message
echo [3] Apply latest stash (keep in list)
echo [4] Pop latest stash (remove from list)
echo [5] Apply specific stash
echo [6] Drop specific stash
echo [7] Clear all stashes
echo [8] Show stash contents
echo [9] Cancel
echo.
set /p "STASH_ACTION=Enter choice (1-9): "

if "%STASH_ACTION%"=="1" (
    echo.
    echo Stashing changes...
    git stash push
    if errorlevel 1 (
        echo ERROR: Failed to stash changes
        echo Make sure you have changes to stash
    ) else (
        echo Changes stashed successfully!
        echo.
        git stash list
    )
    
) else if "%STASH_ACTION%"=="2" (
    echo.
    set /p "STASH_MSG=Enter stash message: "
    if "!STASH_MSG!"=="" (
        echo ERROR: Message cannot be empty
    ) else (
        echo Stashing changes with message...
        git stash push -m "!STASH_MSG!"
        if errorlevel 1 (
            echo ERROR: Failed to stash changes
        ) else (
            echo Changes stashed successfully!
            echo.
            git stash list
        )
    )
    
) else if "%STASH_ACTION%"=="3" (
    echo.
    echo Applying latest stash...
    git stash apply
    if errorlevel 1 (
        echo ERROR: Failed to apply stash
        echo There might be conflicts or no stashes available
    ) else (
        echo Stash applied successfully!
        echo Note: Stash is still in the list
    )
    
) else if "%STASH_ACTION%"=="4" (
    echo.
    echo Popping latest stash...
    git stash pop
    if errorlevel 1 (
        echo ERROR: Failed to pop stash
        echo There might be conflicts or no stashes available
    ) else (
        echo Stash popped successfully!
        echo Note: Stash has been removed from the list
    )
    
) else if "%STASH_ACTION%"=="5" (
    echo.
    git stash list
    echo.
    set /p "STASH_INDEX=Enter stash index (e.g., 0 for stash@{0}): "
    if "!STASH_INDEX!"=="" (
        echo ERROR: Index cannot be empty
    ) else (
        echo Applying stash@{!STASH_INDEX!}...
        git stash apply stash@{!STASH_INDEX!}
        if errorlevel 1 (
            echo ERROR: Failed to apply stash
        ) else (
            echo Stash applied successfully!
        )
    )
    
) else if "%STASH_ACTION%"=="6" (
    echo.
    git stash list
    echo.
    set /p "STASH_INDEX=Enter stash index to drop (e.g., 0 for stash@{0}): "
    if "!STASH_INDEX!"=="" (
        echo ERROR: Index cannot be empty
    ) else (
        set /p "CONFIRM=Are you sure you want to drop stash@{!STASH_INDEX!}? (Y/N): "
        if /i "!CONFIRM!"=="Y" (
            git stash drop stash@{!STASH_INDEX!}
            if errorlevel 1 (
                echo ERROR: Failed to drop stash
            ) else (
                echo Stash dropped successfully!
            )
        ) else (
            echo Operation cancelled.
        )
    )
    
) else if "%STASH_ACTION%"=="7" (
    echo.
    echo WARNING: This will delete ALL stashes!
    set /p "CONFIRM=Type 'DELETE' to confirm: "
    if "!CONFIRM!"=="DELETE" (
        git stash clear
        echo All stashes cleared.
    ) else (
        echo Operation cancelled.
    )
    
) else if "%STASH_ACTION%"=="8" (
    echo.
    git stash list
    echo.
    set /p "STASH_INDEX=Enter stash index to view (e.g., 0 for stash@{0}): "
    if "!STASH_INDEX!"=="" (
        set "STASH_INDEX=0"
    )
    echo.
    echo Contents of stash@{!STASH_INDEX!}:
    echo ========================================
    git stash show -p stash@{!STASH_INDEX!}
    
) else if "%STASH_ACTION%"=="9" (
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
