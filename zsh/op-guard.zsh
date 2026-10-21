# Trust the Homebrew 1Password CLI only when it is still the AgileBits build
# from the official tap, then allow the shell to run it and clear macOS'
# download quarantine flag. Fail closed on anything else.
#
# One-time key import, if `gpg --verify` reports no public key:
#   gpg --keyserver keyserver.ubuntu.com --receive-keys 3FEF9748469ADBE15DA7CA80AC2D62742012EA22
# https://www.1password.dev/cli/verify

typeset -g _op_trust_stamp=""
typeset -g _op_trust_error=""

# External binary only. `whence -p` ignores the `op` function defined below.
op_cask_path() {
  local op_path
  op_path="$(whence -p op 2>/dev/null)" || return 1
  [[ -n "$op_path" && -e "$op_path" ]] || return 1
  op_path="${op_path:A}"
  [[ "$op_path" == */Caskroom/1password-cli/*/op ]] || return 1
  print -r -- "$op_path"
}

_op_receipt_tap() {
  python3 -c 'import json, sys
try:
    print(json.load(open(sys.argv[1], encoding="utf-8"))["source"]["tap"])
except Exception:
    raise SystemExit(1)' "$1" 2>/dev/null
}

_op_codesign_valid() {
  local req
  codesign --verify --strict "$1" 2>/dev/null || return 1
  req="$(codesign -d -r- "$1" 2>&1)" || return 1
  [[ "$req" == *'identifier "com.1password.op"'* ]] || return 1
  [[ "$req" == *'certificate leaf[subject.OU] = "2BUA8C4S2C"'* ]] || return 1
}

# Exit 2 on timeout so a stuck keyring cannot hold the shell open.
_op_gpg_valid() {
  python3 - "$1" "$2" <<'PY'
import subprocess
import sys

signature, binary = sys.argv[1], sys.argv[2]
fingerprint = "3FEF9748469ADBE15DA7CA80AC2D62742012EA22"
try:
    result = subprocess.run(
        ["gpg", "--batch", "--no-tty", "--status-fd", "1", "--verify", signature, binary],
        timeout=8,
        capture_output=True,
        text=True,
    )
except subprocess.TimeoutExpired:
    raise SystemExit(2)
if result.returncode != 0:
    raise SystemExit(1)
for line in result.stdout.splitlines():
    if line.startswith("[GNUPG:] VALIDSIG ") and fingerprint in line.split():
        raise SystemExit(0)
raise SystemExit(1)
PY
}

op_trusted() {
  local op_path stamp receipt tap sig gpg_rc
  _op_trust_error=""

  op_path="$(op_cask_path)" || {
    _op_trust_error="path"
    return 1
  }
  stamp="$(stat -f '%i:%m:%z' "$op_path" 2>/dev/null)" || {
    _op_trust_error="stat"
    return 1
  }
  if [[ -n "$_op_trust_stamp" && "$stamp" == "$_op_trust_stamp" ]]; then
    return 0
  fi

  receipt="${op_path:h:h}/.metadata/INSTALL_RECEIPT.json"
  tap="$(_op_receipt_tap "$receipt")" || {
    _op_trust_error="tap"
    return 1
  }
  [[ "$tap" == "1password/tap" ]] || {
    _op_trust_error="tap"
    return 1
  }

  _op_codesign_valid "$op_path" || {
    _op_trust_error="codesign"
    return 1
  }

  sig="${op_path:h}/op.sig"
  [[ -f "$sig" ]] || {
    _op_trust_error="gpg"
    return 1
  }
  _op_gpg_valid "$sig" "$op_path"
  gpg_rc=$?
  if (( gpg_rc == 2 )); then
    _op_trust_error="gpg-timeout"
    return 1
  fi
  if (( gpg_rc != 0 )); then
    _op_trust_error="gpg"
    return 1
  fi

  _op_trust_stamp="$stamp"
  return 0
}

op_trust_error() {
  print -u2 "op blocked: authenticity check failed${_op_trust_error:+ (${_op_trust_error})}"
}

# Clear the download flag only after op_trusted has accepted this inode.
unquarantine_op() {
  local op_path
  op_path="$(op_cask_path)" || return 0
  op_trusted || return 1
  xattr -p com.apple.quarantine "$op_path" &>/dev/null || return 0
  xattr -d com.apple.quarantine "$op_path" 2>/dev/null || true
}

op() {
  whence -p op >/dev/null 2>&1 || {
    print -u2 "zsh: command not found: op"
    return 127
  }
  if ! op_trusted; then
    op_trust_error
    return 1
  fi
  command op "$@"
}

# Call after oh-my-zsh so the wrapper is the brew the interactive shell runs.
op_guard_wrap_brew() {
  brew() {
    command brew "$@"
    local rc=$?
    if (( rc == 0 )); then
      case "${1:-}" in
        install|upgrade|reinstall|bundle)
          _op_trust_stamp=""
          if whence -p op >/dev/null 2>&1; then
            if op_trusted; then
              unquarantine_op
            else
              op_trust_error
            fi
          fi
          ;;
      esac
    fi
    return $rc
  }
}
