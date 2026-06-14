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
plugin.description = "Warden commands and integration for BSA"
plugin.config = {
	alias = "warden",
	permissions = {"warden.admin"},
    sync = true
}
plugin.client_config = {
	alias = "warden",
	permissions = {"warden.admin"}
}
plugin.permissions = {"warden.admin"}

function plugin:constructor()
	-- BSA Warden Category

    do local en = self.language:add("container", "en")
        en:add("string", "group_description", { default = "Warden integration" })
        en:add("string", "adminlevel_description", { default = "Set your admin level" })
        en:add("string", "adminlevel_invoker_reply", { default = "You set your admin level to %d." })
        en:add("string", "adminlevel_command_reply", { default = " set their admin level to %d." })
        
        en:add("string", "cupdis_description", { default = "Clean up disconnected player props" })
        en:add("string", "cupdis_invoker_reply", { default = "You cleaned up all disconnected players' props." })
        en:add("string", "cupdis_command_reply", { default = " cleaned up all disconnected players' props." })
        
        en:add("string", "cup_description", { default = "Clean up a player's props" })
        en:add("string", "cup_reply", { default = "cleaned up %s's props." })
    end

    local language = self.language

    local group = commands:group("warden")
        :description(language:phrase("#group_description"))
        :flattenize(true)

    group:add("adminlevel")
        :alias("al")
        :permission("warden.admin")
        :description(language:phrase("#en.adminlevel_description"))
        :argument("number", {default = 0, min = 0, max = 3})
        :callback(function(invoker, level)
            invoker.entity:WardenSetAdminLevel(level)
            
            invoker:reply(language:phrase("#en.adminlevel_invoker_reply", level))
            commands:repr(language:phrase("#en.adminlevel_command_reply", level))
                :watermark()
                :send(entity)
        end)

    group:add("cleanupdisconnected")
        :alias("cupdis", "cupdisconnected", "cleanupdis")
        :permission("warden.admin")
        :description(language:phrase("#en.cupdis_description"))
        :callback(function(invoker)
            Warden.CleanupDisconnected()

            invoker:reply(language:phrase("en.cupdis_invoker_reply"))
            commands:repr(invoker.entity, language:phrase("en.cupdis_command_reply"))
                :watermark()
                :broadcast()
        end)

    group:add("cleanup")
        :alias("cup")
        :playeronly()
        :permission("warden.admin")
        :description(language:phrase("#en.cup_description"))
        :argument("player", {})
        :callback(function(invoker, targets)
            invoker:multi_target(targets, function(target)
                target:WardenCleanupEntities()
                
            end, function(targets)
                local names = {}
                for _, v in ipairs(targets) do 
                    if not IsValid(v) then continue end 
                    names[#names + 1] = v:Name() 
                end

                invoker:reply_all(language:phrase("#en.cup_reply", table.concat(names, ", ")))
            end)
        end)
end

function plugin:destructor()
	commands:remove("warden")
end

BSA.Plugins:add("warden", plugin)

SetGlobalString("WardenCommands", "bsa")