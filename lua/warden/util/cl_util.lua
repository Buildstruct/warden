net.Receive("WardenAdminLevel", function()
	Warden.LocalAdminLevel = net.ReadUInt(8)
end)

function Warden.RequestAdminLevel(adminLevel)
	if not LocalPlayer():IsAdmin() then return end

	net.Start("WardenAdminLevel")
	net.WriteUInt(adminLevel, 8)
	net.SendToServer()
end

function Warden.AdminSettingChange(setting, value)
	if setting == "adminlevel" then
		Warden.RequestAdminLevel(value)
		return
	end

	if not LocalPlayer():IsSuperAdmin() then return end

	local newVal = value

	if type(value) == "boolean" then
		newVal = value and 1 or 0
	elseif type(value) == "string" then
		newVal = tonumber(value)
		if not newVal then return end
	end

	net.Start("WardenAdminSettingChange")
	net.WriteString(string.gsub(setting, "warden_", ""))
	net.WriteInt(newVal, 8)
	net.SendToServer()
end