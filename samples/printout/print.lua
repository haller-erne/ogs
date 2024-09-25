local dir = require('pl.dir')

local print = { ENABLED = true}
-------------------------------------------------------------------------------------------------
print.Init =  function( )

	local tbl = ReadIniSection('PRINTER')
	if type(tbl) ~= 'table' then
		XTRACE(1, string.format('INI-section: "PRINTER" not found'))
		return false
	end
	print.ENABLED = tonumber(tbl.ENABLED)
	if not print.ENABLED or print.ENABLED == 0 then
        print.ENABLED = false
        return false
    end

	if type(tbl.FORM) ~= 'string' then
			XTRACE(1, string.format('missing parameter "FORM" in INI-section "PRINTER"'))
		return false
	end
	print.FORM = tbl.FORM

	local pdf = param_as_str(tbl.PDF)
	if #pdf > 0   then
	    local res,err = dir.makepath (pdf)
	    if err then
			XTRACE(1, string.format('PDF folder "'..pdf..'" not found'))
		else
		    print.PDF = pdf
		end
    end

	local printer = param_as_str(tbl.PRINTER)
	if  #printer > 0   then
	    print.PRINTER = printer
	end

	if not print.PRINTER and not print.PDF then
        XTRACE(1, string.format('Invalid section [PRINTER]'))
        print.ENABLED = false
        return false
    end

	print.DB = current_project.base_folder .. '\\station.fdb'
    print.Initialized = true

    return true
end
-------------------------------------------------------------------------------------------------
-- hier the redefinition of GetXMLFile function from system.lua
local GetXMLFile_base = GetXMLFile
local function GetXMLFile_impl(id,model)

    if not print.ENABLED then return nil,nil end
    if not print.Initialized then
        if not print.Init() then return nil,nil end
    end
    -- print enabled and properly initialized
    if print.PRINTER then
        local cmd_line = string.format('locate.exe [sn=%s][db=%s][form=%s][show=true][output=%s]', id, print.DB, print.FORM , print.PRINTER)
        local err = CreateProcess(cmd_line)
        if err then
            XTRACE(1,'print failed:'..err)
        end
    end

    if print.PDF then
        local t = os.date('*t')
        local pfx_day = string.format('%04d%02d%02d',t.year,t.month,t.day)
        local pfx_tim = string.format('%02d%02d%02d',t.hour,t.min,t.sec)
        local file_name = string.format('%s\\%s-%sT%s.pdf', print.PDF, id, pfx_day, pfx_tim)
        local cmd_line = string.format('locate.exe [sn=%s][db=%s][form=%s][show=true][output=%s]', id, print.DB, print.FORM , file_name)
        local err = CreateProcess(cmd_line)
        if err then
            XTRACE(1,'print failed:'..err)
        end
    end
    return GetXMLFile_base(id,model)

end
-------------------------------------------------------------------------------------------------
GetXMLFile = GetXMLFile_impl

