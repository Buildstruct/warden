util.AddNetworkString("WardenOwnership")

Warden.Ownership = Warden.Ownership or {}
Warden.Players = Warden.Players or {}
Warden.Names = Warden.Names or {}

-- send everything
-- intended to be internal, but it's global in case it's somehow needed
function Warden._SendAllOwnerData(plys)
	net.Start("WardenOwnership")
	net.WriteUInt(Warden.OWNER_TYPE_NET.ALL_ENT, Warden.OWNER_TYPE_NET_SIZE)

	net.WriteUInt(table.Count(Warden.Players), Warden.OWNER_NET_SIZE)
	for k, v in pairs(Warden.Players) do
		local id = k == "World" and Warden.WORLD_ID or util.SteamIDTo64(k)
		net.WriteUInt64(id)

		net.WriteUInt(table.Count(v), Warden.OWNER_NET_SIZE)
		for k1, _ in pairs(v) do
			net.WriteUInt(k1, Warden.OWNER_NET_SIZE)
		end
	end

	if plys then
		net.Send(plys)
	else
		net.Broadcast()
	end

	net.Start("WardenOwnership")
	net.WriteUInt(Warden.OWNER_TYPE_NET.ALL_PLY, Warden.OWNER_TYPE_NET_SIZE)

	net.WriteUInt(table.Count(Warden.Names), Warden.OWNER_NET_SIZE)
	for k, v in pairs(Warden.Names) do
		net.WriteUInt64(util.SteamIDTo64(k))
		net.WriteString(v)
	end

	if plys then
		net.Send(plys)
	else
		net.Broadcast()
	end
end

local toUpdate = {}
local toUpdateWorld = {}
local toUpdateNone = {}

local function updateOwnerData()
	if not table.IsEmpty(toUpdate) then
		net.Start("WardenOwnership")
		net.WriteUInt(Warden.OWNER_TYPE_NET.NEW_ENT, Warden.OWNER_TYPE_NET_SIZE)

		net.WriteUInt(table.Count(toUpdate), Warden.OWNER_NET_SIZE)
		for k, v in pairs(toUpdate) do
			local id = k == "World" and Warden.WORLD_ID or util.SteamIDTo64(k)
			net.WriteUInt64(id)

			net.WriteUInt(table.Count(v), Warden.OWNER_NET_SIZE)
			for k1, _ in pairs(v) do
				net.WriteUInt(k1, Warden.OWNER_NET_SIZE)
			end
		end

		net.Broadcast()
	end
	if not table.IsEmpty(toUpdateWorld) then
		net.Start("WardenOwnership")
		net.WriteUInt(Warden.OWNER_TYPE_NET.NEW_WORLD, Warden.OWNER_TYPE_NET_SIZE)

		net.WriteUInt(table.Count(toUpdateWorld), Warden.OWNER_NET_SIZE)
		for k, _ in pairs(toUpdateWorld) do
			net.WriteUInt(k, Warden.OWNER_NET_SIZE)
		end

		net.Broadcast()
	end
	if not table.IsEmpty(toUpdateNone) then
		net.Start("WardenOwnership")
		net.WriteUInt(Warden.OWNER_TYPE_NET.NEW_NONE, Warden.OWNER_TYPE_NET_SIZE)

		net.WriteUInt(table.Count(toUpdateNone), Warden.OWNER_NET_SIZE)
		for k, _ in pairs(toUpdateNone) do
			net.WriteUInt(k, Warden.OWNER_NET_SIZE)
		end

		net.Broadcast()
	end

	toUpdate = {}
	toUpdateWorld = {}
	toUpdateNone = {}
end

-- send a new owner entry to everyone
-- intended to be internal, but it's global in case it's somehow needed
function Warden._UpdateOwnerData(steamID, entID)
	toUpdateNone[entID] = nil
	toUpdateWorld[entID] = nil
	for _, v in pairs(toUpdate) do
		v[entID] = nil
	end

	if steamID == "World" then
		toUpdateWorld[entID] = true
	elseif steamID == "None" then
		toUpdateNone[entID] = true
	else
		toUpdate[steamID] = toUpdate[steamID] or {}
		toUpdate[steamID][entID] = true
	end

	timer.Create("WardenSendOwnerData", 0, 1, updateOwnerData)
