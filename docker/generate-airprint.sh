#!/bin/bash
# Generate AirPrint service files for all CUPS printers.
#
# AVAHI_PUBLISH_MODE=host  — write to AIRPRINT_SERVICES_DIR for the NAS host's avahi-daemon
#                           (avoids UDP/5353 conflict when TrueNAS already runs Avahi).
# AVAHI_PUBLISH_MODE=container (default) — write under /etc/avahi/services and HUP in-container avahi.

set -u

AVAHI_PUBLISH_MODE="${AVAHI_PUBLISH_MODE:-container}"
AVAHI_DIR="${AIRPRINT_SERVICES_DIR:-/etc/avahi/services}"

mkdir -p "${AVAHI_DIR}"
chmod 755 "${AVAHI_DIR}" 2>/dev/null || true

CUPS_PRINTERS=$(lpstat -p 2>/dev/null | awk '{print $2}' || true)

# AirPrint / iOS: URF=none and pdl without image/urf cause many iPhones to ignore the queue.
# Override per deployment if a queue lies about capabilities (e.g. monochrome label printer: set F,F).
AIRPRINT_PDL="${AIRPRINT_PDL:-application/pdf,image/jpeg,image/png,image/urf,application/octet-stream,application/postscript}"
AIRPRINT_URF="${AIRPRINT_URF:-W8,SRGB24,CP255,FN3}"
AIRPRINT_COLOR="${AIRPRINT_COLOR:-T}"
AIRPRINT_DUPLEX="${AIRPRINT_DUPLEX:-T}"

# Remove old AirPrint services (except our template if present elsewhere)
rm -f "${AVAHI_DIR}"/AirPrint-*.service

for printer in $CUPS_PRINTERS; do
    # Get printer info
    PRINTER_INFO=$(lpstat -l -p "$printer" 2>/dev/null | grep Description | cut -d: -f2 | xargs)
    PRINTER_LOCATION=$(lpstat -l -p "$printer" 2>/dev/null | grep Location | cut -d: -f2 | xargs)

    # Use printer name if no description
    [ -z "$PRINTER_INFO" ] && PRINTER_INFO="$printer"
    [ -z "$PRINTER_LOCATION" ] && PRINTER_LOCATION="${PRINTER_INFO}"

    # Create service file
    cat > "${AVAHI_DIR}/AirPrint-${printer}.service" <<EOF
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
    <txt-record>pdl=${AIRPRINT_PDL}</txt-record>
    <txt-record>URF=${AIRPRINT_URF}</txt-record>
    <txt-record>Color=${AIRPRINT_COLOR}</txt-record>
    <txt-record>Duplex=${AIRPRINT_DUPLEX}</txt-record>
    <txt-record>Copies=T</txt-record>
  </service>
</service-group>
EOF
done

_reload_avahi() {
    if [ -n "${AVAHI_HUP_CMD:-}" ]; then
        echo "Running AVAHI_HUP_CMD for host Avahi reload..."
        eval "$AVAHI_HUP_CMD" || echo "Warning: AVAHI_HUP_CMD failed (reload Avahi on the host manually)."
        return
    fi

    if [ "$AVAHI_PUBLISH_MODE" = "host" ]; then
        echo "AirPrint service files updated in ${AVAHI_DIR}"
        echo "If printers do not appear via Bonjour/AirPrint, reload Avahi on the TrueNAS host, e.g.:"
        echo "  sudo killall -HUP avahi-daemon"
        echo "  # or: sudo systemctl kill -s HUP avahi-daemon"
        return
    fi

    if pgrep -x avahi-daemon >/dev/null 2>&1; then
        killall -HUP avahi-daemon 2>/dev/null || true
    fi
}

_reload_avahi
