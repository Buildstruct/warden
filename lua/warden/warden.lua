function Warden.SetupPlayer(plyOrID)
	if not isstring(plyOrID) then
		plyOrID = plyOrID:SteamID()
	end

	Warden.Permissions[plyOrID] = {}
	for _, id in pairs(Warden.PermissionIDs) do
		Warden.Permissions[plyOrID][id] = { global = false }
	end
end

local USE_EXCEPTIONS = {
	mediaplayer_tv = true,
	mediaplayer_tv_ext = true
}

function Warden.PlayerIsDisconnected(steamID)
	local ply = Warden.GetPlayerFromSteamID(steamID)
	return not IsValid(ply)
end

local function worldCheck(permission)
	local perm = GetConVar("warden_world_" .. Warden.PermissionList[permission].id):GetInt()
	if perm < 0 then
		return Warden.PermissionList[permission].defaultWorldPerm
	end

	return perm == 1
end

local function adminCheck(ply, permission)
	if not IsValid(ply) then return end

	local permLevel = GetConVar("warden_admin_level_" .. Warden.PermissionList[permission].id):GetInt()
	if permLevel < 0 then
		permLevel = Warden.PermissionList[permission].defaultAdminLevel
	end

	return permLevel <= ply:WardenGetAdminLevel()
end

function Warden.CheckPermission(receiver, granter, permission)
	if not Warden.PermissionList[permission] then return false end

	receiver = Warden.GetOwner(receiver)
	granter = Warden.GetOwner(granter)
	if not receiver or not granter then return false end

	if adminCheck(receiver, permission) then return true end

	if (receiver.IsWorld and receiver:IsWorld()) or (granter.IsWorld and granter:IsWorld()) then
		local wOverride = hook.Run("WardenCheckPermissionWorld", receiver, granter, permission)
		if wOverride ~= nil then return wOverride end

		return worldCheck(permission)
	end

	if not IsValid(receiver) or not IsValid(granter) then return end

	-- both receiver and granter are confirmed players

	local override = hook.Run("WardenCheckPermission", receiver, granter, permission)
	if override ~= nil then return override end

	if granter:IsBot() and GetConVar("warden_always_target_bots"):GetBool() then
		return true
	end

	if receiver == granter then return true end

	if permission ~= Warden.PERMISSION_ALL and Warden.CheckPermission(receiver, granter, Warden.PERMISSION_ALL) then
		return true
	end

	granter:WardenEnsureSetup()

	--make individual permissions exclude players when the global permission is set
	--we do 'or false' to ensure the permission isn't nil for the inequality
	local perm = Warden.Permissions[granter:SteamID()][permission]
	return (perm.global or false) ~= (perm[receiver:SteamID()] or false)
end

Warden.HasPermission = Warden.CheckPermission

function Warden.GetAllPermissions(receiver, granter)
	if not receiver and not granter then
		return Warden.PermissionList
	end

	if Warden.CheckPermission(receiver, granter, Warden.PERMISSION_ALL) then
		return { [Warden.PERMISSION_ALL] = Warden.PermissionList[Warden.PERMISSION_ALL] }
	end

	local perms = {}

	for k, v in ipairs(Warden.PermissionList) do
		if Warden.CheckPermission(receiver, granter, k) then
			perms[k] = v
		end
	end

	return perms
end

function Warden.HasPermissionLocal(receiver, granter, permission)
	receiver = Warden.GetOwner(receiver)
	granter = Warden.GetOwner(granter)
	if not IsValid(receiver) or not IsValid(granter) then return false end

	granter:WardenEnsureSetup()

	return Warden.Permissions[granter:SteamID()][permission][receiver:SteamID()] or false
end

function Warden.HasPermissionGlobal(ent, permission)
	local ply = Warden.GetOwner(ent)
	if not IsValid(ply) then return false end

	ply:WardenEnsureSetup()

	return Warden.Permissions[ply:SteamID()][permission].global or false
end

local PLAYER = FindMetaTable("Player")

function PLAYER:WardenGetAdminLevel()
	if GetConVar("warden_admin_level_needs_admin"):GetBool() and not self:IsAdmin() then
		return 0
	end

	local adminLevel = SERVER and self.WardenAdminLevel or Warden.LocalAdminLevel
	if not adminLevel then
		adminLevel = GetConVar("warden_default_admin_level"):GetInt()
	end

	return adminLevel
