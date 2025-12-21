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
    dbus \
    && rm -rf /var/lib/apt/lists/*

# Create necessary directories
RUN mkdir -p /var/spool/samba \
    && chmod 1777 /var/spool/samba \
    && mkdir -p /var/lib/samba/printers \
    && mkdir -p /config/cups \
    && mkdir -p /config/samba \
    && mkdir -p /config/avahi \
    && mkdir -p /config/avahi/services \
    # Add the directory for initial config templates
    && mkdir -p /usr/local/etc_config_template/cups \
    && mkdir -p /usr/local/etc_config_template/samba \
    && mkdir -p /usr/local/etc_config_template/avahi/services


# Copy configuration files to a *temporary location* for initialization
COPY cupsd.conf /usr/local/etc_config_template/cups/cupsd.conf
COPY cups-pdf.conf /usr/local/etc_config_template/cups/cups-pdf.conf
COPY smb.conf /usr/local/etc_config_template/samba/smb.conf
COPY avahi-daemon.conf /usr/local/etc_config_template/avahi/avahi-daemon.conf
COPY airprint.service /usr/local/etc_config_template/avahi/services/airprint.service
COPY start.sh /start.sh
COPY generate-airprint.sh /usr/local/bin/generate-airprint.sh
RUN chmod +x /usr/local/bin/generate-airprint.sh

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

RUN useradd -r -G lpadmin -M cups-admin && \
    echo "cups-admin:admin" | chpasswd

# Start all services
CMD ["/start.sh"]
