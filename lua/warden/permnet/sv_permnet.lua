util.AddNetworkString("WardenUpdatePerms")
util.AddNetworkString("WardenPersistPerms")

local function netPerm(graID, recID, permID)
	net.Start("WardenUpdatePerms")
	net.WriteBool(false)
	net.WriteUInt(1, Warden.PERM_PLY_NET_SIZE)
	net.WriteUInt64(util.SteamIDTo64(graID))
	net.WriteUInt(1, Warden.PERM_NET_SIZE)
	net.WriteUInt(permID, Warden.PERM_NET_SIZE)
	net.WriteUInt(1, Warden.PERM_SET_NET_SIZE)

	if recID == "global" then
		net.WriteUInt64(Warden.GLOBAL_ID)
	else
		net.WriteUInt64(util.SteamIDTo64(recID))
	end

	local granting = Warden.PlyPerms[graID][permID][recID]
	net.WriteBool(granting or false)
end

local function netPerms(graID)
	net.WriteUInt64(util.SteamIDTo64(graID))

	local perms = Warden.PlyPerms[graID]
	if not perms then
		net.WriteUInt(0, Warden.PERM_NET_SIZE)
		return
	end

	net.WriteUInt(table.Count(perms), Warden.PERM_NET_SIZE)
	for permID, plys in pairs(perms) do
		net.WriteUInt(permID, Warden.PERM_NET_SIZE)

		net.WriteUInt(table.Count(plys), Warden.PERM_SET_NET_SIZE)
		for k, v in pairs(plys) do
			if k == "global" then
				net.WriteUInt64(Warden.GLOBAL_ID)
			else
				net.WriteUInt64(util.SteamIDTo64(k))
			end

			net.WriteBool(v)
		end
	end
end

local function setPerm(granter, receiver, keyOrID, granting)
	local perm = Warden.GetPermission(keyOrID)
	if not perm then return end

	local recID
	if IsValid(receiver) then
		recID = receiver:SteamID()
	else
		recID = "global"
		granting = granting or false
	end

	local graID = granter:SteamID()
	granter:WardenEnsureSetup()

	local old = Warden.PlyPerms[graID][perm.ID][recID] or false

	Warden.PlyPerms[graID][perm.ID][recID] = granting
	netPerm(graID, recID, perm.ID)
	net.Broadcast()

	if old == (granting or false) then return end

	return recID, perm
end

-- determine whether to grant or revoke based on a bool
function Warden.PermissionRequest(granter, receiver, val, keyOrID)
	if val then
		Warden.GrantPermission(granter, receiver, keyOrID)
	else
		Warden.RevokePermission(granter, receiver, keyOrID)
	end
end

-- set that one player allows another for a perm
-- receiver can be nil
function Warden.GrantPermission(granter, receiver, keyOrID)
	local recID, perm = setPerm(granter, receiver, keyOrID, true)
	if not perm then return end

	if recID == "global" then
		hook.Run("WardenGrantPermissionGlobal", granter, perm)
	else
		if Warden.HasPermissionGlobal(granter, perm) then
			hook.Run("WardenRevokePermission", granter, receiver, perm, true)
		else
			hook.Run("WardenGrantPermission", granter, receiver, perm)
		end
	end
end

-- opposite of above
function Warden.RevokePermission(revoker, receiver, keyOrID)
	local recID, perm = setPerm(revoker, receiver, keyOrID)
	if not perm then return end

	if recID == "global" then
		hook.Run("WardenRevokePermissionGlobal", revoker, perm)
	else
		if Warden.HasPermissionGlobal(revoker, perm) then
			hook.Run("WardenGrantPermission", revoker, receiver, perm, true)
		else
			hook.Run("WardenRevokePermission", revoker, receiver, perm)
		end
	end
end

local function sendAll()
	net.Start("WardenUpdatePerms")
	net.WriteBool(reset)
	net.WriteUInt(table.Count(Warden.PlyPerms), Warden.PERM_PLY_NET_SIZE)
	for k, _ in ipairs(Warden.PlyPerms) do
		netPerms(k)
	end
end

-- in case of file reload
if WARDEN_LOADED then
	sendAll()
	net.Broadcast()
end

gameevent.Listen("player_activate")
hook.Add("player_activate", "WardenPerms", function(data)
	local ply = Player(data.userid)
	if not ply:IsValid() then return end

	ply:WardenEnsureSetup()

	sendAll()
	net.Send(ply)
end)

net.Receive("WardenUpdatePerms", function(_, ply)
	local permID = net.ReadUInt(Warden.PERM_NET_SIZE)

	local receiver
	if not net.ReadBool() then
		receiver = net.ReadPlayer()
	end

	Warden.PermissionRequest(ply, receiver, net.ReadBool(), permID)
end)

local persisted = {}
local function getRecID(plyUserID)
	if net.ReadBool() then
		if persisted[plyUserID] and persisted[plyUserID].global then return end

		persisted[plyUserID] = persisted[plyUserID] or {}
		persisted[plyUserID].global = true

		return "global"
	else
		local receiver = net.ReadPlayer()
		if not IsValid(receiver) then return end

		local recUserID = receiver:UserID()
		if persisted[recUserID] and persisted[recUserID][plyUserID] then return end

		persisted[recUserID] = persisted[recUserID] or {}
		persisted[recUserID][plyUserID] = true

		return receiver:SteamID()
	end
end

net.Receive("WardenPersistPerms", function(_, ply)
	ply:WardenEnsureSetup()

	local plyID = ply:SteamID()
	local plyUserID = ply:UserID()

	local didChanges

	local recC = net.ReadUInt(Warden.PERM_PLY_NET_SIZE)
	for i = 1, recC do
		local recID = getRecID(plyUserID)
		local permC = net.ReadUInt(Warden.PERM_NET_SIZE)
		for j = 1, permC do
			local permID = net.ReadUInt(Warden.PERM_NET_SIZE)

			if recID and Warden.PermID(permID, true) then
				didChanges = true
				Warden.PlyPerms[plyID][permID][recID] = true
			end
		end
	end

	if not didChanges then return end

	net.Start("WardenUpdatePerms")
	net.WriteBool(false)
	net.WriteUInt(1, Warden.PERM_PLY_NET_SIZE)
	netPerms(plyID)
	net.Broadcast()
end)

hook.Add("PlayerDisconnected", "WardenClearPerms", function(ply)
	Warden.PlyPerms[ply:SteamID()] = nil

	local userID = ply:UserID()

	persisted[userID] = nil
	for k, _ in pairs(persisted) do
		persisted[k][userID] = nil
	end
end)
