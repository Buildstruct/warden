function Warden.RequestAdminLevel(adminLevel)
	if not LocalPlayer():IsAdmin() then return end

	net.Start("WardenAdmin")
	net.WriteString("al")
	net.WriteUInt(adminLevel, Warden.ADMIN_LEVEL_NET_SIZE)
	net.SendToServer()
end

function Warden.CleanupDisconnected()
	if not LocalPlayer():IsAdmin() then return end

	net.Start("WardenAdmin")
	net.WriteString("cupdis")
	net.SendToServer()
end

function Warden.CleanupEntities(ply)
	if not LocalPlayer():IsAdmin() then return end

	net.Start("WardenAdmin")
	net.WriteString("cup")
	net.WriteEntity(ply)
	net.SendToServer()
end

function Warden.FreezeEntities(ply)
	if not LocalPlayer():IsAdmin() then return end

	net.Start("WardenAdmin")
	net.WriteString("pfz")
	net.WriteEntity(ply)
	net.SendToServer()
end

net.Receive("WardenAdmin", function()
	Warden.LocalAdminLevel = net.ReadUInt(Warden.ADMIN_LEVEL_NET_SIZE)
end)