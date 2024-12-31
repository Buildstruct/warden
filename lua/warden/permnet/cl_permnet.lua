-- Ask server for permission info
hook.Add("InitPostEntity", "Warden", function()
	net.Start("WardenInitialize")
	net.SendToServer()
end)

net.Receive("WardenInitialize", function()
	local n = net.ReadUInt(8)
	for i = 1, n do
		local granter = net.ReadString()

		local o = net.ReadUInt(8)
		for j = 1, o do
			local permission = net.ReadUInt(8)

			local p = net.ReadUInt(8)
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
	local permission = net.ReadUInt(8)
	local granter = net.ReadEntity()

	if not IsValid(granter) or not granter:IsPlayer() then
		return
	end

	granter:WardenEnsureSetup()

	if net.ReadBool() then
		Warden.PlyPerms[granter:SteamID()][permission]["global"] = granting
	else
		local receiver = net.ReadEntity()
		if IsValid(receiver) and receiver:IsPlayer() then
			Warden.PlyPerms[granter:SteamID()][permission][receiver:SteamID()] = granting
		end
	end
end)

local function networkPermission(receiver, permission, granting)
	net.Start("WardenUpdatePermission")
	net.WriteUInt(permission, 8)
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
	local permID = Warden.PermID(keyOrID)
	networkPermission(receiver, permID, true)
end

-- request that another player does not get this perm
function Warden.RevokePermission(receiver, keyOrID)
	local permID = Warden.PermID(keyOrID)
	networkPermission(receiver, permID, false)
end

gameevent.Listen("player_disconnect")
hook.Add("player_disconnect", "WardenPlayerDisconnect", function(data)
	local steamID = data.networkid
	Warden.PlyPerms[steamID] = nil
end)

