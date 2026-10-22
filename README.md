# Sparschwein

Ein Spar-Cockpit zum Erfassen persönlicher Ersparnisse, Rabatte, Cashback-Beträge und Sparziele.

## Web-App starten

```bash
npm install
npm run dev
```

Produktionsbuild:

```bash
npm run build
npm run preview
```

## Flutter-App für Android und Windows

Die Flutter-App liegt unter `sparschwein_flutter/`. Sie startet mit einem leeren Sparbuch und ohne voreingestelltes Monatsziel. Der Flutter-CLI-Befehl legt die nativen Android- und Windows-Runner an.

```bash
cd sparschwein_flutter
flutter create --project-name sparschwein --platforms=android,windows --org de.sparschwein .
flutter pub get
flutter devices
```

Einmalige Android-Konfiguration für den HTTP-Zugriff zum privaten Pi im LAN: unter Linux/macOS `python3 tool/enable_lan_http.py`, unter Windows PowerShell `.\tool\enable_lan_http.ps1` (aus dem Flutter-Projektordner).

Ausführen und bauen:

```bash
flutter run -d windows
flutter run -d <android-device-id>
flutter build windows
flutter build apk --release
```

Die Einrichtung des Raspberry-Pi-Dienstes ist unter [`raspberry_pi/README.md`](raspberry_pi/README.md) beschrieben. Die App gleicht Änderungen nur über WLAN/Ethernet mit einer privaten IPv4-Adresse ab; der Pi muss im selben Heimnetz erreichbar sein.

## Funktionen

- Sparbeträge mit Datum, Laden, Sparart und Notiz erfassen
- Gesamt-, Monats- und Jahresübersicht mit Verlauf und Sparziel
- Einträge filtern, durchsuchen und entfernen
- Eigene Monatsziele festlegen
- Optionaler Abgleich mit dem Raspberry Pi im Heimnetz
- Start ohne Beispielbuchungen

Es gibt keinen Bereich für lokale Angebote und keine Standortermittlung.
