# Nextcloud Desktop in Docker (Webtop + XFCE)

[![GitHub repository](https://img.shields.io/badge/Source-GitHub-informational)](https://github.com/ByteBreak77/nextcloud-desktop)

**Unofficial community container** with a browser-based XFCE desktop, Firefox,
Thunar and the Nextcloud Desktop Client. The image is built by GitHub Actions
and published to GitHub Container Registry (GHCR).

## Install in Portainer: no scripts, no local build

Prerequisites: Docker + Portainer. The ready-made image must have been built
successfully and be available at:

```text
ghcr.io/bytebreak77/nextcloud-desktop:latest
```

1. Open **Portainer > Stacks > Add stack > Web editor**.
2. Paste [`deploy/portainer-stack.yml`](deploy/portainer-stack.yml).
3. Define the following **Stack environment variables** to choose your host
   paths and host port. These are example values, not hard-coded paths:

   | Variable | Example |
   | --- | --- |
   | `CONFIG_PATH` | `/srv/nextcloud-desktop/Config` |
   | `DATA_PATH` | `/srv/nextcloud-desktop/Data` |
   | `WEB_PORT` | `3100` |
   | `PUID` | `1000` |
   | `PGID` | `1000` |
   | `TZ` | `Europe/Berlin` |

4. Click **Deploy the stack**. Docker creates missing host directories for
   the two bind mounts. Portainer pulls the finished image automatically;
   an optional manual download is:

   ```bash
   docker pull ghcr.io/bytebreak77/nextcloud-desktop:latest
   ```

5. Open `https://YOUR-SERVER-IP:3100` (adjust if you changed `WEB_PORT`).
   A certificate warning is possible with Webtop's local HTTPS certificate.
6. Open Nextcloud in the XFCE desktop, sign in and select a local sync folder
   **inside `/client-data`**, for example `/client-data/Nextcloud`.

The synchronized files will then appear in `DATA_PATH/Nextcloud` on the host.

### Example Portainer stack

```yaml
# Portainer > Stacks > Add stack > Web editor
# Prebuilt image from GitHub Container Registry; NO build and NO host setup.
# Set CONFIG_PATH, DATA_PATH and optionally WEB_PORT in Portainer.
services:
  nextcloud-desktop:
    image: ghcr.io/bytebreak77/nextcloud-desktop:latest
    container_name: nextcloud-desktop
    restart: unless-stopped
    ports:
      - "${WEB_PORT:-3100}:3001"
    environment:
      PUID: "${PUID:-1000}"
      PGID: "${PGID:-1000}"
      TZ: "${TZ:-Europe/Berlin}"
    volumes:
      - type: bind
        source: "${CONFIG_PATH:-/opt/nextcloud-desktop/Config}"
        target: /config
        bind:
          create_host_path: true
      - type: bind
        source: "${DATA_PATH:-/opt/nextcloud-desktop/Data}"
        target: /client-data
        bind:
          create_host_path: true
    shm_size: "1gb"
```

## Login credentials persist across container updates

The container installs GNOME Keyring and opens it in the Nextcloud desktop
session before launching the client. **On first start**, the container creates
a random password inside the persistent `/config` mount:

```text
/config/.local/share/nextcloud-desktop/keyring-password
```

The encrypted keyring is also kept in the same persistent mount:

```text
/config/.local/share/keyrings/
```

This means **only `Config` and `Data` need mounting**. You do not create a
password file, execute a preparation script or manage an extra secret mount
on the destination host. On every restart the password is reused; it is
neither regenerated nor included in the image.

**Security trade-off:** the keyring's unlock password and encrypted keyring
live in the *same* host-mounted Config directory. This maximizes unattended
installation convenience but **does not protect credentials from an attacker
who gains access to your Config files**. Restrict host access and secure
your backups. Do not commit Config to GitHub.

**Migration:** if you already used the older three-mount setup, the image
can migrate its previous read-only `/run/secrets/nextcloud-keyring-password`
into Config *if you keep that legacy mount for one startup*. When upgrading
from a version without a keyring, a **one-time Nextcloud browser login** may
be required to store its token. An unknown existing keyring password cannot
be recovered by this container. Existing Nextcloud sync folders are never
intentionally deleted or reinitialized by the bootstrap scripts.

**Keep the same `CONFIG_PATH` and `DATA_PATH` across all updates.** Back up
both. The current keyring integration has undergone static validation but
still needs a real Docker restart test; it is not yet a verified fix.

## Build, publication, and updates

Source code is in this repository. GitHub Actions builds the multi-arch
image (`linux/amd64` and `linux/arm64`) and publishes it to:

```text
ghcr.io/bytebreak77/nextcloud-desktop:latest
```

Workflow triggers: push to `main`, manual `workflow_dispatch`, and the
scheduled monthly rebuild on the 1st at 03:00 UTC. Packages are installed
from the **Debian repository used by the base image**; a new upstream
Nextcloud release is not necessarily packaged immediately.

To upgrade a Portainer deployment, redeploy the stack and select **Re-pull
image**. A separate image-watcher (if already installed) can also replace
the container. Neither update method changes the host-mounted Config/Data.

### Local development (optional)

```bash
git clone https://github.com/ByteBreak77/nextcloud-desktop.git
cd nextcloud-desktop
docker compose up -d --build
```

The root `docker-compose.yml` is for *local building* and includes `build:`;
use `deploy/portainer-stack.yml` for installing from GHCR.

## Troubleshooting

See container logs via Portainer. In the XFCE desktop Terminal you can check
that Secret Service is available without displaying any tokens:

```bash
gdbus call --session --dest org.freedesktop.DBus \
  --object-path /org/freedesktop/DBus \
  --method org.freedesktop.DBus.NameHasOwner org.freedesktop.secrets
```

This should report `true`. Do **not** post your token, the contents of the
password file or the keyring database in public issues.

## Security and licensing

Webtop has **no authentication by default**, so use it on a trusted LAN
only or configure protective authentication/reverse proxy/VPN. Do not
publicly forward Webtop's HTTPS port. See
[LinuxServer's Webtop security guidance](https://docs.linuxserver.io/images/docker-webtop/).

This is an unofficial community project and is not endorsed by Nextcloud
or LinuxServer.io. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
