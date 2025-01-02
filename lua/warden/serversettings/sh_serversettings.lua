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