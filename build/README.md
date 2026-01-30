# MouseUtilities - UIAccess Build System

Complete build system for enabling UIAccess in MouseUtilities, allowing the application to work with elevated windows and PowerToys.

---

## 🚀 Quick Start

### First Time Setup

1. **Open PowerShell as Administrator**
   - Press `Win + X` → Select "Terminal (Admin)" or "PowerShell (Admin)"

2. **Navigate and Build**
   ```powershell
   cd "C:\Users\artistro08\MouseUtilities\build"
   .\BUILD-ALL.ps1
   ```

3. **Launch Application**
   ```
   C:\Program Files\MouseUtilities\MouseUtilities.exe
   ```

**Done! UIAccess is now enabled!** 🎉

---

## 📋 What is UIAccess?

UIAccess (User Interface Privilege Isolation Access) allows applications to:

- ✅ Send input to elevated (administrator) windows **without running as admin**
- ✅ Interact with PowerToys when PowerToys is running elevated
- ✅ Bypass User Interface Privilege Isolation (UIPI) restrictions
- ✅ Run as normal user while having elevated access capabilities

### Requirements

For UIAccess to work, an application must:
1. Be digitally signed with a code signing certificate
2. Have `uiAccess="true"` in its manifest
3. Have execution level set to `asInvoker` (runs as normal user, not admin)
4. Be installed in a trusted location (Program Files)

---

## 📦 Prerequisites

