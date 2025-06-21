# General

## `ast-grep` (Code structural search, lint, and rewriting.)

You run in an environment where `ast-grep` is available; whenever a search requires syntax-aware or structural matching, default to `ast-grep --lang rust -p '<pattern>'` (or set `--lang` appropriately) and avoid falling back to text-only tools like `rg` or `grep` unless I explicitly request a plain-text search.

## `gh` (Github CLI)

You are given access to the github cli using the `gh` command.

## `git` (Normal Git)

When writing commits (first pick the files you want to add using `git add <files>` and then `git commit -m "<message>"`), follow Conventional Commits (example below):

1. `build`: Changes to build system, dependencies, or project tooling (e.g., npm, webpack, gradle)
1. `chore`: Regular maintenance tasks, updating configs, etc. that don't modify src or test files
1. `ci`: Changes to CI/CD configuration files and scripts (e.g., GitHub Actions, Jenkins)
1. `docs`: Documentation changes only (README, API docs, comments)
1. `feat`: New features or significant functionality additions
1. `fix`: Bug fixes and patches
1. `perf`: Performance improvements
1. `refactor`: Code changes that neither fix bugs nor add features (e.g., restructuring code)
1. `revert`: Reverting a previous commit
1. `style`: Code style changes (formatting, missing semicolons, etc.) without logic changes
1. `test`: Adding or modifying tests

## Docker

Utilize the following template when writing `.dockerignore` for all projects

```
# ===================================================================
# Universal .dockerignore for Python & Node.js (JS/TS) Projects
#
# Purpose: This file prevents files from being sent to the Docker daemon,
# speeding up the build process and creating smaller, more secure images.
# It is meant to be a comprehensive template; uncomment or add items
# as needed for your specific project.
# ===================================================================

# --- General ---
# Ignore version control directories and files
.git
.gitignore
.gitattributes

# Ignore the dockerignore file itself
.dockerignore

# --- IDE & Editor Configuration ---
# JetBrains (PyCharm, WebStorm, IntelliJ)
.idea/
*.iml

# Visual Studio Code
.vscode/

# Visual Studio
.vs/
*.*proj.user
*.dbmdl

# Vim, Emacs, and other editors
*.swp
*.swo
*~
.#*

# --- OS-specific files ---
# macOS
.DS_Store
.AppleDouble
.LSOverride

# Windows
Thumbs.db
ehthumbs.db
Desktop.ini

# ===================================================================
# Language & Framework Specific
# ===================================================================

# --- Python ---
# Bytecode and compiled files
__pycache__/
*.py[cod]
*$py.class
*.so

# Distribution / packaging
.Python
build/
develop-eggs/
dist/
eggs/
sdist/
wheel/
*.egg-info/
.installed.cfg
*.egg

# Virtual environments
.venv/
venv/
env/
ENV/
.env/

# Mypy, Pytest and coverage artifacts
.mypy_cache/
.pytest_cache/
.coverage
.coverage.*
htmlcov/
.tox/
.nox/

# --- Node.js / TypeScript / JavaScript ---
# Dependencies
node_modules/

# Build output
dist/
build/
out/
.next/ # Next.js
.nuxt/ # Nuxt.js
public/build/ # Remix

# Logs
npm-debug.log*
yarn-debug.log
yarn-error.log
pnpm-debug.log

# TypeScript cache
*.tsbuildinfo

# NOTE on lockfiles: In a multi-stage build, you WANT the lockfile in your
# build stage to ensure deterministic installs. You often don't need it in
# the final image. If you have a single-stage build, you might want to
# uncomment these to keep the final image smaller.
# package-lock.json
# yarn.lock
# pnpm-lock.yaml

# --- Secrets & Local Configuration ---
# This is a critical section. NEVER commit secrets to your image.
# Use build arguments, environment variables, or Docker secrets instead.
.env
.env.*
!.env.example # Keep example files for reference

# Local secrets and configuration files
secrets.*.yaml
values.dev.yaml
*.local

# ===================================================================
# Project & Temporary Files
# ===================================================================

# Documentation
# README and LICENSE are often small and useful to have in the image.
# The 'docs' directory is usually for developers and can be ignored.
docs/

# Logs and temporary files
*.log
*.log.*
*.tmp
*.temp

# Other common ignored directories
bin/
obj/
charts/ # Helm charts

# --- Project-specific ---
# Add any files or directories specific to your project that are not
# needed in the Docker image.
# Example:
conversations/
# local_data/
# notebooks/
```

## Python

### Package Manager

Use `uv` when dealing with python projects. Here are some common commands to use:

1. **Init a uv project in a new folder**: `uv init <folder-name>`
1. **Init a uv project in an existing folder**: `uv init .`
1. **Creating a .venv/ folder for local python installation**: `uv venv --seed`
1. **Adding dependencies to the current project**: `uv add <package>`
1. **Adding dependencies from a `requirements.txt` file**: `uv add -r requirements.txt`

For additional documentation refer to the following link (https://docs.astral.sh/uv/llms.txt)

### Styling

- Make sure to use spaces for tabs and indents.
- Utilize **2 spaces** instead of the 4 spaces for tabs and indents that PEP8 recommends.

### Containerization

#### Dockerfile 

Utilize the following template when writing `Dockerfile` for a python application:

- https://raw.githubusercontent.com/astral-sh/uv-docker-example/refs/heads/main/Dockerfile

## Typescript / Javascript

### Package Manager

Use `pnpm` as the package manager when dealing with Typescript / Javascript projects. Here are some common commands:

1. **Create a `package.json` file inside of the current directory**: `pnpm init`
1. **Adding dependencies**: `pnpm add <package>`
1. **Adding dev dependencies**: `pnpm add -D <package>`
1. **Installing all dependencies from an existing project**: `pnpm i` OR `pnpm install`
1. **Removing dependencies**: `pnpm remove <package>`
1. **Updating packages**: `pnpm up` OR `pnpm update` OR `pnpm upgrade`

## Styling

- Make sure to use spaces for tabs and indents
- Utilize **2 spaces** instead of 4 spaces for tabs and indents.
