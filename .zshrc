# ==============================================================================
#
#                         Nevera's .zshrc
#
#   Optimized for speed, clarity, and maintainability.
#   Loads components in a logical order: Env -> Plugins -> Completions -> UI -> Config
#
# ==============================================================================

#-------------------------------------------------------------------------------
# SECTION 1: ENVIRONMENT & PATHS
#-------------------------------------------------------------------------------
# Set essential environment variables first.

# Source local/private environment variables if the file exists
[ -f ~/.zsh_secrets ] && source ~/.zsh_secrets

# Define installation paths for tools
export BUN_INSTALL="$HOME/.bun"
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# opencode
export PATH=/home/definevera/.opencode/bin:$PATH

# Prepend all custom paths to the system PATH for priority
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="$HOME/.koyeb/bin:$PATH"
export PATH="$HOME/.pixi/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.dotnet/tools:$PATH"
export PATH="$HOME/.local/bin/zig-x86_64-linux-0.15.1:$PATH"
export PATH="$HOME/.local/kitty.app/bin:$PATH"
export PATH="/opt/nvim-linux-x86_64/bin:$PATH"
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
export PATH="/usr/local/go/bin:$PATH"
export PATH="/usr/local/cuda/bin:$PATH"
# export LC_ALL="en_US.UTF_8"

# Source Deno's specific environment script
[ -s "$HOME/.deno/env" ] && . "$HOME/.deno/env"

# Set library paths and other system variables
export LD_LIBRARY_PATH="/usr/local/cuda/lib64:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="$HOME/cudnn-v8/cudnn-linux-x86_64-8.9.7.29_cuda12-archive/lib:$LD_LIBRARY_PATH"  # libcudnn8
export GPG_TTY=$(tty)
# export DOCKER_HOST=unix:///var/run/docker.sock

#-------------------------------------------------------------------------------
# SECTION 2: PLUGIN MANAGER (ZINIT)
#-------------------------------------------------------------------------------
# Initialize zinit and load all plugins and snippets.

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
  mkdir -p "$(dirname $ZINIT_HOME)"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

# Load plugins
zinit ice wait lucid blockf
zinit light zsh-users/zsh-completions
zinit light romkatv/zsh-defer
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab                 # Hooks into the completion system

# Load snippets
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::command-not-found
zinit snippet OMZP::tmux
zinit snippet OMZP::fancy-ctrl-z

zinit cdreplay -q

#-------------------------------------------------------------------------------
# SECTION 3: ZSH COMPLETION SYSTEM (THE FAST WAY)
#-------------------------------------------------------------------------------
# This must come AFTER loading plugins (like zsh-completions) but BEFORE
# shell integrations that might use it (like fzf-tab).

typeset -gU fpath

# Add our custom completions directory to the function path
fpath=($HOME/.zsh/completions $fpath)

_zsh_compdump=${XDG_CACHE_HOME:-$HOME/.cache}/zcompdump-$ZSH_VERSION

_zsh_init_completions() {
  autoload -Uz compinit

  # Load the dump (re-creates the plain file when dirs are newer)
  if [[ -s ${_zsh_compdump}.zwc ]]; then
    compinit -C -d "$_zsh_compdump"  # compiled dump exists -> skip security check
  else
    compinit -d "$_zsh_compdump"  # first run or .zwc missing
  fi

  # Re-compile only when needed
  if [[ ! -s ${_zsh_compdump}.zwc || $_zsh_compdump -nt ${_zsh_compdump}.zwc ]]; then
    zcompile -U "$_zsh_compdump" &!   # run in background → never blocks prompt
  fi
}

# Instant prompt – completions appear 0.2 s later (recommended)
zsh-defer _zsh_init_completions

#-------------------------------------------------------------------------------
# SECTION 4: SHELL INTEGRATIONS & UI
#-------------------------------------------------------------------------------
# These tools modify the interactive shell with keybindings, aliases, etc.
# The 'eval' calls here are correct and necessary for them to function.

# OhMyPosh Prompt
zsh-defer -c 'eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/dylan.toml)"'


# FZF and Zoxide
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

if [ -z "$DISABLE_ZOXIDE" ]; then
  eval "$(zoxide init --cmd cd zsh)"
