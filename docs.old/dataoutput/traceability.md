---
id: events
name: Traceability
title: Traceability
tags:
    - dataoutput
---

# Traceability

## Overview

In OGS, the term `Traceability` refers to sending out tool results in JSON format, similar to 
the Rexroth Nexo, CS351 and KE350 tools. This feature allows tools, which do not support
their own detailed and buffered data output (e. g. most electronic torque wrenches), to 
connect to common 3rd party data colletion and analysis systems in the same way as the 
Rexroth tools do (including graph data, if the tool provides this).

In addition to providing industry standard data output for 3rd party tools, OGS also generates
traceability data for its inbuilt tools. Data can be generated for barcode scans, acknowledge
actions and even for user logon/logoff in the same standardized JSON format.  

The `Traceability` feature aims to provide all data in near-realtime and in a high data
quality for 3rd party systems for full process documentation and insight. All data is buffered locally before sending it out over FTP/http to the consuming server to ensure guaranteed
delivery of all process events.

Here is an overview of the system setup:

![Traceability](./traceability.drawio.svg)


## Usage

Traceability is configured in `station.ini` in the `[FTP_CLIENT]` section.
A typical setup is as follows:

``` ini
[FTP_CLIENT] ; or [HTTP_CLIENT], see below
; Set ENABLED=1 to enable traceability data output
ENABLED=1
; Set ReportSkippedOperations=1, if you want to see operators skip actions
; in the traceability data output, else set to =0
ReportSkippedOperations=1

; Define the targets FTP (Sys3xxGateway) server IP-Address and port
HostIP=10.80.59.252
HostPort=21

; In case of Sys3xxGateway(Qtrans) as FTP server use "Username=sys3xx" and
; "Password=sys3xx". TargetFolderOnHost is not needed (ignored) then.
Username=sys3xx
Password=sys3xx

; In case of standard FTP Server the "TargetFolderOnHost" parameter must 
; be set
TargetFolderOnHost=

; Temporary folder for storing result data files on local machine
DIRECTORY=C:\Bosch Rexroth AG\tempData

; Channel info in JSON format 
CHANNEL_99_INFO={ "IP": "", "ChannelName": "WS010|CHANNEL_INFO", "tool serial":	123456, "location name": ["Tool", "Line 2", "WS010", "default", "", "", ""] }
CHANNEL_01_INFO={ "IP": "10.80.59.231",  "ChannelName": "WS010|AC_PF6000", 	"tool serial":	"B5780438", "location name": ["Tool", "Line 2", "WS010", "default", "", "", ""] }
CHANNEL_15_INFO={ "IP": "10.80.59.141",  "ChannelName": "WS010|SIM", 		"tool serial":	0, 			"location name": ["Tool", "Line 2", "WS010", "default", "", "", ""] }
CHANNEL_27_INFO={ "IP": "10.80.59.161",  "ChannelName": "WS010|P2L", 		"tool serial":	0, 			"location name": ["Tool", "Line 2", "WS010", "default", "", "", ""] }
CHANNEL_31_INFO={ "IP": "10.80.59.141",  "ChannelName": "WS010|ACK", 		"tool serial":	0, 			"location name": ["Tool", "Line 2", "WS010", "default", "", "", ""] }
```

The main parameters are explained inline above, the `CHANNEL_xx_INFO` parameters are used to enable reporting data for connected tools. There are basically two different `CHANNEL_xx_INFO` items here:

- `CHANNEL_xx_INFO` with `xx` in the range of `01` to `98`: This is used to
  generate and send traceability info for the tool `xx`. If used for virtual 
  tools, you can set the `IP` and `ChannelName` parameters to simulate these
  parameters, if used for a physical tool, then `IP` and `ChannelName` are
  used from the tools configuration (e.g. for an OpenProtocol torque wrench
  from the `[OpenProtocol]` section, where the communication parameters for
  the tool are defined)
- `CHANNEL_99_INFO`: This is a special "event"-channel for OGS builtin events
  like the barcode scanner, acknowledge button or other events (like OGS
  start shutdown, user login, skip operation, etc.)

The `CHANNEL_xx_INFO` parameter values are interpreted as a JSON string with the following elements:

