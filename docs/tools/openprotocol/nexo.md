---
id: nexo
name: Bosch Rexroth Nexo and Nexo 2 wireless battery tools
title: Bosch Rexroth Nexo and Nexo 2 wireless battery tools
tags:
    - tool
    - tightening
    - openprotocol
---

# Bosch Rexroth Nexo and Nexo 2 wireless battery tools

The [Nexo cordless nutrunners](https://store.boschrexroth.com/Schraubtechnik/Funkakkuschrauber-Nexo) are advanced battery powered tightening tools with high accuracy and reliability. They are certified for safety-critical tightening connections according to VDI/VDE 2862. The tools feature built-in controllers with WiFi communications. They use the [OpenProtocol](../README.md) communication protocol to communicate with the heOGS software. They also support traceability data and curve output, see [tool data http output](#tool-data-http-output).

![Nexo2 cordless nutrunner](resources/nexo2.jpg)

Note, that the Rexroth product site and catalog do not list the Nexo 2 tools at the time of writing this article, but there is a [marketing site with information about Nexo 2](https://www.boschrexroth.com/en/us/products/product-groups/tightening-technology/topics/cordless-nutrunner-nexo/).

## Installation and configuration

### OGS project configuration

For generic information about how to configure OGS with OpenProtocol tools, see  [OpenProtocol documentation](../README.md).

### Tool registration and configuration

The Nexo and Nexo 2 tools are identified by specifying the tool type `NEXO` in the `[OPENPROTO]` section of `station.ini`. 

A typical configuration of the `[OPENPROTO]` section looks like the following :

``` ini
[OPENPROTO]
; Channel/Tool 1 parameters
CHANNEL_01=10.10.2.184
CHANNEL_01_PORT=4545
CHANNEL_01_TYPE=NEXO
; Enable time synchronization 
CHANNEL_01_CHECK_TIME_ENABLED=1
; Force CCW switch selection for rework/loosen
CHANNEL_01_CCW_ACK=1
; to enable curve transmission, set to 1:
CHANNEL_01_CURVE_REQUEST=1
```

The typical parameters are (for more details about the possible parameters, see [OpenProtocol documentation](../README.md)):

- `CHANNEL_<channel>`: Define the IP address used to communicate with the tool.
- `CHANNEL_<channel>_TYPE`: Defines the OpenProtocol communication variant, **must** be set to `NEXO`.
- `CHANNEL_<channel>_PORT`: (optional) Define the TCP port number used for OpenProtocol(typically 4545).
- `CHANNEL_<channel>_CHECK_TIME_ENABLED`: (recommended) If set to a nonzero value, then the tools internal time is synchronized with the OGS date and time. For Nexo 1 this is highly recommended due to issues with the firmware NTP time sync.
- `CHANNEL_<channel>_CCW_ACK`: (optional) If set to a nonzero value, then the CCWSel switch is monitored for
the correct position - i.e. if OGS expects loosen, the switch must be set to the CCW position.
- `CHANNEL_<channel>_CURVE_REQUEST`: Set to 1 to enable curve transmission over OpenProtocol, set to 0 to disable. Set to 1, if you need the curve data in OGS (e.g. for display or dynamic curve analysis with LUA scripting). Disable (set to zero), if you don't need it (for performance reasons). As Nexo and Nexo 2 have built-in data output protocols, it is only needed in special setups, where OGS needs the curve data.

### Tool data output

As Nexo and Nexo 2 have built-in features to send out data and curves (`Traceability` data) to backend data management systems, there is typically no support from OGS needed. 

See [Tool data http output](#tool-data-http-output) for more information about how to configure the tools built-in data output drivers.

## Tool configuration

### Firmware version

Please contact [Bosch Rexroth](https://www.boschrexroth.com) for information about current firmware versions - it is recommended to use up-to-date firmware for compatibility, performance and security!

### Tool mode

The Nexo tools can operate in manual or automatic mode. For OGS to be able to control the tool, automatic mode is required. Depending on your requirements, you can configure the tool to enable switching modes through the tool display (not recommended).

The mode must be setup as follows:

=== "Nexo 2"

    ![alt text](resources/nexo2-mode-simple.png)

    The relevant settings are:

    - `ID code source`: must be set to OpenProtocol, so OGS can send the ID
    - `Operation mode settings`: set operation mode to `auto`

    Make sure the set the `active column` to `A`!

=== "Nexo"

    ![alt text](resources/nexo-mode-simple.png)

    The relevant settings are:

    - `ID code source`: must be set to OpenProtocol, so OGS can send the ID
    - `Operation mode settings`: set operation mode to `auto`

    Make sure the set the `active column` to `A`!

### OpenProtocol configuration

#### Enable and configure OpenProtocol

As OGS needs OpenProtocol to control the tool, the OpenProtocol (Data --> OpenProtocol) must be configured as follows:

=== "Nexo 2"

    ![alt text](resources/nexo2-openprotocol.png)

=== "Nexo"

    ![alt text](resources/nexo-openprotocol.png)


#### Setup PLC signals

To allow controlling the tool correctly, the PLC signals should be set up as follows:

=== "Nexo 2"

    ![alt text](resources/nexo2-plc-table-1.png)
    ![alt text](resources/nexo2-plc-table-2.png)

=== "Nexo"

    ![alt text](resources/nexo-plc-table-1.png)
    ![alt text](resources/nexo-plc-table-2.png)

Important:
- Never assign signal `En` to opctrl input 3.0 – this may enable the tool without
  control of the heOGS software.
- Never assign signal `En` to tool input 0.2 – this will enable the tool without
  control of the heOGS software.
- Always assign signal `CcwIgnore` or `CcwLock` to opctrl input 0.1. This allows 
  OGS to reliably block loosening loosening, even if the network connection to the tool gets lost.

### Using the integrated scanner

Some Nexo models provide a built-in barcode scanner. This barcode scanner can be
used instead of or in combination with any other ID-Code source in OGS. Using the
Nexo scanner, it is therefore possible to start a workflow, select jobs or do other
scan operations inside a workflow.

Please see the Nexo system manual for detailed information about how to use and configure the scanner.  The following section shows a simple setup which allows the
user to trigger the Nexo builtin scanner by pressing a button below the Nexo display.

#### Configure OpenProtocol

To enable ID-code forwarding, the option **Also forward ID-codes from non-selected sources** must be enabled in the OpenProtocol configuration (Home --> Data --> OpenProtocol):

![alt text](resources/nexo2-openprotocol.png)

#### Configure Mode setting

To enable the scanner, add an `ID Input` step to the Mode (Home --> Mode) settings as shown in the following screenshot:

![alt text](resources/nexo2-mode-scanner.png)

## Data output configuration

To make Nexo and Nexo 2 to send out data and curves (`Traceability` data) to backend data management systems (like [ToolsNet](https://www.atlascopco.com/en-us/itba/products/assembly-solutions/software-solutions/toolsnet-8-sku4531), [CSP I-P.M.](https://www.csp-sw.com/quality-management-software-solutions/error-prevention-with-ipm/), [Sciemetric QualityWorX](https://www.sciemetric.com/data-intelligence/qualityworx-data-collection), [QualityR](https://www.haller-erne.de/qualityr-web/), etc.), the builtin data output interfaces can be used. 

To send data out to a central Sys3xxGateway/QualityR server, typically the following options are possible:

1. (preferred) Use the “Standard Nexo” data output with the http transfer option. 
    By default this transmits all step data and tightening curves
2. Use the “Standard Nexo” data output with the http transfer option. 
    By default this also transmits all step data and tightening curves, but sometimes causes troubles with the network infrastructure (firewall transversal,
    transmission of plaintext passwords).

The “Standard Nexo” data output with http transfer is the preferred option, else
use “Standard Nexo” with FTP.

Data reported to Sys3xxGateway will use the following mapping by default:

- Nexo IP address-->Default Sys3xxGateway station name
- Nexo channel name --> if non-empty is used as Sys3xxGateway station name
- Nexo channel number --> Sys3xxGateway channel number
- Tightening program name --> Used as operation name (QWX)

To enable http data output, use Home --> Data --> Standard Nexo and configure as follows:

![alt text](resources/nexo2-http-output.png)

As the Nexo 2 http data output provides incorrect localtion information, make sure to configure the `Data` settings (click the button labeled `Data` in the header row) as follows (disable the location element): 

![alt text](resources/nexo2-http-data.png)

To minimize transmitted file sizes, go to the `Storage`settings (click the button labeled `Storage` in the header row) and set "json formatted output" to `No`: 

![alt text](resources/nexo2-http-storage.png)


## Nexo 1: Wifi notes

- Nexo 1 has issues, if roaming is enabled. Make sure to disable the "roaming" setting in the wifi configuration.
- Nexo 1 by default uses the insecure TKIP encryption for WPA2-PSK, make sure to switch to AES mode instead.
