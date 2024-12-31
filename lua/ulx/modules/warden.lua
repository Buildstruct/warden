local al = ulx.command("Warden", "ulx adminlevel", function(ply, level)
    ply:WardenSetAdminLevel(level)
    ulx.fancyLogAdmin(ply, { ply }, "Set your admin level to " .. level .. ".")
end, "!al", true)
al:addParam({ type = ULib.cmds.NumArg, min = 0, max = 99, default = 0, ULib.cmds.optional })
al:defaultAccess(ULib.ACCESS_ADMIN)