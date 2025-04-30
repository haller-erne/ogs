---
id: sylvac
name: SylvacBleMeters
title: Sylvac bluetooth low energy tools
tags:
    - tool
    - ble
---

# Sylvac Bluetooth low energy tools

The AIOI Pick2Light system is an interactive tool that helps operators by clearly indicating the specific shelf location and, when needed, the quantity of items to be picked or placed. Available in several models, each unit features colored LEDs and a single confirmation button, offering versatile configurations to efficiently manage tasks. <!--links? to aioi H/W setup-->

## Installation and Configuration with OGS

### OGS project configuration

OGS has an interface to add additional tool drivers by adding Windows-DLLs to the `[TOOL_DLL]` section in `station.ini`. To simplify the creation of custom tool drivers, OGS offers the heLuaTool.dll, which enables the development of tool drivers using pure LUA. With this functionality, the AIOI Pick2Light tool is seamlessly integrated into OGS, see [Lua custom tools](../../v3/lua/customtools.md) for more info.

### Tool registration and configuration

According to the instructions provided in the [Lua custom tools](../../v3/lua/customtools.md), a standard configuration for the `[LuaTool_Pick2Light]` section in `station.ini` is as follows:

``` ini
[TOOL_DLL]
heLuaTool.dll=1 

[CHANNELS]
20=LuaTool_Pick2Light 

[LuaTool_Pick2Light]
DRIVER=heLuaTool
TYPE=LUA_FLOWLIGHT
IPADDR=controller_IPADDR
IPPORT=controller_IPPORT
```

The typical parameters are:

- `DRIVER`: The name of the windows dll that implements tool drivers.
- `TYPE`: The name of the tool driver specified in your custom LUA tool driver.
- `IPADDR`: Specify the IP address used for communication with the controller. 
- `IPPORT`: Specify the port number used for communication with the controller (the default port number is 5003).



``` ini
[LuaTool_SYLVAC]
;DRIVER=heLuaTool
; NOTE: for custom LUA too000000000lsMSN0000ls implemented through "heLuaTool", the LUA script
;       file used to provide the implementation of the tool interface is 
;       identified through the "TYPE" set here.
; To use the TYPE=BLE_SYLVAC, you should also add "lua_tool_ble_sylvac" in config.lua
;TYPE=BLE_SYLVAC
;BLE_PORT=COM3
;BLE_MAC=c1:04:68:b0:14:a4
; NOTE: If BLE_CYCLIC_READ is nonzero, then the given handle is read cyclically.
;       Note also, that the GUI then switches to "manual input", i.e. the cyclic
;       data read is displayed in the panel and the user must acknowledge the value
;       to continue to the next step.
;BLE_TOOLTYPE=SYL250_OLD_BUTTON
;BLE_CYCLIC_READ=0
; If cyclic read is active (therefor the GUI is shown), you can set a measure label here:
;GUI_LABEL=Measure [mm]
; NOTE: for "new" Sylvac calipers, devices in "paired" mode required "encrypted" communication
;BLE_ENCRYPT=0
; 0 = public, 1 = (default) random
;BLE_MAC_TYPE=1

; The following setup is for Calipers of type S_CAL Evo with old bluetooth module.
; These devices do not support "paired mode" and "cyclic mode". Data is read whenever
; the data button is clicked on the tool.
; To identify the tool, press the MODE button for 2 seconds. Old devices will not enter
; a menu.
DRIVER=heLuaTool
TYPE=BLE_SYLVAC
BLE_PORT=COM5
BLE_MAC=c1:04:68:b0:14:a4
; Define the correct tooltype here:
BLE_TOOLTYPE=SYL250_OLD_BUTTON
BLE_CYCLIC_READ=0
GUI_LABEL=Length [mm]
BLE_ENCRYPT=0
``` 