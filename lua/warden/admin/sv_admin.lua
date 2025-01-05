util.AddNetworkString("WardenAdmin")

function PLAYER:WardenSetAdminLevel(level)
	if type(level) ~= "number" and type(level) ~= "nil" then
		error("admin level must be a number or nil", 2)
	end

	self.WardenAdminLevel = level

	net.Start("WardenAdmin")
		net.WriteUInt(level, Warden.ADMIN_LEVEL_NET_SIZE)
	net.Send(self)
end

local adminStuffs = {
	al = function(ply)
		ply:WardenSetAdminLevel(net.ReadUInt(Warden.ADMIN_LEVEL_NET_SIZE))
	end,
	cupdis = function(ply)
		Warden.CleanupDisconnected()
	end,
	cup = function(ply)
		local target = net.ReadEntity()
		if not target:IsValid() then return end

		target:WardenCleanupEntities()
	end,
	pfz = function(ply)
		local target = net.ReadEntity()
		if not target:IsValid() then return end

		target:WardenFreezeEntities()
	end
}

net.Receive("WardenAdmin", function(_, ply)
	if not ply:IsAdmin() then return end

	local kind = net.ReadString()
	if adminStuffs[kind] then
		adminStuffs[kind](ply)
	end
end)