hook.Add("InitPostEntity", "WardenACF", function()
	if not ACF then return end

	Warden.PERMISSION_ACF, acf = Warden.RegisterPermissionSimple("acf", "ACF", 2, nil, "warden/acf.png", "icon16/car.png")
	acf.Default = true
	acf.Enabled = false

	if not SERVER then return end

	local oldCanDamage = ACF.Permissions.CanDamage
	function ACF.Permissions.CanDamage(ent, _, dmgInfo)
		if not oldCanDamage(ent, nil, dmgInfo) then return false end
		return Warden.CheckPermission(dmgInfo:GetAttacker(), ent, Warden.PERMISSION_ACF)
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
