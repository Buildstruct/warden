-- localize a string
-- we autoconvert the key because gmod doesn't let us get the english
-- and i would really like the default to be english
local keys = {}
function Warden.L(str, ...)
	local key
	if keys[str] then
		key = keys[str]
	else
		key = string.gsub(str, "%s", "_")
		key = string.gsub(key, "[%%:/=]", "-")
		key = string.gsub(key, "[!?%.,;%[%]{}%(%)'`\"]", "")
		key = "warden." .. string.lower(key)
		keys[str] = key
	end

	local l = language.GetPhrase(key)

	if l ~= key then
		return string.format(l, ...)
	end

	return string.format(str, ...)
end