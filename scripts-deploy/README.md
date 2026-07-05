# Git Deployment Scripts

A comprehensive collection of Windows batch scripts for easy and error-proof Git/GitHub operations. These scripts simplify common Git tasks and can be copied into any project for quick deployment and version control management.

## 📋 Table of Contents

- [Installation](#installation)
- [Prerequisites](#prerequisites)
- [Scripts Overview](#scripts-overview)
- [Detailed Script Documentation](#detailed-script-documentation)
- [Usage Examples](#usage-examples)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

## 🚀 Installation

1. Copy the entire `scripts-deploy` folder into your project root
2. Navigate to the folder and run any script by double-clicking it
3. Scripts will automatically detect your project name and work from the parent directory

```
your-project/
├── scripts-deploy/     ← All deployment scripts
│   ├── init-repo.bat
│   ├── quick-save.bat
│   ├── ...
├── src/
├── package.json
└── ...
```

## ✅ Prerequisites

### Required
- **Git**: [Download Git](https://git-scm.com/downloads)
- **Windows**: Windows 7 or later
- **PowerShell**: Pre-installed on Windows

### Optional (Recommended)
- **GitHub CLI (gh)**: [Download GitHub CLI](https://cli.github.com/)
  - Required for: `init-repo.bat` (automatic repo creation)
  - Required for: `change-account.bat` (easy account switching)

## 📚 Scripts Overview

### Repository Management
| Script | Purpose | Key Features |
|--------|---------|--------------|
| `init-repo.bat` | Initialize new GitHub repository | Auto-detects project name, creates public/private repos, sets up remote |
| `clone-repo.bat` | Clone existing repository | Multiple clone options, branch selection, shallow clones |
| `status.bat` | View repository status | Shows branches, commits, remotes, stashes |

### Committing & Saving
| Script | Purpose | Key Features |
|--------|---------|--------------|
| `quick-save.bat` | Auto-commit with timestamp | No manual commit message needed |
| `save-with-message.bat` | Commit with custom message | User-provided commit message |

### Deployment
| Script | Purpose | Key Features |
|--------|---------|--------------|
| `deploy-dev.bat` | Deploy to development | Creates/switches to dev branch, tags commits |
| `deploy-prod.bat` | Deploy to production | Confirmation required, creates tags, merges to main/master |

### Branch Management
| Script | Purpose | Key Features |
|--------|---------|--------------|
| `create-branch.bat` | Create new branch | Create from current, main, or specific commit |
| `switch-branch.bat` | Switch between branches | Auto-stash/commit changes, fetch remote branches |
| `merge-branch.bat` | Merge branches | Multiple merge strategies, conflict detection |
| `delete-branch.bat` | Delete branches | Delete local, remote, or both with safety checks |
| `compare-branches.bat` | Compare two branches | Show differences, commits, file changes, statistics |

### History & Changes
| Script | Purpose | Key Features |
|--------|---------|--------------|
| `view-history.bat` | View commit history | Multiple view options, search by message/author/date |
| `undo-commit.bat` | Undo last commit | Soft/mixed/hard reset, revert options |
| `revert-to-commit.bat` | **Revert entire project to any past commit** | **Full project restoration, 4 revert methods, safety checks** |
| `stash-changes.bat` | Manage stashed changes | Stash, apply, pop, drop, view stashes |
| `pull-latest.bat` | Pull latest changes | Auto-stash, conflict handling |

### Account & Configuration
| Script | Purpose | Key Features |
|--------|---------|--------------|
| `change-account.bat` | Switch GitHub accounts | Login/logout, configure Git user details |
| `fix-git.bat` | Fix Git connectivity issues | Comprehensive diagnostics and fixes |

### Advanced
| Script | Purpose | Key Features |
|--------|---------|--------------|
| `sync-fork.bat` | Sync forked repository | Fetch and merge upstream changes |

---

## 📖 Detailed Script Documentation

### `init-repo.bat` - Initialize Repository
**What it does:**
- Detects project name from parent folder
- Creates a new GitHub repository (public or private)
- Initializes Git if not already done
- Creates a default `.gitignore` file
- Sets up remote connection
- Makes initial commit and push

**When to use:** Starting a new project or adding Git to an existing project

**Steps:**
1. Run the script
2. Press Enter to use detected project name or type a custom name
3. Choose between public (1) or private (2) repository
4. Script handles everything automatically

**Fallback:** If GitHub CLI not installed, you'll be prompted to manually enter the repository URL

---

### `quick-save.bat` - Auto-Commit & Push
**What it does:**
- Automatically stages all changes
- Creates commit with timestamp (e.g., "Auto-save: 2024-11-22 15:30:45")
- Pushes to remote repository

**When to use:** Quick saves during development without writing commit messages

**Example output:**
```
Commit message: Auto-save: 2024-11-22 15:30:45
Staging all changes...
Committing changes...
Pushing to remote...
Changes saved and pushed successfully!
```

---

### `save-with-message.bat` - Custom Commit
**What it does:**
- Shows current changes
- Prompts for commit message
- Stages, commits, and pushes

**When to use:** When you want meaningful commit messages

**Example:**
```
Current changes:
M  popup.js
A  new-feature.js

Enter commit message: Add user authentication feature
```

---

### `deploy-dev.bat` - Development Deployment
**What it does:**
- Tags commit with `[DEV]` prefix
- Creates or switches to development branch
- Merges changes if switching branches
- Pushes to remote

**When to use:** Deploying features to development environment

**Features:**
- Auto-creates development branch if it doesn't exist
- Handles branch switching with merge
- Conflict detection

---

### `deploy-prod.bat` - Production Deployment
**What it does:**
- Requires "YES" confirmation (safety measure)
- Tags commit with `[PROD]` prefix
- Switches to main/master branch
- Creates timestamped production tag
- Pushes branch and tags

**When to use:** Deploying stable code to production

**Safety features:**
- Double confirmation required
- Automatic tagging for version tracking
- Merge conflict detection

**Example tag:** `prod-20241122-1530`

---

### `create-branch.bat` - Create New Branch
**What it does:**
- Shows existing branches
- Creates new branch from:
  - Current branch
  - Main/master branch
  - Specific commit
- Optionally pushes to remote

**When to use:** Starting work on a new feature or bug fix

**Example workflow:**
```
Enter new branch name: feature-user-profile
Create branch from:
[1] Current branch (development)
[2] Main/Master branch
[3] Specific commit
Enter choice: 1
Branch 'feature-user-profile' created successfully!
```

---

### `switch-branch.bat` - Switch Branches
**What it does:**
- Checks for uncommitted changes
- Offers to stash, commit, or discard changes
- Fetches remote branches
- Switches to target branch
- Optionally restores stashed changes

**When to use:** Switching context between different features or bug fixes

**Smart handling:**
- Auto-stash option
- Fetches remote branches
- Creates local tracking branches for remote branches

---

### `merge-branch.bat` - Merge Branches
**What it does:**
- Shows available branches
- Merges source branch into current branch
- Supports multiple merge strategies:
  - Regular merge (with merge commit)
  - Squash merge (single commit)
  - Fast-forward only
- Detects and reports conflicts

**When to use:** Integrating feature branches into main development branch

**Example:**
```
Current branch: main
Enter branch name to merge FROM: feature-login
Merge Strategy:
[1] Regular merge
[2] Squash merge
[3] Fast-forward only
```

---

### `delete-branch.bat` - Delete Branches
**What it does:**
- Deletes local and/or remote branches
- Protects main/master with extra confirmation
- Checks for unmerged changes
- Offers force delete option

**When to use:** Cleaning up merged or abandoned branches

**Safety features:**
- Cannot delete current branch
- Extra confirmation for main/master
- Warns about unmerged changes

---

### `compare-branches.bat` - Compare Branches
**What it does:**
- Shows commits unique to each branch
- Displays file differences
- Shows statistical summary
- Offers to merge after comparison

**When to use:** Before merging, or to review differences between branches

**Comparison types:**
1. Commits in branch A not in branch B
2. Commits in branch B not in branch A
3. Both differences
4. File differences
5. Detailed diff
6. Statistical summary

---

### `view-history.bat` - View Commit History
**What it does:**
- Multiple view options for commit history
- Search by message, author, or date range
- View file-specific history
- Graphical history of all branches

**When to use:** Reviewing project history, finding specific commits

**View options:**
1. Last 10/20/50 commits
2. All commits
3. Detailed history
4. Graphical history
5. Search by message
6. Search by author
7. Date range
8. File history

---

### `undo-commit.bat` - Undo Commits
**What it does:**
- Undoes last commit with various methods:
  - **Soft reset**: Keep changes staged
  - **Mixed reset**: Keep changes unstaged
  - **Hard reset**: Discard everything
  - **Revert**: Create new commit undoing changes

**When to use:** 
- Soft/Mixed: Made a mistake in commit message or forgot files
- Hard: Want to completely discard changes
- Revert: Already pushed commit and need to undo it

**Important:** Hard reset cannot be undone! Use with caution.

---

### `stash-changes.bat` - Stash Management
**What it does:**
- Temporarily saves uncommitted changes
- Multiple stash operations:
  - Save with or without message
  - Apply (keep in list)
  - Pop (remove from list)
  - Drop specific stash
  - View stash contents
  - Clear all stashes

**When to use:** Need to switch branches but have uncommitted work

**Example workflow:**
```
1. Stash current changes
2. Switch to another branch
3. Do urgent fix
4. Switch back
5. Pop stashed changes
```

---

### `pull-latest.bat` - Pull Changes
**What it does:**
- Fetches latest changes from remote
- Auto-stashes uncommitted changes if present
- Pulls changes into current branch
- Optionally restores stashed changes

**When to use:** Syncing with remote repository updates

**Smart features:**
- Conflict detection
- Auto-stash option
- Restore stash after pull

---

### `change-account.bat` - Account Management
**What it does:**
- Login to different GitHub account
- Logout from current account
- View current account details
- Configure Git user details
- Open GitHub in browser

**When to use:** Working with multiple GitHub accounts

**Requirements:** GitHub CLI (gh) for full functionality

**Options:**
1. Login to different account
2. Logout
3. View current account
4. Configure Git user details
5. Open GitHub in browser

---

### `fix-git.bat` - Fix Git Issues
**What it does:**
- Comprehensive Git diagnostics and fixes
- Fixes common issues:
  - Remote connection problems
  - Credential issues
  - SSH key problems
  - Line ending issues
  - Detached HEAD state
  - Merge conflicts
  - Repository corruption

**When to use:** Experiencing Git errors or connectivity issues

**Fix options:**
1. Fix remote connection
2. Reset credentials
3. Fix SSH keys
4. Clear Git cache
5. Fix line endings
6. Recover from detached HEAD
7. Fix merge conflicts
8. Clean untracked files
9. Repair corrupted repository
10. Test GitHub connectivity
11. **Fix all common issues** (recommended first try)

---

### `revert-to-commit.bat` - Revert Project to Any Past Commit
**What it does:**
- **Completely restores your entire project to any previous commit**
- Shows last 20 commits for easy selection
- Provides 4 different revert methods:
  - **Hard Reset**: Complete revert (DANGEROUS - loses all changes)
  - **Soft Reset**: Undo commits but keep changes staged
  - **Mixed Reset**: Undo commits but keep changes unstaged
  - **Revert Commit**: Safe method that creates new commit (best for pushed commits)
- Auto-stashes uncommitted changes
- Search commits by message
- View commit details before reverting
- Force push option for hard reset

**When to use:** 
- Need to restore project to a working state
- Undo multiple commits at once
- Recover from bad changes
- Go back to a specific version

**IMPORTANT SAFETY FEATURES:**
- Requires typing "I UNDERSTAND" for hard reset
- Must confirm commit hash for destructive operations
- Auto-stashes uncommitted work
- Shows what will be lost before proceeding
- Cannot be accidentally triggered

**Example scenarios:**
1. **Deployed broken code to production:**
   - Run revert-to-commit.bat
   - Select method [1] Hard Reset
   - Enter last working commit hash
   - Confirm with "I UNDERSTAND"
   - Force push to remote

2. **Want to review old version:**
   - Run revert-to-commit.bat
   - Select method [2] Soft Reset
   - Enter commit hash
   - Review changes, then recommit

3. **Already pushed bad commits:**
   - Run revert-to-commit.bat
   - Select method [4] Create Revert Commit
   - Enter commit hash to revert to
   - Safe for shared repositories

**Methods explained:**

1. **Hard Reset** (Destructive):
   - Completely erases all commits and changes after target commit
   - Your project becomes exactly as it was at that commit
   - Use when you want to completely discard recent work
   - Requires force push if already pushed to remote

2. **Soft Reset** (Safe):
   - Removes commits but keeps all changes staged
   - Perfect for re-organizing commits
   - No code is lost

3. **Mixed Reset** (Safe):
   - Removes commits and unstages changes
   - Changes remain in working directory
   - Good for selective re-committing

4. **Revert Commit** (Safest):
   - Creates new commit that undoes changes
   - Preserves history
   - Best for commits already pushed to remote
   - Safe for team collaboration

---

### `sync-fork.bat` - Sync Forked Repository
**What it does:**
- Configures upstream remote
- Fetches upstream changes
- Merges upstream into fork
- Pushes updated fork to origin

**When to use:** Keeping your forked repository up-to-date with the original

**Example workflow:**
```
1. Fork a repository on GitHub
2. Clone your fork locally
3. Run sync-fork.bat
4. Enter original repository URL
5. Script syncs everything
```

---

### `clone-repo.bat` - Clone Repository
**What it does:**
- Clones existing repository
- Multiple clone options:
  - Normal clone
  - Specific branch
  - Shallow clone (faster)
  - Clone with submodules

**When to use:** Getting a copy of existing repository

**Clone types:**
1. **Normal**: Full repository history
2. **Specific branch**: Only specified branch
3. **Shallow**: Latest commit only (faster, smaller)
4. **With submodules**: Includes all submodules

---

### `status.bat` - Repository Status
**What it does:**
- Shows current branch
- Lists remote URLs
- Displays repository status
- Shows last 5 commits
- Lists all branches
- Shows stashed changes

**When to use:** Quick overview of repository state

**Information shown:**
- Current branch
- Remote URLs
- Modified/staged/untracked files
- Recent commits
- Available branches
- Stashed changes

---

## 💡 Usage Examples

### Starting a New Project
```batch
1. Create project folder
2. Add your code files
3. Copy scripts-deploy folder into project
4. Run init-repo.bat
5. Use quick-save.bat or save-with-message.bat for commits
```

### Feature Development Workflow
```batch
1. Run create-branch.bat → Create "feature-new-login"
2. Make changes to code
3. Run save-with-message.bat → "Implement login form"
4. Run deploy-dev.bat → Deploy to development
5. After testing, run deploy-prod.bat → Deploy to production
```

### Fixing a Bug
```batch
1. Run create-branch.bat → Create "bugfix-user-auth"
2. Fix the bug
3. Run save-with-message.bat → "Fix authentication error"
4. Run switch-branch.bat → Switch to main
5. Run merge-branch.bat → Merge bugfix into main
6. Run delete-branch.bat → Delete bugfix branch
```

### Syncing with Team
```batch
1. Morning: Run pull-latest.bat to get team's changes
2. Make your changes
3. Run save-with-message.bat to commit
4. Push changes
5. End of day: Run pull-latest.bat again
```

### Working on Multiple Features
```batch
1. Working on feature A
2. Need to switch to urgent bugfix
3. Run stash-changes.bat → Stash feature A changes
4. Run switch-branch.bat → Switch to bugfix branch
5. Fix bug and commit
6. Run switch-branch.bat → Back to feature A
7. Run stash-changes.bat → Restore feature A changes
```

---

## 🔧 Troubleshooting

### Common Issues and Solutions

#### "Git is not recognized"
**Problem:** Git not installed or not in PATH
**Solution:** 
1. Install Git from https://git-scm.com/downloads
2. Or run `fix-git.bat` and follow prompts

#### "GitHub CLI not installed"
**Problem:** gh command not found
**Solution:** 
1. For automatic repo creation: Install from https://cli.github.com/
2. Or: Manually create repo on GitHub.com and use URL when prompted

#### "Failed to push to remote"
**Problem:** Network issues or authentication failure
**Solution:**
1. Run `fix-git.bat` → Select "Fix all common issues"
2. Check internet connection
3. Run `change-account.bat` to verify authentication

#### "Merge conflicts detected"
**Problem:** Conflicting changes in same file
**Solution:**
1. Open conflicted files
2. Look for `<<<<<<<` markers
3. Resolve conflicts manually
4. Run `save-with-message.bat` → "Resolve merge conflicts"

#### "Permission denied (publickey)"
**Problem:** SSH key not configured
**Solution:**
1. Run `fix-git.bat`
2. Select option 3: "Fix SSH key issues"
3. Follow prompts to create/configure SSH key

#### "Detached HEAD state"
**Problem:** Not on any branch
**Solution:**
1. Run `fix-git.bat`
2. Select option 6: "Recover from detached HEAD"
3. Choose branch to recover to

---

## 📌 Best Practices

### Commit Messages
✅ **Good:**
```
"Add user authentication system"
"Fix navigation bar alignment on mobile"
"Update dependencies to latest versions"
```

❌ **Bad:**
```
"update"
"fix"
"changes"
```

### Branch Naming
✅ **Good:**
```
feature-user-dashboard
bugfix-login-error
hotfix-security-patch
```

❌ **Bad:**
```
test
fix
mybranch
```

### When to Use Each Script

| Scenario | Use This Script |
|----------|----------------|
| Starting new project | `init-repo.bat` |
| Quick daily saves | `quick-save.bat` |
| Meaningful milestones | `save-with-message.bat` |
| Testing new features | `deploy-dev.bat` |
| Releasing to users | `deploy-prod.bat` |
| Starting new feature | `create-branch.bat` |
| Context switching | `switch-branch.bat` + `stash-changes.bat` |
| Made a mistake | `undo-commit.bat` |
| Need project overview | `status.bat` |
| Git errors | `fix-git.bat` |

### Repository Structure
```
recommended-structure/
├── scripts-deploy/          ← Git automation scripts
├── src/                     ← Source code
├── tests/                   ← Test files
├── docs/                    ← Documentation
├── .gitignore              ← Generated by init-repo.bat
├── README.md               ← Project documentation
└── package.json            ← Dependencies (if applicable)
```

### Safety Tips
1. **Always read prompts carefully** - especially for destructive operations
2. **Use `status.bat` regularly** - stay aware of repository state
3. **Test in development first** - use `deploy-dev.bat` before `deploy-prod.bat`
4. **Review before force operations** - understand what hard reset or force push does
5. **Keep backups** - especially before major operations
6. **Use meaningful branch names** - helps everyone understand purpose
7. **Commit frequently** - smaller commits are easier to understand and revert
8. **Pull before you push** - avoid conflicts by staying up-to-date

---

## 🎯 Quick Reference

### Daily Commands
```batch
pull-latest.bat          # Start of day
quick-save.bat           # Quick saves
save-with-message.bat    # Important commits
status.bat              # Check status anytime
```

### Weekly Commands
```batch
view-history.bat        # Review week's work
compare-branches.bat    # Compare development with production
sync-fork.bat          # If using forked repos
```

### As Needed
```batch
create-branch.bat       # New features
merge-branch.bat        # Integrating work
deploy-dev.bat         # Testing
deploy-prod.bat        # Releases
fix-git.bat            # When issues arise
```

---

## 📄 License

These scripts are provided as-is for free use in any project. No attribution required, but appreciated!

## 🤝 Contributing

Feel free to modify these scripts for your specific needs. Common modifications:
- Change default branch names
- Adjust commit message formats
- Add custom hooks or validations
- Integrate with CI/CD systems

## 📞 Support

If you encounter issues:
1. Run `fix-git.bat` first
2. Check this README for solutions
3. Review error messages carefully
4. Ensure Git and prerequisites are installed

---

## ⚡ Quick Start Guide

### First Time Setup (2 minutes)
1. Copy `scripts-deploy` folder to your project
2. Open scripts-deploy folder
3. Run `init-repo.bat`
4. Follow prompts
5. Done! Repository created and connected to GitHub

### Daily Workflow (30 seconds)
1. Make code changes
2. Run `quick-save.bat` for quick commits
3. Or run `save-with-message.bat` for important commits
4. That's it! Changes are saved and pushed

---

**Last Updated:** November 22, 2024  
**Version:** 1.0.0  
**Scripts Count:** 16 scripts covering all major Git operations

---

*Made with ❤️ for developers who want simple, reliable Git automation*
