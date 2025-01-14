CreateClientConVar("warden_touch_self", 1, true, true, "Whether you can touch your own entities.", 0, 1)
CreateClientConVar("warden_touch", 1, true, true, "Whether you can touch any entities.", 0, 1)
local permPersist = CreateClientConVar("warden_perm_persist", 0, true, true, "Allow permissions to persist across sessions.", 0, 1)

if not permPersist:GetBool() then
	sql.Query("DROP TABLE IF EXISTS warden_cl_perms;")
end
sql.Query("CREATE TABLE IF NOT EXISTS warden_cl_perms ( steamID TEXT PRIMARY KEY ON CONFLICT REPLACE, perms TEXT );")

local function netReceiver(receiver)
	local recID
	if IsValid(receiver) then
		net.WriteBool(false)
		net.WritePlayer(receiver)
		recID = receiver:SteamID()
	else
		net.WriteBool(true)
		recID = "global"
	end

	return recID
end

local function sendPerm(receiver, keyOrID, granting)
	local permID = Warden.PermID(keyOrID)
	if not permID then return end

	net.Start("WardenUpdatePerms")
	net.WriteUInt(permID, Warden.PERM_NET_SIZE)
	local recID = netReceiver(receiver)
	net.WriteBool(granting or false)
	net.SendToServer()

	Warden._UpdatePersistPerm(recID, permID, granting)
end

-- set that one player allows another for a perm
-- receiver can be nil
function Warden.GrantPermission(receiver, keyOrID)
	sendPerm(receiver, keyOrID, true)
end

-- opposite of above
function Warden.RevokePermission(receiver, keyOrID)
	sendPerm(receiver, keyOrID)
end

-- determine whether to grant or revoke based on a bool
function Warden.PermissionRequest(receiver, val, keyOrID)
	if val then
		Warden.GrantPermission(receiver, keyOrID)
	else
		Warden.RevokePermission(receiver, keyOrID)
	end
end

local function parse(perms)
	local perms1 = {}
	for k, v in pairs(perms) do
		if not v then continue end

		local key = Warden.PermKey(k, true)
		if key then
			table.insert(perms1, key)
		end
	end

	return sql.SQLStr(table.concat(perms1, ";"))
end

local function unparse(text)
	local perms = string.Explode(";", text)
	local perms1 = {}

	for _, v in ipairs(perms) do
		local id = Warden.PermID(v, true)
		if id then
			perms1[id] = true
		end
	end

	return perms1
end

-- intended to be internal
function Warden._UpdatePersistPerm(recID, permID, state)
	local perms = Warden._GetPersistPerms(recID)

	if state then
		perms[permID] = true
	else
		perms[permID] = nil
	end

	Warden._SetPersistPerms(recID, perms)
end

-- intended to be internal
function Warden._SetPersistPerms(recID, perms)
	local pPerms = parse(perms)

	if pPerms == "" then
		sql.Query(string.format("DELETE FROM warden_cl_perms WHERE steamID = %s;", sql.SQLStr(recID)))
		return
	end

	sql.Query(string.format("INSERT INTO warden_cl_perms ( steamID, perms ) VALUES ( %s, %s );", sql.SQLStr(recID), pPerms))
end

-- intended to be internal
function Warden._GetPersistPerms(recID)
	local q = sql.QueryValue(string.format("SELECT perms FROM warden_cl_perms WHERE steamID = %s LIMIT 1;", sql.SQLStr(recID)))
	if not q then return {} end

	return unparse(q)
end

-- intended to be internal
function Warden._GetAllPersistPerms()
	local q = sql.Query("SELECT * FROM warden_cl_perms;")
	if not q then return {} end

	local allPerms = {}
	for _, v in pairs(q) do
		allPerms[v.steamID] = unparse(v.perms)
	end

	return allPerms
end

