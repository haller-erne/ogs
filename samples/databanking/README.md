---
id: databanking
name: Databanking
title: Databanking
tags:
    - appnote
    - enterprise
---

# Databanking

Databanking is the general term used by OGS for tracking the parts assembly state across multiple stations. It is actually a set of LUA interfaces in OGS, that facilitate two main functions:

1. When starting a workflow, read the part/job state 
2. When finishing a workflow, write the part/job state

Reading and writing the part/job state can be implemented in LUA. Therefore almost any backed system can be used to access and store the parts current build state.

For more information, see the [Databanking section of the OGS documentation](https://haller-erne.github.io/ogs/appnotes/databanking/).

## Instructions

This folder includes sample code to implement databanking with a SQL server database. The following is provided:

- `databanking.lua`: OGS LUA funtion to implement databanking with a SQL server database
- `databanking.sql`: SQL script file to install the neccessary database schema and fill in lookup data values

### SQL server setup

To create a database, add the schema and initialize the tables for databanking, run the following commands in a windows `cmd.exe` shell. Make sure to change the environment variables according to your needs:

``` cmd
SET Server="QUALITYR"
SET DBName="OGS_DataBanking"
SET DBPath="D:\Data\SQL Server\OGS_Datbanking"
SET User="sys3xx"
SET Pass="sys3xx"

sqlcmd -S %Server% -U %User% -P %Pass% -i "databanking.sql" -v DBName = %DBName% DBPath = %DBPath%
```

This will basically run the `databanking.sql` script file against the given database server and create a database. It will then create a schema and setup the tables for use with the `databanking.lua` file.

### OGS setup

For information about how to setup OGS for databanking, see the [Databanking section of the OGS documentation](https://haller-erne.github.io/ogs/appnotes/databanking/).

### Lookup identifier customization

The key to identify a result in databanking is the unique part id (that's handled internally) plus an identifier named `AFO`. The `AFO` value is generated in the function

``` lua
-- Generate a result lookup key
-- By default: return string '(Root:)Jobname+[Taskname]'
function M.GetAFO(Root, JobSeq, JobName, TaskSeq, TaskName) {}
```

The return value is a string, which is used as the parameter for the SQL stored procedure to read the process state from the databanking database.

To override the default implementation, you can override the function in you own LUA module as follows:

``` lua
-- My module, loaded through the requires table in `config.lua`

-- require the databanking.lua module
local databanking = require('databanking')

-- override the GetAFO function:
databanking.GetAFO = function (Root, JobSeq, JobName, TaskSeq, TaskName)
    -- my implementation
    -- generate and return a string with a result lookup key
    return afo
end
```
