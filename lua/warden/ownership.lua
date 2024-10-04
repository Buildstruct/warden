Warden.Ownership = Warden.Ownership or {}
Warden.Players = Warden.Players or {}
Warden.Names = Warden.Names or {}

local ENTITY = FindMetaTable("Entity")
local PLAYER = FindMetaTable("Player")

-- either retrieve the entire player table or the table of a single player
function Warden.GetPlayerTable(plyOrID)
	if not plyOrID then
		return Warden.Players
	end

	local id
	if type(plyOrID) == "string" then
		id = plyOrID
	else
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
	for entIndex, _ in pairs(tbl) do
		local entity = Entity(entIndex)
		if not IsValid(entity) then continue end

		table.insert(_ents, entity)
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
	for entIndex, _ in pairs(tbl) do
		local entity = Entity(entIndex)
		if IsValid(entity) and entity:GetClass() == class then
			table.insert(_ents, entity)
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
	return ownership and ownership.owner
end
function ENTITY:WardenGetOwner()
	return Warden.GetOwner(self)
end

-- get the owner steamid of an entity
function Warden.GetOwnerID(ent)
	local owner = Warden.GetOwner(ent)
	if owner then
		if owner:IsWorld() then return "World" end
		return owner:SteamID()
	end

	local ownership = Warden.GetOwnerTable(ent)
	return ownership and ownership.steamID
end
function ENTITY:WardenGetOwnerID()
	return Warden.GetOwnerID(self)
end

-- get the owner name of an entity
function Warden.GetOwnerName(ent, fallback)
	local owner = Warden.GetOwner(ent)
	if not owner then return fallback end
	if owner:IsWorld() then return "World" end

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

if SERVER then
	util.AddNetworkString("WardenOwnership")

	-- set an entity's owner to a player
	-- will correctly set the owner if you instead supply the world, another entity, or nil
	function Warden.SetOwner(ent, ply)
		if not IsValid(ent) then
			return
		end

		if ply and ply:IsWorld() then
			Warden.SetOwnerWorld(ent)
			return
		end

		if not IsValid(ply) then
			Warden.ClearOwner(ent)
			return
		end

		if not ply:IsPlayer() then
			Warden.ReplaceOwner(ent, ply)
			return
		end

		local index = ent:EntIndex()
		local steamID = ply:SteamID()

		-- Cleanup original ownership if has one
		if Warden.Ownership[index] then
			local lastOwner = Warden.Ownership[index]

			if Warden.Players[lastOwner.steamID] then
				Warden.Players[lastOwner.steamID][index] = nil
			end
		end

		Warden.Ownership[index] = {
			ent = ent,
			owner = ply,
			steamID = steamID
		}

		if not Warden.Players[steamID] then
			Warden.Players[steamID] = {}
		end

		Warden.Players[steamID][index] = true

		Warden.UpdateOwnerData(steamID, ent:EntIndex())
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

		Warden.SetOwner(to, id.owner)
	end
	function ENTITY:WardenReplaceOwner(to)
		Warden.SetOwner(self, to)
	end

	-- remove ownership from an entity
	function Warden.ClearOwner(ent)
		if not IsValid(ent) then return end

		local index = ent:EntIndex()
		local ownership = Warden.Ownership[index]
		if ownership then
			if Warden.Players[ownership.steamID] then
				Warden.Players[ownership.steamID][index] = nil
			end

			Warden.Ownership[index] = nil
		end

		Warden.UpdateOwnerData("None", ent:EntIndex())
	end
	function ENTITY:WardenClearOwner()
		Warden.ClearOwner(self)
	end

	-- set the owner of an entity as the world
	function Warden.SetOwnerWorld(ent)
		local world = game.GetWorld()
		local index = ent:EntIndex()

		-- Cleanup original ownership if has one
		if Warden.GetOwnerTable(index) then
			local lastOwner = Warden.Ownership[index]

			if Warden.Players[lastOwner.steamID] then
				Warden.Players[lastOwner.steamID][index] = nil
			end
		end

		Warden.Ownership[index] = {
			ent = ent,
			owner = world,
			steamID = "World",
		}

		Warden.UpdateOwnerData("World", ent:EntIndex())
	end
	function ENTITY:WardenSetOwnerWorld()
		Warden.SetOwnerWorld(self)
	end

	-- send everything
	-- intended to be internal, but it's global in case it's somehow needed
	function Warden.SendAllOwnerData(plys)
		net.Start("WardenOwnership")
		net.WriteUInt(0, 2)

		net.WriteUInt(table.Count(Warden.Players), 13)
		for k, v in pairs(Warden.Players) do
			net.WriteUInt64(util.SteamIDTo64(k))

			net.WriteUInt(table.Count(v), 13)
			for k1, _ in pairs(v) do
				net.WriteUInt(k1, 13)
			end
		end

		if plys then
			net.Send(plys)
		else
			net.Broadcast()
		end

		net.Start("WardenOwnership")
		net.WriteUInt(3, 2)

		net.WriteUInt(table.Count(Warden.Names), 13)
		for k, v in pairs(Warden.names) do
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
		net.Start("WardenOwnership")
		net.WriteUInt(1, 2)

		net.WriteUInt(table.Count(toUpdate), 13)
		for k, v in pairs(toUpdate) do
			net.WriteUInt64(util.SteamIDTo64(k))

			net.WriteUInt(table.Count(v), 13)
			for k1, _ in pairs(v) do
				net.WriteUInt(k1, 13)
			end
		end

		net.WriteUInt(table.Count(toUpdateWorld), 13)
		for k, _ in pairs(toUpdateWorld) do
			net.WriteUInt(k, 13)
		end

		net.WriteUInt(table.Count(toUpdateNone), 13)
		for k, _ in pairs(toUpdateNone) do
			net.WriteUInt(k, 13)
		end

		net.Broadcast()
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
			net.WriteUInt(2, 2)
			net.WriteUInt64(util.SteamIDTo64(ply:SteamID()))
			net.WriteString(ply:Nick())
		net.SendOmit(ply)

		Warden.SendAllOwnerData(ply)
	end)

	return
end

--TODO: networking