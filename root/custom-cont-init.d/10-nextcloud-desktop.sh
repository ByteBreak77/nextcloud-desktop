#!/usr/bin/with-contenv bash
set -e

mkdir -p /config/Desktop /config/.config/autostart /client-data
mkdir -p /config/.local/share/keyrings /config/.local/share/nextcloud-desktop

cat > /config/Desktop/Nextcloud.desktop <<'EOD'
[Desktop Entry]
Type=Application
Name=Nextcloud
Exec=/usr/local/bin/nextcloud-with-keyring.sh
Icon=Nextcloud
Terminal=false
Categories=Network;
EOD

cat > /config/Desktop/Files.desktop <<'EOD'
[Desktop Entry]
Type=Application
Name=Files
Exec=thunar /client-data
Icon=system-file-manager
Terminal=false
Categories=Utility;
EOD

cat > /config/Desktop/Firefox.desktop <<'EOD'
[Desktop Entry]
Type=Application
Name=Firefox
Exec=firefox-esr
Icon=firefox-esr
Terminal=false
Categories=Network;WebBrowser;
EOD

# This entry is managed by the image, so it is refreshed when upgrading an
# existing /config volume (older image versions used Exec=nextcloud).
cat > /config/.config/autostart/nextcloud.desktop <<'EOD'
[Desktop Entry]
Type=Application
Name=Nextcloud
Exec=/usr/local/bin/nextcloud-with-keyring.sh
X-GNOME-Autostart-enabled=true
EOD

chmod 0755 /config/Desktop/*.desktop
chmod 0644 /config/.config/autostart/nextcloud.desktop
chmod 0700 /config/.local/share/keyrings /config/.local/share/nextcloud-desktop

# Important: do not use chown -R on /client-data. It could traverse many GB
# of Nextcloud files at every container start. Only fix our direct entries.
user_id="${PUID:-1000}"
group_id="${PGID:-1000}"
chown "${user_id}:${group_id}" \
  /config/Desktop /config/.config /config/.config/autostart \
  /config/.local /config/.local/share /config/.local/share/keyrings \
  /config/.local/share/nextcloud-desktop \
  /client-data /config/Desktop/*.desktop \
  /config/.config/autostart/nextcloud.desktop 2>/dev/null || true
