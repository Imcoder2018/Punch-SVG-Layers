# Troubleshooting Guide

## Common Issues and Solutions

### 🔴 Scripts Closing Immediately Without Showing Output

**Problem:** Batch files close instantly without showing any status or errors.

**Cause:** Missing `pause` commands or errors occurring before pause is reached.

**Solution:**
All scripts have been updated with proper error handling and `pause` commands. If you still experience this:

1. **Run from Command Prompt manually:**
   ```cmd
   cd c:\path\to\your\project\scripts-deploy
   init-repo.bat
   ```
   This will keep the window open and show all errors.

2. **Check if Git is installed:**
   ```cmd
   git --version
   ```
   If this fails, install Git from https://git-scm.com/downloads

3. **Run with explicit pause:**
   ```cmd
   cmd /k init-repo.bat
   ```
   The `/k` flag keeps the window open after execution.

---

### 🔴 change-account.bat Not Doing Anything

**Problem:** Script runs but doesn't change GitHub account or shows no output.

**Root Causes:**

1. **GitHub CLI not installed**
   - Download from: https://cli.github.com/
   - After installing, restart your terminal

2. **Not logged in to GitHub CLI**
   - Run: `gh auth login`
   - Follow browser authentication

3. **GitHub CLI installed but not in PATH**
   - Restart your computer after installing
   - Or add to PATH manually: `C:\Program Files\GitHub CLI\`

**How to verify GitHub CLI:**
```cmd
gh --version
```
Should show: `gh version X.X.X`

**Manual workaround if GitHub CLI not available:**
```cmd
# Configure Git manually:
git config --global user.name "Your Name"
git config --global user.email "your@email.com"

# Login to GitHub in browser:
start https://github.com/login
```

---

### 🔴 init-repo.bat Not Working

**Problem:** Repository initialization fails or script closes immediately.

**Common Causes & Solutions:**

#### 1. Git Not Installed
```cmd
# Check if Git is installed:
git --version

# If not installed, download from:
# https://git-scm.com/downloads
```

#### 2. GitHub CLI Not Installed
The script will prompt you to enter a repository URL manually if GitHub CLI is missing.

**Option A:** Install GitHub CLI
- Download: https://cli.github.com/
- Restart terminal after installation

**Option B:** Create repo manually
1. Go to https://github.com/new
2. Create repository
3. Copy the repository URL
4. Run init-repo.bat and paste URL when prompted

#### 3. Not in Correct Directory
Make sure you're running the script from the `scripts-deploy` folder:
```cmd
cd c:\path\to\your\project\scripts-deploy
init-repo.bat
```

#### 4. Already Initialized
If `.git` folder already exists:
```cmd
# Check current remote:
git remote -v

# If wrong remote, update it:
git remote set-url origin YOUR_REPO_URL
```

#### 5. Network/Authentication Issues
```cmd
# Test GitHub connection:
ping github.com

# Login to GitHub CLI:
gh auth login

