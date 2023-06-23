--
id: luadpapi
name: LuaDPApi
title: LuaDPApi
tags:
    - API
---

# LuaDPApi

LuaDPApi provides an interface to the [Microsoft Data Protection API](https://learn.microsoft.com/en-us/windows/win32/api/dpapi/). It implements a thin LUA wrapper interface over the `CryptProtectData` and `CryptUnprotectData` API calls. 

The main purpose is for storing secrets (like passwords, or API token etc.) in a configuration file (like `station.ini`) without exposing the sensitive data to the world (e.g. if storing backups of these configuration files or versioning these files through git). This works by encrypting the secret data and writing the encrypted string into the configuration file. The application reading the configuration file can the decrypt the data and use it.

In the background, the [Microsoft Data Protection API](https://learn.microsoft.com/en-us/windows/win32/api/dpapi/) encrypts/decrypts data by deriving an encryption key based on either the unique machine-id or a user-specific id:

- If the scope during the encryption is the machine-id, then all users, who are able to log on to this machine, will be able to decrypt the data. 
- If the scope during the encryption is the user-id, then only the user, who encrypted the data will be able to decrypt later. Changes top the user password are tracked internally, so even after a password change, the user will be able to decrypt. If a users password is reset, then no access to the encrypted data is possible anymore.

Note, that in an ActiveDirectory environment, backup keys are stored on the domain controller - allowing the domain administrator to decrypt, too. 

In addition to the user/machine-scope, an additional `enthropy` parameter can be used during encryption. In this case, the `enthropy`-data is added as part of the encryption key - effectively allowing successful decryption only, if the very same `enthropy`-data is added during decryption. This is e.g. used by the Edge browser to encrypt website passwords - the `entropy` data is the website URL, so without knowng the actual URL, no password can be decrypted.

# Module

The LuaDPApi module provides global functions to access the [Microsoft Data Protection API](https://learn.microsoft.com/en-us/windows/win32/api/dpapi/).

## Functions

| Function Name | Return Type | Description | Tags |
| -------- | ----------- | ----------- | ---- |
| `protect(data: string, scope: string = 'machine' entropy: string = nil)` | `data: string` or `nil, win32error: integer` | Encrypts the given data (binary string) using the given scope (one of 'maschine' or 'user') and entropy. Returns the encrypted data (as a binary string) or nil and the Win32 API error code. | None |
| `unprotect(data: string, entropy: string = nil)` | `data: string` or `nil, win32error: integer` | Dencrypts the given data (binary string) using the given entropy. Returns the decrypted data (as a binary string) or nil and the Win32 API error code. | None |

!!! info

Note that the LUA functions pass raw data strings to the underlying [Microsoft Data Protection API](https://learn.microsoft.com/en-us/windows/win32/api/dpapi/) functions. Encoding and decoding text strings (e.g. to read/write the encrypted binary data from/to a configuration file) must be handled by additional code.

!!! tip

Typically encrypted data is stored as bs64 encoded strings. Use the LUA `mime` library (part of the `luasocket` library) to encode and decode a base64 string (see below for sample code)


# Examples

## Enumerate connected devices

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



