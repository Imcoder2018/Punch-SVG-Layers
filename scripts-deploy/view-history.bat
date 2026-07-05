@echo off
setlocal enabledelayedexpansion

echo ========================================
echo    View Commit History
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

echo Select view option:
echo.
echo [1] Last 10 commits (simple)
echo [2] Last 20 commits (simple)
echo [3] Last 50 commits (simple)
echo [4] All commits (simple)
echo [5] Last 10 commits (detailed)
echo [6] Graphical history (all branches)
echo [7] Search commits by message
echo [8] Search commits by author
echo [9] View commits in date range
echo [10] View file history
echo [11] Cancel
echo.
set /p "VIEW_CHOICE=Enter choice (1-11): "

if "%VIEW_CHOICE%"=="1" (
    echo.
    echo Last 10 commits:
    echo ========================================
    git log --oneline -10
    
) else if "%VIEW_CHOICE%"=="2" (
    echo.
    echo Last 20 commits:
    echo ========================================
    git log --oneline -20
    
) else if "%VIEW_CHOICE%"=="3" (
    echo.
    echo Last 50 commits:
    echo ========================================
    git log --oneline -50
    
) else if "%VIEW_CHOICE%"=="4" (
    echo.
    echo All commits:
    echo ========================================
    git log --oneline
    
) else if "%VIEW_CHOICE%"=="5" (
    echo.
    echo Last 10 commits (detailed):
    echo ========================================
    git log -10 --pretty=format:"%%C(yellow)%%h%%Creset - %%C(cyan)%%an%%Creset, %%C(green)%%ar%%Creset : %%s" --date=relative
    echo.
    echo.
    
) else if "%VIEW_CHOICE%"=="6" (
    echo.
    echo Graphical history (all branches):
    echo ========================================
    git log --all --graph --decorate --oneline -20
    echo.
    echo (Showing last 20 commits from all branches)
    
) else if "%VIEW_CHOICE%"=="7" (
    echo.
    set /p "SEARCH_MSG=Enter search term for commit message: "
    if not "!SEARCH_MSG!"=="" (
        echo.
        echo Commits matching "!SEARCH_MSG!":
        echo ========================================
        git log --oneline --grep="!SEARCH_MSG!"
    ) else (
        echo Search cancelled.
    )
    
) else if "%VIEW_CHOICE%"=="8" (
    echo.
    set /p "SEARCH_AUTHOR=Enter author name: "
    if not "!SEARCH_AUTHOR!"=="" (
        echo.
        echo Commits by "!SEARCH_AUTHOR!":
        echo ========================================
        git log --oneline --author="!SEARCH_AUTHOR!"
    ) else (
        echo Search cancelled.
    )
    
) else if "%VIEW_CHOICE%"=="9" (
    echo.
    echo Enter date range (format: YYYY-MM-DD)
    set /p "START_DATE=Start date: "
    set /p "END_DATE=End date: "
    if not "!START_DATE!"=="" if not "!END_DATE!"=="" (
        echo.
        echo Commits between !START_DATE! and !END_DATE!:
        echo ========================================
        git log --oneline --after="!START_DATE!" --before="!END_DATE!"
    ) else (
        echo Invalid date range.
    )
    
) else if "%VIEW_CHOICE%"=="10" (
    echo.
    set /p "FILE_PATH=Enter file path: "
    if not "!FILE_PATH!"=="" (
        if exist "!FILE_PATH!" (
            echo.
            echo History of !FILE_PATH!:
            echo ========================================
            git log --oneline --follow -- "!FILE_PATH!"
            echo.
            echo.
            set /p "VIEW_CHANGES=View detailed changes for this file? (Y/N): "
            if /i "!VIEW_CHANGES!"=="Y" (
                echo.
                git log -p --follow -- "!FILE_PATH!"
            )
        ) else (
            echo ERROR: File not found
        )
    ) else (
        echo No file specified.
    )
    
) else if "%VIEW_CHOICE%"=="11" (
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
