CPPI = CPPI or {}

CPPI.CPPI_DEFER = "CPPI_DEFER"
CPPI.CPPI_NOTIMPLEMENTED = "CPPI_NOTIMPLEMENTED"

function CPPI.GetName()
	return "Warden"
end

function CPPI.GetVersion()
	return "1.0"
end

function CPPI.GetInterfaceVersion()
	return 1.3
end

function CPPI.GetNameFromUID()
	return CPPI.CPPI_NOTIMPLEMENTED
end

local plyMeta = FindMetaTable("Player")

function plyMeta:CPPIGetFriends()
	local friends = {}

	for _, ply in player.Iterator() do
		if Warden.CheckPermission(ply, self, Warden.PERMISSION_TOOL) then
			table.insert(friends, ply)
		end
	end

	return friends
end

local entMeta = FindMetaTable("Entity")

function entMeta:CPPIGetOwner()
	local ownerEnt = Warden.GetOwner(self)
	local steamID = Warden.GetOwnerID(self)

	if Warden.IsValid(ownerEnt) then
		return ownerEnt, steamID
	elseif steamID ~= "" then
		return nil, steamID
	end
end

if SERVER then
	function entMeta:CPPISetOwner(ply)
		return Warden.SetOwner(self, ply)
	end

	function entMeta:CPPISetOwnerUID()
		return CPPI.CPPI_NOTIMPLEMENTED
	end

	function entMeta:CPPICanTool(ply)
		return Warden.CheckPermission(ply, self, Warden.PERMISSION_TOOL)
	end
	entMeta.CPPICanProperty = entMeta.CPPICanTool
	entMeta.CPPICanEditVariable = entMeta.CPPICanTool

	function entMeta:CPPICanPhysgun(ply)
		return Warden.CheckPermission(ply, self, Warden.PERMISSION_PHYSGUN)
	end

	function entMeta:CPPICanPickup(ply)
		return Warden.CheckPermission(ply, self, Warden.PERMISSION_GRAVGUN)
	end

	function entMeta:CPPICanPunt(ply)
		if not Warden.GetServerBool("gravgun_punt", true) and not Warden.PlyBypassesFilters(ply) then
			return false
		end

		return Warden.CheckPermission(ply, self, Warden.PERMISSION_GRAVGUN)
	end

	function entMeta:CPPICanUse(ply)
		return Warden.CheckPermission(ply, self, Warden.PERMISSION_USE)
	end
	entMeta.CPPIDrive = entMeta.CPPICanUse

	function entMeta:CPPICanDamage(ply)
		return Warden.CheckPermission(ply, self, Warden.PERMISSION_DAMAGE)
	end
end

