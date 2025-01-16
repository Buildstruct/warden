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
	local attacker = dmg:GetAttacker()
	local validAtt = IsValid(attacker)

	-- fix fire damage
	if validAtt and attacker:GetClass() == "entityflame" and Warden.IsValid(attacker:GetParent()) then
		local newAttacker = attacker:GetParent():CPPIGetOwner()
		if Warden.IsValid(newAttacker) then
			attacker = newAttacker
			dmg:SetAttacker(attacker)
		end
	end

	if Warden.GetServerBool("block_phy_damage", true) and dmg:IsDamageType(DMG_CRUSH) then
		return true
	end

	if Warden.CheckPermission(attacker, ent, Warden.PERMISSION_DAMAGE) then return end
	if Warden.CheckPermission(dmg:GetInflictor(), ent, Warden.PERMISSION_DAMAGE) then return end
	return true
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

	if Warden.GetServerBool("freeze_disconnect", true) then
		Warden.FreezeEntities(steamID)
	end

	if Warden.GetServerBool("cleanup_disconnect", true) then
		local time = Warden.GetServerSetting("cleanup_time", 600)
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