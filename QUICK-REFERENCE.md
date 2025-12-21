# Quick Reference

## Repository Structure

```
truenas-printserver/
├── .github/
│   └── workflows/
│       └── docker-build.yml          # Automated Docker builds
├── docker/
│   ├── Dockerfile                     # Print server image
│   ├── cupsd.conf                     # CUPS configuration
│   ├── smb.conf                       # Samba configuration
│   ├── avahi-daemon.conf              # Avahi configuration
│   ├── airprint.service               # AirPrint service
│   ├── cups-pdf.conf                  # PDF printer config
│   └── start.sh                       # Container startup script
├── charts/
│   └── truenas-printserver/
│       ├── Chart.yaml                 # Helm chart metadata
│       ├── values.yaml                # Default values
│       ├── questions.yaml             # TrueNAS UI form
│       ├── item.yaml                  # Catalog metadata
│       ├── app-readme.md              # App description
│       └── templates/
│           ├── _helpers.tpl           # Template helpers
│           ├── deployment.yaml        # Kubernetes deployment
│           ├── service.yaml           # Kubernetes service
│           └── pvc.yaml               # Persistent volumes
├── README.md                          # Main documentation
├── SETUP.md                           # GitHub setup guide
├── DEPLOYMENT.md                      # Deployment guide
├── LICENSE                            # MIT License
├── .gitignore                         # Git ignore rules
├── trains.yaml                        # Catalog index
└── icon.svg                           # App icon
```

## URLs to Update

Before pushing to GitHub, replace `KaiHongTan` with your GitHub username in:

1. `.github/workflows/docker-build.yml`
2. `charts/truenas-printserver/Chart.yaml`
3. `charts/truenas-printserver/values.yaml`
4. `charts/truenas-printserver/questions.yaml`
5. `charts/truenas-printserver/item.yaml`
6. `charts/truenas-printserver/app-readme.md`
7. `README.md`
8. `DEPLOYMENT.md`
9. `trains.yaml`

## Quick Commands

### Find and Replace Username
```bash
cd github-repo
find . -type f \( -name "*.yaml" -o -name "*.yml" -o -name "*.md" \) \
  -exec sed -i 's/KaiHongTan/your-github-username/g' {} +
```

### Initialize Git Repository
```bash
cd github-repo
git init
git add .
git commit -m "Initial commit: TrueNAS Print Server"
git branch -M main
git remote add origin https://github.com/KaiHongTan/truenas-printserver.git
git push -u origin main
```

### Monitor Docker Build
```bash
# After pushing to GitHub, watch the Actions tab
# https://github.com/KaiHongTan/truenas-printserver/actions
```

### Add to TrueNAS
```
Apps → Manage Catalogs → Add Catalog
Name: TrueNAS Print Server
Repository: https://github.com/KaiHongTan/truenas-printserver
Branch: main
Preferred Trains: charts
```

## Access Points

| Service | Host Network | NodePort |
|---------|-------------|----------|
| CUPS Web | http://[NAS-IP]:631 | http://[NAS-IP]:30631 |
| SMB Share | \\\\[NAS-IP]\\printer | \\\\[NAS-IP]\\printer |

## Default Ports

| Service | Port | Protocol | Purpose |
|---------|------|----------|---------|
| CUPS | 631 | TCP | Web interface & IPP |
| SMB | 445 | TCP | Windows sharing |
| NetBIOS | 139 | TCP | Windows discovery |
| NetBIOS-NS | 137 | UDP | Name service |
| NetBIOS-DGM | 138 | UDP | Datagram service |
| mDNS | 5353 | UDP | Avahi/Bonjour |

## Common kubectl Commands

```bash
# Get pod name
kubectl get pods -n ix-printserver

# View logs
kubectl logs -n ix-printserver [POD-NAME] -f

# Get shell access
kubectl exec -it -n ix-printserver [POD-NAME] -- /bin/bash

# Check printer status
kubectl exec -n ix-printserver [POD-NAME] -- lpstat -t

# Check USB devices
kubectl exec -n ix-printserver [POD-NAME] -- lsusb

# Restart pod
kubectl delete pod -n ix-printserver [POD-NAME]
```

## Troubleshooting Quick Fixes

### Printer not detected
```bash
# Check USB on host
lsusb

# Check USB in container
kubectl exec -n ix-printserver [POD-NAME] -- lsusb
kubectl exec -n ix-printserver [POD-NAME] -- lpinfo -v
```

### Resume paused printer
```bash
kubectl exec -n ix-printserver [POD-NAME] -- cupsenable [PRINTER-NAME]
```

### Clear print queue
```bash
kubectl exec -n ix-printserver [POD-NAME] -- cancel -a [PRINTER-NAME]
```

### View CUPS error log
```bash
kubectl exec -n ix-printserver [POD-NAME] -- tail -f /var/log/cups/error_log
```

## Image Locations

### GitHub Container Registry
```
ghcr.io/KaiHongTan/truenas-printserver:latest
ghcr.io/KaiHongTan/truenas-printserver:main
ghcr.io/KaiHongTan/truenas-printserver:v1.0.0
```

### Pull Image Manually
```bash
docker pull ghcr.io/KaiHongTan/truenas-printserver:latest
```

## Configuration Files

### CUPS
- Main config: `/etc/cups/cupsd.conf`
- Printers: `/etc/cups/printers.conf`
- PPD files: `/etc/cups/ppd/`

### Samba
- Main config: `/etc/samba/smb.conf`

### Avahi
- Daemon config: `/etc/avahi/avahi-daemon.conf`
- Services: `/etc/avahi/services/airprint.service`

## Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| TZ | UTC | Timezone |
| WORKGROUP | WORKGROUP | Windows workgroup |
| SERVER_NAME | TrueNAS-Print | Display name |
| CUPS_MAX_JOBS | 500 | Max concurrent jobs |
| CUPS_LOG_LEVEL | warn | Logging level |
| SAMBA_GUEST_ACCESS | true | Allow no password |
| SAMBA_WINS_SUPPORT | true | Enable WINS |
| AVAHI_IPV6 | true | Enable IPv6 |
| AVAHI_HOSTNAME | truenas-print | mDNS hostname |
| AVAHI_DOMAIN | local | mDNS domain |

## Support Resources

- **GitHub Repository**: https://github.com/KaiHongTan/truenas-printserver
- **GitHub Issues**: https://github.com/KaiHongTan/truenas-printserver/issues
- **CUPS Documentation**: https://www.cups.org/doc/
- **TrueNAS Forums**: https://forums.truenas.com/
- **TrueNAS Documentation**: https://www.truenas.com/docs/scale/

## Version Information

- **Chart Version**: 1.0.0
- **App Version**: 1.0.0
- **Kubernetes**: >= 1.16.0
- **TrueNAS Scale**: >= 24.04 (Dragonfish)

## License

MIT License - See LICENSE file for details
