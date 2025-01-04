if SAM_LOADED then
	return
end

local sam, command = sam, sam.command

command.set_category("Warden")

command.new("adminlevel")
:Aliases("al")
:SetPermission("adminlevel", "admin")
:Help("Bypass Warden's restrictions.")
:AddArg("number", { hint = "level", round = true, min = 0, max = 99, default = 0, optional = true})
:OnExecute(function(ply, level)
	ply:WardenSetAdminLevel(level)
	sam.player.send_message(ply, "Set your admin level to " .. level .. ".")
end)
:End()

command.new("cleanupdisconnected")
:Aliases("cupdis", "cupdisconnected", "cleanupdis")
:SetPermission("cleanupdisconnected", "admin")
:Help("Clean up all disconnected players' props.")
:OnExecute(function(ply)
	Warden.CleanupDisconnected()

	sam.player.send_message(nil, "{A} cleaned up all disconnected players' props.", {
		A = ply
	})
end)
:End()

command.new("cleanup")
:Aliases("cup")
:SetPermission("cleanup", "admin")
:AddArg("player")
:Help("Clean up players' props.")
:OnExecute(function(ply, targets)
	for _, v in ipairs(targets) do
		v:WardenCleanupEntities()
	end

	sam.player.send_message(nil, "{A} cleaned up {T}'s props.", {
		A = ply, T = targets
	})
end)
:End()

command.new("pfreezeprops")
:Aliases("pfz", "pfreezeprops")
:SetPermission("pfreezeprops", "admin")
:AddArg("player")
:Help("Freeze players' props.")
:OnExecute(function(ply, targets)
	for _, v in ipairs(targets) do
		v:WardenFreezeEntities()
	end

	sam.player.send_message(nil, "{A} froze {T}'s props.", {
		A = ply, T = targets
	})
end)
:End()

SetGlobalString("WardenCommands", "sam")