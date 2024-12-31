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
	if not ent or ent:IsWorld() then return end
	if not ent:IsPlayer() and Warden.GetOwner(ent) == game.GetWorld() then return end

	local attacker = dmg:GetAttacker()
	local inflictor = dmg:GetInflictor()
	local owner = Warden.GetOwner(inflictor)
	local entOwner = Warden.GetOwner(ent)
	local ValidAttacker = IsValid(attacker)

	-- fix fire damage
	if ValidAttacker and attacker:GetClass() == "entityflame" and IsValid(attacker:GetParent()) then
		local newAttacker = attacker:GetParent():CPPIGetOwner()
		if Warden.IsValidOwner(newAttacker) then
			attacker = newAttacker
			dmg:SetAttacker(attacker)
		end
	end

	-- Ignored damage types
	if ent:IsVehicle() then
		return
	end

	if ValidAttacker and attacker:IsPlayer() then
		-- Damage between players and players
		if ent:IsPlayer() and not Warden.CheckPermission(attacker, ent, Warden.PERMISSION_DAMAGE) then
			return true
		end

		-- Damage between players and props
		if IsValid(entOwner) and entOwner:IsPlayer() and not Warden.CheckPermission(attacker, ent, Warden.PERMISSION_DAMAGE) then
			return true
		end
	end

	-- Prevent crush damage / damage from the world
	if ent:IsPlayer() and attacker:IsWorld() or not ValidAttacker then
		return true
	end

	-- Damage between unknown attackers and their owners
	if IsValid(owner) and owner:IsPlayer() and not Warden.CheckPermission(owner, ent, Warden.PERMISSION_DAMAGE) then
		return true
	end
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
	Warden.Permissions[steamID] = nil

	if GetConVar("warden_freeze_disconnect"):GetBool() then
		Warden.FreezeEntities(steamID)
	end

	if GetConVar("warden_cleanup_disconnect"):GetBool() then
		local time = GetConVar("warden_cleanup_time"):GetInt()
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