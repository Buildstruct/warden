Warden.Permissions = {}
Warden.PermissionKeys = {}
Warden.PlyPerms = Warden.PlyPerms or {}

local targetBotsCvar = CreateConVar("warden_always_target_bots", 1, FCVAR_REPLICATED, "If true, bots always have all their permissions overridden.", 0, 1)

local permFuncs = {}
local permMeta = { __index = permFuncs }

-- create an unregistered permission table
function Warden.CreatePermission()
	local tbl = {}
	setmetatable(tbl, permMeta)

	return tbl
end

-- register a permission table to the server
-- should be done immediately to allow servers to set the convars on startup
-- try setting something under 'warden' in your lua folder to do this
function Warden.RegisterPermission(key, tbl)
	setmetatable(tbl, permMeta) -- in case it hasn't been set already

	Warden.Permissions[key] = tbl
	local id = table.insert(Warden.PermissionKeys, key)

	tbl._AdminCVar = CreateConVar("warden_perm_" .. key .. "_admin_level", -1, FCVAR_REPLICATED, "Set the admin level needed for admins to override this permission.", -1, 99)
	tbl._WorldCVar = CreateConVar("warden_perm_" .. key .. "_world_access", -1, FCVAR_REPLICATED, "Set whether the world has this permission", -1, 1)
	tbl._EnabledCVar = CreateConVar("warden_perm_" .. key .. "_enabled", 1, FCVAR_REPLICATED, "Set whether this permission is enabled", 0, 1)
	tbl.ID = id

	return id
end

-- same as above but do all of the important stuff at once
function Warden.RegisterPermissionSimple(key, name, desc, adminLevel, worldAccess, icon, iconFallback)
	local tbl = Warden.CreatePermission()

	tbl:SetName(name)
	tbl:SetDesc(desc)
	tbl:SetDefaultAdminLevel(adminLevel)
	tbl:SetDefaultWorldAccess(worldAccess)
	tbl:SetIcon(icon, iconFallback)

	return Warden.RegisterPermission(key, tbl)
end

local defaultIcon = CLIENT and Material("icon16/star.png")
function permFuncs:SetIcon(icon, iconFallback)
	self.IconString = icon
	self.FallbackIconString = iconFallback
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

function permFuncs:SetDefaultAdminLevel(default)
	self.DefaultAdminLevel = default
end

function permFuncs:GetDefaultAdminLevel()
	return self.DefaultAdminLevel or 1
end

function permFuncs:GetAdminLevel()
	if not self._AdminCVar then
		return self:GetDefaultAdminLevel()
	end

	local permLevel = self._AdminCVar:GetInt()
	if permLevel < 0 then
		return self:GetDefaultAdminLevel()
	end

	return permLevel
end

function permFuncs:SetDefaultWorldAccess(worldAccess)
	self.DefaultWorldAccess = worldAccess
end

function permFuncs:GetDefaultWorldAccess()
	return self.DefaultWorldAccess or false
end

function permFuncs:GetWorldAccess()
	if not self._WorldCVar then
		return self:GetDefaultWorldAccess()
	end

	local worldAccess = self._WorldCVar:GetInt()
	if worldAccess < 0 then
		return self:GetDefaultWorldAccess()
	end

	return worldAccess == 1
end

function permFuncs:SetEnabled(enabled)
	self.Enabled = enabled
end

function permFuncs:GetEnabled()
	if not self._EnabledCVar then
		return self.Enabled or true
	end

	if not self._EnabledCVar:GetBool() then
		return false
	end

	return self.Enabled or true
end

-- // default permission definitions // --

Warden.PERMISSION_ALL     = Warden.RegisterPermissionSimple("whitelist", "Whitelist", "Grants full permissions.", 3)
Warden.PERMISSION_PHYSGUN = Warden.RegisterPermissionSimple("physgun", "Physgun", "Allows users to pickup your stuff with the physgun.", 1, nil, "bs/aegis_physgun.png", "icon16/flag_blue.png")
Warden.PERMISSION_GRAVGUN = Warden.RegisterPermissionSimple("gravgun", "Gravgun", "Allows users to pickup your stuff with the gravgun.", 1, true, "bs/aegis_gravgun.png", "icon16/flag_orange.png")
Warden.PERMISSION_TOOL    = Warden.RegisterPermissionSimple("tool", "Toolgun", "Allows users to use the toogun on your stuff.", 2, nil, "bs/aegis_tool.png", "icon16/cup.png")
Warden.PERMISSION_USE     = Warden.RegisterPermissionSimple("use", "Use (E)", "Allows users to sit in your seats, use your wire buttons, etc.", 1, true, "bs/aegis_use.png", "icon16/mouse.png")
Warden.PERMISSION_DAMAGE  = Warden.RegisterPermissionSimple("damage", "Damage", "Allows users to damage you and your stuff (excluding ACF).", 2, true, "bs/aegis_damage.png", "icon16/sport_raquet.png")

