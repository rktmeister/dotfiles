# .zshrc config file for Nevera

# zinit config
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# check if zinit dir exists
if [ ! -d "$ZINIT_HOME" ]; then
  mkdir -p "$(dirname $ZINIT_HOME)"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "${ZINIT_HOME}/zinit.zsh"

# zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Add in snippets
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::command-not-found
zinit snippet OMZP::tmux

# Deno shell completions
source ~/.deno-completions.zsh

# pnpm shell completions
source ~/.completion-for-pnpm.zsh

# bun completions
[ -s "/home/$USER/.bun/_bun" ] && source "/home/$USER/.bun/_bun"

zinit cdreplay -q

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#ff00ff,bg=cyan,bold,underline"

# Export PATHs
export PATH="$PATH:/home/$USER/.pixi/bin"
export PATH="$PATH:/home/$USER/.local/bin"
export PATH="$PATH:/home/$USER/.dotnet/tools"
export PATH="$PATH:/home/$USER/.local/bin/zig-linux-x86_64-0.14.0"
export PATH="$PATH:/home/$USER/Document/C4G/birdwatcher"
export PATH="$PATH:/opt/nvim-linux-x86_64/bin"
export PATH="$PATH:/opt/pycharm-2025.1.1/bin"
export PATH="$PATH:/usr/local/cuda/bin"
export PATH="$PATH:/usr/local/go/bin"
export PATH="$PATH:/home/$USER/.local/share/pnpm"
export PATH="$PATH:/home/$USER/.koyeb/bin"
## bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Export external PATHs
export LD_LIBRARY_PATH="/usr/local/cuda/lib64:$LD_LIBRARY_PATH"
# export DOCKER_HOST=unix:///var/run/docker.sock

# OhMyPosh config file
eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/dylan.toml)"

# QOL Keybindings
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word

# Keybindings for zsh config
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Aliases
alias ls='eza'
alias vim='nvim'
alias l='ls'
alias c='clear'
alias s='ssh_connect'
alias zupdate='source ~/.zshrc'
alias zconfig='vim ~/.zshrc'
alias adg='sudo apt update && sudo apt upgrade'
alias dl='curl -fSsL -O -J -k --retry 5 --retry-delay 3 --retry-max-time 60 --connect-timeout 30 -A "Mozilla/5.0" --max-redirs 10'

## Docker aliases
alias dcup='docker compose up'
alias dcupd='docker compose up -d'
alias dcdown='docker compose down'
alias dclf='docker compose logs -f'
alias dctx='docker context'
alias dstack='docker stack'

## SSH Aliases
### Port Forwarding (-L <local_port>:localhost:<remote_port>)
### Debug (-v)
alias rnd-dylan-sch='ssh_connect dylan@10.32.22.168' 
alias rnd-user-sch='ssh_connect user@10.32.10.178'
alias prod-sch='ssh_connect chat4good@10.32.45.55'
alias rnd-dylan='ssh_connect dylan@100.94.88.29'
alias rnd-user='ssh_connect user@100.94.88.29'
alias prod='ssh_connect chat4good@100.125.248.67'
alias mini='ssh_connect nevera@100.100.81.26'
# Aliases end

# Shell integrations
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"
eval "$(uv generate-shell-completion zsh)"  # uv
eval "$(uvx --generate-shell-completion zsh)"  # uvx
eval "$(pixi completion --shell zsh)"  # pixi
. "/home/$USER/.deno/env"  #deno

export GPG_TTY=$(tty)

# pnpm
export PNPM_HOME="/home/$USER/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# A powerful SSH connection manager that leverages ControlMaster for persistent tunnels.
#
# USAGE:
#   1. Connect with tunnels (and leave them running in the background):
#      ssh_connect connect <server> [port] [local:remote] [start-end]
#
#   2. Start tunnels in the background WITHOUT opening a shell:
#      ssh_connect start <server> [port] [local:remote] [start-end]
#
#   3. Stop the background connection and all its tunnels:
#      ssh_connect stop <server>
#
#   4. Check the status of the background connection:
#      ssh_connect status <server>
#
# PREREQUISITE:
#   Your ~/.ssh/config must be configured for ControlMaster.
#   See: https://www.example.com/ssh-multiplexing-guide

