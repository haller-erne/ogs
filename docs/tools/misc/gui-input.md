---
id: nexo
name: GUI Input
title: GUI Input
tags:
    - tool
    - guiInput
---

# GUI Input
 
The GUI Input tool is a custom interface that allows the operator to input values for a set of predefined parameters. It validates the entered values against their allowed ranges, and once the operator clicks the "Accept" button, the result is displayed, indicating whether the values are within the valid range or not. The GUI can accommodate up to 6 parameters for value entry.

## Installation and configuration

### OGS project configuration

OGS has an interface to add additional tool drivers by adding Windows-DLLs to the `[TOOL_DLL]` section in `station.ini`. To simplify the creation of custom tool drivers, OGS offers the heLuaTool.dll, which enables the development of tool drivers using pure LUA. With this functionality, the GUI Input tool is seamlessly integrated into OGS, see [Lua custom tools](../../v3/lua/customtools.md).

### Tool registration and configuration

According to the instructions provided in the [Lua custom tools](../../v3/lua/customtools.md), a standard configuration for the `[LuaTool_GUI_Input]` section in `station.ini` is as follows:

``` ini
[TOOL_DLL]
heLuaTool.dll=1 

[CHANNELS]
2=LuaTool_GUI_Input 

[LuaTool_GUI_Input]
DRIVER=heLuaTool
TYPE=GUI_INP
Param1 = { "name": "Param 1 m2:", "type": 'float', "default": '250', "min": '0', "max": '' }
Param2 = { "name": "Param 2 m2:", "type": 'float', "default": '0', "min": '-2000', "max": '2000' }
Param3 = { "name": "Param 3 deg:", "type": 'int', "default": '0', "min": '0.0', "max": '' }
Param4 = { "name": "Speed Km/h:", "type": 'int', "default": '0', "min": '0', "max": '' }
Param5 = { "name": "Resistence Om:", "type": 'float', "default": '300', "min": '0.0', "max": '' }
Param6 = { "name": "Height sm.:", "type": 'float', "default": '0', "min": '0.0', "max": '2000' }
```

The typical parameters are:

- `DRIVER`: The name of the windows dll that implements tool drivers.
- `TYPE`: The name of the tool driver specified in your custom LUA tool driver.
- `Param`: When creating parameters, ensure that only **6 parameters** are defined. For each parameter, specify the **type** (e.g., float or int), **min** and **max** values (if applicable), and a **default** value. These defined properties will be displayed on the GUI for the user to input their values accordingly. The **type** will determine the format of the value (e.g., numeric or integer), while the **min** and **max** values define the valid range for the input. The **default** value will be pre-filled if no user input is provided.



## Editor configuration

### Configuring the tool





### Creating a job





