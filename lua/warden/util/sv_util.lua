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
		count = count + 1
	end

	hook.Run("WardenCleanup", Warden.PossibleSteamID(plyOrID), count)
	return count
end
function PLAYER:WardenCleanupEntities()
	Warden.CleanupEntities(self)
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