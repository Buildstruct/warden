util.AddNetworkString("WardenAdminLevel")

local PLAYER = FindMetaTable("Player")

function Warden.FreezeEntities(plyOrID)
	local count = 0
	for _, ent in ipairs(Warden.GetOwnedEntities(plyOrID)) do
		for i = 0, ent:GetPhysicsObjectCount() - 1 do
			local phys = ent:GetPhysicsObjectNum(i)
			phys:EnableMotion(false)
		end
		count = count + 1
	end
	hook.Run("WardenFreeze", Warden.PossibleSteamID(plyOrID), count)
end
function PLAYER:WardenFreezeEntities()
	Warden.FreezeEntities(self)
end

function Warden.CleanupEntities(plyOrID)
	local count = 0
	for _, ent in ipairs(Warden.GetOwnedEntities(plyOrID)) do
		ent:Remove()
	end
	count = count + 1

	hook.Run("WardenCleanup", Warden.PossibleSteamID(plyOrID), count)
	return count
end
function PLAYER:WardenCleanupEntities()
	Warden.CleanupEntities(self)
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

function Warden.FreezeDisconnected()
	for steamID, _ in pairs(Warden._GetPlayerTable()) do
		if Warden.PlayerIsDisconnected(steamID) then
			Warden.FreezeEntities(steamID)
		end
	end
end

function Warden.CleanupDisconnected()
	for steamID, _ in pairs(Warden._GetPlayerTable()) do
		if Warden.PlayerIsDisconnected(steamID) then
			Warden.CleanupEntities(steamID)
		end
	end
end

net.Receive("WardenAdminLevel", function(_, ply)
	if not ply:IsAdmin() then return end

	ply:WardenSetAdminLevel(net.ReadUInt(8))
end)