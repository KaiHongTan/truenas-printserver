# Deployment Guide

Complete guide for deploying the TrueNAS Print Server from GitHub.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [GitHub Setup](#github-setup)
3. [TrueNAS Configuration](#truenas-configuration)
4. [Printer Setup](#printer-setup)
5. [Client Configuration](#client-configuration)
6. [Troubleshooting](#troubleshooting)

## Prerequisites

### GitHub Account
- Create a free account at https://github.com if you don't have one
- Repository will be public (required for free GitHub Container Registry)

### TrueNAS Scale
- **24.10 (Electric Eel), 25.x, or newer:** Apps use Docker, not the Helm catalog in this repo. Install the container via **Custom App** or **Install via YAML** — see the main [README.md](README.md) and [deploy/truenas-scale-25-compose.yaml](deploy/truenas-scale-25-compose.yaml).
- **24.04 (Dragonfish) or earlier:** legacy k3s/Helm catalog flow described in this document may still apply.
- Apps feature enabled; at least ~2GB RAM free for the app workload; USB printer if you use USB passthrough

## GitHub Setup

### Step 1: Fork or Create Repository

**Option A: Fork this repository (easiest)**
1. Click "Fork" button on the original repository
2. This creates a copy in your account

**Option B: Create new repository**
1. Download all files from this package
2. Create new repository on GitHub
3. Upload files following SETUP.md instructions

### Step 2: Enable GitHub Actions

1. Go to your repository
2. Click **Actions** tab
3. Click **"I understand my workflows, go ahead and enable them"**

### Step 3: Wait for Docker Build

1. Push code or create a release tag
2. Go to **Actions** tab
3. Watch the "Build and Push Docker Image" workflow
4. Wait for green checkmark (usually 2-5 minutes)

### Step 4: Make Package Public

1. Go to your GitHub profile → **Packages**
2. Click on **truenas-printserver**
3. Click **Package settings**
4. Under "Danger Zone" → **Change visibility** → **Public**
5. Confirm

## TrueNAS Configuration

### Method 1: Using TrueNAS Catalog (Recommended)

#### Add Catalog

1. Open TrueNAS Scale web interface
2. Navigate to **Apps** → **Manage Catalogs**
3. Click **Add Catalog**
4. Fill in the form:
   ```
   Name: TrueNAS Print Server
   Repository: https://github.com/KaiHongTan/truenas-printserver
   Branch: main
   Preferred Trains: charts
   ```
5. Click **Save**

#### Wait for Sync

1. Stay on "Manage Catalogs" page
2. Wait for the new catalog to show "Healthy" status
3. This may take 1-3 minutes
4. Refresh page if needed

#### Install Application

1. Navigate to **Apps** → **Discover Apps**
2. In the search bar, type: "print"
3. Find **TrueNAS Print Server**
4. Click **Install**

#### Configure Application

**Application Name:**
- Enter: `printserver` (or any name you prefer)

**Container Images:**
- Repository: `ghcr.io/kaihongtan/truenas-printserver`
- Tag: `latest`
- Pull Policy: `IfNotPresent`

**Network Configuration:**
- ✅ Use Host Network: **Enabled** (RECOMMENDED)
  - This provides best auto-discovery
  - Printer will appear automatically on all devices

**Storage Configuration:**
- ✅ Enable Configuration Storage: **Enabled**
  - Size: `1Gi` (default is fine)
- ✅ Enable Spool Storage: **Enabled**
  - Size: `5Gi` (increase if you print large files)

**Environment Variables:**
- Timezone: Select your timezone (e.g., `America/New_York`)
- Windows Workgroup: `WORKGROUP` (change if you use different workgroup)
- Server Name: `TrueNAS-Print` (or any friendly name)

**USB Configuration:**
- ✅ Enable USB Printer Support: **Enabled** (REQUIRED!)
- USB Device Host Path: `/dev/bus/usb` (default)

**Resource Management:**
- Use defaults unless you have specific needs:
  - CPU Limit: `1000m` (1 CPU core)
  - Memory Limit: `512Mi`
  - CPU Request: `100m`
  - Memory Request: `128Mi`

**Advanced Settings:**
- Keep defaults unless you need specific changes
- CUPS Max Jobs: `500`
- Log Level: `warn`
- Guest Access: ✅ Enabled
- WINS Support: ✅ Enabled

#### Deploy

1. Click **Install** at the bottom
2. Wait for deployment (usually 30-60 seconds)
3. Check status in **Installed Applications**
4. Wait for status to show **Active**

### Method 2: Using Helm Command Line

For advanced users who prefer command line:

```bash
# SSH to TrueNAS
ssh root@your-truenas-ip

# Add the Helm repository
helm repo add truenas-printserver https://KaiHongTan.github.io/truenas-printserver
helm repo update

# Install with default values
helm install printserver truenas-printserver/truenas-printserver \
  --namespace ix-printserver \
  --create-namespace

# Or install with custom values
helm install printserver truenas-printserver/truenas-printserver \
  --namespace ix-printserver \
  --create-namespace \
  --set image.repository=ghcr.io/kaihongtan/truenas-printserver \
  --set networking.hostNetwork=true \
  --set env.TZ=America/New_York
```

## Printer Setup

### Access CUPS Web Interface

**Determine the URL:**
- **Host Network mode**: `http://[NAS-IP]:631`
- **NodePort mode**: `http://[NAS-IP]:30631`

Replace `[NAS-IP]` with your TrueNAS IP address.

### Add Your Printer

1. **Open CUPS in browser**
   - Navigate to the URL above

2. **Go to Administration**
   - Click **Administration** in the top menu
   - Click **Add Printer**

3. **Select Local Printer**
   - You should see your USB printer under "Local Printers"
   - Example: "HP LaserJet 1020 (HP LaserJet 1020)"
   - If you don't see it, check troubleshooting section
   - Click **Continue**

4. **Configure Printer Details**
   - **Name**: Enter a simple name (no spaces), e.g., `HP-LaserJet`
   - **Description**: Human-readable name, e.g., `HP LaserJet 1020`
   - **Location**: Optional, e.g., `Office`
   - ✅ **Share This Printer**: **MUST BE CHECKED!**
   - Click **Continue**

5. **Select Printer Driver**
   - Search for your printer model
   - Select the appropriate driver (PPD file)
   - If exact model isn't listed, select a similar model
   - Click **Add Printer**

6. **Set Default Options**
   - Paper Size: Letter or A4
   - Quality: Normal
   - Other options as needed
   - Click **Set Default Options**

7. **Test Print**
   - Click **Maintenance** → **Print Test Page**
   - Verify the test page prints successfully

## Client Configuration

### Windows 10/11

#### Method 1: Auto-Discovery (if working)

1. Open **Settings** → **Devices** → **Printers & Scanners**
2. Click **Add a printer or scanner**
3. Wait for your printer to appear in the list
4. Click on it and click **Add device**

#### Method 2: Manual IPP

1. Open **Settings** → **Devices** → **Printers & Scanners**
2. Click **Add a printer or scanner**
3. Click **"The printer that I want isn't listed"**
4. Select **"Select a shared printer by name"**
5. Enter: `http://[NAS-IP]:631/printers/[PRINTER-NAME]`
   - Replace `[NAS-IP]` with your NAS IP
   - Replace `[PRINTER-NAME]` with the name you gave it in CUPS
6. Click **Next** and follow the wizard

#### Method 3: SMB/Network Path

1. Open File Explorer
2. In address bar, type: `\\[NAS-IP]`
3. You should see your printer
4. Right-click → **Connect**
5. Follow the installation wizard

### macOS

#### Auto-Discovery (Usually Works)

1. Open **System Settings** → **Printers & Scanners**
2. Click the **"+"** button
3. Your printer should appear in the list
4. Select it and click **Add**
5. macOS will automatically download drivers if needed

#### Manual IPP

1. Open **System Settings** → **Printers & Scanners**
2. Click **"+"** button
3. Click **IP** tab at the top
4. Fill in:
   - Protocol: **IPP - Internet Printing Protocol**
   - Address: `[NAS-IP]`
   - Queue: `printers/[PRINTER-NAME]`
   - Name: Your choice
   - Use: Select appropriate driver
5. Click **Add**

### iOS/iPadOS

**AirPrint (Automatic):**
1. Open any document, photo, or webpage
2. Tap the **Share** button
3. Select **Print**
4. Tap **Select Printer**
5. Your printer should appear automatically
6. Tap on it to select
7. Choose options and print

### Linux (Ubuntu/Debian)

#### Auto-Discovery

Most Linux systems with Avahi will auto-discover:
1. Open **Settings** → **Printers**
2. Your printer should appear
3. Click **Add** to install

#### Manual Configuration

```bash
# Using system-config-printer
sudo system-config-printer

# Or via command line
lpadmin -p MyPrinter \
  -v ipp://[NAS-IP]:631/printers/[PRINTER-NAME] \
  -E

# Set as default (optional)
lpadmin -d MyPrinter

# Test print
echo "Test Page" | lp -d MyPrinter
```

### Android

1. Install **Mopria Print Service** from Google Play Store
2. Open the document/photo you want to print
3. Tap **Share** → **Print**
4. Select printer from the list
5. Choose options and print

## Verification

### Check Service Status

**Via TrueNAS UI:**
1. **Apps** → **Installed Applications**
2. Find your print server
3. Status should show **Active**
4. Click the application name
5. View logs and pod details

**Via Command Line:**
```bash
# Check pods
kubectl get pods -n ix-printserver

# Check logs
kubectl logs -n ix-printserver -l app.kubernetes.io/name=truenas-printserver -f

# Check services
kubectl get svc -n ix-printserver

# Check printer status (inside container)
kubectl exec -n ix-printserver [POD-NAME] -- lpstat -t
```

### Test Printing

1. Access CUPS: `http://[NAS-IP]:631`
2. Click **Printers**
3. Click your printer name
4. Click **Maintenance** → **Print Test Page**
5. Verify test page prints

## Troubleshooting

### Printer Not Showing in CUPS

**Check USB connection:**
```bash
# On TrueNAS host
lsusb

# Inside container
kubectl exec -it -n ix-printserver [POD-NAME] -- lsusb
kubectl exec -it -n ix-printserver [POD-NAME] -- lpinfo -v
```

**Solutions:**
1. Verify USB support is enabled in app settings
2. Check USB cable connection
3. Try different USB port
4. Restart the application
5. Check pod logs for errors

### Can't Access CUPS Web Interface

**Check URL:**
- Host Network: `http://[NAS-IP]:631`
- NodePort: `http://[NAS-IP]:30631`

**Check service:**
```bash
kubectl get svc -n ix-printserver
```

**Check pod:**
```bash
kubectl get pods -n ix-printserver
kubectl logs -n ix-printserver [POD-NAME]
```

### Auto-Discovery Not Working

**For Windows:**
1. Try manual IPP method instead
2. Check Windows firewall settings
3. Ensure network is set to "Private" not "Public"

**For macOS/iOS:**
1. Ensure both devices are on same network
2. Check firewall settings on Mac
3. Try manual IPP method

**For all platforms:**
1. Verify host networking is enabled
2. Check if Avahi is running in container
3. Try restarting the application

### Printer Shows as Paused

```bash
# Get pod name
kubectl get pods -n ix-printserver

# Resume printer
kubectl exec -n ix-printserver [POD-NAME] -- cupsenable [PRINTER-NAME]
```

### Clear Stuck Print Jobs

```bash
# Cancel all jobs
kubectl exec -n ix-printserver [POD-NAME] -- cancel -a

# Or cancel specific printer's jobs
kubectl exec -n ix-printserver [POD-NAME] -- cancel -a [PRINTER-NAME]
```

### Restart Application

**Via TrueNAS UI:**
1. **Apps** → **Installed Applications**
2. Find your print server
3. Click the three dots menu
4. Select **Stop**
5. Wait for it to stop
6. Click **Start**

**Via Command Line:**
```bash
# Delete pod (will automatically recreate)
kubectl delete pod -n ix-printserver [POD-NAME]
```

## Maintenance

### View Logs

```bash
# Real-time logs
kubectl logs -n ix-printserver -l app.kubernetes.io/name=truenas-printserver -f

# Last 100 lines
kubectl logs -n ix-printserver -l app.kubernetes.io/name=truenas-printserver --tail=100

# CUPS error log (inside container)
kubectl exec -n ix-printserver [POD-NAME] -- tail -f /var/log/cups/error_log
```

### Update Application

**Via TrueNAS UI:**
1. **Apps** → **Manage Catalogs**
2. Refresh the catalog
3. Go to **Installed Applications**
4. If update available, click **Update**

**Via Helm:**
```bash
helm repo update
helm upgrade printserver truenas-printserver/truenas-printserver \
  --namespace ix-printserver \
  --reuse-values
```

### Backup Configuration

Your printer configurations are stored in persistent volumes and will survive pod restarts. To backup:

```bash
# Find PVCs
kubectl get pvc -n ix-printserver

# Backup can be done through TrueNAS Datasets
# The data is stored in TrueNAS storage pools
```

## Support

If you encounter issues not covered here:

1. Check application logs
2. Review TrueNAS system logs
3. Consult the GitHub repository README
4. Open an issue on GitHub with:
   - TrueNAS Scale version
   - Application version
   - Pod logs
   - Description of the problem

## Next Steps

After successful deployment:
- Configure additional printers if needed
- Set up printer policies in CUPS
- Configure print quotas (if needed)
- Set up email notifications for print jobs (advanced)

---

**Congratulations!** Your network print server is now running and ready to use.
