Warden.ADMIN_LEVEL_NET_SIZE = 8

-- get what admin level a player has
function PLAYER:WardenGetAdminLevel()
	if Warden.GetServerBool("admin_level_needs_admin", true) and not self:IsAdmin() then
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