---
id: loaostools
name: LuaOSTools
title: LuaOSTools
tags:
    - API
---

# LuaOSTools

LuaOSTools provides an interface to various Windows specific APIs. It implements a thin LUA wrapper interface over the Win32 API calls. 

## Module

The LuaOSTools module provides the following submodules:

- luaostools.security: Functions related to User-Management (like get current user name, check group membership)
- luaostools.scard: Functions related to the [WinSCard API](https://learn.microsoft.com/en-us/windows/win32/api/winscard/) (to access PC/SC compatible smart card readers)

All modules are contained in a single LUA C-DLL but are scoped into seperate libraries according to their functionality. To access the libraries, load them as follows:

``` lua
-- Load the OSTools security library:
local security = require('luaostools.security')

-- Load the OSTools scard library:
local scard = require('luaostools.scard')
```

## luaostools.security

| Function Name | Return Type | Description | Tags |
| -------- | ----------- | ----------- | ---- |
| `GetUserName(format: integer = 8)` | `name: string` or `nil, win32error: integer` | Reads the current user name in the given format (1 = FullyQualifiedDN, 2 = SamCompatible, 3 = DisplayName, 6 = UniqueId, 7 = Canonical, 8 = UserPrincipal, 9 = CanonicalEx, 10, = ServicePrincipal, 12 = DnsDomain, 13 = GivenName, 14 = Surname). Returns the requested property/format or nil and the Win32 API error code. | None |
| `IsMemberOf(groupsid: string)` | `isMember: boolean` or `nil, win32error: integer` | Checks, if the current user is a member of the given group (identified by the group security identifier). You can use the well known SIDs (e.g. `'S-1-5-32-544'` for the `Administrators` group) to query for group membership or all other [SID formats allowed for ConvertStringSidToSid()](https://learn.microsoft.com/en-us/windows/win32/secauthz/sid-components). Returns true/false (true if the user is a member) or nil and the Win32 API error code. | None |


For more information, see the Win32 API documentation:

- [Win32 API GetUserNameEx()](https://learn.microsoft.com/en-us/windows/win32/api/secext/nf-secext-getusernameexw)
- [Win32 API SID Components](https://learn.microsoft.com/en-us/windows/win32/secauthz/sid-components)

??? example "Sample code for checking group membership"

    ``` lua
    local ostools = require('luaostools.security')           -- load our library

    -- define the user name formats
    local UserNameFormat = {
        Unknown = 0,                  -- An unknown name type.
        FullyQualifiedDN = 1,         -- The fully qualified distinguished name (for example, CN=Jeff Smith,OU=Users,DC=Engineering,DC=Microsoft,DC=Com).
        SamCompatible = 2,            -- A legacy account name (for example, Engineering\JSmith). The domain-only version includes trailing backslashes (\).
        Display = 3,                  -- A "friendly" display name (for example, Jeff Smith). The display name is not necessarily the defining relative distinguished name (RDN).
        UniqueId = 6,                 -- A GUID string that the IIDFromString function returns (for example, {4fa050f0-f561-11cf-bdd9-00aa003a77b6}).
        Canonical = 7,                -- The complete canonical name (for example, engineering.microsoft.com/software/someone). The domain-only version includes a trailing forward slash (/).
        UserPrincipal = 8,            -- The user principal name (for example, someone@example.com).
        CanonicalEx = 9,              -- The same as NameCanonical except that the rightmost forward slash (/) is replaced with a new line character (\n), even in a domain-only case (for example, engineering.microsoft.com/software\nJSmith).
        ServicePrincipal = 10,        -- The generalized service principal name (for example, www/www.microsoft.com@microsoft.com).
        DnsDomain = 12,               -- The DNS domain name followed by a backward-slash and the SAM user name.
        GivenName = 13,
        Surname = 14,
    }
    local UserNameFormatNames = {
        [UserNameFormat.Unknown] = 'Unknown',
        [UserNameFormat.FullyQualifiedDN] = 'FullyQualifiedDN',
        [UserNameFormat.SamCompatible] = 'SamCompatible',
        [UserNameFormat.Display] = 'Display',
        [UserNameFormat.UniqueId] = 'UniqueId',    
        [UserNameFormat.Canonical] = 'Canonical',
        [UserNameFormat.UserPrincipal] = 'UserPrincipal',
        [UserNameFormat.CanonicalEx] = 'CanonicalEx',
        [UserNameFormat.ServicePrincipal] = 'ServicePrincipal',
        [UserNameFormat.DnsDomain] = 'DnsDomain',
        [UserNameFormat.GivenName] = 'GivenName',
        [UserNameFormat.Surname] = 'Surname',
    }

    -- define some well-known group sids
    local Groups = {
        ['S-1-1-0'] =       'Everyone',
        ['S-1-2-0'] =       'LOCAL',
        ['S-1-5-2'] =       'NETWORK',
        ['S-1-5-18'] =      'SYSTEM',
        ['S-1-5-10'] =      'SELF',
        ['S-1-5-11'] =      'Authenticated Users',
        ['S-1-5-20'] =      'NETWORK SERVICE',
        ['S-1-5-32-544'] =  'Administrators',
        ['S-1-5-32-573'] =  'Event Log Readers',
        ['S-1-5-32-546'] =  'Guests',
        ['S-1-5-32-568'] =  'IIS_IUSRS',
        ['S-1-5-32-559'] =  'Performance Log Users',
        ['S-1-5-32-558'] =  'Performance Monitor Users',
        ['S-1-5-32-547'] =  'Power Users',
        ['S-1-5-32-555'] =  'Remote Desktop Users',
        ['S-1-5-32-580'] =  'Remote Management Users',
        ['S-1-5-32-581'] =  'System Managed Accounts Group',
        ['S-1-5-32-545'] =  'Users',
    }

    print("Getting user name in all formats")
    for k,v in pairs(UserNameFormatNames) do
        local un, err = ostools.GetUserName(k)
        if un == nil then
            print(string.format('  %20.20s: Error %d', v, err))
        else
            print(string.format('  %20.20s: %s', v, un))
        end
    end

    print("Checking membership")
    for k,v in pairs(Groups) do
        local isIn, err = ostools.IsMemberOf(k)
        if isIn == nil then
            print(string.format('  %30.30s: Error %d', v, err))
        else
            if isIn then
                print(string.format('  %30.30s: is member', v))
            else
                print(string.format('  %30.30s: not a member', v))
            end
        end
    end

    ```

## luaostools.scard

| Function Name | Return Type | Description | Tags |
| -------- | ----------- | ----------- | ---- |
| `GetReaders()` | `readers: array of string` or `nil, errormessage: string` | Reads the list of currently attached readers. Returns and array of connected readers or nil and some error message string. | None |
| `GetStatusChange()` | `changes: table of changes (see below)` or `nil, errormessage: string` | Checks, if any of the readers have a change (card removed or card added) and returns a table with details. If a card was detected, then a connection is automatically initiated, so you can call one of the other functions to exchange data with the card. If no change was detected, a empty table is returned. On error nil and an errormessage text is returned. | None |
| `ReadCardSerial(reader: string)` | `status: integer, id: string, data: binarystring` or `nil, errormessage: string` | Reads the card serial number. Returns the card response status (0x9000 for read ok), the card id (as hex encoded string) and the raw (binary) card response data. On error nil and some error message string is returned. | None |

`GetStatusChange()` should be called cyclically to detect card changes. The function returns a table with a key for each readers change - the value then contains information about the change in the following structure:

```lua
---@class StatusChangeEvent
---@field name string Reader name
---@field state integer The event flags as reported by SCardGetStatusChange()
---@field protocol integer The active protocol code as reported by SCardGetStatusChange()
---@field handle integer The card handle (if ~= 0, this indicates a newly connected card)
```

The main information here is the handle value - if handle == 0 then the card was disconnected, if handle ~= 0 then a card connect event happened.

??? example "Sample code for detecting cards and reading ID"

    ``` lua
    local scard = require('luaostools.scard')           -- load our library

    local gReaders = nil
    local gCards = {}
    -- return status, id
    local function GetCardId()
        if not gReaders then
            local readers, err = scard.GetReaders()
            if readers == nil then
                return nil, 'no reader available'
            end
            print("Smartcard Readers found:")
            for _,reader in pairs(readers) do
                print(string.format('  Reader %s', reader))
            end
            gReaders = readers
        end
        local data, err = scard.GetStatusChange()
        if data then
            for k,v in pairs(data) do
                if v.handle and v.handle ~= 0 then
                    -- card is plugged
                    print(string.format('[%s] Card plugged: State %08Xh', k, v.state))
                    local status, id, data = scard.ReadCardSerial(k)
                    if status == 0x9000 then
                        -- local raw = basexx.to_hex(data)
                        print(string.format('       ID = "%s" (State %08Xh)', id, status))
                        gCards[k] = id
                        return true, id
                    else
                        return nil, 'error reading card'
                    end
                else
                    -- card is unplugged
                    local oldId = gCards[k] or ''
                    if oldId == '' then
                        -- was no card before
                        return nil, 'initial card remove event'
                    end
                    print(string.format('[%s] Card "%s" removed', k, oldId))
                    return false, oldId
                end
            end
        end
    end

    -- run an endless test loop...
    while true do
        GetCardId()
    end
    ```


