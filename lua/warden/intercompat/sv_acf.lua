hook.Add("PostGamemodeLoaded", "WardenACFCompat", function()
	if not ACF or not ACF.Permissions or not ACF.Damage then return end

	local oldCanDamage = ACF.Permissions.CanDamage
	function ACF.Permissions.CanDamage(ent, _, dmgInfo)
		if not Warden.GetServerBool("override_acf", false) then
			return oldCanDamage(ent, nil, dmgInfo)
		end

		local owner = ent:WardenGetOwner()
		if not IsValid(owner) or owner:IsWorld() then return false end

		local attacker = dmgInfo:GetAttacker()
		if not Warden.CheckPermission(attacker, ent, Warden.PERMISSION_DAMAGE) then return false end

		return oldCanDamage(ent, nil, dmgInfo)
	end

	hook.Add("ACF_PreDamageEntity", "ACF_DamagePermissionCore", ACF.Permissions.CanDamage)

	local doSquishyDamage = ACF.Damage.doSquishyDamage

	local function isForcedSquishy(ent)
		local owner = ent:WardenGetOwner()
		return IsValid(owner) and owner:IsPlayer() and owner:GetInfoNum("warden_acf_squishy_damage_1", 1) ~= 0
	end

	local function overrideOnDamage(self, ...)
		-- use the squishy damage handler instead of the entity's custom method
		if isForcedSquishy(self) then
			return doSquishyDamage(self, ...)
		end
		return self:ACF_OldOnDamage(...)
	end

	local oldCheck = ACF.Check
	function ACF.Check(ent, forceUpdate)
		local value = oldCheck(ent, forceUpdate)
		if value ~= false then
			if isForcedSquishy(ent) then
				if ent.ACF_OnDamage and not ent.ACF_OldOnDamage then
					ent.ACF_OldOnDamage = ent.ACF_OnDamage
					ent.ACF_OnDamage = overrideOnDamage
				end
				-- tell ACF to treat this entity as squishy
				return "Squishy"
			else
				if ent.ACF_OldOnDamage then
					ent.ACF_OnDamage = ent.ACF_OldOnDamage
					ent.ACF_OldOnDamage = nil
				end
			end
		end
		return value
	end

	SetGlobalBool("WardenACF", true)
end)
