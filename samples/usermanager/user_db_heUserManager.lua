---@brief [[
--- Helper-Module for card/certifications verification in SQL server DB
--- Implement the interface for the heUserManager database access
---@brief ]]

---@class UserManagerDbInterface
---@field private connectionString string Database connection string (ADO format)
---@field private logonGroup string Additional group to check user membership for (for mapping specific user access to a class/group of stations)
---@field private logonAppid string App-ID to use when querying the database
---@field private lastLoginUpdate integer Timeout for login checks
local M = {
	lastLoginUpdate = 0,
}
-- Module level documentation, see https://luals.github.io/wiki/annotations/
---@module 'dpapi'
---@module 'mime'
local json = require('cjson')
local bit32 = require("bit32")

-------------------------------------------------------------
M.GetStationName = function()
    if not M.StationName then
        local ini_tbl = ReadIniSection('GENERAL')
        M.StationName = param_as_str(ini_tbl.STATION_NAME)
    end 
    return M.StationName
end 
------------------------------------------------------------

---Initialize the module
---@param connectionString? string Use the given encrypted or plaintext connectionstring. If nil, then load from station.ini (from section [USER] and parameter logonserver= ).
---@param logonGroup? string Use the given logon group name. If nil, then load from station.ini (from section [USER] and parameter logongroup= ).
---@param logonAppid? string Use the given appid for database queries name. If nil, then try to load from station.ini (or use the default 'OGS').
---@return boolean | nil Ok If the database string is a valid string, then return true, else nil
---@return string | nil Errorstring If some error occurs, then return a descriptive text
M.Init = function(connectionString, logonGroup, logonAppid)

    M.GetStationName()
	M.connectionString = nil
	M.logonGroup = nil
	-- Use the given connection string or read from station.ini
	local cs = connectionString or ReadIniValue('USER', 'logonserver')
	if not cs or #cs == 0 then
		XTRACE(1, "[USER] Error: Invalid or empty connection string given (or in station.ini [USER]:logonserver)")
		M.SetAlarm(-1, 'Invalid or empty connection string for user database access!')
		return nil, 'Invalid or empty connection string!'
	end
	local lg = logonGroup or ReadIniValue('USER', 'logongroup')
	if lg and #lg > 0 then
		M.logonGroup = lg
	else
		M.logonGroup = '' -- 'ogs_users'
	end
	local ai = logonAppid or ReadIniValue('USER', 'logonappid')
	if ai and #ai > 0 then
		M.logonAppid = ai
	else
		M.logonAppid = 'heOGS'
	end
	-- Try to decrypt the connection string (it might be encrypted)
	local dpapi = require('luadpapi')   -- load the DPAPI
	local mime = require('mime')        -- load luasocket/mime (base64)
	local encrypted = mime.unb64(cs)	-- base64 decode the encrypted string to the raw binary buffer
	local connstr, err = dpapi.unprotect(encrypted)	-- try to decrypt
	if connstr ~= nil then				-- Success, use the decoded string!
		cs = connstr
	else
		XTRACE(2, "[USER] Error while decrypting 'logonserver' connection sting in INI file: "..param_as_str(err))
	end
	M.connectionString = cs
	
	
	return true
end

---Get the database connection string. Returns a connectionString or '' (if no connection string is defined in ini file)
---@return string connectionString Database connection string
M.ConnectionString = function()
	if M.connectionString then
		return M.connectionString
	end
	local ok, err = M.Init()
	if not ok then
		return ''
	end
	return M.connectionString
end

---Clears any eventually pending alarm
M.ResetAlarm = function()
	ResetLuaAlarm('user_db_alarm')
end

---Clears any eventually pending alarm
M.SetAlarm = function(level, message)
	SetLuaAlarm('user_db_alarm', level, message)
end

---@class LoginResult
---@field LoginAllowed boolean True, if login is allowed (certificates and group checks ok)
---@field MissinOrOutdatedCount integer Certificate result, 0 = ok, > 0 missing or outdated, -1 = user not found, -2 = user not member of group
---@field UserRights integer Bitmap of user rights as defined in the database (permissions as defined in the app-role)
---@field UserId integer Database User ID
---@field UserName string The user name (short name)
---@field CardNumber string Database card number
---@field UserLevel integer Database User level
---@field Password string Password
---@field db_row table Database user table row

