local enabled = CreateClientConVar("warden_entinfo_enabled", "1", true, false, "Show the entity information HUD element", 0, 1)
local showOwner = CreateClientConVar("warden_entinfo_show_owner", "1", true, false, "Show the owner of the entity you're aiming at", 0, 1)
local showClass = CreateClientConVar("warden_entinfo_show_class", "1", true, false, "Show the entity class of the entity you're aiming at", 0, 1)
local showModel = CreateClientConVar("warden_entinfo_show_model", "1", true, false, "Show the model path of the entity you're aiming at", 0, 1)
local showMaterial = CreateClientConVar("warden_entinfo_show_material", "0", true, false, "Show the material path of the entity you're aiming at", 0, 1)
local showColor = CreateClientConVar("warden_entinfo_show_color", "0", true, false, "Show the color of the entity you're aiming at", 0, 1)
local showPerms = CreateClientConVar("warden_entinfo_show_perms", "1", true, false, "Show the permissions you have with the entity you're aiming at", 0, 1)
local fontSize = CreateClientConVar("warden_entinfo_size", "-1", true, false, "Change the size of the entinfo ui (-1 = auto)", -1, 2)
local doBlur = CreateClientConVar("warden_entinfo_blur", "1", true, false, "Whether to blur the background of the entinfo panel", 0, 1)

surface.CreateFont("WardenEntBig2", {
	font = "Arial",
	size = 35,
})

surface.CreateFont("WardenEnt2", {
	font = "Arial",
	italic = true,
	size = 28,
})

surface.CreateFont("WardenEntBig1", {
	font = "Arial",
	size = 27,
})

surface.CreateFont("WardenEnt1", {
	font = "Arial",
	italic = true,
	size = 22,
})

surface.CreateFont("WardenEntBig0", {
	font = "Arial",
	size = 20,
})

surface.CreateFont("WardenEnt0", {
	font = "Arial",
	italic = true,
	size = 16,
})

local PANEL = {}

function PANEL:Init()
	self:SetAlpha(0)

	self.Width, self.Height = 174, 30

	self:SetSize(self.Width, self.Height)
end

function PANEL:DetermineFontSize()
	local size = fontSize:GetInt()

	if size >= 0 then
		self.FontSize = size
		return
	end

	if ScrW() > 3200 then
		self.FontSize = 2
	elseif ScrW() > 2200 then
		self.FontSize = 1
	else
		self.FontSize = 0
	end
end

function PANEL:GetFont(big)
	return string.format("WardenEnt%s%s", big and "Big" or "", self.FontSize or 0)
end

function PANEL:PerformLayout(w, h)
	self:SetPos(ScrW() - w, ScrH() / 2 - h / 2 - 40)
end

function PANEL:SetEntity(ent)
	self.Entity = ent
end

function PANEL:Reveal(goOut)
	if goOut then
		if self.Out then
			return
		end

		self:Stop()
		self:AlphaTo(255, 0.1)
		self.Out = true

		return
	end

	if not self.Out then
		return
	end

	self:Stop()
	self:AlphaTo(0, 0.25)
	self.Out = nil
end

