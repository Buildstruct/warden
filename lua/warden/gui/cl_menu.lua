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

	panel:CheckBox("Let me touch my own entities", "warden_touch_self")
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

local checks = {}

local function setUpCheck(check, setting)
	table.insert(checks, function()
		if not IsValid(check) then return end
		check:SetChecked(Warden.GetServerBool(setting))
	end)

	function check:OnChange(val)
		Warden.SetServerSetting(setting, val)
	end
end

local function serverSettings(panel)
	panel:Help("Configure the server's settings.")

	permSettingsPnl = vgui.Create("WardenPermSettings")
	panel:AddItem(permSettingsPnl)

	checks = {}

	setUpCheck(panel:CheckBox("Players can always affect bots"), "always_target_bots")

	addSpacer(panel)

	setUpCheck(panel:CheckBox("Freeze players' entities on disconnect"), "freeze_disconnect")
	setUpCheck(panel:CheckBox("Clean up players' entities on disconnect"), "cleanup_disconnect")

	local slider = panel:NumSlider("Entity cleanup time", nil, 0, 1000, 0)
	slider:SetDefaultValue(Warden.GetDefaultServerSetting("cleanup_time"))

	table.insert(checks, function()
		if not IsValid(slider) then return end

		local val = Warden.GetServerSetting("cleanup_time")
		slider.Scratch:SetFloatValue(val)
		slider.TextArea:SetValue(slider.Scratch:GetTextValue())
		slider.Slider:SetSlideX(slider.Scratch:GetFraction())
		slider:SetCookie("slider_val", val)
	end)

	function slider:OnValueChanged(val)
		timer.Create("WardenUpdatingCleanup", 0.5, 1, function()
			Warden.SetServerSetting("cleanup_time", math.floor(val))
		end)
	end

	addSpacer(panel)

	setUpCheck(panel:CheckBox("Admin level needs admin"), "admin_level_needs_admin")

	local numWang = panel:NumberWang("Default admin level", nil, 0, 99, 0)
	numWang:HideWang()

	table.insert(checks, function()
		if not IsValid(numWang) then return end
		numWang:SetText(Warden.GetServerSetting("default_admin_level"))
	end)

	function numWang:OnValueChanged(val)
		Warden.SetServerSetting("default_admin_level", math.Clamp(val, 0, 99))
	end

	for _, v in ipairs(checks) do
		v()
	end
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

	for _, v in ipairs(checks) do
		v()
	end
end)

hook.Add("WardenRepopSetPerms", "Warden", function()
	timer.Create("WardenRepopSetPerms", 1, 1, function()
		if IsValid(setPermPnl) then
			setPermPnl:Repopulate()
		end
	end)
end)