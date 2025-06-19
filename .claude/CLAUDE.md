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

## Python

### Package Manager

You are to use `uv` when dealing with python projects. Here are some common commands to use:

1. **Init a uv project in a new folder**: `uv init <folder-name>`
1. **Init a uv project in an existing folder**: `uv init .`
1. **Creating a .venv/ folder for local python installation**: `uv venv --seed`
1. **Adding dependencies to the current project**: `uv add <package>`

For additional documentation refer to the following link (https://docs.astral.sh/uv/llms.txt)

### Styling

- Make sure to use spaces for tabs and indents.
- Utilize **2 spaces** instead of the 4 spaces for tabs and indents that PEP8 recommends.

## Typescript / Javascript

### Package Manager

You are to use `pnpm` as the package manager of choice when dealing with Typescript / Javascript projects. Here are some common commands:

1. **Create a `package.json` file inside of the current directory**: `pnpm init`
1. **Adding dependencies**: `pnpm add <package>`
1. **Adding dev dependencies**: `pnpm add -D <package>`
1. **Installing all dependencies from an existing project**: `pnpm i` OR `pnpm install`
1. **Removing dependencies**: `pnpm remove <package>`
1. **Updating packages**: `pnpm up` OR `pnpm update` OR `pnpm upgrade`

## Styling

- Make sure to use spaces for tabs and indents
- Utilize **2 spaces** instead of 4 spaces for tabs and indents.
