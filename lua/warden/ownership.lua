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

-- get the player entity from a steamid, does caching unlike gmod's version
function Warden.GetPlayerFromSteamID(steamID)
	if steamID == "World" then return game.GetWorld() end

	if not Warden.SteamIDMap[steamID] then
		Warden.SteamIDMap = {}
		for _, ply in player.Iterator() do
			Warden.SteamIDMap[ply:SteamID()] = ply
		end
	end

	return Warden.SteamIDMap[steamID]
end

-- returns whether an entity is a valid owner
-- second term returns whether it is valid according to IsValid
function Warden.IsValidOwner(ent)
	if IsValid(ent) then
		return true, true
	end

	if ent and ent.IsWorld and ent:IsWorld() then
		return true, false
	end

	return false, false
end

-- either retrieve the entire player table or the table of a single player
function Warden.GetPlayerTable(plyOrID)
	if not plyOrID then
		return Warden.Players
	end

	local id
	if type(plyOrID) == "string" then
		id = plyOrID
	else
		if not IsValid(plyOrID) then return {} end
		id = plyOrID:SteamID()
	end

	return Warden.Players[id] or {}
end
function PLAYER:WardenGetPlayerTable()
	return Warden.GetPlayerTable(self)
end

-- get all entities owned by a player
function Warden.GetOwnedEntities(plyOrID)
	local tbl = Warden.GetPlayerTable(plyOrID)

	local _ents = {}
	for entID, _ in pairs(tbl) do
		local ent = Entity(entID)
		if not IsValid(ent) then
			tbl[entID] = nil
			continue
		end

		table.insert(_ents, ent)
	end

	return _ents
end
function PLAYER:WardenGetOwnedEntities()
	return Warden.GetOwnedEntities(self)
end

-- get all entities owned by a player of a specific class
function Warden.GetOwnedEntitiesByClass(plyOrID, class)
	local tbl = Warden.GetPlayerTable(plyOrID)

	local _ents = {}
	for entID, _ in pairs(tbl) do
		local ent = Entity(entID)
		if not IsValid(ent) then
			tbl[entID] = nil
			continue
		end

		if ent:GetClass() == class then
			table.insert(_ents, ent)
		end
	end

	return _ents
end
function PLAYER:WardenGetOwnedEntitiesByClass(class)
	return Warden.GetOwnedEntitiesByClass(self, class)
end

-- either retrieve the entire owner table or the table of a single entity
function Warden.GetOwnerTable(entOrID)
	if not entOrID then
		return Warden.Ownership
	end

	local id
	if type(entOrID) == "number" then
		id = entOrID
	else
		if not IsValid(entOrID) then return {} end
		id = entOrID:EntIndex()
	end

	return Warden.Ownership[id]
end
function ENTITY:WardenGetOwnerTable()
	return Warden.GetOwnerTable(self)
end

-- get the owner of an entity
function Warden.GetOwner(ent)
	if not IsValid(ent) then
		if ent == nil or not ent.IsWorld then return end
		if ent:IsWorld() then return ent end
		return
	end

	if ent:IsPlayer() then return ent end

	local ownership = Warden.GetOwnerTable(ent)
	return ownership and Warden.GetPlayerFromSteamID(ownership.steamID)
end
function ENTITY:WardenGetOwner()
	return Warden.GetOwner(self)
end

-- get the owner steamid of an entity
function Warden.GetOwnerID(ent)
	local owner = Warden.GetOwner(ent)
	if owner then
		if owner.IsWorld and owner:IsWorld() then return "World" end
		if IsValid(owner) then return owner:SteamID() end
	end

	local ownership = Warden.GetOwnerTable(ent)
	return ownership and ownership.steamID
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

-- get the name of a player with x steamid
function Warden.GetNameFromSteamID(steamID, fallback)
	if steamID == "World" then return "World" end
	return Warden.Names[steamID] or fallback
end

