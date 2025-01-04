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
function Warden.GetClassFilter(entOrClass, key)
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
		if not key then return {} end
		return
	end

	if key then
		return filter[key]
	end

	return filter
end