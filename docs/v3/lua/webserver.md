# Webserver

## Overview 

The OGS runtime uses the Microsoft Windows builtin [http.sys web server](https://learn.microsoft.com/en-us/windows/win32/api/_http/) to server static pages and dynamic pages. The dynamic pages are implemented through LUA scripting and makes it possible to flexibly implement web services like OpenAPI / REST services or others.

A typical use case is to provide a REST interface for third-party systems to connect them to OGS, another is to implement backend logic for a single page application web page frontend running inside OGS (see also [OGS Webbrowser LUA interface](../webbrowser.md)).

The web server LUA api works by registering LUA callback functions for specific URL prefixes, which are then called by the web server, whenever the given URL is requested from a web client.

## Prerequisites

To use the LUA web server API, the web server must be enabled through `station.ini` (in the `[WebServer]` section) and the Microsoft `http.sys` web server must be configured accordingly (a URL reservation must be activated through the `netsh http add urlacl ...` command).

By default the, installer registers a web endpoint at http://localhost:59990, so the endpoint is only accessible from the local machine and only for a locally logged on user.

To access the web server from the outside, make sure to change the listen address in the `station.ini` file, the URL reservation through `netsh http ...` and check the firewall settings. 

## Global Webserver table

OGS exposes the web server through the global `Webserver` object. The `Webserver` object implements the following functions:

- [RegUrl](#regurl): Register a LUA callback function to be called when a specific URL prefix is requested from the web server.

<!--
The following functions are also available, but are not fully implemented at the moment:
- [ExecJS_sync](#execjs-sync): 
- [ExecJS_async](#execjs-async):
- [Show](#show): 
- [Hide](#hide): 
- [GetState](#getstate): 
-->

### RegUrl

The `Webserver.RegUrl` function registers or unregisters a LUA function to be called whenever the web server receives a request to the given URL prefix.

```LUA
fn, err = Webserver.RegUrl(prefix, callbackfn)
```

#### Parameters

- prefix [string]: Path prefix to match against when checking the request URL. Note that this only checks for the path part of the URL (e.g. '/home'). 
- callbackfn [function]: LUA function to be called when a web request matches the prefix. The callback function has the following signature:

        table = callbackfn(reqpath, reqparams, verb, body)

    Where reqpath [string] is the full request path, (e.g. '/api/items'), reqparams [string] the request parameters (e.g. '?max=10&class=5'), verb [integer] the request type (GET, PUT, POST, DELETE) and body [string] the body (binaty) string value (only for POST and PUT).

    The callback function should return a response table with the required parameters to build the http response (optional body).

    [Datails tbd.]

#### Return values

If the function was executed successfully, the callbackfn is returned as the first return value. Else nil is returned and the second return value has an error message string (wrong parameters or unknown instance).

#### Sample code
```LUA
local function handlerfn(reqpath, reqparams, verb, body)
    -- process the request, return the response object (or nil
    -- if this request is not handled) 
    return nil
end
-- Register a LUA function to be called whenever a web request to /api/lua
-- is made
Browser.RegMsgHandler('/api/lua', handlerfn)
```
