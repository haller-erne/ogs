---------------------------------------------------------------------------------------
require('tooltypes')
---------------------------------------------------------------------------------------
local DB = {
    ConnectionString = nil,
    StationName = '',
    SaveLocal = 0,

}
local M = {  }
LastPartState = { }
---------------------------------------------------------------------------------------
local part_results = {  part_id = '', data = {} }
local function clear_part_results()
    part_results.part_id = ''
    part_results.data = {}
end
---------------------------------------------------------------------------------------
function InitOELReport()
    local tbl = ReadIniSection('GENERAL')
    DB.StationName = param_as_str(tbl.STATION_NAME)

	tbl = ReadIniSection('DATABANKING')
	if type(tbl) == 'table' and type(tbl.ConnectionString) == 'string' then
        DB.SaveLocal = tbl.SaveLocal or 0
		DB.ConnectionString = tbl.ConnectionString
	end	
	if DB.ConnectionString and #DB.ConnectionString > 0 then
	    -- enable both: input(UseEOLReportAsDataSource) and output (EOLReportEnabled )
        -- Try to decrypt the connection string 
        local dpapi = require('luadpapi')   -- load the DPAPI
        local mime = require('mime')        -- load luasocket/mime (base64)
        local encrypted = mime.unb64(DB.ConnectionString)
        -- Decrypt the raw data.
        local decrypted, err = dpapi.unprotect(encrypted)
        if decrypted ~= nil then
            DB.ConnectionString = decrypted
        end
        return  true, true
    end 
    XTRACE(1, "[DATABANKING] parameter 'ConnectionString' not found in INI file")
    DB.ConnectionString = nil
	return nil, nil  -- default
end
---------------------------------------------------------------------------------------
local function GetAFO(Root, JobSeq, JobName, TaskSeq, TaskName)
    local afo_property = get_task_property('afo', JobSeq, TaskSeq)
    if afo_property then return afo_property end
    if #Root > 0 then
        JobName = Root..':'..JobName 
    end
    return JobName..'['..param_as_str(TaskSeq)..']'
end
---------------------------------------------------------------------------------------
local function AddStationState(PartID, StationName, STARTTIME)
    local Params = {}
	Params.Barcode = param_as_str(PartID)
	Params.Station = param_as_str(StationName)
	Params.STARTTIME2 = param_as_str(STARTTIME)
    local data, err = luaOpenStoredProc(DB.ConnectionString, 'AddStationState',Params)
    if type(data)  == "table" and data[1] then 
        LastPartState.AssemblyTime = data[1].assembly_time
        if not LastPartState.AssemblyTime then LastPartState.AssemblyTime = 0 end
        LastPartState.LastState = 0
        LastPartState.StationResultID = data[1].id
        if not tonumber(LastPartState.StationResultID) then
            err = 'Invalid "AddStationState" stored procedure'
        else 
            return -- OK!
        end
    end 
    SetLuaAlarm('db connection', -2, err);
    XTRACE(1, "[db connection] ".. param_as_str(err))
