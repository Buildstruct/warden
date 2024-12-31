hook.Add("AddToolMenuCategories", "Warden", function()
	spawnmenu.AddToolCategory("Utilities", "Warden", "#Warden")
end)

local setPermPnl

local function permSet(panel)
	panel:Help("Configure prop protection from other players.")
	panel:AddItem(vgui.Create("WardenSetPerms"))
end

hook.Add("PopulateToolMenu", "Warden", function()
	spawnmenu.AddToolMenuOption("Utilities", "Warden", "warden_perm_set", "#Prop Protection", "", "", permSet)
end)

hook.Add("SpawnMenuOpened", "Warden", function()
	if IsValid(setPermPnl) then
		setPermPnl:Repopulate()
	end
end)