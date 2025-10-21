hook.Add("AddToolMenuCategories", "Warden", function()
	spawnmenu.AddToolCategory("Utilities", "Warden", "#Warden")
end)

local setPermPnl
local setPermPnlExtra
local checks = {}
local permChecks = {}

local function setPerms(panel)
	permChecks = {}

	panel:Help(Warden.L("Configure prop protection settings."))

	panel:CheckBox(Warden.L("Let me touch others' entities"), "warden_touch")
	panel:CheckBox(Warden.L("Let me touch my own entities"), "warden_touch_self")
	panel:CheckBox(Warden.L("Save my perms across sessions"), "warden_perm_persist")

	hook.Run("WardenPermsHeader", panel, permChecks)

	setPermPnl = vgui.Create("WardenSetPerms")
	panel:AddItem(setPermPnl)

	panel:ControlHelp(Warden.L("Right click to copy name/steamID"))

	panel.Extra = {}

	function panel.AdminExtra()
		local hasCmds = GetGlobalString("WardenCommands") ~= ""

		if panel.Admin.cleanup or panel.Admin.freeze then
			local hint = "cleanup/freeze"
			local cmdHint = "!cleanup/!pfreezeprops"

			if not panel.Admin.cleanup then
				hint = "freeze"
				cmdHint = "!pfreezeprops"
			elseif not panel.Admin.freeze then
				hint = "cleanup"
				cmdHint = "!cleanup"
			end

			local help = panel:ControlHelp(Warden.L("Right click to " .. hint .. " props"))
			table.insert(panel.Extra, help)

			if hasCmds then
				local help1 = panel:ControlHelp(Warden.L("(also try " .. cmdHint .. ")"))
				table.insert(panel.Extra, help1)
			end
		end

		if panel.Admin.cupdis then
			local cupdis = panel:Button(Warden.L("Clean up all disconnected players' props"))
			table.insert(panel.Extra, cupdis)
			function cupdis.DoClick()
				Warden.CleanupDisconnected()
			end

			if hasCmds then
				local helpCupdis = panel:ControlHelp(Warden.L("Can also be done with !cupdis"))
				table.insert(panel.Extra, helpCupdis)
			end
		end

		if not panel.Admin.al then return end

		local al, al1 = panel:NumberWang(Warden.L("Admin level"), nil, Warden.ADMIN_LEVEL_MIN, Warden.ADMIN_LEVEL_MAX, 0)
		panel.AL = al
		table.insert(panel.Extra, al)
		table.insert(panel.Extra, al1)

		al:HideWang()

		function al:PerformLayout()
			self:SetTall(16)
			self:AlignBottom()
		end

		local min, max = al:GetMin(), al:GetMax()

		function al:OnValueChanged(val)
			Warden.RequestAdminLevel(math.Clamp(math.floor(val), min, max))
		end

		if hasCmds then
			local helpAL = panel:ControlHelp(Warden.L("Can also be set with !al"))
			table.insert(panel.Extra, helpAL)
		end
	end

	function panel.Refresh()
		local admin = {
			cleanup = LocalPlayer():WardenGetCmdPerm("warden_cleanup_entities"),
			freeze = LocalPlayer():WardenGetCmdPerm("warden_freeze_entities"),
			cupdis = LocalPlayer():WardenGetCmdPerm("warden_cleanup_disconnected"),
			al = LocalPlayer():WardenGetCmdPerm("warden_admin_level")
		}

		if admin.al and IsValid(panel.AL) then
			panel.AL:SetText(LocalPlayer():WardenGetAdminLevel())
		end

		if panel.Admin then
			local changed
			for k, v in pairs(admin) do
				if panel.Admin[k] ~= v then
					changed = true
					break
				end
			end

			if not changed then return end
		end

		panel.Admin = admin

		for _, v in ipairs(panel.Extra) do
			if IsValid(v) then
				v:Remove()
			end
		end

		panel.Extra = {}
		panel.AdminExtra()
	end

	setPermPnlExtra = panel

	for _, v in ipairs(permChecks) do
		v()
	end

	panel.Refresh()
end

