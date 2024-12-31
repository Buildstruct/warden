local cmd = {}
cmd.title = "Admin Level"
cmd.description = "Bypass Warden's restrictions."
cmd.author = "textstack"
cmd.timeCreated = "Monday, December 30 2024"
cmd.category = "Warden"
cmd.call = "al"
cmd.usage = "[level]"
cmd.server = function(ply, args)
    if table.IsEmpty(args) then
        ply:WardenSetAdminLevel(0)
        nadmin:Notify(ply, "Set your admin level to 0.")
        return
    end

    local num = tonumber(args[1])
    if not num then
        ply:WardenSetAdminLevel(0)
        nadmin:Notify(ply, "Set your admin level to 0.")
        return
    end

    ply:WardenSetAdminLevel(num)
    nadmin:Notify(ply, "Set your admin level to " .. num .. ".")
end