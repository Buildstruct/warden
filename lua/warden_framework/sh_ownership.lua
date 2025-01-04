local NET = {
	ALL_ENT = 0,
	ALL_PLY = 1,
	NEW_ENT = 2,
	NEW_PLY = 3,
	NEW_WORLD = 4,
	NEW_NONE = 5
}

local NET_SIZE_TYPE = 3
local NET_SIZE = 13
local WORLD_ID = "18446744073709551614"

Warden.Ownership = Warden.Ownership or {}
Warden.Players = Warden.Players or {}
Warden.Names = Warden.Names or {}
Warden.SteamIDMap = Warden.SteamIDMap or {}

local ENTITY = FindMetaTable("Entity")
local PLAYER = FindMetaTable("Player")

--- // helpers // ---

-- get the player entity from a steamid, does caching unlike gmod's version
function Warden.GetPlayerFromSteamID(steamID)
	if steamID == "World" then return game.GetWorld() end

	if not IsValid(Warden.SteamIDMap[steamID]) then
		Warden.SteamIDMap = {}
		for _, ply in player.Iterator() do
			Warden.SteamIDMap[ply:SteamID()] = ply
		end
	end

	return Warden.SteamIDMap[steamID]
end

-- get the name of a player with x steamid
function Warden.GetNameFromSteamID(steamID, fallback)
	if steamID == "World" then return "World" end
	return Warden.Names[steamID] or fallback
end

-- returns whether an entity is a valid owner
-- second term returns whether it is the world or not
function Warden.IsValidOwner(ent)
	if IsValid(ent) then
		return true, false
	end

	if ent and ent.IsWorld and ent:IsWorld() then
		return true, true
	end

	return false, false
end

-- get a steamid out of a var that might or might not be a player
function Warden.PossibleSteamID(plyOrID)
	if type(plyOrID) == "string" then return plyOrID end

	local valid, world = Warden.IsValidOwner(plyOrID)
	if world then return "World" end
	if valid and plyOrID:IsPlayer() then return plyOrID:SteamID() end
end

-- get an entindex out of a var that might or might not be an entity
function Warden.PossibleEntIndex(entOrID)
	if type(entOrID) == "number" then return entOrID end

	if not IsValid(entOrID) then return end
	return entOrID:EntIndex()
end

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
	local valid, world = Warden.IsValidOwner(ent)
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

-- set an entity's owner to a player
-- id to entity must be valid serverside
-- will correctly set the owner if you instead supply the world, another entity, or nil
function Warden.SetOwner(entOrID, plyOrID)
	local entID = Warden.PossibleEntIndex(entOrID)
	if not entID then return end

	if SERVER and not IsValid(Entity(entID)) then
		Warden.ClearOwner(entID)
		return
	end

	local steamID = Warden.PossibleSteamID(plyOrID)
	if not steamID then
		if IsValid(plyOrID) or type(plyOrID) == "number" then
			Warden.ReplaceOwner(entOrID, plyOrID)
			return
		end

		Warden.ClearOwner(entID)
		return
	end

	if steamID == "" then
		Warden.ClearOwner(entID)
		return
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

