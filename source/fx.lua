-- Little world-space effects: expanding rings (barks, pennings), floating
-- text, dust puffs while the dog runs.

Fx = { list = {} }

function Fx.reset()
    Fx.list = {}
end

function Fx.ring(x, y, r0)
    Fx.list[#Fx.list + 1] = { kind = "ring", x = x, y = y, r = r0 or 4, t = 0.45 }
end

function Fx.text(x, y, str)
    Fx.list[#Fx.list + 1] = { kind = "text", x = x, y = y, str = str, t = 1.0 }
end

function Fx.puff(x, y)
    Fx.list[#Fx.list + 1] = { kind = "puff", x = x, y = y, r = 2, t = 0.35 }
end

function Fx.update(dt)
    for i = #Fx.list, 1, -1 do
        local e = Fx.list[i]
        e.t = e.t - dt
        if e.kind == "ring" then e.r = e.r + 90 * dt end
        if e.kind == "puff" then e.r = e.r + 14 * dt end
        if e.kind == "text" then e.y = e.y - 18 * dt end
        if e.t <= 0 then table.remove(Fx.list, i) end
    end
end

local gfx = playdate.graphics

function Fx.draw()
    for _, e in ipairs(Fx.list) do
        local sx, sy = Draw.wx(e.x), Draw.wy(e.y)
        if e.kind == "ring" or e.kind == "puff" then
            gfx.setColor(gfx.kColorBlack)
            gfx.drawCircleAtPoint(sx, sy, Draw.ws(e.r))
        elseif e.kind == "text" then
            gfx.drawTextAligned(e.str, sx, sy, kTextAlignment.center)
        end
    end
end
