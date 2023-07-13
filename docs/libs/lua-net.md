---
id: luanet
name: LuaNet
title: LuaNet
tags:
    - API
---

# LuaNet

LuaNet provides simple to use functions for REST/OpenAPI calls using http and https protocols. Compared to [luasocket](https://github.com/lunarmodules/luasocket) and [luassl](http://mauriciocarneiro.github.io/software/luassl/index.html), it uses the the Windows infrastructure and therefore correctly works with system proxies. Feature-wise it is not as flexible as luasocket/luassl at the moment (e.g. no direct access to all headers), but it is good enough for OAuth and SAP endpoints (like the [SAP Digital Manufacturing Cloud](https://api.sap.com/package/SAPDigitalManufacturingCloud/rest)).

The basic functions work in a blocking mode, i.e. the process calling the function is blocked until a response from the endpoint is received. However, there are also asynchronous functions for starting a (post) request and polling for the completion. This is especially useful for long-running OpenAPI calls (like some SAP digital manufacturing cloud endpoints).

!!! info

    All functions in LuaNet work transparently, i. e. use raw text strings (binary) for request and response body texts. For OpenAPI/REST services typically JSON encoded objects are used. From the large number of lua json libraries (e. g. see [Awesome Lua](https://github.com/LewisJEllis/awesome-lua#parsing-and-serialization)), we recommend to use [Lua CJSON](https://github.com/mpx/lua-cjson). If you use another library, make sure it support UTF8 correctly! 


## Module

The LuaNet module provides global functions to execute http/https requests.

### Functions

The following table lists blocking functions: 

| Function Name | Return Type | Description | Tags |
| -------- | ----------- | ----------- | ---- |
| `get(url: string, user: string = nil, pass: string = nil)` | `data: string, status: number, statustext: string, data: string` or `nil, status: number, statustext: number` | Executes a blocking get request for the given URL. If the server returns (http) status = 200, then the response is considered valid. In any case, `status` and `statustext` will receive the http response header status data. If a response body is available, then this is returned in the `data` return value (even if status ~= 200).  | None |
| `get_oauth_token(url: string, user: string = nil, pass: string = nil)` | `status: number, data: string` or `nil, status: number, statustext: string` | Requests client credentials from an OAuth2 server (granttype = client_credentials). | None |
| `post(url: string, body: string = nil, auth_bearer_token: string = nil)` | `status: number, data: string, statustext: string` | Send a post request to the given endpoint `URL`, with post `data` in the request body, optinally adding the `auth_bearer_token` value to the `Authorization` header.  | None |

The following table lists the non-blocking functions:

| Function Name | Return Type | Description | Tags |
| -------- | ----------- | ----------- | ---- |
| `post_async(url: string, body: string = nil, auth_bearer_token: string = nil)` | `handle: number` or `nil` | Starts an async post request (see the blocking `post` above for parameter descriptions). On success a `handle` is returned, which can be used for polling the request status or aborting the request.  | None |
| `abort_async_request(handle: number)` | (no return value) | Tries to abort a currently active request identified by the `handle` value (as returned from `post_async()`. If the request is currently active, it might block for a short time - until the request is actually cancelled. If a request was cancelled, then further calls to `poll_async_request()` will return `nil`, as the internal request object for the given handle was deleted and does not exist anymore. | None |
| `poll_async_request(handle: number)` |  `requeststate: number, status: number, data: string, statustext: string`  or `nil, errorcode: number, errortext: string` | Checks the request state of a pending request and returns the current state in `requeststate`. If the 'handle' was not found, nil is returned for `requeststae`, else the current (internal) process step. A value of >= 100 indicates, that the request has completed and the other return values are valid (see the blocking `post` above for result value descriptions). Note, that the internal request object is automatically deleted after `poll_async_request()` returns a status of >= 100. | None |

!!! warning

    A request started through `post_async()` must be completed by either aborting the request through `abort_async_request()` or by polling the request (by using `poll_async_request`) until a state of >= 100 is returned. If not, then the internal request object will not get deleted thus consuming more and more resource.


## Examples

### Simple get request

This sample shows how to execute a simple https get request with basic authentication (e.g. typical surveillance camera).

```lua
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

### Decrypt base64-encoded data

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
local decrypted_data, err = dpapi.unprotect(encrypted) 
if decrypted_data == nil then
    print("ERROR: decrypt failed, err=", err)
    os.exit(-1)
end

-- TODO: use the decrypted data - assume this is a string and print it:
print("decrypted data: ", decrypted_data)

```


