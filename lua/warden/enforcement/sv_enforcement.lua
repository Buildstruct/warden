local USE_EXCEPTIONS = {
	mediaplayer_tv = true,
	mediaplayer_tv_ext = true
}

hook.Add("GravGunPickupAllowed", "Warden", function(ply, ent)
	if not Warden.CheckPermission(ply, ent, Warden.PERMISSION_GRAVGUN) then
		return false
	end
end)

hook.Add("PlayerUse", "Warden", function(ply, ent)
	if USE_EXCEPTIONS[ent:GetClass()] or ent.AlwaysUsable then return end

	if not Warden.CheckPermission(ply, ent, Warden.PERMISSION_USE) then
		return false
	end
end)

hook.Add("EntityTakeDamage", "Warden", function(ent, dmg)
	local attacker = dmg:GetAttacker()

	-- fix fire damage
	if IsValid(attacker) and attacker:GetClass() == "entityflame" and Warden.IsValidOwner(attacker:GetParent()) then
		local newAttacker = attacker:GetParent():CPPIGetOwner()
		if Warden.IsValidOwner(newAttacker) then
			attacker = newAttacker
			dmg:SetAttacker(attacker)
		end
	end

	if not Warden.CheckPermission(attacker, ent, Warden.PERMISSION_DAMAGE) then return true end

	local inflictOwner = Warden.GetOwner(dmg:GetInflictor())
	if not Warden.CheckPermission(inflictOwner, ent, Warden.PERMISSION_DAMAGE) then return true end
end)

hook.Add("CanEditVariable", "Warden", function(ent, ply)
	if not Warden.CheckPermission(ply, ent, Warden.PERMISSION_TOOL) then
		return false
	end
end)

hook.Add("OnPhysgunReload", "Warden", function(_, ply)
	local ent = ply:GetEyeTrace().Entity

	if not Warden.CheckPermission(ply, ent, Warden.PERMISSION_PHYSGUN) then
		return false
	end
end)

gameevent.Listen("player_disconnect")
hook.Add("player_disconnect", "WardenPlayerDisconnect", function(data)
	local steamID = data.networkid
	Warden.PlyPerms[steamID] = nil

	if Warden.GetServerBool("freeze_disconnect", true) then
		Warden.FreezeEntities(steamID)
	end

	if Warden.GetServerBool("cleanup_disconnect", true) then
		local time = Warden.GetServerSetting("warden_cleanup_time")
		local name = data.name

		timer.Create("WardenCleanup#" .. steamID, time, 1, function()
			local count = Warden.CleanupEntities(steamID)
			hook.Run("WardenNaturalCleanup", name, time, steamID, count)
		end)
	end
end)

hook.Add("CanProperty", "Warden", function(ply, property, ent)
	if not Warden.CheckPermission(ply, ent, Warden.PERMISSION_TOOL) then
		return false
	end
end)