# Files to Upload to Server

## 📦 What to Upload

### 1. Admin Panel Files (from `admin/build/`)

Upload **ALL contents** of the `admin/build/` folder to `/public_html/admin/` on your server:

```
admin/build/
├── index.html                    ← REQUIRED
├── favicon.ico                   ← REQUIRED
├── asset-manifest.json           ← REQUIRED
├── manifest.json                 ← REQUIRED
├── robots.txt                    ← Optional
├── logo192.png                   ← Optional
├── logo512.png                   ← Optional
└── static/                       ← REQUIRED
    └── js/
        ├── main.*.js             ← REQUIRED (name will vary)
        ├── main.*.js.map         ← Optional (for debugging)
        └── main.*.js.LICENSE.txt ← Optional
```

**Important:** Upload the **contents** of `admin/build/`, not the `build` folder itself!

### 2. API Files (from `api/`)

Upload **ALL files** from the `api/` folder to `/public_html/api/` on your server:

```
api/
├── config.php                    ← REQUIRED (update with your DB credentials!)
├── subscribe.php                 ← REQUIRED
├── subscribers.php                ← REQUIRED
├── check-subscriber.php          ← Optional (if used)
└── .htaccess                     ← REQUIRED (security)
```

**⚠️ CRITICAL:** Edit `api/config.php` on the server with your actual database credentials!

---

## 📍 Server Structure

After uploading, your server should look like this:

```
/public_html/  (or /var/www/html/ or your web root)
│
├── admin/                        ← Admin panel
│   ├── index.html
│   ├── favicon.ico
│   ├── asset-manifest.json
│   ├── manifest.json
│   ├── robots.txt
│   ├── logo192.png
│   ├── logo512.png
│   └── static/
│       └── js/
│           └── main.*.js
│
├── api/                          ← PHP API
│   ├── config.php
│   ├── subscribe.php
│   ├── subscribers.php
│   ├── check-subscriber.php
│   └── .htaccess
│
├── index.html                    ← Landing page (already exists)
├── styles.css
└── script.js
```

---

## 🚀 Step-by-Step Upload

### Option 1: FTP/SFTP (FileZilla, WinSCP, Cyberduck)

1. **Connect to your server** via FTP/SFTP
2. **Navigate to** `/public_html/` (or your web root)
3. **Create folder** `admin/` if it doesn't exist
4. **Upload admin files:**
   - Open local folder: `admin/build/`
   - Select ALL files and folders inside `build/`
   - Upload to: `/public_html/admin/`
5. **Create folder** `api/` if it doesn't exist
6. **Upload API files:**
   - Open local folder: `api/`
   - Select ALL files
   - Upload to: `/public_html/api/`
7. **Edit** `/public_html/api/config.php` with your database credentials

### Option 2: SSH/SCP (Terminal)

```bash
# Connect to server
ssh user@szybkafucha.app

# Create directories
cd /var/www/html  # or /public_html
mkdir -p admin api

# From your local machine, upload files:
scp -r admin/build/* user@szybkafucha.app:/var/www/html/admin/
scp -r api/* user@szybkafucha.app:/var/www/html/api/

# Edit config.php on server
ssh user@szybkafucha.app
nano /var/www/html/api/config.php
# Update DB credentials, save and exit
```

### Option 3: cPanel File Manager

1. Login to cPanel
2. Open **File Manager**
3. Navigate to `public_html`
4. Create folder `admin` (if doesn't exist)
5. **Upload** → Select all files from `admin/build/` → Upload to `admin/`
6. Create folder `api` (if doesn't exist)
7. **Upload** → Select all files from `api/` → Upload to `api/`
8. Edit `api/config.php` with your database credentials

---

## ✅ Verification Checklist

After uploading, verify:

- [ ] `https://szybkafucha.app/admin/` shows the login page
- [ ] `https://szybkafucha.app/api/subscribers.php` returns JSON data
- [ ] Can login to admin panel with `admin@szybkafucha.pl` / `admin123`
- [ ] Users list loads in the admin panel
- [ ] No console errors in browser (F12)

---

## 🔄 Updating the Panel

When you make changes to the admin panel:

1. **Rebuild locally:**
   ```bash
   cd admin
   npm run build
   ```

2. **Upload only changed files:**
   - Usually just `admin/static/js/main.*.js` (new hash name)
   - Sometimes `admin/index.html` if routes changed
   - Upload and overwrite old files

---

## 📝 File Permissions

On Linux servers, set correct permissions:

```bash
# Admin files - readable by web server
chmod 644 /var/www/html/admin/*
chmod 755 /var/www/html/admin/
chmod 755 /var/www/html/admin/static/
chmod 755 /var/www/html/admin/static/js/

# API files - readable and executable
chmod 644 /var/www/html/api/*.php
chmod 644 /var/www/html/api/.htaccess
```

---

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| White page at `/admin/` | Check if `index.html` exists in `admin/` folder |
| 404 for `/admin/` | Check folder name and permissions |
| "Failed to fetch" | Check if `/api/subscribers.php` works |
| Old version showing | Hard refresh: Ctrl+Shift+R (Windows) or Cmd+Shift+R (Mac) |
