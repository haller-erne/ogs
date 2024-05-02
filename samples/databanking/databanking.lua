---------------------------------------------------------------------------------------
local DB = {  }
StartedAssemebly = nil
AssemblyTime = 0
---------------------------------------------------------------------------------------
local part_results = {  part_id = '', data = {} }
local function clear_part_results()
    part_results.part_id = ''
    part_results.data = {} 
end
---------------------------------------------------------------------------------------
function InitOELReport()
	local tbl = ReadIniSection('DATABANKING')
	if type(tbl) == 'table' and type(tbl.ConnectionString) == 'string' then 
		DB.ConnectionString = tbl.ConnectionString
	end	
	if DB.ConnectionString and #DB.ConnectionString > 0 then
	-- enable both: input(use data banking) and output (use data banking) 
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
    Params.TypeID   = tool_type -- GetTypeIDByTool(tool_type,tool_id, ByHandAck)
    
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
	local err = luaExecStoredProc(DB.ConnectionString, 'AddResult',Params)
    if err then 
	    SetLuaAlarm('db connection', -2, err);
		XTRACE(1, "[db connection] ".. param_as_str(err))
		return nil
    end
	if StartedAssembly then
	    StartedAssembly = nil
        updateAssemblyState(PartID)
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
----------------------------------------------------------------------------------------
function GetTaskResultEvent(PartID, Root, JobSeq, JobName, TaskSeq, TaskName, OpSeq, Final)

    if not DB.ConnectionString then 
        SetLuaAlarm('db connection', -2, 'Invalid database connection. Abort processing!');
        return nil
    end
    if not StartedAssembly then
        StartedAssembly = true
        updateAssemblyState(PartID)
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
local base_stop_assembly  = Barcode_StopAssembly
-----------------------------------------------------------------------------
local function databanking_stop(final_state)
    clear_part_results() 
    base_stop_assembly(final_state)
end
---------------------------------------------------------------------------------
Barcode_StopAssembly  = databanking_stop
--------------------------------------------------------------------------------
local base_start_assembly  = Barcode_StartAssembly
local function assembly_start()
    if base_start_assembly then base_start_assembly() end
end
Barcode_StartAssembly = assembly_start
-----------------------------------------------------------------------
local tbl = nil
local AssemblyID = 0
function updateAssemblyState(PartID)

    if not StartedAssembly then 
        local Params = {}
        Params.AssemblyID   = AssemblyID
        Params.ENDTIME  = param_as_str(os.date('%Y-%m-%d %H:%M:%S'))
        Params.STATE = "0"
        local err = luaExecStoredProc(DB.ConnectionString, 'AddEndAssemblyState',Params)
        if err then 
            SetLuaAlarm('db connection', -2, err);
            XTRACE(1, "[db connection] ".. param_as_str(err))
            return nil
        end
        return true 
        
    elseif StartedAssembly then
        local Params = {}
        if tbl == nil then
            tbl = ReadIniSection('GENERAL')
        end
        Params.Barcode = string.sub(PartID,1,25)
        Params.Rawcode = tostring(PartID) 
        Params.Station = tbl.STATION_NAME
        Params.STATE = "1"
        Params.STARTTIME = param_as_str(os.date('%Y-%m-%d %H:%M:%S'))
--[[
        local data, err = luaOpenStoredProc(DB.ConnectionString, 'CheckLastAssembly', Params)
        if err then 
            SetLuaAlarm('db connection', -2, err);
            XTRACE(1, "[db connection] ".. param_as_str(err))
            return nil
        end
        if not data then 
            Params.TotalDuration = 0
            AssemblyTime = 0
        else 
            Params.TotalDuration = data[1].TotalDuration
            AssemblyTime = data[1].TotalDuration
        end
]]        
        local data, err = luaOpenStoredProc(DB.ConnectionString, 'AddAssemblyState',Params)
        if err then 
            SetLuaAlarm('db connection', -2, err);
            XTRACE(1, "[db connection] ".. param_as_str(err))
            return nil
        end
        AssemblyID = data[1].AssemblyID
        
        return true  
    end
end
-------------------------------------------------------------------------------