# Or configure credentials:
git config --global credential.helper wincred
```

---

### 🔴 All Scripts Close Automatically

**Problem:** Every .bat file closes immediately after running.

**Permanent Fix Applied:**
All scripts now include:
- `pause` at the end
- `pause` before exit on errors
- Error messages displayed before closing

**If still happening:**

1. **Run from Command Prompt:**
   ```cmd
   cmd
   cd c:\path\to\scripts-deploy
   script-name.bat
   ```

2. **Check Windows Execution Policy:**
   ```cmd
   # Run as Administrator:
   powershell Set-ExecutionPolicy RemoteSigned
   ```

3. **Verify file encoding:**
   - Files should be saved as ANSI or UTF-8
   - Not UTF-16 or other encodings

4. **Antivirus interference:**
   - Some antivirus software blocks batch files
   - Add scripts-deploy folder to exclusions

---

### 🔴 "Git is not recognized" Error

**Problem:** Scripts fail with "git is not recognized as an internal or external command"

**Solution:**

1. **Install Git:**
   - Download: https://git-scm.com/downloads
   - During installation, select "Git from the command line and also from 3rd-party software"

2. **Add Git to PATH manually:**
   ```cmd
   # Add to System PATH:
   # Right-click "This PC" → Properties → Advanced system settings
   # → Environment Variables → System Variables → Path → Edit
   # Add: C:\Program Files\Git\cmd
   ```

3. **Restart terminal/computer:**
   - Close all command prompts
   - Open new command prompt
   - Test: `git --version`

---

### 🔴 "Permission Denied" or "Access Denied" Errors

**Solutions:**

1. **Run as Administrator:**
   - Right-click script → "Run as administrator"

2. **Check file permissions:**
   ```cmd
   # In scripts-deploy folder:
   attrib -r *.bat
   ```

3. **Disable antivirus temporarily:**
   - Some antivirus blocks Git operations
   - Add project folder to exclusions

4. **Check if files are in use:**
   - Close any editors/IDEs
   - Close Git GUI clients

---

### 🔴 "Failed to push to remote" Error

**Solutions:**

1. **Check internet connection:**
   ```cmd
   ping github.com
   ```

2. **Verify remote URL:**
   ```cmd
   git remote -v
   # Should show your repository URL
   ```

3. **Update remote URL if wrong:**
   ```cmd
   git remote set-url origin https://github.com/username/repo.git
   ```

4. **Check authentication:**
   ```cmd
   # For HTTPS:
   git config --global credential.helper wincred
   
   # For SSH:
   ssh -T git@github.com
   ```

5. **Force push if needed (CAREFUL!):**
   ```cmd
   git push --force origin main
   ```

---

### 🔴 "Merge Conflict" Errors

**When you see:**
```
CONFLICT (content): Merge conflict in filename
```

**Solution:**

1. **Run fix-git.bat:**
   - Select option [7] "Fix merge conflicts"

2. **Manual resolution:**
   ```cmd
   # 1. Open conflicted files
   # 2. Look for conflict markers:
   #    <<<<<<< HEAD
   #    your changes
   #    =======
   #    their changes
   #    >>>>>>> branch-name
   
   # 3. Edit file to keep desired changes
   # 4. Remove conflict markers
   # 5. Save file
   
   # 6. Mark as resolved:
   git add filename
   
   # 7. Complete merge:
   git commit -m "Resolved merge conflict"
   ```

3. **Abort merge if needed:**
   ```cmd
   git merge --abort
   ```

---

### 🔴 "Detached HEAD" State

**Problem:** Scripts show "detached HEAD" warning.

**Solution:**

1. **Run fix-git.bat:**
   - Select option [6] "Recover from detached HEAD"

2. **Manual fix:**
   ```cmd
   # Create branch from current state:
   git checkout -b recovery-branch
   
   # Or switch to existing branch:
   git checkout main
   ```

---

### 🔴 Scripts Work But Nothing Happens on GitHub

**Problem:** Scripts complete successfully but changes don't appear on GitHub.

**Causes & Solutions:**

1. **Not pushed to remote:**
   ```cmd
   git push origin main
   ```

2. **Wrong branch:**
   ```cmd
   # Check current branch:
   git branch
   
   # Switch to main:
   git checkout main
   ```

3. **Remote not configured:**
   ```cmd
   # Check remotes:
   git remote -v
   
   # Add remote if missing:
   git remote add origin https://github.com/username/repo.git
   ```

4. **Authentication failed silently:**
   ```cmd
   # Re-authenticate:
   gh auth login
   # Or:
   git config --global credential.helper wincred
   ```

---

### 🔴 How to Completely Restore Project to Previous State

**Use the new `revert-to-commit.bat` script!**

**Scenario 1: Deployed broken code (EMERGENCY)**
```cmd
1. Run: revert-to-commit.bat
2. Select: [1] Hard Reset
3. Enter: commit hash of last working version
4. Confirm: Type "I UNDERSTAND"
5. Confirm: Type commit hash again
6. Choose: Force push (Y)
```

**Scenario 2: Want to undo recent commits (SAFE)**
```cmd
1. Run: revert-to-commit.bat
2. Select: [4] Create Revert Commit
3. Enter: commit hash to revert to
4. Push: Yes
```

**Scenario 3: Review old version**
```cmd
1. Run: revert-to-commit.bat
2. Select: [2] Soft Reset
3. Enter: commit hash
4. Review changes
5. Recommit if needed
```

---

## 🆘 Emergency Recovery Steps

### If Everything is Broken:

1. **Check Git status:**
   ```cmd
   cd c:\path\to\your\project
   git status
   ```

2. **Run comprehensive fix:**
   ```cmd
   cd scripts-deploy
   fix-git.bat
   # Select [11] Fix all common issues
   ```

3. **If still broken, restore to last working commit:**
   ```cmd
   revert-to-commit.bat
   # Select appropriate method
   ```

4. **If Git is completely broken:**
   ```cmd
   # Backup your code first!
   # Then delete .git folder and reinitialize:
   cd c:\path\to\your\project
   rmdir /s .git
   cd scripts-deploy
   init-repo.bat
   ```

---

## 📞 Getting More Help

### Diagnostic Commands:
```cmd
# Check Git installation:
git --version

# Check GitHub CLI:
gh --version

# Check Git configuration:
git config --list

# Check remote:
git remote -v

# Check current branch:
git branch

# Check status:
git status

# Check recent commits:
git log --oneline -5
```

### Useful Scripts for Diagnosis:
- `status.bat` - See everything about repository
- `fix-git.bat` - Fix common issues
- `view-history.bat` - See commit history

### If Scripts Still Don't Work:

1. **Verify prerequisites:**
   - Git installed: `git --version`
   - In correct directory: `cd` shows scripts-deploy parent
   - Files not corrupted: Check file sizes

2. **Run scripts manually with error display:**
   ```cmd
   cmd /k script-name.bat
   ```

3. **Check Windows version:**
   - Scripts require Windows 7 or later
   - Command Prompt or PowerShell

4. **Reinstall Git:**
   - Uninstall current Git
   - Download fresh copy
   - Install with default options

---

## 🔧 Advanced Troubleshooting

### Enable Git Debug Mode:
```cmd
set GIT_TRACE=1
set GIT_CURL_VERBOSE=1
git push
```

### Clear Git Cache:
```cmd
git rm -r --cached .
git add .
git commit -m "Clear cache"
```

### Reset Git Configuration:
```cmd
git config --global --unset-all credential.helper
git config --global credential.helper wincred
```

### Test GitHub Connectivity:
```cmd
# HTTPS:
git ls-remote https://github.com/github/gitignore.git HEAD

# SSH:
ssh -T git@github.com
```

---

## ✅ Prevention Tips

1. **Always run `status.bat` before major operations**
2. **Use `quick-save.bat` frequently to avoid losing work**
3. **Test in development before production**
4. **Keep Git and GitHub CLI updated**
5. **Backup important branches**
6. **Use `stash-changes.bat` before switching contexts**
7. **Read error messages carefully**
8. **Keep scripts-deploy folder in every project**

---

**Last Updated:** November 22, 2024  
**Version:** 1.1.0 (Added revert-to-commit functionality)