net.Receive("WardenUpdatePerms", function()
	if net.ReadBool() then
		Warden.PlyPerms = {}
	end

	local graC = net.ReadUInt(Warden.PERM_PLY_NET_SIZE)
	for i = 1, graC do
		local graID = util.SteamIDFrom64(net.ReadUInt64())

		Warden.SetupPlayer(graID)

		local permC = net.ReadUInt(Warden.PERM_NET_SIZE)
		for j = 1, permC do
			local permID = net.ReadUInt(Warden.PERM_NET_SIZE)

			local recC = net.ReadUInt(Warden.PERM_SET_NET_SIZE)
			for k = 1, recC do
				local recID64 = net.ReadUInt64()

				local recID
				if recID64 == Warden.GLOBAL_ID then
					recID = "global"
				else
					recID = util.SteamIDFrom64(recID64)
				end

				Warden.PlyPerms[graID][permID] = Warden.PlyPerms[graID][permID] or {}
				Warden.PlyPerms[graID][permID][recID] = net.ReadBool()
			end
		end
	end
end)

local function sendAllPersists()
	local perms = Warden._GetAllPersistPerms()
	local humans = player.GetHumans()

	net.Start("WardenPersistPerms")
	net.WriteUInt(#humans + 1, Warden.PERM_PLY_NET_SIZE)

	net.WriteBool(true)
	local permsG = perms["global"]
	if permsG then
		net.WriteUInt(table.Count(permsG), Warden.PERM_NET_SIZE)
		for k, _ in pairs(permsG) do
			net.WriteUInt(k, Warden.PERM_NET_SIZE)
		end
	else
		net.WriteUInt(0, Warden.PERM_NET_SIZE)
	end

	for _, receiver in ipairs(humans) do
		netReceiver(receiver)

		local recID = receiver:SteamID()
		local perms1 = perms[recID]

		if not perms1 then
			net.WriteUInt(0, Warden.PERM_NET_SIZE)
			continue
		end

		net.WriteUInt(table.Count(perms1), Warden.PERM_NET_SIZE)
		for k, _ in pairs(perms1) do
			net.WriteUInt(k, Warden.PERM_NET_SIZE)
		end
	end
	net.SendToServer()
end

local maxplayersBits = math.ceil(math.log(1 + game.MaxPlayers()) / math.log(2))

local function sendPly(steamID, entIndex)
	local perms = Warden._GetPersistPerms(steamID)
	if table.IsEmpty(perms) then return end

	net.Start("WardenPersistPerms")
	net.WriteUInt(1, Warden.PERM_PLY_NET_SIZE)
	net.WriteBool(false)
	net.WriteUInt(entIndex, maxplayersBits)
	net.WriteUInt(table.Count(perms), Warden.PERM_NET_SIZE)
	for k, _ in pairs(perms) do
		net.WriteUInt(k, Warden.PERM_NET_SIZE)
	end

	net.SendToServer()
end

hook.Add("InitPostEntity", "WardenPerms", function()
	hook.Add("OnEntityCreated", "WardenPerms", function(ent)
		if ent:IsPlayer() then
			sendPly(ent:SteamID(), ent:EntIndex())
		end
	end)

	sendAllPersists()
end)

gameevent.Listen("player_disconnect")
hook.Add("player_disconnect", "WardenPlayerDisconnect", function(data)
	Warden.PlyPerms[data.networkid] = nil
end)

cvars.AddChangeCallback("warden_perm_persist", function(_, _, newVal)
	if newVal == "0" then
		local perms = Warden._GetPersistPerms("global")

		for k, _ in pairs(Warden.Permissions) do
			Warden.PermissionRequest("global", perms[k], k)
		end

		return
	end

	LocalPlayer():WardenEnsureSetup()
	local perms = Warden.PlyPerms[LocalPlayer():SteamID()]
	local newPerms = {}

	for k, v in pairs(Warden.Permissions) do
		local enabled = perms[k]["global"]

		if enabled == nil then
			newPerms[k] = v:GetDefault()
		else
			newPerms[k] = enabled
		end

		Warden.PermissionRequest("global", newPerms[k], k)
	end

	Warden._SetPersistPerms(nil, newPerms)
end, "MakeDefaultsExplicit")