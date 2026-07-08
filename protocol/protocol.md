# NS200 BLE Protocol

## Device Info
- **Name**: pulsar2698
- **MAC**: 34:C4:59:AB:0A:26

## GATT Services & Characteristics

### 1. Generic Access (0x1800)
- Device Name (0x2A00) - READ, WRITE
- Appearance (0x2A01) - READ, WRITE
- Peripheral Preferred Connection Parameters (0x2A04) - READ
- Central Address Resolution (0x2AA6) - READ
- Resolvable Private Address Only (0x2AC9) - READ

### 2. Device Information (0x180A)
Standard device info characteristics (System ID, Model, Serial, Firmware, etc.)

### 3. Engineering Control (0020676e-6972-6565-6e69-676e4543544f)
Note: UUID decodes to "Enegineering" in ASCII (Bajaj team signature)
- **1020676e-6972-6565-6e69-676e4543544f** - WRITE
- **1120676e-6972-6565-6e69-676e4543544f** - READ

### 4. Engineering Config (0010676e-6972-6565-6e69-676e4543544f)
- **0110676e-6972-6565-6e69-676e4543544f** - WRITE
- **0210676e-6972-6565-6e69-676e4543544f** - WRITE
- **0310676e-6972-6565-6e69-676e4543544f** - WRITE
- **0410676e-6972-6565-6e69-676e4543544f** - WRITE
- **0510676e-6972-6565-6e69-676e4543544f** - WRITE
- **0a10676e-6972-6565-6e69-676e4543544f** - READ

### 5. TI Sensor Profile (f000ffd0-0451-4000-b000-000000000000)
Texas Instruments custom profile for sensor data
- **f000ffd1-0451-4000-b000-000000000000** - WRITE, WRITE NO RESPONSE
  - Descriptor: Characteristic User Description (0x2901)
  - NOTE: No 0x2902 (Client Characteristic Config) found = no notification support
  - Data must be polled via READ

## Data Format (Unknown - To Be Reverse Engineered)
The byte encoding for RPM, speed, gear, fuel, etc. is still unknown.
Use nRF Connect to READ characteristics while bike is running to capture raw bytes.

## Reverse Engineering Steps (if you want to complete this)
1. Enable Bluetooth HCI Snoop Log on Android Developer Options
2. Connect Bajaj Ride Connect app and ride
3. Pull log: `adb pull /sdcard/btsnoop_hci.log`
4. Open in Wireshark, filter by MAC `34:c4:59:ab:0a:26`
5. Correlate hex values with dashboard readings
6. Update bleservice.dart _parseBikeData() with correct byte positions
