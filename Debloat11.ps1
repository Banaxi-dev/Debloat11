
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "The Script must be run as Admin, Cannot Continue."
    pause
    exit
}


$allowedBuilds = @(
    "22621.3296",
    "22631.5189",
    "22631.5335",
    "26100.3476",
    "26100.4061",
    "26100.4188"
)

$build = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuild
$ubr = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").UBR
$currentBuild = "$build.$ubr"

Write-Host "Windows Build $currentBuild"

if (-not ($allowedBuilds -contains $currentBuild)) {
    Write-Warning "The Windows Build ($currentBuild) is not officially supported."
    Write-Host "`nOptions:"
    Write-Host "[1] Trotzdem alles ausführen"
    Write-Host "[2] ExplorerPatcher überspringen"
    Write-Host "[3] Abbrechen"
    $choice = Read-Host "Choose An Option (1-3)"

    switch ($choice) {
        "1" { $runAll = $true; $skipEP = $false }
        "2" { $runAll = $true; $skipEP = $true }
        "3" { Write-Host "Exiting"; pause; exit }
        default {
            Write-Warning ""
            pause
            exit
        }
    }
} else {
    $runAll = $true
    $skipEP = $false
}


$themePath = "C:\Windows\Resources\Themes\dark.theme"
if (Test-Path $themePath) {
    Write-Host "applying dark.theme"
    Start-Process $themePath
    Start-Sleep -Seconds 2
} else {
    Write-Warning "dark.theme not found $themePath"
}


if (-not $skipEP) {
    Write-Host "Installiere ExplorerPatcher..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $epInstaller = "$env:TEMP\ep_setup.exe"
    $epUrl = "https://github.com/valinet/ExplorerPatcher/releases/latest/download/ep_setup.exe"

    try {
        Invoke-WebRequest -Uri $epUrl -OutFile $epInstaller -ErrorAction Stop
        Start-Process -FilePath $epInstaller -ArgumentList "/silent" -Wait
    } catch {
        Write-Warning "Fehler bei der Installation von ExplorerPatcher: $_"
    }
} else {
    Write-Host "ExplorerPatcher Was Bypassed"
}


Write-Host "Removing Startmenu Bloat"

$appsToUnpin = @(
    "Microsoft.YourPhone",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.MSPaint",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo"
)

foreach ($app in $appsToUnpin) {
    $pkg = Get-AppxPackage -Name $app -AllUsers
    if ($pkg) {
        Write-Host "Entferne $app..."
        $pkg | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    } else {
        Write-Host "$app Is not installed"
    }
}




$chromeSetup = "$env:TEMP\ChromeSetup.exe"
Invoke-WebRequest -Uri "https://dl.google.com/chrome/install/latest/chrome_installer.exe" -OutFile $chromeSetup

Start-Process -FilePath $chromeSetup -ArgumentList "/silent /install" -Wait

Remove-Item $chromeSetup



# Explorer neu starten
Stop-Process -Name explorer -Force
Start-Sleep -Seconds 2
Start-Process explorer

Write-Host "Finished"
pause