end
-------------------------------------------------------------------------------
-- OGS calls this function for each task in the job (whenever a job is loosing focus)
function SaveResultEvent(PartID, Root, JobSeq, JobName, OpSeq, OpName, Final)

    if not DB.ConnectionString then return end
    clear_part_results()
    Root = param_as_str(Root)
    JobName = param_as_str(JobName)
    OpName = param_as_str(OpName)

	local TaskName = param_as_str(CurrentOperation.BoltName)
	local TaskSeq  = tonumber(CurrentOperation.BoltNumber)

    local AFO = GetAFO(Root, JobSeq, JobName, TaskSeq, TaskName)
    if #Root > 0 then
        JobName = Root..':'..JobName
    end

	XTRACE(16, "[db connection] add result: "..string.format('%s | %s | %s', JobName, OpName, param_as_str(OpSeq)))
	XTRACE(16, "[db connection] AFO: "..AFO)

	local Params = {}

    local tool_id   = tonumber(CurrentOperation.Tool)
    local tool_type = tonumber(CurrentOperation.ToolType)
    local ByHandAck = tonumber(CurrentOperation.ByHandAck)
    Params.TypeID   = GetTypeIDByTool(tool_type,tool_id, ByHandAck)

	-- this are string parameters (NOT NULL)
	Params.Time     = param_as_str(CurrentOperation.Time)   -- in format: YYYY-MM-DD hh:mm:ss
	Params.PartID   = param_as_str(PartID)
	Params.AFO      = AFO
	Params.Final    = Final
	Params.JOB      = JobName
	Params.Model    = param_as_str(CurrentOperation.Model)
	Params.Station  = param_as_str(CurrentOperation.Station)
	Params.Operation= OpName
	Params.TaskName = TaskName
	Params.Tool     = param_as_str(CurrentOperation.ToolName)
	-- this are integer parameters
	Params.Task     = TaskSeq
	Params.Prg      = tonumber(CurrentOperation.Prg)
	Params.OpSeq    = tonumber(OpSeq)
	Params.RunCount = tonumber(CurrentOperation.RunCount)
	Params.QC       = tonumber(CurrentOperation.QC)
	Params.Total    = tonumber(CurrentOperation.Total)

	-- this string parameters can be empty/NULL
	Params.Barcode  = CurrentOperation.Barcode
	Params.Value1   = CurrentOperation.Value1
	Params.Value2   = CurrentOperation.Value2
	Params.Value3   = CurrentOperation.Value3
	Params.Value4   = CurrentOperation.Value4
	Params.Value5   = CurrentOperation.Value5
	Params.Value6   = CurrentOperation.Value6
	Params.User     = UserManager.user
	local err = luaExecStoredProc(DB.ConnectionString, 'AddResult',Params)
    if err then 
	    SetLuaAlarm('db connection', -2, err);
		XTRACE(1, "[db connection] ".. param_as_str(err))
		return nil
    end
	if not LastPartState.StationResultID then
        AddStationState(Params.PartID, Params.Station, Params.Time)
	end
    return true
end
---------------------------------------------------------------------------------------
local function GetJobAFOList(job)
    local afo_list = ''
	for i,task in pairs(job.Tasks) do
	    local afo = GetAFO(job.Root, job.Seq, job.RawName, task.Seq, task.Name)
        if #afo_list == 0 then
            afo_list = afo
        else
            afo_list = afo_list..';'..afo
        end
	end
	return afo_list