local function entInfo(panel)
	panel:Help(Warden.L("Configure the entity info display."))

	panel:CheckBox(Warden.L("Enabled"), "warden_entinfo_enabled")

	Warden.AddSpacer(panel)

	panel:CheckBox(Warden.L("Show owner"), "warden_entinfo_show_owner")
	panel:CheckBox(Warden.L("Show class"), "warden_entinfo_show_class")
	panel:CheckBox(Warden.L("Show model"), "warden_entinfo_show_model")
	panel:CheckBox(Warden.L("Show material"), "warden_entinfo_show_material")
	panel:CheckBox(Warden.L("Show color"), "warden_entinfo_show_color")
	panel:CheckBox(Warden.L("Show perms"), "warden_entinfo_show_perms")

	Warden.AddSpacer(panel)

	panel:CheckBox(Warden.L("Blur"), "warden_entinfo_blur")

	local combo = panel:ComboBox(Warden.L("Size"), "warden_entinfo_size")
	combo:AddChoice(Warden.L("Auto"), -1)
	combo:AddChoice(Warden.L("Small"), 0)
	combo:AddChoice(Warden.L("Normal"), 1)
	combo:AddChoice(Warden.L("Large"), 2)
end

-- make a serversetting-controlled check
-- if used outside of the settings hooks this will not update
function Warden.SetUpCheck(panel, label, setting)
	local check = panel:CheckBox(Warden.L(label))

	function check:OnChange(val)
		Warden.SetServerSetting(setting, val)
	end

	if not WARDEN_SETTINGS then return check end

	table.insert(checks, function()
		if not IsValid(check) then return end
		check:SetChecked(Warden.GetServerBool(setting))
	end)

	return check
end

-- make a serversetting-controlled wang
-- if used outside of the settings hooks this will not update
function Warden.SetUpWang(panel, label, setting, min, max)
	local numWang = panel:NumberWang(Warden.L(label), nil, min, max, 0)
	numWang:HideWang()

	function numWang:PerformLayout()
		self:SetTall(16)
		self:AlignBottom()
	end

	function numWang:OnValueChanged(val)
		Warden.SetServerSetting(setting, math.Clamp(math.floor(val), min, max))
	end

	if not WARDEN_SETTINGS then return numWang end

	table.insert(checks, function()
		if not IsValid(numWang) then return end
		numWang:SetText(Warden.GetServerSetting(setting))
	end)

	return numWang
end

-- make a serversetting-controlled slider
-- if used outside of the settings hooks this will not update
function Warden.SetUpSlider(panel, label, setting, min, max)
	local slider = panel:NumSlider(Warden.L(label), nil, min, max, 0)

	function slider:OnValueChanged(val)
		timer.Create("WardenUpdating_" .. setting, 0.5, 1, function()
			Warden.SetServerSetting(setting, math.floor(val))
		end)
	end

	if not WARDEN_SETTINGS then return slider end

	table.insert(checks, function()
		if not IsValid(slider) then return end

		local val = Warden.GetServerSetting(setting)
		slider.Scratch:SetFloatValue(val)
		slider.TextArea:SetValue(slider.Scratch:GetTextValue())
		slider.Slider:SetSlideX(slider.Scratch:GetFraction())
		slider:SetCookie("slider_val", val)
	end)

	return slider
end

local classFilterPnl
local modelFilterPnl

