Warden = Warden or {}

AddCSLuaFile("warden/convars.lua")
include("warden/convars.lua")

AddCSLuaFile("warden/permissions.lua")
include("warden/permissions.lua")

AddCSLuaFile("warden/warden.lua")
include("warden/warden.lua")

AddCSLuaFile("warden/cppi.lua")
include("warden/cppi.lua")

AddCSLuaFile("warden/ownership.lua")
include("warden/ownership.lua")

AddCSLuaFile("warden/entinfo.lua")
if CLIENT then
    include("warden/entinfo.lua")
end

