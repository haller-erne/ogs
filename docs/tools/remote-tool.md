# RemoteTool

OGS supports connecting tools over a `ToolGateway`. This enables advanced  tool management scenarios, e.g. "roaming" tools between multiple stations.

Using the `RemoteTool` driver requires a `ToolGateway` running on a server - the server then actually controls the tool, whereas the OGS stations only communication with the `ToolGateway`. This allows delegating tool management to the central `ToolGateway`. 

For each tool managed through the `ToolGateway`, OGS only uses the a generic `RemoteTool` in its local configuration, the `ToolGateway` then has the tool-specific configuration (like e.g. [OpenProtocol tools](/docs/tools/openprotocol/README.md)).

 
## Installation

The `RemoteTool` driver is implemented in `RemoteTool.dll`. To use any `RemoteTool` tool, the driver must be loaded in the `[TOOL_DLL]` section of the projects `station.ini` configuration file (see also [Tool configuration](/docs/tools/README.md)).

To enable the driverin station.ini, set it as follows:

    [TOOL_DLL]
    RemoteTool.dll=1

The overall parameters for the `RemoteTool` driver are configured in the ´[RemoteTool]` section. This is basically used to configure the `ToolGateway` connection parameters, here is a sample setup:

    [RemoteTool]
    ToolGateway_Addr=mytoolgateway.mycompany.com
    ToolGateway_Port=

For more information about the driver parameters, see [Driver Parameters](#driver-parameter-reference) below.

## Tool registration and configuration

All `RemoteTool`-tools are registered in the `[CHANNELS]` section of the projects `station.ini` file.

The `[CHANNELS]` section only defines a channel number to channel name mapping - the channel/tool specific settings are then configured in a seperate section defined by the channel name. Inside the section, a reference to the `RemoteTool` driver then links driver and channel accordingly.
 
The overall layout is therefore as follows (sample is for channel 2):

    [CHANNELS]
    # Map the channel/tool 2 to the 'RemoteTool_Nexo1'-section
    2=RemoteTool_Nexo1

    [RemoteTool_Nexo1]
    # link to the RemoteTool driver
    DRIVER=RemoteTool
    # more channel/tool specific parameters for this tool/driver

Please see [Channel/tool parameter reference](#channeltool-parameter-reference) below for more information about the available parameters.


## Channel/tool parameter reference

Currently, there are no channel/tool-specific parameters needed (other than specifying the `DRIVER=RemoteTool`) to use this driver. All concrete tool communication settings are to be configured on the `ToolGateway` server side. 


## Driver parameter reference

The driver parameters are defined in the `[RemoteTool]` section in the projects `station.ini`.

The following parameters are available:

#### ToolGateway_Addr

IP address or hostname of the tool gateway.

#### ToolGateway_Port

(optional)

Port number to use for connecting to the tool gateway. If not given, the driver tries to use the RPC endpoint mapper using the service UUID to resolve the connection endpoint (might require additional firewall settings).

