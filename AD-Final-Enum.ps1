# ==============================
# FINAL COMBINED FULL AUTO AD ENUMERATION + ULTIMATE TOOLKIT
# ==============================
# Combines both scripts into one clean, improved version
# No duplicate code, better organization, timestamps, and extra useful commands

Write-Host "Starting Full Auto AD Enumeration + Ultimate Toolkit..." -ForegroundColor Green

# Create output folder
$folder = "C:\Temp\AD_Full_Enum"
New-Item -ItemType Directory -Path $folder -Force | Out-Null

# Timestamp for files
$time = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

Write-Host "[*] Output folder created: $folder" -ForegroundColor Yellow

# =========================================
# STEP 1: IDENTITY & BASIC INFO
# =========================================
Write-Host "[*] Gathering Identity Information..." -ForegroundColor Cyan
whoami | Out-File "$folder\01_identity_$time.txt"
whoami /groups >> "$folder\01_identity_$time.txt"
whoami /priv >> "$folder\01_identity_$time.txt"
query user | Out-File "$folder\01_loggedin_users_$time.txt"

# =========================================
# STEP 2: DOMAIN & FOREST INFORMATION
# =========================================
Write-Host "[*] Gathering Domain & Forest Information..." -ForegroundColor Cyan
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

Get-ADDomain | Out-File "$folder\02_domain_$time.txt"
Get-ADForest >> "$folder\02_domain_$time.txt"
Get-ADTrust -Filter * | Out-File "$folder\02_trusts_$time.txt"
Get-ADDefaultDomainPasswordPolicy | Out-File "$folder\02_password_policy_$time.txt"
Get-ADDomainController -Filter * | Out-File "$folder\02_domain_controllers_$time.txt"

# =========================================
# STEP 3: USERS ENUMERATION
# =========================================
Write-Host "[*] Enumerating Users..." -ForegroundColor Cyan
Get-ADUser -Filter * -Properties * | 
    Select-Object Name, SamAccountName, Enabled, PasswordLastSet, LastLogonDate, PasswordNeverExpires, 
                  MemberOf, Description | 
    Out-File "$folder\03_users_$time.txt"

# =========================================
# STEP 4: GROUPS ENUMERATION
# =========================================
Write-Host "[*] Enumerating Groups..." -ForegroundColor Cyan
Get-ADGroup -Filter * | Select-Object Name, GroupScope, GroupCategory | 
    Out-File "$folder\04_groups_$time.txt"

Get-ADGroupMember "Domain Admins" -Recursive | 
    Out-File "$folder\04_domain_admins_$time.txt"

# =========================================
# STEP 5: COMPUTERS ENUMERATION
# =========================================
Write-Host "[*] Enumerating Computers..." -ForegroundColor Cyan
Get-ADComputer -Filter * -Properties * | 
    Select-Object Name, OperatingSystem, OperatingSystemVersion, Enabled, LastLogonDate | 
    Out-File "$folder\05_computers_$time.txt"

# =========================================
# STEP 6: SHARES & NETWORK SHARES
# =========================================
Write-Host "[*] Enumerating Shares..." -ForegroundColor Cyan
Get-SmbShare | Out-File "$folder\06_shares_$time.txt"

# =========================================
# STEP 7: NETWORK INFORMATION
# =========================================
Write-Host "[*] Gathering Network Information..." -ForegroundColor Cyan
ipconfig /all | Out-File "$folder\07_network_$time.txt"
arp -a >> "$folder\07_network_$time.txt"
netstat -ano >> "$folder\07_network_$time.txt"
route print >> "$folder\07_network_$time.txt"

# =========================================
# STEP 8: SERVICES & PROCESSES
# =========================================
Write-Host "[*] Enumerating Services..." -ForegroundColor Cyan
Get-Service | Select-Object Name, DisplayName, Status, StartType | 
    Out-File "$folder\08_services_$time.txt"

# =========================================
# STEP 9: POWER VIEW (if available)
# =========================================
Write-Host "[*] Checking for PowerView..." -ForegroundColor Cyan
if (Test-Path ".\PowerView.ps1") {
    Write-Host "[+] PowerView.ps1 found. Running advanced enumeration..." -ForegroundColor Green
    Import-Module .\PowerView.ps1 -ErrorAction SilentlyContinue
    Get-NetUser | Out-File "$folder\09_powerview_users_$time.txt"
    Get-NetGroup | Out-File "$folder\09_powerview_groups_$time.txt"
    Get-NetComputer | Out-File "$folder\09_powerview_computers_$time.txt"
    Get-NetShare | Out-File "$folder\09_powerview_shares_$time.txt"
} else {
    Write-Host "[-] PowerView.ps1 not found in current directory." -ForegroundColor Yellow
}

# =========================================
# STEP 10: BLOODHOUND COLLECTION (if SharpHound available)
# =========================================
Write-Host "[*] Checking for SharpHound..." -ForegroundColor Cyan
if (Test-Path ".\SharpHound.exe") {
    Write-Host "[+] SharpHound.exe found. Starting BloodHound collection..." -ForegroundColor Green
    try {
        .\SharpHound.exe -c All -d (Get-ADDomain).DNSRoot --ZipFileName "$folder\10_bloodhound_$time.zip"
        Write-Host "[+] BloodHound collection completed!" -ForegroundColor Green
    } catch {
        Write-Host "[-] Error running SharpHound: $_" -ForegroundColor Red
    }
} else {
    Write-Host "[-] SharpHound.exe not found in current directory." -ForegroundColor Yellow
}

# =========================================
# STEP 11: ATTACK PATH HINTS
# =========================================
Write-Host "[*] Generating Simple Attack Hints..." -ForegroundColor Cyan
$admins = Get-Content "$folder\04_domain_admins_$time.txt" -ErrorAction SilentlyContinue
if ($admins) {
    "High Value Targets Found: Domain Admins group has members!" | Out-File "$folder\11_attack_hints_$time.txt"
    "Recommendation: Focus on Domain Admins for privilege escalation paths." | Add-Content "$folder\11_attack_hints_$time.txt"
}

# =========================================
# DONE
# =========================================
Write-Host "`n" -NoNewline
Write-Host "========================================" -ForegroundColor Green
Write-Host "FULL AD ENUMERATION COMPLETED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "All results saved in: " -NoNewline
Write-Host "$folder" -ForegroundColor Yellow
Write-Host "Timestamp: $time" -ForegroundColor Gray
Write-Host "`nFiles created with prefix (01_, 02_, etc.) for easy sorting." -ForegroundColor Cyan