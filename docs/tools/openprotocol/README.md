# OpenProtocol tools

OGS supports connecting tools with `OpenProtocol` interface. As tools differ in functionality and also different tool vendors implement the `OpenProtocol` specification in slightly different ways, OGS has special protocol handlers for the following tools:

- Rexroth Nexo and Nexo 2 wireless tools (for more information, see [Nexo OpenProtocol](/docs/tools/openprotocol/nexo.md))
- Rexroth CS351 and KE350 system tools (for more information, see [System 350 OpenProtocol](/docs/tools/openprotocol/sys350.md))
- GWK Operator+ torque wrenches (for more information, see [GWK Operator+ OpenProtocol](/docs/tools/openprotocol/nexo.md))
- Crane TCI torque wrenches (for more information, see [Crane OpenProtocol](/docs/tools/openprotocol/crane.md))
- Gehmeyr Exact Wifi tools (for more information, see [Gehmeyr OpenProtocol](/docs/tools/openprotocol/gehmeyr.md))

The overall configuration for these tools is similar and the actual driver has the same set of configuration parameters - described on this page.

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

#### PORT

(optional, defaults to 4545)

#### EXTERNAL_IO_OFFSET

#### CHECK_TIME_INTERVAL and TIME_TOLERANCE

#### EXTERNAL_IO_OFFSET



## Channel parameter reference

For specific information about a tools settings or the tools configuration needed (on the tool side), please see the tool-specific information.

In general, the following parameters are available for a `OpenProtocol`-tool:

#### Connection information

#### PORT

(optional, defaults to the shared parameter value)

#### TYPE

(mandatory)

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


