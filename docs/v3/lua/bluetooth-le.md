# Bluetooth LE

## Overview 

The OGS runtime uses the Windows Bluetooth stack to support BLE devices. Currently this is limited to scanning the environment and listen to advertisment frames (see [Bluetooth Low Energy](https://www.bluetooth.com/blog/bluetooth-low-energy-it-starts-with-advertising/)). It provides integrated decoding of the [BTHome v2 format](https://bthome.io/), but also provides raw access to the advertisment data and can therefore used with many devices: 

- [Shelly BLU Button](https://www.shelly.com/de/products/shelly-blu-button-tough-1-black): Small, battery powered single key button
- [Shelly BLU RC Button 4](https://www.shelly.com/de/products/shelly-blu-rc-button-4): Bluetooth LE remot control with four buttons
- Mobile phones or fitness watches for presence detection
- Bluetooth beacons, ...

The OGS bluetooth LE interface provides functions to start scanning (listening for advertisment frames) and stopping a scan. 

## Configuration

To enable BLE support, it must be enabled by setting `ENABLED=1` in `[BLE]` section of `station.ini`. here is a sample:

``` ini
; station.ini

; Bluetooth Low Energy parameters
[BLE]
; Enable bluetooth LE support by setting ENABLED=1
ENABLED=1
```

## LUA Interface

### Overview

If BLE support is enabled in `station.ini` (see [Configuration](#configuration)), then a global `ble` LUA object is provided.

The `ble` object provides the following members:


| Function Name | Return Type | Description | 
| -------- | ----------- | ----------- | ---- |
| `scan_start(callback: function, filter: int)` | - | Can be called to start listening for BLE advertisment frames. If no filter is given (nil), then defaults to `0xFCD2 (BTHome)`. To receive all frames, set to `-1`, else to the 16-bit short UUID of the service. The callback will be called for each frame received and when the scan is stopped. By default, a scan runs for 10 seconds (or until stopped by calling `scan_stop`). | 
| `scan_stop()` | - | Can be called to stop a currently running scan. If a scan times out, then calling `scan_stop` is not required. | 

The callback function provided in the `scan_start` parameter is called with a single table argument:

- The argument will be `nil`, if the scan stopped (timeout or stopped by calling `scan_stop`)
- The argument will have a table with device details and the advertisment data. 

The table with device details and the advertisment data is as follows:

``` lua
---@class BleBtHomeData
---@field flags integer BTHome flags 0x40 = cyclic bthome, 0x44 = trigger bthome
---@field seq integer Sequence number (to detect multiple frames, e. g. increments once per button press)
---@field battery integer Battery level (0-100)
---@field action integer Action code (0 = none, 1 = click, 2 = doubleclick, ...)
---@field button string decoded action ('press', 'double_press', ...)

---@class BleAdvertismentData
---@field id string Unique MAC address of the BLE device
---@field service integer 16-Bit service id (32/128-bit IDs are only provided in the response data)
---@field name string Local device name (if provided, else empty string)
---@field rssi integer The RSSI level
---@field response table<integer,string> The actual advertisment data as key/value (binary string) data
---@field bthome BleBtHomeData|nil If the device is a bthome device, then decoded data here

-- This is what is typically received
---@type BleAdvertismentData
local sample = {
    id = '7CC6B6653AA9',
    service = 0xFCD2,
    name = '',
    rssi = -55,
    response = { [22] = '', [1] = '' },
    bthome = {
        flags = 0x44,
        battery = 100,
        seq = 3,
        action = 1,
        button = 'press'
    }
}
```

### Sample

Typically a callback waiting for some specific advertisment frame (like a button click) is implemented as follows:

``` lua
local cbFn = nil
local myDeviceId = ''

-- Callback function, when a BLE advertisment is received
local function onScan() end
onScan = function(tbl)
	if tbl == nil then
		-- scan finished, restart scanning
        ble.scan_start(cbFn, 0xFCD2)
	else
		XTRACE(16, "scan device found: id="..(tbl.id or ''))
        if tbl.id ==  myDeviceId then
            -- this is our key!
            local bthome = tbl.bthome
            if cbFn then
                cbFn(tbl)
            end
            ble.scan_stop()
        end
	end
end

-- Call this function to start scanning, until an advertisment
-- for the given device-id and the service 0xFCD2 is received,
-- If a matching response is received, the callback function 
-- provided in the parameter will be called and the scan will stop.
function Scan(deviceId, callback)
    -- store the callback function locally
    cbFn = callback
    -- keep the device id
    myDeviceId = deviceId
    -- start (asynchronously) scanning for btHome devices (service UUID = 0xFCD2)
    ble.scan_start(cbFn, 0xFCD2)
end

```

