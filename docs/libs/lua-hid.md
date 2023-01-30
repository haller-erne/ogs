--
id: luahid
name: LuaHID
title: LuaHID
tags:
    - API
---

# LuaHID

LuaHID provides an interface to access USB devices over the `HID` (_human input device_) protocol. It implements a thin LUA wrapper interface over the  cross platform hidapi library (hidapi.dll, see 
[signal11/hidapi (github.com)](https://github.com/signal11/hidapi), licensed under [BSD License](https://github.com/signal11/hidapi/blob/master/LICENSE-bsd.txt)). The code is derived from [ynezz/luahidapi (github.com)](https://github.com/ynezz/luahidapi) ([MIT License](https://github.com/ynezz/luahidapi/blob/master/COPYING)) and adopted to OGS.

Note, that although USB mice and keyboards are technically HID devices, the Windows API does not allow to access these through the HID API (for security reasons). All other (custom) USB HID devices should work.

# Module

The LuaHID module provides global functions to access the systems HID API. Before calling any other function of the module, the `init()` function must be called. 

To actually connect to a physical device, an instance of the `HidDevice` object must be created (see #class_hiddevice below) by calling the `open()` function. This requires specifying the _VID_ (vendor ID) and _PID_ (device id) and (optionally) the _SN_ (serial number). If the parameters are not known beforehand, they may be listed through calling the module level `enumerate()` function. This returns a table of all currently connected devices. Specific device actions (like reading/writing) can then be executed on the object returned from the `open()` call.

## Properties

| Property Name | Return Type | Description | Tags |
| -------- | ----------- | ----------- | ---- |
| `_VERSION` | `string` | Current version of the LuaHID module. See also the `version_mod()` function to get more details about the DLL module version. | Read-Only |
| `_TIMESTAMP` | `string` | Timestamp of the last build of the LuaHID module. | Read-Only |

## Enumerations


## Functions

| Function Name | Return Type | Description | Tags |
| -------- | ----------- | ----------- | ---- |
| `init()` | `boolean` | Initializes the LuaHID library. Returns true on success, nil on failure. | None |
| `exit()` | `boolean` | Cleans up and terminates the LuaHID library. Returns true on success, nil on failure. | None |
| `enumerate(integer vid, integer pid)`<br/>`enumerate()`  | `hidenum` | Returns a HID device enumeration object for HID devices that matches given vid, pid pair. Enumerates all HID devices if no arguments provided or (0,0) used.<br/>**IMPORTANT**: Mouse and keyboard devices are not visible on Windows<br/>Returns nil if failed. | None |
| `write()` | `boolean` | . Returns true on success, nil on failure. | None |
| `read()` | `boolean` | . Returns true on success, nil on failure. | None |
| `set()` | `boolean` | . Returns true on success, nil on failure. | None |
| `getstring()` | `boolean` | . Returns true on success, nil on failure. | None |
| `setfeature()` | `boolean` | . Returns true on success, nil on failure. | None |
| `getfeature()` | `boolean` | . Returns true on success, nil on failure. | None |
| `error()` | `boolean` | . Returns true on success, nil on failure. | None |
| `close()` | `boolean` | . Returns true on success, nil on failure. | None |
| `msleep()` | `boolean` | . Returns true on success, nil on failure. | None |
| `version_mod()` | `boolean` | . Returns true on success, nil on failure. | None |


# Class HidDeviceInfo

The HidDeviceInfo table provides information about a USB HID device connected to the system. The HidDeviceInfo is retrieved by calling the `enumerate()` function and iterating the result by calling the `next()` member. 

## Properties

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

# Class HidEnum

The HidEnum class is actually an iterator and represents the list returned from calling the `enumerate` module function. Each element of the list represents a connected USB HID device and has the properties shown in the following section. 
To iterate the list, call the `next()` instance function - each call to next returns a `HidDeviceInfo` table and internally advances to the next item.

## Functions

| Function Name | Return Type | Description | Tags |
| -------- | ----------- | ----------- | ---- |
| `next()` | `HidDevice` | Returns the current device info data and steps on to the next element in the list. | None |
| `close()` | `None` | Closes the iterator and frees any resources. There is normally no need to call this, as the object is garbage collected automatically. | None |

# Class HidDevice

## Properties

## Functions

    {"write", hidapi_write},
    {"read", hidapi_read},
    {"set", hidapi_set},
    {"getstring", hidapi_getstring},
    {"setfeature", hidapi_setfeature},
    {"getfeature", hidapi_getfeature},
    {"error", hidapi_error},
    {"close", hidapi_close},
    {"__gc",  hidapi_hiddevice_meta_gc},


). are CoreObjects that can be added to Players and guide the Player's animation in sync with the Ability's state machine. Spawn an Ability with `World.SpawnAsset()` or add an Ability as a child of an Equipment/Weapon to have it be assigned to the Player automatically when that item is equipped.