fi

#-------------------------------------------------------------------------------
# SECTION 5: ZSH OPTIONS & STYLING
#-------------------------------------------------------------------------------

# History
HISTFILE=~/.zsh_history
HISTSIZE=5000
SAVEHIST=$HISTSIZE
setopt appendhistory sharehistory hist_ignore_space hist_ignore_all_dups hist_save_no_dups

# Autosuggestions Styling
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#928374"

# Completion Styling (including fzf-tab)
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

#-------------------------------------------------------------------------------
# SECTION 6: KEYBINDINGS
#-------------------------------------------------------------------------------
bindkey -e
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

#-------------------------------------------------------------------------------
# SECTION 7: ALIASES, FUNCTIONS, & CLI CONFIGS
#-------------------------------------------------------------------------------

# General Aliases
alias l='eza'
alias ll='eza -alh'
alias vim='nvim'
alias c='clear'
alias s='ssh_connect'
alias icat='kitten icat'
alias zupdate='source ~/.zshrc'
alias zconfig='vim ~/dotfiles/.zshrc'
alias adg='sudo apt update && sudo apt upgrade'
alias dl='curl -fSsL -O -J -k --retry 5 --retry-delay 3 --retry-max-time 60 --connect-timeout 30 -A "Mozilla/5.0" --max-redirs 10'
alias lj='lazyjj'
alias j='jj'
alias jjj='jj'
alias jn='jj new'
alias jp='jj git push'
alias js='jj st'
alias zrecomp='rm ~/.cache/zcompdump-5.9 ~/.cache/zcompdump-5.9.zwc; zupdate'
alias startros='source /opt/ros/kilted/setup.zsh'
alias upgrade='sudo apt update && sudo apt upgrade -y; flatpak update; sudo snap refresh; oh-my-posh upgrade'
alias codex-yolo='codex --yolo'
alias codex='codex --search --model=gpt-5-codex -c model_reasoning_effort="high" --sandbox workspace-write -c sandbox_workspace_write.network_access=true'

# Docker Aliases
alias dcup='docker compose up'
alias dcupd='docker compose up -d'
alias dcdown='docker compose down'
alias dclf='docker compose logs -f'
alias dctx='docker context'
alias dstack='docker stack'

# SSH Multiplexing Aliases
alias prod-stop='ssh_connect stop prod'
alias prod-status='ssh_connect status prod'
alias rnd-dylan-stop='ssh_connect stop rnd-dylan'
alias rnd-dylan-status='ssh_connect status rnd-dylan'
alias mini-stop='ssh_connect stop mini'
alias mini-status='ssh_connect status mini'
alias proxy-stop='ssh_connect stop proxy'
alias proxy-status='ssh_connect status proxy'
alias studio-stop='ssh_connect stop studio'
alias studio-status='ssh_connect status studio'
alias sockets='ls ~/.ssh/sockets'

# Claude CLI Config
export ENABLE_BACKGROUND_TASKS=1
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
export DISABLE_TELEMETRY=1
alias qlaude='API_TIMEOUT_MS=600000 ANTHROPIC_BASE_URL=http://localhost:4000 ANTHROPIC_MODEL=openrouter/qwen/qwen3-coder ANTHROPIC_SMALL_FAST_MODEL=openrouter/qwen/qwen3-coder claude --dangerously-skip-permissions'
alias klaude='export ANTHROPIC_BASE_URL=https://api.moonshot.ai/anthropic claude --dangerously-skip-permissions'

# EDITOR
export EDITOR=nvim

# --- Custom Functions ---

# Lazygit with directory change on exit
lg() {
    export LAZYGIT_NEW_DIR_FILE=~/.lazygit/newdir
    lazygit "$@"
    if [ -f $LAZYGIT_NEW_DIR_FILE ]; then
            cd "$(cat $LAZYGIT_NEW_DIR_FILE)"
            rm -f $LAZYGIT_NEW_DIR_FILE > /dev/null
    fi
}

