local PANEL = {}

function PANEL:Init()
	self:SetMultiSelect(false)

	self.PermList = {}

	self:MakeColumns()
	self:Repopulate()

	self:SortByColumn(1)
end

function PANEL:MakeColumns()
	self:AddColumn(Warden.L("permission"), 1)
	self:NewSettingCol("ON", "enabled")
	self:NewSettingCol("DF", "default")
	self:NewSettingCol("WA", "world access")
	self:NewSettingCol("AL", "admin level")
end

function PANEL:NewCheck(line, num)
	local check = vgui.Create("Panel")
	check.box = check:Add("DCheckBox")

	function check.box.PerformLayout()
		check.box:Center()
	end

	check.ApplySchemeSettings = function() end

	line:SetValue(num, check)

	return check
end

function PANEL:SetUpLine(key, perm)
	local line = self:AddLine("      " .. perm:GetName())

	line:SetTooltip(perm:GetName())

	local name = line.Columns[1]
	function name.PaintOver(_, w, h)
		surface.SetMaterial(perm:GetIcon())
		surface.SetDrawColor(255, 255, 255)
		surface.DrawTexturedRect(3, h / 2 - 8, 16, 16)
	end

	line:SetSortValue(1, perm.ID)

	local onCheck = self:NewCheck(line, 2)
	function onCheck.box.OnChange(_, val)
		perm:SetEnabled(val)
		line:SetSortValue(2, val and 1 or 0)
		hook.Call("WardenRepopSetPerms")
	end

	local defCheck = self:NewCheck(line, 3)
	function defCheck.box.OnChange(_, val)
		perm:SetDefault(val)
		line:SetSortValue(3, val and 1 or 0)
		hook.Call("WardenRepopSetPerms")
	end

	local worldCheck = self:NewCheck(line, 4)
	function worldCheck.box.OnChange(_, val)
		line:SetSortValue(4, val and 1 or 0)
		perm:SetWorldAccess(val)
	end

	local adminLevel = vgui.Create("Panel")
	adminLevel.box = adminLevel:Add("DNumberWang")

	adminLevel.box:SetMin(Warden.ADMIN_LEVEL_MIN_1) -- can be 0, but that might cause some user error issues
	adminLevel.box:SetMax(Warden.ADMIN_LEVEL_MAX)
	adminLevel.box:SetDecimals(0)
	adminLevel.box:HideWang()

	function adminLevel.box.OnValueChanged(_, val)
		local newVal = math.Clamp(math.floor(val), Warden.ADMIN_LEVEL_MIN_1, Warden.ADMIN_LEVEL_MAX)
		perm:SetAdminLevel(newVal)
		line:SetSortValue(5, newVal)
	end

	function adminLevel.box.PerformLayout()
		local w, h = adminLevel:GetSize()
		adminLevel.box:SetSize(w - 8, h - 2)

		adminLevel.box:Center()
	end

	adminLevel.ApplySchemeSettings = function() end

	line:SetValue(5, adminLevel)

	function line.FixChecks()
		local on = perm:GetEnabled()
		onCheck.box:SetChecked(on)
		line:SetSortValue(2, on and 1 or 0)

		local def = perm:GetDefault()
		defCheck.box:SetChecked(def)
		line:SetSortValue(3, def and 1 or 0)

		local wa = perm:GetWorldAccess()
		worldCheck.box:SetChecked(wa)
		line:SetSortValue(4, wa and 1 or 0)

		local al = perm:GetAdminLevel()
		adminLevel.box:SetText(al)
		line:SetSortValue(5, al)
	end

	return line
end

function PANEL:Repopulate()
	for k, v in pairs(self.PermList) do
		if not IsValid(v) then
			self.PermList[k] = nil
			continue
		end

		if Warden.GetPermission(k, true) then continue end

		self:RemoveLine(v:GetID())
		self.PermList[k] = nil
	end

	for k, v in pairs(Warden.Permissions) do
		if IsValid(self.PermList[k]) then continue end
		self.PermList[k] = self:SetUpLine(k, v)
	end

	for k, v in pairs(self.PermList) do
		v:FixChecks()
	end

	self:SetTall(math.Clamp(self:GetHeaderHeight() + table.Count(self.PermList) * 17 + 1, 80, 300))
end

vgui.Register("WardenPermSettings", PANEL, "WardenListView")