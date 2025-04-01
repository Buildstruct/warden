hook.Add("GravGunPickupAllowed", "Warden", function(ply, ent)
	if not Warden.CheckPermission(ply, ent, Warden.PERMISSION_GRAVGUN) then
		return false
	end
end)

hook.Add("PlayerUse", "Warden", function(ply, ent)
	if not Warden.CheckPermission(ply, ent, Warden.PERMISSION_USE) then
		return false
	end
end)

hook.Add("EntityTakeDamage", "Warden", function(ent, dmg)
	if not IsValid(ent) then return end
	if not Warden.GetServerBool("phy_damage", true) and dmg:IsDamageType(DMG_CRUSH) then return true end

	local attacker = dmg:GetAttacker()
	local validAtt = IsValid(attacker)

	-- sometimes physics damage is attributed to world when it really should not be
	if not validAtt and dmg:IsDamageType(DMG_CRUSH) then
		local perm = Warden.GetPermission(Warden.PERMISSION_DAMAGE, true)
		if perm and (perm:GetEnabled() or not perm:GetDefault()) then
			return true
		end
	end

	-- fix fire damage
	if validAtt and attacker:GetClass() == "entityflame" and Warden.IsValid(attacker:GetParent()) then
		local newAttacker = Warden.GetOwner(attacker:GetParent())
		if Warden.IsValid(newAttacker) then
			attacker = newAttacker
			dmg:SetAttacker(attacker)
		end
	end

	if Warden.CheckPermission(attacker, ent, Warden.PERMISSION_DAMAGE) then return end

	local inflictor = dmg:GetInflictor()
	local infOwnerID = Warden.GetOwnerID(inflictor)
	if not validAtt and infOwnerID and infOwnerID ~= "World" and Warden.CheckPermission(inflictor, ent, Warden.PERMISSION_DAMAGE) then return end

	return true
end)

hook.Add("CanEditVariable", "Warden", function(ent, ply)
	if not Warden.CheckPermission(ply, ent, Warden.PERMISSION_TOOL) then
		return false
	end
end)

hook.Add("OnPhysgunReload", "Warden", function(_, ply)
	if not Warden.GetServerBool("physgun_reload", true) and not Warden.PlyBypassesFilters(ply) then return false end

	if not Warden.CheckPermission(ply, ply:GetEyeTrace().Entity, Warden.PERMISSION_PHYSGUN) then
		return false
	end
end)

gameevent.Listen("player_disconnect")
hook.Add("player_disconnect", "WardenPlayerDisconnect", function(data)
	local steamID = data.networkid

	if Warden.GetServerBool("freeze_disconnect", true) then
		Warden.FreezeEntities(steamID)
	end

	if Warden.GetServerBool("cleanup_disconnect", true) then
		local time = Warden.GetServerSetting("cleanup_time", 600)
		local name = data.name

		timer.Create("WardenCleanup#" .. steamID, time, 1, function()
			local count = Warden.CleanupEntities(steamID)
			hook.Run("WardenNaturalCleanup", name, time, steamID, count)

			if Warden.GetServerBool("cleanup_notify", true) and count > 0 then
				Warden.Notify(nil, "%s's props were cleaned up automatically", name)
			end
		end)
	end
end)

hook.Add("CanProperty", "Warden", function(ply, property, ent)
	if not Warden.CheckPermission(ply, ent, Warden.PERMISSION_TOOL) then
		return false
	end
end)

hook.Add("PlayerSpawnObject", "Warden", function(ply, model)
	if not Warden.IsModelBlocked(model) then return end
	if Warden.PlyBypassesFilters(ply) then return end
	return false
end)

local blockHooks = { "PlayerSpawnSENT", "PlayerSpawnSWEP", "PlayerGiveSWEP" }

for _, v in ipairs(blockHooks) do
	hook.Add(v, "WardenBlock", function(ply, class)
		if not Warden.IsClassBlocked(class) then return end
		if Warden.PlyBypassesFilters(ply) then return end
		return false
	end)
end

hook.Add("PlayerSpawnNPC", "WardenBlock", function(ply, class, wep)
	if not Warden.IsClassBlocked(class) and not Warden.IsClassBlocked(wep) then return end
	if Warden.PlyBypassesFilters(ply) then return end
	return false
end)

hook.Add("PlayerSpawnVehicle", "WardenBlock", function(ply, _, class)
	if not Warden.IsClassBlocked(class) then return end
	if Warden.PlyBypassesFilters(ply) then return end
	return false
end)

hook.Add("PlayerSpawnProp", "WardenBlock", function(ply)
	if not Warden.IsClassBlocked("prop_physics") then return end
	if Warden.PlyBypassesFilters(ply) then return end
	return false
end)

hook.Add("PlayerSpawnRagdoll", "WardenBlock", function(ply)
	if not Warden.IsClassBlocked("prop_ragdoll") then return end
	if Warden.PlyBypassesFilters(ply) then return end
	return false
end)

hook.Add("PlayerSpawnEffect", "WardenBlock", function(ply)
	if not Warden.IsClassBlocked("prop_effect") then return end
	if Warden.PlyBypassesFilters(ply) then return end
	return false
end)