-----------------------------------------------------------------------------
---(internal) send lock release to Database for current user
---@return string: ErrorMessage 
M.LoginRelease = function (user_name)
    local Params = { USER_ID = user_name,  HOST_NAME = M.GetStationName() }
	XTRACE(16, 'logoff user from db')
	local tbl, err = luaOpenStoredProc(M.ConnectionString(), 'DB_LOCK_RELEASE', Params)
   	if err then
    	-- something went badly wrong (exception, e.g. database not connected, wrong connection string, ...)
	    XTRACE(1, 'DB_LOCK_RELEASE failed(UserID='.. param_as_str(user_name) ..'). Error:' ..param_as_str(err))
   		return 'DB_LOCK_RELEASE - database error: ' .. param_as_str(err)
    end
    return nil -- no error
end
-----------------------------------------------------------------------------
---(internal) Check if user is already logged in on another station
---@return string: ErrorMessage 
M.LoginLock = function (user_name)
    local error_msg = nil   -- no error
    local Params = {	USER_ID = user_name,  HOST_NAME = M.GetStationName() }
	XTRACE(16, 'refresh user login in db')
    M.lastLoginUpdate = os.clock()
	local tbl, err = luaOpenStoredProc(M.ConnectionString(), 'DB_LOCK_REQUEST', Params)
   	if err then
       	-- something went badly wrong (exception, e.g. database not connected, wrong connection string, ...)
       	error_msg = 'DB_LOCK_REQUEST failed(UserID='.. param_as_str(user_name) ..'). Error:' ..param_as_str(err) 
    else
    	if tbl and tbl[1] then
    		local result    = tbl[1].RESULT
		    local message   = tbl[1].MESSAGE; 
		    if result ~= 1 then
                error_msg = 'DB_LOCK_REQUEST failed(UserID='.. param_as_str(user_name) ..').'..param_as_str(message) 
		    end
		else 
            error_msg = 'DB_LOCK_REQUEST: invalid return value(UserID='.. param_as_str(user_name) ..')'
	    end    
	end    
    if error_msg then
        XTRACE(1, error_msg)
    end    
    return error_msg
end
-----------------------------------------------------------------------------

---(internal) Check if user is allowed to log on
---@param tbl table Row from Users database table
---@param id string Id (username or cardnumber, only used for error message)
---@return LoginResult|nil Table with login result data
---@return string? ErrorMessage Error message (only if LoginResult is nil)
local function returnValidationInfo(tbl, id)
	if tbl and tbl[1] then
		-- User is found, so we have all data in [ret]
		local cardnumber = tbl[1].cardnumber
		local level = tbl[1].ogs_level
		local password = tbl[1].ogs_password
		local user_id = tbl[1].user_id
		local AuthResult, err = M.ValidateUserById(user_id)
		if AuthResult then
			if AuthResult.LoginAllowed then
				local LoginResult = {
					LoginAllowed = AuthResult.LoginAllowed,
					MissinOrOutdatedCount = AuthResult.MissinOrOutdatedCount,
					UserRights = AuthResult.UserRights,
					UserId = user_id,
					UserName = tbl[1].short_name,
					CardNumber = cardnumber,
					UserLevel = level,
					Password = password,
					db_row = tbl[1],
				}
				return LoginResult
			else
				return nil, 'User is not allowed to log on (certificate or group)'
			end
		end
		return nil, err
	end
	-- User not found in database! Card number is INVALID!
	XTRACE(1, "Validation failed (ID='".. id .."'): not found in database.")
	M.SetAlarm(-1, "ID '".. id .."' not found in database!")
	return nil, "ID '".. id .."' not found in database!"
end

---Query the database for user data for a given card id. This is mainly used to
---retrieve the unique database user_id, which can then be used in further calls
---to authenticate the user and get more details. But it can also be used to
---quickly get the users card number, password, primary OGS level and other details.
---@param CardID string The card id to query user details data from the database
---@return LoginResult|nil Table with login result data
---@return string? ErrorMessage Error message (only if LoginResult is nil)
M.GetUserByCardID = function(CardID)

	if M.ConnectionString() == '' then
		return nil, 'Error: no database connection string defined!'
	end
	M.ResetAlarm()
	XTRACE(16, "Get user by CardID '".. CardID .."'. logon through database...")
	local Params = {}
	Params.cardnumber = param_as_str(CardID)
	local tbl, err = luaOpenStoredProc(M.ConnectionString(), 'SP_GetUserByCardnumber', Params)
	if err then
		-- something went badly wrong (exception, e.g. database not connected, wrong connection string, ...)
		XTRACE(1, "Get user by CardID '".. CardID .."' -> "..param_as_str(err))
		M.SetAlarm(-1, 'Authorization-DB inaccessible: ' .. param_as_str(err))
		return nil,nil
	end
	return returnValidationInfo(tbl, CardID)
