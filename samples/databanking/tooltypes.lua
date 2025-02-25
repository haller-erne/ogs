---------------------------------------------------------------------------------------
local OGS_TOOL_TYPE = {}
OGS_TOOL_TYPE.ERGOSPIN       = 1
OGS_TOOL_TYPE.GWK      		 = 2
OGS_TOOL_TYPE.NEXO     		 = 3
OGS_TOOL_TYPE.HANDEINGABE 	 = 4
OGS_TOOL_TYPE.NEWTYPE 		 = 5
OGS_TOOL_TYPE.CONFIRMATION 	 = 6
OGS_TOOL_TYPE.MODBUS    	 = 7
OGS_TOOL_TYPE.BARCODE_READER = 8
OGS_TOOL_TYPE.CUSTOM_TOOL    = 9

local known_sys_type = {}

function GetTypeIDByTool(tool_type,tool_id, ByHandAck)

-- 1 - tightening system  (Torque, Angle, TMin.TMax,AMin,AMax)
-- 2 - OK/NOK confirmation or barcode input (no values, only status and barcode)
-- 3 - Measurement system (mm) (Length in mm)
-- ....
    if ByHandAck == 1 then return 2 end
    if known_sys_type[tool_id] then return known_sys_type[tool_id] end
    known_sys_type[tool_id] = 1 -- default value

    if tool_type == OGS_TOOL_TYPE.ERGOSPIN or
       tool_type == OGS_TOOL_TYPE.GWK      or
       tool_type == OGS_TOOL_TYPE.NEXO     then
       return 1
    end
    if tool_type == OGS_TOOL_TYPE.HANDEINGABE    or
       tool_type == OGS_TOOL_TYPE.CONFIRMATION   or
       tool_type == OGS_TOOL_TYPE.BARCODE_READER then
       known_sys_type[tool_id] = 2
       return 2
    end
	local lua_tool_type = lua_known_tool_types.get_tool_type(tool_id)
	if lua_tool_type == nil then
		return 1		-- default system type
	end
	local get_tags = lua_known_tool_types.get_impl(lua_tool_type,'get_tags')
	if type(get_tags) ~= 'function' then
        return 1		-- default system type
	end

	local sys_type = get_tags(tool_id)
    if not sys_type then
        sys_type = 1
    else
        known_sys_type[tool_id] = sys_type
    end
    return sys_type

end
--------------------------------------------------------------------------------------------

