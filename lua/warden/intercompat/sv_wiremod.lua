hook.Add("PostGamemodeLoaded", "WardenWireCompat", function()
	if not WireLib then return end

	hook.Add("OnEntityCreated", "WardenCatchHolos", function(ent)
		if ent:GetClass() ~= "gmod_wire_hologram" then return end

		timer.Simple(0, function()
			if not IsValid(ent) then return end
			if not ent.steamid then return end

			Warden.SetOwner(ent, ent.steamid)
		end)
	end)
end)

function Warden.DisableChips(ply, errMsg)
	for _, v in ipairs(Warden.GetOwnedEntities(ply)) do
		if v:GetClass() == "gmod_wire_expression2" then
			v:Error(errMsg)
			v:Destruct()
		elseif v:GetClass() == "starfall_processor" then
			v:Error(errMsg)
		end
	end
end

hook.Add("PlayerDisconnected", "BS_HaltDisconnect", function(ply)
	if not Warden.GetServerBool("freeze_disconnect", true) then return end

	Warden.DisableChips(ply, "Owner disconnected")
end)