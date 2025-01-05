util.AddNetworkString("WardenAdmin")

local PLAYER = FindMetaTable("Player")

function PLAYER:WardenSetAdminLevel(level)
	if type(level) ~= "number" and type(level) ~= "nil" then
		error("admin level must be a number or nil", 2)
	end

	self.WardenAdminLevel = level

	net.Start("WardenAdmin")
	net.WriteBool(true)
	net.WriteUInt(level, Warden.ADMIN_LEVEL_NET_SIZE)
	net.Send(self)
end

local function netNotif(msg)
	net.Start("WardenAdmin")
	net.WriteBool(false)
	net.WriteString(msg)
	net.Broadcast()
end

local adminStuffs = {
	al = function(ply)
		local al = net.ReadUInt(Warden.ADMIN_LEVEL_NET_SIZE)

		ply:WardenSetAdminLevel(al)
	end,
	cupdis = function(ply)
		Warden.CleanupDisconnected()

		netNotif(string.format("%s cleaned up all disconnected players' props", ply:GetName()))
	end,
	cup = function(ply)
		local target = net.ReadEntity()
		if not target:IsValid() or not target:IsPlayer() then return end

		target:WardenCleanupEntities()

		netNotif(string.format("%s cleaned up %s's props", ply:GetName(), target:GetName()))
	end,
	pfz = function(ply)
		local target = net.ReadEntity()
		if not target:IsValid() or not target:IsPlayer() then return end

		target:WardenFreezeEntities()

		netNotif(string.format("%s froze %s's props", ply:GetName(), target:GetName()))
	end
}

net.Receive("WardenAdmin", function(_, ply)
	if not ply:IsAdmin() then return end

	local kind = net.ReadString()
	if adminStuffs[kind] then
		adminStuffs[kind](ply)
	end
end)