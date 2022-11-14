# RemoteTool

OGS supports connecting tools over a `ToolGateway`. This enables advanced  tool management scenarios, e.g. "roaming" tools between multiple stations.

Using the `RemoteTool` driver requires a `ToolGateway` running on a server - the server then actually controls the tool, whereas the OGS stations only communication with the `ToolGateway`. This allows delegating tool management to the central `ToolGateway`. 

For each tool managed through the `ToolGateway`, OGS only uses the a generic `RemoteTool` in its local configuration, the `ToolGateway` then has the tool-specific configuration (like e.g. [OpenProtocol tools](/docs/tools/openprotocol/README.md)).

 
## Installation

The `RemoteTool` driver is implemented in `RemoteTool.dll`. To use any `RemoteTool` tool, the driver must be loaded in the `[TOOL_DLL]` section of the projects `station.ini` configuration file (see also [Tool configuration](/docs/tools/README.md)).

## Tool registration and configuration

All `RemoteTool`-tools are registered in the `[CHANNELS]` section of the projects `station.ini` file.

The `[CHANNELS]` section only defines a channel number to channel name mapping - the channel/tool specific settings are then configured in a seperate section with the channel name.  
 
 
 
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


