# Sparschwein für Flutter

Flutter-Umsetzung für Android und Windows. Das Sparbuch ist beim ersten Start leer; ein Monatsziel wird erst nach eigener Eingabe gesetzt. Die nativen Runner werden im nächsten Schritt durch Flutter erzeugt.

## Plattformziele einrichten

Im Projektordner ausführen:

```bash
flutter create --project-name sparschwein --platforms=android,windows --org de.sparschwein .
flutter pub get
```

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
