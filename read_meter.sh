#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
# set -e Stop script when something went wrong
set -e

# Script: read_meter.sh
# Author: Tobias Baumann aka RaptorSDS
# License: MIT
# with help of OpenAI GPT-3.5
#follow libary need libxml2-utils and libmbus

# Set the serial port for the M-bus adapter
SERIAL_PORT="/dev/ttyUSB0"
#SERIAL_BAUD="2400"

# Set the meter primary address and medium type
PRIMARY_ADDRESS="0"

# Set the medium type
# Medium Type 2 is for electricity meters
# Medium Type 3 is for gas meters
# Medium Type 6 is for heat meters
#MEDIUM_TYPE="2"

#Set Data for Database
UUID1="7680efc0-xxx-xxxx-xxxx-xxxxxxx"
#UUID2=""
#Set address for Database
host_db="192.xxx.xxx.xxx"


# Set the output file path
OUTPUT_FILE="\var\tmp\meter_data.xml"
#OUTPUT_FILE="meter_data.xml"

# Read meter data using libmbus
mbus-serial-request-data "$SERIAL_PORT" "$PRIMARY_ADDRESS"  > "$OUTPUT_FILE"

# Extract the energy value from the XML file using xmllint
ENERGY_VALUE=$(xmllint --xpath 'string(//DataRecord[@id="0"]/Value/text())' "$OUTPUT_FILE")

# Extract the power value from the XML file using xmllint
POWER_VALUE=$(xmllint --xpath 'string(//DataRecord[@id="1"]/Value/text())' "$OUTPUT_FILE")

#Send data to Database
wget -O - -q "http://"$host_db"/middleware/data/"$UUID1".json?operation=add&value="$ENERGY_VALUE""
#wget -O - -q "http://"$host_db"/middleware/data/"$UUID2".json?operation=add&value="$POWER_VALUE""

# Print the energy and power values for debug
#echo "Energy Value: $ENERGY_VALUE"
#echo "Power Value: $POWER_VALUE"
