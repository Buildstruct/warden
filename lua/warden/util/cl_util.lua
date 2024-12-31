net.Receive("WardenAdminLevel", function()
	Warden.LocalAdminLevel = net.ReadUInt(8)
end)

function Warden.RequestAdminLevel(adminLevel)
	net.Start("WardenAdminLevel")
	net.WriteUInt(adminLevel, 8)
	net.SendToServer()
end