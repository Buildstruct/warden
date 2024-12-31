local PLAYER = FindMetaTable("Player")

local adminCvar = CreateConVar("warden_admin_level_needs_admin", 1, FCVAR_REPLICATED, "If true, admin level *only* works for admins.", 0, 1)
local adminCvarDefault = CreateConVar("warden_default_admin_level", 0, FCVAR_REPLICATED, "Set the default permission override level for admins.", 0, 99)

function PLAYER:WardenGetAdminLevel()
	if adminCvar:GetBool() and not self:IsAdmin() then
		return 0
	end

	local adminLevel = SERVER and self.WardenAdminLevel or Warden.LocalAdminLevel
	if not adminLevel then
		adminLevel = adminCvarDefault:GetInt()
	end

	return adminLevel
end

function PLAYER:WardenEnsureSetup()
	if not Warden.Permissions[self:SteamID()] then
		Warden.SetupPlayer(self)
	end
end

function Warden.SetupPlayer(plyOrID)
	if not isstring(plyOrID) then
		plyOrID = plyOrID:SteamID()
	end

	Warden.Permissions[plyOrID] = {}
	for _, id in pairs(Warden.PermissionIDs) do
		Warden.Permissions[plyOrID][id] = { global = false }
	end
end

function Warden.PlayerIsDisconnected(steamID)
	local ply = Warden.GetPlayerFromSteamID(steamID)
	return not Warden.IsValidOwner(ply)
end