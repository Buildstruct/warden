util.AddNetworkString("WardenAdmin")

local PLAYER = FindMetaTable("Player")

function PLAYER:WardenSetAdminLevel(level)
	if type(level) ~= "number" and type(level) ~= "nil" then
		error("admin level must be a number or nil", 2)
	end

	level = math.Clamp(level, Warden.ADMIN_LEVEL_MIN, Warden.ADMIN_LEVEL_MAX)

	self.WardenAdminLevel = level

	net.Start("WardenAdmin")
	net.WriteUInt(Warden.ADMIN_NET.ADMIN_LEVEL, Warden.ADMIN_NET_SIZE)
	net.WriteUInt(level, Warden.ADMIN_LEVEL_NET_SIZE)
	net.Send(self)
end

function Warden.ClearSettings()
	Warden.Settings = {}
	file.Write("warden/settings.json", util.TableToJSON(Warden.Settings))

	net.Start("WardenAdmin")
	net.WriteUInt(Warden.ADMIN_NET.CLEAR_SETTINGS, Warden.ADMIN_NET_SIZE)
	net.Broadcast()
end

function Warden.ClearClassFilters()
	Warden.ClassFilters = {}
	Warden._ResetClassCaches()
	file.Write("warden/classfilters.json", util.TableToJSON(Warden.ClassFilters))

	net.Start("WardenAdmin")
	net.WriteUInt(Warden.ADMIN_NET.CLEAR_CLASSES, Warden.ADMIN_NET_SIZE)
	net.Broadcast()
end

function Warden.ClearModelFilters()
	Warden.ModelFilters = {}
	file.Write("warden/modelfilters.json", util.TableToJSON(Warden.ModelFilters))

	net.Start("WardenAdmin")
	net.WriteUInt(Warden.ADMIN_NET.CLEAR_MODELS, Warden.ADMIN_NET_SIZE)
	net.Broadcast()
end

local function netNotif(msg)
	net.Start("WardenAdmin")
	net.WriteUInt(Warden.ADMIN_NET.MESSAGE, Warden.ADMIN_NET_SIZE)
	net.WriteString(msg)
	net.Broadcast()
end

local adminStuffs = {
	[Warden.ADMIN_NET.ADMIN_LEVEL] = function(ply)
		if not ply:IsAdmin() then return end

		local al = net.ReadUInt(Warden.ADMIN_LEVEL_NET_SIZE)

		ply:WardenSetAdminLevel(al)
	end,
	[Warden.ADMIN_NET.CLEAR_DISCONNECTED] = function(ply)
		if not ply:IsAdmin() then return end

		Warden.CleanupDisconnected()

		netNotif(string.format("%s cleaned up all disconnected players' props", ply:GetName()))
	end,
	[Warden.ADMIN_NET.CLEAR_ENTS] = function(ply)
		if not ply:IsAdmin() then return end

		local target = net.ReadEntity()
		if not target:IsValid() or not target:IsPlayer() then return end

		target:WardenCleanupEntities()

		netNotif(string.format("%s cleaned up %s's props", ply:GetName(), target:GetName()))
	end,
	[Warden.ADMIN_NET.FREEZE_ENTS] = function(ply)
		if not ply:IsAdmin() then return end

		local target = net.ReadEntity()
		if not target:IsValid() or not target:IsPlayer() then return end

		target:WardenFreezeEntities()

		netNotif(string.format("%s froze %s's props", ply:GetName(), target:GetName()))
	end,
	[Warden.ADMIN_NET.CLEAR_SETTINGS] = function(ply)
		if not ply:IsSuperAdmin() then
			ply:ChatPrint("Only superadmins can change Warden's settings.")
			return
		end

		Warden.ClearSettings()
	end,
	[Warden.ADMIN_NET.CLEAR_CLASSES] = function(ply)
		if not ply:IsSuperAdmin() then
			ply:ChatPrint("Only superadmins can change Warden's settings.")
			return
		end

		Warden.ClearClassFilters()
	end,
	[Warden.ADMIN_NET.CLEAR_MODELS] = function(ply)
		if not ply:IsSuperAdmin() then
			ply:ChatPrint("Only superadmins can change Warden's settings.")
			return
		end

		Warden.ClearModelFilters()
	end,
}

net.Receive("WardenAdmin", function(_, ply)
	local kind = net.ReadUInt(Warden.ADMIN_NET_SIZE)

	if adminStuffs[kind] then
		adminStuffs[kind](ply)
	end
end)