end

local function sendNick(ply)
	Warden.Names[ply:SteamID()] = ply:Nick()

	net.Start("WardenOwnership")

	net.WriteUInt(Warden.OWNER_TYPE_NET.NEW_PLY, Warden.OWNER_TYPE_NET_SIZE)
	net.WriteUInt64(util.SteamIDTo64(ply:SteamID()))
	net.WriteString(ply:Nick())
end

gameevent.Listen("player_activate")
hook.Add("player_activate", "WardenSendName", function(data)
	local ply = Player(data.userid)

	sendNick(ply)
	net.SendOmit(ply)
end)

timer.Create("WardenFixNames", 30, 0, function()
	for _, ply in player.Iterator() do
		if Warden.Names[ply:SteamID()] == ply:Nick() then continue end

		sendNick(ply)
		net.Broadcast()
	end
end)

net.Receive("WardenOwnership", function(_, ply)
	Warden._SendAllOwnerData(ply)
end)

timer.Create("WardenSendAllOwnerData", 120, 0, Warden._SendAllOwnerData)

-- // ownership setting // --

local ENTITY = FindMetaTable("Entity")
local PLAYER = FindMetaTable("Player")

local function setInitialOwner(ent)
	local owner = ent:GetInternalVariable("m_hOwnerEntity") or NULL

	if owner == NULL then
		owner = ent:GetInternalVariable("m_hOwner") or NULL
	end

	if owner == NULL then
		owner = ent:GetParent() or NULL
	end

	if owner == NULL then
		owner = ent:GetMoveParent() or NULL
	end

	if owner == NULL then
		Warden.SetOwnerWorld(ent)
	else
		Warden.SetOwner(ent, owner)
	end
end

hook.Add("OnEntityCreated", "Warden", function(ent)
	timer.Simple(0, function()
		if not ent:IsValid() then return end

		if ent:CreatedByMap() then
			Warden.SetOwnerWorld(ent)
			return
		end

		if ent:GetClass() == "gmod_wire_hologram" and ent.steamid then
			Warden.SetOwner(ent, ent.steamid)
			return
		end

		if not Warden.GetOwner(ent) then
			setInitialOwner(ent)
		end
	end)
end)

hook.Add("PlayerInitialSpawn", "Warden", function(ply)
	for entIndex, _ in pairs(Warden._GetPlayerTable(ply)) do
		Warden.SetOwner(Entity(entIndex), ply)
	end

	timer.Remove("WardenCleanup#" .. ply:SteamID())
end)

-- Detours

if ENTITY.SetOwner then
	Warden.BackupEntSetOwner = Warden.BackupEntSetOwner or ENTITY.SetOwner
	function ENTITY:SetOwner(ent)
		Warden.SetOwner(self, ent)
		Warden.BackupEntSetOwner(self, ent)
	end
end

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

hook.Add("PlayerSpawnedEffect",  "Warden", function(ply, _, ent) Warden.SetOwner(ent, ply) end)
hook.Add("PlayerSpawnedProp",    "Warden", function(ply, _, ent) Warden.SetOwner(ent, ply) end)
hook.Add("PlayerSpawnedRagdoll", "Warden", function(ply, _, ent) Warden.SetOwner(ent, ply) end)
hook.Add("PlayerSpawnedNPC",     "Warden", function(ply, ent)    Warden.SetOwner(ent, ply) end)
hook.Add("PlayerSpawnedSENT",    "Warden", function(ply, ent)    Warden.SetOwner(ent, ply) end)
hook.Add("PlayerSpawnedSWEP",    "Warden", function(ply, ent)    Warden.SetOwner(ent, ply) end)
hook.Add("PlayerSpawnedVehicle", "Warden", function(ply, ent)    Warden.SetOwner(ent, ply) end)

hook.Add("EntityRemoved", "Warden", Warden.ClearOwner)
