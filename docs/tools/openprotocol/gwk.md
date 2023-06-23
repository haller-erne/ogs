# GWK Operator+

The GWK Operator+ OpenProtocol implementation (currently, as of June 2023) has quite some quirks. OGS tries to workaround most of them, but the following parameters needs to be tweaked:

- The GWK tool only supports a single OpenProtocol session (even if multiple TCP connections are allowed). Make sure to disable multiple connections in the GWK xPico Web settings (under the "Tunnel"-->"Accept" category)
- The GWK tool seems to never actively disconnect a TCP session and does not close an OpenProtcol session, if the TCP connection gets dropped. According to the GWK development, the internal session is only closed, if no message is received within 15 seconds (the MID9999 alive timeout) - irregardless of the state of the TCP connection. As a workaround, OGS therefore always waits for 30 seconds to reconnect to the tool in case of network communication errors. Faster reconnects are not recommended, as the tool replies with MID0004 (error 96) for the next MID0001 (which makes any OpenProtocol client disconnect). Having a reconnect time of less than 15 seconds therefore will lead to a reconnect loop, where never a good connection to the tool can be established.


see [Bosch Rexroth OPEXplus](https://www.pts-automation.de/handelsprodukte/rexroth-schraubtechnik/drehmomentschluessel-opexplus/) for information about the tool.


![test.png](/docs/tools/openprotocol/resources/Global400mp.png)


