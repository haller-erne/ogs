# OpenProtocol tools

## Overview

OGS supports connecting tools with `OpenProtocol` interface. As tools differ in functionality and also different tool vendors implement the `OpenProtocol` specification in slightly different ways, OGS has special protocol handlers for the following tools:

- Rexroth Nexo and Nexo 2 wireless tools (for more information, see [Nexo OpenProtocol](/docs/tools/openprotocol/nexo.md))
- Rexroth CS351 and KE350 system tools (for more information, see [System 350 OpenProtocol](/docs/tools/openprotocol/sys350.md))
- Rexroth OPEXplus (for more information, see [OPEXplus OpenProtocol](/docs/tools/openprotocol/opexplus.md))
- GWK Operator+ torque wrenches (for more information, see [GWK Operator+ OpenProtocol](/docs/tools/openprotocol/gwk.md))
- Crane TCI torque wrenches (for more information, see [Crane OpenProtocol](/docs/tools/openprotocol/crane.md))
- Gehmeyr Exact Wifi tools (for more information, see [Gehmeyr OpenProtocol](/docs/tools/openprotocol/gehmeyr.md))
- Sturtevant Richmont Global 400 MP connected Exacta 2 digital torque wrenches (for more information, see [Sturtevant Richmond OpenProtocol](/docs/tools/openprotocol/sturtevant.md))
- HS-Technik riveting tool

The overall configuration for these tools is similar and the actual driver has the same set of configuration parameters - described on this page.