- **Windows 10 or 11**
- **AutoHotkey v2.0+** - [Download here](https://www.autohotkey.com/)
- **Administrator privileges**

---

## 🔄 Build Process Overview

```
┌─────────────────────────────────────────────────────────┐
│  STEP 1: Create Certificate                             │
│  • Generate self-signed code signing certificate        │
│  • Install to Trusted Root store                        │
│  • Valid for 5 years                                    │
│  • Run once (requires admin for installation)           │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  STEP 2: Compile & Sign                                 │
│  • Compile MouseUtilities.ahk → .exe                    │
│  • Embed UIAccess manifest                              │
│  • Digitally sign executable                            │
│  • Run after every code change                          │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  STEP 3: Deploy                                         │
│  • Deploy to C:\Program Files\MouseUtilities\           │
│  • Copy settings and icons                              │
│  • Create shortcuts (optional)                          │
│  • Run after every build (requires admin)               │
└─────────────────────────────────────────────────────────┘
```

---

## 📁 File Structure

```
build/
├── BUILD-ALL.ps1              # Master build script (run this)
├── BUILD.bat                  # Double-click launcher
├── 1-CreateCertificate.ps1    # Step 1: Create certificate
├── 2-CompileAndSign.ps1       # Step 2: Compile and sign
├── 3-Deploy.ps1               # Step 3: Deploy to Program Files
├── MouseUtilities.manifest    # UIAccess manifest file
└── README.md                  # This file

certificates/
├── MouseUtilities.pfx         # Private certificate (created by Step 1)
└── MouseUtilities.cer         # Public certificate (created by Step 1)
```

---

## 🛠️ Build Scripts

### BUILD-ALL.ps1 (Recommended)
Runs all steps automatically:
```powershell
.\BUILD-ALL.ps1
```
- Creates certificate (if needed)
- Compiles and signs executable
- Deploys to Program Files
- Verifies everything is working

### Individual Steps

**Step 1: Create Certificate** (run once)
```powershell
.\1-CreateCertificate.ps1
```
- Creates self-signed certificate
- Password: `MouseUtilities2024!`
- Valid for 5 years

**Step 2: Compile & Sign** (run after code changes)
```powershell
.\2-CompileAndSign.ps1
```
- Compiles AHK to EXE
- Embeds UIAccess manifest
- Signs with certificate

**Step 3: Deploy** (run after building)
```powershell
.\3-Deploy.ps1
```
- Deploys to Program Files
- Copies settings and icons
- Creates shortcuts

---

## 🔄 Updating After Code Changes

When you modify `MouseUtilities.ahk`:

```powershell
cd "C:\Users\artistro08\MouseUtilities\build"
.\2-CompileAndSign.ps1
.\3-Deploy.ps1
```

**Note:** No need to recreate the certificate - it's valid for 5 years!

---

## 🐛 Troubleshooting

### "Script must be run as Administrator"
**Fix:** Right-click PowerShell → "Run as Administrator"

### "AutoHotkey compiler not found"
**Fix:** Install AutoHotkey v2 from https://www.autohotkey.com/

### "mt.exe not found"
The script will try alternative methods automatically. For best results:
- **Option A:** Install Resource Hacker - http://www.angusj.com/resourcehacker/
- **Option B:** Install Windows SDK - https://developer.microsoft.com/windows/downloads/windows-sdk/

### PowerToys Doesn't Respond

**Checklist:**
1. **Are you running from Program Files?**
   - UIAccess only works from: `C:\Program Files\MouseUtilities\`
   - Won't work from: Desktop, Downloads, or project folder

2. **Is PowerToys running?**
   - Open Task Manager and check for PowerToys.exe

3. **Does hotkey match PowerToys settings?**
   - Check `settings.ini` → `[ShowCursor_Settings]` → `TargetHotkey`
   - Default: `^!p` (Ctrl+Alt+P)
   - Must match PowerToys "Find My Mouse" hotkey

4. **Is MouseUtilities signed and deployed?**
   - Run `BUILD-ALL.ps1` again to verify

**Note:** With UIAccess, MouseUtilities runs as a **normal user** (no admin) but can still interact with elevated PowerToys.

### Certificate Expired (After 5 Years)

Re-run the build process:
```powershell
.\BUILD-ALL.ps1
```

This will create a new certificate and rebuild everything.

---

## 🔐 Security Notes

### Self-Signed Certificate

**Pros:**
- ✅ Free and immediate
- ✅ Works for personal/internal use
- ✅ Full control over certificate
- ✅ 5-year validity
- ✅ App runs as normal user (no UAC prompts)

**Cons:**
- ⚠️ Shows as "Unknown Publisher"
- ⚠️ May trigger SmartScreen warnings
- ⚠️ Not suitable for public distribution
- ⚠️ Build scripts require admin (but app itself doesn't)

### For Public/Commercial Distribution

Purchase a certificate from a trusted CA:
- **DigiCert** - https://www.digicert.com/
- **Sectigo** - https://www.sectigo.com/
- Cost: ~$100-400/year

To use a commercial certificate:
1. Export it to PFX format
2. Edit `2-CompileAndSign.ps1`:
   ```powershell
   $certPath = "C:\path\to\your\certificate.pfx"
   $pfxPassword = "YourPassword"
   ```
3. Skip Step 1, run Steps 2 and 3

---

## ❓ FAQ

### Do I need to rebuild every time I change settings.ini?
**No.** Just edit `C:\Program Files\MouseUtilities\settings.ini` directly.

### Do I need to rebuild every time I change the .ahk file?
**Yes.** Run:
```powershell
.\2-CompileAndSign.ps1
.\3-Deploy.ps1
```

### Can I run MouseUtilities from a different location?
**No, not with UIAccess.** Windows only allows UIAccess from:
- `C:\Program Files\`
- `C:\Program Files (x86)\`
- `C:\Windows\System32\`

### Does the app run as administrator?
**No!** With UIAccess, the app runs as a **normal user** but can interact with elevated windows. This is the whole benefit of UIAccess - no admin required, no UAC prompts!

### What if I don't need UIAccess?
Just run `MouseUtilities.ahk` directly. You won't need the build process, but:
- ❌ Won't work with elevated PowerToys
- ❌ Limited with admin windows
- ❌ Cannot send input to elevated applications

### Why does it show "Unknown Publisher"?
This is normal for self-signed certificates. The application is still safe and fully functional.

### How do I verify the signature?
```powershell
Get-AuthenticodeSignature "C:\Program Files\MouseUtilities\MouseUtilities.exe"
```

Look for:
- Status: "Valid" or "UnknownError" (both work with self-signed)
- SignerCertificate should be present

---

## 🎯 What Gets Created

After running `BUILD-ALL.ps1`:

**Certificates:**
- `certificates/MouseUtilities.pfx` - Private certificate
- `certificates/MouseUtilities.cer` - Public certificate

**Build Output:**
- `build/MouseUtilities.exe` - Signed executable with UIAccess

**Deployed Files:**
- `C:\Program Files\MouseUtilities\MouseUtilities.exe`
- `C:\Program Files\MouseUtilities\settings.ini`
- `C:\Program Files\MouseUtilities\MouseUtilities.ico`

**Optional:**
- Startup shortcut (if selected during deployment)
- Desktop shortcut (if selected during deployment)

---

## 🔧 Advanced Options

### Custom Certificate Password

Edit `1-CreateCertificate.ps1` and `2-CompileAndSign.ps1`:
```powershell
$pfxPassword = "YourCustomPassword"
```

### Custom Installation Location

Edit `3-Deploy.ps1`:
```powershell
$targetDir = "C:\Program Files\YourFolder"
```

**Warning:** UIAccess only works from trusted locations (Program Files, Windows\System32)

### Silent/Automated Builds

For CI/CD or automation, scripts can be run without prompts:
```powershell
# Suppress prompts by piping input
echo Y | .\3-Deploy.ps1
```

---

## 📚 Technical Details

### Manifest Configuration

The `MouseUtilities.manifest` file includes:
```xml
<requestedExecutionLevel level="asInvoker" uiAccess="true" />
```

This tells Windows:
- Run as normal user (asInvoker = same privilege as the user who launched it)
- Enable UIAccess features (allows interaction with elevated windows)
- **No UAC prompt required!**

### Certificate Specifications

- **Type:** Code Signing Certificate
- **Algorithm:** RSA 2048-bit with SHA256
- **Validity:** 5 years
- **Usage:** Digital Signature, Code Signing
- **Stores:** Trusted Root + Trusted Publishers (LocalMachine)

### Build Pipeline

1. **Compile:** AutoHotkey v2 compiler (Ahk2Exe.exe)
2. **Manifest Embed:** Windows SDK (mt.exe) or Resource Hacker
3. **Sign:** PowerShell Set-AuthenticodeSignature
4. **Timestamp:** DigiCert timestamp server (for verification)

---

## 🆘 Getting Help

If you encounter issues:

1. **Run BUILD-ALL.ps1 again** - It includes verification checks
2. **Check the output** - Scripts provide detailed error messages
3. **Verify prerequisites** - AutoHotkey v2 installed?
4. **Check Event Viewer** - Windows Logs → Application
5. **Review this README** - Most issues are covered above

---

## 📝 Quick Reference Card

```
┌─────────────────────────────────────────────────────┐
│ QUICK COMMANDS                                      │
├─────────────────────────────────────────────────────┤
│                                                     │
│ First Time:                                         │
│   .\BUILD-ALL.ps1                                   │
│                                                     │
│ After Code Changes:                                 │
│   .\2-CompileAndSign.ps1                            │
│   .\3-Deploy.ps1                                    │
│                                                     │
│ Launch App:                                         │
│   C:\Program Files\MouseUtilities\MouseUtilities.exe│
│                                                     │
│ Verify Signature:                                   │
│   Get-AuthenticodeSignature <path-to-exe>          │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## 📄 License

This build system uses standard Windows and AutoHotkey tools. The MouseUtilities project license applies to all generated executables.

---

**Last Updated:** 2024  
**Compatible With:** Windows 10/11, AutoHotkey v2.0+

**Questions?** Review the troubleshooting section or check the individual script files for detailed comments.