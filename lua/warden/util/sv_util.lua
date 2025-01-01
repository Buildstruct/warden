util.AddNetworkString("WardenAdminLevel")

local PLAYER = FindMetaTable("Player")

function Warden.FreezeEntities(steamID)
	local count = 0
	for _, ent in ipairs(Warden.GetOwnedEntities(steamID)) do
		for i = 0, ent:GetPhysicsObjectCount() - 1 do
			local phys = ent:GetPhysicsObjectNum(i)
			phys:EnableMotion(false)
		end
		count = count + 1
	end
	hook.Run("WardenFreeze", steamID, count)
end

function Warden.CleanupEntities(steamID)
	local count = 0
	for _, ent in ipairs(Warden.GetOwnedEntities(steamID)) do
		ent:Remove()
	end
	count = count + 1

	hook.Run("WardenCleanup", steamID, count)
	return count
end

function Warden.FreezeDisconnected()
	for steamID, _ in pairs(Warden.GetPlayerTable()) do
		if Warden.PlayerIsDisconnected(steamID) then
			Warden.FreezeEntities(steamID)
		end
	end
end

function Warden.CleanupDisconnected()
	for steamID, _ in pairs(Warden.GetPlayerTable()) do
		if Warden.PlayerIsDisconnected(steamID) then
			Warden.CleanupEntities(steamID)
		end
	end
end

function PLAYER:WardenSetAdminLevel(level)
	if type(level) ~= "number" and type(level) ~= "nil" then
		error("admin level must be a number or nil", 2)
	end

	self.WardenAdminLevel = level

	net.Start("WardenAdminLevel")
		net.WriteUInt(level, 8)
	net.Send(self)
end

net.Receive("WardenAdminLevel", function(_, ply)
	if not ply:IsAdmin() then return end

	ply:WardenSetAdminLevel(net.ReadUInt(8))
end)