To workaround various glitches in the tools concrete OpenProtocol implementation, the tools are identified by their MID0002 vendor string and their tool type name. For more details, see the [CHANNEL TYPE Parameter](#type) description in the [Channel parameter reference](#channel-parameter-reference) below. 

The supported tool types and vendor codes are:

| Tool type | Vendor code | Vendor | Comments |
| --- | ---- | ---- | ---- |
| NEXO | BRC | Bosch Rexroth | Wireless Nexo Tool |
| CS351 | BRC | Bosch Rexroth | Single channel Compact Box |
| KE350 | BRC | Bosch Rexroth | Multispindle system |
| OPEX | (GWK) | Bosch Rexroth | OPEXplus torque wrench |
| CRANE | CEL | Crane Electronics | TCI Multi, Wrenchstar |
| GHM | GHM | Gehmeyr | GF-ION-EXACT |
| GWK | GWK | GWK | Operator+, Operator22 |
| CET | CET | Sturtevant Richmond | Global 400mt controller |
| BTC | BTC | HS-Technik | NutBee riveting tool |
| ATG | ATG | Cleco | Cleco wifi battery tool |

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

## OpenProtocol driver parameters reference

### Shared parameter reference

The shared parameters are used to change the global defaults for all OpenProtocol tools. If assigned, then these settings will override the built-in defaults. Note, that a channel-specific setting will take priority anyways.

#### PORT 
_(optional, defaults to 4545)_

Defines the TCP port used for OpenProtocol communication. By default uses the standard OpenProtocol port 4545. If the controller supports multiple tools through a single IP address, then typically this setting must be changed to correctly connect to the individual tool.

#### CHECK_TIME_INTERVAL 
_(optional, defaults to 5 [minutes])_

Defines the time [in minutes] when OGS shall check the tools clock. This setting is only used, if time synchronization is enabled for the tool (see [CHANNEL_[TOOL]_CHECK_TIME_ENABLED](#channel_tool_check_time_enabled) below).

#### TIME_TOLERANCE
_(optional, defaults to 5 [seconds])_

Defines the maximum allowed time difference [in seconds] before OGS corrects
the tools realtime clock. This setting is only used, if time synchronization is enabled for the tool (see [CHECK_TIME_ENABLED](#check_time_enabled) below).

#### EXTERNAL_IO_OFFSET
_(optional, defaults to 0)_

This setting enables custom IO access (through LUA) over the OpenProtocol interface. This can be used to read physical inputs and set physical outputs connected to the controller over OpenProtocol.

Depending on the tool, different MIDs are used - to enable this for CS351 and KE350, set it to 2.

### Channel parameter reference

For specific information about a tools settings or the tools configuration needed (on the tool side), please see the tool-specific information.

The parameter names are composed of the channel prefix `CHANNEL_` followed by the channel/tool number (1-32) and the actual parameter name (e.g. `TYPE`). - see the detailed description above. 

In general, the following parameters are available for a `OpenProtocol`-tool:

#### CHANNEL_[tool]_IP 
_(mandatory)_

This setting defines the IP address to use for communication with the tool.

#### CHANNEL_[tool]_PORT
_(optional, defaults to the shared parameter value)_

See [PORT](#port) in the [shared parameter reference](#shared-parameter-reference).

#### CHANNEL_[tool]_TYPE
_(mandatory)_

The allowed tool types and their default parameters are listed in the following table (see the [overview section](#overview) above for tool details):

| Tool type | Alive send rate | Response Timeout | Comments |
| ---   | ---- | ---- | ---- |
| NEXO  | 2 | 5  |  |
| CS351 | 5 | 15 |  |
| OPEX  | 2 | 5  | No MID0040 support, use MID0061 tool SN |
| KE350 | 5 | 15 |  |
| CRANE | 1 | 5  |  |
| GHM   | 2 | 5  | MID0060 Rev 999 only, no alarms |
| GWK   | 2 | 5  | No MID0040 support, use MID0061 tool SN |
| CET   | 2 | 5  | no alarms, incorrect (+1) result ID sequence |
| BTC   | 2 | 5  |  |
| ATG   | 2 | 5  |  |

NOTES:
- The Alive send rate and Response timeout default parameter values can be overridden by the [CHANNEL_[tool]_ALIVEXMTT](#channel__alivexmtt) and [CHANNEL_[tool]_RSPTIMEOUT](#channel__rsptimeout) parameters. 
- All tools use a slightly different set of MIDs to control operation, e.g. some do support alarms, others don't or allow different revisions of the MID commands.
- For Nexo with firmware < V1500, a Alive send rate of 1000ms or less is recommended to ensure stable WiFi operation
- For CS351 and KE350, do not use a Alive send rate less than 5 second, else the controller may become unresponsive 

#### CHANNEL_[tool]_CCW_ACK
_(optional, default = 0 (disabled))_

Defines, if the operator must select a loosen operation on the tool end (for
tools having a CW/CCW switch which is accessible over OpenProtocol). Currently only Rexroth Nexo, CS351 and KE350 support this feature.

The following settings are available:

- 0: Disabled. OGS select a CCW program automatically
- 1: Enabled. Operator must switch to CCW manually 

#### CHANNEL_[tool]_ALIVEXMTT
_(optional, default defined by tool type (see above))_

Defines how often OGS shall send an `ALIVE` data packet (`MID9999`) to the tool to check for connectivity. The value is given in milliseconds.

If OpenProtocol communication is received from the tool within 3 times of
this time setting, then the connection with the tool is considered
disconnected. In this case, OGS shuts down the connection and tries to reconnect. 

#### CHANNEL_[tool]_RSPTIMEOUT
_(optional, default defined by tool type (see above))_

Defines how long OGS shall wait for an OpenProtocol command response from 
the tool before considering the connection as disconnected. The value is 
given in milliseconds.

If no answer for a command sent by OGS to the tool is received within this time setting, then the connection with the tool is considered disconnected. 
In this case, OGS shuts down the connection and tries to reconnect.

#### CHANNEL_[tool]_BARCODE_MID0051_REV
_(optional, default = 0 (disabled))_

If set to a nonzero value, the `MID0051` (ID-Code change) subscription is 
enabled. This can be used to read ID-Codes through a barcode scanner built into the tool (instead of using a seperate scanner).

See the tool-specific documentation about how to enable barcode scanning with
ID-Code forwarding.

#### CHANNEL_[tool]_CHECK_EXT_COND
_(optional, default = 0 (disabled))_

Defines, how the tool enable shall follow the OGS enable signal. The following 
options are available:

- 0: Only check the enable once for each tool operation. 
- 1: Cyclically check the enable while a tool operation is active. 

#### CHANNEL_[tool]_APPL_START
_(optional, default = 0 (single channel mode))_

If set to a nonzero value, OGS uses multispindle (fastening application) mode 
to control the tool. This also changes other behaviour for the communication,
e.g. uses `MID0100` to subscribe for results instead of `MID0060` (for single
channel results).

See [System 350 OpenProtocol](/docs/tools/openprotocol/sys350.md) for more info about multi-spindle mode and how to set it up.

#### CHANNEL_[tool]_CURVE_REQUEST
_(optional, default = 0 (disabled))_

If set to a nonzero value, OGS requests the tightening curve data after a 
rundown has completed. 

NOTES: 

- Depending on the tool type, this introduces significant delays for the
tightening operation!
- If curves are only needed for validation purposes, then [Tool mirroring/twins](#tool-mirroringtwins) can be set up with different parameters for the main and the mirrored tool!

#### CHANNEL_[tool]_CHECK_TIME_ENABLED
_(optional, default = 0 (disabled))_

If set to a nonzero value, OGS checks the tools realtime clock and adjusts it,
if the time delta between the OGS system time and the tools system time is tool large.

See the [shared parameter section](#shared-parameter-reference) for more parameters related to time synchronization.

#### CHANNEL_[tool]_IGNORE_ID
_(optional, default to the tool type)_

Set to a nonzero value to ignore the tightening result ID returned in the tightening results from the tool. OGS expects and validates, that each rundown
of a tool uses an incrementing tightening result ID to ensure no lost or out of
sync tightening results. However, some tools have a flaky implementation so there is an option to disable these checks.

#### Debugging settings

##### CHANNEL_[tool]_SHOWALIVE
_(optional, default = 0 (disabled))_

Set to nonzero to log `MID9999` (alive) messages in the OGS ETW logs.

##### CHANNEL_[tool]_PARAMS
_(internal, default depending on tool type)_

## Tool mirroring/twins

(tbd).
