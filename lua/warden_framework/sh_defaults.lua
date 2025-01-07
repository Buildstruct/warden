Warden.DefaultSettings = Warden.DefaultSettings or {}

Warden.WORLD_ID = "18446744073709551614"

Warden.ADMIN_LEVEL_MIN = 0
Warden.ADMIN_LEVEL_MIN_1 = 1
Warden.ADMIN_LEVEL_MAX = 99

Warden.PERM_NET_SIZE = 8
Warden.PERM_PLY_NET_SIZE = 8

Warden.SETTINGS_NET_SIZE = 8
Warden.SETTINGS_OPTION_NET_SIZE = 11

Warden.FILTER_NET_SIZE = 11
Warden.CLASS_FILTER_NET_SIZE = 6

Warden.ADMIN_LEVEL_NET_SIZE = 8
Warden.ADMIN_NET_SIZE = 4

Warden.OWNER_TYPE_NET_SIZE = 3
Warden.OWNER_NET_SIZE = 13

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

Warden.OWNER_TYPE_NET = {
	ALL_ENT = 0,
	ALL_PLY = 1,
	NEW_ENT = 2,
	NEW_PLY = 3,
	NEW_WORLD = 4,
	NEW_NONE = 5
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