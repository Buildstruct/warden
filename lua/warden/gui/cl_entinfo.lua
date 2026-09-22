local enabled = CreateClientConVar("warden_entinfo_enabled", "1", true, false, "Show the entity information HUD element", 0, 1)
local showOwner = CreateClientConVar("warden_entinfo_show_owner", "1", true, false, "Show the owner of the entity you're aiming at", 0, 1)
local showClass = CreateClientConVar("warden_entinfo_show_class", "0", true, false, "Show the entity class of the entity you're aiming at", 0, 1)
local showModel = CreateClientConVar("warden_entinfo_show_model", "0", true, false, "Show the model path of the entity you're aiming at", 0, 1)
local showMaterial = CreateClientConVar("warden_entinfo_show_material", "0", true, false, "Show the material path of the entity you're aiming at", 0, 1)
local showMass = CreateClientConVar("warden_entinfo_show_mass", "0", true, false, "Show the mass of the entity you're aiming at.", 0, 1)
local showColor = CreateClientConVar("warden_entinfo_show_color", "0", true, false, "Show the color of the entity you're aiming at", 0, 1)
local showPerms = CreateClientConVar("warden_entinfo_show_perms", "1", true, false, "Show the permissions you have with the entity you're aiming at", 0, 1)
local showCGroup = CreateClientConVar("warden_entinfo_show_cgroup", "0", true, false, "Show the collision group of the entity you're aiming at", 0, 1)
local fontSize = CreateClientConVar("warden_entinfo_size", "-1", true, false, "Change the size of the entinfo ui (-1 = auto)", -1, 2)
local doBlur = CreateClientConVar("warden_entinfo_blur", "1", true, false, "Whether to blur the background of the entinfo panel", 0, 1)
local doFollowCursor = CreateClientConVar("warden_entinfo_followcursor", "1", true, false, "Whether the entinfo panel follows the cursor in the context menu", 0, 1)

local COLLISION_GROUP_NAMES = {
	[COLLISION_GROUP_NONE] = "none (%d)",
	[COLLISION_GROUP_DEBRIS] = "debris (%d)",
	[COLLISION_GROUP_DEBRIS_TRIGGER] = "debris trigger (%d)",
	[COLLISION_GROUP_INTERACTIVE_DEBRIS] = "interactive debris (%d)",
	[COLLISION_GROUP_INTERACTIVE] = "interactive (%d)",
	[COLLISION_GROUP_PLAYER] = "player (%d)",
	[COLLISION_GROUP_BREAKABLE_GLASS] = "breakable glass (%d)",
	[COLLISION_GROUP_VEHICLE] = "vehicle (%d)",
	[COLLISION_GROUP_PLAYER_MOVEMENT] = "player movement (%d)",
	[COLLISION_GROUP_NPC] = "npc (%d)",
	[COLLISION_GROUP_IN_VEHICLE] = "in vehicle (%d)",
	[COLLISION_GROUP_WEAPON] = "weapon (%d)",
	[COLLISION_GROUP_VEHICLE_CLIP] = "vehicle clip (%d)",
	[COLLISION_GROUP_PROJECTILE] = "projectile (%d)",
	[COLLISION_GROUP_DOOR_BLOCKER] = "door blocker (%d)",
	[COLLISION_GROUP_PASSABLE_DOOR] = "passable door (%d)",
	[COLLISION_GROUP_DISSOLVING] = "dissolving (%d)",
	[COLLISION_GROUP_PUSHAWAY] = "pushaway (%d)",
	[COLLISION_GROUP_NPC_ACTOR] = "npc actor (%d)",
	[COLLISION_GROUP_NPC_SCRIPTED] = "npc scripted (%d)",
	[COLLISION_GROUP_WORLD] = "world (%d)",
	[COLLISION_GROUP_HL2_SPIT] = "hl2 spit (%d)"
}

local LABEL_COLOR = { 192, 192, 192 }
local BASE_COLOR = { 255, 255, 255 }
local R_COLOR = { 255, 128, 128 }
local G_COLOR = { 128, 255, 128 }
local B_COLOR = { 128, 128, 255 }
local CLIENT_COLOR = { 255, 192, 128 }
local SERVER_COLOR = { 128, 192, 255 }
local WORLD_COLOR = { 255, 128, 255 }
local NONE_COLOR = { 255, 192, 128 }

local contextMenuOpen

hook.Add("OnContextMenuOpen", "WardenEntInfo", function()
	contextMenuOpen = true
end)

hook.Add("OnContextMenuClose", "WardenEntInfo", function()
	contextMenuOpen = nil
end)

local hideHud = not GetConVar("cl_drawhud"):GetBool()

cvars.AddChangeCallback("cl_drawhud", function(_, _, val)
	hideHud = val == "0"
end, "WardenHideEntInfo")

local PANEL = {}

