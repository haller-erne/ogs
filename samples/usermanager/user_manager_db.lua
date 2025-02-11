-- User rights management
local db = require("user_db_heUserManager")

----------------------------------------------------------------------------
UserManager.logofftimer = os.clock()
local function UserManagerStateChanged(info)
	-- some interaction with OGS happened - so reset the paasword timeout
	-- NOTE: this is not 100%, as an external process start (e.g. through PLC could also change state!)
	UserManager.logofftimer = os.clock()
end	
--------------------------------------------------------
local ini_tbl = nil
local UserLogOffTimer = 0
local function UserManagerStatePoll(info)
    if ini_tbl == nil then
        ini_tbl = ReadIniSection('USER')
        UserLogOffTimer = (tonumber(ini_tbl.autologoff) or 0) * 60 -- munutes to seconds
    end
	-- notify central database 
    if UserManager.user and #UserManager.user > 0 then
		-- somebody is logged on
		-- Handle out-logout
		if (UserLogOffTimer > 0) and 
		   (os.clock() - UserManager.logofftimer > UserLogOffTimer)  then
			UserManager.Logout()
		else -- Notify DB server, that we are still logged on
        	if os.clock() - db.lastLoginUpdate > 10 then
	    		XTRACE(16, 'refresh user login in db')
                db.NotifyUserLogonState(true, UserManager.user)
   		        if UserManager.master and #UserManager.master > 0 then
                    db.NotifyUserLogonState(true, UserManager.master)
                end        
		    end
		end    
	end
end
----------------------------------------------------
StateChangedFunctions.add(UserManagerStateChanged)
StatePollFunctions.add(UserManagerStatePoll)
----------------------------------------------------
function UserManager.Logout()
    local current_user = UserManager_GetCurrentUser()
    if current_user == nil or #current_user == 0 then
		-- nobody logged on.
        return
    end
	XTRACE(16, 'UserManager.Logout()')
    -- -1 logoff then, show logon banner in ProcessView(block processing)
    ProcessUserLogin(current_user, 0, -1)
end
--------------------------------------------------------------------------------------------
local function TraceUserLogonChange(new_user, curr_user)
    UserManager.logofftimer = os.clock()
    if new_user == curr_user then return end
    if curr_user and #curr_user > 0 then
        db.NotifyUserLogonState(false, curr_user)
    end        
    if new_user and #new_user > 0 then
        db.NotifyUserLogonState(true, new_user)
    end        
end
------------------------------------------------------------------------------
local um_UpdateStatus_old = UserManager_UpdateStatus
function UserManager_UpdateStatus(user, user_level, master, master_level, autologon, user_id, master_id)
    TraceUserLogonChange(user,   UserManager.user)
    TraceUserLogonChange(master, UserManager.master)
	return um_UpdateStatus_old(user, user_level, master, master_level, autologon, user_id, master_id)
end
--------------------------------------------------------------------------------------------
