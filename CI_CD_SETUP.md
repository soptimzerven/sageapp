# 🚀 CI/CD Setup Guide

## Android Build & Signing with GitHub Actions

This guide explains how to set up automated Android APK and AAB builds using GitHub Actions with secure keystore signing.

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Generate Keystore](#1-generate-keystore)
3. [Add GitHub Secrets](#2-add-github-secrets)
4. [Trigger Build](#3-trigger-build)
5. [Download Artifacts](#4-download-artifacts)
6. [Security Information](#security-information)
7. [Troubleshooting](#troubleshooting)

---

## Overview

The CI/CD pipeline automatically:
- ✅ Builds signed APK (for direct installation)
- ✅ Builds signed AAB (for Google Play Store)
- ✅ Uses secure keystore from GitHub Secrets
- ✅ Cleans up sensitive files after build
- ✅ Uploads artifacts for download

---

## 1. Generate Keystore

### Using the PowerShell Script (Recommended)

Run the keystore generation script from the `scripts` folder:

```powershell
# Navigate to project directory
cd "path\to\Coop Defender Mini"

# Run the keystore generator
.\scripts\generate-keystore.ps1
```

### What the script does:

1. **Prompts for 7+ company details** (all manual input):
   - Organization/Company Name
   - Organizational Unit
   - City/Locality
   - State/Province
   - Country Code (2 letters)
   - Contact Name
   - Contact Email

2. **Prompts for keystore configuration**:
   - Key Alias (default: `upload`)
   - Keystore Filename (default: `upload-keystore.jks`)
   - Keystore Password
   - Key Password

3. **Generates two files**:
   - `upload-keystore.jks` - The actual keystore
   - `upload-keystore.b64.txt` - Base64 encoded version for GitHub

### Privacy Guarantee

⚠️ **This script does NOT:**
- Read your system username
- Access your IP address
- Detect your location
- Auto-fill any information
- Transmit any data

✅ **ALL information is manually entered by you.**

---

## 2. Add GitHub Secrets

After generating the keystore, add these secrets to your GitHub repository:

### Navigate to Secrets:
`Repository` → `Settings` → `Secrets and variables` → `Actions` → `New repository secret`

### Required Secrets:

| Secret Name | Description | Value |
|------------|-------------|-------|
| `KEYSTORE_BASE64` | Base64 encoded keystore | Contents of `upload-keystore.b64.txt` file |
| `KEYSTORE_PASSWORD` | Keystore password | The password you entered for keystore |
| `KEY_ALIAS` | Key alias | The alias you entered (default: `upload`) |
| `KEY_PASSWORD` | Key password | The password you entered for key |

### How to add KEYSTORE_BASE64:

1. Open `upload-keystore.b64.txt` in a text editor
2. Copy the entire contents (it's one long line)
3. Paste as the value for `KEYSTORE_BASE64` secret

---

## 3. Trigger Build

The build triggers automatically on:
- ✅ Push to `main`, `master`, or `develop` branches
- ✅ Pull requests to `main` or `master`
- ✅ Manual trigger via GitHub Actions UI

### Manual Trigger:
1. Go to `Actions` tab in your repository
2. Select `Build Android APK & AAB` workflow
3. Click `Run workflow`
4. Select branch and click `Run workflow`

---

## 4. Download Artifacts

After a successful build:

1. Go to `Actions` tab
2. Click on the completed workflow run
3. Scroll to `Artifacts` section
4. Download:
   - `release-apk` - Contains `app-release.apk`
   - `release-aab` - Contains `app-release.aab`

Artifacts are retained for **30 days**.

---

## Security Information

### What's Protected:

| Item | Protection Method |
|------|------------------|
| Keystore file | Stored as Base64 in GitHub Secrets, decoded at runtime |
| Passwords | Stored in GitHub Secrets, never logged |
| key.properties | Created at runtime, deleted after build |

### Workflow Security Features:

1. **Keystore decoded to temp directory** - Not in workspace
2. **Secrets masked in logs** - GitHub auto-masks secret values
3. **Cleanup step runs always** - Even if build fails
4. **No secrets in code** - All values from GitHub Secrets

### Files Never Committed:

The `.gitignore` excludes:
- `*.jks` - Keystore files
- `*.keystore` - Keystore files
- `*.b64.txt` - Base64 encoded keystores
- `key.properties` - Password file

---

## Troubleshooting

### Build Fails: "Keystore not found"
- Verify `KEYSTORE_BASE64` secret is set
- Ensure the base64 content has no line breaks
- Re-generate and re-copy if needed

### Build Fails: "Invalid keystore format"
- Keystore may be corrupted
- Re-generate using the script

### Build Fails: "Wrong password"
- Verify `KEYSTORE_PASSWORD` matches exactly
- Verify `KEY_PASSWORD` matches exactly
- Passwords are case-sensitive

### Build Fails: "Key alias not found"
- Verify `KEY_ALIAS` matches what you entered during generation
- Default is `upload` if you pressed Enter

### Local Build Works, CI Fails
- Ensure `key.properties` is NOT committed
- The CI creates its own `key.properties` at runtime

---

## File Structure

```
project/
├── .github/
│   └── workflows/
│       └── android-build.yml    # CI/CD workflow
├── android/
│   ├── app/
│   │   └── build.gradle.kts     # Configured for CI signing
│   └── key.properties           # ⚠️ NEVER COMMIT (gitignored)
├── scripts/
│   └── generate-keystore.ps1    # Keystore generator
└── CI_CD_SETUP.md               # This file
```

---

## Quick Reference

```powershell
# Generate keystore (run once)
.\scripts\generate-keystore.ps1

# Secrets to add to GitHub:
# - KEYSTORE_BASE64
# - KEYSTORE_PASSWORD
# - KEY_ALIAS
# - KEY_PASSWORD

# Trigger build:
# Push to main/master/develop OR manual trigger in Actions tab
```

---

## Support

If you encounter issues:
1. Check the workflow logs in GitHub Actions
2. Verify all 4 secrets are set correctly
3. Ensure keystore was generated successfully
4. Try regenerating the keystore

---

*Last updated: December 2024*
