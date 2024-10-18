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

# load completions
autoload -U compinit && compinit

zinit cdreplay -q

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#ff00ff,bg=cyan,bold,underline"

# Export PATHs
export PATH="$PATH:/home/definevera/.pixi/bin"
export PATH="$PATH:/home/$USER/.local/bin"
export PATH="$PATH:/home/$USER/.dotnet/tools"
export PATH="$PATH:/home/$USER/Document/C4G/birdwatcher"
export PATH="$PATH:/opt/nvim-linux64/bin"
export PATH="$PATH:/home/$USER/Documents/Dylan/llama.cpp"
export PATH="$PATH:/usr/local/cuda/bin"
export PATH="$PATH:/usr/local/go/bin"
## bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Export external PATHs
export NVM_DIR="$HOME/.nvm"
export LD_LIBRARY_PATH="/usr/local/cuda/lib64:$LD_LIBRARY_PATH"
export DOCKER_HOST=unix:///var/run/docker.sock

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
alias ls='ls --color'
alias vim='nvim'
alias l='ls'
alias c='clear'
alias s='kitten ssh'
alias zupdate='source ~/.zshrc'
alias zconfig='vim ~/.zshrc'
alias adg='sudo apt update && sudo apt upgrade'
alias icat='kitten icat'

# SSH Aliases
## Port Forwarding (-L <local_port>:localhost:<remote_port>)
## Debug (-v)
alias rnd-dylan='ssh_connect dylan@10.32.10.178' 
alias rnd-user='ssh_connect user@10.32.10.178'
alias prod='ssh_connect chat4good@10.32.45.55'

# Shell integrations
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"

GPG_TTY=$(tty)
export GPG_TTY

# pyenv
# export PYENV_ROOT="$HOME/.pyenv"
# [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
# eval "$(pyenv init -)"

# nvm
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# pixi
eval "$(pixi completion --shell zsh)"

# deno
. "/home/definevera/.deno/env"

# pnpm
export PNPM_HOME="/home/definevera/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# bun completions
[ -s "/home/definevera/.bun/_bun" ] && source "/home/definevera/.bun/_bun"

# ssh QOL
ssh_connect() {
  local server=$1
  shift
  local forward_args=()
  
  while (( $# > 0 )); do
      forward_args+=("-L" "$1:127.0.0.1:$1")
      shift
  done
  
  if (( ${#forward_args[@]} > 0 )); then
      s "${forward_args[@]}" "$server"
  else
      s "$server"
  fi
}
