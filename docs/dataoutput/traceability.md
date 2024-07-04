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



## Reference