local function serverSettings(panel)
	checks = {}
	WARDEN_SETTINGS = true

	panel:Help(Warden.L("Configure the server's entity permissions."))

	panel:SetLabel(Warden.L("Server Settings (superadmins only)"))

	function panel:PaintOver(w, h)
		local headerHeight = self:GetHeaderHeight()

		if headerHeight >= h then return end
		if LocalPlayer():IsSuperAdmin() then return end

		surface.SetDrawColor(255, 0, 0)
		surface.DrawOutlinedRect(0, headerHeight, w, h - headerHeight, 2)
	end

	local permSettingsPnl = vgui.Create("WardenPermSettings")
	panel:AddItem(permSettingsPnl)

	panel:ControlHelp(Warden.L("ON: is the perm enabled?"))
	panel:ControlHelp(Warden.L("DF: is the perm on by default?"))
	panel:ControlHelp(Warden.L("WA: does the world have the perm?"))
	panel:ControlHelp(Warden.L("AL: the admin level to bypass the perm"))

	panel:Help(Warden.L("Configure class filters."))

	Warden.SetUpCheck(panel, "Filters bypass blocked perms", "class_filter_bypass")

	panel:ControlHelp(Warden.L("Shown on list using gold outlines"))
	panel:ControlHelp(Warden.L("Right click to set per-filter"))

	classFilterPnl = vgui.Create("WardenClassFilters")
	panel:AddItem(classFilterPnl)

	panel:ControlHelp(Warden.L("Prefix with `-` to remove class"))
	panel:ControlHelp(Warden.L("Use `,`/`;` to do multiple operations"))
	panel:ControlHelp(Warden.L("Use `+`/`-`/`=` to quick-set columns"))
	panel:ControlHelp(Warden.L("Has basic wildcard support (`*`)"))

	panel:Help(Warden.L("Block models from being spawned."))

	Warden.SetUpCheck(panel, "Block list is a whitelist", "model_filter_whitelist")

	modelFilterPnl = vgui.Create("WardenModelFilters")
	panel:AddItem(modelFilterPnl)

	panel:ControlHelp(Warden.L("Prefix with `-` to remove model"))
	panel:ControlHelp(Warden.L("Use `,`/`;` to do multiple operations"))

	table.insert(checks, function()
		if IsValid(permSettingsPnl) then
			permSettingsPnl:Repopulate()
		end

		if IsValid(modelFilterPnl) then
			modelFilterPnl:Repopulate()
		end

		if IsValid(classFilterPnl) then
			classFilterPnl:Repopulate()
		end
	end)

	panel:Help(Warden.L("Configure general server settings."))

	Warden.SetUpCheck(panel, "Players can always affect bots", "always_target_bots")
	Warden.SetUpCheck(panel, "Allow gravgun punting", "gravgun_punt")
	Warden.SetUpCheck(panel, "Allow physgun reload", "physgun_reload")
	Warden.SetUpCheck(panel, "Allow physics damage", "phy_damage")
	Warden.SetUpCheck(panel, "Burning players take damage", "fire_damage")

	hook.Run("WardenSettingsPlayers", panel, checks)

	Warden.AddSpacer(panel)

	Warden.SetUpCheck(panel, "Freeze players' entities on disconnect", "freeze_disconnect")
	Warden.SetUpCheck(panel, "Clean up players' entities on disconnect", "cleanup_disconnect")
	Warden.SetUpCheck(panel, "Notify the server on cleanup", "cleanup_notify")

	Warden.SetUpSlider(panel, "Clean up time", "cleanup_time", 0, 1000)

	Warden.AddSpacer(panel)

	Warden.SetUpCheck(panel, "Admin level needs admin", "admin_level_needs_admin")

	Warden.SetUpWang(panel, "Default admin level", "default_admin_level", Warden.ADMIN_LEVEL_MIN, Warden.ADMIN_LEVEL_MAX)
	Warden.SetUpWang(panel, "AL to bypass filters", "admin_level_filter_bypass", Warden.ADMIN_LEVEL_MIN_1, Warden.ADMIN_LEVEL_MAX)

	hook.Run("WardenSettingsExtra", panel, checks)

	Warden.AddSpacer(panel)

	Warden.Confirmer(panel, "Reset server settings", "reset server settings", function()
		Warden.ClearSettings(Warden.ADMIN_NET.CLEAR_SETTINGS)
	end)
	Warden.Confirmer(panel, "Clear class filters", "clear class filters", function()
		Warden.ClearSettings(Warden.ADMIN_NET.CLEAR_CLASSES)
	end)
	Warden.Confirmer(panel, "Clear blocked models", "clear blocked models", function()
		Warden.ClearSettings(Warden.ADMIN_NET.CLEAR_MODELS)
	end)

	WARDEN_SETTINGS = nil

	for _, v in ipairs(checks) do
		v()
	end
end

hook.Add("PopulateToolMenu", "Warden", function()
	spawnmenu.AddToolMenuOption("Utilities", "Warden", "warden_setperms", Warden.L("Prop Protection"), "", "", setPerms)
	spawnmenu.AddToolMenuOption("Utilities", "Warden", "warden_entinfo", Warden.L("Entity Info"), "", "", entInfo)
	spawnmenu.AddToolMenuOption("Utilities", "Warden", "warden_serversettings", Warden.L("Server Settings"), "", "", serverSettings)
end)