ssh_connect() {
  # Zsh-specific: enable extended globbing for regex matching
  setopt extended_glob

  if [[ $# -lt 1 ]]; then
    echo "Usage: ssh_connect [connect|start|stop|status] <server_alias> [ports...]"
    return 1
  fi

  local command=$1
  local server=$2
  
  # If the first argument is not a known command, assume it's a server name
  # for a standard connection.
  if [[ "$command" != "connect" && "$command" != "start" && "$command" != "stop" && "$command" != "status" ]]; then
    server=$1
    command="connect"
    shift # The remaining arguments are ports
  else
    shift 2 # The remaining arguments are ports
  fi

  # --- Command Handlers ---

  case "$command" in
    stop)
      echo "Stopping SSH master connection and tunnels for $server..."
      # -O exit sends the 'stop' signal to the master process
      ssh -O exit "$server"
      ;;

    status)
      echo "Checking status of SSH master connection for $server..."
      # -O check pings the master process
      ssh -O check "$server"
      ;;

    start|connect)
      local forward_args=()
      local ports_display=()
      
      # Your brilliant port-parsing logic remains here
      while (( $# > 0 )); do
        if [[ $1 =~ ^([0-9]+)-([0-9]+)$ ]]; then
          local start=${match[1]} end=${match[2]}
          if (( start >= 1024 && end <= 49151 && start <= end )); then
            for port in $(seq $start $end); do
              forward_args+=("-L" "$port:127.0.0.1:$port")
              ports_display+=("$port")
            done
          else echo "Warning: Invalid port range: $1"
          fi
        elif [[ $1 =~ ^([0-9]+):([0-9]+)$ ]]; then
          local local_port=${match[1]} remote_port=${match[2]}
          if (( local_port >= 1024 && local_port <= 49151 && remote_port >= 1024 && remote_port <= 49151 )); then
            forward_args+=("-L" "$local_port:127.0.0.1:$remote_port")
            ports_display+=("$local_port→$remote_port")
          else echo "Warning: Invalid port mapping: $1"
          fi
        elif [[ $1 =~ ^[0-9]+$ ]]; then
          if (( $1 >= 1024 && $1 <= 49151 )); then
            forward_args+=("-L" "$1:127.0.0.1:$1")
            ports_display+=("$1")
          else echo "Warning: Invalid port number: $1"
          fi
        else echo "Warning: Invalid format: $1"
        fi
        shift
      done

      # --- The Core Logic ---
      if (( ${#forward_args[@]} > 0 )); then
        echo "Checking for existing master connection..."
        # Quietly check if a master is already running.
        if ssh -O check "$server" &>/dev/null; then
          echo "Warning: Master connection already exists for $server."
          echo "Tunnels cannot be added to a running connection."
          echo "To apply new tunnels, run 'ssh_connect stop $server' first."
        else
          echo "Establishing new background master connection for $server..."
          echo "Forwarding ports: ${ports_display[@]}"
          
          # -f: Go into the background
          # -N: Do not execute a remote command (just for tunnels)
          # -o ExitOnForwardFailure=yes: Crucial for reliability. The command will fail
          #   if any of the local ports are already in use.
          ssh -f -N -o ExitOnForwardFailure=yes "${forward_args[@]}" "$server"
          
          if [[ $? -eq 0 ]]; then
            echo "Tunnels successfully established in the background."
          else
            echo "Error: Failed to establish tunnels. A port might be in use or the server is unreachable."
            return 1
          fi
        fi
      fi

      # For the 'connect' command, open an interactive shell after setting up tunnels.
      # This will be an instant "slave" connection.
      if [[ "$command" == "connect" ]]; then
        echo "Opening interactive shell to $server..."
        ssh "$server"
      fi
      ;;
    *)
      echo "Error: Unknown command '$command'"
      return 1
      ;;
  esac
}

#compdef tailscale
compdef _tailscale tailscale

# Copyright 2013-2023 The Cobra Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# zsh completion for tailscale                            -*- shell-script -*-

__tailscale_debug()
{
    local file="$BASH_COMP_DEBUG_FILE"
    if [[ -n ${file} ]]; then
        echo "$*" >> "${file}"
    fi
}

_tailscale()
{
    local shellCompDirectiveError=1
    local shellCompDirectiveNoSpace=2
    local shellCompDirectiveNoFileComp=4
    local shellCompDirectiveFilterFileExt=8
    local shellCompDirectiveFilterDirs=16
    local shellCompDirectiveKeepOrder=32

    local lastParam lastChar flagPrefix requestComp out directive comp lastComp noSpace keepOrder
    local -a completions

    __tailscale_debug "\n========= starting completion logic =========="
    __tailscale_debug "CURRENT: ${CURRENT}, words[*]: ${words[*]}"

    # The user could have moved the cursor backwards on the command-line.
    # We need to trigger completion from the $CURRENT location, so we need
    # to truncate the command-line ($words) up to the $CURRENT location.
    # (We cannot use $CURSOR as its value does not work when a command is an alias.)
    words=("${=words[1,CURRENT]}")
    __tailscale_debug "Truncated words[*]: ${words[*]},"

    lastParam=${words[-1]}
    lastChar=${lastParam[-1]}
    __tailscale_debug "lastParam: ${lastParam}, lastChar: ${lastChar}"

    # For zsh, when completing a flag with an = (e.g., tailscale -n=<TAB>)
    # completions must be prefixed with the flag
    setopt local_options BASH_REMATCH
    if [[ "${lastParam}" =~ '-.*=' ]]; then
        # We are dealing with a flag with an =
        flagPrefix="-P ${BASH_REMATCH}"
    fi

    # Prepare the command to obtain completions
    requestComp="${words[1]} completion __complete --descs=true --flags=true -- ${words[2,-1]}"
    if [ "${lastChar}" = "" ]; then
        # If the last parameter is complete (there is a space following it)
        # We add an extra empty parameter so we can indicate this to the go completion code.
        __tailscale_debug "Adding extra empty parameter"
        requestComp="${requestComp} \"\""
    fi

    __tailscale_debug "About to call: eval ${requestComp}"

    # Use eval to handle any environment variables and such
    out=$(eval ${requestComp} 2>/dev/null)
    __tailscale_debug "completion output: ${out}"

    # Extract the directive integer following a : from the last line
    local lastLine
    while IFS='\n' read -r line; do
        lastLine=${line}
    done < <(printf "%s\n" "${out[@]}")
    __tailscale_debug "last line: ${lastLine}"

    if [ "${lastLine[1]}" = : ]; then
        directive=${lastLine[2,-1]}
        # Remove the directive including the : and the newline
        local suffix
        (( suffix=${#lastLine}+2))
        out=${out[1,-$suffix]}
    else
        # There is no directive specified.  Leave $out as is.
        __tailscale_debug "No directive found.  Setting do default"
        directive=0
    fi

    __tailscale_debug "directive: ${directive}"
    __tailscale_debug "completions: ${out}"
    __tailscale_debug "flagPrefix: ${flagPrefix}"

    if [ $((directive & shellCompDirectiveError)) -ne 0 ]; then
        __tailscale_debug "Completion received error. Ignoring completions."
        return
    fi

    while IFS='\n' read -r comp; do
        if [ -n "$comp" ]; then
            # If requested, completions are returned with a description.
            # The description is preceded by a TAB character.
            # For zsh's _describe, we need to use a : instead of a TAB.
            # We first need to escape any : as part of the completion itself.
            comp=${comp//:/\\:}

            local tab="$(printf '\t')"
            comp=${comp//$tab/:}

            __tailscale_debug "Adding completion: ${comp}"
            completions+=${comp}
            lastComp=$comp
        fi
    done < <(printf "%s\n" "${out[@]}")

    if [ $((directive & shellCompDirectiveNoSpace)) -ne 0 ]; then
        __tailscale_debug "Activating nospace."
        noSpace="-S ''"
    fi

    if [ $((directive & shellCompDirectiveKeepOrder)) -ne 0 ]; then
        __tailscale_debug "Activating keep order."
        keepOrder="-V"
    fi

    if [ $((directive & shellCompDirectiveFilterFileExt)) -ne 0 ]; then
        # File extension filtering
        local filteringCmd
        filteringCmd='_files'
        for filter in ${completions[@]}; do
            if [ ${filter[1]} != '*' ]; then
                # zsh requires a glob pattern to do file filtering
                filter="\*.$filter"
            fi
            filteringCmd+=" -g $filter"
        done
        filteringCmd+=" ${flagPrefix}"

        __tailscale_debug "File filtering command: $filteringCmd"
        _arguments '*:filename:'"$filteringCmd"
    elif [ $((directive & shellCompDirectiveFilterDirs)) -ne 0 ]; then
        # File completion for directories only
        local subdir
        subdir="${completions[1]}"
        if [ -n "$subdir" ]; then
            __tailscale_debug "Listing directories in $subdir"
            pushd "${subdir}" >/dev/null 2>&1
        else
            __tailscale_debug "Listing directories in ."
        fi

        local result
        _arguments '*:dirname:_files -/'" ${flagPrefix}"
        result=$?
        if [ -n "$subdir" ]; then
            popd >/dev/null 2>&1
        fi
        return $result
    else
        __tailscale_debug "Calling _describe"
        if eval _describe $keepOrder "completions" completions $flagPrefix $noSpace; then
            __tailscale_debug "_describe found some completions"

            # Return the success of having called _describe
            return 0
        else
            __tailscale_debug "_describe did not find completions."
            __tailscale_debug "Checking if we should do file completion."
            if [ $((directive & shellCompDirectiveNoFileComp)) -ne 0 ]; then
                __tailscale_debug "deactivating file completion"

                # We must return an error code here to let zsh know that there were no
                # completions found by _describe; this is what will trigger other
                # matching algorithms to attempt to find completions.
                # For example zsh can match letters in the middle of words.
                return 1
            else
                # Perform file completion
                __tailscale_debug "Activating file completion"

                # We must return the result of this command, so it must be the
                # last command, or else we must store its result to return it.
                _arguments '*:filename:_files'" ${flagPrefix}"
            fi
        fi
    fi
}

# don't run the completion function when being source-ed or eval-ed
if [ "$funcstack[1]" = "_tailscale" ]; then
    _tailscale
fi

# Source local/private environment variables if the file exists
if [ -f ~/.zsh_secrets ]; then
  source ~/.zsh_secrets
  # You could add a message to confirm it's loaded, e.g.:
  # echo "Sourced local secrets from ~/.zsh_secrets"
fi

# load completions
autoload -U compinit && compinit
