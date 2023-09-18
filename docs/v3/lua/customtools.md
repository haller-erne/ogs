---
id: luacustomtools
name: LuaCustomTools
title: Lua custom tools
tags:
    - API
---

## Overview

OGS has an interface to add additional tool drivers by adding Windows-DLLs to the `[TOOL_DLL]` section in `station.ini`. To make it easier to implement custom tool drivers, OGS provides `heLuaTool.dll` - this allows implementing tool drivers in pure LUA. 

To implement a tool driver in LUA, usually the following steps are required:

- Add/enable `heLuaTool.dll` in the `[TOOL_DLL]`-section in `station.ini`
- Create a custom LUA tool driver file (see bvelow) and add it to your projects configuration (add the file name to the `requires = {}`-list in `config.lua`)
- Add one or more channels to `station.ini` (in the `[CHANNELS]`-section in `station.ini`). Note, that the section name assigned to the tool number must start with `LuaTool_`!
- Add the specified section to `station.ini` and set `Driver=heLuaTool` and `TYPE=` to the tool driver name as defined in your custom LUA tool driver
- Also add the tool/channel parameters as required by your LUA driver in the specified section.
- To allow using the custom tools, add then to the `custom` section in the heOpCfg tools editor tab. Also add new tool/action properties as required. Make sure to use the same tool/channel numbers as defined in your `station.ini`. 

Here is an excerpt from `station.ini` showing the relevant entries:

``` ini title="station.ini"
[TOOL_DLL]
heLuaTool.dll=1 ; (1)!

[CHANNELS]
20=LuaTool_MyCustomTool ; (2)!

[LuaTool_MyCustomTool]
Driver=heLuaTool
TYPE=MyCustomTool
; additional LUA too specific parameters can follow
```

1. Load and enable the generic LUA tool interface DLL

2. Create the channel/tool 20 and assign the configuration section `LuaTool_MyCustomTool`. Make sure to start the section name with `LuaTool_`, else the Lua tool DLL will not get loaded for this section!

To implement a tool driver using LUA, there are basically two possibilities:

1. Use the low-level API provided by `heLuaTool.dll`.
2. USe the [Simplified API](#simplified-api) 

It is highly recommended to use the [Simplified API](#simplified-api) described below to implement custom tool drivers - using the low-level API requires in-depth knowledge of the API to not break other drivers!

## Simplified API

The simplified custom tool driver API uses five states and associated transitions to implement the tool behaviour. Each transitions can be implemented in the custom tool LUA code to provide the custom functionality - if not implemented, the transition is executed without a custom action.

Here is the state diagram for the behaviour:

``` mermaid
stateDiagram-v2
    [*] --> active: init()
    inactive --> active: activate()
    active --> inactive: deactivate()
    active --> enabled: enable()
    enabled --> enabled: execute()
    enabled --> disabled: disable()
    disabled --> enabled: enable()
    disabled --> inactive: deactivate()
```

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


### Mermaid test

The following is a simple mermaid sequence diagram, for more details, see [https://squidfunk.github.io/mkdocs-material/reference/diagrams/](https://squidfunk.github.io/mkdocs-material/reference/diagrams/)

``` mermaid
sequenceDiagram
  autonumber
  Alice->>John: Hello John, how are you?
  loop Healthcheck
      John->>John: Fight against hypochondria
  end
  Note right of John: Rational thoughts!
  John-->>Alice: Great!
  John->>Bob: How about you?
  Bob-->>John: Jolly good!
```
