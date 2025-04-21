local al = ulx.command("Warden", "ulx adminlevel", function(ply, level)
    ply:WardenSetAdminLevel(level)
    ulx.fancyLogAdmin(ply, { ply }, "Set your admin level to " .. level .. ".")
end, "!al", true)
al:addParam({ type = ULib.cmds.NumArg, min = 0, max = 99, default = 0, ULib.cmds.optional })
al:defaultAccess(ULib.ACCESS_ADMIN)
al:help("Bypass Warden's restrictions.")

local cupdis = ulx.command("Warden", "ulx cupdis", function(ply)
    Warden.CleanupDisconnected()
    ulx.fancyLogAdmin(ply, "#A cleaned up all disconnected players' props.")
end, "!cupdis", true)
cupdis:defaultAccess(ULib.ACCESS_ADMIN)
cupdis:help("Clean up all disconnected players' props.")

local cup = ulx.command("Warden", "ulx cleanup", function(ply, targets)
    for _, v in ipairs(targets) do
        v:WardenCleanupEntities()
    end

    ulx.fancyLogAdmin(ply, "#A cleaned up #T's props.", targets)
end, "!cleanup", true)
cup:addParam({ type = ULib.cmds.PlayersArg })
cup:defaultAccess(ULib.ACCESS_ADMIN)
cup:help("Clean up players' props.")

local pfz = ulx.command("Warden", "ulx pfreezeprops", function(ply, targets)
    for _, v in ipairs(targets) do
        v:WardenFreezeEntities()
    end

    ulx.fancyLogAdmin(ply, "#A froze #T's props.", targets)
end, "!pfreezeprops", true)
pfz:addParam({ type = ULib.cmds.PlayersArg })
pfz:defaultAccess(ULib.ACCESS_ADMIN)
pfz:help("Freeze players' props.")

if CLIENT then return end
SetGlobalString("WardenCommands", "ulx")