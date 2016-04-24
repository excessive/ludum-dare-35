local memoize = require "memoize"
local iqm     = require "iqm"
local anim9   = require "anim9"

local anims
local _lanim = memoize(function(path)
	return iqm.load_anims(path)
end)

return {
	model = memoize(function(path, actor)
		return iqm.load(path, actor)
	end),

	anims = function(path)
		return anim9(_lanim(path))
	end,

	sound = memoize(function(filename)
		return love.audio.newSource(filename)
	end),

	font = memoize(function(filename, size)
		return love.graphics.newFont(filename, size)
	end),

	texture = memoize(function(filename, flags)
		local texture = love.graphics.newImage(filename, flags)
		texture:setFilter("linear", "linear", 16)
		return texture
	end)
}
