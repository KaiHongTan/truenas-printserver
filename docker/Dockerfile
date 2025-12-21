FROM debian:bookworm-slim

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install all required packages
RUN apt-get update && apt-get install -y \
    cups \
    cups-client \
    cups-filters \
    cups-bsd \
    cups-pdf \
    printer-driver-gutenprint \
    printer-driver-hpcups \
    hplip \
    samba \
    samba-common-bin \
    avahi-daemon \
    avahi-utils \
    libnss-mdns \
    inotify-tools \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Create necessary directories
RUN mkdir -p /var/spool/samba \
    && chmod 1777 /var/spool/samba \
    && mkdir -p /var/lib/samba/printers \
    && mkdir -p /config/cups \
    && mkdir -p /config/samba \
    && mkdir -p /config/avahi

# Copy configuration files
COPY cupsd.conf /etc/cups/cupsd.conf
COPY cups-pdf.conf /etc/cups/cups-pdf.conf
COPY smb.conf /etc/samba/smb.conf
COPY avahi-daemon.conf /etc/avahi/avahi-daemon.conf
COPY airprint.service /etc/avahi/services/airprint.service
COPY start.sh /start.sh

# Make start script executable
RUN chmod +x /start.sh

# Expose necessary ports
# 631 - CUPS/IPP
# 139, 445 - Samba
# 137/udp, 138/udp - NetBIOS
# 5353/udp - mDNS/Avahi
EXPOSE 631/tcp 139/tcp 445/tcp 137/udp 138/udp 5353/udp

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD lpstat -r || exit 1

# Set working directory
WORKDIR /

# Start all services
CMD ["/start.sh"]