-- set an entity's owner to a player
-- will correctly set the owner if you instead supply the world, another entity, or nil
function Warden.SetOwner(entOrID, plyOrID)
	local entID, steamID

	if type(plyOrID) == "string" then
		steamID = plyOrID
	else
		if plyOrID and plyOrID.IsWorld and plyOrID:IsWorld() then
			Warden.SetOwnerWorld(entOrID)
			return
		end

		if not IsValid(plyOrID) then
			Warden.ClearOwner(entOrID)
			return
		end

		if not plyOrID:IsPlayer() then
			Warden.ReplaceOwner(entOrID, plyOrID)
			return
		end

		steamID = plyOrID:SteamID()
	end

	if type(entOrID) == "number" then
		if SERVER and not IsValid(Entity(entOrID)) then
			Warden.ClearOwner(entOrID)
			return
		end

		entID = entOrID
	else
		if not IsValid(entOrID) then return end
		entID = entOrID:EntIndex()
	end

	if steamID == "World" then
		Warden.SetOwnerWorld(entID)
		return
	end

	if steamID == "" then
		Warden.ClearOwner(entID)
		return
	end

	Warden.ClearOwner(entID, true)

	Warden.Ownership[entID] = {
		steamID = steamID
	}

	Warden.Players[steamID] = Warden.Players[steamID] or {}
	Warden.Players[steamID][entID] = true

	Warden.UpdateOwnerData(steamID, entID)

	if SERVER then
		Entity(entID):CallOnRemove("WardenOwnership", Warden.ClearOwner)
	end
end
function ENTITY:WardenSetOwner(ply)
	Warden.SetOwner(self, ply)
end

-- replace an entity's owner with that of another entity's
function Warden.ReplaceOwner(from, to)
	if not IsValid(from) or from:IsPlayer() then return end
	if not IsValid(to) or to:IsPlayer() then return end

	local id = Warden.GetOwnerTable(from)
	if not id then return end -- is ownerless

	Warden.SetOwner(to, Warden.GetPlayerFromSteamID(id.steamID))
end
function ENTITY:WardenReplaceOwner(to)
	Warden.SetOwner(self, to)
end

-- remove ownership from an entity
function Warden.ClearOwner(entOrID, noNetwork)
	local id
	if type(entOrID) == "number" then
		id = entOrID
	else
		if not IsValid(entOrID) then return end
		id = entOrID:EntIndex()
	end

	local ownership = Warden.Ownership[id]
	if ownership then
		if Warden.Players[ownership.steamID] then
			Warden.Players[ownership.steamID][id] = nil

			if table.IsEmpty(Warden.Players[ownership.steamID]) then
				Warden.Players[ownership.steamID] = nil
			end
		end

		Warden.Ownership[id] = nil
	end

	if not noNetwork then
		Warden.UpdateOwnerData("None", id)
	end
end
function ENTITY:WardenClearOwner()
	Warden.ClearOwner(self)
end

-- set the owner of an entity as the world
function Warden.SetOwnerWorld(entOrID)
	local id
	if type(entOrID) == "number" then
		if SERVER and not IsValid(Entity(EntOrID)) then
			Warden.ClearOwner(id)
			return
		end

		id = entOrID
	else
		if not IsValid(entOrID) then return end
		id = entOrID:EntIndex()
	end

	Warden.ClearOwner(id, true)

	Warden.Ownership[id] = {
		steamID = "World",
	}

	Warden.Players["World"] = Warden.Players["World"] or {}
	Warden.Players["World"][id] = true

	Warden.UpdateOwnerData("World", id)

	if SERVER then
		Entity(id):CallOnRemove("WardenOwnership", Warden.ClearOwner)
	end
end
function ENTITY:WardenSetOwnerWorld()
	Warden.SetOwnerWorld(self)
end

if SERVER then
	util.AddNetworkString("WardenOwnership")

	-- send everything
	-- intended to be internal, but it's global in case it's somehow needed
	function Warden.SendAllOwnerData(plys)
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
	function Warden.UpdateOwnerData(steamID, entID)
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
		Warden.SendAllOwnerData(ply)
	end)

	timer.Create("WardenSendAllOwnerData", 120, 0, Warden.SendAllOwnerData)

	return
end

-- dummy function for shared parity
function Warden.UpdateOwnerData() end

-- ask the server for owner data
function Warden.RequestAllOwnerData()
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
	timer.Simple(10, Warden.RequestAllOwnerData)
	Warden.RequestAllOwnerData()
end)