function PANEL:DrawParsed(right, parsed, plus)
	plus = plus or 0
	local x, y = parsed:Size()
	self.ThisWidth, self.ThisHeight = math.max(self.ThisWidth, x + 8 + plus), self.ThisHeight + y

	parsed:Draw(right - 4, self.ItemY, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

	self.ItemY = self.ItemY + parsed:GetHeight()
end

function PANEL:ShowOwner(w)
	if not showOwner:GetBool() then
		return
	end

	local ownerName = self.Entity:GetNWString("Owner")
	local r, g, b = 255, 255, 255

	local ownerID = self.Entity:GetNWString("OwnerID")
	if ownerID == "World" then
		ownerName = "[[WORLD]]"
		r, g, b = 255, 128, 255
	elseif not ownerID or ownerID == "" then
		ownerName = "[[NONE]]"
		r, g, b = 255, 192, 128
	end

	local parsed = markup.Parse(string.format("<font=%s><color=192,192,192>owner: </color><color=%s,%s,%s>%s</color></font>", self:GetFont(true), r, g, b, ownerName))
	self:DrawParsed(w, parsed)
end

function PANEL:ShowClass(w)
	if not showClass:GetBool() then
		return
	end

	local parsed = markup.Parse(string.format("<font=%s><color=192,192,192>class: </color>%s (%s)</font>", self:GetFont(), self.Entity:GetClass(), self.Entity:EntIndex()))
	self:DrawParsed(w, parsed)
end

function PANEL:ShowModel(w)
	if not showModel:GetBool() then
		return
	end

	local parsed = markup.Parse(string.format("<font=%s><color=192,192,192>model: </color>%s</font>", self:GetFont(), self.Entity:GetModel()))
	self:DrawParsed(w, parsed)
end

function PANEL:ShowMaterial(w)
	if not showMaterial:GetBool() then
		return
	end

	local mat = self.Entity:GetMaterial()
	if not mat or mat == "" then
		mat = self.Entity:GetMaterials()[1]
	end
	if not mat or mat == "" then
		return
	end

	local parsed = markup.Parse(string.format("<font=%s><color=192,192,192>material: </color>%s</font>", self:GetFont(), mat))
	self:DrawParsed(w, parsed)
end

function PANEL:ShowColor(w)
	if not showColor:GetBool() then
		return
	end

	local col = self.Entity:GetColor()
	if col == color_white then
		return
	end

	local r, g, b, a = col:Unpack()

	local parsed = markup.Parse(string.format("<font=%s><color=192,192,192>color: </color><color=%s,%s,%s>●</color> [<color=255,128,128>%s</color>, <color=128,255,128>%s</color>, <color=128,128,255>%s</color>, %s]</font>", self:GetFont(), r, g, b, r, g, b, a))
	self:DrawParsed(w, parsed)
end

function PANEL:ShowPerms(w)
	if not showPerms:GetBool() then
		return
	end

	local plus = 0
	local shift = (self.FontSize or 0) * 3
	surface.SetDrawColor(255, 255, 255)
	for k, v in ipairs(Warden.PermissionList) do
		if k == Warden.PERMISSION_ALL then
			continue
		end
		if not Warden.CheckPermission(LocalPlayer(), self.Entity, k) then
			continue
		end

		surface.SetMaterial(v.icon)
		surface.DrawTexturedRect(w - plus - 22, self.ItemY + shift, 16, 16)
		plus = plus + 20
	end

	if plus == 0 then
		return
	end

	local parsed = markup.Parse(string.format("<font=%s><color=192,192,192>perms: </color></font>", self:GetFont()))
	self:DrawParsed(w - plus, parsed, plus)
end

function PANEL:SetEntColor()
	local owner = Warden.GetOwner(self.Entity)

	if not IsValid(owner) then
		surface.SetDrawColor(0, 0, 0, 0)
		return
	end

	local r, g, b = team.GetColor(owner:Team()):Unpack()
	surface.SetDrawColor(r, g, b)
end

function PANEL:Paint(w, h)
	self:Blur()
	self:DetermineFontSize()

	surface.SetDrawColor(0, 0, 0, 200)
	surface.DrawRect(0, 0, w, h)

	if not IsValid(self.Entity) then
		surface.SetDrawColor(team.GetColor(LocalPlayer():Team()))
		surface.DrawRect(0, h - 3, w, h)

		return
	end

	self:SetEntColor()
	surface.DrawRect(0, h - 3, w, h)

	self.ThisWidth, self.ThisHeight = 8, 8
	self.ItemY = 4

	self:ShowOwner(w)
	self:ShowClass(w)
	self:ShowModel(w)
	self:ShowMaterial(w)
	self:ShowColor(w)
	self:ShowPerms(w)

	if self.ThisWidth ~= self.Width or self.ThisHeight ~= self.Height then
		self:SetSize(self.ThisWidth, self.ThisHeight)
		self.Width, self.Height = self.ThisWidth, self.ThisHeight
	end
end

local blur = Material("pp/blurscreen")
function PANEL:Blur()
	if not doBlur:GetBool() then
		return
	end

	local x, y = self:LocalToScreen(0, 0)

	surface.SetDrawColor(255, 255, 255)
	surface.SetMaterial(blur)

	local clipping = DisableClipping(false)
	for i = 1, 5 do
		blur:SetFloat("$blur", (i / 4) * 4)
		blur:Recompute()

		render.UpdateScreenEffectTexture()
		surface.DrawTexturedRect(-x, -y, ScrW(), ScrH())
	end
	DisableClipping(clipping)
end

vgui.Register("WardenEntityInfo", PANEL, "DPanel")

local function tick()
	if not IsValid(Warden.EntityInfo) then
		return
	end

	if not enabled:GetBool() then
		Warden.EntityInfo:Reveal(false)
		return
	end

	local tr = util.GetPlayerTrace(LocalPlayer())
	tr.mask = MASK_SHOT

	local _trace = util.TraceLine(tr)
	if not _trace.Hit or not IsValid(_trace.Entity) or _trace.Entity:IsPlayer() then
		Warden.EntityInfo:Reveal(false)
		return
	end

	Warden.EntityInfo:Reveal(true)
	Warden.EntityInfo:SetEntity(_trace.Entity)
end

hook.Add("InitPostEntity", "WardenEntityInfo", function()
	Warden.EntityInfo = vgui.Create("WardenEntityInfo")
	hook.Add("Tick", "WardenEntityInfo", tick)
end)

local hideHud = not GetConVar("cl_drawhud"):GetBool()
local cameraOut

local function hideEntInf()
	if not IsValid(Warden.EntityInfo) then
		return
	end

	if hideHud or cameraOut then
		Warden.EntityInfo:Hide()
	else
		Warden.EntityInfo:Show()
	end
end

cvars.AddChangeCallback("cl_drawhud", function(_, _, val)
	hideHud = val == "0"
	hideEntInf()
end, "WardenHideEntInfo")

hook.Add("PlayerSwitchWeapon", "WardenHideEntInfo", function(_, _, newWeapon)
	cameraOut = newWeapon:GetClass() == "gmod_camera"
	hideEntInf()
end)

-- hotload support
if IsValid(Warden.EntityInfo) then
	Warden.EntityInfo:Remove()
	Warden.EntityInfo = vgui.Create("WardenEntityInfo")
	hook.Add("Tick", "WardenEntityInfo", tick)
end