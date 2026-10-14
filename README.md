# VZ-Mbus_script

Ein schlankes Bash-Skript, das einen **M-Bus-Zähler** (Strom, Gas, Wärme, Wasser …) ausliest und den Zählerstand an die **[Volkszähler](https://volkszaehler.org)-Middleware** sendet. Ohne Perl, nur mit `libmbus`, `xmllint` und `wget`.

![Shell](https://img.shields.io/badge/shell-bash-4EAA25?logo=gnubash&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-blue)

---

## Inhalt

- [Funktionsweise](#funktionsweise)
- [Voraussetzungen](#voraussetzungen)
- [Installation](#installation)
- [Zähler finden und testen](#zähler-finden-und-testen)
- [Konfiguration](#konfiguration)
- [Automatisch ausführen (Cron)](#automatisch-ausführen-cron)
- [Fehlersuche](#fehlersuche)
- [Lizenz](#lizenz)

---

## Funktionsweise

```
M-Bus-Zähler ──► USB/Serial- oder TCP-Adapter ──► libmbus (XML) ──► xmllint ──► wget ──► Volkszähler-Middleware
```

1. `mbus-serial-request-data` fragt den Zähler ab und schreibt die Antwort als XML-Datei.
2. `xmllint` liest daraus den Zählerstand (`DataRecord id="0"`) und optional die Leistung (`DataRecord id="1"`).
3. `wget` überträgt den Wert per HTTP an die Middleware (`operation=add`).

---

## Voraussetzungen

| Komponente | Hinweis |
|---|---|
| M-Bus-Pegelwandler | Seriell/USB (z. B. `/dev/ttyUSB0`) oder M-Bus-zu-TCP-Gateway |
| [libmbus](https://github.com/rscada/libmbus) | Stellt `mbus-serial-scan`, `mbus-serial-request-data` usw. bereit |
| `libxml2-utils` | Enthält `xmllint` |
| `wget` | Für die Übertragung an die Middleware |
| Volkszähler | Laufende Middleware und ein angelegter Kanal (UUID) |

**Schnittstelle:** üblich sind **2400 Baud, 8E1**. Manche Zähler nutzen 300 oder 9600 Baud.

---

## Installation

### 1. Abhängigkeiten installieren

```bash
sudo apt update
sudo apt install libxml2-utils wget
```

Ist `libmbus` nicht über den Paketmanager verfügbar, aus dem Quellcode bauen:

```bash
sudo apt install git build-essential libtool autoconf automake
git clone https://github.com/rscada/libmbus.git
cd libmbus
./build.sh
sudo make install
sudo ldconfig
```

### 2. Seriellen Port einstellen

```bash
sudo stty -F /dev/ttyUSB0 2400 cs8 parenb -parodd -cstopb
```

### 3. Skript herunterladen

```bash
git clone https://github.com/RaptorSDS/VZ-Mbus_script.git
cd VZ-Mbus_script
chmod +x read_meter.sh
```

---

## Zähler finden und testen

**Bus nach Zählern durchsuchen** und die Primäradresse notieren (oder vom Zähler-Display ablesen):

```bash
# Seriell
mbus-serial-scan /dev/ttyUSB0

# TCP:  <IP> <Port>
mbus-tcp-scan 192.168.0.100 10001
```

**Testabfrage** – hier mit Primäradresse `1`:

```bash
# Seriell
mbus-serial-request-data /dev/ttyUSB0 1

# TCP:  <IP> <Port> <Adresse>
mbus-tcp-request-data 192.168.0.100 10001 1
```

In der XML-Ausgabe prüfen, welcher `DataRecord` welchen Wert enthält. Das Skript nutzt standardmäßig:

| DataRecord | Inhalt (typisch) | Verwendung im Skript |
|---|---|---|
| `id="0"` | Zählerstand (Energie / Volumen) | wird gesendet (`UUID1`) |
| `id="1"` | aktuelle Leistung | vorbereitet, auskommentiert (`UUID2`) |

> [!NOTE]
> Die Reihenfolge der Records hängt vom Zähler ab. Passt sie nicht, die `id` in den `xmllint`-Zeilen des Skripts anpassen.

---

## Konfiguration

`read_meter.sh` öffnen und die Werte oben im Skript anpassen:

```bash
nano read_meter.sh
```

| Variable | Beispiel | Beschreibung |
|---|---|---|
| `SERIAL_PORT` | `/dev/ttyUSB0` | Serieller Port des M-Bus-Adapters |
| `PRIMARY_ADDRESS` | `0` | Primäradresse des Zählers |
| `UUID1` | `7680efc0-…` | Volkszähler-Kanal für den Zählerstand |
| `UUID2` | *(leer)* | Optional: Kanal für die Leistung |
| `host_db` | `192.168.0.10` | Host der Volkszähler-Middleware |
| `OUTPUT_FILE` | `/var/tmp/meter_data.xml` | Zwischenablage der XML-Antwort |
| `IP` / `PORT` | `192.168.0.100` / `10001` | Optional: TCP-Gateway statt seriell |

**Optionale Funktionen** sind im Skript mit `#` auskommentiert und können bei Bedarf aktiviert werden:

- **Zweiter Kanal (Leistung):** `UUID2` setzen und die zweite `wget`-Zeile einkommentieren.
- **TCP statt seriell:** `IP`/`PORT` setzen, die `mbus_request_data`-Zeile einkommentieren und die serielle Abfrage auskommentieren.
- **Debug-Ausgabe:** die `echo`-Zeilen am Ende einkommentieren.

**Manuell testen:**

```bash
./read_meter.sh
```

Danach sollte der Wert im Volkszähler-Frontend erscheinen.

---

## Automatisch ausführen (Cron)

```bash
crontab -e
```

Beispiel: Abfrage alle 3 Minuten (Pfad anpassen):

```cron
*/3 * * * * /bin/bash /home/pi/VZ-Mbus_script/read_meter.sh
```

> [!TIP]
> M-Bus ist eher langsam. Ein Intervall von mindestens einer Minute ist empfehlenswert.

---

## Fehlersuche

| Problem | Mögliche Ursache / Lösung |
|---|---|
| Scan findet keinen Zähler | Baudrate prüfen (300 / 2400 / 9600), Verkabelung und Pegelwandler kontrollieren |
| `Permission denied` auf `/dev/ttyUSB0` | Benutzer zur Gruppe `dialout` hinzufügen: `sudo usermod -aG dialout $USER` |
| `xmllint: command not found` | `sudo apt install libxml2-utils` |
| Kein Wert im Volkszähler | UUID und `host_db` prüfen, URL `http://<host>/middleware/data/<UUID>.json` im Browser testen |
| Falscher Wert übertragen | Anderen `DataRecord` wählen (siehe [Zähler finden und testen](#zähler-finden-und-testen)) |

---

## Lizenz

Veröffentlicht unter der [MIT-Lizenz](LICENSE) – © 2023 RaptorSDS
