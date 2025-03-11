---
id: nexo
name: AIOI Pick2Light tool
title: AIOI Pick2Light tool
tags:
    - tool
    - pick2light
---

# AIOI Pick2Light tool

The AIOI Pick2Light tools are interactive communication devices associated with each shelf location, guiding the operator by clearly indicating the exact position and, if necessary, the quantity of units to be picked or placed. The hardware comes in multiple models, each featuring colored LEDs integrated into a single confirmation button. This design allows for various operational configurations, offering more flexible ways to manage tasks. For example, it enables multiple workers to operate simultaneously in the same area, with each worker assigned a unique color. It also supports preparing multiple orders at once by a single operator, with different colors assigned to each order. (links? to aioi H/W setup )

## Installation and configuration

### OGS project configuration

OGS has an interface to add additional tool drivers by adding Windows-DLLs to the `[TOOL_DLL]` section in `station.ini`. To simplify the creation of custom tool drivers, OGS offers the heLuaTool.dll, which enables the development of tool drivers using pure LUA. With this functionality, the AIOI Pick2Light tool is seamlessly integrated into OGS, see [Lua custom tools](../../v3/lua/customtools.md).

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
- `IPPORT`: Specify the port number used for communication with the controller.


## Editor configuration

### Configuring the tool

In the Tools section of the Editor, add a new tool named Pick2light and assign it to the appropriate channel (ensure the channel number matches the one specified in the `station.ini` file). Provide a name for the tool and, under the Task & Action properties section, define the following properties:
- `text`: The text to be displayed on the display
- `farbe`: The color of the confirm button
- `buzzer`: The buzzer sound setting, which can be set to 'OFF', 'ON', 'BLINK', or 'FAST_BLINK'
- `segment`: The property of the display segment

Assign a tool number to each property, as shown in the reference image below. You may also indicate the "type" for each property and provide a brief description.

![properties](resources/properties.png)



### Creating a job

To set up a job and task with the appropriate operations and tools, follow the steps below:

1. In the Jobs catalog, create a new job and then add a new task. In the operation section below, add an operation by selecting "new operation."
2. To assign an existing operation along with its tool, click the three dots next to the operation and select from the window that opens.
3. To add a new operation, provide a name for the operation and assign a tool by clicking the three dots next to the tool, which will open the tools window. From there, select the "Pick2Light" tool. It is **crucial** to set the program (Prg) value to the Pick2Light tool address (also known as the bin number). 
4. Afterward, assign the newly created operation to the task, as shown in the image below. 
5. Finally, ensure that the correct values are assigned to the properties for each task. The values for each of the properties are discussed in the next section.




![prg_specify](resources/prg_specify.png)


AIOI color, buzzer, segment properties