if SERVER then
	util.AddNetworkString("WardenOwnership")

	-- send everything
	-- intended to be internal, but it's global in case it's somehow needed
	function Warden._SendAllOwnerData(plys)
		net.Start("WardenOwnership")
		net.WriteUInt(NET.ALL_ENT, NET_SIZE_TYPE)

		net.WriteUInt(table.Count(Warden.Players), NET_SIZE)
		for k, v in pairs(Warden.Players) do
			local id = k == "World" and WORLD_ID or util.SteamIDTo64(k)
			net.WriteUInt64(id)

			net.WriteUInt(table.Count(v), NET_SIZE)
			for k1, _ in pairs(v) do
				net.WriteUInt(k1, NET_SIZE)
			end
		end

		if plys then
			net.Send(plys)
		else
			net.Broadcast()
		end

		net.Start("WardenOwnership")
		net.WriteUInt(NET.ALL_PLY, NET_SIZE_TYPE)

		net.WriteUInt(table.Count(Warden.Names), NET_SIZE)
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
			net.WriteUInt(NET.NEW_ENT, NET_SIZE_TYPE)

			net.WriteUInt(table.Count(toUpdate), NET_SIZE)
			for k, v in pairs(toUpdate) do
				local id = k == "World" and WORLD_ID or util.SteamIDTo64(k)
				net.WriteUInt64(id)

				net.WriteUInt(table.Count(v), NET_SIZE)
				for k1, _ in pairs(v) do
					net.WriteUInt(k1, NET_SIZE)
				end
			end

			net.Broadcast()
		end
		if not table.IsEmpty(toUpdateWorld) then
			net.Start("WardenOwnership")
			net.WriteUInt(NET.NEW_WORLD, NET_SIZE_TYPE)

			net.WriteUInt(table.Count(toUpdateWorld), NET_SIZE)
			for k, _ in pairs(toUpdateWorld) do
				net.WriteUInt(k, NET_SIZE)
			end

			net.Broadcast()
		end
		if not table.IsEmpty(toUpdateNone) then
			net.Start("WardenOwnership")
			net.WriteUInt(NET.NEW_NONE, NET_SIZE_TYPE)

			net.WriteUInt(table.Count(toUpdateNone), NET_SIZE)
			for k, _ in pairs(toUpdateNone) do
				net.WriteUInt(k, NET_SIZE)
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

	gameevent.Listen("player_activate")
	hook.Add("player_activate", "WardenSendName", function(data)
		local ply = Player(data.userid)

		Warden.Names[ply:SteamID()] = ply:Nick()

		net.Start("WardenOwnership")

		net.WriteUInt(NET.NEW_PLY, NET_SIZE_TYPE)
		net.WriteUInt64(util.SteamIDTo64(ply:SteamID()))
		net.WriteString(ply:Nick())

		net.SendOmit(ply)
	end)

	net.Receive("WardenOwnership", function(_, ply)
		Warden._SendAllOwnerData(ply)
	end)

	timer.Create("WardenSendAllOwnerData", 120, 0, Warden._SendAllOwnerData)

	return
end

-- dummy function for shared parity
-- intended to be internal
function Warden._UpdateOwnerData() end

-- ask the server for owner data
-- intended to be internal
function Warden._RequestAllOwnerData()
	net.Start("WardenOwnership")
	net.SendToServer()
end

local readNet
readNet = {
	[NET.ALL_ENT] = function()
		Warden.Ownership = {}
		Warden.Players = {}

		readNet[NET.NEW_ENT]()
	end,
	[NET.ALL_PLY] = function()
		Warden.Names = {}

		local count = net.ReadUInt(NET_SIZE)
		for i = 1, count do
			readNet[NET.NEW_PLY]()
		end
	end,
	[NET.NEW_ENT] = function()
		local entCount = net.ReadUInt(NET_SIZE)
		for i = 1, entCount do
			local sid64 = net.ReadUInt64()
			local steamID = sid64 == WORLD_ID and "World" or util.SteamIDFrom64(sid64)

			Warden.Players[steamID] = Warden.Players[steamID] or {}

			local entCount1 = net.ReadUInt(NET_SIZE)
			for j = 1, entCount1 do
				local entID = net.ReadUInt(NET_SIZE)
				Warden.SetOwner(entID, steamID)
			end
		end
	end,
	[NET.NEW_PLY] = function()
		local steamID = util.SteamIDFrom64(net.ReadUInt64())
		local name = net.ReadString()

		Warden.Names[steamID] = name
	end,
	[NET.NEW_WORLD] = function()
		local worldCount = net.ReadUInt(NET_SIZE)
		for i = 1, worldCount do
			local entID = net.ReadUInt(NET_SIZE)
			Warden.SetOwnerWorld(entID)
		end
	end,
	[NET.NEW_NONE] = function()
		local noneCount = net.ReadUInt(NET_SIZE)
		for i = 1, noneCount do
			local entID = net.ReadUInt(NET_SIZE)
			Warden.ClearOwner(entID)
		end
	end
}

net.Receive("WardenOwnership", function()
	readNet[net.ReadUInt(NET_SIZE_TYPE)]()
end)

hook.Add("InitPostEntity", "WardenGetOwnerData", function()
	timer.Simple(10, Warden._RequestAllOwnerData)
	Warden._RequestAllOwnerData()
end)