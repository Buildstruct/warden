hook.Add("InitPostEntity", "WardenACF1", function()
	if not ACF then return end

	local oldCanDamage = ACF.Permissions.CanDamage
	function ACF.Permissions.CanDamage(ent, _, dmgInfo)
		if Warden.GetPermission(Warden.PERMISSION_ACF) and Warden.CheckPermission(dmgInfo:GetAttacker(), ent, Warden.PERMISSION_ACF) then return end
		if oldCanDamage(ent, nil, dmgInfo) == false then return false end
		if not Warden.CheckPermission(dmgInfo:GetAttacker(), ent, Warden.PERMISSION_DAMAGE) then return false end
	end

	hook.Add("ACF_PreDamageEntity", "ACF_DamagePermissionCore", ACF.Permissions.CanDamage)

	local doSquishy
	local oldDealDamage = ACF.Damage.dealDamage
	function ACF.Damage.dealDamage(ent, dmgResult, dmgInfo)
		doSquishy = not Warden.CheckPermission(dmgInfo:GetAttacker(), ent, Warden.PERMISSION_ACF)
		local result = oldDealDamage(ent, dmgResult, dmgInfo)
		doSquishy = nil

		return result
	end

	local doSquishyDamage = ACF.Damage.doSquishyDamage
	local function overrideOnDamage(self, ...)
		if doSquishy then
			return doSquishyDamage(self, ...)
		end

		return self:ACF_OldOnDamage(...)
	end

	local oldCheck = ACF.Check
	function ACF.Check(ent, forceUpdate)
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

	SetGlobalBool("WardenACF", true)
end)
