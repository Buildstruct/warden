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

local function sendPerm(receiver, keyOrID, granting, dontDB)
	local permID = Warden.PermID(keyOrID)
	if not permID then return end

	net.Start("WardenUpdatePerms")
	net.WriteUInt(permID, Warden.PERM_NET_SIZE)
	local recID = netReceiver(receiver)
	net.WriteBool(granting or false)
	net.SendToServer()

	if dontDB then return end

	Warden._UpdatePersistPerm(recID, permID, granting)
end

-- set that one player allows another for a perm
-- receiver can be nil
function Warden.GrantPermission(receiver, keyOrID, dontDB)
	sendPerm(receiver, keyOrID, true, dontDB)
end

-- opposite of above
function Warden.RevokePermission(receiver, keyOrID, dontDB)
	sendPerm(receiver, keyOrID, nil, dontDB)
end

-- determine whether to grant or revoke based on a bool
function Warden.PermissionRequest(receiver, val, keyOrID, dontDB)
	if val then
		Warden.GrantPermission(receiver, keyOrID, dontDB)
	else
		Warden.RevokePermission(receiver, keyOrID, dontDB)
	end
end

local function parse(perms)
	local perms1 = {}
	for k, v in pairs(perms) do
		if v then
			table.insert(perms1, k)
		end
	end

	return sql.SQLStr(table.concat(perms1, ";"))
end

local function unparse(text)
	local perms = string.Explode(";", text)

	local perms1 = {}
	for _, v in ipairs(perms) do
		perms1[v] = true
	end

	return perms1
end

-- intended to be internal
function Warden._UpdatePersistPerm(recID, permID, state)
	local perms = Warden._GetPersistPerms(recID)
	local permKey = Warden.PermKey(permID, true)

	if state then
		perms[permKey] = true
	else
		perms[permKey] = nil
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
-- get persist perms for everyone on the server + global perms
function Warden._GetAllPersistPerms()
	local recIDs = {}
	for _, v in ipairs(player.GetHumans()) do
		if v == LocalPlayer() then continue end

		table.insert(recIDs, sql.SQLStr(v:SteamID()))
	end

	table.insert(recIDs, sql.SQLStr("global"))
	local str = table.concat(recIDs, ", ")

	local q = sql.Query(string.format("SELECT * FROM warden_cl_perms WHERE steamID IN ( %s );", str))
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

local function netPersists(ply, perms)
	local recID = netReceiver(ply)
	perms = perms or Warden._GetPersistPerms(recID)

	local perms1 = {}
	for k, _ in pairs(perms) do
		local permID = Warden.PermID(k, true)
		if permID then
			table.insert(perms1, permID)
		end
	end

	net.WriteUInt(#perms1, Warden.PERM_NET_SIZE)
	for _, v in ipairs(perms1) do
		net.WriteUInt(v, Warden.PERM_NET_SIZE)
	end
end

local function sendAllPersists()
	local allPerms = Warden._GetAllPersistPerms()

	net.Start("WardenPersistPerms")
	net.WriteUInt(table.Count(allPerms), Warden.PERM_PLY_NET_SIZE)

	for k, v in pairs(allPerms) do
		netPersists(Warden.GetPlayerFromSteamID(k), v)
	end

	net.SendToServer()
end

hook.Add("InitPostEntity", "WardenPerms", function()
	hook.Add("OnEntityCreated", "WardenPerms", function(ent)
		if not ent:IsPlayer() then return end

		net.Start("WardenPersistPerms")
		net.WriteUInt(1, Warden.PERM_PLY_NET_SIZE)
		netPersists(ent)
		net.SendToServer()
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

		for k, _ in pairs(Warden.GetAllPermissions()) do
			local key = Warden.PermKey(k, true)
			if key then
				Warden.PermissionRequest("global", perms[key], k, true)
			end
		end

		return
	end

	LocalPlayer():WardenEnsureSetup()
	local perms = Warden.PlyPerms[LocalPlayer():SteamID()]
	local newPerms = {}

	for k, v in pairs(Warden.GetAllPermissions()) do
		local key = Warden.PermKey(k, true)
		if not key then continue end

		local enabled = perms[k]["global"]

		if enabled == nil then
			newPerms[key] = v:GetDefault()
		else
			newPerms[key] = enabled
		end

		Warden.PermissionRequest("global", newPerms[key], k, true)
	end

	local oldPerms = Warden._GetPersistPerms("global")

	for k, v in pairs(oldPerms) do
		if newPerms[k] == nil then
			newPerms[k] = v
		end
	end

	Warden._SetPersistPerms("global", newPerms)
end, "MakeDefaultsExplicit")