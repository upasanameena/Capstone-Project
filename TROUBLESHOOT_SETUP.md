# Troubleshooting: start_all.sh Not Found

## Issue
You're getting: `chmod: cannot access 'start_all.sh': No such file or directory`

## Quick Fix Commands

### 1. Check if you're in the right directory and list files:
```bash
pwd
ls -la
```

### 2. If the file doesn't exist, check if you're in the correct project:
```bash
cd ~
ls -la | grep -i capstone
```

### 3. If you need to clone the repository again:
```bash
cd ~
git clone https://github.com/upasanameena/Capstone-Project.git
cd Capstone-Project/backend
chmod +x start_all.sh
./start_all.sh
```

### 4. If you're in a different directory (like Capstonefinal), navigate correctly:
```bash
cd ~/Capstonefinal/Capstone-Project/backend
ls -la start_all.sh  # Check if file exists
```

### 5. If file is missing, copy it or pull from git:
```bash
cd ~/Capstonefinal/Capstone-Project
git pull origin main  # or master, depending on your branch
cd backend
chmod +x start_all.sh
./start_all.sh
```

### 6. Alternative: Create the file manually
If the file is truly missing, you can verify the directory structure:
```bash
cd ~/Capstonefinal/Capstone-Project/backend
find . -name "*.sh" -type f
```

## One-Command Setup (if starting fresh)
```bash
cd ~ && git clone https://github.com/upasanameena/Capstone-Project.git && cd Capstone-Project/backend && chmod +x start_all.sh && ./start_all.sh
```

