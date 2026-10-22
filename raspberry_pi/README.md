# Sparschwein-LAN-Sync für Raspberry Pi

Der Dienst speichert Sparschwein-Einträge und Monatsziele in einer SQLite-Datei auf dem Raspberry Pi. Er stellt ausschließlich eine kleine HTTP-API für das Heimnetz bereit. Es ist kein Cloudkonto und kein Port-Forwarding nötig.

## Voraussetzungen

- Raspberry Pi OS mit systemd und Python 3
- Raspberry Pi und App-Geräte im selben privaten WLAN/LAN
- Eine im Router reservierte lokale IPv4-Adresse für den Pi, zum Beispiel `192.168.1.50`

## Installation

Kopiere `server.py` und `sparschwein-sync.service` auf den Raspberry Pi. Führe im Ordner mit diesen Dateien aus:

```bash
sudo useradd --system --no-create-home --home-dir /var/lib/sparschwein-sync --shell /usr/sbin/nologin sparschwein-sync
sudo install -d -o root -g root /opt/sparschwein-sync
sudo install -m 0755 server.py /opt/sparschwein-sync/server.py
sudo install -d -o sparschwein-sync -g sparschwein-sync /var/lib/sparschwein-sync
```

Erzeuge ein zufälliges gemeinsames Token und speichere es geschützt auf dem Pi:

```bash
TOKEN="$(python3 -c 'import secrets; print(secrets.token_urlsafe(32))')"
printf 'SPARSCHWEIN_SYNC_TOKEN=%s\n' "$TOKEN" | sudo tee /etc/sparschwein-sync.env >/dev/null
sudo chmod 600 /etc/sparschwein-sync.env
printf 'Token für die App: %s\n' "$TOKEN"
```

Installiere und starte den Dienst:

```bash
sudo install -m 0644 sparschwein-sync.service /etc/systemd/system/sparschwein-sync.service
sudo systemctl daemon-reload
sudo systemctl enable --now sparschwein-sync
sudo systemctl status sparschwein-sync
hostname -I
```

Bewahre den ausgegebenen Token für die App-Einrichtung auf. Die API verwendet Port `8765`. Teste sie von einem Gerät im Heimnetz:

```bash
curl http://192.168.1.50:8765/health
```

Ersetze die Beispiel-IP durch die lokale IP des Pi. In der App werden diese IP und der Token eingetragen.

## Netzwerkgrenze

Der Dienst lauscht auf dem lokalen IPv4-Netzwerk. Lege **keine Portweiterleitung** im Router an. Die App soll nur bei WLAN/Ethernet und einer privaten lokalen IPv4-Adresse synchronisieren; bei Mobilfunk bleibt die lokale Warteschlange auf dem Gerät. Der Token schützt die API zusätzlich. Verwende die App-Synchronisierung nur in einem vertrauenswürdigen Heimnetz: Die LAN-Verbindung nutzt HTTP, nicht TLS.

Die SQLite-Datei liegt unter `/var/lib/sparschwein-sync/sparschwein.sqlite3`. Sichere dieses Verzeichnis regelmäßig, wenn du ein separates Backup möchtest.
