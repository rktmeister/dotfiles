# SSH connection manager

_ssh_connect_usage() {
  print -r -- "Usage: ssh_connect [connect|start|stop|status|add|cancel|list] <server_alias> [ports...] [-- ssh_options...]" >&2
  print -r -- "Example: ssh_connect start my-server 8080 9000-9010 -- -i ~/.ssh/id_rsa -p 2222" >&2
  print -r -- "Example: ssh_connect add my-server 5432 -- -i ~/.ssh/id_rsa" >&2
}

_ssh_connect_parse_ports() {
  emulate -L zsh -o err_return -o pipefail -o no_xtrace -o no_verbose
  setopt no_beep

  typeset -g -a _ssh_connect_forward_args
  typeset -g -a _ssh_connect_ports_display
  typeset -g -a _ssh_connect_port_specs

  _ssh_connect_forward_args=()
  _ssh_connect_ports_display=()
  _ssh_connect_port_specs=()

  local arg
  for arg in "$@"; do
    if [[ $arg =~ ^([0-9]+)-([0-9]+)$ ]]; then
      local start=${match[1]} end=${match[2]}
      if (( start >= 1024 && end <= 65535 && start <= end )); then
        local port
        for (( port=start; port<=end; port++ )); do
          _ssh_connect_forward_args+=("-L" "$port:127.0.0.1:$port")
          _ssh_connect_ports_display+=("$port")
          _ssh_connect_port_specs+=("${port}:${port}")
        done
      else
        print -r -- "Warning: Invalid port range: $arg" >&2
      fi
    elif [[ $arg =~ ^([0-9]+):([0-9]+)$ ]]; then
      local local_port=${match[1]} remote_port=${match[2]}
      if (( local_port >= 1024 && local_port <= 65535 && remote_port >= 1024 && remote_port <= 65535 )); then
        _ssh_connect_forward_args+=("-L" "$local_port:127.0.0.1:$remote_port")
        _ssh_connect_ports_display+=("${local_port}->${remote_port}")
        _ssh_connect_port_specs+=("${local_port}:${remote_port}")
      else
        print -r -- "Warning: Invalid port mapping: $arg" >&2
      fi
    elif [[ $arg =~ ^[0-9]+$ ]]; then
      if (( arg >= 1024 && arg <= 65535 )); then
        _ssh_connect_forward_args+=("-L" "$arg:127.0.0.1:$arg")
        _ssh_connect_ports_display+=("$arg")
        _ssh_connect_port_specs+=("${arg}:${arg}")
      else
        print -r -- "Warning: Invalid port number: $arg" >&2
      fi
    else
      print -r -- "Warning: Invalid format: $arg" >&2
    fi
  done
}

_ssh_connect_state_file() {
  emulate -L zsh -o err_return -o pipefail -o no_xtrace -o no_verbose
  setopt no_beep

  local server=$1
  local state_dir="${SSH_CONNECT_STATE_DIR:-$HOME/.ssh/ssh_connect}"
  local safe_server="${server//[^A-Za-z0-9_.@-]/_}"
  REPLY="$state_dir/$safe_server"
}

