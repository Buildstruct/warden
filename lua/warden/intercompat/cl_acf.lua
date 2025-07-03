CreateClientConVar("warden_acf_squishy_damage", "1", true, true, "Whether ACF should treat your entities as squishy when inflicting damage", 0, 1)

hook.Add("WardenSettingsExtra", "WardenACF", function(panel)
	if not GetGlobalBool("WardenACF", false) then return end

	Warden.AddSpacer(panel)
	Warden.SetUpCheck(panel, "Override ACF's perms", "override_acf")
end)

hook.Add("WardenPermsHeader", "WardenACF", function(panel)
	if not GetGlobalBool("WardenACF", false) then return end

	panel:CheckBox(Warden.L("Make my entities ACF-squishy"), "warden_acf_squishy_damage")
end)

--[[
local function paintOverACF(item)
	item.OldCPanelFunction = item.OldCPanelFunction or item.CPanelFunction
	if not item.OldCPanelFunction then return end

	function item.CPanelFunction(panel)
		item.OldCPanelFunction(panel)

		function panel:PaintOver(w, h)
			local headerHeight = self:GetHeaderHeight()

			if headerHeight >= h then return end
			if not Warden.GetServerBool("override_acf", false) then return end

			surface.SetDrawColor(255, 0, 0)
			surface.DrawOutlinedRect(0, headerHeight, w, h - headerHeight, 2)
		end
	end
end

local function acfOverride()
	local toolMenu = spawnmenu.GetToolMenu("Utilities")
	for _, v in ipairs(toolMenu) do
		if v.ItemName ~= "ACF" then continue end

		for _, v1 in ipairs(v) do
			paintOverACF(v1)
		end
	end
end

hook.Add("PopulateToolMenu", "WardenACF", function()
	timer.Simple(0, function()
		if GetGlobalBool("WardenACF", false) then
			acfOverride()
		end
	end)
end)
--]]