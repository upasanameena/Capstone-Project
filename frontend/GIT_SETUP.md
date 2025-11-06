# Git Setup for Kali Linux VM

## Option 1: Push to GitHub/GitLab (Recommended)

### On Windows (where your project is now):

1. **Initialize git repository** (if not already done):
```powershell
cd F:\Project\sentinel-blaze-main
git init
git add .
git commit -m "Initial commit: UI visualization for CSV data"
```

2. **Create a repository on GitHub/GitLab** (or use existing one)

3. **Add remote and push**:
```powershell
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git branch -M main
git push -u origin main
```

### On Kali Linux VM:

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git
cd sentinel-blaze-main

# Install dependencies
npm install

# Set backend path if needed (if kali-vm-project-main is in different location)
export BACKEND_ROOT=/path/to/kali-vm-project-main

# Start API server
npm run api

# In another terminal, start UI
npm run dev
```

---

## Option 2: Direct Transfer via SCP

### On Windows (PowerShell):

```powershell
# Copy entire sentinel-blaze-main folder to VM
scp -r F:\Project\sentinel-blaze-main username@VM_IP:/home/username/

# Or use WinSCP/Putty for GUI transfer
```

### On Kali Linux VM:

```bash
cd ~/sentinel-blaze-main
npm install
export BACKEND_ROOT=/path/to/kali-vm-project-main  # if needed
npm run api  # Terminal 1
npm run dev  # Terminal 2
```

---

## Option 3: USB Transfer

1. Copy `F:\Project\sentinel-blaze-main` to USB drive
2. Plug USB into Kali VM
3. Mount USB and copy files:
```bash
sudo mkdir /mnt/usb
sudo mount /dev/sdb1 /mnt/usb  # Adjust device name
cp -r /mnt/usb/sentinel-blaze-main ~/
cd ~/sentinel-blaze-main
npm install
```

---

## Important Notes:

- **BACKEND_ROOT**: If your `kali-vm-project-main` folder is not a sibling of `sentinel-blaze-main`, set the environment variable:
  ```bash
  export BACKEND_ROOT=/path/to/kali-vm-project-main
  npm run api
  ```

- **Ports**: Make sure ports 5174 (API) and 8080 (UI) are not blocked by firewall

- **Node.js**: Ensure Node.js 18+ is installed on Kali:
  ```bash
  node -v
  # If not installed:
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt-get install -y nodejs
  ```

