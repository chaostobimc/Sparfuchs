# Sparschwein für Flutter

Flutter-Umsetzung für Android und Windows. Das Sparbuch ist beim ersten Start leer; ein Monatsziel wird erst nach eigener Eingabe gesetzt. Die nativen Runner werden im nächsten Schritt durch Flutter erzeugt.

## Plattformziele einrichten

Im Projektordner ausführen:

```bash
flutter create --project-name sparschwein --platforms=android,windows --org de.sparschwein .
```

Danach die Android-HTTP-Konfiguration ausführen: Linux/macOS `python3 tool/enable_lan_http.py`; Windows PowerShell `.\tool\enable_lan_http.ps1`. Anschließend `flutter pub get`.

## LAN-Synchronisierung

Die App hält Einträge lokal vor und synchronisiert ausstehende Erstellungen, Löschungen und Monatsziele automatisch, sobald WLAN oder Ethernet sowie die private IPv4-Adresse des Raspberry Pi verfügbar sind. Über Mobilfunk werden keine Sync-Anfragen gesendet. Pi-Setup: [`../raspberry_pi/README.md`](../raspberry_pi/README.md).

## Starten

```bash
flutter devices
flutter run -d windows
flutter run -d <android-device-id>
```

## Builds

```bash
flutter build windows
flutter build apk --release
```
