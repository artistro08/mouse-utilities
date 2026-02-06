# ============================================================================
# 3-Deploy.ps1
# Deploys the signed executable to Program Files (trusted location)
# ============================================================================

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  MouseUtilities - Deploy to Program Files" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    Read-Host -Prompt "Press Enter to exit"
    exit 1
}

# Paths
$scriptRoot = $PSScriptRoot
$projectRoot = Split-Path $scriptRoot -Parent
$sourceExe = Join-Path $scriptRoot "MouseUtilities.exe"
$sourceIni = Join-Path $projectRoot "settings.ini"
$sourceIco = Join-Path $projectRoot "MouseUtilities.ico"
$targetDir = "C:\Program Files\MouseUtilities"
$targetExe = Join-Path $targetDir "MouseUtilities.exe"
$userConfigDir = Join-Path $env:USERPROFILE ".config\mouse-utilities"
$targetIni = Join-Path $userConfigDir "settings.ini"
$targetIco = Join-Path $targetDir "MouseUtilities.ico"

# Check if source executable exists
if (-not (Test-Path $sourceExe))
{
    Write-Host "ERROR: Signed executable not found!" -ForegroundColor Red
    Write-Host "Expected: $sourceExe" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please run '2-CompileAndSign.ps1' first!" -ForegroundColor Yellow
    Read-Host -Prompt "Press Enter to exit"
    exit 1
}

# Verify the executable is signed
Write-Host "Verifying executable signature..." -ForegroundColor Yellow
$signature = Get-AuthenticodeSignature -FilePath $sourceExe

if ($signature.Status -eq "NotSigned")
{
    Write-Host "ERROR: Executable is not signed!" -ForegroundColor Red
    Write-Host "Please run '2-CompileAndSign.ps1' first!" -ForegroundColor Yellow
    Read-Host -Prompt "Press Enter to exit"
    exit 1
}

Write-Host "✓ Signature verified: $($signature.SignerCertificate.Subject)" -ForegroundColor Green
Write-Host ""

# Check if target directory exists, create if not
if (-not (Test-Path $targetDir))
{
    Write-Host "Creating target directory..." -ForegroundColor Yellow
    Write-Host "  $targetDir" -ForegroundColor Gray
    try
    {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        Write-Host "✓ Directory created!" -ForegroundColor Green
        Write-Host ""
    } catch
    {
        Write-Host "ERROR: Failed to create directory!" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Read-Host -Prompt "Press Enter to exit"
        exit 1
    }
}

# Stop any running instances
Write-Host "Checking for running instances..." -ForegroundColor Yellow
$runningProcesses = Get-Process -Name "MouseUtilities" -ErrorAction SilentlyContinue

if ($runningProcesses)
{
    Write-Host "Found $($runningProcesses.Count) running instance(s). Stopping..." -ForegroundColor Yellow
    try
    {
        $runningProcesses | Stop-Process -Force
        Start-Sleep -Seconds 2
        Write-Host "✓ Processes stopped!" -ForegroundColor Green
        Write-Host ""
    } catch
    {
        Write-Host "WARNING: Could not stop some processes!" -ForegroundColor Yellow
        Write-Host "You may need to stop them manually." -ForegroundColor Yellow
        Write-Host ""
    }
}

# Copy files
Write-Host "Deploying files to Program Files..." -ForegroundColor Yellow
Write-Host ""

