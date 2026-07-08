# NS200 Dash App - Setup Guide

## Prerequisites
- Windows PC with internet connection
- Android phone (USB debugging enabled)
- USB cable

## Quick Setup

1. **Install Flutter** (if not already installed):
   - Download from: https://docs.flutter.dev/get-started/install/windows
   - Or run `setup.ps1` in the `app/` folder

2. **Connect your phone**:
   - Enable Developer Options (Settings → About → Tap Build Number 7 times)
   - Enable USB Debugging (Developer Options)
   - Plug phone into PC via USB

3. **Build & Install**:
   ```powershell
   cd app
   flutter run
   ```

## Project Structure
```
ns200/
├── app/
│   ├── lib/
│   │   ├── main.dart                 # App entry point
│   │   ├── models/bike_data.dart     # Data models
│   │   ├── services/
│   │   │   ├── ble_service.dart      # BLE connection code
│   │   │   └── trip_service.dart     # Trip recording (SQLite)
│   │   ├── providers/
│   │   │   └── bike_provider.dart    # State management
│   │   ├── screens/
│   │   │   ├── dashboard_screen.dart # Main dashboard
│   │   │   ├── trip_screen.dart      # Trip history
│   │   │   └── settings_screen.dart  # BLE pairing
│   │   └── widgets/
│   │       ├── rpm_gauge.dart        # Animated tachometer
│   │       ├── speed_display.dart    # Speed readout
│   │       ├── gear_indicator.dart   # Gear position
│   │       └── fuel_info.dart        # Fuel economy
│   ├── pubspec.yaml
│   └── setup.ps1                    # Auto-setup script
└── protocol/
    └── protocol.md                  # BLE protocol notes
```

## BLE Protocol (for reference)

The bike (`pulsar2698`) exposes these services:

| Service UUID | Description |
|-------------|-------------|
| `0020676e-6972-6565-6e69-676e4543544f` | Engineering Control |
| `0010676e-6972-6565-6e69-676e4543544f` | Engineering Config |
| `f000ffd0-0451-4000-b000-000000000000` | TI Sensor (telemetry) |

The telemetry characteristic `f000ffd1-0451-4000-b000-000000000000` under the TI Sensor service is where live bike data is expected.
