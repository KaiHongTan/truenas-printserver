# TrueNAS Scale Print Server

[![Build and Push Docker Image](https://github.com/KaiHongTan/truenas-printserver/actions/workflows/docker-build.yml/badge.svg)](https://github.com/KaiHongTan/truenas-printserver/actions/workflows/docker-build.yml)

All-in-one network print server for TrueNAS Scale with maximum cross-platform compatibility.

**TrueNAS Scale 24.10 (Electric Eel) and later (including 25.x)** use **Docker-based Apps**, not Kubernetes. Install this image with **Custom App** or **Install via YAML** (see [Installation](#installation)). The Helm catalog under [`trains/charts/`](trains/charts/truenas-printserver/) applies only to **older Scale** releases that still ran k3s.

## Features

- **CUPS** — print server with web UI (`http://<NAS-IP>:631`)
- **Samba/SMB** — Windows printer sharing
- **Avahi/mDNS** — discovery on macOS, iOS, and Linux (on TrueNAS: optional **host Avahi** mode so AirPrint files are published by the NAS, not a second Avahi in the container)
- **AirPrint** — Apple devices
- **IPP** — network printing
- **USB** — pass-through from the NAS when configured
- **Persistent storage** — configs and spool via bind mounts / ixVolumes

## Compatible clients

- Windows 10/11, macOS, iOS/iPadOS, Linux (Avahi/CUPS), Android (e.g. Mopria), Chrome OS (IPP)

## Installation

Choose one method. **Host networking** is recommended (same default as the legacy Helm chart).

### Method 1: Install iX App (wizard)

1. Set an **apps pool** if prompted: **Apps** → choose pool for applications.
2. **Apps** → **Discover Apps** → **Custom App** (Install iX App).
3. **Application name**: e.g. `truenas-printserver` (lowercase, DNS-safe).
4. **Image**: Repository `ghcr.io/kaihongtan/truenas-printserver`, tag `latest` (or pin a tag), pull policy as you prefer. (Docker requires a **lowercase** `ghcr.io/user/repo` path; GitHub repo URLs may still be mixed case.)
5. **Network**: Enable **Host network**.
6. **Security**: Enable **Privileged**. Under **Capabilities**, add: `NET_ADMIN`, `NET_RAW`, `NET_BIND_SERVICE`, `SYS_ADMIN`.
7. **Environment variables** (add each name/value):

   | Name | Example value |
   |------|----------------|
   | `TZ` | `America/New_York` |
   | `WORKGROUP` | `WORKGROUP` |
   | `SERVER_NAME` | `TrueNAS-Print` |
   | `CUPS_MAX_JOBS` | `500` |
   | `CUPS_LOG_LEVEL` | `warn` |
   | `SAMBA_GUEST_ACCESS` | `true` |
   | `SAMBA_WINS_SUPPORT` | `true` |
   | `AVAHI_IPV6` | `true` |
   | `AVAHI_HOSTNAME` | `truenas-print` |
   | `AVAHI_DOMAIN` | `local` |
   | `AVAHI_PUBLISH_MODE` | `host` (recommended on TrueNAS — see below) |
   | `AIRPRINT_SERVICES_DIR` | `/airprint/avahi-services` (must match the AirPrint storage mount) |

8. **TrueNAS and Avahi (AirPrint discovery)**  
   TrueNAS already runs **Avahi** on the host. With **host networking**, starting a second Avahi inside the container competes for **UDP 5353**, so generated `AirPrint-*.service` files may never be advertised. **Fix:** set `AVAHI_PUBLISH_MODE=host`, set `AIRPRINT_SERVICES_DIR` to a path such as `/airprint/avahi-services`, and add storage:

   - **Host path** `/etc/avahi/services` (on the NAS) → **container** `/airprint/avahi-services` (read-write).

   The container’s `generate-airprint.sh` then writes into the **host** service directory; host Avahi picks them up after a reload (see [Troubleshooting](#troubleshooting)). You do **not** need a separate `/etc/avahi` config volume for this mode.

   Optional: set `AVAHI_HUP_CMD` to a command that reloads host Avahi (advanced; often unnecessary if you reload once after adding printers).

9. **Storage** (use **ixVolumes** and/or **Host path**). The startup script links **`/etc/cups`** and **`/etc/samba`** to **`/config/cups`** and **`/config/samba`** — mount persistence there (not only at `/etc/...`, or the symlink step can hide your mount):

   | Mount path in container | Purpose |
   |-------------------------|---------|
   | `/config/cups` | CUPS configuration |
   | `/config/samba` | Samba configuration |
   | `/airprint/avahi-services` | AirPrint `.service` files for **host** Avahi (pair with `AVAHI_PUBLISH_MODE=host`) |
   | `/var/spool/cups` | CUPS spool |
   | `/var/spool/samba` | Samba spool |
   | `/var/spool/cups-pdf` | PDF output spool |

   If you use **`AVAHI_PUBLISH_MODE=container`** instead (not recommended on TrueNAS with host network), mount **`/config/avahi`** for in-container Avahi config and omit the host `/etc/avahi/services` bind.

11. **USB printers**: Add a **Host path** (or equivalent) mount **Host** `/dev/bus/usb` → **Container** `/dev/bus/usb`. Skip if you only use network printers.
12. **Portal** (optional): HTTP, use node IP, port **631**, path `/`.
13. **Restart policy**: e.g. **Unless stopped** or **Always**.
14. **Resources** (optional): e.g. limit 1 CPU / 512Mi RAM; request 100m CPU / 128Mi RAM.
15. Deploy, then open **CUPS**: `http://<NAS-IP>:631`.

Official UI reference: [Custom App Screens](https://www.truenas.com/docs/scale/scaleuireference/apps/installcustomappscreens/).

### Method 2: Install via YAML

1. Edit [`deploy/truenas-scale-25-compose.yaml`](deploy/truenas-scale-25-compose.yaml): replace every `/CHANGE_ME/...` host path with real paths or adapt after paste using TrueNAS storage UI.
2. **Apps** → **Discover Apps** → **Custom App** → **Install via YAML**, paste the compose, deploy.

If TrueNAS rejects part of the file, use **Method 1** and mirror the same settings; Compose dialects can differ slightly by release.

### Legacy: Helm catalog (pre–24.10 only)

On **TrueNAS Scale 24.04 and earlier** (k3s / Helm Apps), you could add this repo as a catalog and install from **Discover Apps**. That flow **does not** apply to 24.10+.

<details>
<summary>Legacy catalog steps (Dragonfish and older)</summary>

1. **Apps** → **Manage Catalogs** → **Add Catalog** — repository `https://github.com/KaiHongTan/truenas-printserver`, branch `main`, preferred train `charts`.
2. **Discover Apps** → install **TrueNAS Print Server** with **Host network** enabled.

</details>

<details>
<summary>Legacy Helm CLI (not for Docker-era Scale)</summary>

```bash
helm repo add truenas-printserver https://KaiHongTan.github.io/truenas-printserver
helm repo update
helm install printserver truenas-printserver/truenas-printserver \
  --namespace ix-printserver \
  --create-namespace
```

</details>

## Migrating from an old Kubernetes app install

If you upgraded the NAS from pre–24.10 and had this app under k3s: **back up** the datasets that held CUPS, Samba, Avahi, and spool data. Deploy using Method 1 or 2, then point the new mounts at the **same host paths** (or copy data into new ixVolumes). Host-path data was not always moved automatically; see TrueNAS release notes for your upgrade path.

## Configuration reference

| Setting | Recommended | Notes |
|--------|-------------|--------|
| Host network | On | Best discovery; CUPS at port 631 on NAS IP |
| USB | Mount `/dev/bus/usb` | When using USB printers |
| Privileged + caps | As in wizard above | Matches [`values.yaml`](trains/charts/truenas-printserver/values.yaml) |

Without host network you must **publish ports** (631 TCP, 445/139 TCP, 137–138 UDP, 5353 UDP for mDNS) and may lose some discovery behavior — same trade-off as the old NodePort mode.

## Usage

### Add a printer

1. Open `http://<NAS-IP>:631`
2. **Administration** → **Add Printer** → choose the printer (e.g. USB)
3. Enable **Share This Printer**, pick a driver, save

### Clients

- **Windows**: Settings → Printers, or `\\<NAS-IP>\<printer-name>`
- **macOS / iOS**: should discover via Bonjour/AirPrint when host networking is used
- **Linux**: `system-config-printer` or `lpadmin -p NAME -v ipp://<NAS-IP>:631/printers/<NAME> -E`
- **Android**: e.g. Mopria Print Service

## Troubleshooting

### Printer not seen on USB

On the NAS (SSH): `lsusb`. In the app **Shell** (Apps → your app): `lsusb` and `lpinfo -v`. Ensure `/dev/bus/usb` is mounted and **Privileged** is on.

### AirPrint / Bonjour does not show the printer

**iPhone vs Mac:** iOS expects **`image/urf`** in the `pdl` TXT record and a real **`URF=...`** feature string — **`URF=none`** (older images) makes many iPhones skip the printer. Rebuild/pull the latest image, regenerate services, then **`killall -HUP avahi-daemon`** on the host.

For **monochrome / label-only** queues, if iOS still misbehaves, set env on the app (optional overrides for `generate-airprint.sh`): **`AIRPRINT_COLOR=F`**, **`AIRPRINT_DUPLEX=F`**. Advanced: **`AIRPRINT_PDL`**, **`AIRPRINT_URF`** if you tune per site.

When using **`AVAHI_PUBLISH_MODE=host`**, confirm **`AirPrint-*.service`** files exist on the NAS under **`/etc/avahi/services`**, then reload host Avahi (SSH on TrueNAS as root):

```bash
killall -HUP avahi-daemon
# or: systemctl kill -s HUP avahi-daemon
```

Add or remove a printer in CUPS to re-run `generate-airprint.sh`, or restart the app.

### Cannot open CUPS

With **host network**: `http://<NAS-IP>:631`. Check nothing else binds 631. Use **View Logs** on the installed app.

### Logs and shell (Scale 24.10+)

Use **Apps** → **Installed Applications** → select **truenas-printserver** (or your name) → **View Logs** / **Shell**.

On the NAS CLI (if you have Docker): `docker ps` to find the container, then:

```bash
docker logs -f <container_id>
docker exec -it <container_id> lpstat -r
```

### Legacy kubectl (only if you still run k3s)

```bash
kubectl exec -it -n ix-printserver <pod> -- lsusb
kubectl logs -n ix-printserver -l app.kubernetes.io/name=truenas-printserver -f
```

## Architecture

```
TrueNAS host
  └── Docker container (privileged, host network)
        CUPS :631 | Samba :445/:139 | Avahi mDNS :5353/udp
        └── /dev/bus/usb  →  USB printer(s)
```

## Updating

**Apps** → **Installed Applications** → your print server → update image tag or redeploy after changing YAML. Pull policy **Always** if you want every restart to re-pull `latest`.

## Uninstall

**Apps** → **Installed Applications** → **Delete**. Datasets you attached remain on disk unless you remove them separately.

## Contributing

Pull requests are welcome: fork, branch, commit, push, open a PR.

## License

MIT — see [LICENSE](LICENSE).

## Credits

- [CUPS](https://www.cups.org/)
- [Samba](https://www.samba.org/)
- [Avahi](https://www.avahi.org/)

**Support:** [Issues](https://github.com/KaiHongTan/truenas-printserver/issues) · [Discussions](https://github.com/KaiHongTan/truenas-printserver/discussions)
