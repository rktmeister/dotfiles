# .zshrc config file for DefiNevera

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
export PATH="$PATH:/home/definevera/.local/bin"
export PATH="$PATH:/home/definevera/.dotnet/tools"
export PATH="$PATH:/home/definevera/Document/C4G/birdwatcher"
export PATH="$PATH:/opt/nvim-linux64/bin"
export PATH="$PATH:/home/definevera/Documents/Dylan/llama.cpp"
export PATH="$PATH:/usr/local/cuda/bin"
export PATH="$PATH:/usr/local/go/bin"

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
alias rnd='s -L 8080:localhost:8000 dylan@10.32.10.178'
alias main='s chat4good@10.32.45.55'

# Shell integrations
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# nvm
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
