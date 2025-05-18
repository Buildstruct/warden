hook.Add("PostGamemodeLoaded", "WardenACFCompat", function()
	if not ACF or not ACF.Permissions then return end

	local oldCanDamage = ACF.Permissions.CanDamage
	function ACF.Permissions.CanDamage(ent, _, dmgInfo)
		if not Warden.GetServerBool("override_acf", false) then
			return oldCanDamage(ent, nil, dmgInfo)
		end

		local owner = ent:WardenGetOwner()
		if not owner.IsWorld or Owner:IsWorld() then return false end

		local attacker = dmgInfo:GetAttacker()
		if not Warden.CheckPermission(attacker, ent, Warden.PERMISSION_DAMAGE) then return false end
		if not Warden.CheckPermission(attacker, ent, Warden.PERMISSION_GRAVGUN) then return false end

		return true
	end

	hook.Add("ACF_PreDamageEntity", "ACF_DamagePermissionCore", ACF.Permissions.CanDamage)

	SetGlobalBool("WardenACF", true)
end)