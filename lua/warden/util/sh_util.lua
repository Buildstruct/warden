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