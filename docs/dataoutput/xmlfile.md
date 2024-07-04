---
id: xmlfile
name: End-of-process (XML) file
title: End-of-process (XML) file
tags:
    - dataoutput
---

# End-of-process (XML) file

## Overview

OGS records all process results and the resulting part state internally in its database, but it also provides interfaces to provide this data to other systems.

The End-of-process (XML) file functionality (by default) automatically generates a XML file containing the  part staus at the moment, when OGS finishes a workflow (i.e. the part leaves the station). 

The mechanism used to generate the XML file allows overriding the file name (by default generated as `<model><serial>-<timestamp>.xml`) as well as the file contents by implementing the LUA function `GetXMLFile()`.

By setting the configuration options in `station.ini`, the destination folder to save the result files can be specified, as well as when a file shall be created (e.g. only if the part is completed, i.e. all tasks are finished or everytime, even if there are missing tasks).  


## Usage

### Enabling the XML data output

To enable the XML data output, define the destination directory to use in the `[XML]` section in your projects `station.ini` as follows:

``` ini
[XML]
; Define the workflow complete data output (save a result data file).
; NOTES:
; - If the DIRECTORY parameter is missing or empty, no file is generated.
; - The [GENERAL] section RESULT_Ok=, RESULT_Nok=, RESULT_incomplete= define when a XML
;   file is actually generated, e.g. if RESULT_incomplete=SKIP, no XML file will be
;    generated, if a part is finished with incomplete status (like missing bolts).
; - The generated file format/contents can be overriden by LUA code (see GetXMLFile())
;
; Define the output directory for generated part result reports (by default in XML format)
DIRECTORY=C:\Daten
```

XML data output is disabled, if the `DIRECTORY` parameter is missing or empty.

### Define when a file is generated

In general, the XML file is generated when a workflow is completed (i.e. when OGS switches from the process screen back to the idle screen). However, sometimes - depending on the parts result - one does not want to actually save a result data file (e.g. because the part is only partially completed, set aside and will be finished later).

OGS uses the "archive" settings to decide, if the result file shall be generated - as this is conceptionally the same as for the "archiving" setting of the database. The parameters for this are in the `[GENERAL]` section of `station.ini` as follows:

``` ini
;
; If Operator finishes part processing, should be part result get archived in the Database?
;  SKIP - (default) do not archive part result (keep it in database as not completed)
;  SAVE - archive part result ((keep it in database as archived))
;  ASK  - ask operator if part result shall be archived or not
; Define the behaviour according to the part state as follows:
Result_OK=SAVE
Result_NOK=SAVE
Result_incomplete=SKIP
```

The above sample will create a result file, if the part is completed, i. e. all tasks are either
finished OK or NOK, but there will no file be created, if any of the tasks is noch completed (or not started).

## Reference

The default file naming and data format is implementend in `<install dir>\lualib\system.lua`. 

### File Naming conventions

By default, OGS generates the filename of the result data file as follows:

    <idcode>-<timestamp>.xml

where

- `<idcode>` is the concatenation of the model code and serial number
- `<timestamp>` is the current date/time in format `YYMMDD-HHmmss`


### File contents

By default the generated file contains the results in the following XML format:

``` xml
<?xml version="1.0" encoding="ISO-8859-1"?>
<prozess  id="M-061231231232" typ="MODEL 06" version="1.0">
	<station name ="[he-007] ST03" host="nbhei7wx" zeitstempel="04.07.2024 10:24:59" kundeninfo="" werker="red" meister="" ergebnis="NOK">
		<bauteil name ="Brake Caliper" zeitstempel="04.07.2024 10:24:59" ergebnis="nicht vorhanden">
			<schrauben>
				<schraube num="1" name="S1" werkzeug="Nexo" prg="6" moment="30.09" mommin="28.00" mommax="32.00" winkel="782" winmin="500.0" winmax="1200.0" ergebnis="OK" comment=""/>
				<schraube num="2" name="S2" werkzeug="Nexo" prg="6" moment="30.13" mommin="28.00" mommax="32.00" winkel="815" winmin="500.0" winmax="1200.0" ergebnis="OK" comment=""/>
				<schraube num="3" name="S3" werkzeug="Nexo" prg="12" moment="10.03" mommin="8.00" mommax="12.00" winkel="43" winmin="30" winmax="60" ergebnis="OK" comment=""/>
				<schraube num="4" name="S4" werkzeug="Nexo" prg="12" moment="" mommin="" mommax="" winkel="" winmin="" winmax="" ergebnis="nicht vorhanden" comment=""/>
			</schrauben>
		</bauteil>
		<bauteil name ="Oil dipstick" zeitstempel="04.07.2024 10:25:03" ergebnis="NOK">
			<schrauben>
				<schraube num="1" name="S1" werkzeug="Ack" prg="0" moment="INF" mommin="0.00" mommax="0.00" winkel="INF" winmin="0.0" winmax="0.0" ergebnis="NOK" comment=""/>
			</schrauben>
		</bauteil>
		<bauteil name ="Oil dipstick popup" zeitstempel="04.07.2024 10:25:04" ergebnis="OK">
			<schrauben>
				<schraube num="1" name="S1" werkzeug="Ack" prg="0" moment="INF" mommin="0.00" mommax="0.00" winkel="INF" winmin="0.0" winmax="0.0" ergebnis="OK" comment=""/>
			</schrauben>
		</bauteil>
	</station>
</prozess>
```

Note, that all jobs and tasks are listed - those not ran are tagged with the result attribute `ergebnis="nicht vorhanden"`.

### Lua function to override file name and content

To override the file name or file content, implement the LUA function `GetFileName()` in your projects LUA code. The function is called with the `<idcode>` value and the `<model>` code. Before OGS calls the function, the cuttent part state is saved into the `station_results` global variable. The function should use the contents of `station_results` to generate the actual file data and return it along with the file name.

The function has the following signature:

``` lua
function GetFileName(idcode, model)

    -- Your code to create filename and filecontent
    -- Use the global variable station_results to generate the file content.

    return filename, filecontent
end
```

To just change the generated file name, you can call the "original" function from your code and just change the filename. Here is a sample:

``` lua
-- Store the original function in a local variable
local old_GetFileName = GetFileName

-- Define the new function (override the original one)
function GetFileName(idcode, model)

	-- Call the "original" function to get the XML data
	local old_filename, old_filecontent = old_GetFileName(idcode, model)

	-- Create a new filename as "<idcode>-<YYYY><MM><DD>T<HH><mm><ss>.xml"
	local t = os.date('*t')
	local t_as_str = string.format('%04d%02d%02dT%02d%02d%02d', t.year,t.month, t.day, t.hour,t.min,t.sec)
	local new_filename = string.format('%s-%s.xml', idcode, t_as_str)

	-- Return the "new" filename and the "old" file content
    return new_filename, old_filecontent
end
```

To get started quickly, see the default implementation in `<install dir>\lualib\system.lua`. 