end

---Query the database for user data for a given user name. This is mainly used to
---retrieve the unique database user_id, which can then be used in further calls
---to authenticate the user and get more details. But it can also be used to
---quickly get the users card number, password, primary OGS level and other details.
---@param UserName string The user name to query user details data from the database
---@return LoginResult|nil Table with login result data
---@return string? ErrorMessage Error message (only if LoginResult is nil)
M.GetUserByUserName = function(UserName)

	if M.ConnectionString() == '' then
		return nil, 'Error: no database connection string defined!'
	end
	M.ResetAlarm()
	XTRACE(16, "Get user by name '".. UserName .."'. logon through database...")
	local Params = {}
	Params.shortname = param_as_str(UserName)
	local tbl,err = luaOpenStoredProc(M.ConnectionString(), 'SP_GetUserByName', Params)
	if err then
		-- something went badly wrong (exception, e.g. database not connected, wrong connection string, ...)
		XTRACE(1, "Get user by name '".. UserName .."' -> "..param_as_str(err))
		M.SetAlarm(-1, 'Authorization-DB inaccessible: ' .. param_as_str(err))
		return nil,nil
	end
	return returnValidationInfo(tbl, UserName)
end

---@class AuthResult
---@field LoginAllowed boolean True, if login is allowed (certificates and group checks ok)
---@field MissinOrOutdatedCount integer Certificate result, 0 = ok, > 0 missing or outdated, -1 = user not found, -2 = user not member of group
---@field UserRights integer Bitmap of user rights as defined in the database (permissions as defined in the app-role)

---Check, if a given user (by its database-user-id) is allowed to log in or not.
---Also returns the authentication details (app-rights)
---@param UserID number Database User-ID of the user to query the database
---@return nil|AuthResult AuthResult
---@return string? ErrorMessage Error message, if AuthResult is nil
M.ValidateUserById = function(UserID)

	if M.ConnectionString() == '' then
		return nil, 'Error: no database connection string defined!'
	end
	M.ResetAlarm()
	XTRACE(16, "Authenticate user by User ID='".. UserID .."' ...")
	local Params = {}
	Params.user_id   = UserID
	Params.groupname = param_as_str(M.logonGroup)
	Params.appname   = param_as_str(M.logonAppid)
	local tbl, err = luaOpenStoredProc(M.ConnectionString(), 'SP_ValidateUserById', Params)
	if err then
		-- something went badly wrong (exception, e.g. database not connected, wrong connection string, ...)
		XTRACE(1, "RFID DB validation failed (UserID='".. UserID .."'): "..tostring(err))
		M.SetAlarm(-1, 'Error authenticating user - database error: ' .. tostring(err))
		return nil, 'Error authentication user - database error: ' .. tostring(err)
	end
    if tbl and tbl[1] then
		local row = tbl[1]		-- only the first row contins data
		local MissingOrOutdatedCount = tonumber(row.MissingOrOutdatedCount)
		if MissingOrOutdatedCount then
			if MissingOrOutdatedCount == 0 then
				-- Certificate and group checks are ok, so calculate the user rights
				local UserRights = 0
				local JsonAppRights = row.JsonAppRights
				if JsonAppRights then
					local rows = json.decode(JsonAppRights)
					for k,v in pairs(rows) do
						if v.code and tonumber(v.code) then
							UserRights = UserRights + tonumber(v.code)
						end
					end
				end
				local AuthResult = {
					LoginAllowed = true,
					MissinOrOutdatedCount = MissingOrOutdatedCount,
					UserRights = UserRights
				}
				return AuthResult
			end
		end
		if MissingOrOutdatedCount > 0 then
			M.SetAlarm(-1, 'Certificate(s) expired!')
		end
		if MissingOrOutdatedCount == -1 then
			M.SetAlarm(-1, 'User not found!')
		end
		if MissingOrOutdatedCount == -2 then
			M.SetAlarm(-1, "User is not a member of the '"..param_as_str(M.logonGroup).."' group!")
		end
		local AuthResult = {
			LoginAllowed = false,
			MissinOrOutdatedCount = MissingOrOutdatedCount,
			UserRights = 0
		}
		return AuthResult
    end
	-- something is wrong
	XTRACE(1, "RFID DB validation failed (UserID='".. UserID .."'): ")
	M.SetAlarm(-1, "User ID '".. UserID .."' not found in Database!")
	return nil, "User ID '".. UserID .."' not found in Database!"