end

function PLAYER:WardenEnsureSetup()
	if not Warden.Permissions[self:SteamID()] then
		Warden.SetupPlayer(self)
	end
end

hook.Add("CanTool", "Warden", function(ply, tr, tool)
	local ent = tr.Entity
	if ent:IsWorld() then return true end

	if not Warden.CheckPermission(ply, ent, Warden.PERMISSION_TOOL) then
		return false
	end
end)

hook.Add("GravGunPunt", "Warden", function(ply, ent)
	if not Warden.CheckPermission(ply, ent, Warden.PERMISSION_GRAVGUN) then
		return false
	end
end)

hook.Add("PhysgunPickup", "Warden", function(ply, ent)
	if not Warden.CheckPermission(ply, ent, Warden.PERMISSION_PHYSGUN) then
		return false
	end
end)

hook.Add("CanProperty", "Warden", function(ply, property, ent)
	if not Warden.CheckPermission(ply, ent, Warden.PERMISSION_TOOL) then
		return false
	end
end)

gameevent.Listen("player_disconnect")

if SERVER then
	util.AddNetworkString("WardenUpdatePermission")
	util.AddNetworkString("WardenAdminLevel")
	util.AddNetworkString("WardenInitialize")

	local initialized = {}
	net.Receive("WardenInitialize", function(_, ply)
		if initialized[ply] then return end
		initialized[ply] = true

		Warden.SetupPlayer(ply)
		net.Start("WardenInitialize")
		net.WriteUInt(#Warden.Permissions, 8)
		for steamID, perms in pairs(Warden.Permissions) do
			net.WriteString(steamID)
			net.WriteUInt(#perms, 8)
			for permisson, ssteamIDs in pairs(perms) do
				net.WriteUInt(permisson, 8)

				local toSend = {}
				for ssteamID, granted in pairs(ssteamIDs) do
					if granted then
						table.insert(toSend, ssteamID)
					end
				end
				net.WriteUInt(#toSend, 8)
				for _, ssteamID in ipairs(toSend) do
					net.WriteString(ssteamID)
				end
			end
		end
		net.Send(ply)
	end)

	local function getInternalOwner(ent)
		local owner = ent:GetInternalVariable("m_hOwnerEntity") or NULL
		if owner == NULL then owner = ent:GetInternalVariable("m_hOwner") or NULL end
		if owner == NULL then return false end
		if not owner:IsPlayer() then owner = Warden.GetOwner(owner) end
		return owner
	end

	hook.Add("OnEntityCreated", "Warden", function(ent)
		timer.Simple(0, function()
			if ent:IsValid() and not Warden.GetOwner(ent) then
				local owner = getInternalOwner(ent)
				if owner then
					Warden.SetOwner(ent, owner)
				else
					Warden.SetOwnerWorld(ent)
				end
			end
		end)
	end)

	hook.Add("PlayerInitialSpawn", "Warden", function(ply)
		for entIndex, _ in pairs(Warden.GetPlayerTable(ply)) do
			Warden.SetOwner(Entity(entIndex), ply)
		end

		timer.Remove("WardenCleanup#" .. ply:SteamID())
	end)

	net.Receive("WardenUpdatePermission", function(_, ply)
		local permission = net.ReadUInt(8)
		if not Warden.PermissionList[permission] then return end

		local granting = net.ReadBool()
		if net.ReadBool() then
			local receiver = net.ReadEntity()
			if IsValid(receiver) then
				if granting then
					Warden.GrantPermission(ply, receiver, permission)
				else
					Warden.RevokePermission(ply, receiver, permission)
				end
			end
		else
			if granting then
				Warden.GrantPermission(ply, nil, permission)
			else
				Warden.RevokePermission(ply, nil, permission)
			end
		end
	end)

	local function networkPermission(ply, receiver, permission, granting)
		net.Start("WardenUpdatePermission")
		net.WriteBool(granting) -- Granting = true, Revoking = false
		net.WriteUInt(permission, 8) -- Permission index
		net.WriteEntity(ply) -- Player granting the permission
		if receiver then
			net.WriteBool(false) -- Is Global Permission
			net.WriteEntity(receiver) -- Player receiving the permission
		else
			net.WriteBool(true)
		end
		net.Broadcast()
	end

	function Warden.GrantPermission(granter, receiver, permission)
		granter:WardenEnsureSetup()

		if IsValid(receiver) and receiver:IsPlayer() then
			if Warden.Permissions[granter:SteamID()][permission]["global"] then
				hook.Run("WardenRevokePermission", granter, receiver, Warden.PermissionList[permission].id, true)
			else
				hook.Run("WardenGrantPermission", granter, receiver, Warden.PermissionList[permission].id)
			end

			Warden.Permissions[granter:SteamID()][permission][receiver:SteamID()] = true
			networkPermission(granter, receiver, permission, true)
		else
			hook.Run("WardenGrantPermissionGlobal", granter, Warden.PermissionList[permission].id)
			Warden.Permissions[granter:SteamID()][permission]["global"] = true
			networkPermission(granter, nil, permission, true)
		end
	end

	function Warden.RevokePermission(revoker, receiver, permission)
		if not Warden.Permissions[revoker:SteamID()][permission] then
			Warden.SetupPlayer(revoker)
		end

		if IsValid(receiver) and receiver:IsPlayer() then
			if Warden.Permissions[revoker:SteamID()][permission]["global"] then
				hook.Run("WardenGrantPermission", revoker, receiver, Warden.PermissionList[permission].id, true)
			else
				hook.Run("WardenRevokePermission", revoker, receiver, Warden.PermissionList[permission].id)
			end

			Warden.Permissions[revoker:SteamID()][permission][receiver:SteamID()] = nil
			networkPermission(revoker, receiver, permission, false)
		else
			hook.Run("WardenRevokePermissionGlobal", revoker, Warden.PermissionList[permission].id)
			Warden.Permissions[revoker:SteamID()][permission]["global"] = nil
			networkPermission(revoker, nil, permission, false)
		end
	end

	function Warden.FreezeEntities(steamID)
		local count = 0
		for _, ent in ipairs(Warden.GetOwnedEntities(steamID)) do
			for i = 0, ent:GetPhysicsObjectCount() - 1 do
				local phys = ent:GetPhysicsObjectNum(i)
				phys:EnableMotion(false)
			end
			count = count + 1
		end
		hook.Run("WardenFreeze", steamID, count)
	end

	function Warden.CleanupEntities(steamID)
		local count = 0
		for _, ent in ipairs(Warden.GetOwnedEntities(steamID)) do
			ent:Remove()
		end
		count = count + 1

		hook.Run("WardenCleanup", steamID, count)
		return count
	end

	function Warden.FreezeDisconnected()
		for steamID, _ in pairs(Warden.GetPlayerTable()) do
			if Warden.PlayerIsDisconnected(steamID) then
				Warden.FreezeEntities(steamID)
			end
		end
	end

	function Warden.CleanupDisconnected()
		for steamID, _ in pairs(Warden.GetPlayerTable()) do
			if Warden.PlayerIsDisconnected(steamID) then
				Warden.CleanupEntities(steamID)
			end
		end
	end

	-- Detours

	if PLAYER.AddCount then
		Warden.BackupPlyAddCount = Warden.BackupPlyAddCount or PLAYER.AddCount
		function PLAYER:AddCount(enttype, ent)
			Warden.SetOwner(ent, self)
			Warden.BackupPlyAddCount(self, enttype, ent)
		end
	end

	if PLAYER.AddCleanup then
		Warden.BackupPlyAddCleanup = Warden.BackupPlyAddCleanup or PLAYER.AddCleanup
		function PLAYER:AddCleanup(enttype, ent)
			Warden.SetOwner(ent, self)
			Warden.BackupPlyAddCleanup(self, enttype, ent)
		end
	end

	if cleanup then
		Warden.BackupCleanupAdd = Warden.BackupCleanupAdd or cleanup.Add
		function cleanup.Add(ply, enttype, ent)
			if IsValid(ent) then
				Warden.SetOwner(ent, ply)
			end

			Warden.BackupCleanupAdd(ply, enttype, ent)
		end

		Warden.BackupCleanupReplaceEntity = Warden.BackupCleanupReplaceEntity or cleanup.ReplaceEntity
		function cleanup.ReplaceEntity(from, to, ...)
			local ret = { Warden.BackupCleanupReplaceEntity(from, to, ...) }
			if ret[1] and IsValid(from) and IsValid(to) then
				Warden.ReplaceOwner(from, to)
			end

			return unpack(ret)
		end
	end

	if undo then
		Warden.BackupUndoReplaceEntity = Warden.BackupUndoReplaceEntity or undo.ReplaceEntity
		function undo.ReplaceEntity(from, to, ...)
			local ret = { Warden.BackupUndoReplaceEntity(from, to, ...) }
			if ret[1] and IsValid(from) and IsValid(to) then
				Warden.ReplaceOwner(from, to)
			end

			return unpack(ret)
		end

		local currentUndo

		Warden.BackupUndoCreate = Warden.BackupUndoCreate or undo.Create
		function undo.Create(...)
			currentUndo = { ents = {} }
			return Warden.BackupUndoCreate(...)
		end

		Warden.BackupUndoAddEntity = Warden.BackupUndoAddEntity or undo.AddEntity
		function undo.AddEntity(ent, ...)
			if currentUndo and IsValid(ent) then
				table.insert(currentUndo.ents, ent)
			end

			return Warden.BackupUndoAddEntity(ent, ...)
		end

		Warden.BackupUndoSetPlayer = Warden.BackupUndoSetPlayer or undo.SetPlayer
		function undo.SetPlayer(ply, ...)
			if currentUndo and IsValid(ply) then
				currentUndo.owner = ply
			end

			return Warden.BackupUndoSetPlayer(ply, ...)
		end

		Warden.BackupUndoFinish = Warden.BackupUndoFinish or undo.Finish
		function undo.Finish(...)
			if not currentUndo then
				return Warden.BackupUndoFinish(...)
			end

			local ply = currentUndo.owner
			if not IsValid(ply) then
				currentUndo = nil
				return Warden.BackupUndoFinish(...)
			end

			for _, ent in ipairs(currentUndo.ents) do
				if IsValid(ent) then
					Warden.SetOwner(ent, ply)
				end
			end

			currentUndo = nil
			return Warden.BackupUndoFinish(...)
		end
	end

	function PLAYER:WardenSetAdminLevel(level)
		if type(level) ~= "number" and type(level) ~= "nil" then
			error("admin level must be a number or nil", 2)
		end

		self.WardenAdminLevel = level

		net.Start("WardenAdminLevel")
			net.WriteUInt(level, 8)
		net.Send(self)
	end

	hook.Add("PlayerSpawnedEffect",  "Warden", function(ply, _, ent) Warden.SetOwner(ent, ply) end)
	hook.Add("PlayerSpawnedProp",    "Warden", function(ply, _, ent) Warden.SetOwner(ent, ply) end)
	hook.Add("PlayerSpawnedRagdoll", "Warden", function(ply, _, ent) Warden.SetOwner(ent, ply) end)
	hook.Add("PlayerSpawnedNPC",     "Warden", function(ply, ent)    Warden.SetOwner(ent, ply) end)
	hook.Add("PlayerSpawnedSENT",    "Warden", function(ply, ent)    Warden.SetOwner(ent, ply) end)
	hook.Add("PlayerSpawnedSWEP",    "Warden", function(ply, ent)    Warden.SetOwner(ent, ply) end)
	hook.Add("PlayerSpawnedVehicle", "Warden", function(ply, ent)    Warden.SetOwner(ent, ply) end)

	hook.Add("EntityRemoved", "Warden", Warden.ClearOwner)

	hook.Add("GravGunPickupAllowed", "Warden", function(ply, ent)
		if not Warden.CheckPermission(ply, ent, Warden.PERMISSION_GRAVGUN) then
			return false
		end
	end)

	hook.Add("PlayerUse", "Warden", function(ply, ent)
		if USE_EXCEPTIONS[ent:GetClass()] or ent.AlwaysUsable then return end

		if not Warden.CheckPermission(ply, ent, Warden.PERMISSION_USE) then
			return false
		end
	end)

	hook.Add("EntityTakeDamage", "Warden", function(ent, dmg)
		if not ent or ent:IsWorld() then return end
		if not ent:IsPlayer() and Warden.GetOwner(ent) == game.GetWorld() then return end

		local attacker = dmg:GetAttacker()
		local inflictor = dmg:GetInflictor()
		local owner = Warden.GetOwner(inflictor)
		local entOwner = Warden.GetOwner(ent)
		local ValidAttacker = IsValid(attacker)

		-- fix fire damage
		if ValidAttacker and attacker:GetClass() == "entityflame" and IsValid(attacker:GetParent()) then
			attacker = attacker:GetParent():CPPIGetOwner()
			if attacker ~= nil then
				dmg:SetAttacker(attacker)
			end
		end

		-- Ignored damage types
		if ent:IsVehicle() then
			return
		end

		if ValidAttacker and attacker:IsPlayer() then
			-- Damage between players and players
			if ent:IsPlayer() and not Warden.CheckPermission(attacker, ent, Warden.PERMISSION_DAMAGE) then
				return true
			end

			-- Damage between players and props
			if IsValid(entOwner) and entOwner:IsPlayer() and not Warden.CheckPermission(attacker, ent, Warden.PERMISSION_DAMAGE) then
				return true
			end
		end

		-- Prevent crush damage / damage from the world
		if ent:IsPlayer() and attacker:IsWorld() or not ValidAttacker then
			return true
		end

		-- Damage between unknown attackers and their owners
		if IsValid(owner) and owner:IsPlayer() and not Warden.CheckPermission(owner, ent, Warden.PERMISSION_DAMAGE) then
			return true
		end
	end)

	hook.Add("CanEditVariable", "Warden", function(ent, ply)
		if not Warden.CheckPermission(ply, ent, Warden.PERMISSION_TOOL) then
			return false
		end
	end)

	hook.Add("OnPhysgunReload", "Warden", function(_, ply)
		local ent = ply:GetEyeTrace().Entity

		if not Warden.CheckPermission(ply, ent, Warden.PERMISSION_PHYSGUN) then
			return false
		end
	end)

	hook.Add("player_disconnect", "WardenPlayerDisconnect", function(data)
		local steamID = data.networkid
		Warden.Permissions[steamID] = nil

		if GetConVar("warden_freeze_disconnect"):GetBool() then
			Warden.FreezeEntities(steamID)
		end

		if GetConVar("warden_cleanup_disconnect"):GetBool() then
			local time = GetConVar("warden_cleanup_time"):GetInt()
			local name = data.name

			timer.Create("WardenCleanup#" .. steamID, time, 1, function()
				local count = Warden.CleanupEntities(steamID)
				hook.Run("WardenNaturalCleanup", name, time, steamID, count)
			end)
		end
	end)

	return
end

-- Ask server for permission info
hook.Add("InitPostEntity", "Warden", function()
	net.Start("WardenInitialize")
	net.SendToServer()
end)

net.Receive("WardenInitialize", function()
	local n = net.ReadUInt(8)
	for i = 1, n do
		local granter = net.ReadString()

		local o = net.ReadUInt(8)
		for j = 1, o do
			local permission = net.ReadUInt(8)

			local p = net.ReadUInt(8)
			for k = 1, p do
				local receiver = net.ReadString()

				Warden.SetupPlayer(granter)
				Warden.Permissions[granter][permission][receiver] = true
			end
		end
	end
end)

net.Receive("WardenAdminLevel", function()
	Warden.LocalAdminLevel = net.ReadUInt(8)
end)

net.Receive("WardenUpdatePermission", function()
	local granting = net.ReadBool()
	local permission = net.ReadUInt(8)
	local granter = net.ReadEntity()

	if not IsValid(granter) or not granter:IsPlayer() then
		return
	end

	granter:WardenEnsureSetup()

	if net.ReadBool() then
		Warden.Permissions[granter:SteamID()][permission]["global"] = granting
	else
		local receiver = net.ReadEntity()
		if IsValid(receiver) and receiver:IsPlayer() then
			Warden.Permissions[granter:SteamID()][permission][receiver:SteamID()] = granting
		end
	end
end)

local function networkPermission(receiver, permission, granting)
	net.Start("WardenUpdatePermission")
	net.WriteUInt(permission, 8)
	net.WriteBool(granting)
	if receiver then
		net.WriteBool(true)
		net.WriteEntity(receiver)
	else
		net.WriteBool(false)
	end
	net.SendToServer()
end

function Warden.GrantPermission(receiver, permission)
	networkPermission(receiver, permission, true)
end

function Warden.RevokePermission(receiver, permission)
	networkPermission(receiver, permission, false)
end

hook.Add("player_disconnect", "WardenPlayerDisconnect", function(data)
	local steamID = data.networkid
	Warden.Permissions[steamID] = nil
end)

