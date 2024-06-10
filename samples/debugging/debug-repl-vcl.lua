-- simple VCLua debug window with an interactive shell / repl
local vcl = require "vcl.core"
vcl.Application():Initialize()

local form = vcl.Form( nil, {
		name = "myForm",
		caption="Test form",
		width=500,
		height=500,
		left=1800,
		--position="poScreenCenter"
	}
)

local lastlines = {}
local lastpos = 0
local function gather_results(success, ...)
  local n = select('#', ...)
  return success, { n = n, ... }
end
local function showtraceback(...)
  return debug.traceback(...)
end
local function compilechunk(chunk)
    local f,err = loadstring('return ' .. chunk, 'REPL')
    if not f then
        -- try the original code without return
        f,err = loadstring(chunk, 'REPL')
    end
    return f,err
end
local function displayresults(results)
  if results.n == 0 then
    return
  end
  print(unpack(results, 1, results.n))
end
local function displayerror(err)
  print(err)
end

local function memo_onKeyDown(sender, key, shift)  -- TKeyEvent
    key = 0 -- VK_UNKNOWN
end
local function memo_onKeyUp(sender, key, shift)
    key = 0 -- VK_UNKNOWN
end

local labelTxt = "Enter text"
local memo = vcl.Memo( form, { left = 20, top=20, height=400, width=460,
                --OnKeyUp=memo_onKeyUp,
                --OnKeyDown=memo_onKeyDown,
             } )
local edit
local clicked = nil
local function enteredInfo(sender, key)
    if key == 38 then   -- cursor up
        if not clicked then
            lastpos = lastpos - 1
            if lastpos < 1 then lastpos = 1 end
            edit.text = lastlines[lastpos]
            clicked = true
        else
            clicked = nil
        end
    elseif key == 40 then   -- cursor down
        if not clicked then
            lastpos = lastpos + 1
            if lastpos > #lastlines then
                edit.text = ""
                lastpos = #lastlines
            else
                edit.text = lastlines[lastpos]
            end
            clicked = true
        else
            clicked = nil
        end
    elseif key == 13 then
        local line = tostring(sender.text)
        if line == "" or #line == 0 then return end
	    memo:Append("> "..line)     -- add the command line
        local f, err = compilechunk(line)
        if f then
            -- setfenv(f, self:getcontext())
            local success, results = gather_results(xpcall(f, function(...) return showtraceback(...) end))
            if success then
                displayresults(results) --memo:Append(tostring(results))
            else
                displayerror(results[1]) --memo:Append(results[1])
            end
        else
            displayerror(err) --memo:Append(err)
        end
        if lastlines[#lastlines+1] ~= edit.text then
            lastlines[#lastlines+1] = edit.text
            lastpos = #lastlines+1
        end
	    edit.text = ""
	end
end

edit = vcl.Edit( form, { left=20, top=460, width=340, OnKeyUp=enteredInfo} )

-- globally replace the print function to add everything to our memo
print = function(s)
    local txt = tostring(s)
    if txt == "" or #txt == 0 then return end
    memo.Lines:SetText(memo.Lines:GetText() .. txt)
end

form:Show()

-- set a global, so we can reference this from the outside
debug_repl_vcl = {
    form = form,
    edit = edit,
    memo = memo,
    lastlines = lastlines
}

