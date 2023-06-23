---
id: luadpapi
name: LuaDPApi
title: LuaDPApi
tags:
    - API
---

# LuaDPApi

LuaDPApi provides an interface to the [Microsoft Data Protection API](https://learn.microsoft.com/en-us/windows/win32/api/dpapi/). It implements a thin LUA wrapper interface over the `CryptProtectData` and `CryptUnprotectData` API calls. 

The main purpose is to store secrets (like passwords, or API token etc.) in a configuration file (like to OGS `station.ini`) without exposing the sensitive data to the world (e.g. if storing backups of these configuration files or versioning these files through git). This works by encrypting the secret data and writing the encrypted string into the configuration file. The application reading the configuration file can the decrypt the data and use it.

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

    As encrypted data is binary, for configuration files, it is usually stored as a base64 encoded string. Use the LUA `mime` library (part of the `luasocket` library) to encode and decode a base64 string (see below for sample code). Also make sure to use the same text encoding for encryption and decryption (LUA uses UTF8-strings)!


# Examples

## Encrypt a string

This sample shows how to encrypt a given plaintext string (LUA string, UTF8-encoded) and encode the encrypted data into a base64 string.

```lua
local dpapi = require('luadpapi')  -- load the DPAPI
local mime = require('mime')       -- load luasocket/mime (base64)

-- Sample plaintext password (or connection string, etc)
local plaintext = 'MySuperSecretPassword' 

-- Encrypt the plaintext for the 'machine' scope. All users logged 
-- into the same machine will be able to decrypt the data later.
-- encrypt (usually done at the commandline through powershell):
local encrypted_data, err = dpapi.protect(plaintext, 'machine') 
if encrypted_data == nil then
    print("ERROR: encrypt failed, err=", err)
    os.exit(-1)
end

-- Do a base64 encode of the encrypted data for storing in *.ini file:
local encrypted_b64 = mime.b64(encrypted_data)     

-- TODO: save to some text file, but for now just print it
print("encrypted, base64 encoded data: ", encrypted_b64)

```

## Decrypt base64-encoded data

This sample shows how to decrypt previously encrypted and base64 encoded data. 

```lua
local dpapi = require('luadpapi')   -- load the DPAPI
local mime = require('mime')        -- load luasocket/mime (base64)

-- Sample plaintext password (or connection string, etc)
-- !!! Make sure to paste the data generated from the previous sample!
local encrypted_b64 = 'AQAAANCMnd8BFdERjHoAwE/Cl+'...'ylQ=' 

-- Convert from base64 to raw data
local encrypted = mime.unb64(encrypted_b64)

-- Decrypt the raw data.
local decrypted_data, err = dpapi.unprotect(plaintext) 
if decrypted_data == nil then
    print("ERROR: decrypt failed, err=", err)
    os.exit(-1)
end

-- TODO: use the decrypted data - assume this is a string and print it:
print("decrypted data: ", decrypted_data)

```

## Encrypt/decrypt using Powershell

The DPAPI is also implemented in the [Security.Cryptography.ProtectedData] DotNET assembly, so 
these functions can be also be used from Powershell.

!!! warning

    In contrast to LUA, Powershell by default uses Unicode encodiung (16-Bit characters)! 
    For interoperability with LUA, make sure to encode/decode all strings to UTF8 (as shown 
    in the samples below)!

The following samples are based on [https://stackoverflow.com/questions/46400234/encrypt-string-with-the-machine-key-in-powershell](https://stackoverflow.com/questions/46400234/encrypt-string-with-the-machine-key-in-powershell).

```powershell

Function Decrypt-WithMachineKey($s) {
    Add-Type -AssemblyName System.Security

    $SecureStr = [System.Convert]::FromBase64String($s)
    $bytes = [Security.Cryptography.ProtectedData]::Unprotect($SecureStr, $null, [Security.Cryptography.DataProtectionScope]::LocalMachine)
    $Password = [System.Text.Encoding]::UTF8.GetString($bytes)
    return $Password
}

Function Encrypt-WithMachineKey($s) {
    Add-Type -AssemblyName System.Security

    $bytes = [System.Text.Encoding]::UTF8.GetBytes($s)
    $SecureStr = [Security.Cryptography.ProtectedData]::Protect($bytes, $null, [Security.Cryptography.DataProtectionScope]::LocalMachine)
    $SecureStrBase64 = [System.Convert]::ToBase64String($SecureStr)
    return $SecureStrBase64
}

# Encrypt
$plaintext = "MySuperSecretPassword"
$encrypted_b64 = Encrypt-WithMachineKey(plaintext)

# Show the base64-string
$encrypted

# Decrypt again
$decrypted = Decrypt-WithMachineKey(encrypted)

# Show the decrypted string
$decrypted

```




