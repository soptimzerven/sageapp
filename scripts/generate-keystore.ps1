<#
.SYNOPSIS
    Generates an Android signing keystore for Google Play Store deployment.

.DESCRIPTION
    This script generates a JKS (Java KeyStore) file for signing Android apps.
    It prompts for ALL required information and does NOT read any system data.
    
    PRIVACY GUARANTEE:
    - Does NOT read system username, computer name, or any local data
    - Does NOT access network or IP information
    - Does NOT auto-fill any fields
    - ALL information is provided by the user manually
    - Keystore is generated locally and never transmitted

.NOTES
    Requirements: Java JDK must be installed (keytool command)
    Output: Keystore file + Base64 encoded version for GitHub Secrets
#>

# ============================================
# PRIVACY NOTICE
# ============================================
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  ANDROID KEYSTORE GENERATOR" -ForegroundColor Cyan
Write-Host "  Secure and Privacy-Respecting" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "PRIVACY GUARANTEE:" -ForegroundColor Green
Write-Host "  - This script does NOT read any system information"
Write-Host "  - This script does NOT access your username, IP, or location"
Write-Host "  - This script does NOT auto-fill any fields"
Write-Host "  - ALL data is entered manually by you"
Write-Host ""
Write-Host "You will be prompted for 7+ company/organization details."
Write-Host "Press Enter to continue or Ctrl+C to cancel..."
Read-Host | Out-Null

# ============================================
# CHECK JAVA/KEYTOOL
# ============================================
Write-Host ""
Write-Host "[1/9] Checking for Java keytool..." -ForegroundColor Yellow

$keytoolExists = $null
try {
    $keytoolExists = Get-Command keytool -ErrorAction SilentlyContinue
} catch {
    $keytoolExists = $null
}

if ($null -eq $keytoolExists) {
    Write-Host "  X ERROR: Java keytool not found!" -ForegroundColor Red
    Write-Host "  Please install Java JDK and ensure keytool is in your PATH."
    Write-Host "  Download from: https://adoptium.net/"
    exit 1
} else {
    Write-Host "  OK keytool found" -ForegroundColor Green
}

# ============================================
# COLLECT USER INPUT (ALL MANUAL - NO AUTO-FILL)
# ============================================
Write-Host ""
Write-Host "[2/9] Enter Organization/Company Details" -ForegroundColor Yellow
Write-Host "        (All fields are required)" -ForegroundColor Gray
Write-Host ""

# 1. Organization Name
$orgName = ""
while ([string]::IsNullOrWhiteSpace($orgName)) {
    Write-Host "  1. Organization/Company Name"
    Write-Host "     Example: My Company LLC" -ForegroundColor Gray
    $orgName = Read-Host "     Enter value"
    if ([string]::IsNullOrWhiteSpace($orgName)) {
        Write-Host "     X Organization name is required" -ForegroundColor Red
    }
}

# 2. Organizational Unit
$orgUnit = ""
while ([string]::IsNullOrWhiteSpace($orgUnit)) {
    Write-Host ""
    Write-Host "  2. Organizational Unit"
    Write-Host "     Example: Mobile Development" -ForegroundColor Gray
    $orgUnit = Read-Host "     Enter value"
    if ([string]::IsNullOrWhiteSpace($orgUnit)) {
        Write-Host "     X Organizational unit is required" -ForegroundColor Red
    }
}

# 3. City/Locality
$city = ""
while ([string]::IsNullOrWhiteSpace($city)) {
    Write-Host ""
    Write-Host "  3. City/Locality"
    Write-Host "     Example: San Francisco" -ForegroundColor Gray
    $city = Read-Host "     Enter value"
    if ([string]::IsNullOrWhiteSpace($city)) {
        Write-Host "     X City is required" -ForegroundColor Red
    }
}

# 4. State/Province
$state = ""
while ([string]::IsNullOrWhiteSpace($state)) {
    Write-Host ""
    Write-Host "  4. State/Province"
    Write-Host "     Example: California or CA" -ForegroundColor Gray
    $state = Read-Host "     Enter value"
    if ([string]::IsNullOrWhiteSpace($state)) {
        Write-Host "     X State/Province is required" -ForegroundColor Red
    }
}

