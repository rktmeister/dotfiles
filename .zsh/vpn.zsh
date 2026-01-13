# VPN switcher

vpn() {
  emulate -L zsh -o err_return -o pipefail
  setopt no_beep

  # Override in rc if names differ. Flags should be a zsh array.
  # typeset -ga VPN_TS_UP_FLAGS=(--accept-dns=false --hostname=my-box)
  local ZSCALER_AGENT="${ZSCALER_AGENT:-zsaservice}"
  local ZSCALER_TUNNEL="${ZSCALER_TUNNEL:-zstunnel}"

  # Lazy binary discovery
  local TS
  TS=$(command -v tailscale 2>/dev/null || true)

  # Helpers
  if [[ $EUID -eq 0 ]]; then
    _sudo() { print -r -- "--> $*"; "$@"; }
  else
    _sudo() { print -r -- "--> sudo $*"; sudo "$@"; }
  fi
  _active() { systemctl is-active --quiet "$1"; }
  _unit_loaded() { [[ "$(systemctl show -p LoadState --value "$1" 2>/dev/null)" == "loaded" ]]; }
  _ts_up() {
    [[ -n $TS ]] || { print -r -- "tailscale CLI not found"; return 127; }
    local -a flags=()
    if (( ${+VPN_TS_UP_FLAGS} )) && [[ ${(t)VPN_TS_UP_FLAGS} == *array* ]]; then
      flags=("${(@)VPN_TS_UP_FLAGS}")
    elif [[ -n ${VPN_TS_UP_FLAGS:-} ]]; then
      setopt localoptions noglob
      flags=(${=VPN_TS_UP_FLAGS})
    fi
    _sudo "$TS" up "${flags[@]}"
  }


  # Snapshot for rollback
  local -a PREV_UNITS=()
  local prev_ts=0
  _active tailscaled && { PREV_UNITS+=("tailscaled"); prev_ts=1; }
  _active "$ZSCALER_AGENT" && PREV_UNITS+=("$ZSCALER_AGENT")
  _active "$ZSCALER_TUNNEL" && PREV_UNITS+=("$ZSCALER_TUNNEL")

  rollback() {
    print -r -- "\n!! VPN switch failed. Attempting rollback to: ${PREV_UNITS[*]:-(none)}"
    if (( ${#PREV_UNITS[@]} )); then
      _sudo systemctl restart "${PREV_UNITS[@]}" || print -r -- "!! Unit restart rollback failed"
      (( prev_ts )) && { _ts_up || print -r -- "!! tailscale up rollback failed"; }
    else
      print -r -- "!! No prior units to restore"
    fi
  }

  case "${1:-}" in
    zscaler)
      # Already on Zscaler
      if ! _active tailscaled && { _active "$ZSCALER_AGENT" || _active "$ZSCALER_TUNNEL"; }; then
        print -r -- "--> Zscaler already active"
        return 0
      fi
      sudo -v || return 1
      trap 'rollback' ZERR

      print -r -- "--> Deactivating Tailscale"
      if _active tailscaled; then
        if [[ -n $TS ]] && ! _sudo "$TS" down; then
          print -r -- "!! tailscale down failed, proceeding to stop"
        fi
        _sudo systemctl stop tailscaled
      fi
      # no tailscaled --cleanup

      print -r -- "--> Activating Zscaler (agent then tunnel)"
      local did_any=0
      if _unit_loaded "$ZSCALER_AGENT"; then _sudo systemctl restart "$ZSCALER_AGENT"; did_any=1; fi
      if _unit_loaded "$ZSCALER_TUNNEL"; then _sudo systemctl restart "$ZSCALER_TUNNEL"; did_any=1; fi
      (( did_any )) || { print -r -- "!! No Zscaler units found"; return 1; }
      ;;

    tailscale)
      # Already on Tailscale
      if _active tailscaled && ! _active "$ZSCALER_AGENT" && ! _active "$ZSCALER_TUNNEL"; then
        print -r -- "--> Tailscale already active"
        return 0
      fi
      [[ -n $TS ]] || { print -r -- "tailscale CLI not found"; return 127; }
      sudo -v || return 1
      trap 'rollback' ZERR

      print -r -- "--> Deactivating Zscaler"
      local -a stops=()
      _unit_loaded "$ZSCALER_AGENT"  && stops+=("$ZSCALER_AGENT")
      _unit_loaded "$ZSCALER_TUNNEL" && stops+=("$ZSCALER_TUNNEL")
      (( ${#stops[@]} )) && _sudo systemctl stop "${stops[@]}"

      print -r -- "--> Activating Tailscale"
      _sudo systemctl restart tailscaled
      [[ -z "${VPN_SKIP_TS_UP:-}" ]] && _ts_up
      ;;

    status)
      {
        systemctl status --no-pager tailscaled "$ZSCALER_AGENT" "$ZSCALER_TUNNEL"
        if _active tailscaled && command -v tailscale >/dev/null 2>&1; then
          tailscale status || true
        fi
      } || true
      return
      ;;

    *)
      print -r -- 'usage: vpn {zscaler|tailscale|status}' >&2
      return 2
      ;;
  esac

  trap - ZERR
  print -r -- "\n--> Switch successful. Final Status:"
  vpn status
}

# Completion
autoload -Uz compdef
_vpn_complete() { compadd zscaler tailscale status }
compdef _vpn_complete vpn
