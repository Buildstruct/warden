local PANEL = {}

-- sets text entry up to work command-line style
function Warden.NoLoseFocus(panel)
	panel:SetHistoryEnabled(true)

	function panel:OnKeyCodeTyped(code)
		self:OnKeyCode(code)

		if code == KEY_ENTER and not self:IsMultiline() and self:GetEnterAllowed() then
			if IsValid(self.Menu) then
				self.Menu:Remove()
			end

			local text = self:GetText()

			local dontExit = true
			if string.Trim(text) == "" then
				self:FocusNext()
				dontExit = nil
			else
				self:OnEnter(text)
				self:AddHistory(text)
			end

			self:SetText("")

			self.HistoryPos = 0

			return dontExit
		end

		if self.m_bHistory or IsValid(self.Menu) then
			if code == KEY_UP then
				self.HistoryPos = self.HistoryPos - 1
				self:UpdateFromHistory()
			end
			if code == KEY_DOWN or code == KEY_TAB then
				self.HistoryPos = self.HistoryPos + 1
				self:UpdateFromHistory()
			end
		end
	end
end

function PANEL:Init()
	self:SetMultiSelect(false)

	self.PermList = {}
	self.ClassList = {}

	self:AddColumn("class", 1)

	local col = self:NewSettingCol("SP", "allow spawning")
	col.KEY = "_allow"
	self.blockCol = col:GetColumnID()

	self:Repopulate()
end

function PANEL:RemoveClass(class, dontNet)
	local line = self.ClassList[class]
	if not line then return end

	if not dontNet and Warden.UpdateClassFilter(class) then return end

	self:RemoveLine(line:GetID())
	self.ClassList[class] = nil

	if not dontNet then
		self:SetTall(math.Clamp(self:GetHeaderHeight() + table.Count(self.ClassList) * 17 + 1, 80, 300))
		self:InvalidateParent(true)
	end
end

function PANEL:AddClass(class, filter, dontNet)
	if not filter then
		if self.ClassList[class] then return end
		if not dontNet and Warden.UpdateClassFilter(class) then return end
	else
		if not dontNet and Warden.UpdateClassFilter(class, filter) then return end
		if self.ClassList[class] then
			self.ClassList[class]:FixChecks(filter)
			return
		end
	end

	local line = self:AddLine(class)
	self.ClassList[class] = line
	line.CLASS = class

	line:SetTooltip(class)

	for _, v in pairs(self.PermList) do
		self:PermCheck(line, class, v.KEY, v:GetColumnID())
	end

	self:PermCheck(line, class, "_allow", self.blockCol)

	function line.FixChecks(_, filter1)
		filter1 = filter1 or Warden.GetClassFilter(class, nil, true)

		for k, v in pairs(self.Columns) do
			if k == 1 then continue end

			local check1 = line:GetValue(k)
			if not IsValid(check1) or not IsValid(check1.box) then continue end

			local sort = 0
			if check1.box:GetChecked() then
				sort = 1
			elseif check1.box:GetChecked() == false then
				sort = -1
			end

			check1.box.m_bChecked = filter1[check1.KEY]
			line:SetSortValue(k, sort)
		end
	end

	if filter then
		line:FixChecks(filter)
	end

	if not dontNet then
		self:SetTall(math.Clamp(self:GetHeaderHeight() + table.Count(self.ClassList) * 17 + 1, 80, 300))
		self:InvalidateParent(true)
	end
end

function PANEL:Repopulate()
	self._Perms = Warden.Permissions
	local changed = self:SetPermColumns(true)

	if changed then
		for k, v in pairs(self.ClassList) do
			if not IsValid(v) then continue end
			self:RemoveLine(v:GetID())
		end

		self.ClassList = {}
	else
		for k, v in pairs(self.ClassList) do
			if not IsValid(v) then
				self.ClassList[k] = nil
				continue
			end

			if Warden.ClassFilters[k] then continue end

			self:RemoveClass(k, true)
		end
	end

	for k, v in pairs(Warden.ClassFilters) do
		if IsValid(self.ClassList[k]) then continue end

		self:AddClass(k, v, true)
	end

	for k, v in pairs(self.ClassList) do
		v:FixChecks()
	end

	self:SetTall(math.Clamp(self:GetHeaderHeight() + table.Count(self.ClassList) * 17 + 1, 80, 300))
	self:InvalidateParent(true)
