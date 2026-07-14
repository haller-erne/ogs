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

To implement a tool driver using LUA, there are basically two options:

1. Use the low-level API provided by `heLuaTool.dll`.
2. Use the [Simplified API](#simplified-api) 

!!! info

    It is highly recommended to use the [Simplified API](#simplified-api) described below to implement custom tool drivers - using the low-level API requires in-depth knowledge of the API to not break other drivers!


## LUA driver anatomy and driver registration

The LUA tool driver must be implemented as LUA module, returning the module table. Another requirement is to have the tool driver type as member `type` in the module table (this is how `station.ini` and the actual LUA driver is linked). 

In addition to this, it is __required__ to register the driver module with OGS by adding the tool driver type and its module to the global `lua_known_tool_types` table - best practice is to use the function `register_tool` from the `lua_tool_helpers`-module.

Here is a skeleton of a driver module:

``` lua title="my_custom__driver.lua"
-- My custom LUA tool driver
local _M = {
	type = 'MyCustomTool',     -- type id (must match the DRIVER= in INI file)
}

-- register this tool with OGS (heLuaTool.dll)
local helpers = require('lua_tool_helpers')
helpers.register_tool(_M)

-- return the module
return _M
```


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

The `active` state is entered whenever OGS has an active operation for this tool. While the tool is `active`, it might switch back and forth between `disabled` and `enabled` (e.g. depending on any external enable/release condition).  After a tool result has been received, the state typically switches back to `inactive` (another tool is active or workflow has finished). 

!!! info

    Use the `lua_tool_helpers.lua` in your code - this provides helpers for registering the tool driver, flexible default formatting functions and a few handy helpers!


### Tool driver interface functions

The actual tool driver implementation is provided by implementing the tool driver interface functions - and return them as members of the module table. Note that each interface has a `channel` parameter with

A typical implementation would look like the following (adding the `_M.init()`, the `_M.enable()` and the the `_M.execute()` functions):

``` lua title="my_custom__driver.lua"
-- My custom LUA tool driver
local _M = {
	type = 'MyCustomTool',     -- type id (must match the DRIVER= in INI file)
}
local helpers = require('lua_tool_helpers')

-------------------------------------------------------------
-- Tool event: Initialize tool - called once during OGS init 
-- return 'OK' or some error text if the initialization failes.
function _M.init(channel)
    -- Decode/get my configuration (from station.ini)
    local cfg = {
        ComPort = channel.ini_params.COM_PORT,      -- COM port
    }
    -- Do whatever is needed to initialize your driver
    -- ...
  	channel.cfg = cfg         -- store the channels config data
    return 'OK'               -- init successfully done
end

----------------------------------------------------------------------------
-- Tool event: Cyclically called while the tool is enabled
-- return the tool task state
function _M.execute(channel)
    -- Check for tool finished
    local ResultData = _M.GetResultData() -- must be implemented!
    if ResultData == nil then       -- no data available from the tool
        return channel.task_state   -- wait more.
    end
    if ResultData.Error then        -- some error occurred
        return lua_task_fault       -- return an error code
    end
    if ResultData.Data then         -- received data
        -- Build a result data table and notify the OGS core 
        local values = {
            ResultData.torque,          -- M1 actual value
            ResultData.angle,           -- M2 actual value
            ResultData.t_min,           -- M1 min
            ResultData.t_max,           -- M1 max
            0.0,                        -- M2 min
            0.0                         -- M2 max
        }
        local error_code = helpers.get_code_from_limits(ResultData.torque, ResultData.t_min, ResultData.t_max)
        lua_tool_result_response(channel.tool, error_code, 0, '2A', values)
        return lua_task_completed
    end
    return channel.task_state       -- wait more.
end

-------------------------------------------------------------
-- Tool event: Called whenever the tool is to be enabled
-- @ output: true|false  - tool enabled/not enabled 
--                         (will be called again until enabled!)
function _M.enable(channel)
    local cfg = channel.cfg     -- access the channel config data
    -- Do whatever is needed
    return true                 -- tool is enabled
end

-------------------------------------------------------------
-- register this tool with OGS (heLuaTool.dll)
helpers.register_tool(_M)
-- return the module
return _M
```

The following functions can be implemented as part of the `simple` LUA tool driver interface:


| Function Name | Return Type | Description | Tags |
| -------- | ----------- | ----------- | ---- |
| `init(channel: table)` | `result: string` | Is called once for each tool (channel) registered in `station.ini` for this driver. The `channel` table parameter has the `channel.tool` entry set to the channel/tool number defined in `[CHANNELS]` (from `station.ini`) and the `channel.ini_params` as a table of strings with the complete `LuaTool_...`-section from `station.ini`. Return `'OK'` on successful initialization, else an error message string. __Hint:__ The driver can add its own instance data to the `channel` table for later use. | None |
| `activate(channel: table)` | `result: boolean` | Is called whenever OGS activates a tool (i.e. the workflow switches to an action/operation where this tool is needed). The function is called cyclically until it returns `true` | None |
| `deactivate(channel: table)` | `result: boolean` | Is called whenever OGS deactivates a tool (i.e. the workflow switches to another action/operation). The function is called cyclically until it returns `true` | None |
| `enable(channel: table)` | `result: boolean` | Is called whenever the tool is active and OGS needs to enable a tool. The function is called cyclically until it returns `true` | None |
| `disable(channel: table)` | `result: boolean` | Is called whenever the tool is active and OGS needs to disable a tool (e.g. if some external condition is removed like an external enable signal). The function is called cyclically until it returns `true` | None |
| `execute(channel: table)` | `result: number` | Is called while the tool is enabled to check the tool, if it has finished. If so, the global function `lua_tool_result_response` should be called (to send result data to the OGS core) and a value of `lua_task_completed` should be returned. If the function should be called again (tool not yet finished), return `channel.task_state`. In case of an error, return `lua_task_fault` or some of the other error codes (see `lua_tool.lua` in the `lualibs` folder for details)| None |

!!! note

    To cyclically poll a tool driver (e.g. to implement network communication), implement the modules `_M.poll()` function (low-level API) or register a global StatePoll function (use `StatePollFunctions.add()` and use the (low-level API) _M.channels table to iterate your drivers registered channels).

### Tool driver formatting functions

To allow the LUA tool drivers to correctly present their values on the OGS user interface screen, the following module interface functions can be used:

-  _M.get_tool_units(): Defines the unit texts and number of digits used for formatting the tool results in the action/operation list pane. 
-  _M.get_tool_result_string(): Defines the main (large) result text shown in the bottom right corner result pane.
-  _M.get_footer_string(): Defines the footer string shown in the bottom right corner result pane.
-  _M.get_prg_string(): Defines the program string shown in the upper right corner of the bottom right corner result pane.

As the functions are part of the low-level API, they are passed the the tool number instead of the channel table (as with the simple API interface). As the LUA tool driver infrastructure keeps a list of registered channels in each tool drivers module table, this can be used to access the channel table from a given tool as follows:

``` lua
-- Get the channel table from a given tool number
_M.get_channel_from_tool = function(tool)
    local channel = _M.channels[tool]
    return channel
end
```

The following functions can be implemented for formatting:

| Function Name | Return Type | Description | Tags |
| -------- | ----------- | ----------- | ---- |
| `get_tool_units(tool: number)` | `unit1: string, unit2: string, decimals1: number, decimals2: number` | Returns the unit text and number of decimals used for showing the result values in the result list. | None |
| `get_tool_result_string(tool: number)` | `text: string` | Returns the center text shown in the result pane. | None |
| `get_footer_string(tool: number)` | `text: string` | Returns the footer text for the result pane. | None |
| `get_prg_string(tool: number)` | `text: string` | Returns the program name/number text for the result pane (the top right text). | None |

The `lua_tool_helpers` module provides a reusable implementation for formatting text by specifying a format string - and a helper function to read the format strings from the `station.ini` tool driver sections.

Here is some sample code on how to use it:

``` lua
local helpers = require('lua_tool_helpers')
local _M = {
	type = 'MyLuaTool',     -- type identifier (as in INI file)
}

-------------------------------------------------------------
-- Initialize the driver and read the parameter section
function _M.init(channel)
	-- local (tool instance specific) parameters
	local cfg = {
        -- Initialize the parameters for formatting
        fmt = helpers.read_fmt_config(channel)
    }
    channel.cfg = cfg
    return 'OK'
end

-------------------------------------------------------------
-- Get the tool specific measurement units 
-- @param tool: channel number as configured in station.ini
-- @return:  applicable only for the first two values (from 6)
_M.get_tool_units = function(tool)
	local channel = _M.channels[tool]
    return helpers.get_tool_units(channel, channel.cfg.fmt)
end
-- Get the tool specific result string
_M.get_tool_result_string = function(tool)
	local channel = _M.channels[tool]
    return helpers.get_tool_result_string(channel, channel.cfg.fmt)
end
-- Get the tool specific footer string
_M.get_footer_string = function(tool)
	local channel = _M.channels[tool]
    return helpers.get_footer_string(channel, channel.cfg.fmt)
end
-- Get the tool specific program name
_M.get_prg_string = function(tool)
	local channel = _M.channels[tool]
    return helpers.get_prg_string(channel, channel.cfg.fmt)
end
```


### Tool driver miscelaneous functions

tbd.

