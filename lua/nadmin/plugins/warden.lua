-- this admin mod got poopoo design

local al = {}
al.title = "Admin Level"
al.description = "Bypass Warden's restrictions."
al.author = "textstack"
al.timeCreated = "Monday, December 30 2024"
al.category = "Warden"
al.call = "al"
al.usage = "[level]"
al.id = "warden_admin_level"
al.forcedPriv = true
al.server = function(ply, args)
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
    nadmin:Notify(ply, nadmin.colors.white, "Set your admin level to " .. num .. ".")
end

al.advUsage = {
    {
        text = "Admin level",
        type = "number"
    }
}

nadmin:RegisterCommand(al)

local cupdis = {}
cupdis.title = "Cleanup Disconnected"
cupdis.description = "Clean up all disconnected players' props."
cupdis.author = "textstack"
cupdis.timeCreated = "Saturday, January 4 2025"
cupdis.category = "Warden"
cupdis.call = "cupdis"
cupdis.id = "warden_cleanup_disconnected"
cupdis.forcedPriv = true
cupdis.server = function(ply)
    Warden.CleanupDisconnected()

    local myCol = nadmin:GetNameColor(caller) or nadmin.colors.blue

    nadmin:Notify(myCol, ply:GetName(), nadmin.colors.white, " cleaned up all disconnected players' props.")
end

nadmin:RegisterCommand(cupdis)

local cup = {}
cup.title = "Cleanup Props"
cup.description = "Clean up players' props."
cup.author = "textstack"
cup.timeCreated = "Saturday, January 4 2025"
cup.category = "Warden"
cup.call = "cleanup"
cup.usage = "<player>"
cup.id = "warden_cleanup_entities"
cup.forcedPriv = true
cup.server = function(ply, args)
    local targs = nadmin:FindPlayer(args[1], caller, nadmin.MODE_BELOW)
    if #targs > 0 then
        for i, targ in ipairs(targs) do
            targ:WardenCleanupEntities()
        end

        local myCol = nadmin:GetNameColor(caller) or nadmin.colors.blue

        local msg = {myCol, caller:Nick(), nadmin.colors.white, " cleaned up "}
        table.Add(msg, nadmin:FormatPlayerList(targs, "and"))
        table.Add(msg, {nadmin.colors.white, "'s props."})
        nadmin:Notify(unpack(msg))
    else
        nadmin:Notify(caller, nadmin.colors.red, nadmin.errors.noTargLess)
    end
end

cup.advUsage = {
    {
        type = "player",
        text = "Player"
    },
}

nadmin:RegisterCommand(cup)

local pfz = {}
pfz.title = "Freeze Props"
pfz.description = "Freeze players' props."
pfz.author = "textstack"
pfz.timeCreated = "Saturday, January 4 2025"
pfz.category = "Warden"
pfz.call = "pfreezeprops"
pfz.usage = "<player>"
pfz.id = "warden_freeze_entities"
pfz.forcedPriv = true
pfz.server = function(ply, args)
    local targs = nadmin:FindPlayer(args[1], caller, nadmin.MODE_BELOW)
    if #targs > 0 then
        for i, targ in ipairs(targs) do
            targ:WardenFreezeEntities()
        end

        local myCol = nadmin:GetNameColor(caller) or nadmin.colors.blue

        local msg = {myCol, caller:Nick(), nadmin.colors.white, " froze "}
        table.Add(msg, nadmin:FormatPlayerList(targs, "and"))
        table.Add(msg, {nadmin.colors.white, "'s props."})
        nadmin:Notify(unpack(msg))
    else
        nadmin:Notify(caller, nadmin.colors.red, nadmin.errors.noTargLess)
    end
end

pfz.advUsage = {
    {
        type = "player",
        text = "Player"
    },
}

nadmin:RegisterCommand(pfz)

SetGlobalString("WardenCommands", "nadmin")