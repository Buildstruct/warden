function Warden.RequestAdminLevel(adminLevel)
	if not LocalPlayer():IsAdmin() then return end

	net.Start("WardenAdmin")
	net.WriteUInt(Warden.ADMIN_NET.ADMIN_LEVEL, Warden.ADMIN_NET_SIZE)
	net.WriteUInt(adminLevel, Warden.ADMIN_LEVEL_NET_SIZE)
	net.SendToServer()
end

function Warden.CleanupDisconnected()
	if not LocalPlayer():IsAdmin() then return end

	net.Start("WardenAdmin")
	net.WriteUInt(Warden.ADMIN_NET.CLEAR_DISCONNECTED, Warden.ADMIN_NET_SIZE)
	net.SendToServer()
end

function Warden.CleanupEntities(ply)
	if not LocalPlayer():IsAdmin() then return end

	net.Start("WardenAdmin")
	net.WriteUInt(Warden.ADMIN_NET.CLEAR_ENTS, Warden.ADMIN_NET_SIZE)
	net.WriteEntity(ply)
	net.SendToServer()
end

function Warden.FreezeEntities(ply)
	if not LocalPlayer():IsAdmin() then return end

	net.Start("WardenAdmin")
	net.WriteUInt(Warden.ADMIN_NET.FREEZE_ENTS, Warden.ADMIN_NET_SIZE)
	net.WriteEntity(ply)
	net.SendToServer()
end

function Warden.ClearSettings(kind)
	if not LocalPlayer():IsSuperAdmin() then
		LocalPlayer():ChatPrint("Only superadmins can change Warden's settings.")
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
		notification.AddLegacy(net.ReadString(), NOTIFY_CLEANUP, 7)
		surface.PlaySound("buttons/button14.wav")
	end
}

net.Receive("WardenAdmin", function()
	local kind = net.ReadUInt(Warden.ADMIN_NET_SIZE)

	if adminStuffs[kind] then
		adminStuffs[kind]()
	end
end)