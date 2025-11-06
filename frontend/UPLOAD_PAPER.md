# How to Upload Your Research Paper PDF

## Quick Steps

### Step 1: Copy Your PDF File

Copy your research paper PDF file to the `public` folder in your project.

**On Windows:**
```powershell
# Navigate to project
cd F:\Project\sentinel-blaze-main

# Copy your PDF to public folder
copy "C:\path\to\your\research-paper.pdf" "public\research-paper.pdf"
```

**On Kali Linux:**
```bash
# Navigate to project
cd ~/capstone

# Copy your PDF to public folder
cp /path/to/your/research-paper.pdf public/research-paper.pdf

# Or if you're uploading from Windows, use scp:
scp your-paper.pdf kali@VM_IP:~/capstone/public/research-paper.pdf
```

### Step 2: Rename if Needed

The viewer expects the file to be named `research-paper.pdf`. If your PDF has a different name:

**Option A: Rename your file**
```bash
# On Kali Linux
mv public/your-paper-name.pdf public/research-paper.pdf
```

**Option B: Use environment variable**
Create a `.env` file in your project root:
```bash
# .env file
VITE_PAPER_FILENAME=your-paper-name.pdf
```

Then place your PDF as `public/your-paper-name.pdf`

### Step 3: Verify It's in the Right Place

**File structure should be:**
```
sentinel-blaze-main/
├── public/
│   ├── research-paper.pdf  ← Your PDF goes here
│   ├── favicon.ico
│   └── ...
├── src/
└── ...
```

### Step 4: Restart Dev Server

If the dev server is running, restart it to pick up the new file:

```bash
# Stop the server (Ctrl+C)
# Then restart
npm run dev
```

### Step 5: Test It

1. Open your browser: `http://localhost:8080`
2. Scroll to the "Research Paper" section
3. Click "📄 View Research Paper" button
4. Your PDF should open in a full-screen viewer

---

## File Location Details

### Default Path
- **File location:** `public/research-paper.pdf`
- **URL in browser:** `http://localhost:8080/research-paper.pdf`

### Custom Filename
If you want to use a different filename:

1. **Create `.env` file** in project root:
   ```
   VITE_PAPER_FILENAME=my-research-paper.pdf
   ```

2. **Place your PDF** as `public/my-research-paper.pdf`

3. **Restart dev server**

---

## Troubleshooting

### PDF doesn't show / "PDF Not Found" error

**Check 1: File exists**
```bash
# On Kali Linux
ls -la public/research-paper.pdf

# Should show file details, not "No such file"
```

**Check 2: File permissions**
```bash
# Make sure file is readable
chmod 644 public/research-paper.pdf
```

**Check 3: File name matches**
- Default: `research-paper.pdf` (lowercase, with hyphen)
- Or check `.env` for `VITE_PAPER_FILENAME`

**Check 4: Restart dev server**
- Vite needs to be restarted to pick up new files in `public/`

### PDF shows but is blank/empty

- Check if PDF is corrupted: open it in a PDF viewer
- Check browser console (F12) for errors
- Try a different PDF file to test

### PDF loads but viewer is slow

- Large PDF files (>50MB) may load slowly
- Consider compressing the PDF if it's very large
- Or host it externally and update the iframe src

---

## Alternative: Host PDF Externally

If you want to host the PDF on a different server:

1. **Update `ResearchPaperViewer.tsx`:**
   ```tsx
   const PDF_URL = "https://your-domain.com/path/to/paper.pdf";
   ```

2. **Or use environment variable:**
   ```bash
   # .env
   VITE_PAPER_URL=https://your-domain.com/path/to/paper.pdf
   ```

---

## File Size Recommendations

- **Recommended:** < 10MB for fast loading
- **Maximum:** 50MB (may be slow)
- **If larger:** Consider hosting externally or compressing

---

## Quick Reference

| Task | Command |
|------|---------|
| Copy PDF to public | `cp paper.pdf public/research-paper.pdf` |
| Check if file exists | `ls -la public/research-paper.pdf` |
| Rename PDF | `mv public/old-name.pdf public/research-paper.pdf` |
| Set custom filename | Create `.env` with `VITE_PAPER_FILENAME=your-file.pdf` |

---

## After Uploading

Once your PDF is in place:
1. ✅ File is in `public/research-paper.pdf`
2. ✅ Restart dev server: `npm run dev`
3. ✅ Open browser: `http://localhost:8080`
4. ✅ Click "View Research Paper" button
5. ✅ PDF should display in full-screen viewer

---

## Git Considerations

**Should you commit the PDF to Git?**

- **Small PDF (<5MB):** Yes, you can commit it
- **Large PDF (>5MB):** Consider using Git LFS or hosting externally

**To commit:**
```bash
git add public/research-paper.pdf
git commit -m "Add research paper PDF"
git push
```

**To ignore (if too large):**
Add to `.gitignore`:
```
public/*.pdf
# or
public/research-paper.pdf
```

