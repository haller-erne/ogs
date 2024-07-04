---
id: traceability
name: Event logging
title: Event logging
tags:
    - dataoutput
---

# Event logging

## Overview

In OGS, the term `Event logging` refers to capturing and processing various events from within the OGS application. Compared with [OGS Traceability](/docs/dataoutput/traceability.md), the focus of event logging is not part-related, but station-related. Instead of e.g. detailed tightening result data and curves, `Event logging` captures alarms and other station events. It can therefore be used for [LEAN](https://lean-placement.de/) purposes, [OEE](https://en.wikipedia.org/wiki/Overall_equipment_effectiveness) monitoring and other availability and optimization questions. 

The following event categories are available:

- Barcode scans
- GUI interaction events
- User logon/logoff events
- Alarms
- Workflow events
- Tool result events
- Common events
- Error events

By default, all these event categories are available, but there is no default handler registered. Therefore, by default, none of these events are logged.

## Log events to file

As part of the OGS installation, a default implementation for `Event logging` 
is provided in `<install dir>\lualib\heEventLog.lua`. This implementation writes *.csv files (filename includes a timestamp) with event data, so they can easily be uploaded to a database or analyzed by Excel. A file is generated for
each day, once a day the old file is then uploaded to a server file share.

The following sections describe how to use it in your project.

### Add heEventlog.lua to your project

To add `heEventlog.lua` to your project, simply include it into the `requires` list in your projects `config.lua`. Here is a sample:

``` lua
-- config.lua
requires = {
	"barcode",
	"user_manager",
	"heEventlog"        -- load the event logging functions
}
current_project.logo_file = 'logo-rexroth.png'
current_project.billboard = 'http://127.0.0.1:60000/billboard.html'
```

### Configuration (station.ini)

The `heEventlog.lua` implementation requires some additional parameters in `station.ini`. These parameters are configured in the `[EVENT_LOG]` section as follows:

``` ini
[EVENT_LOG]
; Set local directory for (temporarily) storing log files
DIRECTORY=C:\OGS_Log
;; Set target directory for storing the logfiles
TARGET_DIR=\\myserver\share$\OGS\LOG-Files\station-01
```

The following parameters are required:

- `DIRECTORY`: Local directory for saving the current days file (and possibly older files, if they can't be transmitted to the server)
- `TARGET_DIR`: Final destination for the event files. Finished files (containing all events from a whole day) will be moved to this folder and deleted locally.

## Customizing

To customize the logging (e.g. to send the event in realtime to some logging server or MQTT broker), the OGS global `Eventlog` and its member functions can be implemented in custom code.

Note, that you will have to create the global `Eventlog` LUA table and the needed member functions in your code - see `<install dir>\lualib\heEventLog.lua`. 

The following member functions of the global LUA table `Eventlog` mujst be implemented:

- `Eventlog.Init()`: Called once when OGS is loaded, return true on success, /else nil, error.
- `Eventlog.Stop()`: Called when OGS is about to terminate. Last chance to finish any pending task, before the application is shut down.
- `Eventlog.Write(evt, status, user1, user2, test, p1, p2, p3, p4, p5, p6)`: Called by OGS for each event. The event details are passed as parameters as follows:
    - evt: Event type: one of COMMON (0), BARCODE (1), INTERACTION (2),
	  USER_LOGON (3), ALARM (4), WORKFLOW (5), RESULT (6), ERROR (7). See the default implementation in `heEventlog.lua` for event type specific information.
    - status: Event status (like ok, nok, etc.). See the default implementation 
      in `heEventlog.lua` for event type specific information.
    - user1, user2: Currently logged on user ID when the event was emitted
    - p1-p6: Event parameters. The actual meaning of the parameter depends on 
      the event type, see the default implementation in `heEventlog.lua` for event type specific information.

