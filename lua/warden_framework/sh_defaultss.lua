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