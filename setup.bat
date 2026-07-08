@echo off
title NS200 Dash - Auto Setup
color 0C
echo.
echo ============================================
echo    NS200 Dash - Automatic Setup
echo ============================================
echo.

:: Check if running as admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] Please run this as Administrator
    echo     Right-click -^> Run as Administrator
    pause
    exit /b 1
)

cd /d "%~dp0"

:: Step 1: Install Flutter SDK
echo [1/4] Installing Flutter SDK...
if not exist "C:\flutter\bin\flutter.bat" (
    echo     Downloading (this takes a few minutes)...
    powershell -Command "$url='https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.27.4-stable.zip'; $zip='%TEMP%\flutter.zip'; Write-Host '    Downloading Flutter...'; Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing; Write-Host '    Extracting...'; Expand-Archive -Path $zip -DestinationPath 'C:\flutter' -Force; Write-Host '    Done!'"
) else (
    echo     Flutter already installed
)

set PATH=C:\flutter\bin;%PATH%

:: Step 2: Generate proper Flutter project
echo [2/4] Generating Flutter project scaffold...
if not exist "app\android\gradlew.bat" (
    mkdir temp_project 2>nul
    cd temp_project
    call flutter create --project-name ns200_app --org com.ns200 --platforms android,ios . >nul 2>&1
    cd ..
    
    :: Copy generated platform files into our app directory
    xcopy /E /Y temp_project\android\* app\android\* >nul
    xcopy /E /Y temp_project\ios\* app\ios\* >nul
    copy /Y temp_project\.metadata app\.metadata >nul 2>&1
    
    :: Clean up temp
    rmdir /S /Q temp_project
    
    echo     Project scaffold generated!
) else (
    echo     Platform files already exist
)

:: Step 3: Install dependencies
echo [3/4] Installing Dart dependencies...
cd app
call flutter pub get
cd ..
echo     Dependencies installed!

:: Step 4: Build APK
echo [4/4] Building release APK...
cd app
call flutter build apk --release
cd ..
echo.
echo ============================================
echo    BUILD COMPLETE!
echo ============================================
echo.
echo APK location: app\build\app\outputs\flutter-apk\app-release.apk
echo.
echo Install on your phone:
echo   1. Copy the APK to your phone
echo   2. Open it and allow installation from unknown sources
echo.
pause
