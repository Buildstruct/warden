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

	setting = string.sub(setting, 1, 100)

	if table.Count(Warden.Settings) >= 255 and not Warden.Settings[setting] then
		error("[WARDEN] Too many settings on file?")
	end

	Warden.Settings[setting] = newVal
	file.Write("warden/settings.json", util.TableToJSON(Warden.Settings))

	net.Start("WardenAdminSettingChange")
	net.WriteUInt(1, 8)
	net.WriteString(setting)
	net.WriteInt(newVal, 11)
	net.Broadcast()
end

local function sendAll()
	net.Start("WardenAdminSettingChange")
	net.WriteUInt(table.Count(Warden.Settings), 8)
	for k, v in pairs(Warden.Settings) do
		net.WriteString(k)
		net.WriteInt(v, 11)
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
	local value = net.ReadInt(11)

	Warden.SetServerSetting(setting, value)
end)