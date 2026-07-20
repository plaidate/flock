-- Small math/timer helpers used everywhere.

Util = { timers = {} }

function Util.clamp(v, a, b)
    if v < a then return a end
    if v > b then return b end
    return v
end

function Util.lerp(a, b, t)
    return a + (b - a) * t
end

function Util.sign(v)
    if v > 0 then return 1 end
    if v < 0 then return -1 end
    return 0
end

function Util.dist(x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

-- unit vector + length; returns 0,0,0 for a zero vector
function Util.norm(x, y)
    local l = math.sqrt(x * x + y * y)
    if l < 0.0001 then return 0, 0, 0 end
    return x / l, y / l, l
end

-- smallest signed angle (degrees) turning from a to b
function Util.angdiff(a, b)
    local d = (b - a) % 360
    if d > 180 then d = d - 360 end
    return d
end

function Util.rnd(a, b)
    return a + math.random() * (b - a)
end

-- deterministic 0..1 hash for ground decoration (no math.random)
function Util.hash(ix, iy)
    local n = ix * 374761393 + iy * 668265263
    n = n ~ (n >> 13)
    n = (n * 1274126177) & 0x7fffffff
    return (n % 1000) / 1000
end

function Util.after(t, fn)
    Util.timers[#Util.timers + 1] = { t = t, fn = fn }
end

function Util.update(dt)
    for i = #Util.timers, 1, -1 do
        local tm = Util.timers[i]
        tm.t = tm.t - dt
        if tm.t <= 0 then
            table.remove(Util.timers, i)
            tm.fn()
        end
    end
end

-- draw str scaled up (menus/titles); centered on x
local gfx = playdate.graphics
function Util.bigText(str, cx, y, scale)
    local w, h = gfx.getTextSize(str)
    if w == 0 then return end
    local img = gfx.image.new(w, h)
    gfx.pushContext(img)
    gfx.drawText(str, 0, 0)
    gfx.popContext()
    img:drawScaled(cx - w * scale / 2, y, scale)
end
