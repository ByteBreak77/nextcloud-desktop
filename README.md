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

Copy `deploy/docker-compose.yml` to the target server and replace:

```text
GITHUB_USER
```

with your GitHub username or organization.

Example:

```yaml
services:
  nextcloud-desktop:
    image: ghcr.io/itwissen-yt/nextcloud-desktop:latest
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

## Publish to GitHub Container Registry

This repository includes `.github/workflows/docker-publish.yml`.

Push the repository to GitHub with the default branch `main`. Every push to `main` builds and publishes:

```text
ghcr.io/YOUR_GITHUB_USERNAME/nextcloud-desktop:latest
```

A Git tag such as:

```bash
git tag v1.0.0
git push origin v1.0.0
```

also publishes a versioned image tag.

## Initial Git commands

```bash
git init
git add .
git commit -m "Initial Nextcloud Desktop image"
git branch -M main
git remote add origin https://github.com/YOUR_GITHUB_USERNAME/nextcloud-desktop.git
git push -u origin main
```

## Watchtower

Watchtower can update the running container when a new `latest` image is published.

If your Watchtower installation is configured with label filtering, the supplied deployment Compose already contains:

```text
com.centurylinklabs.watchtower.enable=true
```

For a private GHCR image, the target Docker host must be authenticated to `ghcr.io`. For a public container package, authentication is generally not needed for pulling.

## Updating

Development side:

```bash
git add .
git commit -m "Update image"
git push
```

GitHub Actions then builds and publishes the new image. The target server can pull it manually with:

```bash
docker compose pull
docker compose up -d
```

or automatically through Watchtower.

## Important update behavior

Do not delete the mounted `Config` and `Data` directories. Replacing the container or updating the image is safe as long as these mounts stay in place.


## Third-party software and trademarks

This project packages third-party open-source software, including:

- LinuxServer.io Webtop
- Nextcloud Desktop Client
- Debian packages

The Nextcloud Desktop Client is distributed under GPL-2.0-or-later.

This is an unofficial community project.
It is not affiliated with or endorsed by Nextcloud GmbH or LinuxServer.io.

All product names, trademarks and registered trademarks belong to their respective owners.
