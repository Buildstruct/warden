Warden.ClassFilters = Warden.ClassFilters or {}
Warden.ModelFilters = Warden.ModelFilters or {}

Warden.FILTER_NET_SIZE = 11
Warden.CLASS_FILTER_NET_SIZE = 6

function Warden.PlyBypassesFilters(ply)
	return Warden.GetServerSetting("admin_level_filter_bypass") <= ply:WardenGetAdminLevel()
end

function Warden.BlockClass(class)
	Warden.UpdateClassFilter(class, "_allow", false)
end

function Warden.UnblockClass(class)
	Warden.UpdateClassFilter(class, "_allow")
end

function Warden.BlockModel(model)
	return Warden.UpdateModelFilter(model, true)
end

function Warden.UnblockModel(model)
	return Warden.UpdateModelFilter(model)
end

function Warden.IsModelBlocked(model)
	if not model then return false end

	return (Warden.ModelFilters[model] or false) ~= Warden.GetServerBool("model_filter_whitelist", false)
end

function Warden.IsClassBlocked(class)
	local allow = Warden.GetClassFilter(class, "_allow")
	if allow == nil then return false end

	return not allow
end

function Warden.IsEntityBlocked(ent)
	return Warden.IsModelBlocked(ent:GetModel()) or Warden.IsClassBlocked(ent:GetClass())
end

-- check if an ent is filtered
-- omit key to get entire filter
-- true == always allow, false == always deny
function Warden.GetClassFilter(entOrClass, key, noWildCard)
	if not entOrClass then
		if not key then return {} end
		return
	end

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
		filter = {}
	end

	if not noWildCard then
		filter = Warden._GetClassWCFilter(class, filter)
	end

	if key then
		return filter[key]
	end

	return filter
end

-- get whether the particular entity bypasses warden's permission behavior
-- intended to be internal
function Warden._GetEntPermBypass(entOrClass, perm)
	perm = Warden.GetPermission(perm, true)
	if not perm then return end

	local bypass = Warden.GetClassFilter(entOrClass, perm.KEY)
	if bypass ~= true then return bypass end

	local bypassBlocked = Warden.GetClassFilter(entOrClass, "_bypass") or false
	if Warden.GetServerBool("class_filter_bypass", false) ~= bypassBlocked then return true end
end

local wildCards = {}
local wcCache = {}

-- reset caches when a class is updated
-- intended to be internal
function Warden._SetClassCache(class, filter)
	wcCache = {}

	if string.Right(class, 1) ~= "*" then return end

	wildCards[class] = filter
end

-- reset caches on reload/start
-- intended to be internal
function Warden._ResetClassCaches()
	for k, v in pairs(Warden.ClassFilters) do
		if string.Right(k, 1) == "*" then
			wildCards[k] = v
		end
	end

	wcCache = {}
end

-- get the filter of a class derived from wild cards
-- intended to be internal
function Warden._GetClassWCFilter(class, baseFilter)
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
	Warden._ResetClassCaches()
end)

-- in case of file reload
if WARDEN_LOADED then
	Warden._ResetClassCaches()
end