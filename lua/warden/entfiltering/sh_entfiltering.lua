Warden.ClassFilters = Warden.ClassFilters or {}
Warden.ModelFilters = Warden.ModelFilters or {}

-- get whether the particular entity bypasses warden's permission behavior
function Warden.GetEntPermBypass(entOrClass, perm)
	perm = Warden.GetPermission(perm, true)
	if not perm then return end

	return Warden.GetClassFilter(entOrClass, perm.KEY)
end

function Warden.PlyBypassesFilters(ply)
	return Warden.GetServerSetting("admin_level_filter_bypass") <= ply:WardenGetAdminLevel()
end

function Warden.BlockClass(class)
	Warden.UpdateClassFilter(class, "_block", true)
end

function Warden.UnblockClass(class)
	Warden.UpdateClassFilter(class, "_block")
end

function Warden.BlockModel(model)
	return Warden.UpdateModelFilter(model, true)
end

function Warden.UnblockModel(model)
	return Warden.UpdateModelFilter(model)
end

function Warden.IsModelBlocked(model)
	return Warden.ModelFilters[model] or false
end

function Warden.IsClassBlocked(class)
	return Warden.GetClassFilter(class, "_block") or false
end

function Warden.IsEntityBlocked(ent)
	return Warden.IsModelBlocked(ent:GetModel()) or Warden.IsClassBlocked(ent:GetClass())
end

-- check if an ent is filtered
-- true == always allow, false == always deny
function Warden.GetClassFilter(entOrClass, key, nofilter)
	local class = entOrClass
	if type(entOrClass) ~= "string" then
		if not IsValid(entOrClass) then
			if not key then return {} end
			return
		end

		class = entOrClass:GetClass()
	end

	local filter = Warden.ClassFilters[class]
	if not filter then
		if not key then
			return nofilter and {} or Warden.GetClassWCFilter(class)
		end

		if nofilter then return end
		return Warden.GetClassWCFilter(class)[key]
	end

	if not nofilter then
		filter = Warden.GetClassWCFilter(class, filter)
	end

	if key then
		return filter[key]
	end

	return filter
end

local wildCards = {}
local wcCache = {}

-- add to wild card cache if a class has a wild card
function Warden.SetClassWildCard(wc, filter)
	if string.Right(wc, 1) ~= "*" then return end

	wcCache = {}
	wildCards[wc] = filter
end

-- refresh wild card cache
function Warden.ResetClassWildCards()
	for k, v in pairs(Warden.ClassFilters) do
		if string.Right(k, 1) == "*" then
			wildCards[k] = v
		end
	end

	wcCache = {}
end

-- get the filter of a class derived from wild cards
function Warden.GetClassWCFilter(class, baseFilter)
	if wcCache[class] then return wcCache[class] end

	local runningFilters = {}

	for k, v in pairs(wildCards) do
		local find = string.sub(k, 1, -2)
		find = string.PatternSafe(find)
		if not string.find(class, "^" .. find) then continue end

		table.insert(runningFilters, { wc = k , filter = v })
	end

	-- more generic wildcards should be overridden by more specific ones
	table.sort(runningFilters, function(a, b)
		return string.len(a.wc) < string.len(a.wc)
	end)

	if baseFilter then
		table.insert(runningFilters, { filter = baseFilter })
	end

	local filter = {}
	for _, v in ipairs(runningFilters) do
		for k, v1 in pairs(v.filter) do
			filter[k] = v1
		end
	end

	wcCache[class] = filter

	return filter
end

hook.Add("PostGamemodeLoaded", "WardenWildCards", function()
	Warden.ResetClassWildCards()
end)

-- in case of file reload
if WARDEN_LOADED then
	Warden.ResetClassWildCards()
end