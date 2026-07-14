---
id: socketTray
name: LuaSupportforSocketTrays
title: Lua Support for Socket Trays
tags:
    - tool
    - socket trays
---

# Lua Support for the MSTKN Socket Trays
The MSTKN socket trays functionality is currently extended with the help of Lua support. Previously, the socket groupings were serially restricted, with sockets assigned to tools in sequential blocks (e.g., sockets 1-4 mapped to tool 1, sockets 5-8 to tool 2). This limitation meant that you could not map a socket out of sequence—such as mapping socket 9 to tool 1 if tool 1 had already been assigned sockets 1-4. However, with the introduction of Lua support, this serial restriction has been removed, allowing for more flexible mapping. Now, any socket can be mapped to any tool, regardless of its numerical order (e.g., tool 1 can now include sockets 1, 8, 7, and 5). 

## Modes
In order to implement this feature, the functionality has been classified into two modes: Mode 1 and Mode 2, as discussed below:

<!--### Tool inactive case?-->

### Mode 1: Socket Mapping and LED Behavior

In *Mode 1*, tools/channels are assigned to specific sockets. Only the assigned sockets are active when the tool is active, while all other sockets remain inactive. Here's how the socket tray LEDs behave:

- **Active Sockets**: These are illuminated in yellow.
- **Socket to be Picked**: The socket that needs to be selected is blinking green.
- **Inactive Sockets**: All other sockets in the tray are turned off.

**Behavior Flow**:
1. When the tool is active, only the assigned sockets are lit up in yellow.
2. The socket that should be picked will blink green.
3. Once the correct socket is picked, it switches from blinking green to green.
4. If the wrong socket is picked, it changes from yellow to red, indicating an error state.

In *Mode 1*, any number of sockets can be mapped to each tool, and these mappings can overlap.

---

### Mode 2: For Multi-Spindle Tightening Tool and LED Behavior

*Mode 2* is designed for multi-spindle tightening tools, where two sockets can be picked at the same time. The sockets to be picked are specified in the `station.ini` file under the respective application number (discussed in detail later). Here's how the LED behavior works in this mode:

- **Active Sockets**: These are the sockets that are active for the tool in mode2 and are illuminated in yellow.
- **Socket to be Picked**: These sockets are blinking green.
- **Other Sockets in Tray**: All other sockets in the tray are turned off.

**Behavior Flow**:
1. The sockets that should be picked will blink green.
2. Once the correct socket is picked, it changes from blinking green to green.
3. If the wrong socket is picked, it changes from yellow to red, indicating an error state.

The only restriction, in general, is that channels cannot be in both Mode 1 and Mode 2 at the same time.



## OGS project configuration

To enable Lua support for the socket trays, place the Lua script in the project folder and then add the script name under the "requires" section in the config.lua file.
### Configuring station.ini 
``` ini title="station.ini"
[SocketTray]
ENABLED = 1
Groups = 16
Map = 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 
TCP=<tool ip address>
PORT=502


[Lua_Channel_to_Socket_Map]
;Channels cannot be in both mode1 and mode2 simultaneously.
MODE1=1,2

;Assign sockets to each channel in mode-1
CHANNEL_01=1, 2, 3, 4, 5, 6, 7, 8, 14, 15, 16
CHANNEL_02=9, 10, 11, 12, 13

MODE2=3
;the application number should match the program number specified in the OGS Editor
APPL_01=1,2
APPL_02=1,3  
APPL_03=1,4
APPL_04=5,6
APPL_05=5,7
APPL_06=5,8
APPL_07=5,9
APPL_08=5,10
APPL_09=5,11
APPL_10=5,12
```


In the updated **station.ini** file, the **SocketTray** section now only requires configuration with the following parameters:

- `ENABLED`: This value specifies whether the SocketTray is activated (1 for enabled, 0 for disabled).
  
- `Groups`: This value defines the total number of sockets.
  
- `Map` (optional): This field provides the mapping of the sockets of serial trays.

- `TCP or IP`: The IP address of the tool is entered here, allowing the system to connect to the tool.

- `PORT`: This defines the communication port used to connect to the tool. The default is usually port 502 for TCP connection and 5003 for UDP connection.

Additionally, a new section needs to be added - **Lua_Channel_to_Socket_Map** for channel and socket mapping:

- `MODE1`: This section defines the channels that are mapped to `Mode 1`. The specified channels cannot be assigned to `Mode 2` simultaneously.
  
- `CHANNEL_01 .. CHANNEL_02`: This defines the specific sockets assigned to channels in **Mode 1**. 

- `MODE2`: This section assigns a single channel to **Mode 2**. Only one channel can be assigned to **Mode 2** at a time. If multiple channels are listed, only the first channel will be considered, and the rest will be ignored.

- `APPL_01, APPL_02, etc.`: These fields map application numbers (which should match the program numbers in the OGS Editor) to the channel in **Mode 2**. Each entry pairs the application with the sockets to be picked.



## Editor configuration


To use the socket tray, enable the "Use socket tray" option in the **Editor** settings. Next, create a job, tasks, and operations in the **Jobs catalog** of the Editor. For each operation, assign the appropriate tool (make sure the tool/channel number matches the number provided in the **station.ini** file). 

For tools in **Mode 1** (as specified in the **ini** file), assign the corresponding socket number. This number indicates which socket should be picked during the operation, and it must be from the list of sockets assigned to that tool/channel in the **ini** file. 

For tools in **Mode 2**, specify the program number, which should match the **application number** listed in the **ini** file. Ensure that the program number aligns with the values in the **ini** file. Provide a socket number, which appears on the OGS during the operation.

Any discrepancy between the configuration and the `station.ini` file will trigger the corresponding alarms.

Finally, create a new family and assign the job to it.

<!--H/W setup details?-->