# The Diplomat Peak – Das letzte Kapitel

Ein vollständiges **First-Person-Psychologie-Horror-Puzzle** in **Godot 4**, basierend
auf dem Spiele-Design-Dokument (5 Akte, 3 Rätsel, Finale mit Jumpscare).
Das gesamte Spiel ist in GDScript geschrieben und **vollständig editierbar** –
alles wird prozedural aufgebaut, keine externen Asset-Pakete nötig.

> **100 % Twitch-sicher, kein Blut/Gore.** Fokus auf Isolation, Dschungel-Atmosphäre,
> Gewitter und Paranoia.

---

## 1. Spiel starten

1. [Godot 4.2 oder neuer](https://godotengine.org/download) installieren.
2. Dieses Projekt öffnen: Menü **Projekt → Projektmanager → Import**, dann
   `project.godot` öffnen (oder einfach `project.godot` per Doppelklick).
3. Mit **F5** (oder grünen *Play*-Knopf) starten.

Die Engine lädt automatisch den **Titelbildschirm**. Dort **klicken**, um das Spiel
zu starten (der Mauszeiger wird übernommen / *Pointer Lock*).

> Benötigt eine Desktop-GPU mit OpenGL 3.3+ (Forward+ Renderer). Auf Notebooks/Low-End
> kann man in den Projekteinstellungen unter *Rendering → Renderer* auf **Mobile**
> umschalten.

---

## 2. Kontrollen

| Taste | Funktion |
|-------|----------|
| `W A S D` | Bewegung |
| `Shift` | Sprint |
| `E` | Interagieren (Safe, Hebel, Uhr, Notizen, Schalter) |
| `F` | Blinklicht ein/aus |
| `I` / `J` | Journal (letzten gelesenen Artikel wieder öffnen) |
| `ESC` | Pause (Maus entsperren) |
| Maus | Blickrichtung |
| Klick | Maus entsperren/sperren |

---

## 3. Ablauf / Rätsel (Lösungen)

Das Spiel folgt dem Design-Dokument. Die Lösungen sind hier – **nicht weiterlesen,
wenn du die Rätsel selbst lösen willst!**

- **Akt 1 – Foyer:** Safe-Code = **10449** (Zimmer 104 + Geburtsjahr 1949).
- **Akt 2 – Korridor:** Hebel-Reihenfolge = **Rot → Blau → Grün → Gelb**.
- **Akt 3 – Penthouse:** Standuhr auf **22:55** (bzw. 10:55) stellen.
- **Akt 4 – Terrasse:** Not-Schalter → totale Stille → Gang im Torflur → **Jumpscare**.

Jeder Akt enthält einen **Zeitungsartikel** (Notiz), der den Hinweis liefert.
Notizen werden gelesen, indem du `E` bei der fallierten Zeitung benutzt.

---

## 4. Projektstruktur

```
project.godot            Engine-Konfiguration (Autoloads, Eingaben, Renderer)
icon.svg                 App-Icon

scenes/
  TitleScreen.tscn       Startbildschirm
  Foyer.tscn             Akt 1
  Corridor.tscn          Akt 2
  Penthouse.tscn         Akt 3
  Terrace.tscn           Akt 4 (Finale)
  (Alle Szen-Dateien sind minimal: ein Wurzelknoten mit Script.
   Alles andere wird im Skript aufgebaut.)

scripts/
  GameManager.gd         Autoload: Spielstand, Flags, Ziele, Notizen, Szenenwechsel
  AudioManager.gd        Autoload: alle Geräusche/Schleifen
  SceneBase.gd           Alle Level erben davon: Licht, Nebel, Spieler, Regen, Donner
  PlayerController.gd    Erste-Person-Controller: Bewegung, Mouse-Look, Interaktion
  Interactable.gd        Basis für interagierbare Objekte
  Note.gd                lesbare Zeitungs-Notiz
  Portal.gd              reiner Übergang (z.B. Aufzug)
  Door.gd                Tür mit Kollision + Öffnungs-Animation + Übergang
  Builder.gd             Helfer: Boxen, Wände, Räume (mit Texturen)
  LevelKit.gd            Mobiliar: Pflanzen, Tresen, Teppich, Fenster, Lampen
  FlickerLight.gd        zerrüttetes, flackerndes Licht
  Rain.gd                prozeduraler Regen
  Thunder.gd             Blitz + Donner (visuell & Audio)
  NotesData.gd           Texte aller Fundstücke (Zeitungsartikel)
  TitleScreen.gd         Startbildschirm-Oberfläche

  puzzles/
    PuzzleSafe.gd        Rezeption-Safe
    Lever.gd             einzelner Hebel
    PuzzleLevers.gd      Notstrom-Aggregat (Reihenfolge)
    PuzzleClock.gd       Standuhr
    EmergencySwitch.gd   Not-Schalter (Finale)

  ui/
    UIManager.gd         Autoload: gesamte 2D-Oberfläche (HUD, Overlays, Jumpscare)
    KeypadUI.gd          Tastenfeld (Safe)
    ClockUI.gd           On-Screen-Uhr (Penthouse)
    ClockFace.gd         analoges Zifferblatt (draggable)
    Crosshair.gd         Wohnkreuz
    JumpscareScreen.gd   Strobe-Überlagerung

  levels/
    LevelFoyer.gd        Akt 1 – Raumaufbau
    LevelCorridor.gd     Akt 2
    LevelPenthouse.gd    Akt 3
    LevelTerrace.gd      Akt 4 – Finale

assets/
  audio/*.wav            15 prozedural erzeugte Geräusche
  textures/*.png         8 prozedural erzeugte Texturen

scripts/audio_gen.py     erzeugt die .wav-Dateien (python3 scripts/audio_gen.py)
scripts/texture_gen.py   erzeugt die .png-Dateien (python3 scripts/texture_gen.py)
```

---

## 5. Rätsel bearbeiten

### Safe (Akt 1)
Code in `scripts/ui/UIManager.gd`:
```gdscript
func open_keypad(target_code: String = "10449") -> void:
```
und in `scripts/puzzles/PuzzleSafe.gd`:
```gdscript
UIManager.open_keypad("10449")
```
Einfach die Ziffern ändern.

### Hebel-Reihenfolge (Akt 2)
In `scripts/puzzles/PuzzleLevers.gd`:
```gdscript
var _sequence: Array = [0, 1, 2, 3]  # 0=Rot, 1=Blau, 2=Grün, 3=Gelb
```
Die Reihenfolge der Indizes definiert die Lösung.

### Uhr (Akt 3)
Ziel-Zeit in `scripts/ui/ClockUI.gd`:
```gdscript
@export var target_hour: int = 22
@export var target_minute: int = 55
```
Und die Beschriftung/Hinweis-Text in `scripts/NotesData.gd` (`article3`).

---

## 6. Texte der Fundstücke

Alle Zeitungsartikel/Tagebücher stehen zentral in `scripts/NotesData.gd`.
Pro ID ein Dictionary mit `title` und `body`. Changing = einfach Text anpassen.
Die Level verweisen per ID (`note_id`) darauf.

---

## 7. Level bearbeiten / neue Räume bauen

Jedes Level ist ein Skript, das von `SceneBase` erbt. Im `_ready()` wird
Zuerst `spawn_position` / `spawn_yaw` gesetzt, dann `super._ready()` (Licht,
Spieler, Regen, Donner) und dann in Unter-Funktionen der Raum aufgebaut:

- `Builder.floor_ceiling(...)` – Boden + Decke (mit Texturen)
- `Builder.wall_segment(...)` – Wandstück (für Türöffnungen)
- `Builder.static_box(...)` – ein Kollider-Objekt
- `LevelKit.plant/desk/rug/window/accent_light/fallen_kommode(...)` – Mobiliar

**Beispiel:** einen neuen Raum bauen
```gdscript
func _build_room() -> void:
    Builder.floor_ceiling(Vector2(12.0, 10.0), 4.0,
        Color(0.16,0.11,0.07), Color(0.04,0.04,0.04), self, "wood", "concrete")
    Builder.wall_segment(12.0, 4.0, 0.2, Color(0.15,0.19,0.16),
        Vector3(0, 2.0, -5.0), self, "wallpaper")
    # ...
```

**Texturen:** wähle aus `concrete, wood, wallpaper, metal, fabric, paper, dirt, fern`
(siehe `scripts/Builder.gd` → `const TEX`). Eigene Texturen in
`assets/textures/` ablegen und in `TEX` ergänzen.

**Türen/Übergänge:** nutze `Door.new()` (mit Kollision) oder `Portal.new()`
(reiner Trigger). Setze `target_scene`, `act` und ggf. `require_flag`.

---

## 8. Atmosphäre anpassen

- **Nebel/Dunst:** `scripts/SceneBase.gd` → `_build_environment()`
  (`fog_density`, `volumetric_fog_density`).
- **Regen:** `scripts/Rain.gd` (`_count`, `_volume`, `_top`).
- **Blitz/Donner:** `scripts/Thunder.gd` (Intervalle, Flash-Energie).
- **Licht:** `scripts/FlickerLight.gd` (Flackern) und die Akzent-Lichter in den Leveln.
- **Finale-Stille:** in `scripts/levels/LevelTerrace.gd` → `_on_gate_open()`.

---

## 9. Audio

Alle Geräusche sind `.wav`-Dateien in `assets/audio/`. Sie können durch eigene
Aufnahmen ersetzt werden (gleicher Dateiname). Ohne Änderungen worked alles –
neue Geräusche per `AudioManager.sfx("name")` abspielbar (Datei `name.wav`).

Neue Geräusche prozedural erzeugen:
```bash
python3 scripts/audio_gen.py
```

---

## 10. Jumpscare (Finale)

In `scripts/ui/UIManager.gd` → `show_jumpscare()`. Dort wird der Strobe
(`JumpscareScreen.flash_color`), der Scream (`AudioManager.sfx("scream")`) und
das automatische Beenden (`get_tree().quit()`) steuerbar. Das Finale wird
ausgelöst in `scripts/levels/LevelTerrace.gd` → `_on_final()`.

---

## 11. Tipps / Fehlerbehebung

- **Maus nicht gesperrt?** Pointer-Lock funktioniert nur auf Desktop (Windows/Linux/macOS),
  nicht im Web/Mobile. Klicke im Spiel, um die Maus zu sperren.
- **Kein Ton?** Prüfe in den Projekteinstellungen unter *Audio* die Master-Lautstärke.
  Alle `.wav`-Dateien liegen unter `assets/audio/`.
- **Performance schlecht?** Renderer auf *Mobile* schalten oder Nebel/Volumetrischen
  Nebel reduzieren (`SceneBase._build_environment`).
- **Spieler steckt?** Kollision prüfen: Wände/Böden sind `StaticBody3D` mit
  `CollisionShape3D` (Layer 1). Der Spieler-Capsule ist Layer 1.
- **Rätsel schon gelöst, Tür geht nicht auf?** Die Türen erwarten die Flags
  (`act1_safe_open`, `act2_generator_on`, `act3_clock_solved`, `act4_gate_open`).

---

## 12. Aufbau erweitern

- **Neuen Akt hinzufügen:** neues `.tscn` (Wurzel = `Node3D` mit eigenem
  `LevelXxx.gd`, der von `SceneBase` erbt), in `GameManager.objective_for_act()`
  eintragen, eine `Door`/`Portal` als Übergang setzen.
- **Eigenes Skript:** einfach ein neues `.gd` unter `scripts/` anlegen. Die
  Engine erkennt `class_name`-Scripts automatisch.

---

Made with Godot 4. Viel Spaß beim Erkunden des Diplomat Peak! 🌧️⚡
