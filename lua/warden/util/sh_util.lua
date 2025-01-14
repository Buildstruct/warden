Warden.Names = Warden.Names or {}

local PLAYER = FindMetaTable("Player")

function PLAYER:WardenEnsureSetup()
	Warden.SetupPlayer(self)
end

function Warden.SetupPlayer(plyOrID)
	if not isstring(plyOrID) then
		plyOrID = plyOrID:SteamID()
	end

	Warden.PlyPerms[plyOrID] = Warden.PlyPerms[plyOrID] or {}
	for _, v in pairs(Warden.Permissions) do
		Warden.PlyPerms[plyOrID][v.ID] = Warden.PlyPerms[plyOrID][v.ID] or {}
	end
end

function Warden.PlayerIsDisconnected(steamID)
	local ply = Warden.GetPlayerFromSteamID(steamID)
	return not Warden.IsValid(ply)
end

-- get the player entity from a steamid, does caching unlike gmod's version
local steamIDMap = {}
function Warden.GetPlayerFromSteamID(steamID)
	if steamID == "World" then return game.GetWorld() end

	if not IsValid(steamIDMap[steamID]) then
		steamIDMap = {}
		for _, ply in player.Iterator() do
			steamIDMap[ply:SteamID()] = ply
		end
	end

	return steamIDMap[steamID]
end

-- get the name of a player with x steamid
function Warden.GetNameFromSteamID(steamID, fallback)
	if steamID == "World" then return "World" end
	return Warden.Names[steamID] or fallback
end

-- returns whether an entity is valid, including the world
-- second term returns whether it is the world or not
function Warden.IsValid(ent)
	if IsValid(ent) then
		return true, false
	end

	if ent and ent.IsWorld and ent:IsWorld() then
		return true, true
	end

	return false, false
end

-- get a steamid out of a var that might or might not be a player
function Warden.PossibleSteamID(plyOrID)
	if type(plyOrID) == "string" then return plyOrID end

	local valid, world = Warden.IsValid(plyOrID)
	if world then return "World" end
	if valid and plyOrID:IsPlayer() then return plyOrID:SteamID() end
end

-- get an entindex out of a var that might or might not be an entity
function Warden.PossibleEntIndex(entOrID)
	if type(entOrID) == "number" then return entOrID end

	if not IsValid(entOrID) then return end
	return entOrID:EntIndex()
end