# Gerätebeobachter 055 – begrenzte Nachweise

`physical-availability.json` ist das tatsächlich ausgeführte Ergebnis: keine verfügbare adb-Verbindung, Exit 3, keine physische Messung. `observer-contracts.log` enthält 13 erfolgreiche Python-Vertragstests; die ausgegebenen Erfolgs-/Fehlerfälle verwenden ausdrücklich Fake-adb und sind keine Hardwareberichte.

Die native Parse-Prüfung und der markierte Desktop-Kurzlauf endeten jeweils mit Prozesscode 0. Alle sechs Klassen-/Grafikfälle liefen 20 reale Sekunden mit mindestens 30 gemessenen Bildern und echten Angriffen; 808 Quellinputs blieben vor/nach dem Lauf identisch. Der erhaltene erste 12-Sekunden-Lauf verfehlte lediglich die unveränderte Mindestzahl von 30 Bildern bei zwei langsamen Software-Renderer-Fällen und endete korrekt mit Code 1. Nur die Kurzkonfiguration wurde verlängert.

Der Linux/Xvfb/llvmpipe-Lauf mit Dummy-Audio prüft Ablauf und Messinstrumentierung; weder Telefon-FPS noch Wächterabnahme, Wärme, Akku oder Touch wurden dadurch geprüft. `receipt.json` bindet die begrenzten Belege an ihre Quellen. Physische Prüfung und Touch-Abnahme bleiben offen.
