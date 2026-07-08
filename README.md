# NS200 Dash

Custom dashboard app for **Bajaj Pulsar NS200** with Bluetooth LE telemetry.

## Features

- **Live Dashboard** — animated RPM gauge, speed, gear position, fuel economy
- **Trip Recording** — auto-saves data points, speed charts, distance, avg/max speed
- **BLE Debug Console** — read/write raw characteristics, hex data viewer
- **Premium Dark Theme** — black/red neon aesthetic matching the NS200

## Quick Start

```batch
setup.bat
```

This installs Flutter, generates platform files, and builds the APK.

Or manually:
```powershell
cd app
flutter pub get
flutter run
```

## BLE Protocol

| Service | UUID |
|---------|------|
| Engineering Control | `0020676e-6972-6565-6e69-676e4543544f` |
| Engineering Config | `0010676e-6972-6565-6e69-676e4543544f` |
| TI Sensor (telemetry) | `f000ffd0-0451-4000-b000-000000000000` |

Bike advertises as **pulsar2698**. Telemetry data encoding is still being reverse engineered.
