# GGreg20_V3 Tasmota ESP32 Driver - Optimized Edition

> **Note:** This driver is a fork of the [original driver repository](https://github.com/iotdevicesdev/ggreg20-v3-tasmota-esp32-driver) from the GGreg20_V3 manufacturer (IoT-devices, LLC). The manufacturer recommends using this optimized version (see the [related GitHub issue](https://github.com/iotdevicesdev/ggreg20-v3-tasmota-esp32-driver/issues/3)).

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Tasmota](https://img.shields.io/badge/Tasmota-12%2B-blue)](https://tasmota.github.io/)
[![Berry](https://img.shields.io/badge/Berry-Language-green)](https://berry-lang.github.io/)

Optimized Berry driver for the GGreg20_V3 Geiger Counter with Tasmota firmware on ESP32. This enhanced version provides improved performance, robustness, and seamless Home Assistant integration.

## 📋 Table of Contents

- [Features](#features)
- [What's New](#whats-new)
- [Hardware Requirements](#hardware-requirements)
- [Installation](#installation)
- [Configuration](#configuration)
- [Home Assistant Integration](#home-assistant-integration)
- [Usage](#usage)
- [API Reference](#api-reference)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [Credits](#credits)
- [License](#license)

## ✨ Features

- **Real-time radiation monitoring** with GGreg20_V3 Geiger Counter by IoT-devices, LLC
- **CPM (Counts Per Minute)** calculation with 1-minute and 5-minute averages
- **Dose rate** in µSv/h with calibrated conversion factor
- **Cumulative dose** tracking in µSv
- **Automatic min/max tracking** with persistent storage
- **Home Assistant ready** with MQTT telemetry and optimized initial values

## 📖 API Reference

- **Geiger Counter**: [GGreg20_V3](https://iot-devices.com.ua/en/product/ggreg20_v3-assembled-ionizing-radiation-detector-with-geiger-tube-sbm-20/) by IoT-devices, LLC
- **Microcontroller**: ESP32 (any variant supported by Tasmota)
- **Firmware**: Tasmota 12.0 or later with Berry support

### Wiring

Connect GGreg20_V3 to ESP32:
- **GGreg20_V3 OUT** → **ESP32 GPIO (configure as Counter1)**
- **GND** → **GND**

## 📥 Installation

### Step 1: Flash Tasmota

1. Flash your ESP32 with Tasmota firmware (12.0+)
2. Ensure Berry scripting is enabled in your build

### Step 2: Configure Counter

In Tasmota console:
```
Backlog CounterType 0; CounterDebounce 0; SaveData 0
```

### Step 3: Install Driver

**Recommended installation method:**

1. **Upload the driver file**
   - Navigate to **Consoles** → **Manage File system**
   - Upload `ggreg20_v3_driver_v2.be` (keep the original filename)

2. **Create or edit autoexec.be**
   - In the file system, create (or edit) `autoexec.be`
   - Add the following line:
   ```berry
   load("ggreg20_v3_driver_v2.be")
   ```

3. **Restart Tasmota**
   ```
   Restart 1
   ```

**Advantages of this method:**
- ✅ Clean separation of code
- ✅ Easy updates (just replace `ggreg20_v3_driver_v2.be`)
- ✅ `autoexec.be` remains minimal and readable
- ✅ Can load multiple modules independently

### Step 4: Verify Installation

In Tasmota console:
```
Status 10
```

You should see GGreg20_V3 sensors listed.

## ⚙️ Configuration

### Basic Configuration

The driver works out-of-the-box with default settings. No configuration required!

### Calibration Factor

The conversion factor depends on your Geiger tube type and the type of measurement needed.

**For detailed calibration information and technical background**, please refer to the official guide:
[Geiger tube J305 conversion factor: differences between the coefficient for source radiation power and absorbed dose](https://iot-devices.com.ua/en/geiger-tube-j305-conversion-factor-the-differences-between-the-coefficient-for-source-radiation-power-and-absorbed-dose/)

**Default value:** 0.00812 (suitable for most SBM-20 and J305 tubes)

**To adjust the calibration factor:**
1. Edit the driver file (`ggreg20_v3_driver_v2.be`)
2. Modify line: `static var GGpowerfactor = 0.00812`
3. Save and restart Tasmota

**Important notes:**
- Geiger tubes have manufacturing tolerances (typically ±20%)
- The conversion factor depends on radiation type and energy
- For accurate measurements, calibrate against a certified reference source
- Different tubes (SBM-20 vs J305) may require different factors
- Consult the IoT-devices technical documentation for your specific tube model

### Telemetry Period

**IMPORTANT:** Tasmota's default TelePeriod is 300 seconds (5 minutes). For proper operation of this driver, you must change it to 60 seconds:

```
TelePeriod 60
```

This ensures MQTT data is published every minute, synchronizing with the driver's 1-minute measurement cycle.

### Min/Max Reset

To reset recorded minimum/maximum values, you have two options:

**Option 1: Reset to a specific value (recommended)**
```
Backlog Mem1 25; Mem2 25
```
Set to 25 CPM or any other natural average value of measured CPM in your area.
Values take effect immediately on next reading (within 60 seconds).

**Option 2: Complete reset (requires restart)**
```
Backlog Mem1 0; Mem2 0; Restart 1
```
Setting both to 0 triggers automatic reinitialization to 25 CPM on restart.

## 📊 Usage

### Web Interface

Navigate to your Tasmota device IP. The main page shows:

```
GGreg20_V3 timer:    45 seconds
GGreg20_V3 cpt:      12 CpT
GGreg20_V3 powert:   0.097 µSv/h
GGreg20_V3 cpm1m:    12 CpM
GGreg20_V3 power1m:  0.097 µSv/h
GGreg20_V3 cpm5m:    11.4 CpM
GGreg20_V3 power5m:  0.093 µSv/h
GGreg20_V3 dose:     0.0032 µSv
GGreg20_V3 cpmin:    10.2 CpM
GGreg20_V3 cpmax:    15.8 CpM
```

### MQTT Telemetry

Published every TelePeriod (default 60s):

```json
{
  "Time": "2025-03-01T15:30:00",
  "COUNTER": {
    "C1": 1523
  },
  "GGreg20_V3": {
    "sec": 45,
    "cpt": 12,
    "powert": 0.097,
    "cpm1m": 12,
    "power1m": 0.097,
    "cpm5m": 11.4,
    "power5m": 0.093,
    "dose": 0.0032,
    "cpmin": 10.2,
    "cpmax": 15.8
  }
}
```

### Tasmota Rules

**Note:** The following rules are examples and suggestions. They are not mandatory for the driver to function.

#### GMC.MAP Integration

Upload data to [GMC.MAP](https://www.gmcmap.com/) every 15 minutes:

```
Rule1
ON tele-GGreg20_V3#cpm5m DO VAR1 %value% ENDON
ON tele-GGreg20_V3#power5m DO VAR2 %value% ENDON
ON tele-GGreg20_V3#cpm1m DO VAR4 %value% ENDON
ON tele-GGreg20_V3#power1m DO VAR5 %value% ENDON
ON Time#Minute|15 DO WEBQUERY http://www.GMCmap.com/log2.asp?AID=XXXXX&GID=XXXXXXXXXXX&CPM=%VAR4%&ACPM=%VAR1%&uSV=%VAR5% GET ENDON

Rule1 4
Rule1 1
```

Replace `XXXXX` with your GMC.MAP Account ID and `XXXXXXXXXXX` with your Geiger ID.

#### High Radiation Alert

Send MQTT alert if CPM exceeds threshold:

```
Rule2
ON tele-GGreg20_V3#cpm5m>100 DO Publish stat/alert/radiation HIGH_%value%_CPM ENDON

Rule2 1
```

#### Daily Min/Max Reset

Reset tracking every day at midnight:

```
Rule3
ON Time#Minute=0 DO IF (Time#Hour==0) Backlog Mem1 25; Mem2 25 ENDIF ENDON

Rule3 1
```

## 📖 API Reference

### Sensor Values

| Field | Description | Unit | Update Frequency |
|-------|-------------|------|------------------|
| `sec` | Seconds since last minute | seconds | 1s |
| `cpt` | Counts in current period | counts | 1s |
| `powert` | Current dose rate | µSv/h | 1s |
| `cpm1m` | 1-minute average CPM | CPM | 60s |
| `power1m` | 1-minute average dose rate | µSv/h | 60s |
| `cpm5m` | 5-minute average CPM | CPM | 60s |
| `power5m` | 5-minute average dose rate | µSv/h | 60s |
| `dose` | Cumulative dose since boot | µSv | 60s |
| `cpmin` | Minimum CPM observed | CPM | 60s |
| `cpmax` | Maximum CPM observed | CPM | 60s |

### Memory Locations

| Memory | Purpose | Default | Access |
|--------|---------|---------|--------|
| Mem1 | Minimum CPM (persistent) | 25 | `Mem1` |
| Mem2 | Maximum CPM (persistent) | 25 | `Mem2` |

### Console Commands

```console
# View current memory values
Mem1              # Show minimum CPM
Mem2              # Show maximum CPM

# Reset min/max tracking
Backlog Mem1 0; Mem2 0; Restart 1

# View sensor status
Status 10

# Set telemetry period (seconds)
TelePeriod 60

# View counter configuration
Counter1          # Show current count
CounterType       # Show counter type (should be 0)
CounterDebounce   # Show debounce time (recommended: 100)
```

## 🔍 Troubleshooting

### No sensor data showing

**Check counter configuration:**
```
Backlog CounterType 0; CounterDebounce 0
```

**Verify wiring:**
- GGreg20_V3 OUT connected to configured GPIO
- Power and ground connected

**Check driver loaded:**
```
br
```
Should show Berry console. Type:
```berry
import string
print(string.find(tasmota.read_sensors(), "GGreg20"))
```
Should return a number (not `nil`).

### CPM values seem incorrect

**Check calibration factor:**
- Default: 0.00812 (SBM-20)
- Verify tube type matches
- Consider ±20% manufacturing tolerance

**Allow time for stabilization:**
- 5-minute average needs 5 minutes to stabilize
- Background radiation varies naturally

### Min/Max not updating

**Verify memory writes enabled:**
```
SaveData
```
Should return a value > 0.

**Check memory values:**
```
Mem1
Mem2
```

**Reset if needed:**
```
Backlog Mem1 0; Mem2 0; Restart 1
```

### JSON parsing errors

**Console shows errors:**
```
GGreg20 JSON error: ...
```

**Possible causes:**
- Old Tasmota version (need 12.0+)
- Counter not configured
- C1 counter name conflict

**Solution:**
- Update Tasmota firmware
- Verify counter setup
- Check `Status 10` for counter presence

## 📝 Version History

### Version 7
- Native JSON parsing using `json.load()` instead of manual string parsing
- Performance improvement: Reduced from ~8-10 sensor reads per second to just 1
- Encapsulated variables: All state now properly contained in class instance
- Array-based buffer: Uses proper array `[]` instead of map `{}` for 5-minute data
- Validity counter: Ensures correct average calculation during first 5 minutes
- Enhanced error handling: Graceful degradation if counter reading fails
- Automatic min/max tracking: Records observed extrema with persistent storage
- Home Assistant friendly: Initializes with realistic values (25 CPM) instead of zeros

### Version 6
- Added CPMin and CPMax monitoring
- Non-null initial values for MQTT/Home Assistant compatibility

### Version 5
- Set not null initial values to avoid bad data sending to MQTT (Home Assistant receives too quick!)

### Version 4
- Calibration factor upgraded to 0.00812

### Version 3
- Memory and code optimized
- 5 minutes CPM precision set to 1 digit after the decimal point
- Cosmetic change: from "uSv" to "µSv"

### Version 2
- Full rewrite of the driver to clean and beautify code
- Include CPM 5 minutes average
- Include Power and CPM 1 minute averages

### Version 1
- Fix: if the native temperature sensor of the ESP32 is not shown (SetOption146 0), then the driver would fail to run
- Fix: as explained by distrubi, "the calculated dose was waaaay too low", conversion factor fix integrated
- New: since CPM count is reset every 60 seconds, added a time counter

## 👏 Credits

### Hardware & Support
- **IoT-devices, LLC** - GGreg20_V3 manufacturer
  - Special thanks for excellent product, documentation and customer support

### Community Contributions
- **distrubi** - Conversion factor correction (GitHub user)
- **Tasmota community** - Berry language support and framework

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Resources

### Hardware
- [GGreg20_V3 Product Page](https://www.tindie.com/products/iotdev/ggreg20_v3-ionizing-radiation-detector/)
- [GGreg20_V3 Documentation](https://iot-devices.com.ua/en/product/ggreg20_v3-ionizing-radiation-detector-with-geiger-tube-sbm-20/)
- [Conversion Factor Calculation](https://iot-devices.com.ua/en/technical-note-how-to-calculate-the-conversion-factor-for-geiger-tube-sbm20/)

### Software
- [Tasmota Firmware](https://tasmota.github.io/)
- [Berry Language Documentation](https://berry-lang.github.io/)
- [Tasmota Berry Scripting](https://tasmota.github.io/docs/Berry/)

### Community
- [Original Driver Repository](https://github.com/iotdevicesdev/ggreg20-v3-tasmota-esp32-driver)

### Radiation Safety
- [EPA Radiation Information](https://www.epa.gov/radiation)
- [Background Radiation Levels](https://en.wikipedia.org/wiki/Background_radiation)
- [Radiation Units Explained](https://www.nrc.gov/reading-rm/basic-ref/glossary/radiation-dose.html)

---

**⚠️ Safety Note**: This device is for monitoring purposes only. It is NOT a replacement for professional radiation safety equipment. Always follow proper safety protocols when dealing with radiation sources.

**📊 Typical Background Radiation**: 10-30 CPM (0.08-0.24 µSv/h) is normal background radiation. Higher levels may indicate radioactive materials nearby.

**🏥 Reference Dose Rates**:
- Natural background: 0.05-0.30 µSv/h
- Airplane flight: ~3 µSv/h
- Chest X-ray: ~20 µSv (one-time)
- Annual limit for public: 1,000 µSv/year
