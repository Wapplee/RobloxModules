local module = {}
local recheckList = {}

local function getParentFunc(p)
	return type(p) == "function" and p or function() return typeof(p) == "Instance" and p or game end
end

local function isValidScript(s)
	return typeof(s) == "Instance" and s:IsDescendantOf(game)
end

local function getAllValues(parent, value, forceIndex, valueType)
	if not parent then return {} end
	local results = {}
	local valuesToFind = type(value) == "table" and value or {value}
	local indicesToFind = type(forceIndex) == "table" and forceIndex or (forceIndex and {forceIndex} or nil)

	local funcs = filtergc("function", {
		IgnoreExecutor = true,
		Constants = valueType == "constant" and valuesToFind or nil,
		Upvalues = valueType == "upvalue" and valuesToFind or nil,
	})
	
	for _, func in funcs do
		local sok, env = pcall(getfenv, func)
		if not sok or type(env) ~= "table" then continue end

		local s = rawget(env, "script")
		if not isValidScript(s) then continue end
		if not (s == parent or s:IsDescendantOf(parent)) then continue end

		local ok, values = pcall(debug[`get{valueType}s`], func)
		if not ok then continue end

		for i, v in pairs(values) do
			local valueMatch = table.find(valuesToFind, v)
			local indexMatch = not indicesToFind or table.find(indicesToFind, i)
			if not valueMatch or not indexMatch then continue end
			local entry = {
				Script = s, Function = func, Index = i, Type = valueType,
				ogValue = v, Value = v,
				getFunc = debug[`get{valueType}`],
				setFunc = debug[`set{valueType}`],
			}
			local proxy = newproxy(true)
			local mt = getmetatable(proxy)
			mt.__index = entry
			mt.__newindex = function(_, k, val)
				if k == "Value" then entry.setFunc(entry.Function, entry.Index, val) end
				entry[k] = val
			end
			table.insert(results, proxy)
		end
	end
	return results
end

function module:createValueGroup(parentF, value, forceIndex, valuetype, recheck)
	valuetype = valuetype or "constant"
	local parentFunc = getParentFunc(parentF)
	local prox = newproxy(true)
	local tab = {
		ParentF = parentFunc,
		Grouped = getAllValues(parentFunc(), value, forceIndex, valuetype),
		ogValue = value, Value = value,
		forceIndex = forceIndex,
		Type = valuetype, Enabled = true,
		setFunc = debug[`set{valuetype}`],
	}
	tab.Reset = function() prox.Value = tab.ogValue end
	tab.Stop = function() tab.Reset() tab.Enabled = false end
	tab.Destroy = function()
		tab.Stop()
		local idx = table.find(recheckList, tab)
		if idx then table.remove(recheckList, idx) end
	end

	if recheck then table.insert(recheckList, tab) end

	local mt = getmetatable(prox)
	mt.__index = tab
	mt.__newindex = function(_, k, val)
		if k == "Value" then
			for i, v in tab.Grouped do
				if not isValidScript(v.Script) then table.remove(tab.Grouped, i) continue end
				tab.setFunc(v.Function, v.Index, val)
			end
		end
		tab[k] = val
	end
	return prox
end

-- recheck loop
function module:Initiate(check)
	local stop = false
	check.Destroying:Connect(function() stop = true end)
	task.spawn(function()
		while task.wait(.5) and not stop do
			for _, v in recheckList do
				if not v.Enabled then continue end
				for j = #v.Grouped, 1, -1 do
					if not isValidScript(v.Grouped[j].Script) then
						table.remove(v.Grouped, j)
					end
				end
				local parent = v.ParentF()
				if not parent then continue end
				for _, val in getAllValues(parent, v.ogValue, v.forceIndex, v.Type) do
					local found = false
					for _, existing in v.Grouped do
						if existing.Script == val.Script then found = true break end
					end
					if not found then
						table.insert(v.Grouped, val)
						val.Value = v.Value
					end
				end
			end
		end
	end)
end

function module:getValues(parent, value, forceIndex, valueType)
	return getAllValues(parent or game, value, forceIndex, valueType or "constant")
end

function module:searchValues(value, checktype)
	warn("-- SEARCHING... --")
	for gcnum, func in pairs(getgc()) do
		if not (type(func) == "function" and islclosure(func) and not isexecutorclosure(func)) then continue end
		local ok, values = pcall(debug[`get{(checktype or "constant")}s`], func)
		if not ok then continue end
		for i, v in pairs(values) do
			if v ~= value then continue end
			local sok, env = pcall(getfenv, func)
			if sok and type(env) == "table" and rawget(env, "script") then
				warn("Script:", env.script:GetFullName())
			end
			warn("Value Number:", i)
			warn("------------------")
		end
		if tostring(gcnum):sub(-2,-1) == "00" then task.wait() end
	end
end

getgenv().memoryModule = module
getgenv().MemoryModule = module

--[[
local valg = createValueGroup(game, "Stamina", "constant", true)
valg.Value = "MaxStamina"

task.wait(40)
valg:Destroy()
--]]

return module
