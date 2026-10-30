extends RefCounted
class_name NotesData
## Zentrale, editierbare Sammlung aller Fundstücke (Zeitungsartikel).
## Jede Note-Interaktion greift per ID auf diese Texte zurück.

static func get(id: String) -> Dictionary:
    match id:
        "article1":
            return {
                "title": "MANILA DAILY BULLETIN - 14. AUGUST 1988",
                "body": "MYSTERIOSES VERSCHWINDEN IM DIPLOMAT PEAK RESORT\n\nBaguio City - Die lokale Polizei steht vor einem Rätsel. In der Nacht zum 12. August verlieren über 40 Hotelgäste panisch das luxuriöse Diplomat Peak Resort. Der Hotelmanager, Herr Eduardo Ramirez, bleibt spurlos verschwunden. Polizeihauptkommissar Santos gab bekannt, dass Ramirez zuletzt in Zimmer 104 gesehen wurde. Akten zeigen, dass Ramirez im Jahr 1949 geboren wurde und seinen persönlichen Tresor stets mit der Kombination aus seiner Zimmernummer und den letzten zwei Ziffern seines Geburtsjahres sicherte.\n\nCode = Zimmernummer + Geburtsjahr."
            }
        "article2":
            return {
                "title": "BAGUIO HERALD - 03. NOVEMBER 1991",
                "body": "SICHERHEITSWARNTING FÜR DAS STILLGELEGTE ANWESEN\n\nBaguio City - Nach mehreren Einbrüchen warnt die Stadtverwaltung vor dem Betreten des Diplomat Peak Resorts. Das veraltete Notstromaggregat im Ostflügel stellt eine erhebliche Gefahr dar. Laut den alten Wartungsprotokollen führt das falsche Einlegen der Hauptsicherungen zu einer sofortigen Überlastung. Der rote Hauptschalter muss zwingend VOR dem blauen Sicherungshebel betätigt werden. Der grüne Hilfsgenerator darf NIEMALS an erster Stelle geschaltet werden, sondern muss stets als drittes Glied der Kette einrasten. Der gelbe Erdschalter bildet den Abschluss der Sequenz.\n\nReihenfolge: 1. Rot, 2. Blau, 3. Grün, 4. Gelb."
            }
        "article3":
            return {
                "title": "TAGESSPIEGEL BAGUIO - 20. SEPTEMBER 1988",
                "body": "DIE STUNDE DER ANOMALIE\n\nBaguio City - Ehemalige Angestellte des Diplomat Peak Resorts berichten von verstörenden Phänomenen vor der Schließung. Chefkoch Mateo schrieb in sein Tagebuch: \"Jede Nacht, wenn die Kirchturmuhr im Tal exakt 03:15 Uhr schlägt, bleiben alle analogen Uhren im Penthouse genau 4 Stunden und 20 Minuten VOR der aktuellen Zeit stehen. Die Räder der großen Standuhr lassen sich nur dann drehen, wenn man die Zeiger auf diese berechnete Schattenzeit einstellt.\"\n\nBerechnung: 03:15 - 4 Std. 20 Min. = 22:55 Uhr (oder 10:55 Uhr)."
            }
        "diary":
            return {
                "title": "TAGEBUCHT DES KÖCHICHEN - 1988",
                "body": "...die Kirchturmuhr schlägt 03:15. Die Standuhr im Penthouse steht wieder still, vier Stunden und zwanzig Minuten vor der Zeit. Wenn ich je entkommen will, muss ich ihre Zeiger auf die Schattenzeit drehen..."
            }
        _:
            return {"title": "Unbekannt", "body": ""}
