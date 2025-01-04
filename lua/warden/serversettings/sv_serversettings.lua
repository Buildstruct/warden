util.AddNetworkString("WardenAdminSettingChange")

do
	local newSettings = file.Read("warden/settings.json", "DATA")
	if newSettings then
		Warden.Settings = util.JSONToTable(newSettings)
	else
		Warden.Settings = Warden.Settings or {}
	end
end

-- write a server setting and save to file
function Warden.SetServerSetting(setting, value)
	local newVal
	if type(value) == "boolean" then
		newVal = value and 1 or 0
	else
		newVal = tonumber(value)
		if not newVal then return end
	end

	Warden.Settings[setting] = newVal
	file.Write("warden/settings.json", util.TableToJSON(Warden.Settings))

	net.Start("WardenAdminSettingChange")
	net.WriteUInt(1, Warden.SETTINGS_NET_SIZE)
	net.WriteString(setting)
	net.WriteInt(newVal, Warden.SETTINGS_OPTION_NET_SIZE)
	net.Broadcast()
end

local function sendAll()
	net.Start("WardenAdminSettingChange")
	net.WriteUInt(table.Count(Warden.Settings), 8)
	for k, v in pairs(Warden.Settings) do
		net.WriteString(k)
		net.WriteInt(v, Warden.SETTINGS_OPTION_NET_SIZE)
	end
end

-- in case of file reload
if WARDEN_LOADED then
	sendAll()
	net.Broadcast()
end

gameevent.Listen("player_activate")
hook.Add("player_activate", "WardenSettings", function(data)
	local ply = Player(data.userid)
	if not ply:IsValid() then return end

	sendAll()
	net.Send(ply)
end)

net.Receive("WardenAdminSettingChange", function(_, ply)
	if not ply:IsSuperAdmin() then
		ply:ChatPrint("Only superadmins can change Warden's settings.")
		return
	end

	local setting = net.ReadString()
	local value = net.ReadInt(Warden.SETTINGS_OPTION_NET_SIZE)

	Warden.SetServerSetting(setting, value)
end)