# 5. Country Code (2 letters)
$country = ""
while ([string]::IsNullOrWhiteSpace($country)) {
    Write-Host ""
    Write-Host "  5. Country Code (exactly 2 letters)"
    Write-Host "     Example: US, UK, PH, CA" -ForegroundColor Gray
    $country = Read-Host "     Enter value"
    if ([string]::IsNullOrWhiteSpace($country) -or $country.Length -ne 2) {
        Write-Host "     X Country code must be exactly 2 letters" -ForegroundColor Red
        $country = ""
    }
}
$country = $country.ToUpper()

# 6. Contact Name (for certificate)
$contactName = ""
while ([string]::IsNullOrWhiteSpace($contactName)) {
    Write-Host ""
    Write-Host "  6. Contact Name for Certificate"
    Write-Host "     Example: John Smith" -ForegroundColor Gray
    $contactName = Read-Host "     Enter value"
    if ([string]::IsNullOrWhiteSpace($contactName)) {
        Write-Host "     X Contact name is required" -ForegroundColor Red
    }
}

# 7. Contact Email
$contactEmail = ""
while ([string]::IsNullOrWhiteSpace($contactEmail)) {
    Write-Host ""
    Write-Host "  7. Contact Email"
    Write-Host "     Example: dev@company.com" -ForegroundColor Gray
    $contactEmail = Read-Host "     Enter value"
    if ([string]::IsNullOrWhiteSpace($contactEmail)) {
        Write-Host "     X Valid email is required" -ForegroundColor Red
    } elseif ($contactEmail -notmatch "@") {
        Write-Host "     X Email must contain @" -ForegroundColor Red
        $contactEmail = ""
    }
}

# ============================================
# KEYSTORE CONFIGURATION
# ============================================
Write-Host ""
Write-Host "[3/9] Keystore Configuration" -ForegroundColor Yellow
Write-Host ""

# Key Alias
$keyAlias = ""
while ([string]::IsNullOrWhiteSpace($keyAlias)) {
    Write-Host "  Key Alias (press Enter for default: upload)"
    $keyAlias = Read-Host "     Enter value"
    if ([string]::IsNullOrWhiteSpace($keyAlias)) {
        $keyAlias = "upload"
        Write-Host "     Using default: upload" -ForegroundColor Gray
    }
    # Validate alias (alphanumeric and underscore only)
    if ($keyAlias -notmatch "^[a-zA-Z0-9_]+$") {
        Write-Host "     X Alias must be alphanumeric (letters, numbers, underscore only)" -ForegroundColor Red
        $keyAlias = ""
    }
}

# Keystore filename
Write-Host ""
Write-Host "  Keystore filename (press Enter for default: upload-keystore.jks)"
$keystoreFile = Read-Host "     Enter value"
if ([string]::IsNullOrWhiteSpace($keystoreFile)) {
    $keystoreFile = "upload-keystore.jks"
    Write-Host "     Using default: upload-keystore.jks" -ForegroundColor Gray
}
if (-not $keystoreFile.EndsWith(".jks")) {
    $keystoreFile = "$keystoreFile.jks"
}

# ============================================
# PASSWORD INPUT (SECURE)
# ============================================
Write-Host ""
Write-Host "[4/9] Set Passwords (minimum 6 characters)" -ForegroundColor Yellow
Write-Host "        Passwords are hidden as you type" -ForegroundColor Gray
Write-Host ""

# Keystore Password
$keystorePassPlain = ""
while ($keystorePassPlain.Length -lt 6) {
    $keystorePass = Read-Host "  Keystore Password" -AsSecureString
    $keystorePassPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($keystorePass)
    )
    if ($keystorePassPlain.Length -lt 6) {
        Write-Host "     X Password must be at least 6 characters" -ForegroundColor Red
    }
}

# Key Password
Write-Host ""
$keyPassPlain = ""
while ($keyPassPlain.Length -lt 6) {
    $keyPass = Read-Host "  Key Password (can be same as keystore password)" -AsSecureString
    $keyPassPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($keyPass)
    )
    if ($keyPassPlain.Length -lt 6) {
        Write-Host "     X Password must be at least 6 characters" -ForegroundColor Red
    }
}

# ============================================
# CONFIRMATION
# ============================================
Write-Host ""
Write-Host "[5/9] Confirm Details" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Organization:    $orgName"
Write-Host "  Unit:            $orgUnit"
Write-Host "  City:            $city"
Write-Host "  State:           $state"
Write-Host "  Country:         $country"
Write-Host "  Contact:         $contactName"
Write-Host "  Email:           $contactEmail"
Write-Host "  Key Alias:       $keyAlias"
Write-Host "  Keystore File:   $keystoreFile"
Write-Host ""

