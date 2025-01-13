util.AddNetworkString("WardenUpdatePermission")
util.AddNetworkString("WardenInitialize")

local initialized = {}
net.Receive("WardenInitialize", function(_, ply)
	if initialized[ply] then return end
	initialized[ply] = true

	Warden.SetupPlayer(ply)
	net.Start("WardenInitialize")
	net.WriteUInt(#Warden.PlyPerms, Warden.PERM_PLY_NET_SIZE)
	for steamID, perms in pairs(Warden.PlyPerms) do
		net.WriteString(steamID)
		net.WriteUInt(#perms, Warden.PERM_NET_SIZE)
		for permID, steamIDs in pairs(perms) do
			net.WriteUInt(permID, Warden.PERM_NET_SIZE)

			local toSend = {}
			for steamID1, granted in pairs(steamIDs) do
				if granted then
					table.insert(toSend, steamID1)
				end
			end

			net.WriteUInt(#toSend, Warden.PERM_PLY_NET_SIZE)
			for _, steamID1 in ipairs(toSend) do
				net.WriteString(steamID1)
			end
		end
	end
	net.Send(ply)
end)

net.Receive("WardenUpdatePermission", function(_, ply)
	local permID = net.ReadUInt(Warden.PERM_NET_SIZE)
	if not Warden.GetPermission(permID) then return end

	local granting = net.ReadBool()
	if net.ReadBool() then
		local receiver = net.ReadEntity()
		if IsValid(receiver) then
			if granting then
				Warden.GrantPermission(ply, receiver, permID)
			else
				Warden.RevokePermission(ply, receiver, permID)
			end
		end
	else
		if granting then
			Warden.GrantPermission(ply, nil, permID)
		else
			Warden.RevokePermission(ply, nil, permID)
		end
	end
end)

local function networkPermission(ply, receiver, permID, granting)
	net.Start("WardenUpdatePermission")
	net.WriteBool(granting) -- Granting = true, Revoking = false
	net.WriteUInt(permID, Warden.PERM_NET_SIZE) -- permID index
	net.WriteEntity(ply) -- Player granting the permID
	if receiver then
		net.WriteBool(false) -- Is Global permID
		net.WriteEntity(receiver) -- Player receiving the permID
	else
		net.WriteBool(true)
	end
	net.Broadcast()
end

-- set that one player allows another for a perm
function Warden.GrantPermission(granter, receiver, keyOrID)
	granter:WardenEnsureSetup()

	local perm = Warden.GetPermission(keyOrID)
	if not perm then return end

	if IsValid(receiver) and receiver:IsPlayer() then
		if Warden.HasPermissionGlobal(receiver, perm.ID) then
			hook.Run("WardenRevokePermission", granter, receiver, perm, true)
		else
			hook.Run("WardenGrantPermission", granter, receiver, perm)
		end

		Warden.PlyPerms[granter:SteamID()][perm.ID][receiver:SteamID()] = true
		networkPermission(granter, receiver, perm.ID, true)
	else
		hook.Run("WardenGrantPermissionGlobal", granter, perm)
		Warden.PlyPerms[granter:SteamID()][perm.ID]["global"] = true
		networkPermission(granter, nil, perm.ID, true)
	end
end

-- opposite of above
function Warden.RevokePermission(revoker, receiver, keyOrID)
	revoker:WardenEnsureSetup()

	local perm = Warden.GetPermission(keyOrID)
	if not perm then return end

	if IsValid(receiver) and receiver:IsPlayer() then
		if Warden.HasPermissionGlobal(receiver, perm.ID) then
			hook.Run("WardenGrantPermission", revoker, receiver, perm, true)
		else
			hook.Run("WardenRevokePermission", revoker, receiver, perm)
		end

		Warden.PlyPerms[revoker:SteamID()][perm.ID][receiver:SteamID()] = nil
		networkPermission(revoker, receiver, perm.ID, false)
	else
		hook.Run("WardenRevokePermissionGlobal", revoker, perm)
		Warden.PlyPerms[revoker:SteamID()][perm.ID]["global"] = nil
		networkPermission(revoker, nil, perm.ID, false)
	end
end