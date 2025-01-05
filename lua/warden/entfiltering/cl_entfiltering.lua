Warden.ClassFilters = Warden.ClassFilters or {}
Warden.ModelFilters = Warden.ModelFilters or {}

-- update a filter for a class (if superadmin)
function Warden.UpdateClassFilter(class, key, state)
	if not LocalPlayer():IsSuperAdmin() then
		LocalPlayer():ChatPrint("Only superadmins can change Warden's settings.")
		return true
	end

	local filter
	if type(key) == "table" then
		filter = key
	elseif key == nil then
		filter = {}
	else
		filter = Warden.GetClassFilter(class, nil, true)
		filter[key] = state
	end

	net.Start("WardenEntFiltering")
	net.WriteBool(true)
	net.WriteString(class)
	net.WriteUInt(table.Count(filter), Warden.CLASS_FILTER_NET_SIZE)
	for k, v in pairs(filter) do
		net.WriteString(k)
		net.WriteBool(v)
	end
	net.SendToServer()
end

-- update a filter for a model (if superadmin)
function Warden.UpdateModelFilter(model, state)
	if not LocalPlayer():IsSuperAdmin() then
		LocalPlayer():ChatPrint("Only superadmins can change Warden's settings.")
		return true
	end

	net.Start("WardenEntFiltering")
	net.WriteBool(false)
	net.WriteString(model)
	net.WriteBool(state or false)
	net.SendToServer()
end

local function updateClassFilters()
	local count = net.ReadUInt(Warden.FILTER_NET_SIZE)
	for i = 1, count do
		local class = net.ReadString()
		local count1 = net.ReadUInt(Warden.CLASS_FILTER_NET_SIZE)
		local filter = {}

		for j = 1, count1 do
			local key = net.ReadString()
			filter[key] = net.ReadBool()
		end

		if table.IsEmpty(filter) then
			filter = nil
		end

		Warden.ClassFilters[class] = filter
		Warden._SetClassCache(class, filter)
	end
end

local function updateModelFilters()
	local count = net.ReadUInt(Warden.FILTER_NET_SIZE)
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