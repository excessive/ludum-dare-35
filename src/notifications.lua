local tiny    = require "tiny"
local cpml    = require "cpml"
local timer   = require "timer"
local convoke = require "convoke"

local notifications = tiny.system {
   no_pause = true,
   queue = {},
   ding  = love.audio.newSource("assets/sfx/ding.wav"),
   timer = timer.new(),
   size  = cpml.vec2(200, 50),
   font  = love.graphics.newFont("assets/fonts/NotoSans-Regular.ttf", 14)
}

function notifications:add(msg, icon)
   assert(type(msg) == "string")

   table.insert(self.queue, { icon = icon, text = msg, opacity=1.0 })

   convoke(function(continue, wait)
      self.timer.add(5, continue())
      wait()
      self.timer.tween(
         0.5,
         self.queue[1],
         { opacity=0 },
         "out-cubic",
         continue()
      )
      wait()
      table.remove(self.queue, 1)
   end)()
end

local function transform(index)
   local spacing = 60
   local x = love.graphics.getWidth() - 210
   local y = spacing * index + 10
   return x, y
end

function notifications:update(dt)
   self.timer.update(dt)
end

function notifications:draw()
   for i, n in ipairs(self.queue) do
      local x, y = transform(i-1)
      local pad = 5
      love.graphics.setColor(0, 0, 0, 200*n.opacity)
      love.graphics.rectangle("fill", x, y, self.size.x, self.size.y, 4)
      love.graphics.setColor(20, 90, 127, 255*n.opacity)
      love.graphics.rectangle("line", x, y, self.size.x, self.size.y, 4)
      love.graphics.setColor(255, 255, 255, 255*n.opacity)
      love.graphics.setFont(self.font)
      love.graphics.printf(n.text, x + pad, y + pad, 200)
   end
   love.graphics.setColor(255, 255, 255, 255)
end

return notifications