end

local cross = Material("icon16/cross.png")

function PANEL:PermCheck(line, class, perm, colID)
	local check = vgui.Create("Panel")
	check.box = check:Add("DCheckBox")
	check.KEY = perm

	check.ApplySchemeSettings = function() end

	line:SetValue(colID, check)

	function check.box.OnChange(_, val)
		Warden.UpdateClassFilter(class, perm, val)

		local sort = 0
		if val then
			sort = 1
		elseif val == false then
			sort = -1
		end

		line:SetSortValue(colID, sort)
	end

	function check.box.PerformLayout(pnl, val)
		pnl:Center()
	end

	function check.box.SetValue(pnl, val)
		pnl.m_bChecked = val
		pnl.m_bValue = val
		pnl:OnChange(val)
		pnl:SetCookie("checked", val)
	end

	function check.box.Toggle()
		local val = check.box:GetChecked()

		if val then
			val = nil
		elseif val == false then
			val = true
		else
			val = false
		end

		check.box:SetValue(val)
	end

	function check.box.PaintOver(_, w, h)
		if check.box:GetChecked() ~= false then return end

		surface.SetDrawColor(255, 255, 255)
		surface.DrawRect(1, 1, w - 2, h - 2)

		surface.SetMaterial(cross)
		surface.DrawTexturedRect(1, 1, w - 2, h - 2)
	end
end

function PANEL:GetFilterElems()
	local elems = {}
	for k, v in pairs(self.Columns) do
		if k == 1 then continue end

		table.insert(elems, v.KEY)
	end

	return elems
end

function PANEL:OnRowRightClick(_, line)
	local _menu = DermaMenu()

	_menu:AddOption("#spawnmenu.menu.copy", function()
		SetClipboardText(line.CLASS)
	end):SetIcon("icon16/page_copy.png")

	_menu:AddOption("Remove filter", function()
		self:RemoveClass(line.CLASS)
	end):SetIcon("icon16/delete.png")

	_menu:Open()
end

Warden.AddDListElems(PANEL)

vgui.Register("WardenClassFiltersList", PANEL, "DListView")

local PANEL1 = {}

local black = Color(30, 30, 30)

function PANEL1:Init()
	self.Entry = self:Add("DTextEntry")
	self.Entry:Dock(BOTTOM)
	self.Entry:SetPlaceholderText("Add classes to filter list...")

	Warden.NoLoseFocus(self.Entry)

	function self.Entry.OnEnter(pnl)
		local elems = string.Explode("[,;|]", pnl:GetValue(), true)

		for _, v in ipairs(elems) do
			local entry = string.Trim(v)
			local left = entry:Left(1)

			local remove
			if left == "-" then
				remove = true
				entry = string.TrimLeft(string.sub(entry, 2))
			end

			local expl = string.Explode(" ", entry)
			local class = expl[1]
			local filterOps = table.concat(expl, "", 2)

			local filter
			if filterOps then
				filter = Warden.GetClassFilter(class, nil, true)
				for k, v1 in ipairs(self.List:GetFilterElems()) do
					local char = string.sub(filterOps, k, k)

					if char == "-" then
						filter[v1] = false
					elseif char == "+" then
						filter[v1] = true
					elseif char == "=" then
						filter[v1] = nil
					end
				end
			end

			if remove then
				self:RemoveClass(class)
			else
				self:AddClass(class, filter)
			end
		end
	end

	self.List = self:Add("WardenClassFiltersList")
	self.List:Dock(TOP)

	function self.List.PaintOver(pnl, w, h)
		if not table.IsEmpty(pnl.ClassList) then return end

		local h1 = pnl:GetHeaderHeight()
		draw.DrawText("no classes filtered", "WardenEntBig0", w / 2, (h - h1) / 2 - 10 + h1, black, TEXT_ALIGN_CENTER)
	end
end

function PANEL1:PerformLayout()
	if not IsValid(self.List) then return end

	self:SetTall(self.List:GetTall() + self.Entry:GetTall() + 5)
end

function PANEL1:RemoveClass(class, dontNet)
	self.List:RemoveClass(class, dontNet)
end

function PANEL1:AddClass(class, dontNet)
	self.List:AddClass(class, dontNet)
end

function PANEL1:Repopulate()
	self.List:Repopulate()
end

vgui.Register("WardenClassFilters", PANEL1, "Panel")