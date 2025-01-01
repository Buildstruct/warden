local PANEL = {}

function PANEL:Init()
	self:SetTall(200)
	self:SetHeaderHeight(20)

	self.PermList = {}

	self:MakeColumns()
	self:Repopulate()
end

function PANEL:NewCol(name, desc)
	local col = self:AddColumn(name)

	col:SetTooltip(desc)
	col:SetTooltipDelay(0)
	col:SetFixedWidth(40)

	return col
end

function PANEL:MakeColumns()
	self:AddColumn("permission", 1)
	self:NewCol("ON", "enabled")
	self:NewCol("WA", "world access")
	self:NewCol("AL", "admin level")
end

function PANEL:SetUpLine(key, perm)
	local line = self:AddLine("      " .. perm:GetName())

	local name = line.Columns[1]
	function name.PaintOver(_, w, h)
		surface.SetMaterial(perm:GetIcon())
		surface.SetDrawColor(255, 255, 255)
		surface.DrawTexturedRect(3, h / 2 - 8, 16, 16)
	end

	local onCheck = vgui.Create("Panel")
	onCheck.box = onCheck:Add("DCheckBox")

	function onCheck.box.OnChange(_, val)
		perm:SetEnabled(val)
	end

	function onCheck.box.PerformLayout()
		onCheck.box:Center()
	end

	onCheck.ApplySchemeSettings = function() end

	line:SetValue(2, onCheck)

	local worldCheck = vgui.Create("Panel")
	worldCheck.box = worldCheck:Add("DCheckBox")

	function worldCheck.box.OnChange(_, val)
		perm:SetWorldAccess(val)
	end

	function worldCheck.box.PerformLayout()
		worldCheck.box:Center()
	end

	worldCheck.ApplySchemeSettings = function() end

	line:SetValue(3, worldCheck)

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

	line:SetValue(4, adminLevel)

	function line.FixChecks()
		onCheck.box:SetChecked(perm:GetEnabled())
		worldCheck.box:SetChecked(perm:GetWorldAccess())
		adminLevel.box:SetText(perm:GetAdminLevel())
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
end

-- override
function PANEL:FixColumnsLayout()
	local numCols = table.Count(self.Columns)
	if numCols < 1 then return end

	local totalWidth = 0
	for k, col in pairs(self.Columns) do
		if k == 1 then continue end

		totalWidth = totalWidth + math.ceil(col:GetWide())
	end

	local nameCol = self.Columns[1]
	if nameCol then
		nameCol:SetWidth(self.pnlCanvas:GetWide() - totalWidth)
	end

	local x = 0
	for k, col in pairs(self.Columns) do
		col.x = x
		x = x + math.ceil(col:GetWide())

		col:SetTall(math.ceil(self:GetHeaderHeight()))
		col:SetVisible(not self:GetHideHeaders())
	end
end

vgui.Register("WardenPermSettings", PANEL, "DListView")