-- // helpers and global funcs // --

-- collapse a keyOrID value into just a key for permissions
function Warden.PermKey(keyOrID)
	local key = keyOrID
	if type(keyOrID) == "number" then
		key = Warden.PermissionKeys[keyOrID]
	end

	return key
end

-- collapse a keyOrID value into just an id for permissions
function Warden.PermID(keyOrID)
	local perm = Warden.GetPermission(keyOrID)
	return perm and perm.ID
end

-- whether two ents have a local perm
function Warden.HasPermissionLocal(receiver, granter, keyOrID)
	receiver = Warden.GetOwner(receiver)
	granter = Warden.GetOwner(granter)
	if not IsValid(receiver) or not IsValid(granter) then return false end

	local id = Warden.PermID(keyOrID)
	local permList = Warden.Permissions[granter:SteamID()][id]

	return permList and permList[receiver:SteamID()] or false
end

-- whether an ent has a global perm
function Warden.HasPermissionGlobal(ent, keyOrID)
	local ply = Warden.GetOwner(ent)
	if not IsValid(ply) then return false end

	local id = Warden.PermID(keyOrID)
	local permList = Warden.Permissions[ply:SteamID()][id]

	return permList and permList.global or false
end

-- get the permission status for two players
function Warden.GetPermStatus(receiver, granter, keyOrID)
	receiver = Warden.GetOwner(receiver)
	granter = Warden.GetOwner(granter)

	local id = Warden.PermID(keyOrID)

	local permList = Warden.Permissions[granter:SteamID()][id]
	if not permList then return false end

	local global = permList.global or false
	local lcl = permList[receiver:SteamID()] or false

	return global ~= lcl
end

-- get a permission object from the key or id
-- force: get the permission even if it's disabled
function Warden.GetPermission(keyOrID, force)
	local key = Warden.PermKey(keyOrID)
	if not key then return end

	local perm = Warden.Permissions[key]
	if perm and (force or perm:GetEnabled()) then
		return perm
	end
end

Warden.GetPerm = Warden.GetPermission

-- check if something has the permission to affect another thing
-- keyOrID is the key or id of a permission
function Warden.CheckPermission(receiver, granter, keyOrID)
	local perm = Warden.GetPermission(keyOrID)
	if not perm then return true end

	receiver = Warden.GetOwner(receiver)
	granter = Warden.GetOwner(granter)

	if not receiver then return false end
	if IsValid(receiver) and perm:GetAdminLevel() <= receiver:WardenGetAdminLevel() then return true end
	if not granter then return false end

	if (receiver.IsWorld and receiver:IsWorld()) or (granter.IsWorld and granter:IsWorld()) then
		local wOverride = hook.Run("WardenCheckPermissionWorld", receiver, granter, Warden.PermID(keyOrID))
		if wOverride ~= nil then return wOverride end

		return perm:GetWorldAccess()
	end

	if not IsValid(receiver) or not IsValid(granter) then return false end

	-- both receiver and granter are confirmed players

	local override = hook.Run("WardenCheckPermission", receiver, granter, Warden.PermID(keyOrID))
	if override ~= nil then return override end

	if granter:IsBot() and targetBotsCvar:GetBool() then
		return true
	end

	if receiver == granter then return true end

	if perm.ID ~= Warden.PERMISSION_ALL and Warden.CheckPermission(receiver, granter, Warden.PERMISSION_ALL) then
		return true
	end

	granter:WardenEnsureSetup()

	return Warden.GetPermStatus(receiver, granter, keyOrID)
end

Warden.HasPermission = Warden.CheckPermission

-- get every perm or every perm for a specific pair of ents
function Warden.GetAllPermissions(receiver, granter)
	if not receiver and not granter then
		local perms = {}
		for k, v in ipairs(Warden.Permissions) do
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

	for k, v in ipairs(Warden.Permissions) do
		if v:GetEnabled() and Warden.CheckPermission(receiver, granter, k) then
			perms[k] = v
		end
	end

	return perms
end