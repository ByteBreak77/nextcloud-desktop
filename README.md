# Nextcloud Desktop in Docker

A browser-accessible XFCE desktop with Firefox, Thunar and the Nextcloud Desktop Client.

## Features

- Web desktop via LinuxServer Webtop
- Nextcloud Desktop Client
- Firefox browser
- Thunar file manager
- Persistent desktop and Nextcloud configuration
- Persistent Nextcloud sync data
- Ready for GitHub Container Registry (GHCR)
- Watchtower-friendly deployment

## Persistent data

Two host directories are mounted into the container:

- `./Config` -> `/config`
- `./Data` -> `/client-data`

`/config` stores the Webtop user profile and Nextcloud client configuration. This is why a container/image update does not require setting up the Nextcloud account again.

`/client-data` stores the files synchronized by the Nextcloud Desktop Client.

## Local build and test

```bash
chmod +x build-and-start.sh
./build-and-start.sh
```

Then open:

```text
https://SERVER-IP:3100
```

The service uses HTTPS on port 3001 inside the container. Therefore use `https://`, not `http://`.

## First Nextcloud setup

1. Open the web desktop.
2. Start **Nextcloud**.
3. Enter the Nextcloud server URL and authorize the client.
4. When Nextcloud asks for the local sync folder, change it to:

```text
/client-data/Nextcloud
```

or another subdirectory below `/client-data`.

Example:

```text
/client-data/test-Nextcloud
```

Do **not** select a directory under the container's temporary filesystem if you want the files to survive container recreation.

## Docker Compose for deployment
Example:

```yaml
services:
  nextcloud-desktop:
    image: ghcr.io/bytebreak77/nextcloud-desktop:latest
    container_name: nextcloud-desktop
    restart: unless-stopped
    ports:
      - "3100:3001"
    environment:
      PUID: 1000
      PGID: 1000
      TZ: Europe/Berlin
    volumes:
      - ./Config:/config
      - ./Data:/client-data
    shm_size: "1gb"
    labels:
      - "com.centurylinklabs.watchtower.enable=true"
```

Create the directories before the first start:

```bash
mkdir -p Config Data
docker compose up -d
```

## Third-party software and trademarks

This project packages third-party open-source software, including:

- LinuxServer.io Webtop
- Nextcloud Desktop Client
- Debian packages

The Nextcloud Desktop Client is distributed under GPL-2.0-or-later.

This is an unofficial community project.
It is not affiliated with or endorsed by Nextcloud GmbH or LinuxServer.io.

All product names, trademarks and registered trademarks belong to their respective owners.
