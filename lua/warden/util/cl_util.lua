CreateClientConVar("warden_touch_self", 1, true, true, "Whether you can touch your own entities.", 0, 1)

net.Receive("WardenAdminLevel", function()
	Warden.LocalAdminLevel = net.ReadUInt(8)
end)

function Warden.RequestAdminLevel(adminLevel)
	if not LocalPlayer():IsAdmin() then return end

	net.Start("WardenAdminLevel")
	net.WriteUInt(adminLevel, 8)
	net.SendToServer()
end