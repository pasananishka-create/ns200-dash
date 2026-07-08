# NS200 BLE Reverse Engineering Guide

## Overview
We need to capture the raw BLE data packets between the Bajaj Ride Connect app and your bike to decode how RPM, speed, gear, fuel, etc. are encoded into bytes.

## Prerequisites
- **Phone A** (second phone with nRF Connect installed)
- **Phone B** (your main phone with Bajaj Ride Connect)
- **USB cable** for Phone B
- **PC** with ADB (Android Debug Bridge)

---

## Step 1: Install ADB (if not already installed)

Download **Platform Tools** from Google:
1. Go to https://developer.android.com/studio/releases/platform-tools
2. Download **platform-tools-latest-windows.zip**
3. Extract to `C:\platform-tools`
4. Add `C:\platform-tools` to your PATH:
   - Open **Settings** → **System** → **About** → **Advanced system settings**
   - Click **Environment Variables**
   - Under **User variables**, select `Path` → **Edit** → **New**
   - Add `C:\platform-tools` → **OK**

Verify it works:
```powershell
adb --version
```

## Step 2: Enable Developer Options on Phone B

1. Open **Settings** → **About Phone**
2. Tap **Build Number** 7 times (you'll see "You are now a developer!")
3. Go back → **System** → **Developer Options**

**Enable USB Debugging:**
- Find **USB Debugging** → toggle **ON**

**Enable Bluetooth HCI Snoop Log:**
- Find **Bluetooth HCI Snoop Log** → tap it
- Choose **"Enabled (Full)"** if available, otherwise just enable it

## Step 3: Capture BLE Traffic

1. **Plug Phone B into your PC** via USB
2. On Phone B, USB notification appears → tap it → choose **File Transfer** mode
3. On PC, verify the phone is detected:
   ```powershell
   adb devices
   ```
   You should see something like `abcdef123456 device`

4. **Turn ON your bike ignition** (console lights up)

5. On Phone B, open **Bajaj Ride Connect**, connect to your bike

6. On **Phone A** (second phone), open **nRF Connect**:
   - Tap SCAN
   - Find `pulsar2698` in the list
   - **DO NOT CONNECT** — Phone A is just watching
   - Note the dBm signal strength and device is visible

7. **Go for a 2-3 minute ride** on Phone B (with Bajaj Ride Connect running in background)

8. After the ride, stop recording, and **turn off Bluetooth HCI Snoop** in Developer Options (this saves/flushes the log file)

## Step 4: Pull the Log File

Run this on your PC:
```powershell
adb pull /sdcard/btsnoop_hci.log C:\Users\pasan anishka\Desktop\ns200\protocol\btsnoop_hci.log
```

If that doesn't work, try:
```powershell
adb pull /data/misc/bluetooth/logs/btsnoop_hci.log C:\Users\pasan anishka\Desktop\ns200\protocol\btsnoop_hci.log
```

If you get "permission denied" on the second path, run:
```powershell
adb shell
su 0 cat /data/misc/bluetooth/logs/btsnoop_hci.log > /sdcard/btsnoop_hci.log
exit
adb pull /sdcard/btsnoop_hci.log C:\Users\pasan anishka\Desktop\ns200\protocol\btsnoop_hci.log
```

## Step 5: While Waiting for the Ride — Get More Info from nRF Connect

While Phone A sees `pulsar2698`, try these **without connecting** to the bike:

1. Tap `pulsar2698` in nRF Connect → **CONNECT**
2. Expand **all 3 custom services**
3. For the **`f000ffd1-...`** characteristic (under TI Sensor service):
   - Tap it → tap the **up arrow** (write)
   - Try writing: `01` (hex), then `00` (hex) — see if anything changes
4. Look at the **READ** characteristics:
   - Tap **READ** on `1120676e-...` (under Engineering Control service)
     - What hex data comes back?
   - Tap **READ** on `0a10676e-...` (under Engineering Config service)
     - What hex data comes back?
5. Try tapping **READ** on `f000ffd1-...` (under TI Sensor)
   - What hex data comes back?

Send me the hex values you get from each READ. This is the raw bike data we need to decode.

## Step 6: Send Me the Files for Analysis

Once you have:
1. The `btsnoop_hci.log` file
2. The nRF Connect READ results (hex values)
3. Any observations about what was happening on the dashboard when you read them

Place them in `C:\Users\pasan anishka\Desktop\ns200\protocol\` and I'll analyze everything to figure out the byte encoding.

## What I'll Do With the Data
1. Filter the BLE packets by your bike's MAC (`34:c4:59:ab:0a:26`)
2. Identify all ATT Write/Read/Notify packets
3. Correlate byte values with known bike states (e.g., when RPM = 3000, what bytes were sent)
4. Map the encoding pattern for each metric
5. Update `ble_service.dart` with the correct parser

## Expected Data Format (Hypothesis)
Based on the TI Sensor profile, data is likely encoded as:
```
Byte 0-1: RPM (uint16)
Byte 2:   Speed (uint8, km/h)
Byte 3:   Gear (0=N, 1-6)
Byte 4-5: Fuel (uint16, 0-1023 for level)
...
```

We'll confirm or correct this once we have the captures.
