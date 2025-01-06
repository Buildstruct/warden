Warden.Ownership = Warden.Ownership or {}
Warden.Players = Warden.Players or {}
Warden.Names = Warden.Names or {}

local ENTITY = FindMetaTable("Entity")
local PLAYER = FindMetaTable("Player")

--- // getters // ---

-- get all entities owned by a player
-- the callback receives each ent and returns whether the ent should be added to the list
function Warden.GetOwnedEntities(plyOrID, callback)
	local tbl = Warden._GetPlayerTable(plyOrID)
	if table.IsEmpty(tbl) then return {} end

	local steamID = Warden.PossibleSteamID(plyOrID)
	if not steamID then return {} end

	callback = callback or function() return true end

	local _ents = {}
	for entID, _ in pairs(tbl) do
		local ent = Entity(entID)
		if not IsValid(ent) then
			tbl[entID] = nil
			continue
		end

		if Warden.GetOwnerID(ent) ~= steamID then
			tbl[entID] = nil
			continue
		end

		if callback(ent) then
			table.insert(_ents, ent)
		end
	end

	return _ents
end
function PLAYER:WardenGetOwnedEntities()
	return Warden.GetOwnedEntities(self)
end

-- get all entities of a specific class owned by a player
function Warden.GetOwnedEntitiesByClass(plyOrID, class)
	return Warden.GetOwnedEntities(plyOrID, function(ent)
		return ent:GetClass() == class
	end)
end
function PLAYER:WardenGetOwnedEntitiesByClass(class)
	return Warden.GetOwnedEntitiesByClass(self, class)
end

-- get the owner of an entity
function Warden.GetOwner(ent)
	local steamID = Warden.GetOwnerID(ent)
	if steamID then return Warden.GetPlayerFromSteamID(steamID) end
end
function ENTITY:WardenGetOwner()
	return Warden.GetOwner(self)
end

-- get the owner steamid of an entity
function Warden.GetOwnerID(ent)
	local valid, world = Warden.IsValid(ent)
	if not valid then return end

	if world then return "World" end
	if ent:IsPlayer() then return ent:SteamID() end

	local ownership = Warden._GetOwnerTable(ent)
	if ownership then return ownership.steamID end
end
function ENTITY:WardenGetOwnerID()
	return Warden.GetOwnerID(self)
end

-- get the owner name of an entity
function Warden.GetOwnerName(ent, fallback)
	local ownerID = Warden.GetOwnerID(ent)
	if not ownerID then return fallback end

	return Warden.GetNameFromSteamID(ownerID, fallback)
end
function ENTITY:WardenGetOwnerName(fallback)
	return Warden.GetOwnerName(self, fallback)
end

-- returns how many times an entity's owner has changed
-- possibly useful for debugging and sanity checks
function Warden.GetOwnerChanges(entOrID)
	local tbl = Warden._GetOwnerTable(entOrID)
	if not tbl then return 0 end -- never had an owner
	if not tbl.changes then return 1 end -- had its first owner

	return tbl.changes
end
function ENTITY:WardenGetOwnerChanges()
	return Warden.GetOwnerChanges(self)
end

--- // setters // ---
-- online other sections, superadmin clients do not get their setters networked

-- set an entity's owner to a player
-- id to entity must be valid serverside
-- will correctly set the owner if you instead supply the world, another entity, or nil
function Warden.SetOwner(entOrID, plyOrID)
	local entID = Warden.PossibleEntIndex(entOrID)
	if not entID then return false end

	if SERVER and not IsValid(Entity(entID)) then
		Warden.ClearOwner(entID)
		return true
	end

	local steamID = Warden.PossibleSteamID(plyOrID)
	if not steamID then
		if IsValid(plyOrID) or type(plyOrID) == "number" then
			Warden.ReplaceOwner(entOrID, plyOrID)
			return true
		end

		Warden.ClearOwner(entID)
		return true
	end

	if steamID == "" then
		Warden.ClearOwner(entID)
		return true
	end

	Warden.ClearOwner(entID, true)

	Warden.Ownership[entID] = { steamID = steamID }

	local ent = Entity(entID)
	if IsValid(ent) then
		Warden.Ownership[entID].changes = ent.WardenOwnerChanges
		ent.WardenOwnerChanges = nil
	end

	Warden.Players[steamID] = Warden.Players[steamID] or {}
	Warden.Players[steamID][entID] = true

	Warden._UpdateOwnerData(steamID, entID)

	if SERVER then
		Entity(entID):CallOnRemove("WardenOwnership", Warden.ClearOwner)
	end

	return true
end
function ENTITY:WardenSetOwner(plyOrID)
	Warden.SetOwner(self, plyOrID)
end

-- remove ownership from an entity
-- set noNetwork to true to disable server networking to clients
function Warden.ClearOwner(entOrID, noNetwork)
	local id = Warden.PossibleEntIndex(entOrID)
	if not id then return end

	local ownership = Warden.Ownership[id]
	if ownership then
		if Warden.Players[ownership.steamID] then
			Warden.Players[ownership.steamID][id] = nil

			if table.IsEmpty(Warden.Players[ownership.steamID]) then
				Warden.Players[ownership.steamID] = nil
			end
		end

		if Warden.Ownership[id] then
			local ent = Entity(id)
			if IsValid(ent) then
				ent.WardenOwnerChanges = Warden.Ownership[id].changes
			end

			Warden.Ownership[id] = nil
		end
	end

	if not noNetwork then
		Warden._UpdateOwnerData("None", id)
	end
end
function ENTITY:WardenClearOwner(noNetwork)
	Warden.ClearOwner(self, noNetwork)
end

-- set the owner of an entity as the world
-- id to entity must be valid serverside
function Warden.SetOwnerWorld(entOrID)
	Warden.SetOwner(entOrID, "World")
end
function ENTITY:WardenSetOwnerWorld()
	Warden.SetOwnerWorld(self)
end

-- replace an entity's owner with that of another entity's
function Warden.ReplaceOwner(from, to)
	if from == to then return end

	local fromID = Warden.PossibleEntIndex(from)
	if not fromID then return end

	local toID = Warden.PossibleEntIndex(to)
	if not toID then return end

	local ownership = Warden._GetOwnerTable(fromID)
	if not ownership then return end -- is ownerless

	Warden.SetOwner(toID, ownership.steamID)
end
function ENTITY:WardenReplaceOwner(to)
	Warden.SetOwner(self, to)
end

--- // internal // ---

-- either retrieve the entire owner table or the table of a single entity
-- intended to be internal
function Warden._GetOwnerTable(entOrID)
	if not entOrID then
		return Warden.Ownership
	end

	local id = Warden.PossibleEntIndex(entOrID)
	if not id then return end

	return Warden.Ownership[id]
end

-- get a list of entids that a player owns
-- intended to be internal
function Warden._GetPlayerTable(plyOrID)
	if not plyOrID then
		return Warden.Players
	end

	local id = Warden.PossibleSteamID(plyOrID)
	if not id then return {} end

	return Warden.Players[id] or {}
end