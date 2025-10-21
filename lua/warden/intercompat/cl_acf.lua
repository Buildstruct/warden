CreateClientConVar("warden_acf_squishy_damage", "-1", true, true, "Whether ACF should treat all your entities as squishy when inflicting damage", -1, 1)

hook.Add("WardenSettingsExtra", "WardenACF", function(panel)
	if not GetGlobalBool("WardenACF", false) then return end

	Warden.AddSpacer(panel)
	Warden.SetUpCheck(panel, "ACF-squishy by default", "acf_default_squishy_damage")
	Warden.SetUpCheck(panel, "Override ACF's perms", "override_acf")
end)

hook.Add("WardenPermsHeader", "WardenACF", function(panel)
	if not GetGlobalBool("WardenACF", false) then return end

	panel:CheckBox(Warden.L("Make my entities ACF-squishy"), "warden_acf_squishy_damage")
end)