function PANEL:Init()
	self:SetAlpha(0)

	self.WorkingWidth, self.WorkingHeight = 10, 10
	self.MouseX, self.MouseY = 0, 0
	self.MouseFollowLerp = 0
	self.RightAlign = true
end

function PANEL:Paint(w, h)
	if self:GetAlpha() == 0 or hideHud then return end
	if hook.Run("HUDShouldDraw", "WardenEntInfo") == false then return end

	self:Blur()
	surface.SetDrawColor(0, 0, 0, 200)
	surface.DrawRect(0, 0, w, h)

	if not IsValid(self.Entity) then return end

	self.WorkingWidth, self.WorkingHeight = 0, 4

	self:ShowOwner()
	self:ShowClass()
	self:ShowModel()
	self:ShowMaterial()
	self:ShowMass()
	self:ShowCGroup()
	self:ShowColor()
	self:ShowPerms()
	self:ShowBottomBar()

	self.WorkingHeight = self.WorkingHeight + 4
end

function PANEL:Think()
	if not enabled:GetBool() then
		self:Reveal(false)
		return
	end

	if self.WorkingWidth ~= self:GetWide() or self.WorkingHeight ~= self:GetTall() then
		self:SetSize(self.WorkingWidth, self.WorkingHeight)
	end

	self:DeterminePos()

	local tr = LocalPlayer():GetEyeTrace()
	if not tr.Hit or not IsValid(tr.Entity) or tr.Entity:IsPlayer() then
		self:Reveal(false)
		return
	end

	self:DetermineFontSize()

	self:Reveal(true)
	self.Entity = tr.Entity
end

function PANEL:ShowOwner()
	if not showOwner:GetBool() then return end

	local ownerName = self.Entity:WardenGetOwnerName()
	local valueColor = BASE_COLOR

	local ownerID = self.Entity:WardenGetOwnerID()
	if ownerID == "World" then
		ownerName = Warden.L("[[WORLD]]")
		valueColor = WORLD_COLOR
	elseif not ownerName or not ownerID or ownerID == "" then
		ownerName = Warden.L("[[NONE]]")
		valueColor = NONE_COLOR
	end

	surface.SetFont(self:GetFont(true))
	self:DrawColorText(LABEL_COLOR, Warden.L("owner:"), " ", valueColor, ownerName)
end

function PANEL:ShowClass()
	if not showClass:GetBool() then return end

	local valueColor = BASE_COLOR
	local clientClass = self.Entity:GetClass()
	local serverClass = self.Entity:GetNW2String("ServerClass", clientClass)
	local class = clientClass

	if clientClass ~= serverClass then
		if LocalPlayer():KeyDown(IN_WALK) or LocalPlayer():KeyDown(IN_SPEED) then
			class = serverClass
			valueColor = SERVER_COLOR
		else
			class = clientClass
			valueColor = CLIENT_COLOR
		end
	end

	surface.SetFont(self:GetFont())
	self:DrawColorText(LABEL_COLOR, Warden.L("class:"), " ", valueColor, class, BASE_COLOR, string.format(" (%s)", self.Entity:EntIndex()))
end

function PANEL:ShowModel()
	if not showModel:GetBool() then return end

	surface.SetFont(self:GetFont())
	self:DrawColorText(LABEL_COLOR, Warden.L("model:"), " ", BASE_COLOR, self.Entity:GetModel())
end

function PANEL:ShowMaterial()
	if not showMaterial:GetBool() then return end

	local mat = self.Entity:GetMaterial()
	if not mat or mat == "" then
		mat = self.Entity:GetMaterials()[1]
	end

	if not mat or mat == "" then return end

	surface.SetFont(self:GetFont())
	self:DrawColorText(LABEL_COLOR, Warden.L("material:"), " ", BASE_COLOR, mat)
end

function PANEL:ShowMass()
	if not showMass:GetBool() then return end
	if not self.Entity.Mass or self.Entity.Mass <= 0 then return end

	surface.SetFont(self:GetFont())
	self:DrawColorText(LABEL_COLOR, Warden.L("mass:"), " ", BASE_COLOR, math.Round(self.Entity.Mass, 2))
end

function PANEL:ShowCGroup()
	if not showCGroup:GetBool() then return end

	local group = self.Entity:GetCollisionGroup()
	if group == COLLISION_GROUP_NONE then return end

	group = Warden.L(COLLISION_GROUP_NAMES[group], group) or group

	surface.SetFont(self:GetFont())
	self:DrawColorText(LABEL_COLOR, Warden.L("collision group:"), " ", BASE_COLOR, group)
end

function PANEL:ShowColor()
	if not showColor:GetBool() then return end

	local col = self.Entity:GetColor()
	if col == color_white then return end

	local r, g, b, a = col:Unpack()

	surface.SetFont(self:GetFont())
	self:DrawColorText(LABEL_COLOR, Warden.L("color:"), " ", { r, g, b }, "●", R_COLOR, r, G_COLOR, g, B_COLOR, b, BASE_COLOR, a)
