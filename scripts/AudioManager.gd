extends Node
## Audio-Manager (Autoload). Zentraler Ausgang für alle Geräusche und
## die atmosphärischen Schleifen (Regen, Ambient, Sturm).
## Alle Geräusche sind kurze .wav-Dateien in `res://assets/audio/`,
## damit du sie leicht durch echte Aufnahmen ersetzen kannst.

var master_volume: float = 0.9

var _ambient: AudioStreamPlayer
var _rain: AudioStreamPlayer
var _sfx: AudioStreamPlayer

func _ready() -> void:
    _ambient = AudioStreamPlayer.new()
    _ambient.name = "AmbientPlayer"
    add_child(_ambient)
    _rain = AudioStreamPlayer.new()
    _rain.name = "RainPlayer"
    add_child(_rain)
    _sfx = AudioStreamPlayer.new()
    _sfx.name = "SfxPlayer"
    add_child(_sfx)
    set_ambient_volume(0.35)
    set_rain_volume(0.5)

## Hilfsfunktion: 0..1 -> Dezibel.
func linear_to_db(v: float) -> float:
    if v <= 0.0:
        return -80.0
    return 20.0 * log(v, 10.0)

## ----- Schleifen -----

func start_ambient() -> void:
    if not _ambient.stream:
        _ambient.stream = load("res://assets/audio/ambient.wav") as AudioStream
    _ambient.play()

func stop_ambient() -> void:
    _ambient.stop()

func start_rain() -> void:
    if not _rain.stream:
        _rain.stream = load("res://assets/audio/rain.wav") as AudioStream
    _rain.play()

func stop_rain() -> void:
    _rain.stop()

func set_ambient_volume(v: float) -> void:
    _ambient.volume_db = linear_to_db(v)

func set_rain_volume(v: float) -> void:
    _rain.volume_db = linear_to_db(v)

## ----- Einmal-Sounds -----

## `name` == Dateiname (ohne .wav) in res://assets/audio/.
func sfx(name: String) -> void:
    var path := "res://assets/audio/" + name + ".wav"
    if not ResourceLoader.exists(path):
        push_warning("AudioManager: fehlendes SFX '" + name + "' (" + path + ")")
        return
    _sfx.stream = load(path) as AudioStream
    _sfx.play()

## Synchronisierter Donnerschlag (vom Thunder-Visual-Script ausgelöst).
func thunder() -> void:
    sfx("thunder")

## Prüft, ob alle Audio-Dateien vorhanden sind (zum Debuggen).
func audio_assets_status() -> Dictionary:
    var names := ["ambient", "rain", "thunder", "scream", "click", "lock",
                  "lever", "generator", "elevator", "clock", "door", "gate",
                  "heartbeat", "wind"]
    var out := {}
    for n in names:
        out[n] = ResourceLoader.exists("res://assets/audio/" + n + ".wav")
    return out