_ssh_connect_state_update_add() {
  emulate -L zsh -o err_return -o pipefail -o no_xtrace -o no_verbose
  setopt no_beep

  local server=$1
  shift
  (( $# > 0 )) || return 0

  _ssh_connect_state_file "$server"
  local state_file=$REPLY
  mkdir -p "${state_file:h}"

  local -A seen
  local -a ordered
  local line
  if [[ -f $state_file ]]; then
    while IFS= read -r line; do
      [[ -n $line ]] || continue
      if [[ -z ${seen[$line]} ]]; then
        seen[$line]=1
        ordered+=("$line")
      fi
    done < "$state_file"
  fi

  local spec
  for spec in "$@"; do
    if [[ -z ${seen[$spec]} ]]; then
      seen[$spec]=1
      ordered+=("$spec")
    fi
  done

  if (( ${#ordered[@]} )); then
    printf "%s\n" "${ordered[@]}" >| "$state_file"
  else
    : >| "$state_file"
  fi
}

_ssh_connect_state_update_cancel() {
  emulate -L zsh -o err_return -o pipefail -o no_xtrace -o no_verbose
  setopt no_beep

  local server=$1
  shift
  (( $# > 0 )) || return 0

  _ssh_connect_state_file "$server"
  local state_file=$REPLY
  [[ -f $state_file ]] || return 0

  local -A remove
  local spec
  for spec in "$@"; do
    remove[$spec]=1
  done

  local -a remaining
  local line
  while IFS= read -r line; do
    [[ -n $line ]] || continue
    [[ -z ${remove[$line]} ]] && remaining+=("$line")
  done < "$state_file"

  if (( ${#remaining[@]} )); then
    printf "%s\n" "${remaining[@]}" >| "$state_file"
  else
    : >| "$state_file"
  fi
}

_ssh_connect_state_clear() {
  emulate -L zsh -o err_return -o pipefail -o no_xtrace -o no_verbose
  setopt no_beep

  local server=$1
  _ssh_connect_state_file "$server"
  local state_file=$REPLY
  [[ -f $state_file ]] || return 0
  : >| "$state_file"
}

_ssh_connect_state_list() {
  emulate -L zsh -o err_return -o pipefail -o no_xtrace -o no_verbose
  setopt no_beep

  local server=$1
  _ssh_connect_state_file "$server"
  local state_file=$REPLY

  if [[ -s $state_file ]]; then
    print -r -- "Tracked forwards (added via ssh_connect):"
    local line
    while IFS= read -r line; do
      [[ -n $line ]] || continue
      print -r -- "  $line"
    done < "$state_file"
  else
    print -r -- "No tracked forwards for $server."
  fi
}

_ssh_connect_list_config_forwards() {
  emulate -L zsh -o err_return -o pipefail -o no_xtrace -o no_verbose
  setopt no_beep

  local server=$1
  shift

  local cfg
  cfg=$(ssh -G "$@" "$server" 2>/dev/null) || return 0

  local -a local_forwards=()
  local line
  while IFS= read -r line; do
    [[ $line == localforward\ * ]] || continue
    local listen connect rest
    rest="${line#localforward }"
    listen="${rest%% *}"
    connect="${rest#* }"
    [[ -n $listen && -n $connect && $connect != "$rest" ]] || continue
    local_forwards+=("${listen} -> ${connect}")
  done <<< "$cfg"

  if (( ${#local_forwards[@]} )); then
    print -r -- "Configured LocalForward entries (ssh -G):"
    local item
    for item in "${local_forwards[@]}"; do
      print -r -- "  $item"
    done
  else
    print -r -- "No LocalForward entries in ssh config for $server."
  fi
}

_ssh_connect_master_running() {
  emulate -L zsh -o err_return -o pipefail -o no_xtrace -o no_verbose
  setopt no_beep

  local server=$1
  shift
  ssh -O check "$@" "$server" &>/dev/null
}

_ssh_connect_start_master() {
  emulate -L zsh -o err_return -o pipefail -o no_xtrace -o no_verbose
  setopt no_beep

  local server=$1
  shift
  local -a ssh_opts=("$@")
  local ports_display="${(j: :)_ssh_connect_ports_display}"

  print -r -- "Establishing new background master connection for $server..."
  [[ -n $ports_display ]] && print -r -- "Forwarding ports: ${ports_display}"
  ssh -f -N -o ExitOnForwardFailure=yes "${_ssh_connect_forward_args[@]}" "${ssh_opts[@]}" "$server"
  if [[ $? -eq 0 ]]; then
    if [[ -n $ports_display ]]; then
      print -r -- "Tunnels successfully established in the background."
      _ssh_connect_state_update_add "$server" "${_ssh_connect_port_specs[@]}"
    else
      print -r -- "Master connection established in the background."
    fi
  else
    print -r -- "Error: Failed to establish master connection. A port might be in use or the server is unreachable." >&2
    return 1
  fi
}

_ssh_connect_apply_existing_forward() {
  emulate -L zsh -o err_return -o pipefail -o no_xtrace -o no_verbose
  setopt no_beep

  local action=$1
  local server=$2
  shift 2
  local -a ssh_opts=("$@")
  local ports_display="${(j: :)_ssh_connect_ports_display}"

  case "$action" in
    forward)
      print -r -- "Adding forwards to existing master for $server..."
      if ssh -O forward "${_ssh_connect_forward_args[@]}" "${ssh_opts[@]}" "$server"; then
        [[ -n $ports_display ]] && print -r -- "Forwarding updated: ${ports_display}"
        _ssh_connect_state_update_add "$server" "${_ssh_connect_port_specs[@]}"
      else
        print -r -- "Warning: Failed to add forwards to existing master." >&2
        print -r -- "Run 'ssh_connect stop $server' then retry to apply new tunnels." >&2
        return 1
      fi
      ;;
    cancel)
      print -r -- "Canceling forwards on existing master for $server..."
      if ssh -O cancel "${_ssh_connect_forward_args[@]}" "${ssh_opts[@]}" "$server"; then
        [[ -n $ports_display ]] && print -r -- "Forwarding canceled: ${ports_display}"
        _ssh_connect_state_update_cancel "$server" "${_ssh_connect_port_specs[@]}"
      else
        print -r -- "Warning: Failed to cancel forwards on existing master." >&2
        return 1
      fi
      ;;
    *)
      print -r -- "Error: Unknown forward action '$action'" >&2
      return 2
      ;;
  esac
}

ssh_connect() {
  emulate -L zsh -o err_return -o pipefail -o no_xtrace -o no_verbose
  setopt no_beep

  if [[ $# -lt 1 ]]; then
    _ssh_connect_usage
    return 1
  fi

  local command=connect
  local server=""

  # Handle implicit 'connect' command
  case "$1" in
    connect|start|stop|status|add|cancel|list)
      command=$1
      server=${2:-}
      shift 2
      ;;
    *)
      server=$1
      shift
      ;;
  esac

  if [[ -z $server ]]; then
    print -r -- "Error: missing server alias." >&2
    _ssh_connect_usage
    return 1
  fi

  # Separate port arguments from pass-through ssh options
  local -a port_args
  local -a ssh_opts
  while (( $# > 0 )); do
    if [[ "$1" == "--" ]]; then
      shift # Consume the '--'
      ssh_opts=("$@") # The rest of the arguments are for ssh
      break
    fi
    port_args+=("$1")
    shift
  done

  case "$command" in
    stop)
      print -r -- "Stopping SSH master connection and tunnels for $server..."
      ssh -O exit "${ssh_opts[@]}" "$server"
      local rc=$?
      if (( rc == 0 )); then
        _ssh_connect_state_clear "$server"
      fi
      return $rc
      ;;
    status)
      print -r -- "Checking status of SSH master connection for $server..."
      ssh -O check "${ssh_opts[@]}" "$server"
      ;;
    start|connect)
      _ssh_connect_parse_ports "${port_args[@]}"
      if (( ${#_ssh_connect_forward_args[@]} > 0 )) || [[ "$command" == "start" ]]; then
        print -r -- "Checking for existing master connection..."
        if _ssh_connect_master_running "$server" "${ssh_opts[@]}"; then
          if (( ${#_ssh_connect_forward_args[@]} > 0 )); then
            _ssh_connect_apply_existing_forward forward "$server" "${ssh_opts[@]}"
          else
            print -r -- "Master connection already exists for $server."
          fi
        else
          _ssh_connect_start_master "$server" "${ssh_opts[@]}" || return 1
        fi
      fi

      if [[ "$command" == "connect" ]]; then
        print -r -- "Opening interactive shell to $server..."
        ssh "${ssh_opts[@]}" "$server"
      fi
      ;;
    add|cancel)
      if (( ${#port_args[@]} == 0 )); then
        print -r -- "Error: $command requires one or more port arguments." >&2
        return 1
      fi

      _ssh_connect_parse_ports "${port_args[@]}"
      if (( ${#_ssh_connect_forward_args[@]} == 0 )); then
        print -r -- "Error: no valid port arguments provided." >&2
        return 1
      fi

      print -r -- "Checking for existing master connection..."
      if _ssh_connect_master_running "$server" "${ssh_opts[@]}"; then
        _ssh_connect_apply_existing_forward "$command" "$server" "${ssh_opts[@]}"
      else
        if [[ "$command" == "add" ]]; then
          print -r -- "No master connection for $server. Establishing one..."
          _ssh_connect_start_master "$server" "${ssh_opts[@]}" || return 1
        else
          print -r -- "Warning: No master connection for $server; nothing to cancel." >&2
          return 1
        fi
      fi
      ;;
    list)
      print -r -- "Checking status of SSH master connection for $server..."
      if _ssh_connect_master_running "$server" "${ssh_opts[@]}"; then
        print -r -- "Master is running."
      else
        print -r -- "Master is not running."
      fi
      _ssh_connect_state_list "$server"
      _ssh_connect_list_config_forwards "$server" "${ssh_opts[@]}"
      ;;
    *)
      print -r -- "Error: Unknown command '$command'" >&2
      return 1
      ;;
  esac
}
