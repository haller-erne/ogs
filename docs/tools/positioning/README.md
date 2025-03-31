---
id: positioning
name: Positioning
title: Tool Tracking and Positioning
tags:
    - positioning
---

# Tool Tracking and Positioning

## Overview

Tool tracking (and positioning) is used to ensure that a tool is working on the correct task by locating tool and/or workpiece in 3D space. The general idea is to only enable a tool, if it is in the correct position - to prevent operating (tightening) on the wrong task/bolt and to ensure reproducible documentation of the tightening results of all bolts. In other workds, the tool is disabled until the tools position (and orientation) in relation to the parts position/orientation is in the correct range. The concept is pretty generic, so there are quite a few use cases:

- Using a 3D tracking system to track the position and orientation of a tool
- Using mechanical guides or handling systems for e.g. tightening tools including sensors to measure its position
- Use simple digital I/O sensors for detecting a parts position or locking state

## Supported systems

OGS supports the following systems for tool and position tracking:

- [ART DTrack](https://ar-tracking.com/en/product-program/products-connection-software-dtrack) realtime high precision infrared camera based tool tracking with passive (and active) markers. Can be flexibly used with different tool types and models (tightening, riveting, hand-tracking using gloves) due to the passive markers. Provides a large range of applications and covered space through the available range of cameras: from plug-and-play pre-calibrated stero cameras for a quick start in typical single-user assembly stations up to large multi-camera setups for covering huge areas. Highly integrated into OGS including teching and tolerance definitions through the OGS gui.
- [ART Verpose](https://ar-tracking.com/en/product-program/products-connection-software-verpose) tool mounted camera for object detection and identification. Primarily used for (but not limited to) locating bolts on a part.
- [Sarissa local positioning system](https://www.sarissa.de/en/solutions/local-positioning-system) ultrasonic RTLS positioning system. Uses active tags mounted on a tool (or glove) for sending out ultrasonic waves, which are triangulated using microphones mounted in the station.
- [Nexonar RTLS](https://www.nexonar.com/en/solutions/real-time-location-system) realtime precision infrared camera based tool tracking with active tags sending our infrared light. Provides a scalable setup starting with a single camera and can be extended to multi-camera setups to cover a larger working range. 
- Linear and rotational sensors connected over Fieldbus (Ethernet/IP, Modbus/TCP, IO-Link) for tool mounts, e.g. [Jäger Handling HandyFlex](https://www.jaeger-handling.de/handy-flex?lang=en) (see the availables [sensors](https://www.jaeger-handling.de/carbo-arm/equipment-options-carbo-arm/positions-transducer-swivel-and-telescopic-axis?lang=en)) or other tool arms.
- Simple digital sensors connected over Fieldbus (Ethernet/IP, Modbus/TCP, IO-Link) for detecting, if the tool or the part is in the correct position. This can also be used to connect other positioning systems with digital I/O signals (e.g. [Jäger HandyTrack 200](https://www.jaeger-handling.de/carbo-arm/equipment-options-carbo-arm/positions-transducer-swivel-and-telescopic-axis/handy-track-200?lang=en)) or the [Sarissa PositionBox](https://www.sarissa.de/loesungen/positionbox).

## OGS usage

### Overview

As the underlying idea for positioning is to enable the tool depending on some external information, this is actually similar to the concept of a socket tray / nut selector (enable the tool only, if the correct socket was used): both only enable the tool, if the correct conditions are met. OGS shows the state of "external enable", "socket tray selection" and "positioning" in the same spot in the OGS runtime GUI - next to the tools tile in the status bar.

Here is a sample screenshot of the OGS toolbar when the tool is not in the correct position (expected position 5 - yellow background):

![OGS monitor positioning](resources/monitor-tile-positioning.png)

As all three conditions might be required, OGS processes the information in a sequence:

1. Check if the correct socket is used (if any)
2. If a correct socket is available (or no check active), check the position
3. If the position is ok, check any additional external signals (external enable)

If any of the preconditions fail, then OGS jumps back in the sequence to the first missing condition - e.g. if the socket is switched while in the correct position, OGS again shows the socket request.

Conceptionally, positioning is connected to the bolts position on the part, whereas the socket information belongs to the tightening operation (i.e. likely the same for all bolts with the same tightening parameters). OGS therefore uses different spots in the GUI of the workflow editor to configure these parameters (external enable is scripting only):

![heOpCfg positioning configuration](resources/heOpCfg-positioning-and-sockets.png)

A task is marked as positioning-enabled by setting the task parameter Position sensor(PS) (column PS in the jobs editor tasks list) to a non-zero value. If a tasks PS-value is set to zero, then the position is not tracked for the task.

!!! note

    If you can't see the PS column, then use `Database --> Settings` and check 
    the"Use Position Encoder" in the Job section or set the `POSITION_ENCODER_IN_USE` in the GLOBAL-Section of the INI Parameters on the Tools tab to 1 - see the bottom part of the screenshot above)

### Project configuration

Starting with OGS V3.1, the positioning drivers are included in the installation (`<installdir>\lualib\libpositioning`). To use these drivers, include the `lib.positioning` file in your project (through the `config.lua` requires list or 
directly by adding a `require('lib.positioning)` somewhere in the code).

!!! note

    OGS provided lua files are referenced from a lib subfolder, to include the positioning.lua file, you must therefore reference it as `lib.positioning`! This allows backwards compatibility with identically named files from the project!

Adding it to the `requires` table in the projects `config.lua` will then look as follows:

```  lua hl_lines="7"
-- add the shared folder (..\shared)
OGS.Project.AddPath('../shared')

requires = {
	"barcode",
	"user_manager",
	"lib.positioning",      -- (1)
}
current_project.logo_file = '../shared/logo-rexroth.png'
current_project.billboard = 'http://127.0.0.1:60000/billboard.html'
```
1.  Add this line to include the `positioning.lua` driver in the project.

The `positioning.lua` file automatically scans the `[OPENPROTO]` section for `CHANNEL_XX_POSITIONING=<section>` parameters. It also scans the `[CHANNELS]` section and looks for `POSITIONING=<section>` parameters for custom tools. If found, then the `<section>` is read. The section is expected to contain the `DRIVER=` parameter (to select the actual hardware) driver, as well as the driver-specific parameters for this specific tool. Note, that the driver itself might need some parameters (in its own section in `station.ini`, e.g. the `[POSITION_ART]` section as shown below).

Here is a sample fragment on how to configure an OpenProtocol tool with the AR-Tracking driver (see [available drivers](#available-drivers) below and [ART SmartTrack](./positioning-art-dtrack.md) for detailed info):

``` ini
[OPENPROTO]
CHANNEL_01=192.168.1.42
CHANNEL_01_TYPE=GWK
CHANNEL_01_PORT=4002
; --> this channel shall use ART positioning
CHANNEL_01_POSITIONING=POSITIONING_ART_CH1

; --> Connection between the CHANNEL_01 and the ART positioning system
[POSITIONING_ART_CH1]
; Define to use the AR.Tracking positioning system with this channel
DRIVER=ART
; Positioning timeout in milliseconds. Defines the grace time before enable
; is removed for the tool, when leaving a position. If not set, defaults to 0.
TIMEOUT=1000
; Define the target tracker and tool adapter for this tool
; Target-ID: this is the model of the target mounted to the tool. By default,
; T1-T8 are provided, other targets can be defined in "targets.atti"-file 
TARGET_ID=T5
; Target-Mount-ID: specify the adapter geometry, so the ART driver can calulate
; the tool center point depending on where the target is mounted on the tool.
; By default, "Rexroth ESA030G" and "GWK Operator Plus" are provided, custom
; mounts may be added in "targetmounts.atti"
TARGET_MOUNT_ID=Rexroth ESA030G
; Default-length of the adapter mounted to the tool (tool center point)
OFFSET_MM=0

; --> common parameter required by the ART driver
[POSITIONING_ART]
; Define the IP-Address of the SmartTrack camera system
IP=10.10.2.108
; If you want to use custom targets or custom target_mounts, then you can
; specify these in "targets.atti" and "targetmounts.atti" in the following
; folder. If the folder is not specified, it defaults to the current projects
; folder.
;DB_FOLDER=
; If you want to set the reference tracker, then add the name of the tracker here.
; NOTE: the reference tracker must be configured through DTrack and *must* have
;       then name "reference" or "referenz" (case insensitive) as part of the
;       body name, else it will not be accepted.
REFERENCE_TRACKER=Claw Target 21 Reference
```

To add a positioning system to a LUA tool (see [LUA custom tools](/ogs/v3/lua/customtools/)), a slightly different syntax is needed. In this case, the `POSITIONING=<section>` must be added to the tools configuration section. Here is a sample:

``` ini
[CHANNELS]
1=LuaTool_MyTool

[LuaTool_MyTool]
; standard LUA tool parameters:
DRIVER=heLuaTool
TYPE=...
; add positioning:
POSITIONING=MyTool_PosiConfig

; --> Connection between the LUA tool and the ART positioning system
[MyTool_PosiConfig]
; Define to use the AR.Tracking positioning system with this channel
DRIVER=ART
; ... more parameters

; --> common parameter required by the ART driver
[POSITIONING_ART]
; ... more parameters
```

### Available drivers

Currently, the following drivers are shipped with the OGS installer:

- `ART`: Driver for the [AR-Tracking SmartTrack3 realtime tracking system](https://ar-tracking.com/en/product-program/smarttrack3), see [ART SmartTrack](./positioning-art-dtrack.md) for details.
- `IO`: Driver for the rotation + distance type systems (like the Jäger HandyFlex)  with optional support for tilt. Note that this driver requires providing some LUA glue code to read the sensors values from e.g. a field bus and forwarding the raw
sensor values to the driver by calling `UpdatePos_RotIncLenInc()` or `UpdatePos_RotIncLenAbs()`. The driver then handles coordinate transforms, teaching and tolerance calculations internally. See [IO positioning](./positioning-io.md) for details.
- `DIGITAL`: Minimal positioning driver, which only uses a single "Inpos" signal. Note that this driver requires providing some LUA glue code to generate the "Inpos" signal (typically by reading I/O values from e.g. a field bus) and thencalling the drivers `UpdatePos_InPos()` function. This can be used to connect exisiting positioning systems or implement own logic based on digital input combinations. See [digital positioning](./positioning-digital.md) for details.

Other positioning systems mentioned above (like [ART Verpose](https://ar-tracking.com/en/product-program/products-connection-software-verpose), [Sarissa local positioning system](https://www.sarissa.de/en/solutions/local-positioning-system), [Nexonar RTLS](https://www.nexonar.com/en/solutions/real-time-location-system), ...) are typically implemented using the `DIGITAL` driver, see details here:

- [ART Verpose](./positioning-art-verpose.md)
- [Sarissa PositionBox](./positioning-sarissa-digital.md)

### Customization

To add a custom driver, use one of the existing drivers as a base and override its
functions.

If the LUA module file name adheres to the driver naming convention (module name is `positioning_<drivername>.lua`), then the driver will automatically load, if `DRIVER=<drivername>` is given in `station.ini`.