end

function PANEL:ShowPerms()
	if not showPerms:GetBool() then return end

	local perms = Warden.GetAllPermissions(LocalPlayer(), self.Entity)
	local totalWidth = table.Count(perms) * 20

	if totalWidth == 0 then return end

	surface.SetFont(self:GetFont())
	local textWidth, textHeight = self:DrawColorText(LABEL_COLOR, Warden.L("perms:"), " ", { gap = totalWidth - 4 })

	local cursor = self.RightAlign and self:GetWide() - totalWidth or textWidth - totalWidth + 8
	local shift = (self.FontSize or 0) * 3
	surface.SetDrawColor(255, 255, 255)

	for k, v in pairs(perms) do
		surface.SetMaterial(v:GetIcon())
		surface.DrawTexturedRect(cursor, self.WorkingHeight - textHeight + shift, 16, 16)
		cursor = cursor + 20
	end
end

function PANEL:ShowBottomBar()
	local owner = Warden.GetOwner(self.Entity)

	if not IsValid(owner) then return end

	local r, g, b = team.GetColor(owner:Team()):Unpack()
	surface.SetDrawColor(r, g, b)
	surface.DrawRect(0, self:GetTall() - 4, self:GetWide(), 4)
	self.WorkingHeight = self.WorkingHeight + 4
end

local blur = Material("pp/blurscreen")
function PANEL:Blur()
	if not doBlur:GetBool() then return end

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

function PANEL:Reveal(reveal)
	if reveal then
		if self.Revealed then return end

		self:Stop()
		self:AlphaTo(255, 0.1)
		self.Revealed = true

		return
	end

	if not self.Revealed then return end

	self:Stop()
	self:AlphaTo(0, 0.25)
	self.Revealed = nil
end

function PANEL:DeterminePos()
	if contextMenuOpen and doFollowCursor:GetBool() then
		self.RightAlign = nil
		self.MouseX, self.MouseY = gui.MouseX(), gui.MouseY() -- only setting this here prevents snapping to the top left corner

		if self.MouseFollowLerp > 0.999 then
			self.MouseFollowLerp = 1
		else
			self.MouseFollowLerp = self.MouseFollowLerp + (1 - self.MouseFollowLerp) * 20 * FrameTime()
		end
	else
		self.RightAlign = true

		if self.MouseFollowLerp < 0.001 then
			self.MouseFollowLerp = 0
		else
			self.MouseFollowLerp = self.MouseFollowLerp - self.MouseFollowLerp * 20 * FrameTime()
		end
	end

	local mousePosX, mousePosY = self.MouseX + 16, self.MouseY + 16
	local screenPosX, screenPosY = ScrW() - self:GetWide(), ScrH() / 2 - self:GetTall() / 2 - 40
	self:SetPos(Lerp(self.MouseFollowLerp, screenPosX, mousePosX), Lerp(self.MouseFollowLerp, screenPosY, mousePosY))
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

function PANEL:DrawColorText(...)
	local curColor = BASE_COLOR
	local totalWidth, totalHeight = 0, 0
	local elems = {}
	for _, v in ipairs({...}) do
		if istable(v) then
			if v.gap then
				totalWidth = totalWidth + v.gap
				--table.insert(elems, { text = "", color = curColor, w = v.gap, h = 0 })
			else
				curColor = v
			end
		else
			local w, h = surface.GetTextSize(v)
			totalWidth, totalHeight = totalWidth + w, math.max(totalHeight, h)
			table.insert(elems, { text = v, color = curColor, w = w, h = h })
		end
	end

	local cursor = self.RightAlign and self:GetWide() - totalWidth - 4 or 4
	for _, elem in ipairs(elems) do
		surface.SetTextColor(unpack(elem.color))
		surface.SetTextPos(cursor, self.WorkingHeight)
		surface.DrawText(elem.text)
		cursor = cursor + elem.w
	end

	self.WorkingWidth, self.WorkingHeight = math.max(self.WorkingWidth, totalWidth + 8), self.WorkingHeight + totalHeight

	return totalWidth, totalHeight
end

function PANEL:GetFont(big)
	return string.format("WardenEnt%s%s", big and "Big" or "", self.FontSize or 0)
end

vgui.Register("WardenEntityInfo", PANEL, "DPanel")

hook.Add("InitPostEntity", "WardenEntityInfo", function()
	if IsValid(Warden.EntityInfo) then
		Warden.EntityInfo:Remove()
	end

	Warden.EntityInfo = vgui.Create("WardenEntityInfo")
end)

-- hotload support for singleplayer
if game.SinglePlayer() and IsValid(Warden.EntityInfo) then
	Warden.EntityInfo:Remove()
	Warden.EntityInfo = vgui.Create("WardenEntityInfo")
end