# SSH connection manager
ssh_connect() {
  setopt extended_glob
  if [[ $# -lt 1 ]]; then
    echo "Usage: ssh_connect [connect|start|stop|status] <server_alias> [ports...] [-- ssh_options...]"
    echo "Example: ssh_connect start my-server 8080 9000-9010 -- -i ~/.ssh/id_rsa -p 2222"
    return 1
  fi

  local command=$1
  local server=$2

  # Handle implicit 'connect' command
  if [[ "$command" != "connect" && "$command" != "start" && "$command" != "stop" && "$command" != "status" ]]; then
    server=$1
    command="connect"
    shift
  else
    shift 2
  fi

  # --- MODIFICATION START ---
  # Separate port arguments from pass-through ssh options
  local port_args=()
  local ssh_opts=()
  while (( $# > 0 )); do
    if [[ "$1" == "--" ]]; then
      shift # Consume the '--'
      ssh_opts=("$@") # The rest of the arguments are for ssh
      break
    fi
    port_args+=("$1")
    shift
  done
  # --- MODIFICATION END ---

  case "$command" in
    stop)
      echo "Stopping SSH master connection and tunnels for $server..."
      # Pass through ssh options
      ssh -O exit "${ssh_opts[@]}" "$server"
      ;;
    status)
      echo "Checking status of SSH master connection for $server..."
      # Pass through ssh options
      ssh -O check "${ssh_opts[@]}" "$server"
      ;;
    start|connect)
      local forward_args=()
      local ports_display=()
      # --- MODIFICATION START ---
      # Loop over the collected port_args instead of the original $@
      for arg in "${port_args[@]}"; do
        if [[ $arg =~ ^([0-9]+)-([0-9]+)$ ]]; then
          local start=${match[1]} end=${match[2]}
          if (( start >= 1024 && end <= 49151 && start <= end )); then
            for port in $(seq $start $end); do
              forward_args+=("-L" "$port:127.0.0.1:$port")
              ports_display+=("$port")
            done
          else echo "Warning: Invalid port range: $arg"
          fi
        elif [[ $arg =~ ^([0-9]+):([0-9]+)$ ]]; then
          local local_port=${match[1]} remote_port=${match[2]}
          if (( local_port >= 1024 && local_port <= 49151 && remote_port >= 1024 && remote_port <= 49151 )); then
            forward_args+=("-L" "$local_port:127.0.0.1:$remote_port")
            ports_display+=("$local_port→$remote_port")
          else echo "Warning: Invalid port mapping: $arg"
          fi
        elif [[ $arg =~ ^[0-9]+$ ]]; then
          if (( $arg >= 1024 && $arg <= 49151 )); then
            forward_args+=("-L" "$arg:127.0.0.1:$arg")
            ports_display+=("$arg")
          else echo "Warning: Invalid port number: $arg"
          fi
        else echo "Warning: Invalid format: $arg"
        fi
      done
      # --- MODIFICATION END ---

      if (( ${#forward_args[@]} > 0 )); then
        echo "Checking for existing master connection..."
        # Pass through ssh options
        if ssh -O check "${ssh_opts[@]}" "$server" &>/dev/null; then
          echo "Warning: Master connection already exists for $server."
          echo "Tunnels cannot be added to a running connection."
          echo "To apply new tunnels, run 'ssh_connect stop $server' first."
        else
          echo "Establishing new background master connection for $server..."
          if (( ${#ports_display[@]} > 0 )); then
            echo "Forwarding ports: ${ports_display[@]}"
          fi
          # Pass through ssh options here as well
          ssh -f -N -o ExitOnForwardFailure=yes "${forward_args[@]}" "${ssh_opts[@]}" "$server"
          if [[ $? -eq 0 ]]; then
            echo "Tunnels successfully established in the background."
          else
            echo "Error: Failed to establish tunnels. A port might be in use or the server is unreachable."
            return 1
          fi
        fi
      fi

      if [[ "$command" == "connect" ]]; then
        echo "Opening interactive shell to $server..."
        # And finally, pass through ssh options to the interactive shell
        ssh "${ssh_opts[@]}" "$server"
      fi
      ;;
    *)
      echo "Error: Unknown command '$command'"
      return 1
      ;;
  esac
}

# bun completions
[ -s "/home/definevera/.bun/_bun" ] && source "/home/definevera/.bun/_bun"
