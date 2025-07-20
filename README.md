# Dotfiles

This repository contains all the necessary dotfiles that I need for any Linux machine.

## Requirements

The `.zshrc` file contains configurations for `zoxide`, `fzf`, and `oh-my-posh`, `tmux` which requires initial setup before we can continue using the config. 

**[zoxide](https://github.com/ajeetdsouza/zoxide)**:
```
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
```

**[fzf](https://github.com/junegunn/fzf?tab=readme-ov-file#using-git)**:
```
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install
```

**[oh-my-posh](https://ohmyposh.dev/docs/installation/linux)**:
```
curl -s https://ohmyposh.dev/install.sh | bash -s
```

**[tmux](https://github.com/tmux/tmux)** + **[TPM](https://github.com/tmux-plugins/tpm)**:

Install tmux using package manager.

```
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

## Setup

Clone this repo in the `$HOME` directory, cd into `dotfiles/`, and then run `stow --adopt .` to create the symlinks.

If `stow` is not yet installed, you should do so with whatever package manager your OS is using.

### Completions

1. `mkdir -p ~/.zsh/completions/`
1. Create the completions file for all of your tools that you have, below is a couple of the common and popular tools

```bash


```

Once all of the completions file have been created, simply run `zrecomp` and this will enable completions. If you do add more tools and it has its own completions, remember to run `zrecomp` again after adding it into the folder.

### Environment Variables + Claude Code Router

Once you've cloned this repo, make sure to add in the .zsh_secrets file to store all of your API keys that you want to export as an environment variable.

Then, once you've set all of your API keys, `cd .claude-code-router` and run `envsubst < config.json.example > config.json`. This will create the `config.json` file for you without having to manually fill in each provider's API key.
