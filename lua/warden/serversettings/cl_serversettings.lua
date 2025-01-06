Warden.Settings = Warden.Settings or {}

-- write a server setting and save to file (if superadmin)
function Warden.SetServerSetting(setting, value)
	if not LocalPlayer():IsSuperAdmin() then
		Warden.SAInform()
		return true
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
	net.WriteInt(newVal, Warden.SETTINGS_OPTION_NET_SIZE)
	net.SendToServer()
end

net.Receive("WardenAdminSettingChange", function()
	local count = net.ReadUInt(Warden.SETTINGS_NET_SIZE)

	for i = 1, count do
		local setting = net.ReadString()
		local value = net.ReadInt(Warden.SETTINGS_OPTION_NET_SIZE)

		Warden.Settings[setting] = value
	end
end)