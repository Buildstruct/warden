util.AddNetworkString("WardenAdminSettingChange")

net.Receive("WardenAdminSettingChange", function(_, ply)
	if not ply:IsSuperAdmin() then
		ply:ChatPrint("Only superadmins can change Warden's settings.")
		return
	end

	local setting = net.ReadString()
	local value = net.ReadInt(8)

	Warden.SetServerSetting(setting, value)
end)

local settings = {}

-- write a server setting and save to file
function Warden.SetServerSetting(setting, value)
	setting = string.gsub(setting, "warden_", "")

	local cvar = GetConVar("warden_" .. setting)
	if not cvar then return end

	Warden.SetCVar(cvar, value)

	settings[setting] = value
	file.Write("warden_settings.json", util.TableToJSON(settings))
end

hook.Add("PostGamemodeLoaded", "Warden", function()
	local newSettings = file.Read("warden_settings.json", "DATA")
	if not newSettings then return end

	settings = util.JSONToTable(newSettings)

	for k, v in pairs(settings) do
		local cvar = GetConVar("warden_" .. k)
		if not cvar then continue end

		Warden.SetCVar(cvar, v)
	end
end)