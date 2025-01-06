Warden.Ownership = Warden.Ownership or {}
Warden.Players = Warden.Players or {}
Warden.Names = Warden.Names or {}

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
	[Warden.OWNER_TYPE_NET.ALL_ENT] = function()
		Warden.Ownership = {}
		Warden.Players = {}

		readNet[Warden.OWNER_TYPE_NET.NEW_ENT]()
	end,
	[Warden.OWNER_TYPE_NET.ALL_PLY] = function()
		Warden.Names = {}

		local count = net.ReadUInt(Warden.OWNER_NET_SIZE)
		for i = 1, count do
			readNet[Warden.OWNER_TYPE_NET.NEW_PLY]()
		end
	end,
	[Warden.OWNER_TYPE_NET.NEW_ENT] = function()
		local entCount = net.ReadUInt(Warden.OWNER_NET_SIZE)
		for i = 1, entCount do
			local sid64 = net.ReadUInt64()
			local steamID = sid64 == Warden.WORLD_ID and "World" or util.SteamIDFrom64(sid64)

			Warden.Players[steamID] = Warden.Players[steamID] or {}

			local entCount1 = net.ReadUInt(Warden.OWNER_NET_SIZE)
			for j = 1, entCount1 do
				local entID = net.ReadUInt(Warden.OWNER_NET_SIZE)
				Warden.SetOwner(entID, steamID)
			end
		end
	end,
	[Warden.OWNER_TYPE_NET.NEW_PLY] = function()
		local steamID = util.SteamIDFrom64(net.ReadUInt64())
		local name = net.ReadString()

		Warden.Names[steamID] = name
	end,
	[Warden.OWNER_TYPE_NET.NEW_WORLD] = function()
		local worldCount = net.ReadUInt(Warden.OWNER_NET_SIZE)
		for i = 1, worldCount do
			local entID = net.ReadUInt(Warden.OWNER_NET_SIZE)
			Warden.SetOwnerWorld(entID)
		end
	end,
	[Warden.OWNER_TYPE_NET.NEW_NONE] = function()
		local noneCount = net.ReadUInt(Warden.OWNER_NET_SIZE)
		for i = 1, noneCount do
			local entID = net.ReadUInt(Warden.OWNER_NET_SIZE)
			Warden.ClearOwner(entID)
		end
	end
}

net.Receive("WardenOwnership", function()
	readNet[net.ReadUInt(Warden.OWNER_TYPE_NET_SIZE)]()
end)

hook.Add("InitPostEntity", "WardenGetOwnerData", function()
	timer.Simple(10, Warden._RequestAllOwnerData)
	Warden._RequestAllOwnerData()
end)