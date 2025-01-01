hook.Add("AddToolMenuCategories", "Warden", function()
	spawnmenu.AddToolCategory("Utilities", "Warden", "#Warden")
end)

local setPermPnl
local permSettingsPnl

local function addSpacer(panel)
	local spacer = vgui.Create("Panel")
	spacer:SetTall(1)
	panel:AddItem(spacer)
end

local function setPerms(panel)
	panel:Help("Configure prop protection from other players.")

	setPermPnl = vgui.Create("WardenSetPerms")
	panel:AddItem(setPermPnl)
end

local function entInfo(panel)
	panel:Help("Configure the entity info display.")

	panel:CheckBox("Enabled", "warden_entinfo_enabled")

	addSpacer(panel)

	panel:CheckBox("Show Owner", "warden_entinfo_show_owner")
	panel:CheckBox("Show Class", "warden_entinfo_show_class")
	panel:CheckBox("Show Model", "warden_entinfo_show_model")
	panel:CheckBox("Show Material", "warden_entinfo_show_material")
	panel:CheckBox("Show Color", "warden_entinfo_show_color")
	panel:CheckBox("Show Permissions", "warden_entinfo_show_perms")

	addSpacer(panel)

	panel:CheckBox("Blur", "warden_entinfo_blur")

	local combo = panel:ComboBox("Size", "warden_entinfo_size")
	combo:AddChoice("Auto", -1)
	combo:AddChoice("Small", 0)
	combo:AddChoice("Normal", 1)
	combo:AddChoice("Large", 2)
end

local function serverSettings(panel)
	panel:Help("Configure the server's settings.")

	permSettingsPnl = vgui.Create("WardenPermSettings")
	panel:AddItem(permSettingsPnl)
end

hook.Add("PopulateToolMenu", "Warden", function()
	spawnmenu.AddToolMenuOption("Utilities", "Warden", "warden_setperms", "#Prop Protection", "", "", setPerms)
	spawnmenu.AddToolMenuOption("Utilities", "Warden", "warden_entinfo", "#Entity Info", "", "", entInfo)
	spawnmenu.AddToolMenuOption("Utilities", "Warden", "warden_serversettings", "#Server Settings", "", "", serverSettings)
end)

hook.Add("SpawnMenuOpened", "Warden", function()
	if IsValid(setPermPnl) then
		setPermPnl:Repopulate()
	end

	if IsValid(permSettingsPnl) then
		permSettingsPnl:Repopulate()
	end
end)

hook.Add("WardenRepopSetPerms", "Warden", function()
	timer.Create("WardenRepopSetPerms", 1, 1, function()
		if IsValid(setPermPnl) then
			setPermPnl:Repopulate()
		end
	end)
end)