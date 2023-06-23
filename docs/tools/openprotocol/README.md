# OpenProtocol tools

OGS supports connecting tools with `OpenProtocol` interface. As tools differ in functionality and also different tool vendors implement the `OpenProtocol` specification in slightly different ways, OGS has special protocol handlers for the following tools:

- Rexroth Nexo and Nexo 2 wireless tools (for more information, see [Nexo OpenProtocol](/docs/tools/openprotocol/nexo.md))
- Rexroth CS351 and KE350 system tools (for more information, see [System 350 OpenProtocol](/docs/tools/openprotocol/sys350.md))
- Rexroth OPEXplus (for more information, see [OPEXplus OpenProtocol](/docs/tools/openprotocol/opexplus.md))
- GWK Operator+ torque wrenches (for more information, see [GWK Operator+ OpenProtocol](/docs/tools/openprotocol/gwk.md))
- Crane TCI torque wrenches (for more information, see [Crane OpenProtocol](/docs/tools/openprotocol/crane.md))
- Gehmeyr Exact Wifi tools (for more information, see [Gehmeyr OpenProtocol](/docs/tools/openprotocol/gehmeyr.md))
- Sturtevant Richmont Global 400 MP connected Exacta 2 digital torque wrenches (for more information, see [Sturtevant Richmond OpenProtocol](/docs/tools/openprotocol/sturtevant.md))

The overall configuration for these tools is similar and the actual driver has the same set of configuration parameters - described on this page.

To workaround various glitches in the tools concrete OpenProtocol implementation, the tools are identified by their MID0002 vendor string and their tool type name. For more details, see the [CHANNEL TYPE Parameter](#type) description in the [Channel parameter reference](#channel-parameter-reference) below. 

The supported tool types and vendor codes are:

| Tool type | Vendor code | Vendor | Comments |
| --- | ---- | ---- | ---- |
| NEXO | BRC | Bosch Rexroth | Wireless Nexo Tool |
| CS351 | BRC | Bosch Rexroth | Single channel Compact Box |
| KE350 | BRC | Bosch Rexroth | Multispindle system |
| CRANE | CEL | Crane Electronics | TCI Multi, Wrenchstar |
| GHM | GHM | Gehmeyr | GF-ION-EXACT |
| GWK | GWK | GWK | Operator+ |
| CET | CET | Sturtevant Richmond | Global 400mt controller |


## Installation

The `OpenProtocol` driver is implemented in `OpConn.dll`. To use any `OpenProtocol` tool, the driver must be loaded in the `[TOOL_DLL]` section of the projects `station.ini` configuration file (see also [Tool configuration](/docs/tools/README.md)).

## Tool registration and configuration

All `OpenProtocol`-tools are registered in the `[OPENPROTO]` section of the projects `station.ini` file.

The `[OPENPROTO]` section mixes the tool parameters and the channel mapping (due to historic reasons) by combining the channel number and the parameter name/value in the `station.ini` entry. 

Each parameter is prefixed with the channel number and followed by parameter name as follows:

    CHANNEL_<two-digit channel>_<param name>=<param value>

Where
- `<two-digit channel>` is the channel number in the range 01...99 (the channel number maps 1:1 to the tool number from the workflow configuration) 
- `<param name>` is the parameter name (see [Channel parameter reference](#channel-parameter-reference))
- `<param value>` is the actual parameter value for the given parameter

In addition to the channel-specific parameters, there are also shared parameters. These act as default parameters for the channel-specific settings and can be overridden by the channel specific values.

For more details on the shared parameters, see [Shared parameter reference](#shared-parameter-reference)) below .


A sample `OpenProtocol` tool configuration (channel 01) would therefore look similar to the following:

    [OPENPROTO]
    # Shared/default parameters
    PORT=4545
    # Channel/Tool 1 parameters
    CHANNEL_01=10.10.2.163
    CHANNEL_01_TYPE=NEXO
    CHANNEL_01_CHECK_TIME_ENABLED=1
    CHANNEL_01_NEXONAR_CHANNEL=6
    CHANNEL_01_CURVE_REQUEST=1



## Shared parameter reference

The shared parameters can be used to change the global defaults for all OpenProtocol tools. If assigned, then these settings will override the built-in defaults. Note, that a channel-specific setting will take priority anyways.

### PORT 
_(optional, defaults to 4545)_

Defines the TCP port used for OpenProtocol communication. By default uses the standard OpenProtocol port 4545. If the controller supports multiple tools through a single IP address, then typically this setting must be changed to correctly connect to the individual tool.

### CHECK_TIME_INTERVAL 

### TIME_TOLERANCE

#### EXTERNAL_IO_OFFSET



## Channel parameter reference

For specific information about a tools settings or the tools configuration needed (on the tool side), please see the tool-specific information.

The parameter names are composed of the channel prefix `CHANNEL_` followed by the channel/tool number (1-32) and the actual parameter name (e.g. `TYPE`). - see the detailed description above. 

In general, the following parameters are available for a `OpenProtocol`-tool:

#### IP 

#### PORT

(optional, defaults to the shared parameter value)

### TYPE

_(mandatory)_

The allowed tool types and their default parameters are listed in the following table:

| Tool type | Alive send rate | Response Timeout | Comments |
| ---   | ---- | ---- | ---- |
| NEXO  | 2 | 5  |  |
| CS351 | 5 | 15 |  |
| KE350 | 5 | 15 |  |
| CRANE | 1 | 5  |  |
| GHM   | 2 | 5  | MID0060 Rev 999 only, no alarms |
| GWK   | 2 | 5  | No MID0040 support, use MID0061 tool SN |
| CET   | 2 | 5  | no alarms, incorrect (+1) result ID sequence |

NOTES:
- The Alive send rate and Response timeout default parameter values can be overridden by the [ALIVEXMTT](alivexmtt) and [RSPTIMEOUT](rsptimeout) parameters. 
- All tools use a slightly different set of MIDs to control operation, e.g. some do support alarms, others don't or allow different revisions of the MID commands.
- For Nexo with firmware < V1500, a Alive send rate of 1000ms or less is recommended to ensure stable WiFi operation
- For CS351 and KE350, do not use a Alive send rate less than 5 second, else the controller may become unresponsive 


#### CCW_ACK

#### PARAMS

#### ALIVEXMTT

#### SHOWALIVE

#### RSPTIMEOUT

#### BARCODE_MID0051_REV

#### CHECK_EXT_COND

#### APPL_START

#### CURVE_REQUEST

#### CHECK_TIME_ENABLED

#### IGNORE_ID


