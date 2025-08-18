Warden.Permissions = {}
Warden.PermissionIDs = {}
Warden.PlyPerms = Warden.PlyPerms or {}

local permFuncs = {}
local permMeta = { __index = permFuncs }

-- create an unregistered permission table
function Warden.CreatePermission(key)
	local tbl = {}

	setmetatable(tbl, permMeta)
	tbl.KEY = key

	return tbl
end

-- register a permission table to the server
function Warden.RegisterPermission(tbl, key)
	local id = table.insert(Warden.Permissions, tbl)

	if not key then
		key = tbl.KEY
	else
		setmetatable(tbl, permMeta)
		tbl.KEY = key
	end

	Warden.PermissionIDs[key] = id
	tbl.ID = id

	return id, tbl
end

-- same as above but do all of the important stuff at once
function Warden.RegisterPermissionSimple(key, name, adminLevel, worldAccess, icon, iconFallback)
	local tbl = Warden.CreatePermission(key)

	tbl:SetName(name)
	tbl:SetAdminLevel(adminLevel, true)
	tbl:SetWorldAccess(worldAccess, true)
	tbl:SetIcon(icon, iconFallback)

	return Warden.RegisterPermission(tbl)
end

local defaultIcon = CLIENT and Material("icon16/star.png")
function permFuncs:SetIcon(icon, iconFallback)
	self.IconString = icon or self.IconString
	self.FallbackIconString = iconFallback or self.FallbackIconString

	self._Icon = nil
end

function permFuncs:GetIconString()
	return self.IconString, self.FallbackIconString
end

function permFuncs:GetIcon()
	if SERVER then return end

	if self._Icon then
		return self._Icon
	end

	if self.IconString then
		self._Icon = Material(self.IconString)

		if not self._Icon:IsError() then
			return self._Icon
		end
	end

	if self.FallbackIconString then
		self._Icon = Material(self.FallbackIconString)

		if not self._Icon:IsError() then
			return self._Icon
		end
	end

	self._Icon = defaultIcon

	return self._Icon
end

function permFuncs:SetName(name)
	self.Name = name
end

function permFuncs:GetName()
	if SERVER then return self.Name or "perm" end

	return Warden.L(self.Name or "perm")
end

function permFuncs:SetDesc(desc)
	self.Desc = desc
end

function permFuncs:GetDesc()
	return self.Desc or "A permission"
end

local function makeGetSet(name, cvarName, get, fallback)
	permFuncs["Set" .. name] = function(self, value, doNotSave)
		if WARDEN_LOADED and not doNotSave then
			Warden.SetServerSetting(cvarName .. self.KEY, value)
			return
		end

		self[name] = value
	end

	permFuncs["Get" .. name] = function(self)
		local fallback1 = self[name]
		if fallback1 == nil then fallback1 = fallback end

		return Warden["GetServer" .. get](cvarName .. self.KEY, fallback1)
	end
end

makeGetSet("AdminLevel", "admin_level_", "Setting", 99)
makeGetSet("WorldAccess", "world_access_", "Bool", false)
makeGetSet("Default", "default_", "Bool", false)
makeGetSet("Enabled", "enabled_", "Bool", true)
makeGetSet("BypassTouch", "bypass_touch_", "Bool", false)

-- // default permission definitions // --

Warden.PERMISSION_ALL     = Warden.RegisterPermissionSimple("whitelist", "whitelist", 3)
Warden.PERMISSION_TOOL    = Warden.RegisterPermissionSimple("tool", "toolgun", 2, nil, "warden/tool.png", "icon16/wand.png")
Warden.PERMISSION_PHYSGUN = Warden.RegisterPermissionSimple("physgun", "physgun", 1, nil, "warden/physgun.png", "icon16/wrench.png")
Warden.PERMISSION_GRAVGUN = Warden.RegisterPermissionSimple("gravgun", "gravgun", 1, true, "warden/gravgun.png", "icon16/wrench_orange.png")

