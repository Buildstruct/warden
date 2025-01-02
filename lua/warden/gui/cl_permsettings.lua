local PANEL = {}

function PANEL:Init()
	self:SetHeaderHeight(20)
	self:SetMultiSelect(false)

	self.PermList = {}

	self:MakeColumns()
	self:Repopulate()
end

function PANEL:NewCol(name, desc)
	local col = self:AddColumn(name)

	col:SetTooltip(desc)
	col:SetTooltipDelay(0)
	col:SetFixedWidth(30)

	return col
end

function PANEL:MakeColumns()
	self:AddColumn("permission", 1)
	self:NewCol("ON", "enabled")
	self:NewCol("DF", "default")
	self:NewCol("WA", "world access")
	self:NewCol("AL", "admin level")
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

	local name = line.Columns[1]
	function name.PaintOver(_, w, h)
		surface.SetMaterial(perm:GetIcon())
		surface.SetDrawColor(255, 255, 255)
		surface.DrawTexturedRect(3, h / 2 - 8, 16, 16)
	end

	local onCheck = self:NewCheck(line, 2)
	function onCheck.box.OnChange(_, val)
		perm:SetEnabled(val)
		hook.Call("WardenRepopSetPerms")
	end

	local defCheck = self:NewCheck(line, 3)
	function defCheck.box.OnChange(_, val)
		perm:SetDefault(val)
		hook.Call("WardenRepopSetPerms")
	end

	local worldCheck = self:NewCheck(line, 4)
	function worldCheck.box.OnChange(_, val)
		perm:SetWorldAccess(val)
	end

	local adminLevel = vgui.Create("Panel")
	adminLevel.box = adminLevel:Add("DNumberWang")

	adminLevel.box:SetMin(1) -- can be 0, but that might cause some user error issues
	adminLevel.box:SetMax(99)
	adminLevel.box:SetDecimals(0)
	adminLevel.box:HideWang()

	function adminLevel.box.OnValueChanged(_, val)
		perm:SetAdminLevel(math.Clamp(val, 1, 99))
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

	self:SetTall(self:GetHeaderHeight() + table.Count(self.PermList) * 17 + 1)
end

-- override
function PANEL:FixColumnsLayout()
	local numCols = table.Count(self.Columns)
	if numCols < 1 then return end

	local totalWidth = 0
	for k, col in pairs(self.Columns) do
		if k == 1 then continue end

		totalWidth = totalWidth + col:GetWide()
	end

	local nameCol = self.Columns[1]
	if nameCol then
		nameCol:SetWidth(self.pnlCanvas:GetWide() - totalWidth)
	end

	local x = 0
	for k, col in pairs(self.Columns) do
		col.x = x
		x = x + col:GetWide()

		col:SetTall(self:GetHeaderHeight())
		col:SetVisible(not self:GetHideHeaders())
	end
end

vgui.Register("WardenPermSettings", PANEL, "DListView")