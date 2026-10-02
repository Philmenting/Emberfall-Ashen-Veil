# Lokaler Online-Test 0.33

Der Online-Test umfasst Gastidentität, Cloud-Backup, offene Gemeinschaften, persistenten Gruppenchat und einen getrennten serverautoritativen Fortschrittsprototyp. Er macht Emberfall noch nicht zu einem vollständigen MMO: Nyras sichtbare Kämpfe und ihr lokaler Spielstand bleiben weiterhin clientseitig.

## Starten

Das optionale Online-Menü ist nur in den Exportprofilen **Android Debug** und **Android Emulator Debug** aktiv. Beide Testprofile enthalten die Netzberechtigung und das Build-Merkmal `nakama_local_test`. Das Profil **Google Play Beta** hat weder das Merkmal noch die Netzberechtigung.

1. Auf dem Entwicklungsrechner den lokalen PostgreSQL-/Nakama-Testserver starten:

   ```sh
   ./tools/run_local_nakama.sh
   ```

   Die bereits installierten Entwicklerwerkzeuge liegen standardmäßig im Nachbarordner `.android-game-tools/online-backend`. Für einen anderen Pfad kann `EMBERFALL_BACKEND_ROOT` gesetzt werden. Der Testserver lauscht nur an `127.0.0.1`; Console und API werden nicht ins LAN freigegeben. `Ctrl+C` beendet Nakama und eine von diesem Skript gestartete Datenbank.

2. Für Android den Emulatorport an den Entwicklungsrechner weiterleiten:

   ```sh
   adb reverse tcp:7350 tcp:7350
   ```

   Bei einem anderen SDK-Aufbau muss `adb` aus dem Android-SDK-Ordner aufgerufen werden. Im Desktop-Editor zeigt `127.0.0.1` direkt auf denselben Rechner.
   Nach einem Neustart des ADB-Servers oder Emulators den Reverse-Port erneut einrichten.

3. In Godot **Project → Export… → Android Emulator Debug** exportieren und die APK installieren. Alternativ die Exportvorlage **Android Debug** für ein ARM64-Testgerät verwenden; das Gerät muss über eine sichere, lokale Tunnelverbindung zum Entwicklungsrechner kommen.

## In-Game-Ablauf

Im Lager **Options → Online Test** öffnen. **Connect Guest Account** legt bei Bedarf eine zufällige, kryptografische ID in `user://emberfall_online.cfg` an und meldet sie beim lokalen Nakama an. Es wird keine Hardwarekennung gelesen und kein Session-Token dauerhaft gespeichert.

Nach der Anmeldung kann im **Fellowship Board** eine offene Gemeinschaft mit bis zu 40 Mitgliedern erstellt oder nach Namen gesucht werden. Der Server verwaltet Mitgliedschaft und Mitgliederliste. Beitreten und Verlassen werden direkt beim Server bestätigt. Der Gruppenchat verbindet sich über Nakamas WebSocket, lädt die jüngsten gespeicherten Nachrichten und empfängt neue Nachrichten in Echtzeit. Nachrichten werden auf eine einzelne Zeile und 180 Zeichen begrenzt; der Client drosselt schnelles Senden. Diese Begrenzung ersetzt keine serverseitige Moderation oder Spam-Abwehr und ist deshalb nur für den lokalen Testserver gedacht.

### Server Progression Test

Nach der Gastanmeldung erzeugt **Settle / Refresh** ein separates Nakama-Profil. Es wird nicht aus dem lokalen Spielstand importiert und überschreibt diesen nicht. Im Profil liegen eine Testklasse, Startausrüstung, Gold, Erfahrung, Attribute, freigeschaltete Etagen, Farmziel und servergenerierte Beute.

