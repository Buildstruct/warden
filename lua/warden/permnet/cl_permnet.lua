CreateClientConVar("warden_touch_self", 1, true, true, "Whether you can touch your own entities.", 0, 1)
CreateClientConVar("warden_touch", 1, true, true, "Whether you can touch any entities.", 0, 1)
local permPersist = CreateClientConVar("warden_perm_persist", 0, true, false, "Allow permissions to persist across sessions.", 0, 1)

if not permPersist:GetBool() then
	sql.Query("DROP TABLE IF EXISTS warden_cl_perms;")
end
sql.Query("CREATE TABLE IF NOT EXISTS warden_cl_perms ( steamID TEXT PRIMARY KEY ON CONFLICT REPLACE, perms TEXT );")

Warden.PersistPerms = Warden.PersistPerms or {}

-- Ask server for permission info and send persist perms
hook.Add("InitPostEntity", "Warden", function()
	local allPerms = Warden._GetAllPersistPerms()

	net.Start("WardenInitialize")

	net.WriteUInt(table.Count(allPerms), Warden.PERSIST_PERMS_NET_SIZE)
	for k, v in pairs(allPerms) do
		if k == "global" then
			net.WriteUInt64(Warden.GLOBAL_ID)
		else
			net.WriteUInt64(util.SteamIDTo64(k))
		end

		net.WriteUInt(table.Count(v), Warden.PERM_NET_SIZE)
		for k1, _ in pairs(v) do
			net.WriteUInt(k1, Warden.PERM_NET_SIZE)
		end
	end

	net.SendToServer()
end)

net.Receive("WardenInitialize", function()
	local n = net.ReadUInt(Warden.PERM_PLY_NET_SIZE)
	for i = 1, n do
		local granter = net.ReadString()

		local o = net.ReadUInt(Warden.PERM_NET_SIZE)
		for j = 1, o do
			local permission = net.ReadUInt(Warden.PERM_NET_SIZE)

			local p = net.ReadUInt(Warden.PERM_PLY_NET_SIZE)
			for k = 1, p do
				local receiver = net.ReadString()

				Warden.SetupPlayer(granter)
				Warden.PlyPerms[granter][permission][receiver] = true
			end
		end
	end
end)

net.Receive("WardenUpdatePermission", function()
	local granting = net.ReadBool()
	local permission = net.ReadUInt(Warden.PERM_NET_SIZE)
	local granter = net.ReadEntity()

	if not IsValid(granter) or not granter:IsPlayer() then
		return
	end

	granter:WardenEnsureSetup()

	if net.ReadBool() then
		Warden.PlyPerms[granter:SteamID()][permission]["global"] = granting
	else
		local recID = util.SteamIDFrom64(net.ReadUInt64())
		Warden.PlyPerms[granter:SteamID()][permission][recID] = granting
	end
end)

local function networkPermission(receiver, permission, granting)
	net.Start("WardenUpdatePermission")
	net.WriteUInt(permission, Warden.PERM_NET_SIZE)
	net.WriteBool(granting)
	if receiver then
		net.WriteBool(true)
		net.WriteEntity(receiver)
	else
		net.WriteBool(false)
	end
	net.SendToServer()
end

-- request that another player get this perm
function Warden.GrantPermission(receiver, keyOrID)
	if IsValid(receiver) and (not receiver:IsPlayer() or receiver:IsBot()) then return end

	local permID = Warden.PermID(keyOrID)

	networkPermission(receiver, permID, true)

	local perms = Warden._GetPersistPerms(receiver)
	perms[permID] = true
	Warden._SetPersistPerms(receiver, perms)
end

-- request that another player does not get this perm
function Warden.RevokePermission(receiver, keyOrID)
	if IsValid(receiver) and (not receiver:IsPlayer() or receiver:IsBot()) then return end

	local permID = Warden.PermID(keyOrID)

	networkPermission(receiver, permID, false)

	local perms = Warden._GetPersistPerms(receiver)
	perms[permID] = nil
	Warden._SetPersistPerms(receiver, perms)
end

-- determine whether to grant or revoke based on a bool
function Warden.PermissionRequest(receiver, val, keyOrID)
	if val then
		Warden.GrantPermission(receiver, keyOrID)
	else
		Warden.RevokePermission(receiver, keyOrID)
	end
end

gameevent.Listen("player_disconnect")
hook.Add("player_disconnect", "WardenPlayerDisconnect", function(data)
	Warden.PlyPerms[data.networkid] = nil
end)

local function parse(perms)
	local perms1 = {}
	for k, _ in pairs(perms) do
		local key = Warden.PermKey(k)
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
		local id = Warden.PermID(v)
		if id then
			perms1[id] = true
		end
	end

	return perms1
end

local function clearPerms(steamID)
	Warden.PersistPerms[steamID] = nil
	sql.Query(string.format("DELETE FROM warden_cl_perms WHERE steamID = %s;", sql.SQLStr(steamID)))
end

-- intended to be internal
function Warden._SetPersistPerms(ply, perms)
	local steamID = "global"
	if IsValid(ply) then
		steamID = ply:SteamID()
	end

	if not perms or table.IsEmpty(perms) then
		clearPerms(steamID)
		return
	end

	Warden.PersistPerms[steamID] = perms
	sql.Query(string.format("INSERT INTO warden_cl_perms ( steamID, perms ) VALUES ( %s, %s );", sql.SQLStr(steamID), parse(perms)))
end

-- intended to be internal
function Warden._GetPersistPerms(ply)
	local steamID = "global"
	if IsValid(ply) then
		steamID = ply:SteamID()
	end

	if Warden.PersistPerms[steamID] then return Warden.PersistPerms[steamID] end

	local q = sql.QueryValue(string.format("SELECT perms FROM warden_cl_perms WHERE steamID = %s LIMIT 1;", sql.SQLStr(steamID)))
	if not q then
		Warden.PersistPerms[steamID] = {}
		return Warden.PersistPerms[steamID]
	end

	Warden.PersistPerms[steamID] = unparse(q)
	return Warden.PersistPerms[steamID]
end

-- intended to be internal
function Warden._GetAllPersistPerms()
	local q = sql.Query("SELECT * FROM warden_cl_perms;")
	if not q then
		Warden.PersistPerms = {}
		return {}
	end

	local allPerms = {}
	for _, v in pairs(q) do
		allPerms[v.steamID] = unparse(v.perms)
	end

	Warden.PersistPerms = allPerms

	return allPerms
end