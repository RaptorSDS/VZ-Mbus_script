# Mbus Auslesen für VZ

Auf dieser Seite finden sie eine Möglichkeit ohne perl einen MBus Zähler abzufragen

Vorraussetzung

Zähler ist über einen Serial Anschluß angeschlossen ( der Script kann auch auf TCP MBus gändert werden oder für einen virtuellen Seriellen Anschluß über SOCAT beispielweise)

Der Com-Port sollte auf 2400Baud 8E1 gestellt werden alternativ 300 Baud bzw 9600 Baud

    sudo stty /dev/ttyUSB0 2400 cs8 -parodd -cstopb

    libmbus libxml2-utils

nötigen Dateien installieren

    sudo apt update && apt install libmbus libxml2-utils

nun eine Zähler auflisten lassen

bitte den Port anpassen

     mbus-serial-scan  /dev/ttyUSB0

Bitte die Addresse merken oder von Zähler ablesen

nun kann eine Testabfrage der Daten gemacht werden

001 ist die Addresse des Zählers

    mbus-serial-request-data /dev/ttyV0 001

Bitte die hier schauen welche Daten der Zähler zur Verfügung stelle Der nachfolgende Script nutz „ DataRecord id=„0“ “ für Zählerstand

 Als nächstes Abfragedatei erstellen
    
 git clone

    git clone https://github.com/RaptorSDS/VZ-Mbus_script.git

Abfragedatei bearbeiten

    nano read_meter.sh

#Set the serial port for the M-bus adapter

    SERIAL_PORT="/dev/ttyUSB0"

#Set the meter primary address and medium type

    PRIMARY_ADDRESS="0"

#Set Data for Database

    UUID1="7680efc0-xxx-xxxx-xxxx-xxxxxxx"

    #UUID2=""

#Set address for Database

   host_db="192.xxx.xxx.xxx"


Bitte Com-Port und UUID an deine Gegebenheiten anpassen.

Dieses Script sendet nur die aktuellen Zählerstand an die Middleware, bereits vorbereitet ist alternativ/zusätzlich der Leistung.
Zeilen mit „#“ sind auskommentiert und können bei Bedarf genutzt werden für Debug oder um einen zweiten Kanal hinzuzufügen.

Datei Speichern und ausführbar machen

     chmod +x auslesen.sh

Datei zu CRON hinzufügen (hier als Beispiel Raspberry Pi mit 3 minuten Intervall)

    */3 * * * * /bin/bash /home/pi/read_meter.sh

Der Mbus ist ggf nicht der schnellste eine Auslesung sollte minimal im Minuten Bereich durchgeführt werden .
