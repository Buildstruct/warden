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
-- should be done immediately to allow servers to set the convars on startup
-- try setting something under 'warden' in your lua folder to do this
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
function Warden.RegisterPermissionSimple(key, name, desc, adminLevel, worldAccess, icon, iconFallback)
	local tbl = Warden.CreatePermission(key)

	tbl:SetName(name)
	tbl:SetDesc(desc)
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
	return self.Name or "Permission"
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

-- // default permission definitions // --

Warden.PERMISSION_ALL     = Warden.RegisterPermissionSimple("whitelist", "whitelist", "Grants full permissions.", 3)
Warden.PERMISSION_PHYSGUN = Warden.RegisterPermissionSimple("physgun", "physgun", "Allows users to pickup your stuff with the physgun.", 1, nil, "bs/aegis_physgun.png", "icon16/flag_blue.png")
Warden.PERMISSION_GRAVGUN = Warden.RegisterPermissionSimple("gravgun", "gravgun", "Allows users to pickup your stuff with the gravgun.", 1, true, "bs/aegis_gravgun.png", "icon16/flag_orange.png")
Warden.PERMISSION_TOOL    = Warden.RegisterPermissionSimple("tool", "toolgun", "Allows users to use the toogun on your stuff.", 2, nil, "bs/aegis_tool.png", "icon16/cup.png")
Warden.PERMISSION_USE     = Warden.RegisterPermissionSimple("use", "use", "Allows users to sit in your seats, use your wire buttons, etc.", 1, true, "bs/aegis_use.png", "icon16/mouse.png")
Warden.PERMISSION_DAMAGE  = Warden.RegisterPermissionSimple("damage", "damage", "Allows users to damage you and your stuff (excluding ACF).", 2, true, "bs/aegis_damage.png", "icon16/sport_raquet.png")

-- // helpers and global funcs // --

-- collapse a keyOrID value into just an id for permissions
-- force: get the id even if it's disabled
function Warden.PermID(keyOrID, force)
	local permID = keyOrID
	if type(keyOrID) == "string" then
		permID = Warden.PermissionIDs[keyOrID]
	end

	if type(keyOrID) == "table" then
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
	if type(keyOrID) == "table" then
		if not force and not keyOrID:GetEnabled() then return end
		return keyOrID
	end

	local permID = Warden.PermID(keyOrID, force)
	return permID and Warden.Permissions[permID]
end

Warden.GetPerm = Warden.GetPermission

-- check if something has the permission to affect another thing
-- keyOrID is the key or id of a permission
function Warden.CheckPermission(receiver, granter, keyOrID)
	local perm = Warden.GetPermission(keyOrID, true)
	if not perm then return false end

	local receiverOwner = Warden.GetOwner(receiver)
	local granterOwner = Warden.GetOwner(granter)

	if not receiverOwner then return false end
	if IsValid(receiverOwner) and perm:GetAdminLevel() <= receiverOwner:WardenGetAdminLevel() then return true end
	if not granterOwner then return false end

	if (receiverOwner.IsWorld and receiverOwner:IsWorld()) or (granterOwner.IsWorld and granterOwner:IsWorld()) then
		local wOverride = hook.Run("WardenCheckPermissionWorld", receiverOwner, granterOwner, perm.ID)
		if wOverride ~= nil then return wOverride end

		return perm:GetWorldAccess()
	end

	if not IsValid(receiverOwner) or not IsValid(granterOwner) then return false end

	-- both receiverOwner and granterOwner are confirmed players

	local override = hook.Run("WardenCheckPermission", receiverOwner, granterOwner, perm.ID)
	if override ~= nil then return override end

	if granterOwner:IsBot() and Warden.GetServerBool("always_target_bots", false) then
		return true
	end

	if receiverOwner == granterOwner then
		if receiver == receiverOwner and receiver ~= granter then
			return receiverOwner:GetInfoNum("warden_touch_self", 1) == 1
		end

		return true
	end

	if perm.ID ~= Warden.PERMISSION_ALL and Warden.CheckPermission(receiverOwner, granterOwner, Warden.PERMISSION_ALL) then
		return true
	end

	granterOwner:WardenEnsureSetup()

	return Warden.GetPermStatus(receiverOwner, granterOwner, perm)
end

Warden.HasPermission = Warden.CheckPermission

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

	local permList = Warden.PlyPerms[ply:SteamID()][perm.ID]

	local state = permList and permList.global
	if state == nil then
		state = perm:GetDefault()
	end

	return state
end

-- get every perm or every perm for a specific pair of ents
function Warden.GetAllPermissions(receiver, granter)
	if not receiver and not granter then
		local perms = {}
		for k, v in pairs(Warden.Permissions) do
			if v:GetEnabled() then
				perms[k] = v
			end
		end

		return perms
	end

	local globalPerm = Warden.GetPermission(Warden.PERMISSION_ALL)
	if globalPerm and Warden.CheckPermission(receiver, granter, Warden.PERMISSION_ALL) then
		return { [Warden.PERMISSION_ALL] = globalPerm }
	end

	local perms = {}

	for k, v in pairs(Warden.Permissions) do
		if v:GetEnabled() and Warden.CheckPermission(receiver, granter, k) then
			perms[k] = v
		end
	end

	return perms
end

-- get the permission status for two players
-- intended to be internal, you probably want CheckPermission instead
function Warden.GetPermStatus(receiver, granter, perm)
	granter:WardenEnsureSetup()

	if not perm:GetEnabled() then return perm:GetDefault() end

	local permList = Warden.PlyPerms[granter:SteamID()][perm.ID]
	if not permList then return false end

	local global = permList.global
	if global == nil then
		global = perm:GetDefault()
	end

	local lcl = permList[receiver:SteamID()] or false

	return global ~= lcl
end