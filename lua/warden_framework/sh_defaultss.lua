Warden.DefaultSettings = Warden.DefaultSettings or {}

function Warden.SetDefaultServerSetting(setting, value)
	if type(value) == "boolean" then
		value = value and 1 or 0
	elseif value == nil then
		value = 0
	end

	Warden.DefaultSettings[setting] = value
end

function Warden.GetDefaultServerSetting(setting)
	return Warden.DefaultSettings[setting]
end

Warden.SetDefaultServerSetting("freeze_disconnect", true)
Warden.SetDefaultServerSetting("cleanup_disconnect", true)
Warden.SetDefaultServerSetting("admin_level_needs_admin", true)
Warden.SetDefaultServerSetting("always_target_bots", false)
Warden.SetDefaultServerSetting("cleanup_time", 600)
Warden.SetDefaultServerSetting("default_admin_level", 0)