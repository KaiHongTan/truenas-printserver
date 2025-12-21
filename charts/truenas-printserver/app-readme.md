# TrueNAS Print Server

Complete network print server solution with maximum cross-platform compatibility.

## Features

- **CUPS** - Industry-standard UNIX printing system
- **Samba** - Windows SMB printer sharing  
- **Avahi/mDNS** - Auto-discovery for macOS, iOS, and Linux
- **AirPrint** - Native wireless printing for Apple devices
- **IPP** - Modern internet printing protocol

## Compatibility

✅ Windows (Auto-discovery + SMB)  
✅ macOS (AirPrint + Bonjour)  
✅ iOS/iPadOS (AirPrint)  
✅ Linux (Avahi/CUPS)  
✅ Android (Mopria Print Service)

## Quick Start

1. **Deploy the app** with default settings (Host Network recommended)
2. **Connect your USB printer** to the TrueNAS server
3. **Access CUPS** at `http://[NAS-IP]:631`
4. **Add printer**: Administration → Add Printer → Select USB printer
5. **Enable sharing**: Check "Share This Printer"
6. **Print from any device** - auto-discovery works automatically!

## Configuration

### Recommended Settings
- **Host Network**: Enabled (for best auto-discovery)
- **USB Support**: Enabled (required for USB printers)
- **Storage**: Keep defaults (1Gi config, 5Gi spool)

### Network Access
- **Host Network Mode**: `http://[NAS-IP]:631`
- **NodePort Mode**: `http://[NAS-IP]:30631`

## Client Setup

**Windows**: Auto-discover or use `\\[NAS-IP]\printer-name`  
**Mac/iOS**: Printer appears automatically  
**Linux**: Auto-discovers via Avahi  
**Android**: Use Mopria Print Service app

## Support

- Documentation: [GitHub Repository](https://github.com/KaiHongTan/truenas-printserver)
- Issues: [GitHub Issues](https://github.com/KaiHongTan/truenas-printserver/issues)
