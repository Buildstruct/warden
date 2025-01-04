util.AddNetworkString("WardenEntFiltering")

do
	local filter = file.Read("warden/classfilters.json", "DATA")
	if filter then
		Warden.ClassFilters = util.JSONToTable(filter)
	else
		Warden.ClassFilters = Warden.ClassFilters or {}
	end

	local filter1 = file.Read("warden/modelfilters.json", "DATA")
	if filter1 then
		Warden.ModelFilters = util.JSONToTable(filter1)
	else
		Warden.ModelFilters = Warden.ModelFilters or {}
	end
end

local function netFilter(filter)
	if not filter then
		net.WriteUInt(0, 6)
		return
	end

	net.WriteUInt(table.Count(filter), 6)
	for k, v in pairs(filter) do
		net.WriteString(k)
		net.WriteBool(v)
	end
end

-- update a filter for a class
function Warden.UpdateClassFilter(class, key, state)
	local filter
	if type(key) == "table" then
		filter = key
	elseif key ~= nil then
		filter = Warden.GetClassFilter(class, nil, true)
		filter[key] = state
	end

	if table.IsEmpty(filter) then
		filter = nil
	end

	Warden.ClassFilters[class] = filter
	Warden.SetClassCache(class, filter)
	file.Write("warden/classfilters.json", util.TableToJSON(Warden.ClassFilters))

	net.Start("WardenEntFiltering")
	net.WriteBool(true)
	net.WriteUInt(1, 11)
	net.WriteString(class)
	netFilter(filter)
	net.Broadcast()
end

-- update a model filter
-- true == block
function Warden.UpdateModelFilter(model, state)
	if state == false then
		state = nil
	end

	Warden.ModelFilters[model] = state
	file.Write("warden/modelfilters.json", util.TableToJSON(Warden.ModelFilters))

	net.Start("WardenEntFiltering")
	net.WriteBool(false)
	net.WriteUInt(1, 11)
	net.WriteString(model)
	net.WriteBool(state or false)
	net.Broadcast()
end

local function sendAll(callback)
	net.Start("WardenEntFiltering")
	net.WriteBool(true)
	net.WriteUInt(table.Count(Warden.ClassFilters), 11)
	for k, v in pairs(Warden.ClassFilters) do
		net.WriteString(k)
		netFilter(v)
	end
	callback()

	net.Start("WardenEntFiltering")
	net.WriteBool(false)
	net.WriteUInt(table.Count(Warden.ModelFilters), 11)
	for k, v in pairs(Warden.ModelFilters) do
		net.WriteString(k)
		net.WriteBool(v)
	end
	callback()
end

-- in case of file reload
if WARDEN_LOADED then
	sendAll(net.Broadcast)
end

gameevent.Listen("player_activate")
hook.Add("player_activate", "WardenClassFilter", function(data)
	local ply = Player(data.userid)
	if not ply:IsValid() then return end

	sendAll(function()
		net.Send(ply)
	end)
end)

net.Receive("WardenEntFiltering", function(_, ply)
	if not ply:IsSuperAdmin() then
		ply:ChatPrint("Only superadmins can change Warden's settings.")
		return
	end

	if net.ReadBool() then
		local class = net.ReadString()
		local count = net.ReadUInt(6)
		local filter = {}

		for j = 1, count do
			local key = net.ReadString()
			filter[key] = net.ReadBool()
		end

		Warden.UpdateClassFilter(class, filter)
	else
		local model = net.ReadString()
		local state = net.ReadBool()
		Warden.UpdateModelFilter(model, state)
	end
end)