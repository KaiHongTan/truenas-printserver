#!/bin/bash
# Generate AirPrint service files for all CUPS printers

AVAHI_DIR="/etc/avahi/services"
CUPS_PRINTERS=$(lpstat -p | awk '{print $2}')

# Remove old AirPrint services (except our template)
rm -f ${AVAHI_DIR}/AirPrint-*.service

for printer in $CUPS_PRINTERS; do
    # Get printer info
    PRINTER_INFO=$(lpstat -l -p $printer | grep Description | cut -d: -f2 | xargs)
    PRINTER_LOCATION=$(lpstat -l -p $printer | grep Location | cut -d: -f2 | xargs)
    
    # Use printer name if no description
    [ -z "$PRINTER_INFO" ] && PRINTER_INFO="$printer"
    
    # Create service file
    cat > ${AVAHI_DIR}/AirPrint-${printer}.service <<EOF
<?xml version="1.0" standalone='no'?>
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
  <name replace-wildcards="yes">${PRINTER_INFO} @ %h</name>
  <service>
    <type>_ipp._tcp</type>
    <subtype>_universal._sub._ipp._tcp</subtype>
    <port>631</port>
    <txt-record>txtver=1</txt-record>
    <txt-record>qtotal=1</txt-record>
    <txt-record>rp=printers/${printer}</txt-record>
    <txt-record>ty=${PRINTER_INFO}</txt-record>
    <txt-record>adminurl=http://%h:631/</txt-record>
    <txt-record>note=${PRINTER_LOCATION}</txt-record>
    <txt-record>pdl=application/pdf,image/jpeg,image/png,application/postscript</txt-record>
    <txt-record>Transparent=T</txt-record>
    <txt-record>URF=none</txt-record>
    <txt-record>Color=T</txt-record>
    <txt-record>Duplex=T</txt-record>
    <txt-record>Copies=T</txt-record>
  </service>
</service-group>
EOF
done

# Reload Avahi
killall -HUP avahi-daemon