Warden.PERMISSION_USE, use = Warden.RegisterPermissionSimple("use", "use", 1, true, "warden/use.png", "icon16/mouse.png")
use:SetBypassTouch(true, true)

Warden.PERMISSION_DAMAGE  = Warden.RegisterPermissionSimple("damage", "damage", 2, true, "warden/damage.png", "icon16/gun.png")

-- // helpers and global funcs // --

-- collapse a keyOrID value into just an id for permissions
-- force: get the id even if it's disabled
function Warden.PermID(keyOrID, force)
	local permID = keyOrID
	local _type = type(keyOrID)

	if _type == "string" then
		permID = Warden.PermissionIDs[keyOrID]
	elseif _type == "table" then
		if not force and not keyOrID:GetEnabled() then return end
		return keyOrID.ID
	end

	local perm = Warden.Permissions[permID]
	if perm and (force or perm:GetEnabled()) then
		return permID
	end
end

-- get a permission object from the key or id
-- force: get the permission even if it's disabled
function Warden.GetPermission(keyOrID, force)
	local permID = Warden.PermID(keyOrID, force)
	return permID and Warden.Permissions[permID]
end

Warden.GetPerm = Warden.GetPermission

hook.Add("WardenPreCheckPermission", "WardenWhitelist", function(receiver, granter, perm, receiverOwner, granterOwner, validRec, validGra)
	if perm.ID == Warden.PERMISSION_ALL then return end
	if Warden._CheckPerm(receiver, granter, Warden.Permissions[Warden.PERMISSION_ALL], receiverOwner, granterOwner, validRec, validGra) then return true end
end)

local pCache = {}
local pAllCache = {}

-- check if something has the permission to affect another thing
-- keyOrID is the key or id of a permission
function Warden.CheckPermission(receiver, granter, keyOrID)
	local perm = Warden.GetPermission(keyOrID, true)
	if not perm then return false end

	local cID = string.format("%s%s%s", receiver or "$", granter or "$", perm.KEY or "$")
	if pCache[cID] then return pCache[cID] end

	local receiverOwner = Warden.GetOwner(receiver)
	local granterOwner = Warden.GetOwner(granter)

	local validRec = IsValid(receiverOwner)
	local validGra = IsValid(granterOwner)

	-- check receiver's touch settings
	if validRec and receiver == receiverOwner and receiver ~= granter and not perm:GetBypassTouch() then
		if receiverOwner == granterOwner then
			if receiverOwner:GetInfoNum("warden_touch_self", 1) == 0 then
				pCache[cID] = false
				return false
			end
		elseif not IsValid(granter) or not granter:IsPlayer() then
			if receiverOwner:GetInfoNum("warden_touch", 1) == 0 then
				pCache[cID] = false
				return false
			end
		end
	end

	local out = hook.Run("WardenPreCheckPermission", receiver, granter, perm, receiverOwner, granterOwner, validRec, validGra)
	if out == nil then
		out = Warden._CheckPerm(receiver, granter, perm, receiverOwner, granterOwner, validRec, validGra)
	end

	pCache[cID] = out
	return out
end

Warden.HasPermission = Warden.CheckPermission
Warden.HasPerm = Warden.CheckPermission

-- collapse a keyOrID value into just a key for permissions
-- force: get the key even if it's disabled
function Warden.PermKey(keyOrID, force)
	local perm = Warden.GetPermission(keyOrID, force)
	return perm and perm.KEY
end

-- whether two ents have a local perm
function Warden.HasPermissionLocal(receiver, granter, keyOrID)
	receiver = Warden.GetOwner(receiver)
	granter = Warden.GetOwner(granter)
	if not IsValid(receiver) or not IsValid(granter) then return false end

	granter:WardenEnsureSetup()

	local id = Warden.PermID(keyOrID)
	local permList = Warden.PlyPerms[granter:SteamID()][id]

	return permList and permList[receiver:SteamID()] or false
end

