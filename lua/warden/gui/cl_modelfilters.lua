local PANEL = {}

local black = Color(30, 30, 30)

function PANEL:Init()
	self.Entry = self:Add("WardenTextEntry")
	self.Entry:Dock(BOTTOM)
	self.Entry:SetPlaceholderText("Add models to block list...")

	function self.Entry.OnEnter(pnl)
		local elems = string.Explode("[,;|]", pnl:GetValue(), true)

		for _, v in ipairs(elems) do
			local entry = string.Trim(v)
			local remove
			if entry:Left(1) == "-" then
				remove = true
				entry = string.TrimLeft(string.sub(entry, 2))
			end

			if remove then
				self:RemoveModel(entry)
			else
				self:AddModel(entry)
			end
		end
	end

	function self.List.PaintOver(pnl, w, h)
		if not table.IsEmpty(self.Models) then return end

		draw.DrawText("no models blocked", "WardenEntBig0", w / 2, h / 2 - 10, black, TEXT_ALIGN_CENTER)
	end

	self.Models = {}

	self:Repopulate()
end

function PANEL:FixList()
	for k, v in pairs(self.Controls) do
		if not IsValid(v) then
			self.Controls[k] = nil
		end
	end

	for k, v in pairs(self.List.Items) do
		if not IsValid(v) then
			self.List.Items[k] = nil
		end
	end
end

function PANEL:RemoveModel(model, dontNet)
	local icon = self.Models[model]
	if not icon then return end

	if not dontNet and Warden.UnblockModel(model) then return end

	if not IsValid(icon) then
		self.Models[model] = nil
		self:FixList()
		return
	end

	self.Models[model] = nil
	icon:Remove()
	self:FixList()

	self:InvalidateLayout()
end

function PANEL:AddModel(model, dontNet)
	if self.Models[model] then return end

	if not dontNet and Warden.BlockModel(model) then return end

	local icon = vgui.Create("SpawnIcon", self)
	icon:SetModel(model)
	icon:SetTooltip(model)
	icon.Model = model
	icon.Value = model

	icon.DoClick = function(button)
		self:OnRightClick(button)
	end
	icon.OpenMenu = function(button)
		self:OnRightClick(button)
	end

	self.List:AddItem(icon)
	table.insert(self.Controls, icon)

	self.Models[model] = icon

	self:InvalidateLayout()

	return icon
end

function PANEL:OnRightClick(button)
	local _menu = DermaMenu()

	_menu:AddOption("#spawnmenu.menu.copy", function()
		SetClipboardText(button.Model)
	end):SetIcon("icon16/page_copy.png")

	_menu:AddOption("Unblock model", function()
		self:RemoveModel(button.Model)
	end):SetIcon("icon16/accept.png")

	_menu:Open()
end

function PANEL:Repopulate()
	for k, _ in pairs(self.Models) do
		if not Warden.ModelFilters[k] then
			self:RemoveModel(k, true)
		end
	end

	for k, _ in pairs(Warden.ModelFilters) do
		self:AddModel(k, true)
	end
end

-- override
function PANEL:PerformLayout(w, h)
	local width = w - self.List:GetPadding() + self.List:GetSpacing()
	local itemWidth = 64 + self.List:GetSpacing()
	self.Height = math.Clamp(math.ceil(table.Count(self.Models) / math.floor(width / itemWidth)), 1, 5)

	local height = itemWidth * math.max(self.Height, 1) + self.List:GetPadding() * 2 - self.List:GetSpacing()
	self.List:SetPos(0, 0)
	self.List:SetSize(self:GetWide(), height)

	self:SetTall(height + 5 + self.Entry:GetTall())
end

vgui.Register("WardenModelFilters", PANEL, "PropSelect")