- `location name`: Array of location names [1..7] (of type string)
- `IP`: IP address (or com port or the connection string) of the tool
- `ChannelName`: The channel name used for building the result data file
- `tool serial`: The tool serial number to use

If the parameters are not given, they default to whatever the actual tool driver
provides, the parameters give override the defaults.

## Communication settings (http/FTP)

The `Traceability` feature support sending the data to either a FTP server or posting it to a http server (but not both at the same time). The following sections show how to setup the communication parameters.

### http output

To enable http output, the configuration section must be named `[HTTP_CLIENT]` and the communication settings given as follows:

``` ini
[HTTP_CLIENT]
; Set ENABLED=1 to enable traceability data output
ENABLED=1
; Set ReportSkippedOperations=1, if you want to see operators skip actions
; in the traceability data output, else set to =0
ReportSkippedOperations=1

; Define the targets http (Sys3xxGateway) server URL endpoint
; Note, that this also supports https!
HostURL=http://myserver:8888/sys3xxgateway

; Optionally set username/password for http basic authentication
;Username=sys3xx
;Password=sys3xx
```

### FTP output

To enable FTP output, the configuration section must be named `[FTP_CLIENT]` and the communication settings given as follows:

``` ini
[FTP_CLIENT]
; Set ENABLED=1 to enable traceability data output
ENABLED=1
; Set ReportSkippedOperations=1, if you want to see operators skip actions
; in the traceability data output, else set to =0
ReportSkippedOperations=1

; Define the targets FTP (Sys3xxGateway) server IP-Address and port
HostIP=10.80.59.252
HostPort=21

; In case of Sys3xxGateway(Qtrans) as FTP server use "Username=sys3xx" and
; "Password=sys3xx". TargetFolderOnHost is not needed (ignored) then.
Username=sys3xx
Password=sys3xx

; In case of standard FTP Server the "TargetFolderOnHost" parameter must 
; be set and is used as a base folder to store data.
TargetFolderOnHost=
```

Note, that the FTP output supports two different server types:

- Standard FTP server: A standard FTP server allows (virtual) file system access. Therefore typically a username and password must be used for authentication and a target folder (`TargetFolderOnHost`) to indicate where the transmitted files are stored must be configured. Note, that due to security reasons nowadays unencrypted data (password) exchange should not be used.
- `Sys3xxGateway` FTP server: This is a FTP server which only supports a subset of the standard FTP protocol. It does not require authentication (username/password) and also does not allow file system access. It handles all received data in-memory and validates it - only data which validates as a correct result data is accepted and processed. The parameters `Username`, `Password` and `TargetFolderOnHost` are therefore not used - so the security level is on par with the http transport.

## Reference

### Custom file name generation

By default, the file for transmitting to FTP is generated internally in the following form:

    <hostdir>/<YYYY-MM-DD_HH>/<YYYYMMDDHHmmSS>_<IPAddr>_<Channel>_<seq>.json

Where:

- `<hostdir>` as specified in the `[FTP_CLIENT]` section (Parameter `TargetFolderOnHost`)
- `<YYYY-MM-DD_HH>` and `<YYYYMMDDHHmmSS>` date/time stamps
- `<IPAddr>` the tools IP address (or connection string), maybe overridden in the `CHANNEL_xx_INFO` parameters
- `<Channel>` channel number of the tool
- `<seq>` result sequence counter value (if any) of the tool

For custom tools, the generated file can be modified by overriding the LUA function `GetFTPFilename()`. 

The function has the following signature:

``` lua
function GetFTPFilename(idcode, IP, Rack, Slot, Seq)

    -- Your code to create a relative filename in the format 
    --    <subfolder(s)>/<filename>

    return filename
end
```

### LUA tools result data

A custom LUA tool can also generate a tracability result file. The low-level OGS API responsible to generate the actual data is the function `LUA_GetJSON()` - however, it is **not recommended** to override this function, as the LUA custom tool interface provides a more convenient wrapper (see [LUA custom tools](/docs/v3/lua/customtools.md) by calling the tool drivers `process_param_list()`, `get_tags()`, `extended_param_list()` and `extended_function_list()` interface functions.

To get more info about custom tracebility output formatting for LUA tools, see the default implementation in `<install dir>\lualib\json_ftp.lua`. 