-- whether an ent has a global perm
function Warden.HasPermissionGlobal(ent, keyOrID)
	local ply = Warden.GetOwner(ent)
	if not IsValid(ply) then return false end

	ply:WardenEnsureSetup()

	local perm = Warden.GetPermission(keyOrID, true)
	if not perm then return false end
	if not perm:GetEnabled() then return perm:GetDefault() end

	local state = Warden.PlyPerms[ply:SteamID()][perm.ID].global
	if state == nil then
		if ply:GetInfoNum("warden_perm_persist", 0) == 0 then
			state = perm:GetDefault()
		else
			state = false
		end
	end

	return state
end

hook.Add("WardenGetAllPerms", "WardenWhitelist", function(receiver, granter)
	local globalPerm = Warden.Permissions[Warden.PERMISSION_ALL]
	if globalPerm:GetEnabled() and Warden.CheckPermission(receiver, granter, globalPerm) then
		return { [Warden.PERMISSION_ALL] = globalPerm }
	end
end)

-- get every perm or every perm for a specific pair of ents
function Warden.GetAllPermissions(receiver, granter)
	local cID = string.format("%s%s", receiver or "$", granter or "$")
	if pAllCache[cID] then return pAllCache[cID] end

	if not receiver and not granter then
		local perms = {}
		for k, v in pairs(Warden.Permissions) do
			if v:GetEnabled() then
				perms[k] = v
			end
		end

		pAllCache[cID] = perms
		return perms
	end

	local override = hook.Run("WardenGetAllPerms", receiver, granter)
	if override ~= nil then
		pAllCache[cID] = override
		return override
	end

	local perms = {}

	for k, v in pairs(Warden.Permissions) do
		if v:GetEnabled() and Warden.CheckPermission(receiver, granter, k) then
			perms[k] = v
		end
	end

	pAllCache[cID] = perms
	return perms
end

timer.Create("WardenPCache", 0.5, 0, function()
	pCache = {}
	pAllCache = {}
end)

-- intended to be internal
function Warden._CheckPerm(receiver, granter, perm, receiverOwner, granterOwner, validRec, validGra)
	-- check if the granter ent is filtered
	local bypass = Warden._GetEntPermBypass(granter, perm)
	if bypass ~= nil then
		if bypass then return true end
		if not validRec or Warden.GetServerSetting("admin_level_filter_bypass") > receiverOwner:WardenGetAdminLevel() then return false end
	end

	if validRec and perm:GetAdminLevel() <= receiverOwner:WardenGetAdminLevel() then return true end
	if validGra and granterOwner:IsBot() and Warden.GetServerBool("always_target_bots", false) then return true end

	if not granterOwner or not receiverOwner then return perm:GetDefault() end

	if (receiverOwner.IsWorld and receiverOwner:IsWorld()) or (granterOwner.IsWorld and granterOwner:IsWorld()) then
		return perm:GetWorldAccess()
	end

	if not validRec or not validGra then return perm:GetDefault() end

	-- both receiverOwner and granterOwner are confirmed players

	local override = hook.Run("WardenCheckPermission", receiverOwner, granterOwner, perm)
	if override ~= nil then return override end

	if receiverOwner == granterOwner then return true end

	return Warden._GetPermStatus(receiverOwner, granterOwner, perm)
end

-- get the permission status for two players
-- intended to be internal, you probably want CheckPermission instead
function Warden._GetPermStatus(receiver, granter, perm)
	local grantID = granter:SteamID()
	Warden.PlyPerms[grantID] = Warden.PlyPerms[grantID] or {}
	for _, v in pairs(Warden.Permissions) do
		Warden.PlyPerms[grantID][v.ID] = Warden.PlyPerms[grantID][v.ID] or {}
	end

	if not perm:GetEnabled() then return perm:GetDefault() end

	local permList = Warden.PlyPerms[grantID][perm.ID]
	if not permList then return false end

	--ignore default settings if perm persist is on
	local global = permList.global
	if global == nil then
		if granter:GetInfoNum("warden_perm_persist", 0) == 0 then
			global = perm:GetDefault()
		else
			global = false
		end
	end

	local lcl = permList[receiver:SteamID()] or false

	return global ~= lcl
end