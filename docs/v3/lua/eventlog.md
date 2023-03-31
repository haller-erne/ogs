# Workflow and interaction events

## Overview

The OGS core allows to subscribe for various events from the kernel. The main use case is to log all actions to allow full traceability or to measure event timings.

The LUA eventlog interface consists of the single global table `EventLog` - and a few functions which are called by OGS. The `EventLog` table must be created by the LUA code during startup, as `EventLog.Init()` is only called once during the OGS startup sequence.

The following functions should be defined to use the EventLog-Interface:

- `EventLog.Init()`: Is called during OGS startup. To enable the EventLog events, the function must return true.
- `EventLog.Stop()`: Is called before OGS shuts down. 
- `EventLog.Write(EventType, ...)`: Is called whenever a new event is emitted by the OGS core.

The following `EventType` values are currently supported:

- `COMMON` (= 0): 
- `BARCODE` (= 1): 
- `INTERACTION` (= 2):
- `USER_LOGON` (= 3):
- `ALARM` (= 4):
- `WORKFLOW` (= 5): 
- `RESULT` (= 6): Called whenever the current tool result is updated.
- `SOFTWARE_ERROR` (= 7):  -- configuration( ini)  errors

## Events

The `EventLog.Write(EventType, ...)` function is called with different parameters, depending on the actual `EventType`. If the event is related to a user action, then the parameters `User1` and `User2` provide information about the users logged on when the event occurred. The parameters are as follows:

- `User1`: The operator-level user
- `User1`: The supervisor-level user (if logged on)

### Common event

The common event is currently not used by the OGS core, but reserved as a general status/text event placeholder. It can be used e.g. from the LUA side to inject custom events. The function signature is as follows:

    EventLog.Write(BARCOMMON, Status, Text)

The following parameter values are provided:

- Status (int): Custom status code
- Text (string): Custom event message

### Barcode event

The barcode event is fired, whenever a new barcode is received. The function signature is as follows:

    EventLog.Write(BARCODE, FieldNo, User1, User2, Code, Source, Tag)

The following parameter values are provided:

- FieldNo: Barcode field number (reference into the barcode table)
- Code: The actual ID-Code value
- Source: The ID code source (`Barcode`, `RFID`, ... whatever is configured in `station.ini` or added through `barcode.lua`)
- Tag: The barcode table tag name - typically used to identify the type of the scanned bar code. This has a 1:1 relation to the FieldNo value and is defined in the projects barcode table (see `barcode.lua`).

### Interaction event

The interaction event is fired, whenever one of the operator buttons is pressed on the GUI. The function signature is as follows:

    EventLog.Write(INTERACTION, Request, User1, User2, Text, JobSeq, OpSeq, Field)

The following parameter values are provided:

