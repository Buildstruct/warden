hook.Add("InitPostEntity", "WardenACF1", function()
	if not ACF then return end

	local oldCanDamage = ACF.Permissions.CanDamage
	function ACF.Permissions.CanDamage(ent, _, dmgInfo)
		local perm = Warden.GetPermission(Warden.PERMISSION_ACF, true)
		if not perm then return oldCanDamage(ent, nil, dmgInfo) end

		local attacker = dmgInfo:GetAttacker()

		if not perm:GetEnabled() then
			if not oldCanDamage(ent, nil, dmgInfo) then return false end
			if not Warden.CheckPermission(attacker, ent, Warden.PERMISSION_DAMAGE) then return false end
			if not perm:GetDefault() then return false end

			return
		end

		if ACF.EnableSafezones and ACF.Permissions.Safezones then
			if ACF.Permissions.IsInSafezone(ent:GetPos()) then return false end
			if IsValid(attacker) and ACF.Permissions.IsInSafezone(attacker:GetPos()) then return false end
		end

		if not Warden.CheckPermission(attacker, ent, Warden.PERMISSION_ACF) then return false end
	end

	hook.Add("ACF_PreDamageEntity", "ACF_DamagePermissionCore", ACF.Permissions.CanDamage)

	local doSquishyDamage = ACF.Damage.doSquishyDamage

	local function isForcedSquishy(ent)
		local owner = ent:WardenGetOwner()
		if not IsValid(owner) or not owner:IsPlayer() then return false end

		local squishy = owner:GetInfoNum("warden_acf_squishy_damage", -1)
		if squishy < 0 then return Warden.GetServerBool("acf_default_squishy_damage", false) end

		return squishy ~= 0
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
