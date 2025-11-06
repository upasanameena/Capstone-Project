# Push Project to Git - Step by Step

## ✅ Repository is Ready!

Your local repository has been initialized and committed. Now push it to GitHub/GitLab.

---

## Step 1: Create a GitHub Repository

1. Go to **https://github.com** and sign in
2. Click the **"+"** icon (top right) → **"New repository"**
3. Fill in:
   - **Repository name:** `sentinel-blaze-main` (or any name you prefer)
   - **Description:** "UI visualization dashboard for ML firewall CSV data"
   - **Visibility:** Choose Public or Private
   - **DO NOT** check "Initialize with README" (we already have files)
4. Click **"Create repository"**

---

## Step 2: Push to GitHub

**Copy the commands from GitHub** (they'll show after creating the repo), OR use these:

```powershell
# Navigate to project
cd F:\Project\sentinel-blaze-main

# Add remote (replace YOUR_USERNAME and YOUR_REPO_NAME)
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git

# Push to GitHub
git branch -M main
git push -u origin main
```

**If asked for credentials:**
- Use a **Personal Access Token** (not your password)
- To create one: GitHub → Settings → Developer settings → Personal access tokens → Generate new token (classic)
- Give it `repo` permissions
- Copy the token and use it as password when pushing

---

## Step 3: Verify on GitHub

1. Go to your repository on GitHub
2. You should see all files including:
   - `server.mjs` (API server)
   - `src/components/DataVisualization.tsx` (Visualization component)
   - `QUICK_START.md` (Setup guide)
   - All other project files

---

## Step 4: Clone on Kali Linux VM

**On your Kali Linux VM, run:**

```bash
# Install git if not installed
sudo apt-get update
sudo apt-get install -y git

# Clone the repository
git clone https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git

# Or if you used a different name:
git clone https://github.com/YOUR_USERNAME/sentinel-blaze-main.git

# Navigate to project
cd sentinel-blaze-main

# Install Node.js (if not installed)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install dependencies
npm install

# Set backend path (if kali-vm-project-main is not a sibling folder)
export BACKEND_ROOT=/path/to/kali-vm-project-main

# Start API server (Terminal 1)
npm run api

# Start UI server (Terminal 2)
npm run dev

# Open browser: http://localhost:8080
```

---

## Alternative: Using GitLab

If you prefer GitLab:

1. Go to **https://gitlab.com** and create a new project
2. Use these commands:

```powershell
cd F:\Project\sentinel-blaze-main
git remote add origin https://gitlab.com/YOUR_USERNAME/YOUR_REPO_NAME.git
git branch -M main
git push -u origin main
```

---

## Troubleshooting

### "remote origin already exists"
```powershell
git remote remove origin
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
```

### "Authentication failed"
- Use a Personal Access Token instead of password
- Or use SSH: `git@github.com:YOUR_USERNAME/YOUR_REPO_NAME.git`

### "Permission denied"
- Make sure you have write access to the repository
- Check that the repository name/URL is correct

---

## Quick Reference

**Repository URL format:**
- HTTPS: `https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git`
- SSH: `git@github.com:YOUR_USERNAME/YOUR_REPO_NAME.git`

**After cloning on Kali, remember to:**
1. Set `BACKEND_ROOT` if backend is not in sibling folder
2. Run `npm install` to install dependencies
3. Start both servers (`npm run api` and `npm run dev`)

---

## Next Steps After Cloning on Kali

See `QUICK_START.md` for detailed setup instructions.

