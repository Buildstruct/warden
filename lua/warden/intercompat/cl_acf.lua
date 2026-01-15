local cvarSquishy = CreateClientConVar("warden_acf_squishy_damage", "-1", true, true, "Whether ACF should treat all your entities as squishy when inflicting damage", -1, 1)

hook.Add("WardenSettingsExtra", "WardenACF", function(panel)
	if not GetGlobalBool("WardenACF", false) then return end

	Warden.AddSpacer(panel)
	Warden.SetUpCheck(panel, "ACF-squishy by default", "acf_default_squishy_damage")
end)

hook.Add("WardenPermsHeader", "WardenACF", function(panel, checks)
	if not GetGlobalBool("WardenACF", false) then return end

	local check = panel:CheckBox(Warden.L("Make my entities ACF-squishy"))

	function check:OnChange(val)
		cvarSquishy:SetBool(val)
	end

	table.insert(checks, function()
		if not IsValid(check) then return end

		local val = cvarSquishy:GetInt()
		if val < 0 then
			val = Warden.GetServerBool("acf_default_squishy_damage", false)
		else
			val = val ~= 0
		end

		check:SetChecked(val)
	end)
end)
