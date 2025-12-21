# TrueNAS Scale Print Server

[![Build and Push Docker Image](https://github.com/KaiHongTan/truenas-printserver/actions/workflows/docker-build.yml/badge.svg)](https://github.com/KaiHongTan/truenas-printserver/actions/workflows/docker-build.yml)

All-in-one network print server for TrueNAS Scale with maximum cross-platform compatibility.

## 🎯 Features

✅ **CUPS** - Industry-standard print server with web interface  
✅ **Samba/SMB** - Native Windows printer sharing  
✅ **Avahi/mDNS** - Auto-discovery on macOS, iOS, and Linux  
✅ **AirPrint** - Wireless printing from Apple devices  
✅ **IPP** - Modern internet printing protocol  
✅ **USB Support** - Direct USB printer connection to NAS  
✅ **Persistent Storage** - Configuration survives updates  
✅ **TrueNAS UI** - Deploy directly from catalog  

## 📱 Compatible Devices

- **Windows** (10/11) - Auto-discovery + SMB
- **macOS** - AirPrint + Bonjour
- **iOS/iPadOS** - AirPrint
- **Linux** - Avahi/CUPS
- **Android** - Mopria Print Service
- **Chrome OS** - IPP printing

## 🚀 Installation

### Method 1: TrueNAS Catalog (Recommended)

1. **Add this repository as a catalog in TrueNAS Scale:**
   - Go to **Apps** → **Manage Catalogs**
   - Click **Add Catalog**
   - Name: `TrueNAS Print Server`
   - Repository: `https://github.com/KaiHongTan/truenas-printserver`
   - Branch: `main`
   - Preferred Trains: `charts`

2. **Install the app:**
   - Go to **Apps** → **Discover Apps**
   - Search for "TrueNAS Print Server"
   - Click **Install**
   - Configure settings (recommended: Host Network = Enabled)
   - Click **Install**

3. **Configure your printer:**
   - Access CUPS: `http://[NAS-IP]:631`
   - Go to **Administration** → **Add Printer**
   - Select your USB printer
   - ✅ Check "Share This Printer"
   - Choose appropriate driver
   - Done!

### Method 2: Manual Helm Installation

```bash
# Add the repository
helm repo add truenas-printserver https://KaiHongTan.github.io/truenas-printserver
helm repo update

# Install
helm install printserver truenas-printserver/truenas-printserver \
  --namespace ix-printserver \
  --create-namespace
```

## ⚙️ Configuration

### Recommended Settings

| Setting | Value | Description |
|---------|-------|-------------|
| Host Network | ✅ Enabled | Best for auto-discovery |
| USB Support | ✅ Enabled | Required for USB printers |
| Config Storage | 1Gi | Stores printer configs |
| Spool Storage | 5Gi | Stores print queue |
| Timezone | Your TZ | For accurate logs |

### Network Modes

**Host Network (Recommended)**
- Best auto-discovery across all platforms
- Access: `http://[NAS-IP]:631`
- Printer auto-appears on all devices

**NodePort Mode**
- Use if host network conflicts
- Access: `http://[NAS-IP]:30631`
- May require manual configuration on some devices

## 📋 Usage

### Adding a Printer

1. Open browser: `http://[NAS-IP]:631`
2. Click **Administration** → **Add Printer**
3. Select your USB printer from "Local Printers"
4. Configure:
   - **Name**: Simple name (no spaces)
   - **Description**: Human-readable description
   - ✅ **Share This Printer** (IMPORTANT!)
5. Select printer driver (PPD file)
6. Set default options (paper size, quality)
7. Click **Add Printer**

### Client Configuration

**Windows:**
1. Settings → Devices → Printers → Add a printer
2. Select printer from list (auto-discovered)
3. Or manually: `\\[NAS-IP]\printer-name`

**macOS:**
1. System Settings → Printers & Scanners
2. Click "+" to add
3. Printer appears automatically

**iOS/iPadOS:**
1. Open any document/photo
2. Tap Share → Print
3. Printer appears automatically (AirPrint)

**Linux:**
```bash
# Auto-discovers via Avahi
system-config-printer

# Or manual:
lpadmin -p MyPrinter -v ipp://[NAS-IP]:631/printers/[PRINTER-NAME] -E
```

**Android:**
1. Install "Mopria Print Service" from Play Store
2. Open document → Share → Print
3. Select printer from list

## 🔧 Troubleshooting

### Printer Not Detected

**Check USB connection:**
```bash
# On TrueNAS, check if printer is visible
lsusb

# Check in container
kubectl exec -it -n ix-printserver [POD-NAME] -- lsusb
kubectl exec -it -n ix-printserver [POD-NAME] -- lpinfo -v
```

**Solution:** Ensure USB support is enabled in app settings

### Can't Access Web Interface

**Host Network:** `http://[NAS-IP]:631`  
**NodePort:** `http://[NAS-IP]:30631`

Check your service:
```bash
kubectl get svc -n ix-printserver
```

### Services Won't Start

View logs:
```bash
kubectl logs -n ix-printserver -l app.kubernetes.io/name=truenas-printserver -f
```

Common fixes:
- Enable privileged mode in settings
- Verify USB host path mount
- Check port availability

### Printer Shows as Paused

```bash
kubectl exec -n ix-printserver [POD-NAME] -- cupsenable [PRINTER-NAME]
```

### Clear Print Queue

```bash
kubectl exec -n ix-printserver [POD-NAME] -- cancel -a [PRINTER-NAME]
```

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│           TrueNAS Scale Host            │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │   Kubernetes Pod (Privileged)     │ │
│  │                                   │ │
│  │  ┌─────────┐  ┌────────┐  ┌────┐ │ │
│  │  │  CUPS   │  │ Samba  │  │Avahi│ │
│  │  │ :631    │  │ :445   │  │mDNS │ │
│  │  └────┬────┘  └───┬────┘  └──┬─┘ │ │
│  │       │           │          │   │ │
│  │       └───────────┴──────────┘   │ │
│  │                 │                │ │
│  └─────────────────┼────────────────┘ │
│                    │                  │
│         ┌──────────▼──────────┐       │
│         │   /dev/bus/usb      │       │
│         │   (USB Devices)     │       │
│         └──────────┬──────────┘       │
└────────────────────┼──────────────────┘
                     │
              ┌──────▼──────┐
              │ USB Printer │
              └─────────────┘
```

## 📦 What's Included

- **CUPS 2.4+** with web interface
- **Samba 4.x** for SMB sharing
- **Avahi** for mDNS/Bonjour
- **Common printer drivers** (Gutenprint, HP, etc.)
- **AirPrint support** built-in
- **Health monitoring** and auto-restart

## 🔄 Updating

### Via TrueNAS UI
1. Go to **Apps** → Installed Applications
2. Find "TrueNAS Print Server"
3. Click **Update** (if available)

### Via Helm
```bash
helm repo update
helm upgrade printserver truenas-printserver/truenas-printserver \
  --namespace ix-printserver \
  --reuse-values
```

## 🗑️ Uninstallation

### Via TrueNAS UI
1. Go to **Apps** → Installed Applications
2. Find "TrueNAS Print Server"
3. Click **Delete**

### Via Helm
```bash
helm uninstall printserver -n ix-printserver
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Credits

Built with:
- [CUPS](https://www.cups.org/) - Common UNIX Printing System
- [Samba](https://www.samba.org/) - SMB/CIFS implementation
- [Avahi](https://avahi.org/) - mDNS/DNS-SD implementation

## 📞 Support

- **Documentation**: This README
- **Issues**: [GitHub Issues](https://github.com/KaiHongTan/truenas-printserver/issues)
- **Discussions**: [GitHub Discussions](https://github.com/KaiHongTan/truenas-printserver/discussions)

## ⭐ Show Your Support

If this project helped you, please consider giving it a ⭐!

---

**Made with ❤️ for TrueNAS Scale users who want hassle-free network printing**
