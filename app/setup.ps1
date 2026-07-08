Write-Host "=== NS200 Dash App Setup ===" -ForegroundColor Cyan
Write-Host ""

# Check for Flutter
if (!(Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "Flutter not found. Installing..." -ForegroundColor Yellow
    $url = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.27.4-stable.zip"
    $zipPath = "$env:TEMP\flutter.zip"
    $extractPath = "$env:USERPROFILE\flutter"

    Write-Host "Downloading Flutter SDK..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing

    Write-Host "Extracting..." -ForegroundColor Yellow
    Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

    Write-Host "Adding Flutter to PATH..." -ForegroundColor Yellow
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $flutterBin = "$extractPath\bin"
    if ($userPath -notlike "*$flutterBin*") {
        [Environment]::SetEnvironmentVariable("Path", "$userPath;$flutterBin", "User")
    }

    Write-Host "Flutter installed!" -ForegroundColor Green
}

# Initialize project
Write-Host "Initializing Flutter project..." -ForegroundColor Yellow
flutter create --project-name ns200_app --org com.ns200 --platforms android,ios "$env:TEMP\ns200_temp"
if ($?) {
    Copy-Item "$env:TEMP\ns200_temp\android\*" "android\" -Recurse -Force
    Copy-Item "$env:TEMP\ns200_temp\ios\*" "ios\" -Recurse -Force
    Remove-Item "$env:TEMP\ns200_temp" -Recurse -Force
    Write-Host "Platform files generated!" -ForegroundColor Green
}

# Get dependencies
Write-Host "Installing dependencies..." -ForegroundColor Yellow
flutter pub get

Write-Host ""
Write-Host "=== Setup Complete ===" -ForegroundColor Green
Write-Host "Run 'flutter run' to build and deploy to your phone." -ForegroundColor Cyan
