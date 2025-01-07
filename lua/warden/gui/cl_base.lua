local PANEL = {}

function PANEL:NewPermCol(id, perm)
	local col = self:AddColumn("")
	self.PermList[id] = col
	col.ID = id
	col.KEY = perm.KEY

	col:SetTooltip(perm:GetName())
	col:SetTooltipDelay(0)
	col:SetFixedWidth(self:GetHeaderHeight())

	function col.Header.PaintOver(_, w, h)
		surface.SetMaterial(perm:GetIcon())
		surface.SetDrawColor(255, 255, 255)
		surface.DrawTexturedRect(w / 2 - 8, h / 2 - 8, 16, 16)
	end
end

function PANEL:NewSettingCol(name, desc, id)
	local col = self:AddColumn(name, id)

	col:SetTooltip(string.lower(Warden.L(desc)))
	col:SetTooltipDelay(0)
	col:SetFixedWidth(30)

	return col
end

function PANEL:SetPermColumns(force)
	self.PermList = self.PermList or {}

	local changed

	for _, v in pairs(self.PermList) do
		if not IsValid(v) then
			changed = true
			break
		end
		if not Warden.GetPermission(v.ID, force) then
			changed = true
			break
		end
	end

	for k, _ in pairs(self._Perms) do
		if not self.PermList[k] then
			changed = true
			break
		end
	end

	if not changed then return false end

	for _, v in pairs(self.PermList) do
		v:Remove()
	end

	self.PermList = {}

	for k, v in pairs(self.Columns) do
		if not IsValid(v) then
			self.Columns[k] = nil
		end
	end

	for k, v in pairs(self._Perms) do
		self:NewPermCol(k, v)
	end

	local c = table.Count(self._Perms)
	local h = self:GetHeaderHeight()
	local width = h + math.max((h / 4) * (6 - c), 0)

	for k, v in pairs(self.PermList) do
		v:SetFixedWidth(width)
	end

	return true
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

		col:SetTall(self:GetHeaderHeight())
		col:SetVisible(not self:GetHideHeaders())
	end
end

vgui.Register("WardenListView", PANEL, "DListView")

local PANEL1 = {}

function PANEL1:Init()
	self:SetHistoryEnabled(true)
end

-- override
function PANEL1:OnKeyCodeTyped(code)
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

vgui.Register("WardenTextEntry", PANEL1, "DTextEntry")

-- add a button to a dform that asks for typed confirmation when pressed
function Warden.Confirmer(panel, label, confirm, callback)
	label = Warden.L(label)
	confirm = string.lower(confirm or "confirm")

	local button = panel:Button(label)

	function button:DoClick()
		button:FocusNext()
		RunConsoleCommand("-menu")

		Derma_StringRequest(label, Warden.L("Please type `%s` to confirm", confirm), "", function(text)
			if string.lower(text) == confirm then
				callback()
				surface.PlaySound("buttons/button5.wav")
			else
				surface.PlaySound("buttons/button10.wav")
			end
		end, nil, Warden.L("Confirm"))
	end
end

-- renders a red cross when the provided model or class is blocked
function Warden.CrossBlock(icon, model, class)
	icon.WardenPaintOver = icon.WardenPaintOver or icon.PaintOver

	function icon.PaintOver(pnl, w, h)
		pnl:WardenPaintOver(w, h)

		if not Warden.IsModelBlocked(model) and not Warden.IsClassBlocked(class) then return end

		local r = math.min(w, h) * 0.5
		local cX, cY = w / 2, h / 2

		local verts = {
			{ x = 0.366, y = 0 },
			{ x = 0.866, y = 0.5 },
			{ x = 0.5, y = 0.866 },
			{ x = 0, y = 0.366 },
			{ x = -0.5, y = 0.866 },
			{ x = -0.866, y = 0.5 },
			{ x = -0.366, y = 0 },
			{ x = -0.866, y = -0.5 },
			{ x = -0.5, y = -0.866 },
			{ x = 0, y = -0.366 },
			{ x = 0.5, y = -0.866 },
			{ x = 0.866, y = -0.5 },
			{ x = 0.366, y = 0 }
		}

		for _, v in ipairs(verts) do
			v.x = v.x * r + cX
			v.y = v.y * r + cY
		end

		surface.SetDrawColor(255, 0, 0, 96)
		draw.NoTexture()
		surface.DrawPoly(verts)
	end
end

-- add spacing to a dform
function Warden.AddSpacer(panel)
	local spacer = vgui.Create("Panel")
	spacer:SetTall(1)
	panel:AddItem(spacer)

	return spacer
end