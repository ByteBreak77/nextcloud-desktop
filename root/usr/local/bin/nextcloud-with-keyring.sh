#!/usr/bin/env bash
# Runs inside the XFCE user session (typically "abc"). This version does
# not require a password/secret file to be created on the Docker host.
set -Eeuo pipefail

log() { printf '[nextcloud-keyring] %s\n' "$*" >&2; }
fail() { log "ERROR: $*"; exit 1; }

# LinuxServer Webtop mounts the persistent user home at /config.
export HOME=/config
export XDG_CONFIG_HOME=/config/.config
export XDG_DATA_HOME=/config/.local/share
umask 077

state_dir="$XDG_DATA_HOME/nextcloud-desktop"
keyring_dir="$XDG_DATA_HOME/keyrings"
mkdir -p "$state_dir" "$keyring_dir"
chmod 0700 "$state_dir" "$keyring_dir"

# First run: generate a random keyring password *inside persistent /config*.
# Later runs reuse precisely the same file. The password is NEVER baked
# into the Docker image, printed, or stored in the repository.
secret_file="$state_dir/keyring-password"
legacy_secret=/run/secrets/nextcloud-keyring-password

if [[ ! -e "$secret_file" && -r "$legacy_secret" && -s "$legacy_secret" ]]; then
    # Optional one-time migration when upgrading a previous 3-mount stack.
    temp_file="$(mktemp "$state_dir/.keyring-password.XXXXXXXX")"
    trap 'rm -f "$temp_file"' EXIT
    cat "$legacy_secret" > "$temp_file"
    chmod 0600 "$temp_file"
    ln "$temp_file" "$secret_file" 2>/dev/null || true
    rm -f "$temp_file"
    trap - EXIT
    log 'Migrated existing host keyring password into persistent /config'
fi

if [[ ! -e "$secret_file" ]]; then
    # Atomic create: never overwrite an existing file, even if two clients
    # happen to start at almost the same time.
    temp_file="$(mktemp "$state_dir/.keyring-password.XXXXXXXX")"
    trap 'rm -f "$temp_file"' EXIT
    openssl rand -hex 32 > "$temp_file" || fail 'Unable to generate keyring password'
    chmod 0600 "$temp_file"
    if ln "$temp_file" "$secret_file" 2>/dev/null; then
        log 'Generated a persistent keyring password in /config (first start)'
    fi
    rm -f "$temp_file"
    trap - EXIT
fi

[[ -f "$secret_file" && -s "$secret_file" && -r "$secret_file" ]] ||
    fail 'Could not read persistent keyring password in /config; check permissions'
chmod 0600 "$secret_file"

# The keyring and QtKeychain must share ONE session D-Bus. XFCE normally
# supplies it; when absent, start a private bus for both processes.
if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
    log 'No desktop session D-Bus detected; starting one for Nextcloud'
    exec dbus-run-session -- "$0" --session-bus-ready
fi

keyring_password="$(cat "$secret_file")"
[[ -n "$keyring_password" ]] || fail 'Persistent keyring password is empty'

# --unlock creates the login keyring if absent, and unlocks it otherwise.
# Do this BEFORE starting Nextcloud so QtKeychain can read saved tokens.
if ! daemon_env="$(printf '%s' "$keyring_password" | gnome-keyring-daemon --unlock --components=secrets)"; then
    unset keyring_password
    fail 'Keyring unlock failed (existing keyring may require an older password)'
fi
unset keyring_password

# The environment assignments are produced by the installed binary.
if [[ -n "$daemon_env" ]]; then
    eval "$daemon_env"
    for keyring_variable in GNOME_KEYRING_CONTROL GNOME_KEYRING_PID SSH_AUTH_SOCK; do
        if [[ -n "${!keyring_variable:-}" ]]; then export "$keyring_variable"; fi
    done
fi
if ! daemon_env="$(gnome-keyring-daemon --start --components=secrets)"; then
    fail 'Failed to initialize GNOME Keyring'
fi
if [[ -n "$daemon_env" ]]; then
    eval "$daemon_env"
    for keyring_variable in GNOME_KEYRING_CONTROL GNOME_KEYRING_PID SSH_AUTH_SOCK; do
        if [[ -n "${!keyring_variable:-}" ]]; then export "$keyring_variable"; fi
    done
fi
unset daemon_env

ready=false
for attempt in $(seq 1 30); do
    reply="$(timeout 3s gdbus call --session \
      --dest org.freedesktop.DBus \
      --object-path /org/freedesktop/DBus \
      --method org.freedesktop.DBus.NameHasOwner \
      org.freedesktop.secrets 2>/dev/null || true)"
    if [[ "$reply" == *true* ]]; then
        ready=true
        break
    fi
    sleep 0.25
done
[[ "$ready" == true ]] || fail 'Secret Service is not available on the session D-Bus'

# Fail visibly if the existing login collection is still locked. Do not
# silently trigger a fresh browser login on every container restart.
lock_state="$(timeout 3s gdbus call --session \
  --dest org.freedesktop.secrets \
  --object-path /org/freedesktop/secrets/collection/login \
  --method org.freedesktop.DBus.Properties.Get \
  org.freedesktop.Secret.Collection Locked 2>/dev/null || true)"
if [[ "$lock_state" == *true* ]]; then
    fail 'Login keyring remains locked; preserve /config and check existing keyring credentials'
fi

log 'Secret Service is ready; starting Nextcloud Desktop Client'
exec /usr/bin/nextcloud
