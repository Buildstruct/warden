function Warden.RequestAdminLevel(adminLevel)
	if not LocalPlayer():WardenGetCmdPerm("warden_admin_level") then return end

	net.Start("WardenAdmin")
	net.WriteUInt(Warden.ADMIN_NET.ADMIN_LEVEL, Warden.ADMIN_NET_SIZE)
	net.WriteUInt(adminLevel, Warden.ADMIN_LEVEL_NET_SIZE)
	net.SendToServer()
end

function Warden.CleanupDisconnected()
	if not LocalPlayer():WardenGetCmdPerm("warden_cleanup_disconnected") then return end

	net.Start("WardenAdmin")
	net.WriteUInt(Warden.ADMIN_NET.CLEAR_DISCONNECTED, Warden.ADMIN_NET_SIZE)
	net.SendToServer()
end

function Warden.CleanupEntities(ply)
	if not LocalPlayer():WardenGetCmdPerm("warden_cleanup_entities") then return end

	net.Start("WardenAdmin")
	net.WriteUInt(Warden.ADMIN_NET.CLEAR_ENTS, Warden.ADMIN_NET_SIZE)
	net.WriteEntity(ply)
	net.SendToServer()
end

function Warden.FreezeEntities(ply)
	if not LocalPlayer():WardenGetCmdPerm("warden_freeze_entities") then return end

	net.Start("WardenAdmin")
	net.WriteUInt(Warden.ADMIN_NET.FREEZE_ENTS, Warden.ADMIN_NET_SIZE)
	net.WriteEntity(ply)
	net.SendToServer()
end

function Warden.ClearSettings(kind)
	if not LocalPlayer():IsSuperAdmin() then
		Warden.SAInform()
		return
	end

	net.Start("WardenAdmin")
	net.WriteUInt(kind, Warden.ADMIN_NET_SIZE)
	net.SendToServer()
end

local adminStuffs = {
	[Warden.ADMIN_NET.ADMIN_LEVEL] = function()
		Warden.LocalAdminLevel = net.ReadUInt(Warden.ADMIN_LEVEL_NET_SIZE)
	end,
	[Warden.ADMIN_NET.CLEAR_SETTINGS] = function()
		Warden.Settings = {}
	end,
	[Warden.ADMIN_NET.CLEAR_CLASSES] = function()
		Warden.ClassFilters = {}
		Warden._ResetClassCaches()
	end,
	[Warden.ADMIN_NET.CLEAR_MODELS] = function()
		Warden.ModelFilters = {}
	end,
	[Warden.ADMIN_NET.MESSAGE] = function()
		local msg = net.ReadString()
		local name = net.ReadString()
		local name1 = net.ReadString()

		notification.AddLegacy(Warden.L(msg, name, name1), NOTIFY_CLEANUP, 7)
		surface.PlaySound("buttons/button22.wav")
	end
}

net.Receive("WardenAdmin", function()
	local kind = net.ReadUInt(Warden.ADMIN_NET_SIZE)

	if adminStuffs[kind] then
		adminStuffs[kind]()
	end
end)