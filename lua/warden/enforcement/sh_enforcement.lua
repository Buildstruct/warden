hook.Add("CanTool", "Warden", function(ply, tr, tool)
	local ent = tr.Entity
	if ent:IsWorld() then return true end

	if not Warden.CheckPermission(ply, ent, Warden.PERMISSION_TOOL) then
		return false
	end
end)

hook.Add("GravGunPunt", "Warden", function(ply, ent)
	if not Warden.GetServerBool("gravgun_punt", true) and not Warden.PlyBypassesFilters(ply) then
		return false
	end

	if not Warden.CheckPermission(ply, ent, Warden.PERMISSION_GRAVGUN) then
		return false
	end
end)

hook.Add("PhysgunPickup", "Warden", function(ply, ent)
	if ent:IsPlayer() and not Warden.CheckPermission(ply, ent, Warden.PERMISSION_PHYSGUN) then
		return false
	end
end)