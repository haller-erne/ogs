---
id: luamodbus
name: LuaModbus
title: LuaModbus
tags:
    - API
---

# LuaModbus

LuaModbus provides a wrapper over libModbus (see [libmodbus (github.com)](https://libmodbus.org/), [LGPL-2.1](https://github.com/stephane/libmodbus/blob/master/COPYING.LESSER)) to access Modbus-TCP/UDP-Devices from LUA. In addition to wrapping the libModbus library, LuaModbus also adds a background thread to cyclically read/write a set of registers and automatically reconnect the connection. Using this thread, after the connection is (re)established, a register can automatically be set to a given value (e.g. for setting a "startup" bit as seen in the Rexroth/Phoenix Contact I/O modules).
The actual LUA wrapper is based on the [etactica/lua-libmodbus (github.com)](https://github.com/etactica/lua-libmodbus) LUA bindings ([MIT-License](https://github.com/etactica/lua-libmodbus/blob/master/LICENSE)), but heavily modified for use with OGS.

Unless otherwise noted, LuaModbus implements the same set of features as the original lua-libmodbus, so the library documentation ([Reference (etactica.github.io)](http://etactica.github.io/lua-libmodbus/)) is a very good source of information.

-------------  TODO  -----------

## Module

The LuaModbus module provides global (helper) functions for to access the systems HID API. Before calling any other function of the module, the `init()` function must be called. 

To actually connect to a physical device, an instance of the `HidDevice` object must be created (see #class_hiddevice below) by calling the `open()` function. This requires specifying the _VID_ (vendor ID) and _PID_ (device id) and (optionally) the _SN_ (serial number). If the parameters are not known beforehand, they may be listed through calling the module level `enumerate()` function. This returns a table of all currently connected devices. Specific device actions (like reading/writing) can then be executed on the object returned from the `open()` call.

### Properties

| Property Name | Return Type | Description | Tags |
| -------- | ----------- | ----------- | ---- |
| `_VERSION` | `string` | Current version of the LuaHID module. See also the `version_mod()` function to get more details about the DLL module version. | Read-Only |
| `_TIMESTAMP` | `string` | Timestamp of the last build of the LuaHID module. | Read-Only |

### Functions

| Function Name | Return Type | Description | Tags |
| -------- | ----------- | ----------- | ---- |
| `init()` | `boolean` | Initializes the LuaHID library. Returns true on success, nil on failure. | None |
| `exit()` | `boolean` | Cleans up and terminates the LuaHID library. Returns true on success, nil on failure. | None |
| `enumerate(integer vid, integer pid)`<br/>`enumerate()`  | `hidenum` | Returns a HID device enumeration object for HID devices that matches given vid, pid pair. Enumerates all HID devices if no arguments provided or (0,0) used.<br/>**IMPORTANT**: Mouse and keyboard devices are not visible on Windows<br/>Returns nil if failed. | None |
| `open(string path)`<br/>`open(number vid, number pid)` | `HidDevice` | Opens a HID device using a path name or a vid,pid pair. Returns a HID device object on success - specifying a serial number is currently not implemented. Returns nil on failure. | None |
| `write(HidDevice dev, string report)`<br/>`write(HidDevice dev, integer report_id, string report)` | `integer` | Writes the given `report` data string to the `report_id` (0 by default). Returns number of bytes actually sent on success, nil on failure. | None |
| `read(HidDevice dev, integer report_size [, timeout_msec])` | `string` | Reads data from the given device. If a device has multiple reports, the first byte indicates the report ID and one extra byte needs to be allocated via report_size. For a normal call, `timeout_msec` can be omitted and blocking will depend on the selected option setting. Passing `timeout_msec` == -1 will always block. Returns the report data (as string) on success, nil on failure. | None |
| `set(HidDevice dev, string option)` | `integer` | Set the read blocking option, allowed parameters are `noblock` and `block`. Returns true on success, nil on failure. | None |
| `getstring(HidDevice dev, string option)` | `string` | Reads the given option property from the device. Currently known option names are `manufacturer`, `product` and `serial`. Returns the option value on success, nil on failure. | None |
| `setfeature(HidDevice dev, integer feature_id, string data)` | `integer` | Send a feature report for the given `feature_id` with the given `feature_data`. Returns the number of bytes actually sent on success, nil on failure. | None |
| `getfeature(HidDevice dev, integer feature_id, integer feature_size)` | `string` | Get (read) a feature report for the given `feature_id`. A 0 is used for a single feature report. Returns the feature data (as a string) on success, nil on failure. | None |
| `error(HidDevice dev)` | `string` | Returns a string (as ASCII) describing the last error occurred for the device or nil if there was no error. | None |
| `close(HidDevice dev)` | `None` | Closes the given HidDevice object. | None |
| `msleep(integer milliseconds)` | `None` | Convenience function to sleep a number of milliseconds. | None |
| `version_mod()` | `string, table` | Returns the file version info of the LuaHID DLL (as a string in the from "major.minor.build-hi,build-low" and a table with the same values. | None |


## Class HidDeviceInfo

The HidDeviceInfo table provides information about a USB HID device connected to the system. The HidDeviceInfo is retrieved by calling the `enumerate()` function and iterating the result by calling the `next()` member. 

### Properties

| Property Name | Return Type | Description | Tags |
| -------- | ----------- | ----------- | ---- |
| `path` | `string` | System specific device path. | Read-Only |
| `vid` | `integer` | Vendor ID of the device. | Read-Only |
| `pid` | `integer` | Product ID of the device. | Read-Only |
| `serial_number` | `string` | Device serial number. | Read-Only |
| `release` | `integer` | Release number (version) of the device. | Read-Only |
| `manufacturer_string` | `string` | Manufacturer name. | Read-Only |
| `product_ _string` | `string` | Product name. | Read-Only |
| `usage_page` | `integer` | HID usage page of the device. | Read-Only |
| `usage` | `integer` | HID usage of the device. | Read-Only |
| `interface` | `integer` | Interface number of the device. | Read-Only |

## Class HidEnum

The HidEnum class is actually an iterator and represents the list returned from calling the `enumerate` module function. Each element of the list represents a connected USB HID device and has the properties shown in the following section. 
To iterate the list, call the `next()` instance function - each call to next returns a `HidDeviceInfo` table and internally advances to the next item.

### Functions

| Function Name | Return Type | Description | Tags |
| -------- | ----------- | ----------- | ---- |
| `next()` | `HidDevice` | Returns the current device info data and steps on to the next element in the list. | None |
| `close()` | `None` | Closes the iterator and frees any resources. There is normally no need to call this, as the object is garbage collected automatically. | None |

## Class HidDevice

### Functions

The member functions of HidDevice are wrapped functions of the module. The following lines are identical:

```lua
local hidapi = require('LuaHID')
-- ...
-- assume dev is a HidDevice object returned from calling open()
-- The following are identical:
hidapi.write(dev, report_id, report_data)
dev:write(report_id, report_data)

```

| Function Name | Return Type | Description | Tags |
| -------- | ----------- | ----------- | ---- |
| `write(string report)`<br/>`write(HidDevice dev, integer report_id, string report)` | `integer` | See `LuaHID.write(...)` | None |
| `read(integer report_size [, timeout_msec])` | `string` | See `LuaHID.read(...)` | None |
| `set(HidDevice dev, integer option)` | `integer` | See `LuaHID.set(...)` | None |
| `getstring(HidDevice dev, string option)` | `string` | See `LuaHID.getstring(...)` | None |
| `setfeature(HidDevice dev, integer feature_id, string data)` | `integer` | See `LuaHID.setfeature(...)` | None |
| `getfeature(HidDevice dev, integer feature_id, integer feature_size)` | `string` | See `LuaHID.getfeature(...)` | None |
| `error()` | `string` | See `LuaHID.error(...)` | None |
| `close(HidDevice dev)` | `None` | See `LuaHID.close(...)` | None |

## Examples

### Enumerate connected devices

This sample lists all connected HID devices and shows some of their properties.
```lua
-- Load the LuaHID module
local hidapi = require('LuaHID')
print(string.format("Lib VERSION %s build on %s", hid._VERSION, hid._TIMESTAMP))

-- Initialize the library
if hidapi.init() then
	print("hid library: init")
else
	print("hid library: init error")
	return
end

-- Enumerate the currently connected devices and print some information
local enum = hidapi.enumerate()
if not enum then
	print("Enumeration: no device found or enumeration failed!")
	return
else
	while true do
		local dev = enum:next()
		if not dev then break end
			print("Device found:")
			print(string.format("path = '%s'", dev.path))
			print(string.format("vid = 0x%04X", dev.vid))
			print(string.format("pid = 0x%04X", dev.pid))
			print(string.format("serial_number = '%s'", dev.serial_number))
		end
	end
end

-- Do a clean shutdown
if hidapi.exit() then
	print("hid library: exit")
else
	print("hid library: exit error")
	return
end
```


### Read/write device report data

This sample tries to connect to a specific device using a given _VID_/_PID_ and writes/reads some data in non-blocking mode. 
```lua
-- Load the LuaHID module
local hidapi = require('LuaHID')
print(string.format("Lib VERSION %s build on %s", hid._VERSION, hid._TIMESTAMP))

-- Initialize the library
if hid.init() then
	print("hid library: init")
else
	print("hid library: init error")
	return
end

-- Open a device by VID/PID
USB_DEVICE_VID = 0x04D8
USB_DEVICE_PID = 0x8ABC
USB_REPORT_SIZE = 4
local dev = hidapi.open(USB_DEVICE_VID, USB_DEVICE_PID)
if not dev then
	print("Open: unable to open test device")
	return
end
print("Open: opened test device")

-- Read the serial number
local sn = dev:getstring("serial")
if sn then
	print("Product String: "..sn)
else
	print("Unable to read product string")
	return
end

-- set non-blocking reads
if not dev:set("noblock") then
	print("Failed to set non-blocking option")
	return
end

-- Try to read from the device. There shoud be no
-- data here, but execution should not block.
local rx = dev:read(USB_REPORT_SIZE)
if rx then
	print("Done non-blocking read test")
	print("Size of report read = "..#rx)
else
	print("Read error during non-blocking read test")
	return
end

-- Prepare and write report; report 0 is implied
local tx = string.char(0x12, 0x34, 0x56, 0x78)
local res = dev:write(tx)
if not res then
	print("Unable to write()")
	print("Error: "..dev:error())
	return
end

-- Try reading data
local rx
for i = 1, 10 do
	-- a non-infinite read loop
	-- since we read immediately right after writing, the device buffer
	-- will be empty, it will NAK, and an empty string is returned
	rx = dev:read(USB_REPORT_SIZE)
	if not rx then
		print("Unable to read()")
		print("Error: "..dev:error())
		return
	elseif rx == "" then
		print("Waiting...")
	else
		break
	end
	for j = 1,200000 do end -- short delay
end
if #rx > 0 then
	print("Successfully read data from device!")
end

-- Close the device
dev:close()
print("Close: closed test device")

-- Do a clean shutdown
if hidapi.exit() then
	print("hid library: exit")
else
	print("hid library: exit error")
	return
end
```

### More samples

More samples can be found in then `examples`-folder in the GitHub repository at [luahidapi/doc/examples at master · ynezz/luahidapi (github.com)](https://github.com/ynezz/luahidapi/tree/master/doc/examples).
