function Warden.DisableChips(ply, errMsg)
	for _, v in ipairs(Warden.GetOwnedEntities(ply)) do
		if v:GetClass() == "gmod_wire_expression2" then
			v:Error(errMsg)
			v:Destruct()
		elseif v:GetClass() == "starfall_processor" then
			v:Destroy()
		end
	end
end

hook.Add("PlayerDisconnected", "WardenHaltDisconnect", function(ply)
	if not Warden.GetServerBool("freeze_disconnect", true) then return end

	Warden.DisableChips(ply, "Owner disconnected")
end)