hook.Add("SpawnMenuOpened", "Warden", function()
	if IsValid(setPermPnl) then
		setPermPnl:Repopulate()
	end

	if IsValid(setPermPnlExtra) then
		setPermPnlExtra.Refresh()
	end

	for _, v in ipairs(checks) do
		v()
	end

	for _, v in ipairs(permChecks) do
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

local function modelFilter(mdl, add)
	if Warden.GetServerBool("model_filter_whitelist", false) then
		add = not add
	end

	if add then
		if IsValid(modelFilterPnl) then
			modelFilterPnl:AddModel(mdl)
		else
			Warden.BlockModel(mdl)
		end
	else
		if IsValid(modelFilterPnl) then
			modelFilterPnl:RemoveModel(mdl)
		else
			Warden.UnblockModel(mdl)
		end
	end
end

local function overrideModelCType(container, obj)
	local icon = Warden.OldModelCType(container, obj)
	if not icon then return end

	local mdl = string.gsub(obj.model, "\\", "/")

	-- the functions to detect what class a model
	-- belongs to are unreliable clientside
	Warden.CrossBlock(icon, mdl, "prop_*")

	-- override
	function icon.OpenMenu(pnl)
		if pnl:GetParent() and pnl:GetParent().ContentContainer then
			container = pnl:GetParent().ContentContainer
		end

		local _menu = DermaMenu()
		_menu:AddOption("#spawnmenu.menu.copy", function()
			SetClipboardText(mdl)
		end):SetIcon("icon16/page_copy.png")

		_menu:AddOption("#spawnmenu.menu.spawn_with_toolgun", function()
			RunConsoleCommand("gmod_tool", "creator")
			RunConsoleCommand("creator_type", "4")
			RunConsoleCommand("creator_name", obj.model)
		end):SetIcon("icon16/brick_add.png")

		-- warden additions

		if LocalPlayer():IsSuperAdmin() then
			if Warden.IsModelBlocked(mdl) then
				_menu:AddOption(Warden.L("(Warden) Unblock model"), function()
					modelFilter(mdl, false)
				end):SetIcon("icon16/accept.png")
			else
				_menu:AddOption(Warden.L("(Warden) Block model"), function()
					modelFilter(mdl, true)
				end):SetIcon("icon16/delete.png")
			end
		end

		-- end warden additions

		local submenu, submenu_opt = _menu:AddSubMenu("#spawnmenu.menu.rerender", function()
			if IsValid(pnl) then pnl:RebuildSpawnIcon() end
		end)
		submenu_opt:SetIcon("icon16/picture_save.png")

		submenu:AddOption("#spawnmenu.menu.rerender_this", function()
			if IsValid(pnl) then pnl:RebuildSpawnIcon() end
		end):SetIcon("icon16/picture.png")
		submenu:AddOption("#spawnmenu.menu.rerender_all", function()
			if IsValid(container) then container:RebuildAll() end
		end):SetIcon("icon16/pictures.png")

		_menu:AddOption("#spawnmenu.menu.edit_icon", function()
			if not IsValid(pnl) then return end

			local editor = vgui.Create("IconEditor")
			editor:SetIcon(pnl)
			editor:Refresh()
			editor:MakePopup()
			editor:Center()
		end):SetIcon("icon16/pencil.png")

		-- Do not allow removal/size changes from read only panels
		if IsValid(pnl:GetParent()) and pnl:GetParent().GetReadOnly and pnl:GetParent():GetReadOnly() then
			_menu:Open()
			return
		end

		pnl:InternalAddResizeMenu(_menu, function(w, h)
			if not IsValid(pnl) then return end

			pnl:SetSize(w, h)
			pnl:InvalidateLayout(true)
			container:OnModified()
			container:Layout()
			pnl:SetModel(obj.model, obj.skin or 0, obj.body)
		end)

		_menu:AddSpacer()
		_menu:AddOption("#spawnmenu.menu.delete", function()
			if not IsValid(pnl) then return end

			pnl:Remove()
			hook.Run("SpawnlistContentChanged")
		end):SetIcon("icon16/bin_closed.png")

		_menu:Open()
	end

	return icon
end

local function overrideGenericCType(container, obj, func)
	local icon = func(container, obj)
	if not icon then return end

	Warden.CrossBlock(icon, nil, obj.spawnname)

	return icon
end

local cTypes = { "entity", "vehicle", "npc", "weapon" }
local oldCFuncs = {}

local function doOverrides()
	if Warden.OldModelCType then
		spawnmenu.AddContentType("model", overrideModelCType)
	end

	for _, v in ipairs(cTypes) do
		if not oldCFuncs[v] then continue end

		spawnmenu.AddContentType(v, function(container, obj)
			return overrideGenericCType(container, obj, oldCFuncs[v])
		end)
	end
end

if WARDEN_LOADED then
	doOverrides()
end

hook.Add("PostGamemodeLoaded", "WardenSpawnmenu", function()
	Warden.OldModelCType = spawnmenu.GetContentType("model")

	for _, v in ipairs(cTypes) do
		oldCFuncs[v] = spawnmenu.GetContentType(v)
	end

	doOverrides()
end)