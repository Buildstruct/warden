util.AddNetworkString("WardenUpdatePermission")
util.AddNetworkString("WardenAdminLevel")
util.AddNetworkString("WardenInitialize")

local initialized = {}
net.Receive("WardenInitialize", function(_, ply)
	if initialized[ply] then return end
	initialized[ply] = true

	Warden.SetupPlayer(ply)
	net.Start("WardenInitialize")
	net.WriteUInt(#Warden.PlyPerms, 8)
	for steamID, perms in pairs(Warden.PlyPerms) do
		net.WriteString(steamID)
		net.WriteUInt(#perms, 8)
		for permID, steamIDs in pairs(perms) do
			net.WriteUInt(permID, 8)

			local toSend = {}
			for steamID1, granted in pairs(steamIDs) do
				if granted then
					table.insert(toSend, steamID1)
				end
			end

			net.WriteUInt(#toSend, 8)
			for _, steamID1 in ipairs(toSend) do
				net.WriteString(steamID1)
			end
		end
	end
	net.Send(ply)
end)

net.Receive("WardenUpdatePermission", function(_, ply)
	local permID = net.ReadUInt(8)
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
	net.WriteUInt(permID, 8) -- permID index
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

	local permID = Warden.PermID(keyOrID)
	if not permID then return end

	if IsValid(receiver) and receiver:IsPlayer() then
		if Warden.PlyPerms[granter:SteamID()][permID]["global"] then
			hook.Run("WardenRevokePermission", granter, receiver, permID, true)
		else
			hook.Run("WardenGrantPermission", granter, receiver, permID)
		end

		Warden.PlyPerms[granter:SteamID()][permID][receiver:SteamID()] = true
		networkPermission(granter, receiver, permID, true)
	else
		hook.Run("WardenGrantPermissionGlobal", granter, permID)
		Warden.PlyPerms[granter:SteamID()][permID]["global"] = true
		networkPermission(granter, nil, permID, true)
	end
end

-- opposite of above
function Warden.RevokePermission(revoker, receiver, keyOrID)
	revoker:WardenEnsureSetup()

	local permID = Warden.PermID(keyOrID)
	if not permID then return end

	if IsValid(receiver) and receiver:IsPlayer() then
		if Warden.PlyPerms[revoker:SteamID()][permID]["global"] then
			hook.Run("WardenGrantPermission", revoker, receiver, permID, true)
		else
			hook.Run("WardenRevokePermission", revoker, receiver, permID)
		end

		Warden.PlyPerms[revoker:SteamID()][permID][receiver:SteamID()] = nil
		networkPermission(revoker, receiver, permID, false)
	else
		hook.Run("WardenRevokePermissionGlobal", revoker, permID)
		Warden.PlyPerms[revoker:SteamID()][permID]["global"] = nil
		networkPermission(revoker, nil, permID, false)
	end
end