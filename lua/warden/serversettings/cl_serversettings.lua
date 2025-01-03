Warden.Settings = Warden.Settings or {}

-- write a server setting and save to file (if superadmin)
function Warden.SetServerSetting(setting, value)
	if setting == "adminlevel" then
		Warden.RequestAdminLevel(value)
		return
	end

	if not LocalPlayer():IsSuperAdmin() then
		LocalPlayer():ChatPrint("Only superadmins can change Warden's settings.")
		return
	end

	local newVal
	if type(value) == "boolean" then
		newVal = value and 1 or 0
	else
		newVal = tonumber(value)
		if not newVal then return end
	end

	net.Start("WardenAdminSettingChange")
	net.WriteString(setting)
	net.WriteInt(newVal, 11)
	net.SendToServer()
end

net.Receive("WardenAdminSettingChange", function()
	local count = net.ReadUInt(8)

	for i = 1, count do
		local setting = net.ReadString()
		local value = net.ReadInt(11)

		Warden.Settings[setting] = value
	end
end)