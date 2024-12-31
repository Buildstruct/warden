local PANEL = {}

function PANEL:Init()
	self:SetTall(500)
	self:SetHeaderHeight(20)

	self.PermList = {}
	self.PlyList = {}

	self:MakeColumns()
	self:Repopulate()
end

function PANEL:NewPermCol(id, perm)
	local col = self:AddColumn("")
	self.PermList[id] = col
	col.ID = id

	col:SetTooltip(perm:GetName())
	col:SetTooltipDelay(0)
	col:SetFixedWidth(20)

	function col.Header.PaintOver(_, w, h)
		surface.SetMaterial(perm:GetIcon())
		surface.SetDrawColor(255, 255, 255)
		surface.DrawTexturedRect(w / 2 - 8, h / 2 - 8, 16, 16)
	end
end

function PANEL:MakeColumns()
	self:AddColumn("name", 1)

	for k, v in pairs(Warden.GetAllPermissions()) do
		self:NewPermCol(k, v)
	end
end

function PANEL:ResetColumns()
	local changed = false

	for k, v in pairs(self.PermList) do
		if not IsValid(v) then
			self.PermList[k] = nil
			changed = true
		elseif not Warden.GetPermission(v.ID) then
			v:Remove()
			self.PermList[k] = nil
			changed = true
		end
	end

	for k, v in pairs(self._Perms) do
		if self.PermList[k] then continue end

		self:NewPermCol(k, v)
		changed = true
	end

	if changed then
		for k, v in pairs(self.Columns) do
			if not IsValid(v) then
				self.Columns[k] = nil
			end
		end
	end

	return changed
end

local function checkFuncs(pnl, permID, ply)
	function pnl.OnChange(_, val)
		Warden.PermissionRequest(ply, val, permID)
	end

	function pnl.PerformLayout(_, val)
		pnl:Center()
	end

	if not ply then return end

	function pnl.PaintOver(_, w, h)
		if not pnl:GetChecked() or not Warden.HasPermissionGlobal(LocalPlayer(), permID) then
			return
		end

		surface.SetDrawColor(255, 255, 255)
		surface.DrawRect(1, 1, w - 2, h - 2)

		surface.SetMaterial(cross)
		surface.DrawTexturedRect(1, 1, w - 2, h - 2)
	end
end

local darkMagenta = Color(192, 0, 192)
local magenta = Color(255, 192, 255)

function PANEL:MakeGlobalLine()
	local line = self:AddLine("[[GLOBAL]]")

	line:SetZPos(1)

	line.Columns[1].ApplySchemeSettings = function()
		if line:IsLineSelected() then
			line.Columns[1]:SetTextColor(magenta)
		else
			line.Columns[1]:SetTextColor(darkMagenta)
		end
	end

	for k, v in pairs(self.Columns) do
		if k == 1 then continue end

		local check = vgui.Create("Panel")
		check.box = check:Add("DCheckBox")
		checkFuncs(check.box, v.ID)

		check.ApplySchemeSettings = function() end

		line:SetValue(k, check)
	end

	function line.FixChecks()
		for k, v in pairs(self.Columns) do
			if k == 1 then continue end

			local check = line:GetValue(k)
			if not IsValid(check) or not IsValid(check.box) then continue end

			check.box:SetChecked(Warden.HasPermissionGlobal(LocalPlayer(), v.ID))
		end
	end

	return line
end

function PANEL:MakePlyLine(ply)
	local line = self:AddLine(ply:GetName())

	for k, v in pairs(self.Columns) do
		if k == 1 then continue end

		local check = vgui.Create("Panel")
		check.box = check:Add("DCheckBox")
		checkFuncs(check.box, v.ID, ply)

		check.ApplySchemeSettings = function() end

		line:SetValue(k, check)
	end

	function line.FixChecks()
		for k, v in pairs(self.Columns) do
			if k == 1 then continue end

			local check = line:GetValue(k)
			if not IsValid(check) or not IsValid(check.box) then continue end

			local on = Warden.HasPermissionLocal(ply, LocalPlayer(), v.ID)
			check.box:SetChecked(on)
			line:SetSortValue(k, on and 1 or 0)
		end
	end

	return line
end

function PANEL:Repopulate()
	self._Perms = Warden.GetAllPermissions()

	local changed = self:ResetColumns()

	if changed then
		for k, v in pairs(self.PlyList) do
			if not IsValid(v) then continue end
			self:RemoveLine(v:GetID())
		end

		self.PlyList = {}
	else
		for k, v in pairs(self.PlyList) do
			if not IsValid(v) then
				self.PlyList[k] = nil
				continue
			end

			if IsValid(Player(k)) then continue end

			self:RemoveLine(v:GetID())
			self.PlyList[k] = nil
		end
	end

	for k, v in player.Iterator() do
		if not IsValid(self.PlyList[v:UserID()]) then
			local line
			if v == LocalPlayer() then
				line = self:MakeGlobalLine()
			else
				line = self:MakePlyLine(v)
			end

			self.PlyList[v:UserID()] = line
		end
	end

	for k, v in pairs(self.PlyList) do
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

vgui.Register("WardenSetPerms", PANEL, "DListView")