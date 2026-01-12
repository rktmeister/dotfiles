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
export PATH="/home/definevera/.amp/bin:$PATH"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"
export PATH="$HOME/.koyeb/bin:$PATH"
export PATH="$HOME/.pixi/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.dotnet/tools:$PATH"
export PATH="$HOME/.local/bin/zig-x86_64-linux-0.15.2:$PATH"
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
  eval "$(zoxide init zsh)"
fi

# Custom CD with Icon and Zoxide fallback
if command -v zoxide &> /dev/null; then
  zd() {
    if [ $# -eq 0 ]; then
      builtin cd ~ && return
    elif [ -d "$1" ]; then
      builtin cd "$1"
    else
      z "$@" && printf "\U000F17A9 " && pwd || echo "Error: Directory not found"
    fi
  }
  alias cd="zd"
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
alias l='ls --color=auto'
alias ll='ls -alh --color=auto'
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
alias gearlever='flatpak run it.mijorus.gearlever'
alias codex-yolo='codex --yolo'
alias spotify='spotify_player'
alias ts='tmux new -s'
alias ta='tmux attach -t'
alias tl='tmux list-session'
alias tk='tmux kill-session -t'
alias cxusage='ccusage-codex'

# Docker Aliases
alias dcup='docker compose up'
alias dcupd='docker compose up -d'
alias dcdown='docker compose down'
alias dclf='docker compose logs -f'
alias dctx='docker context'
alias dstack='docker stack'

# SSH Multiplexing Aliases
sockets() {
  emulate -L zsh -o err_return -o pipefail -o no_xtrace -o no_verbose
  setopt no_beep

  local mode="short"
  local debug=0
  while (( $# > 0 )); do
    case "$1" in
      -d|--debug) debug=1; shift ;;
      -l|--long) mode="long"; shift ;;
      -k|--kill) mode="kill"; shift; break ;;
      -h|--help)
        print -r -- "Usage: sockets [-l|--long] [-d|--debug]"
        print -r -- "       sockets -k <alias> [-- ssh_options...]"
        return 0
        ;;
      --) shift; break ;;
      *) break ;;
    esac
  done

  if [[ $mode == "kill" ]]; then
    local target="${1:-}"
    if [[ -z $target ]]; then
      print -r -- "Usage: sockets -k <alias> [-- ssh_options...]"
      return 2
    fi
    shift
    if (( $# > 0 )) && [[ $1 == "--" ]]; then
      shift
    fi
    if (( $# > 0 )); then
      ssh_connect stop "$target" -- "$@"
    else
      ssh_connect stop "$target"
    fi
    return $?
  fi

  local sock_dir="${SSH_SOCKET_DIR:-$HOME/.ssh/sockets}"
  local config="${SSH_CONFIG:-$HOME/.ssh/config}"

  if [[ ! -d $sock_dir ]]; then
    print -r -- "No sockets directory: $sock_dir"
    return 1
  fi

  local -a socket_paths
  socket_paths=($sock_dir/*(N))
  if (( debug )); then
    print -r -- "sock_dir=$sock_dir"
    print -r -- "socket_paths=${(qqq)socket_paths}"
    print -r -- "xtrace=${options[xtrace]} verbose=${options[verbose]}"
  fi
  if (( ${#socket_paths[@]} == 0 )); then
    print -r -- "No active sockets in $sock_dir"
    return 0
  fi

  local -A cp_to_aliases cp_to_ssh_target cp_base_to_aliases cp_base_to_ssh_target
  if [[ -f $config ]]; then
    local -a hosts
    hosts=("${(@f)$(awk '
      tolower($1)=="host" {
        for (i=2; i<=NF; i++) {
          if ($i !~ /[*?]/ && $i !~ /^!/ && $i !~ /\[/) print $i
        }
      }' "$config")}")

    local host cfg cp cp_base host_user host_hostname host_port host_target
    for host in $hosts; do
      cfg=$(ssh -G "$host" 2>/dev/null) || continue
      cp=$(awk '$1=="controlpath"{print $2; exit}' <<<"$cfg")
      [[ -n $cp && $cp != "none" ]] || continue
      cp_base="${cp:t}"
      host_user=$(awk '$1=="user"{print $2; exit}' <<<"$cfg")
      host_hostname=$(awk '$1=="hostname"{print $2; exit}' <<<"$cfg")
      host_port=$(awk '$1=="port"{print $2; exit}' <<<"$cfg")
      host_target="${host_user}@${host_hostname}:${host_port}"
      cp_to_aliases[$cp]="${cp_to_aliases[$cp]:+${cp_to_aliases[$cp]}, }$host"
      cp_to_ssh_target[$cp]="$host_target"
      cp_base_to_aliases[$cp_base]="${cp_base_to_aliases[$cp_base]:+${cp_base_to_aliases[$cp_base]}, }$host"
      cp_base_to_ssh_target[$cp_base]="$host_target"
    done
  fi

  if [[ $mode == "long" ]]; then
    printf "%-20s %-30s %s\n" "ALIAS" "TARGET" "SOCKET"
  fi

  local socket socket_abs socket_base alias socket_target
  for socket in $socket_paths; do
    socket_abs="${socket:A}"
    socket_base="${socket:t}"
    alias="${cp_to_aliases[$socket_abs]}"
    socket_target="${cp_to_ssh_target[$socket_abs]}"
    [[ -n $alias ]] || alias="${cp_to_aliases[$socket]}"
    [[ -n $alias ]] || alias="${cp_base_to_aliases[$socket_base]}"
    [[ -n $socket_target ]] || socket_target="${cp_to_ssh_target[$socket]}"
    [[ -n $socket_target ]] || socket_target="${cp_base_to_ssh_target[$socket_base]}"
    if [[ -z $socket_target && $socket_base == target=* ]]; then
      local maybe="${socket_base#target=}"
      if [[ $maybe =~ ^[^@]+@[^:]+:[0-9]+$ ]]; then
        socket_target="$maybe"
      fi
    fi

    if (( debug )); then
      print -r -- "loop socket_base=$socket_base alias=${alias:-<none>} target=${socket_target:-<none>}"
    fi

    if [[ $mode == "long" ]]; then
      if [[ -n $alias ]]; then
        printf "%-20s %-30s %s\n" "$alias" "$socket_target" "$socket_base"
      else
        printf "%-20s %-30s %s\n" "-" "-" "$socket_base"
      fi
    else
      if [[ -n $alias ]]; then
        printf "%-20s %s\n" "$alias" "$socket_base"
      else
        print -r -- "$socket_base"
      fi
    fi
  done
}

# Claude CLI Config
export ENABLE_BACKGROUND_TASKS=1
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
export DISABLE_TELEMETRY=1

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

# vpn {zscaler|tailscale|status}
[[ -f "$HOME/.zsh/vpn.zsh" ]] && source "$HOME/.zsh/vpn.zsh"


# SSH connection manager
[[ -f "$HOME/.zsh/ssh_connect.zsh" ]] && source "$HOME/.zsh/ssh_connect.zsh"

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

# Added by LM Studio CLI (lms)
export PATH="$PATH:/home/definevera/.lmstudio/bin"
# End of LM Studio CLI section


# bun completions
[ -s "/home/definevera/.bun/_bun" ] && source "/home/definevera/.bun/_bun"
