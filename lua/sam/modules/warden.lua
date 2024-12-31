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