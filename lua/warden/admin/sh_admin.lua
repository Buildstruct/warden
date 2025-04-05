local PLAYER = FindMetaTable("Player")

-- get what admin level a player has
function PLAYER:WardenGetAdminLevel()
	if Warden.GetServerBool("admin_level_needs_admin", true) and not self:WardenGetPerm("warden_admin_level") then
		return 0
	end

	if CLIENT and self ~= LocalPlayer() then
		return 0
	end

	local adminLevel = SERVER and self.WardenAdminLevel or Warden.LocalAdminLevel
	if not adminLevel then
		adminLevel = Warden.GetServerSetting("default_admin_level", 0)
	end

	return adminLevel
end

function Warden.SAInform(ply)
	if CLIENT then
		notification.AddLegacy(Warden.L("Only superadmins can change Warden's settings."), NOTIFY_ERROR, 4)
		return
	end

	ply:ChatPrint("Only superadmins can change Warden's settings.")
end