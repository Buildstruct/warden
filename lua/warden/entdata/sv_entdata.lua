util.AddNetworkString("WardenEntData")

local trackedEnts = {}

local function updateData(ent, pvs)
	local phys = ent:GetPhysicsObject()
	if phys:IsValid() then
		ent.Mass = phys:GetMass()
		ent.IsFrozen = not phys:IsMotionEnabled()
	else
		ent.Mass = 0
		ent.IsFrozen = false
	end

	net.Start("WardenEntData", true)
	net.WriteEntity(ent)
	net.WriteBool(ent.IsFrozen)
	net.WriteFloat(ent.Mass)

	if pvs then
		net.SendPVS(ent:GetPos())
	else
		net.Broadcast()
	end
end

hook.Add("OnEntityCreated", "WardenEntData", function(ent)
	timer.Simple(0, function()
		if not ent:IsValid() then return end

		trackedEnts[ent:EntIndex()] = ent
		updateData(ent)
		ent:SetNW2String("ServerClass", ent:GetClass())
	end)
end)

timer.Create("WardenTrackedEnts", 10, 0, function()
	for id, ent in pairs(trackedEnts) do
		if not ent:IsValid() then
			trackedEnts[id] = nil
			continue
		end

		updateData(ent)
	end
end)

local PING_KEYS = {
	[IN_ATTACK] = true,
	[IN_USE] = true,
	[IN_ATTACK2] = true,
	[IN_RELOAD] = true,
	[IN_WEAPON1] = true,
	[IN_WEAPON1] = true,
	[IN_ALT1] = true,
	[IN_ALT2] = true,
	[IN_GRENADE1] = true,
	[IN_GRENADE1] = true
}

hook.Add("KeyPress", "WardenEntData", function(ply, key)
	if not PING_KEYS[key] then return end

	local tr = ply:GetEyeTrace()
	local ent = tr.Entity
	if not ent:IsValid() then return end

	timer.Create("WardenEntDataPing_" .. ent:EntIndex(), 0, 1, function()
		if not ent:IsValid() then return end
		updateData(ent, true)
	end)
end)

hook.Add("PhysgunDrop", "WardenEntData", function(_, ent)
	timer.Create("WardenEntDataPing_" .. ent:EntIndex(), 0, 1, function()
		if not ent:IsValid() then return end
		updateData(ent, true)
	end)
end)