Warden.ClassFilters = Warden.ClassFilters or {}
Warden.ModelFilters = Warden.ModelFilters or {}

-- update a filter for a class (if superadmin)
function Warden.UpdateClassFilter(class, key, state)
	if not LocalPlayer():IsSuperAdmin() then
		LocalPlayer():ChatPrint("Only superadmins can change Warden's settings.")
		return
	end

	net.Start("WardenEntFiltering")
	net.WriteBool(true)
	net.WriteString(class)
	net.WriteString(key)
	net.WriteBool(state or false)
	net.SendToServer()
end

-- update a filter for a model (if superadmin)
function Warden.UpdateModelFilter(model, state)
	if not LocalPlayer():IsSuperAdmin() then
		LocalPlayer():ChatPrint("Only superadmins can change Warden's settings.")
		return
	end

	net.Start("WardenEntFiltering")
	net.WriteBool(false)
	net.WriteString(model)
	net.WriteBool(state or false)
	net.SendToServer()
end

local function updateClassFilters()
	local count = net.ReadUInt(11)
	for i = 1, count do
		local key = net.ReadString()
		local count1 = net.ReadUInt(6)
		local filter = {}

		for j = 1, count1 do
			local key1 = net.ReadString()
			filter[key1] = net.ReadBool()
		end

		Warden.ClassFilters[key] = filter
	end
end

local function updateModelFilters()
	local count = net.ReadUInt(11)
	for i = 1, count do
		local key = net.ReadString()
		local state = net.ReadBool()

		if state then
			Warden.ModelFilters[key] = true
		else
			Warden.ModelFilters[key] = nil
		end
	end
end

net.Receive("WardenEntFiltering", function()
	if net.ReadBool() then
		updateClassFilters()
	else
		updateModelFilters()
	end
end)