Die Laufzeitmodule in `server/modules/emberfall.js` erlauben nur serverseitige Profil-Schreibvorgänge. Der Client darf das Profil lesen und eine erlaubte Aktion anfordern: Farmziel einrichten, Klasse wählen, Attributpunkt verwenden, Gegenstand anlegen oder verkaufen und Ausrüstung verstärken. Der Client sendet keine Gold-/XP-Menge, Siegmeldung, Beutequalität oder Gegenstandsstatistik. Beim erneuten Abgleich verwendet der Server seine Uhr, rechnet höchstens 24 Stunden ab und simuliert Läufe mit dem serverseitigen Profil. Jeder abgerechnete Lauf erhält einen neuen Zufallsstartwert aus Nakamas kryptografischem Zufallszahlengenerator; Belohnungs- und Beutewürfe werden daraus serverseitig abgeleitet. Fehlt die Zufallsquelle, bricht die Abrechnung ab, statt auf vorhersehbare Würfe zurückzufallen. Nakama speichert das Profil mit `permissionWrite=0` für Clients.

Derzeit ist das ein separater Testdatensatz. Nyras lokales Kampfmodell, lokale Beute/Ökonomie, Verträge, Speichern und AFK-Simulation nutzen diese Serverdaten noch nicht. Dadurch ändert der neue Testpfad keine bestehenden Saves. Für ein echtes Online-Spiel müssen wir anschließend Serverprofil und sichtbares Gameplay zusammenführen, Clientaktionen vollständig über die Server-APIs führen sowie Migration, Moderation, Betriebsüberwachung und ein echtes Anmeldekonto ergänzen.

Für einen Gerätewechsel auf der alten Installation **Create Account Transfer Key** wählen und den Schlüssel privat kopieren. Auf einer frischen Installation den Schlüssel im Feld **Add an Existing Account to This Installation** eingeben und **Import Account Key** wählen, bevor dort ein neues Gastkonto erstellt wird. Der importierte Schlüssel wird mit einer neuen installationsgebundenen Kennung ersetzt und nach erfolgreicher Verknüpfung serverseitig entwertet. Der bisherige Login der alten Installation bleibt bestehen; dieser Test verbindet eine zweite Installation und ist kein erzwungener Ein-Geräte-Umzug. Die alte Installation kann einen noch nicht verwendeten Schlüssel unter **Revoke Key** widerrufen. Der Schlüssel ist ein Anmeldeschlüssel: Jeder, der ihn besitzt, kann sich während seiner Gültigkeit am Gastkonto anmelden. Er wird in der lokalen Testkonfiguration gespeichert, damit er auf der ausgebenden Installation erneut angezeigt oder widerrufen werden kann.

Der Kontowechsel meldet dieselbe Nakama-Identität auf dem neuen Gerät an; er kopiert den lokalen Spielstand nicht automatisch. Danach **Check Cloud** prüfen und **Restore Cloud Backup** separat bestätigen. **Create Cloud Backup** lädt den aktuellen Spielstand explizit hoch. **Update Cloud Backup** verlangt eine Bestätigung, bevor ein vorhandener Stand ersetzt wird. **Restore Cloud Backup** ist ebenfalls durch eine Bestätigung geschützt. Upload und Restore sind nur im Lager möglich. Restore validiert zuerst den Spielstand und erhält über den vorhandenen SaveStore eine lokale Recovery-Kopie, die unter **Save Backup → Undo Last Restore** zurückgespielt werden kann.

## Automatisierte Servertests

`tests/progression_runtime_test.js` prüft Zeitabrechnung, 24-Stunden-Limit, doppelte Ansprüche, einen kryptografischen Zufallsstart je abgerechnetem Lauf, keine Neuwürfe bei Replay ohne Zeitfortschritt, Inventargrenze und das Ignorieren clientseitig eingeschleuster Werte anhand der Laufzeitdatei mit isolierter Nakama-Speicher- und Uhrsimulation:

```sh
node --check server/modules/emberfall.js
node tests/progression_runtime_test.js
```

