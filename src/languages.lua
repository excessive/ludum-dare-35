local i18n    = require "i18n"
local languages = {}

local function cycle(world)
	local function next_lang()
		languages.current = (languages.current % #languages) + 1
		local lang = languages[languages.current]
		local top = Scene.current()
		world.lang:set_locale(lang)
		world.notify(string.format("Changed locale to %s", lang))

		preferences.language = lang
		love.filesystem.write("preferences.json", json.encode(preferences))
	end
end

local function load(lang)
	-- Load languages
	local lang_base = "locale"
	local languages = { current = 1 }
	local files     = love.filesystem.getDirectoryItems(lang_base)

	for i, file in ipairs(files) do
		local name, ext = file:match("([^/]+)%.([^%.]+)$")

		if ext == "lua" then
			table.insert(languages, name)

			if name == lang then
				languages.current = #languages
			end
		end
	end

	local language = i18n()
	language:set_fallback("en")
	language:set_locale(languages[languages.current])
	for _, lang in ipairs(languages) do
		language:load(string.format("%s/%s.lua", lang_base, lang))
	end
	language:set_locale(lang)

	language.cycle = cycle

	return language
end

return {
	load = load,
}