$confirm = Read-Host "  Is this correct? (yes/no)"
if ($confirm -ne "yes" -and $confirm -ne "y") {
    Write-Host ""
    Write-Host "  Cancelled. Please run the script again." -ForegroundColor Yellow
    exit 0
}

# ============================================
# GENERATE KEYSTORE
# ============================================
Write-Host ""
Write-Host "[6/9] Generating Keystore..." -ForegroundColor Yellow

# Build the DN (Distinguished Name)
$dname = "CN=$contactName, OU=$orgUnit, O=$orgName, L=$city, ST=$state, C=$country"

# Output path (current directory)
$outputPath = Join-Path -Path (Get-Location) -ChildPath $keystoreFile

# Remove existing keystore if present
if (Test-Path $outputPath) {
    Remove-Item $outputPath -Force
}

# Generate keystore using keytool
$keytoolArgs = @(
    "-genkeypair",
    "-v",
    "-keystore", "`"$outputPath`"",
    "-storetype", "JKS",
    "-keyalg", "RSA",
    "-keysize", "2048",
    "-validity", "10000",
    "-alias", $keyAlias,
    "-storepass", $keystorePassPlain,
    "-keypass", $keyPassPlain,
    "-dname", "`"$dname`""
)

try {
    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = "keytool"
    $processInfo.Arguments = $keytoolArgs -join " "
    $processInfo.RedirectStandardOutput = $true
    $processInfo.RedirectStandardError = $true
    $processInfo.UseShellExecute = $false
    $processInfo.CreateNoWindow = $true
    
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $processInfo
    $process.Start() | Out-Null
    $process.WaitForExit()
    
    if ($process.ExitCode -eq 0 -and (Test-Path $outputPath)) {
        Write-Host "  OK Keystore generated successfully!" -ForegroundColor Green
    } else {
        $errorOutput = $process.StandardError.ReadToEnd()
        Write-Host "  X Failed to generate keystore" -ForegroundColor Red
        Write-Host "  Error: $errorOutput" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "  X Error: $_" -ForegroundColor Red
    exit 1
}

# ============================================
# ENCODE TO BASE64
# ============================================
Write-Host ""
Write-Host "[7/9] Encoding Keystore to Base64..." -ForegroundColor Yellow

$keystoreBytes = [System.IO.File]::ReadAllBytes($outputPath)
$keystoreBase64 = [System.Convert]::ToBase64String($keystoreBytes)
$base64File = $outputPath -replace "\.jks$", ".b64.txt"

# Save base64 to file
$keystoreBase64 | Out-File -FilePath $base64File -Encoding ASCII -NoNewline

Write-Host "  OK Base64 encoded and saved to: $base64File" -ForegroundColor Green

# ============================================
# OUTPUT GITHUB SECRETS INSTRUCTIONS
# ============================================
Write-Host ""
Write-Host "[8/9] GitHub Secrets Configuration" -ForegroundColor Yellow
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  ADD THESE SECRETS TO GITHUB" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Go to: GitHub Repository -> Settings -> Secrets and variables -> Actions"
Write-Host ""
Write-Host "Add the following secrets:" -ForegroundColor White
Write-Host ""
Write-Host "  Secret Name          Value"
Write-Host "  -------------------  ------------------------------------------"
Write-Host "  KEYSTORE_BASE64      Contents of: $base64File"
Write-Host "  KEYSTORE_PASSWORD    Your keystore password"
Write-Host "  KEY_ALIAS            $keyAlias"
Write-Host "  KEY_PASSWORD         Your key password"
Write-Host ""

# ============================================
# SECURITY REMINDERS
# ============================================
Write-Host "[9/9] Security Reminders" -ForegroundColor Yellow
Write-Host ""
Write-Host "IMPORTANT:" -ForegroundColor Red
Write-Host "  1. NEVER commit the .jks or .b64.txt files to Git!"
Write-Host "  2. Store the keystore password securely (you need it forever)"
Write-Host "  3. Back up the .jks file securely - if lost, you cannot update your app!"
Write-Host "  4. Delete the .b64.txt file after adding to GitHub Secrets"
Write-Host ""
Write-Host "Files Generated:" -ForegroundColor White
Write-Host "  Keystore: $outputPath"
Write-Host "  Base64:   $base64File"
Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  KEYSTORE GENERATION COMPLETE!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""

# Clear sensitive variables from memory
$keystorePassPlain = $null
$keyPassPlain = $null
[System.GC]::Collect()