`tests/cloud_transfer_e2e.gd` prüft gegen den echten lokalen Nakama-Server getrennte Gastkonten: serverseitige Profilinitialisierung, Ablehnung gesperrter Etagen und fremder Klassen, gültige Attributvergabe, Zurückweisung direkter Client-Schreibversuche, Backup/Transfer, zwei Spieler in derselben Gemeinschaft und persistenten Gruppenchat. Der Android-Workflow startet dafür PostgreSQL 16 und [Nakama 3.41.0](https://github.com/heroiclabs/nakama/releases/tag/v3.41.0) mit dem Servermodul aus `server/modules`. Den Integrationstest lokal nach dem Serverstart aufrufen:

```sh
XDG_DATA_HOME=/tmp/emberfall-transfer-e2e godot --headless --path . --script tests/cloud_transfer_e2e.gd
```

Das prüft Serverauthentifizierung, Profil- und Speicherschutz, Gruppenmitgliedschaft und Gruppenchat mit getrennten lokalen Profilen innerhalb eines Godot-Prozesses. Es prüft weder Android-Clipboard und Touchbedienung noch Deinstallation, Android-App-Daten oder einen echten Wechsel zwischen zwei physischen Geräten.

Die Datensicherung ist privat für die angemeldete Gast-ID les- und schreibbar. Es gibt einen Cloud-Slot; beim Ersetzen wird eine veraltete Version mit Nakamas Versionsprüfung abgewiesen. Es gibt keine automatische Synchronisierung. Deinstallation oder Löschen der App-Daten entfernt den lokalen Zugang; ein vorher erstellter und sicher aufbewahrter Transfer-Schlüssel kann das Konto auf einer frischen Installation anmelden. Der manuelle Spielstand-Backup-Code bleibt davon unabhängig und portabel.

## Vertrauensgrenze und offene Arbeit

Der manuelle Cloud-Backup-Slot bleibt les- und schreibbar für seinen Gastkonto-Besitzer. Ein modifizierter Client kann den dort gespeicherten lokalen Spielstand manipulieren. Das neue separate Testprofil ist serverseitig schreibgeschützt für Clients; es autorisiert aber noch nicht Nyras lokales Spiel. Die beiden Datenbestände sind getrennt. Gemeinschaften und Chat nutzen Nakamas eingebaute Server-APIs; Chatnachrichten werden persistent gespeichert. Der aktuelle Client begrenzt Nachrichtenlänge und Sendefrequenz, erzwingt aber keine Moderation. Der Transfer-Schlüssel ist eine zufällige, einmalig verwendbare Geräteanmeldung, kein E-Mail-/Google-/Apple-Konto und keine Identitätsprüfung. Vor einem öffentlichen Betrieb braucht das Projekt die vollständige Einbindung serverautoritativ berechneter Kämpfe/Belohnungen in das Gameplay, echte Kontoverknüpfung, Chatmoderation, serverseitige Rate Limits, Speichermigration, Beobachtbarkeit sowie ein Betriebs-/Datenschutzkonzept. Es gibt noch keinen öffentlichen Nakama-Endpunkt und keine gemeinsame Dungeon-Instanz.

Der 0.29-Transfercode wurde in dieser Umgebung noch nicht gegen zwei Android-Installationen erprobt. Ein serverseitiger Integrationstest ist im Android-CI-Workflow ergänzt, aber hier wegen gesperrter TCP-Sockets noch nicht ausführbar (`Operation not permitted`). Auch Sandbox-ADB und Gradle können hier keine lokalen Sockets erstellen. Deshalb konnte weder der Emulator installiert noch der aktuelle Google-Play-AAB gebaut werden. Siehe den Entwicklungsstand in [EARLY_ACCESS.md](EARLY_ACCESS.md).

Das mitgelieferte Serverkennwort `defaultkey`, die lokale Datenbank mit Trust-Authentifizierung und der lokale Gastzugang sind ausschließlich für diesen Loopback-Entwicklungstest bestimmt. Diese Werte dürfen nicht in einem öffentlich erreichbaren Server oder Store-Build verwendet werden.

Netzwerk-Integrationstests ohne `--fixed-fps` ausführen: beschleunigte Simulationszeit kann HTTP-Timeouts vor einer realen Antwort auslösen. Namenssuche und Open-Filter dürfen bei Nakama nicht kombiniert werden; geschlossene Namenssuchtreffer werden lokal ausgeschlossen.
