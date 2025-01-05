local PANEL = {}

function PANEL:Init()
	self:SetTall(400)
	self:SetHeaderHeight(20)
	self:SetMultiSelect(false)

	self.PlyList = {}

	self:AddColumn("name", 1)
	self:Repopulate()
end

local cross = Material("icon16/cross.png")

local function checkFuncs(pnl, permID, ply, callback)
	function pnl.OnChange(_, val)
		Warden.PermissionRequest(ply, val, permID)
		if callback then callback(val) end
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
		surface.DrawRect(2, 2, w - 4, h - 4)

		surface.SetMaterial(cross)
		surface.DrawTexturedRect(1, 1, w - 2, h - 2)
	end
end

local darkMagenta = Color(192, 0, 192)
local magenta = Color(255, 192, 255)

function PANEL:MakeGlobalLine()
	local line = self:AddLine("[[GLOBAL]]")
	line.IsGlobal = true

	line:SetSortValue(1, -1)

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
		line:SetSortValue(k, -1)
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
	line.Name = ply:GetName()
	line.SteamID = ply:SteamID()

	line:SetTooltip(line.SteamID)

	for k, v in pairs(self.Columns) do
		if k == 1 then continue end

		local check = vgui.Create("Panel")
		check.box = check:Add("DCheckBox")
		checkFuncs(check.box, v.ID, ply, function(val)
			line:SetSortValue(k, val and 1 or 0)
		end)

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
	local changed = self:SetPermColumns()

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
		if IsValid(self.PlyList[v:UserID()]) then continue end

		local line
		if v == LocalPlayer() then
			line = self:MakeGlobalLine()
		else
			line = self:MakePlyLine(v)
		end

		self.PlyList[v:UserID()] = line
	end

	for k, v in pairs(self.PlyList) do
		v:FixChecks()
	end

	if changed then
		self:SortByColumn(1)
	end
end

-- override
function PANEL:SortByColumn(cID, descending)
	table.sort(self.Sorted, function(a, b)
		local aval = a:GetSortValue(cID) or a:GetColumnText(cID)
		local bval = b:GetSortValue(cID) or b:GetColumnText(cID)

		if aval == -1 then return true end
		if bval == -1 then return false end

		if descending then
			aval, bval = bval, aval
		end

		if isnumber(aval) and isnumber(bval) then return aval < bval end

		return tostring(aval) < tostring(bval)
	end)

	self:SetDirty(true)
	self:InvalidateLayout()
end

function PANEL:OnRowRightClick(_, line)
	if line.IsGlobal then return end

	local _menu = DermaMenu()

	_menu:AddOption("Copy steamID", function()
		SetClipboardText(line.SteamID)
	end):SetIcon("icon16/page_copy.png")

	_menu:AddOption("Copy name", function()
		self:RemoveClass(line.Name)
	end):SetIcon("icon16/page_copy.png")

	if LocalPlayer():IsAdmin() then
		_menu:AddSpacer()

		local submenu = _menu:AddSubMenu("Admin options...")
		submenu:SetIcon("icon16/user_gray.png")

		submenu:AddOption("Freeze props", function()
			Warden.FreezeEntities(ply)
		end):SetIcon("icon16/anchor.png")

		submenu:AddOption("Clean up props", function()
			Warden.CleanupEntities(ply)
		end):SetIcon("icon16/cross.png")
	end

	_menu:Open()
end

vgui.Register("WardenSetPerms", PANEL, "WardenListView")