try
{
    # Copy executable
    Write-Host "  Copying MouseUtilities.exe..." -ForegroundColor Gray
    Copy-Item -Path $sourceExe -Destination $targetExe -Force
    Write-Host "  ✓ Executable deployed" -ForegroundColor Green

    # Copy settings.ini to user config directory
    if (Test-Path $sourceIni)
    {
        # Create user config directory if it doesn't exist
        if (-not (Test-Path $userConfigDir))
        {
            New-Item -ItemType Directory -Path $userConfigDir -Force | Out-Null
            Write-Host "  Created config directory: $userConfigDir" -ForegroundColor Gray
        }
        Write-Host "  Copying settings.ini to user config..." -ForegroundColor Gray
        Copy-Item -Path $sourceIni -Destination $targetIni -Force
        Write-Host "  ✓ Settings deployed to: $targetIni" -ForegroundColor Green
    }

    # Copy icon
    if (Test-Path $sourceIco)
    {
        Write-Host "  Copying MouseUtilities.ico..." -ForegroundColor Gray
        Copy-Item -Path $sourceIco -Destination $targetIco -Force
        Write-Host "  ✓ Icon deployed" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "✓ All files deployed successfully!" -ForegroundColor Green
    Write-Host ""
} catch
{
    Write-Host "ERROR: Failed to copy files!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Read-Host -Prompt "Press Enter to exit"
    exit 1
}

# Create startup shortcut (optional)
Write-Host "Would you like to create a startup shortcut? (Y/N)" -ForegroundColor Yellow
$createStartup = Read-Host

if ($createStartup -eq "Y" -or $createStartup -eq "y")
{
    $startupFolder = [Environment]::GetFolderPath("Startup")
    $shortcutPath = Join-Path $startupFolder "MouseUtilities.lnk"

    try
    {
        $WshShell = New-Object -ComObject WScript.Shell
        $shortcut = $WshShell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $targetExe
        $shortcut.WorkingDirectory = $targetDir
        $shortcut.Description = "MouseUtilities - Unified Mouse and Keyboard Utilities"
        if (Test-Path $targetIco)
        {
            $shortcut.IconLocation = $targetIco
        }
        $shortcut.Save()

        Write-Host "✓ Startup shortcut created!" -ForegroundColor Green
        Write-Host "  Location: $shortcutPath" -ForegroundColor Gray
        Write-Host ""
    } catch
    {
        Write-Host "WARNING: Failed to create startup shortcut!" -ForegroundColor Yellow
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Write-Host ""
    }
}

# Create desktop shortcut (optional)
Write-Host "Would you like to create a desktop shortcut? (Y/N)" -ForegroundColor Yellow
$createDesktop = Read-Host

if ($createDesktop -eq "Y" -or $createDesktop -eq "y")
{
    $desktopFolder = [Environment]::GetFolderPath("Desktop")
    $shortcutPath = Join-Path $desktopFolder "MouseUtilities.lnk"

    try
    {
        $WshShell = New-Object -ComObject WScript.Shell
        $shortcut = $WshShell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $targetExe
        $shortcut.WorkingDirectory = $targetDir
        $shortcut.Description = "MouseUtilities - Unified Mouse and Keyboard Utilities"
        if (Test-Path $targetIco)
        {
            $shortcut.IconLocation = $targetIco
        }
        $shortcut.Save()

        Write-Host "✓ Desktop shortcut created!" -ForegroundColor Green
        Write-Host "  Location: $shortcutPath" -ForegroundColor Gray
        Write-Host ""
    } catch
    {
        Write-Host "WARNING: Failed to create desktop shortcut!" -ForegroundColor Yellow
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Write-Host ""
    }
}

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Deployed Location:" -ForegroundColor White
Write-Host "  $targetDir" -ForegroundColor Gray
Write-Host ""
Write-Host "Files Deployed:" -ForegroundColor White
Write-Host "  ✓ MouseUtilities.exe (signed with UIAccess)" -ForegroundColor Gray
if (Test-Path $targetIni)
{ Write-Host "  ✓ settings.ini ($targetIni)" -ForegroundColor Gray
}
if (Test-Path $targetIco)
{ Write-Host "  ✓ MouseUtilities.ico" -ForegroundColor Gray
}
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor White
Write-Host "  1. Launch: $targetExe" -ForegroundColor Cyan
Write-Host "  2. UIAccess should now be enabled!" -ForegroundColor Cyan
Write-Host ""
Write-Host "Testing UIAccess:" -ForegroundColor White
Write-Host "  - The app should now work with elevated windows" -ForegroundColor Gray
Write-Host "  - PowerToys integration should function properly" -ForegroundColor Gray
Write-Host "  - Check Event Viewer for any UIAccess errors" -ForegroundColor Gray
Write-Host ""

# Ask if user wants to launch now
Write-Host "Would you like to launch MouseUtilities now? (Y/N)" -ForegroundColor Yellow
$launchNow = Read-Host

if ($launchNow -eq "Y" -or $launchNow -eq "y")
{
    try
    {
        Start-Process -FilePath $targetExe -WorkingDirectory $targetDir
        Write-Host "✓ MouseUtilities launched!" -ForegroundColor Green
        Write-Host ""
    } catch
    {
        Write-Host "ERROR: Failed to launch!" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host ""
    }
}

Read-Host -Prompt "Press Enter to continue"
