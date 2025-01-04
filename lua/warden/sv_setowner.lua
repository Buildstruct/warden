local PLAYER = FindMetaTable("Player")

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
	for entIndex, _ in pairs(Warden._GetPlayerTable(ply)) do
		Warden.SetOwner(Entity(entIndex), ply)
	end

	timer.Remove("WardenCleanup#" .. ply:SteamID())
end)

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

hook.Add("PlayerSpawnedEffect",  "Warden", function(ply, _, ent) Warden.SetOwner(ent, ply) end)
hook.Add("PlayerSpawnedProp",    "Warden", function(ply, _, ent) Warden.SetOwner(ent, ply) end)
hook.Add("PlayerSpawnedRagdoll", "Warden", function(ply, _, ent) Warden.SetOwner(ent, ply) end)
hook.Add("PlayerSpawnedNPC",     "Warden", function(ply, ent)    Warden.SetOwner(ent, ply) end)
hook.Add("PlayerSpawnedSENT",    "Warden", function(ply, ent)    Warden.SetOwner(ent, ply) end)
hook.Add("PlayerSpawnedSWEP",    "Warden", function(ply, ent)    Warden.SetOwner(ent, ply) end)
hook.Add("PlayerSpawnedVehicle", "Warden", function(ply, ent)    Warden.SetOwner(ent, ply) end)

hook.Add("EntityRemoved", "Warden", Warden.ClearOwner)