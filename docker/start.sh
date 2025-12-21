#!/bin/bash
set -e

echo "=========================================="
echo "Starting TrueNAS Print Server"
echo "=========================================="

# Function to handle shutdown
shutdown_handler() {
    echo "Shutting down services..."
    pkill avahi-daemon || true
    pkill smbd || true
    pkill nmbd || true
    cupsd -t && kill $(cat /var/run/cups/cupsd.pid) || true
    exit 0
}

trap shutdown_handler SIGTERM SIGINT

# Create necessary directories if they don't exist
mkdir -p /var/spool/samba
mkdir -p /var/lib/samba/printers
mkdir -p /var/spool/cups-pdf
mkdir -p /run/cups/certs
mkdir -p /var/run/dbus

# Set permissions
chmod 1777 /var/spool/samba
chmod 755 /var/lib/samba/printers
chmod 1777 /var/spool/cups-pdf
chmod 755 /run/cups/certs

# Start D-Bus (required for Avahi)
echo "Starting D-Bus..."
rm -f /var/run/dbus/pid
dbus-daemon --system --fork || true

# Wait a moment for D-Bus to start
sleep 2

# Start Avahi daemon
echo "Starting Avahi daemon..."
avahi-daemon --daemonize --no-chroot || {
    echo "Warning: Avahi failed to start, continuing anyway..."
}

# Wait for Avahi to initialize
sleep 2

# Start Samba
echo "Starting Samba services..."
smbd --foreground --no-process-group &
SMBD_PID=$!
nmbd --foreground --no-process-group &
NMBD_PID=$!

# Start CUPS
echo "Starting CUPS..."
cupsd -f &
CUPSD_PID=$!

# Wait for CUPS to be ready
echo "Waiting for CUPS to be ready..."
for i in {1..30}; do
    if lpstat -r >/dev/null 2>&1; then
        echo "CUPS is ready!"
        break
    fi
    echo "Waiting for CUPS... ($i/30)"
    sleep 1
done

# Configure CUPS for remote access
echo "Configuring CUPS..."
cupsctl --remote-admin --remote-any --share-printers 2>/dev/null || true
cupsctl BrowseLocalProtocols=dnssd 2>/dev/null || true

# Generate initial AirPrint services
echo "Generating AirPrint services..."
/usr/local/bin/generate-airprint.sh

echo "=========================================="
echo "Print Server Started Successfully!"
echo "=========================================="
echo "CUPS Web Interface: http://[SERVER_IP]:631"
echo "Samba Printers: \\\\[SERVER_IP]\\printers"
echo "=========================================="
echo ""
echo "Services running:"
echo "- CUPS (PID: $CUPSD_PID)"
echo "- Samba SMB (PID: $SMBD_PID)"
echo "- Samba NMB (PID: $NMBD_PID)"
echo "- Avahi mDNS"
echo ""
echo "Connect your USB printer and configure it at:"
echo "http://[SERVER_IP]:631/admin"
echo ""
echo "Press Ctrl+C to stop all services"
echo "=========================================="

# Monitor processes and restart if needed
LAST_PRINTER_COUNT=0
while true; do
    # Check if CUPS is still running
    if ! kill -0 $CUPSD_PID 2>/dev/null; then
        echo "ERROR: CUPS died, restarting..."
        cupsd -f &
        CUPSD_PID=$!
    fi
    
    # Check if Samba is still running
    if ! kill -0 $SMBD_PID 2>/dev/null; then
        echo "ERROR: Samba SMB died, restarting..."
        smbd --foreground --no-process-group &
        SMBD_PID=$!
    fi
    
    if ! kill -0 $NMBD_PID 2>/dev/null; then
        echo "ERROR: Samba NMB died, restarting..."
        nmbd --foreground --no-process-group &
        NMBD_PID=$!
    fi
    
    # Check if printer count changed (new printer added/removed)
    CURRENT_PRINTER_COUNT=$(lpstat -p 2>/dev/null | wc -l)
    if [ "$CURRENT_PRINTER_COUNT" != "$LAST_PRINTER_COUNT" ]; then
        echo "Printer count changed, regenerating AirPrint services..."
        /usr/local/bin/generate-airprint.sh
        LAST_PRINTER_COUNT=$CURRENT_PRINTER_COUNT
    fi
    
    sleep 10
done