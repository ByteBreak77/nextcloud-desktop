FROM lscr.io/linuxserver/webtop:debian-xfce

LABEL org.opencontainers.image.source="https://github.com/ByteBreak77/nextcloud-desktop" \
      org.opencontainers.image.title="Nextcloud Desktop Web Container" \
      org.opencontainers.image.description="XFCE web desktop with Nextcloud sync and a persistent auto-unlocked keyring"

# Nextcloud uses QtKeychain / Secret Service for its login token.
# GNOME Keyring and its session D-Bus are provided inside this image.
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
         nextcloud-desktop \
         firefox-esr \
         thunar \
         curl \
         ca-certificates \
         nano \
         gnome-keyring \
         libsecret-tools \
         dbus \
         dbus-x11 \
         libglib2.0-bin \
         openssl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY root/ /
RUN chmod 0755 /custom-cont-init.d/*.sh /usr/local/bin/nextcloud-with-keyring.sh
