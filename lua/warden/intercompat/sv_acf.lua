hook.Add("InitPostEntity", "WardenACF1", function()
	if not ACF then return end

	local doSquishy
	local doSquishyDamage
	local function overrideOnDamage(self, ...)
		if doSquishy then
			return doSquishyDamage(self, ...)
		end

		return self:ACF_OldOnDamage(...)
	end

	local oldCheck
	local function overrideCheck(ent, forceUpdate)
		local value = oldCheck(ent, forceUpdate)
		if not value then return value end

		if doSquishy then
			if ent.ACF_OnDamage and not ent.ACF_OldOnDamage then
				ent.ACF_OldOnDamage = ent.ACF_OnDamage
				ent.ACF_OnDamage = overrideOnDamage
			end

			-- tell ACF to treat this entity as squishy
			return "Squishy"
		end

		if ent.ACF_OldOnDamage then
			ent.ACF_OnDamage = ent.ACF_OldOnDamage
			ent.ACF_OldOnDamage = nil
		end

		return value
	end

	local oldCanDamage
	local function canDamage(ent, inflictor, ...)
		if Warden.GetPermission(Warden.PERMISSION_ACF) and Warden.CheckPermission(inflictor, ent, Warden.PERMISSION_ACF) then return end
		if oldCanDamage(...) == false then return false end
		if not Warden.CheckPermission(inflictor, ent, Warden.PERMISSION_DAMAGE) then return false end
	end

	-- ACE
	if not ACF.Damage then
		oldCanDamage = ACF.Permissions.CanDamage
		function ACF.Permissions.CanDamage(ent, energy, frArea, angle, inflictor, bone, gun, _type)
			return canDamage(ent, inflictor, ent, energy, frArea, angle, inflictor, bone, gun, _type)
		end

		hook.Add("ACF_BulletDamage", "ACF_DamagePermissionCore", ACF.Permissions.CanDamage)

		local oldDamage = ACF_Damage
		function ACF_Damage(ent, energy, frArea, angle, inflictor, bone, gun, _type)
			doSquishy = not Warden.CheckPermission(inflictor, ent, Warden.PERMISSION_ACF)
			local result = oldDamage(ent, energy, frArea, angle, inflictor, bone, gun, _type)
			doSquishy = nil

			return result
		end

		doSquishyDamage = ACF_SquishyDamage
		oldCheck = ACF_Check
		CF_Check = overrideCheck

		return
	end

	oldCanDamage = ACF.Permissions.CanDamage
	function ACF.Permissions.CanDamage(ent, two, dmgInfo)
		return canDamage(ent, dmgInfo:GetAttacker(), ent, two, dmgInfo)
	end

	hook.Add("ACF_PreDamageEntity", "ACF_DamagePermissionCore", ACF.Permissions.CanDamage)

	local oldDealDamage = ACF.Damage.dealDamage
	function ACF.Damage.dealDamage(ent, dmgResult, dmgInfo)
		doSquishy = not Warden.CheckPermission(dmgInfo:GetAttacker(), ent, Warden.PERMISSION_ACF)
		local result = oldDealDamage(ent, dmgResult, dmgInfo)
		doSquishy = nil

		return result
	end

	doSquishyDamage = ACF.Damage.doSquishyDamage
	oldCheck = ACF.Check
	ACF.Check = overrideCheck

	SetGlobalBool("WardenACF", true)
end)
