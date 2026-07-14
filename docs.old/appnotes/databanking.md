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

Typical use cases are:

- Rework stations (usually having the workflows of multiple stations combined into a single, large workflow).
- EOL-Checks (end of line checks): Can be used to selectively check single tasks from the assembly stations and visualize these to the operator and add additional (plausibility) checks.

A default implementation using a Microsoft SQL server backend is available and described in this appnote.

## Default SQL Server implementation

### Overview

The SQL server default databanking implementation identifies and stores data by combining then following properties and using it as a key for data retrieval:

- Part serial number
- Job name
- Task name

(see also [howto customize the datbanking lookup key](#lookup-identifier-customization) below)

??? example "Sample rework scenario"

    ### Example

    Say `station 1` processes the part with the serial `123456` as follows:

    | Jobs     | Tasks    | Result |
    | -------- | -------- | ------ |
    | S1 Job 1 | Task 1.1 | OK |
    | S1 Job 2 | Task 2.1 | OK |
    |          | Task 2.1 | NOK |
    | S1 Job 3 | Task 3.1 | not completed|

    Say the rework station `station 5` is configured to rework all jobs as follows:

    | Jobs     | Tasks    | 
    | -------- | -------- | 
    | S1 Job 2 | Task 2.1 | 
    |          | Task 2.1 | 
    | S1 Job 3 | Task 3.1 | 
    | S2 Job 1 | Task 4.1 | 
    | S3 Job 1 | Task 5.1 | 
    | S4 Job 1 | Task 6.1 | 

    If the part with the serial `123456` is scanned in `station 5` (assume due to being NOK in `station 1` it is directly routed to the rework station `station 5`), it now shows up as follows in the OGS process screen (current part status was loaded from the databanking SQL server):

    | Jobs     | Tasks    | Result |
    | -------- | -------- | ------ |
    | S1 Job 2 | Task 2.1 | OK |
    |          | Task 2.1 | NOK |
    | S1 Job 3 | Task 3.1 | not completed |
    | S2 Job 1 | Task 4.1 | not completed |
    | S3 Job 1 | Task 5.1 | not completed |
    | S4 Job 1 | Task 6.1 | not completed |



!!! Info

    - All data is retrieved by using the key `[part serial number]:[Job name]:[Task name]`, so the rework station shows the exact part/task status of the previous operations
    - The rework station does not need to have all jobs/tasks defined identically to the original stations (e.g. S1 Job 1 is not defined in the example rework config shown above). Setup just what you need!


### Server requirements

A Microsoft SQL server database must be available and accessible from each OGS station using databanking. As OGS accesses the data every time a workflow is started and completed, a reliable and fast network connection to the database server is very important.

Supported SQL server versions are: 2019, 2022.

### Client Requirements

Databanking is fully supported with OGS >= V3.0.

Additional software components required:

- SQL Server native client 11 ([SNAC/SQLNCLI](https://learn.microsoft.com/en-us/sql/relational-databases/native-client/applications/installing-sql-server-native-client)) or SQL Server OLE DB driver ([MSOLEDBSQL](https://learn.microsoft.com/en-us/sql/connect/oledb/oledb-driver-for-sql-server)). <span style="color:red">NOTE: On an x64 operating system, the x64 versions od the database drivers must be used!</span> 

### Installation

To install follow the steps outlined in the next sections. All files mentioned are available from the public [OGS GitHub repository databanking sample](https://github.com/haller-erne/ogs/tree/main/samples/databanking).

#### SQL Server Schema and seed data

Use the [databanking.sql](https://github.com/haller-erne/ogs/raw/main/samples/databanking/databanking_schema.sql) file to install the database schema and lookup data required by the default databanking implementation. 

For more information, see the [README file](https://github.com/haller-erne/ogs/blob/main/samples/databanking/README.md) in the [OGS GitHub repository databanking sample](https://github.com/haller-erne/ogs/tree/main/samples/databanking) folder.

#### Integrate databanking into OGS Project 

To integrate databanking into your OGS project, the following changes to the project are needed:

1. Add the [databanking.lua](https://github.com/haller-erne/ogs/raw/main/samples/databanking/databanking.lua) file to your project by adding it into the `requires` table in your projects `config.lua` file.
2. Modify your `station.ini` file to add the database connection information in the `[DATABANKING]` section to the `ConnectionString=` parameter. Here is a sample (using SQL server native client, see [Connection strings below](#database-connection-strings) for more info):

    ``` ini
    [DATABANKING]
    ConnectionString=Provider=SQLNCLI11.1;User ID=<my-user>;Password=<my-pass>;Initial Catalog=<my-db>;Data Source=<my-server>\<my-instance>[,server-port]
    ```

!!! info

    To use an encrypted database connection string, see [database connection strings below](#database-connection-strings).


### Database connection strings

The databanking setup in this sample uses Microsoft ADO to connect to the database. It therefore is not limited to Microsoft SQL server, but works with all databases providing ODBC or OleDB database drivers.

To prevent information leakage, you can also use encrypted database connection strings. This works by encrypting the plaintext connection string with Microsofts data protection API using the machine key of the current system. As this ties the encrypted string to the physical machine, copies of the configureation file cannot be decrypted on another machine. See [sample powershell command for encryption](https://haller-erne.github.io/ogs/libs/lua-dpapi/#sample-powershell-commandlet-for-encryption) on how to encrypt a plaintext string for use with OGS.

For Microsoft SQL server, there are multiple options for connecting to the database, supported are the (old) SQL server native client and the current SQL server OleDB driver. These are described in more detail in the following section.

!!! info

    To workaround missing or invalid server certificates, add `Encrypt=false;` and/or `TrustServerCertificate=false;` to the connection string.


#### SQL Server OleDB driver (MSOLEDBSQL)

Here is a sample connection string using the SQL server native client 11:

``` ini
[DATABANKING]
ConnectionString=Provider=MSOLEDBSQL;Data Source=<my-server>\<my-instance>[,server-port];Initial Catalog=<my-db>;User ID=<my-user>;Password=<my-pass>;
```

A quick reference to the parameters can be found at [connectionstrings.com](https://www.connectionstrings.com/ole-db-driver-for-sql-server/) or in the [official Microsoft documentation](https://learn.microsoft.com/en-us/sql/connect/oledb/oledb-driver-for-sql-server).

#### SQL Server native client (SNAC/SQLNCLI)

Here is a sample connection string using the SQL server native client 11:

``` ini
[DATABANKING]
; Define the database connection used for databanking
ConnectionString=Provider=SQLNCLI11.1;Data Source=<my-server>\<my-instance>[,server-port];Initial Catalog=<my-db>;User ID=<my-user>;Password=<my-pass>;

; Define, if data received from databanking should be saved locally (only used for special cases, e.g. for locate.exe, default = 0)
SaveLocal=0
```

A quick reference to the parameters can be found at [connectionstrings.com](https://www.connectionstrings.com/sql-server-native-client-11-0-oledb-provider/) or in the [official Microsoft documentation](https://learn.microsoft.com/en-us/sql/relational-databases/native-client/applications/installing-sql-server-native-client).


## Custom implementations

_TODO: describe the LUA functions used for databanking._

``` lua
function InitOELReport()

function SaveResultEvent(PartID, Root, JobSeq, JobName, OpSeq, OpName, Final)

function GetTaskResultEvent(PartID, Root, JobSeq, JobName, TaskSeq, TaskName, OpSeq, Final)

function SaveStationResultEvent(PartID, StationName, State, Time, Duration, User)

extern SaveJobLocal()

-- Not exactly a databanking function, but it is used in databanking.lua
-- to track manually deleted data.
function ClearResultsEvent(PartID, Root, JobSeq, JobName, TaskSeq, TaskName)

```

Note, that the `databanking.lua` also overrides the following events:

- Barcode_StopAssembly
- Barcode_StartAssembly

Make sure to **not** override these events without calling the old implementation, else databanking will not work.

### Lookup identifier customization

In general, databanking uses the unique part id (that's handled internally) plus an identifier named `AFO` to (uniquely) identify a result in databanking. The sample databanking implementation uses a central function to generate the `AFO` value in the follwoing function
:
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
