--[[
	██████╗ ███████╗ █████╗ 
	██╔══██╗██╔════╝██╔══██╗
	██████╔╝███████╗███████║
	██╔══██╗╚════██║██╔══██║
	██████╔╝███████║██║  ██║
	╚═════╝ ╚══════╝╚═╝  ╚═╝
	BSA Warden Commands
]]
    
local commands = BSA.Commands
local repr = BSA.Repr
local plugin = {}
plugin.description = "BSA warden integration"
plugin.config = {
	alias = "warden",
	permissions = {"warden.admin"}
}
plugin.client_config = {
	alias = "warden",
	permissions = {"warden.admin"}
}
plugin.permissions = {"warden.admin"}

function plugin:constructor()
	-- BSA Warden Category

    local group = commands:group("warden")
        :description("Warden integration")
        :flattenize(true)

    local function multi_target(invoker, targets, callback, response)
        local found = {}
        for i = 1, #targets do
            local target = targets[i]
            invoker:can(target, function(can)
                if not IsValid(target) then return end

                if can then
                    found[#found+1] = target
                    callback(target)
                end

                if i == #targets then
                    if #found > 0 then
                        local txt = {}
                        for i=1, #found do
                            txt[#txt+1] = found[i]
                            if i ~= #found then
                                txt[#txt+1] = ", "
                            end
                        end
                        response(found, txt)
                    else
                        invoker:reply(language:phrase("#commands.fun.responses.no_targets"))
                    end
                end
            end)
        end
    end
    group.multi_target = multi_target

    local function format_reply(invoker, ...)
        local entity = (not invoker:serverless() and invoker.entity) and invoker.entity or invoker:username()
        invoker:reply(...)
        if invoker.silent then
            local message = commands:repr(entity, " ", ...)
            if invoker:issilent() then
                local h, s, v = ColorToHSV(BSA.Accent)
                v = v / 2
                message:insert("[", HSVToColor(h, s, v), "Silent", BSA.log.__white, "] ")
            end
            message:watermark()
            message:exclude(invoker.entity)
            message:permission("commands.silent.visible")
            return
        end
        commands:repr(entity, " ", ...)
            :watermark()
            :exclude(invoker.entity)
            :broadcast()
    end
    group.format_reply = format_reply

    group:add("adminlevel")
        :alias("al")
        :permission("warden.admin")
        :description("Set your admin level")
        :argument("number", {default = 0, min = 0, max = 3})
        :callback(function(invoker, level)
            local entity = invoker.entity

            entity:WardenSetAdminLevel(level)
            commands:repr("Set your admin level to " .. level .. ".")
                :watermark()
                :send(entity)
        end)

    group:add("cleanupdisconnected")
        :alias("cupdis", "cupdisconnected", "cleanupdis")
        :permission("warden.admin")
        :description("Clean up disconnected player props")
        :callback(function(invoker)
            local entity = invoker.entity
            Warden.CleanupDisconnected()

            commands:repr(entity, " cleaned up all disconnected players' props.")
                :watermark()
                :broadcast()
        end)

    group:add("cleanup")
        :alias("cup")
        :playeronly()
        :permission("warden.admin")
        :description("Clean up a player's props")
        :argument("player", {})
        :callback(function(invoker, targets)
            multi_target(invoker, targets, function(target)
                target:WardenCleanupEntities()

            end, function(targets, formatted)
                format_reply(invoker, "cleaned up ", unpack(formatted), "'s props.")
            end)
        end)

    group:add("pfreezeprops")
        :alias("pfz")
        :playeronly()
        :permission("warden.admin")
        :description("Freeze players' props.")
        :argument("player", {})
        :callback(function(invoker, targets)
            multi_target(invoker, targets, function(target)
                target:WardenFreezeEntities()

            end, function(targets, formatted)
                format_reply(invoker, "froze ", unpack(formatted), "'s props.")
            end)
        end)
end

function plugin:destructor()
	commands:remove("warden")
    self.forcedPlayers = nil
end

BSA.Plugins:add("warden", plugin)

SetGlobalString("WardenCommands", "bsa")