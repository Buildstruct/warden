Warden.DefaultSettings = Warden.DefaultSettings or {}

Warden.GLOBAL_ID = "18446744073709551614"
Warden.WORLD_ID = "18446744073709551614"
Warden.INVALID_PERM_ID = 255

Warden.ADMIN_LEVEL_MIN = 0
Warden.ADMIN_LEVEL_MIN_1 = 1
Warden.ADMIN_LEVEL_MAX = 99

Warden.PERM_NET_SIZE = 4
Warden.PERM_PLY_NET_SIZE = 8
Warden.PERM_SET_NET_SIZE = 8

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

Warden.SetDefaultServerSetting("class_filter_bypass", false)
Warden.SetDefaultServerSetting("model_filter_whitelist", false)

Warden.SetDefaultServerSetting("perm_notify", true)
Warden.SetDefaultServerSetting("always_target_bots", false)
Warden.SetDefaultServerSetting("gravgun_punt", true)
Warden.SetDefaultServerSetting("physgun_reload", true)
Warden.SetDefaultServerSetting("phy_damage", true)
Warden.SetDefaultServerSetting("fire_damage", true)

Warden.SetDefaultServerSetting("freeze_disconnect", true)
Warden.SetDefaultServerSetting("cleanup_disconnect", true)
Warden.SetDefaultServerSetting("cleanup_notify", true)
Warden.SetDefaultServerSetting("cleanup_time", 600)

Warden.SetDefaultServerSetting("admin_level_needs_admin", true)
Warden.SetDefaultServerSetting("default_admin_level", 0)
Warden.SetDefaultServerSetting("admin_level_filter_bypass", 4)

local function onCami()
	local cmdType = GetGlobalString("WardenCommands")
	if not CAMI and cmdType == "" then return end

	local cmdFuncs = {
		sam = function(perm, altPerm)
			Warden.AddCustomCmdPermCallback(perm, function(ply)
				return ply:HasPermission(altPerm) or false
			end)
		end,
		ulx = function(perm, altPerm)
			Warden.AddCustomCmdPermCallback(perm, function(ply)
				return ULib.ucl.query(ply, altPerm) or false
			end)
		end,
		nadmin = function(perm, altPerm)
			Warden.AddCustomCmdPermCallback(perm, function(ply)
				return ply:HasPerm(altPerm) or false
			end)
		end
	}

	local perms = {
		warden_cleanup_entities = {
			sam = "cleanup",
			ulx = "ulx cleanup",
			nadmin = "cleanup"
		},
		warden_freeze_entities = {
			sam = "pfreezeprops",
			ulx = "ulx pfreezeprops",
			nadmin = "pfreezeprops"
		},
		warden_cleanup_disconnected = {
			sam = "cleanupdisconnected",
			ulx = "ulx cupdis",
			nadmin = "cupdis"
		},
		warden_admin_level = {
			sam = "adminlevel",
			ulx = "ulx adminlevel",
			nadmin = "adminlevel"
		}
	}

	for k, v in pairs(perms) do
		if cmdFuncs[cmdType] and v[cmdType] then
			cmdFuncs[cmdType](k, v[cmdType])
		elseif CAMI then
			local privilege = {
				Name = k,
				MinAccess = "admin"
			}

			CAMI.RegisterPrivilege(privilege)
		end
	end
end

timer.Simple(10, onCami)