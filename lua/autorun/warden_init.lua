Warden = Warden or {}

if SERVER then
	file.CreateDir("warden")
	resource.AddSingleFile("materials/warden/tool.png")
	resource.AddSingleFile("materials/warden/physgun.png")
	resource.AddSingleFile("materials/warden/gravgun.png")
	resource.AddSingleFile("materials/warden/use.png")
	resource.AddSingleFile("materials/warden/damage.png")
	resource.AddSingleFile("materials/warden/acf.png")
end

local function addFile(File, directory)
	local prefix = string.lower(string.Left(File, 3))

	if SERVER and prefix == "sv_" then
		--include server
		include(directory .. File)
	elseif prefix == "sh_" then
		--include server and add to client
		if SERVER then
			AddCSLuaFile(directory .. File)
		end
		include(directory .. File)
	elseif prefix == "cl_" then
		--add to client and include in client
		if SERVER then
			AddCSLuaFile(directory .. File)
		elseif CLIENT then
			include(directory .. File)
		end
	end
end

--load directories
local includeDir
includeDir = function(directory)
	directory = directory .. "/"

	--finds files and folders in the directory
	local files, directories = file.Find(directory .. "*", "LUA")

	--for each file, add the file
	for _, v in ipairs(files) do
		if string.EndsWith(v, ".lua") then
			addFile(v, directory)
		end
	end

	--for each directory found, do this function again
	for _, v in ipairs(directories) do
		includeDir(directory .. v)
	end
end

includeDir("warden_framework")
includeDir("warden")

WARDEN_LOADED = true