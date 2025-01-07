Warden.Settings = Warden.Settings or {}

-- get a server setting
function Warden.GetServerSetting(setting, fallback)
	local value = Warden.Settings[setting]

	if value == nil then
		value = Warden.GetDefaultServerSetting(setting)
	end

	if value == nil then return fallback end

	return value
end

-- get a server setting as a boolean
function Warden.GetServerBool(setting, fallback)
	local value = Warden.Settings[setting]

	if value == nil then
		value = Warden.GetDefaultServerSetting(setting)
	end

	if value == nil then return fallback end

	return value ~= 0
end

Warden.SetDefaultServerSetting("always_target_bots", false)
Warden.SetDefaultServerSetting("gravgun_punt", true)
Warden.SetDefaultServerSetting("class_filter_bypass", false)
Warden.SetDefaultServerSetting("model_filter_whitelist", false)

Warden.SetDefaultServerSetting("freeze_disconnect", true)
Warden.SetDefaultServerSetting("cleanup_disconnect", true)
Warden.SetDefaultServerSetting("cleanup_time", 600)

Warden.SetDefaultServerSetting("admin_level_needs_admin", true)
Warden.SetDefaultServerSetting("default_admin_level", 0)
Warden.SetDefaultServerSetting("admin_level_filter_bypass", 4)