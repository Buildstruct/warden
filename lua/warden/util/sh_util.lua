Warden.Names = Warden.Names or {}

local PLAYER = FindMetaTable("Player")

-- get what admin level a player has
function PLAYER:WardenGetAdminLevel()
	if Warden.GetServerBool("admin_level_needs_admin", true) and not self:IsAdmin() then
		return 0
	end

	local adminLevel = SERVER and self.WardenAdminLevel or Warden.LocalAdminLevel
	if not adminLevel then
		adminLevel = Warden.GetServerSetting("default_admin_level", 0)
	end

	return adminLevel
end

function PLAYER:WardenEnsureSetup()
	if not Warden.PlyPerms[self:SteamID()] then
		Warden.SetupPlayer(self)
	end
end

function Warden.SetupPlayer(plyOrID)
	if not isstring(plyOrID) then
		plyOrID = plyOrID:SteamID()
	end

	Warden.PlyPerms[plyOrID] = {}
	for _, v in pairs(Warden.Permissions) do
		Warden.PlyPerms[plyOrID][v.ID] = {}
	end
end

function Warden.PlayerIsDisconnected(steamID)
	local ply = Warden.GetPlayerFromSteamID(steamID)
	return not Warden.IsValidOwner(ply)
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

-- returns whether an entity is a valid owner
-- second term returns whether it is the world or not
function Warden.IsValidOwner(ent)
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

	local valid, world = Warden.IsValidOwner(plyOrID)
	if world then return "World" end
	if valid and plyOrID:IsPlayer() then return plyOrID:SteamID() end
end

-- get an entindex out of a var that might or might not be an entity
function Warden.PossibleEntIndex(entOrID)
	if type(entOrID) == "number" then return entOrID end

	if not IsValid(entOrID) then return end
	return entOrID:EntIndex()
end