end
----------------------------------------------------------------------------------------
-- OGS calls this function whenever the user clicks "delete op", "delete job" or "delete all"
-- OGS then calls this function for each non-empty record in the specific scope
function ClearResultsEvent(PartID, Root, JobSeq, JobName, TaskSeq, TaskName)

    if not DB.ConnectionString then return end
    clear_part_results()
    Root    = param_as_str(Root)
    JobName = param_as_str(JobName)
    TaskName= param_as_str(TaskName)
	XTRACE(16, "[db connection] clear Task: ".. JobName..' | '..TaskName)

    if (JobSeq == 0 or #JobName == 0) then  -- clear all assembly results by <PartID>
        TaskSeq = 0
        TaskName= ''
    end
	local Params = {}
	Params.PartID = param_as_str(PartID)
    if TaskSeq > 0 and #TaskName > 0 then
	    -- clear single task result
        Params.afo_list = GetAFO(Root, JobSeq, JobName, TaskSeq, TaskName)
	    local err = luaExecStoredProc(DB.ConnectionString, 'ClearResults',Params)
	    if err then
	        SetLuaAlarm('db connection', -2, err);
		    XTRACE(1, "[db connection] ".. param_as_str(err))
            return nil
        end
        return true
    end
    for i,job in pairs(Workflow.Jobs) do
        if (job.Seq == JobSeq) or               -- clear Job results by <PartID, JobSeq>
           (JobSeq == 0 or #JobName == 0) then  -- clear all assembly results by <PartID>
            Params.afo_list = GetJobAFOList(job)
	        local err = luaExecStoredProc(DB.ConnectionString, 'ClearResults',Params)
	        if err then 
	            SetLuaAlarm('db connection', -2, err);
		        XTRACE(1, "[db connection] ".. param_as_str(err))
		        return nil
            end
        end
	end
    return true
end
---------------------------------------------------------------------------------------
-- helper to fill the LastPartState 
local function CheckStationState(PartID, StationName)
    if not DB.ConnectionString then return end
	local Params = {}
	Params.Barcode  = PartID
	Params.Station  = param_as_str(StationName)
	XTRACE(16, "[db connection] check station state: "..string.format('%s | %s', Params.Barcode, Params.Station))
	local data, err  = luaOpenStoredProc(DB.ConnectionString, 'CheckStationState',Params)
    if err then 
	    SetLuaAlarm('db connection', -2, err);
		XTRACE(1, "[db connection] ".. param_as_str(err))
		return
    end
    if type(data) == "table" and data[1] then
        LastPartState.AssemblyTime = data[1].assembly_time
        LastPartState.LastState = data[1].last_state
        if not LastPartState.AssemblyTime then LastPartState.AssemblyTime = 0 end
        if not LastPartState.LastState then LastPartState.LastState = 0 end
    end
end
----------------------------------------------------------------------------------------
-- Called by OGS when a workflow is started
-- The function is called for each task configured for the workflow.
function GetTaskResultEvent(PartID, Root, JobSeq, JobName, TaskSeq, TaskName, OpSeq, Final)

    if not DB.ConnectionString then
        SetLuaAlarm('db connection', -2, 'Invalid database connection. Abort processing!');
        return nil
    end
    if not LastPartState.AssemblyTime then
        CheckStationState(PartID)
    end
    if PartID  ~= part_results.part_id then
        XTRACE(16, "[db connection] Get part results request: [".. param_as_str(PartID)..'] '..param_as_str(JobName))
        local Params = { PartID = param_as_str(PartID)}
        local err
        part_results.data, err = luaOpenStoredProc(DB.ConnectionString, 'GetResults',Params)
        if err then
            SetLuaAlarm('db connection', -2, 'Invalid database connection. Abort processing!');
            XTRACE(1, "[db connection] ".. param_as_str(err))
            return nil
        end
        part_results.part_id = PartID
    end

    if not part_results.data then return {} end  -- empty result table

    Root = param_as_str(Root)
    JobName = param_as_str(JobName)
    local AFO = GetAFO(Root, JobSeq, JobName, TaskSeq, TaskName)
    for k,r in pairs(part_results.data) do
        if r.AFO == AFO and r.Final == Final then
            return r
        end
    end
    return {}  -- task result not found
end
-----------------------------------------------------------------------
local function SaveDataBankingResultsLocal()
    local JobsToSave = {}
    if not part_results.data then return end  -- empty result table
    local current_station = DB.StationName
    local temp = {}
    local keys = {}
    for k,r in pairs(part_results.data) do
       if r.Station ~= current_station then 
            if not JobsToSave[r.JOB] then
                JobsToSave[r.JOB] = r.ResultID
                table.insert(keys, r.ResultID)
                temp[r.ResultID] = r.JOB
            end
       end 
    end
	table.sort(keys)
    for _, key in ipairs(keys) do
        SaveJobLocal(temp[key])
    end
end

-----------------------------------------------------------------------
local base_start_assembly  = Barcode_StartAssembly
local function assembly_start()
    if base_start_assembly then base_start_assembly() end
    if DB.SaveLocal and DB.SaveLocal ~= 0 then
        SaveDataBankingResultsLocal()
    end
end
Barcode_StartAssembly = assembly_start

-----------------------------------------------------------------------
local base_stop_assembly  = Barcode_StopAssembly
-----------------------------------------------------------------------------
local function databanking_stop(final_state)
    LastPartState = { }
    clear_part_results() 
    base_stop_assembly(final_state)
end
---------------------------------------------------------------------------------
Barcode_StopAssembly  = databanking_stop
--------------------------------------------------------------------------------
-- Called whenever OGS finishes a workflow
function SaveStationResultEvent(PartID, StationName, State, Time, Duration, User)
    if not DB.ConnectionString then return end
    if not LastPartState.StationResultID then return end -- no results
	   
	local Params = {}
	Params.ID       = LastPartState.StationResultID
	Params.State    = tonumber(State)
	Params.STARTTIME1 = Time
	Params.ProcessDuration = tonumber(Duration)
	Params.User = param_as_str(User)
	XTRACE(16, "[db connection] update station result: "..string.format('%s | %s | %s | %s | %s', 
		   Params.ID, param_as_str(State), param_as_str(Params.Time),  param_as_str(ProcessDuration), Params.User))
	local err = luaExecStoredProc(DB.ConnectionString, 'UpdateStationState',Params)
    if err then 
	    SetLuaAlarm('db connection', -2, err);
		XTRACE(1, "[db connection] ".. param_as_str(err))
    end
end


 ---------------------------------------------------------------------------------------
 -- Call a stored procedure to get list of stations results for a given part/serial
M.GetStationStates = function(Model, Order, SerialNumber, Preassembly, StationList)
    if not DB.ConnectionString then return end
	local Params = {}
	
	Params.MODEL = Model
	Params.ORDER = Order
	Params.SN    = SerialNumber
	Params.PREASSEMBLY = Preassembly
	for v, state in pairs(StationList) do
    	XTRACE(16, "[db connection] get station states: "..string.format('%s | %s',
                 Params.MODEL..Params.SN..Params.ORDER..Params.PREASSEMBLY, param_as_str(v)))
    end
	local data, err  = luaOpenStoredProc(DB.ConnectionString, 'GetStationStates',Params)
    if err then 
		return err
    end
    if type(data) == "table" and data[1] then
    	for i, record in ipairs(data) do
            local station = record.Station
            local barcode  = record.Barcode
            if StationList[station] then
                StationList[station] = StationList[station] + 1
            end
        end    
   		return nil
    end
	return nil
end
---------------------------------------------------------------------------------
-- Call the stored procedure CheckFourEyesPrinciple to check, if current user
-- was involved in the production on any station (which is not allowed for validation)
-- for a given part/serial.
M.CheckFourEyesPrinciple = function(model, sn, user_name)

	local station = DB.StationName
	local pos = string.find(station, 'Endpruefung' )
	if not pos or pos == 0 then return nil end -- skip check for not 'Endpruefung' stations
	
    if not DB.ConnectionString then return 'invalid DB connection' end
	local Params = {}
	
	Params.MODEL = model
	Params.SN    = sn
	Params.USER  = param_as_str(user_name)
	Params.Station = station
   	XTRACE(16, "[db connection] : FourEyesPrinciple "..Params.MODEL..' '..Params.SN..' '..Params.USER)
	local data, err  = luaOpenStoredProc(DB.ConnectionString, 'CheckFourEyesPrinciple',Params)
    if err then 
		return err
    end
    if type(data) == "table" and data[1] then
    	if data[1].CNT > 0 then 
			return Params.USER.. " hat am Produkt montiert. Vier-Augen-Prinzip nicht eingehalten."
		else 
			return nil
		end	
    end
	return 'CheckFourEyesPrinciple : invalid return value'
end


-------------------------------------------------------------------------------
--
--       Batch monitoring functions
--
-------------------------------------------------------------------------------
M.SetBatchSize = function(Auftrag, Material, size, current)

    if not DB.ConnectionString then 
        SetLuaAlarm('db connection', -2, 'Invalid database connection. Abort processing!');
    end
    local Params = { OrderNumber    = param_as_str(Auftrag) ,
					 MaterialNumber = param_as_str(Material),
					 BatchSize      = size
				   }
    local err =  luaOpenStoredProc(DB.ConnectionString, 'SetBatchSize',Params)
    if err then
        SetLuaAlarm('db connection', -2, 'Database request failed!');
        XTRACE(1, "[db connection] ".. param_as_str(err))
    else
        XTRACE(16,string.format('Save batch size into database: "%s/%s" succeeded. current/size = %d ', 
			param_as_str(Auftrag), param_as_str(Material), size ))
    end
end
-------------------------------------------------------------------------------
M.SetLastProcessed = function(Auftrag, Material, current)

    if not DB.ConnectionString then 
        SetLuaAlarm('db connection', -2, 'Invalid database connection. Abort processing!');
    end
    local Params = { OrderNumber    = param_as_str(Auftrag) ,
					 MaterialNumber = param_as_str(Material),
					 LastProcessed  = current
				   }
    local err =  luaOpenStoredProc(DB.ConnectionString, 'SetLastProcessed',Params)
    if err then 
        SetLuaAlarm('db connection', -2, 'Database request failed!');
        XTRACE(1, "[db connection] ".. param_as_str(err))
     else
        XTRACE(16,string.format('Save the number of the last processed batch element into database: "%s/%s" succeeded. last = %d ', 
			param_as_str(Auftrag), param_as_str(Material), current))
    end
end
----------------------------------------------------------------------------------------
M.GetLastProcessed = function(Auftrag, Material)

    if not DB.ConnectionString then 
        SetLuaAlarm('db connection', -2, 'Invalid database connection. Abort processing!');
		return 0,0
    end
    local Params = { OrderNumber    = param_as_str(Auftrag) ,
					 MaterialNumber = param_as_str(Material),
				   }
	local tbl, err			   
    tbl , err =  luaOpenStoredProc(DB.ConnectionString, 'GetLastProcessed',Params)
    if err then 
        SetLuaAlarm('db connection', -2, 'Database request failed!');
        XTRACE(1, "[db connection] ".. param_as_str(err))
		return 0,0
    end
	local size = 0
	local current = 0
	if tbl and tbl[1] then
		size 	= tbl[1].BatchSize
		current =  tbl[1].LastProcessed
        XTRACE(16,string.format('Get batch parameters for: "%s/%s" succeeded. size = %d last = %d', 
					param_as_str(Auftrag), param_as_str(Material), size, current ))
	    return 	size, current + 1
	end
    XTRACE(16,string.format('Get batch parameters for: "%s/%s" failed.', 
					param_as_str(Auftrag), param_as_str(Material)))
	return nil,nil
end

-------------------------------------------------------------------------------
--
--       Component list functions
--
-------------------------------------------------------------------------------

---------------------------------------------------------------------------
M.DBGetNonConformList = function(Model, SN)
    if not DB.ConnectionString then
        SetLuaAlarm('db connection', -2, 'Invalid database connection. Abort processing!');
		return nil
    end
    local Params = { Model        = param_as_str(Model) ,
					 SerialNumber = param_as_str(SN),
				   }
    local tbl , err =  luaOpenStoredProc(DB.ConnectionString, 'GetNonConformList',Params)
    if err then 
        SetLuaAlarm('db connection', -2, 'Database request failed!');
        XTRACE(1, "[db connection] ".. param_as_str(err))
		return nil
    end
	if type (tbl) == "table" then
         return tbl
    else      
         return {}
    end
	return nil
end
-------------------------------------------------------------------------------
M.DBSetNonConformID = function(Model, SN, newID, oldID)

    if not DB.ConnectionString then
        SetLuaAlarm('db connection', -2, 'Invalid database connection. Abort processing!');
        return
    end
    local Params = { Model        = param_as_str(Model) ,
					 SerialNumber = param_as_str(SN),
                     newID        = param_as_str(newID),
                     oldID        = param_as_str(oldID),
				   }
    local err =  luaExecStoredProc(DB.ConnectionString, 'SetNonConformID',Params)
    if err then
        SetLuaAlarm('db connection', -2, 'Database request failed!');
        XTRACE(1, "[db connection] ".. param_as_str(err))
    else
        XTRACE(16,string.format('NonConform ID: "%s/%s : %s" saved.',
					param_as_str(Model), param_as_str(SN), param_as_str(newID)))
    end
    return err
end
--  Check Charge function
--
------------------------------------------------------------------------------
-- Call the CheckCarge stored procedure to validate a scanned barcode of a batch 
--- return value :
--   false -> SQL /Connection error
--   -1    -> Charge does not exist
--    0    -> Charge OK 
--   >0    -> Charge NOK 
M.SqlChargeCheck = function(id)
    if not DB.ConnectionString then
        SetLuaAlarm('db connection', -2, 'Invalid database connection. Abort processing!');
        return false
    end
    local Params = { IDCode        = param_as_str(id)..'             ' }
    local tbl , err = luaOpenStoredProc(DB.ConnectionString, 'CheckCharge',Params)
    if err then
        SetLuaAlarm('db connection', -2, 'CheckCharge function failed!');
        XTRACE(1, "[db connection] ".. param_as_str(err))
		return false
    else
		if tbl and tbl[1] and tonumber(tbl[1].st_state) then
			local st_state = tbl[1].st_state
			XTRACE(16,string.format('Get charge [%s] state. st_state = %d', param_as_str(id),st_state ))
			return  st_state
		end
	end
    SetLuaAlarm('db connection', -2, 'Invalid CheckCharge stored procedure!');
    XTRACE(16,string.format('Invalid CheckCharge stored procedure!'))
	return false
end

--------------------------------------------------------------------------------
--    PDF in Database 
-------------------------------------------------------------------------------
M.SavePDFtoDatabase = function(Dir,ID,  FileName)

    if not DB.ConnectionString then return end
	   
	local Params = {}
	Params.IDCode   = ID   ---   active_barcodes[1].val .. active_barcodes[3].val  -- MN + Charge
	Params.Station  = DB.StationName  -- aus der INI 
	Params.FileName = FileName
	local full_name = Dir..'\\'..FileName
	local inp  = io.open(full_name, "rb")
	if not inp then 
		XTRACE(1, "[db connection] open PDF file error: "..full_name)
		return false
	end	
	Params.PDF = inp:read("*all")
	inp:close()
	
	if not 	Params.PDF then 
		XTRACE(1, "[db connection] read PDF file error: "..full_name)
		return false
	end
	local bsize = #Params.PDF
	XTRACE(16, "[db connection] send PDF to database: "..full_name .. param_as_str(bsize))
	local err = luaExecStoredProc(DB.ConnectionString, 'InsertPDFReport',Params)
    if err then 
	    SetLuaAlarm('db connection', -2, err);
		XTRACE(1, "[db connection] ".. param_as_str(err))
		return false
    end
	return true
end
---------------------------------------------------------------------------------------
-- Call the MergPDF stored procedure to combine station result pdfs
M.AssemblyPDF = function(Model, Order, SerialNumber)
    if not DB.ConnectionString then return 'invalid DB connection' end
	local Params = {}
	
	Params.MODEL = Model
	Params.ORDER = Order
	Params.SN    = SerialNumber
   	XTRACE(16, "[db connection] merge PDF: "..Params.MODEL..Params.SN..Params.ORDER)
	local data, err  = luaOpenStoredProc(DB.ConnectionString, 'MergePDF',Params)
    if err then 
		return err
    end
    if type(data) == "table" and data[1] then
    	for i, tbl in ipairs(data) do
    	    if type(tbl) == "table" and tbl.output then
            	local output = tbl.output
                local pos = string.find(output,'PDF_SUCCESS')
                if pos then
                    return '' -- OK
                end   
            end        
        end    
    end
	return 'MergePDF : invalid return value'
end
-------------------------------------------------------------------------------
return M