end
--------------------------------------------------------------------------------------------------------------
M.NotifyUserLogonState = function(isLoggedOn, user_name)
    local err
	if isLoggedOn then
	    err = M.LoginLock(user_name)
	else
	    err = M.LoginRelease(user_name)
	end
	if err then
        M.SetAlarm(-1, err)
    end    
end
--------------------------------------------------------------------------------------------------------------

--local loginResult, err
--loginResult, err = M.GetUserByUserName('holger2')
--loginResult, err = M.GetUserByUserName('holger1')
--loginResult, err = M.GetUserByCardID('U40003ACC4D')
--loginResult, err = M.GetUserByCardID('U40003ACC4Dxxx')

--------------------------------------------------------------------------------------------------------------
-- OGS Database user validation interface implementation
--------------------------------------------------------------------------------------------------------------

-- Use this modules functions to access the database
local db = M

----------------------------------------------------
local function granted(UserRights, right)
   
    local res = bit32.band(UserRights, right)
    return (res ~= 0)
end 
----------------------------------------------------
function UserManager_HasDBRight(right)

    local loginResult = M.userinfo[UserManager.user]
    if loginResult and loginResult.UserRights then 
        if granted(loginResult.UserRights, right) then 
            return 1
        end    
        loginResult = M.userinfo[UserManager.master]
        if loginResult and granted(loginResult.UserRights, right) then 
            return 1
        end   
        return 0 
    end    
	return -1
end
---------------------------------------------------------------------------------------
---@param CardID string CardID to use for searching the user
---@return string? userName User name for the given card ID (nil or false if not found)
---@return integer|string? userLevel User level for the given card ID (nil or false if not found, 1=User, 2=Supervisor, 3=Admin, ...)
function UserManager_GetUserFromDByID(CardID)
    local err
    db.ResetAlarm()
    local loginResult = M.userinfo[user_name]
    if not loginResult then 
    	loginResult, err = db.GetUserByCardID(CardID)
		M.userinfo[loginResult.UserName] = loginResult
    end    
	if loginResult then
		-- Found user!
		err = db.LoginLock(loginResult.UserName)
        if err then
            db.SetAlarm(-1, err)
            XTRACE(1, err)
        else    -- OK!
    		return loginResult.UserName, loginResult.UserLevel
		end
	end
	-- Error. Note: currently OGS cannot handle the error text, this is ignored.
    return nil, err
 end
---------------------------------------------------------------------------------------
function UserManager_GetUserDataFromDB(user_name)
    local err
    db.ResetAlarm()
    local loginResult = M.userinfo[user_name]
    if not loginResult then 
        XTRACE(16, 'UserManager_GetUserDataFromDB: User: '.. user_name)
        if user_name == 'Autologon' then return nil end

        last = {}
	    if user_name == UserManager.user then
            XTRACE(16, '  --> operator already logged on.')
		    return param_as_str(UserManager.user_id)..','..param_as_str(UserManager.user_level)..','..param_as_str(UserManager.user_id)
	    end
	    if user_name == UserManager.master then
            XTRACE(16, ' --> supervisor already logged on.')
		    return param_as_str(UserManager.master_id)..','..param_as_str(UserManager.master_level)..','..param_as_str(UserManager.master_id)
	    end
	    loginResult, err = db.GetUserByUserName(user_name)
		M.userinfo[user_name] = loginResult
	end    
	if loginResult then
		-- Found user!
		err = db.LoginLock(loginResult.UserName)
        if err then
            db.SetAlarm(-1, err)
            XTRACE(1, err)
    	    return nil
		end
        local res = string.format('%s,%d,%s', loginResult.Password, loginResult.UserLevel, param_as_str(loginResult.CardNumber))
		return res
	end
    XTRACE(16, '  --> no valid user id.')
	return nil
end
----------------------------------------------------------------------------


return M
