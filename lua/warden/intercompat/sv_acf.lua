hook.Add("PostGamemodeLoaded", "WardenACFCompat", function()
	if not ACF or not ACF.Permissions then return end

	local oldCanDamage = ACF.Permissions.CanDamage
	function ACF.Permissions.CanDamage(ent, _, dmgInfo)
		if not Warden.GetServerBool("override_acf", false) then
			return oldCanDamage(ent, nil, dmgInfo)
		end

		return Warden.CheckPermission(dmgInfo:GetAttacker(), ent, Warden.PERMISSION_DAMAGE)
	end

	SetGlobalBool("WardenACF", true)
end)