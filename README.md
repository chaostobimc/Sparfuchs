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

Ausführen und bauen:

```bash
flutter run -d windows
flutter run -d <android-device-id>
flutter build windows
flutter build apk --release
```

## Funktionen

- Sparbeträge mit Datum, Laden, Sparart und Notiz erfassen
- Gesamt-, Monats- und Jahresübersicht mit Verlauf und Sparziel
- Einträge filtern, durchsuchen und entfernen
- Eigene Monatsziele festlegen
- Start ohne Beispielbuchungen

Es gibt keinen Bereich für lokale Angebote und keine Standortermittlung.
