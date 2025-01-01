util.AddNetworkString("WardenAdminSettingChange")

net.Receive("WardenAdminSettingChange", function(_, ply)
	if not ply:IsSuperAdmin() then
		ply:ChatPrint("Only superadmins can change Warden's settings.")
		return
	end

	local setting = net.ReadString()
	local value = net.ReadInt(8)

	local cvar = GetConVar("warden_" .. setting)
	if not cvar then return end

	cvar:SetInt(value)
end)