- Request: The actual request code, one of the following:

	- noReq (0x0000=: no request

	- finishProcess (0x0001): finish assembly processing
	- clearProcess (0x0002): clear all tightening results on assembly go to first Job
	- startJob (0x0004): start current Job (is available only in WorkflowState::WaitJobStart)
	- finishJob	(0x0008): finish current Job processing and set WorkflowState::WaitJobStart
	- skipJob (0x0010): finish current Job processing and go to next Job
	- clearJob (0x0020): clear all tightening results on current Job and set WorkflowState::WaitJobStart
	- skipRundown (0x0040): set current operation to NOK and go to next operation
	- clearBolt (0x0080): set current Bolt to NOT_PROCESSED
	- startDiag (0x0100): enable start diagnostic job
	- selectRundown	(0x0200): select Job / Bolt in view or on image
	- userLogon (0x0400): user logon
	- pauseJob (0x0800): pause Job
	- processNOK (0x1000): continue processing after NOK result
	- CCW (0x2000): CCW
	- manualInput (0x4000): manual input in start view (added for LUA trace log only)
	- unmountJob (0x8000): unmount Job
	- switchTool (0x10000): switch between alternative and standard tool
	- teachToolPos (0x20000): enable teach mode for teaching a new tool position (only if positioning mode is enabled)

- Text: Usually empty, except for the `manualInput` request - in this case provides the actual manual input value.
- JobSeq: Current job sequence
- OpSeq: Current task/operation sequence
- Field: Used for the `manualInput` request - has the field name for which data was entered.

### Logon event

The logon event is fired, whenever a user logs on or off. The function signature is as follows:

    EventLog.Write(LOGON, Status, User1, User2, Text, Level)

The following parameter values are provided:

- Status: Logon result status, one of the following values

    - 0 = Success (user is logged on)
    - -1 = Username not found (unknown username or database connection error)
    - -2 = Invalid password (or password check failed)
    - -3 = No priviledges (user is known, password is correct, but missing rights for actual logon - might happen, if e.g. certification check or trainig checks fail for the user (or are outdated))
    - 1 = Logoff (user has successfully logged off)
    - 2 = Autologon (the autologon user is now logged on)

- Text: Depending on the status value one of the following
    
    - 'login': for successful user login.
    - 'autologon' for failed user autologon 
    - username in case of otherwise failed login attempts

- Level: Active user level (0 = nobody logged in, 1 = operator level, 2 = supervisor level, 3 = admin level)

### Alarm event

The alarm event is fired, whenever a new alarm is raised or if an alarm state changes. The function signature is as follows:

    EventLog.Write(ALARM, Status, User1, User2, Text)

The following parameter values are provided:

- Status (int): Alarm level (0 = alarm cleared)
- Text (string): Alarm message

### Workflow event

The workflow event is fired, whenever the workflow state changes. The function signature is as follows:

    EventLog.Write(WORKFLOW, Status, User1, User2, Text)

The following parameter values are provided:

- Status (int): Type code
- Text (string): Descriptive message

### Result event

The result event is fired, whenever the result state for the current tool operation changes. The function signature is as follows:

    EventLog.Write(RESULT, Status, User1, User2, Text)

The following parameter values are provided:

- Status (int): Quality code of the result
- Text (string): currently not used

## Sample code

### Write events to a logfile

A sample implementaion for logging all events to a file is provides in `heEventLog.lua` (in the lualib folder).

### Send events over MQTT

To send the events over MQTT, here is a snippet on how to convert the event data into a json message ready to be published over MQTT.

The sample omits the MQTT boilerplate code and focuses on the Eventlog implementation (see luamqttclient for more info).

``` LUA
local mqtt = require('luamqttclient')
local json = require('json')	

local MqttTopic = 'mytopic/mysubtopic'      -- the MQTT event topic

-- setup the global eventlog table
EventLog = {
}

-- The init function called from OGS
EventLog.Init = function()

    --[[
        initialize MQTT [omitted]
    ]]

    -- send a MQTT bootup message
    local msg = json.encode({type=0,name='CUSTOM',status=0,text='OGS started'})        
    MC:Publish(MqttTopic, 0, msg)
    
    return true
end

-- The Stop function - send a MQTT shutdown message
EventLog.Stop = function()
    -- send a MQTT shutdown message
    local msg = json.encode({type=0,name='CUSTOM',status=0,text='OGS shutdown'})        
    MC:Publish(MqttTopic, 0, msg)
end

-- Define a event parameter/name mapping table
EventLog.EvtParms = {   -- define custom tags names for the function parameters
    [1] = { name='BARCODE',     'fieldno', 'user1', 'user2', 'code', 'source', 'tag' },
    [2] = { name='INTERACTION', 'status', 'user1', 'user2', 'text', 'jobseq', 'opseq', 'field' },
    [3] = { name='USER_LOGON',  'status', 'user1', 'user2', 'login', 'level' },
    [4] = { name='ALARM',       'severity', 'user1', 'user2', 'message' },
    [5] = { name='WORKFLOW',    'status', 'user1', 'user2', 'message', 'source', 'tag' },
    [6] = { name='RESULT',      'status', 'user1', 'user2', 'code', 'source', 'tag' },
    --[0] = { name='COMMON', 'type', 'status', 'text' },
    --[7] = { name='SOFTWARE_ERROR', 'type', 'status', 'text' },
}

-- The Eventlog.Write function is called from OGS whenever a new event occurrs
EventLog.Write = function (type, ...)
    -- map the parameters/names depending on the event type
    local params = EventLog.EvtParms[type]
	local t = os.date('*t')
    local res = {
        type = type,
        timestamp = string.format('%04d-%02d-%02d %02d:%02d:%02d',t.year,t.month,t.day,t.hour,t.min,t.sec),
    }
    res.name = params.name or 'UNKNOWN'
    if params then
        for i = 2,#arg do
            res[params[i-1]] = arg[i-1]
        end
    end
    -- publish over mqtt
    local msg = json.encode(res)        
    MC:Publish(MqttTopic, 0, msg)
end
```
Running this code then generates json messages like the following (login event):

``` json
{
    "type":3,
    "timestamp":"2023-03-31 09:56:00",
    "name":"USER_LOGON",
    "status":0,
    "user1":"U40003ACC4D",
    "user2":"",
    "login":"login"
}
```
