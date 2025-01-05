Warden.DefaultSettings = Warden.DefaultSettings or {}

Warden.ADMIN_NET = {
	ADMIN_LEVEL = 0,
	CLEAR_DISCONNECTED = 1,
	CLEAR_ENTS = 2,
	FREEZE_ENTS = 3,
	CLEAR_SETTINGS = 4,
	CLEAR_CLASSES = 5,
	CLEAR_MODELS = 6,
	MESSAGE = 7
}

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