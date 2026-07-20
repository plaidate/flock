-- All rendering. The world draws through a camera transform (pan + zoom):
-- the camera fits the dog and every unpenned animal in frame, zooming out
-- as the action spreads (Samurai Shodown style) and back in as it bunches,
-- clamped to the fenced field and the area below the HUD. Animals and dogs
-- are parametric 1-bit shapes - no image assets - so they scale cleanly.

local gfx = playdate.graphics

Draw = {}

-- ------------------------------------------------------------- camera

local VIEW_H = 240 - C.HUD_H
local MIN_ZOOM = 0.45

-- world -> screen
function Draw.wx(x) return (x - G.cam.x) * G.cam.s + 200 end
function Draw.wy(y) return (y - G.cam.y) * G.cam.s + C.HUD_H + VIEW_H / 2 end
function Draw.ws(v) return v * G.cam.s end

function Draw.resetCam()
    local p = G.player
    G.cam = { x = p.x, y = p.y, s = 0.8 }
end

function Draw.updateCam(dt)
    local f = G.field
    local p = G.player
    -- bounding box of the actors that matter
    local minx, maxx, miny, maxy = p.x, p.x, p.y, p.y
    for _, a in ipairs(G.animals) do
        if not a.penned then
            if a.x < minx then minx = a.x end
            if a.x > maxx then maxx = a.x end
            if a.y < miny then miny = a.y end
            if a.y > maxy then maxy = a.y end
        end
    end
    local bw = maxx - minx + 120
    local bh = maxy - miny + 120
    local ts = math.min(1, 400 / bw, VIEW_H / bh)
    ts = math.max(ts, MIN_ZOOM)
    local cx = (minx + maxx) / 2
    local cy = (miny + maxy) / 2
    -- keep the viewport inside the field (centre small fields)
    local vw, vh = 400 / ts, VIEW_H / ts
    if f.W <= vw then cx = f.W / 2 else cx = Util.clamp(cx, vw / 2, f.W - vw / 2) end
    if f.H <= vh then cy = f.H / 2 else cy = Util.clamp(cy, vh / 2, f.H - vh / 2) end
    local k = math.min(1, C.CAM_RATE * dt)
    G.cam.x = G.cam.x + (cx - G.cam.x) * k
    G.cam.y = G.cam.y + (cy - G.cam.y) * k
    G.cam.s = G.cam.s + (ts - G.cam.s) * math.min(1, 2 * dt)
end

-- ------------------------------------------------------------- ground

local function drawGround()
    local f = G.field
    local s = G.cam.s
    local wx0 = G.cam.x - 200 / s
    local wy0 = G.cam.y - VIEW_H / 2 / s
    local x0 = math.floor(wx0 / 32) - 1
    local y0 = math.floor(wy0 / 32) - 1
    local nx = math.ceil(400 / s / 32) + 2
    local ny = math.ceil(VIEW_H / s / 32) + 2
    gfx.setColor(gfx.kColorBlack)
    for ix = x0, x0 + nx do
        for iy = y0, y0 + ny do
            local h = Util.hash(ix, iy)
            local wx = ix * 32 + h * 24
            local wy = iy * 32 + ((h * 7) % 1) * 24
            if wx > 0 and wx < f.W and wy > 0 and wy < f.H then
                local sx, sy = Draw.wx(wx), Draw.wy(wy)
                if h < 0.25 then
                    gfx.drawPixel(sx, sy)
                elseif h < 0.34 then
                    gfx.drawLine(sx, sy, sx - 1 * s, sy - 3 * s)
                    gfx.drawLine(sx + 2 * s, sy, sx + 3 * s, sy - 3 * s)
                end
            end
        end
    end
end

local function drawBorder()
    local f = G.field
    gfx.setColor(gfx.kColorBlack)
    local x0, y0 = Draw.wx(0), Draw.wy(0)
    local x1, y1 = Draw.wx(f.W), Draw.wy(f.H)
    gfx.drawRect(x0, y0, x1 - x0, y1 - y0)
    local ps = math.max(2, Draw.ws(3))
    for x = 0, f.W, 40 do
        local sx = Draw.wx(x)
        gfx.fillRect(sx - 1, y0 - 2, ps, ps + 2)
        gfx.fillRect(sx - 1, y1 - ps, ps, ps + 2)
    end
    for y = 0, f.H, 40 do
        local sy = Draw.wy(y)
        gfx.fillRect(x0 - 2, sy - 1, ps + 2, ps)
        gfx.fillRect(x1 - ps, sy - 1, ps + 2, ps)
    end
end

local ditherPattern = { 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55 }

local function drawField()
    local f = G.field
    -- ponds
    for _, p in ipairs(f.ponds) do
        local sx, sy, sr = Draw.wx(p.x), Draw.wy(p.y), Draw.ws(p.r)
        gfx.setPattern(ditherPattern)
        gfx.fillCircleAtPoint(sx, sy, sr)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawCircleAtPoint(sx, sy, sr)
        gfx.drawArc(sx, sy, sr * 0.55, 40, 140)
    end
    -- rocks and trees
    for _, c in ipairs(f.circles) do
        local sx, sy, sr = Draw.wx(c.x), Draw.wy(c.y), Draw.ws(c.r)
        if c.kind == "rock" then
            gfx.setColor(gfx.kColorWhite)
            gfx.fillCircleAtPoint(sx, sy, sr)
            gfx.setColor(gfx.kColorBlack)
            gfx.drawCircleAtPoint(sx, sy, sr)
            gfx.drawArc(sx - sr * 0.2, sy - sr * 0.2, sr * 0.5, 180, 330)
        else
            gfx.setPattern(ditherPattern)
            gfx.fillCircleAtPoint(sx, sy, sr)
            gfx.setColor(gfx.kColorBlack)
            gfx.drawCircleAtPoint(sx, sy, sr)
            gfx.fillCircleAtPoint(sx, sy, math.max(1, Draw.ws(2)))
        end
    end
    -- walls (incl. pen walls)
    gfx.setColor(gfx.kColorBlack)
    for _, r in ipairs(f.rects) do
        gfx.fillRect(Draw.wx(r.x), Draw.wy(r.y),
            math.max(2, Draw.ws(r.w)), math.max(2, Draw.ws(r.h)))
    end
    -- pen straw + gate posts
    local pen = f.pen
    gfx.setPattern(ditherPattern)
    gfx.fillRect(Draw.wx(pen.inner.x), Draw.wy(pen.inner.y), Draw.ws(pen.inner.w), math.max(2, Draw.ws(3)))
    gfx.setColor(gfx.kColorBlack)
    local gap = C.PEN_GAP
    local pr = math.max(2, Draw.ws(3))
    if pen.gate == "left" or pen.gate == "right" then
        local gx = pen.gate == "left" and pen.x + 2 or pen.x + pen.w - 3
        gfx.fillCircleAtPoint(Draw.wx(gx), Draw.wy(pen.y + (pen.h - gap) / 2), pr)
        gfx.fillCircleAtPoint(Draw.wx(gx), Draw.wy(pen.y + (pen.h + gap) / 2), pr)
    else
        local gy = pen.gate == "top" and pen.y + 2 or pen.y + pen.h - 3
        gfx.fillCircleAtPoint(Draw.wx(pen.x + (pen.w - gap) / 2), Draw.wy(gy), pr)
        gfx.fillCircleAtPoint(Draw.wx(pen.x + (pen.w + gap) / 2), Draw.wy(gy), pr)
    end

    -- the gate leaf (pinned back open; swings shut when the trial is won)
    -- and the shepherd waiting beside the hinge to close it
    local leaf = pen.leaf
    if leaf then
        local q = 0
        if G.closeT then q = 1 - math.max(0, G.closeT) / 0.9 end
        local ang = math.rad(Util.lerp(leaf.open, leaf.closed, q))
        local hx, hy = Draw.wx(leaf.x), Draw.wy(leaf.y)
        local ex = hx + math.cos(ang) * Draw.ws(leaf.len)
        local ey = hy + math.sin(ang) * Draw.ws(leaf.len)
        gfx.setLineWidth(2)
        gfx.drawLine(hx, hy, ex, ey)
        gfx.setLineWidth(1)
        gfx.fillCircleAtPoint(hx, hy, math.max(2, Draw.ws(2.5)))
        local off = 16 * (1 - q) + 5
        local sxw, syw
        if pen.gate == "left" then sxw, syw = leaf.x - off * 0.5, leaf.y + off
        elseif pen.gate == "right" then sxw, syw = leaf.x + off * 0.5, leaf.y + off
        elseif pen.gate == "top" then sxw, syw = leaf.x + off, leaf.y - off * 0.5
        else sxw, syw = leaf.x + off, leaf.y + off * 0.5 end
        local sx2, sy2 = Draw.wx(sxw), Draw.wy(syw)
        local s = G.cam.s
        gfx.drawCircleAtPoint(sx2, sy2 - 7 * s, math.max(1.5, 2.2 * s))
        gfx.drawLine(sx2, sy2 - 5 * s, sx2, sy2 + 2 * s)
        gfx.drawLine(sx2, sy2 + 2 * s, sx2 - 2 * s, sy2 + 6 * s)
        gfx.drawLine(sx2, sy2 + 2 * s, sx2 + 2 * s, sy2 + 6 * s)
        gfx.drawLine(sx2 + 3 * s, sy2 - 8 * s, sx2 + 3 * s, sy2 + 6 * s)
    end
end

-- ------------------------------------------------------------- animals

local function drawAnimal(a)
    local br = a.breed
    local s = G.cam.s
    local ax, ay = Draw.wx(a.x), Draw.wy(a.y)
    local fx, fy = a.fx, a.fy
    local moving = math.abs(a.vx) + math.abs(a.vy) > 6

    if moving then
        local sway = math.sin((a.phase or 0) * 4) * 2 * s
        gfx.setColor(gfx.kColorBlack)
        gfx.drawLine(ax - fy * 3 * s, ay + fx * 3 * s, ax - fy * 3 * s + sway * fx, ay + fx * 3 * s + 3 * s)
        gfx.drawLine(ax + fy * 3 * s, ay - fx * 3 * s, ax + fy * 3 * s - sway * fx, ay - fx * 3 * s + 3 * s)
    end

    local bw, bh = a.r * 2 * s, a.r * 1.5 * s
    if br.upright then bw, bh = a.r * 1.5 * s, a.r * 2 * s end
    gfx.setColor(gfx.kColorWhite)
    gfx.fillEllipseInRect(ax - bw / 2, ay - bh / 2, bw, bh)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawEllipseInRect(ax - bw / 2, ay - bh / 2, bw, bh)

    local neck = (br.longNeck and a.r + 4 or a.r) * s
    local hx, hy = ax + fx * neck, ay + fy * neck
    if br.longNeck then
        gfx.drawLine(ax + fx * a.r * 0.6 * s, ay + fy * a.r * 0.6 * s, hx, hy)
    end
    local hr = math.max(1.5, a.r * 0.42 * s)
    if br.darkHead then
        gfx.fillCircleAtPoint(hx, hy, hr)
    else
        gfx.setColor(gfx.kColorWhite)
        gfx.fillCircleAtPoint(hx, hy, hr)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawCircleAtPoint(hx, hy, hr)
    end
    if a.species == "duck" or a.species == "goose" then
        gfx.drawLine(hx, hy, hx + fx * (hr + 2 * s), hy + fy * (hr + 2 * s))
    end
    if br.horns then
        gfx.drawLine(hx - fy * 3 * s, hy + fx * 3 * s, hx - (fy * 4 + fx * 3) * s, hy + (fx * 4 - fy * 3) * s)
        gfx.drawLine(hx + fy * 3 * s, hy - fx * 3 * s, hx + (fy * 4 - fx * 3) * s, hy - (fx * 4 + fy * 3) * s)
    end
    if a.species == "sheep" and s > 0.7 then
        gfx.drawPixel(ax - 2, ay - 2)
        gfx.drawPixel(ax + 2, ay - 1)
        gfx.drawPixel(ax, ay + 2)
    end

    if not a.penned and a.agit > C.PANIC_AT then
        gfx.drawText("!", ax - 2, ay - a.r * s - 14)
    end
end

-- ------------------------------------------------------------- the dog

-- screen-space parametric dog (menus pass absolute coords, play passes
-- transformed coords + the camera scale)
function Draw.dog(px, py, heading, persona, creep, barkT, scale)
    local look = persona.look
    scale = (scale or 1) * look.size
    local rad = math.rad(heading)
    local fx, fy = math.cos(rad), math.sin(rad)
    local rr = 5.5 * scale
    local cr = 5 * scale
    local hr = 4 * scale
    local cxp = px + fx * 5 * scale
    local cyp = py + fy * 5 * scale
    local hx = px + fx * 10 * scale
    local hy = py + fy * 10 * scale

    if creep then rr, cr, hr = rr * 0.9, cr * 0.9, hr * 0.9 end

    gfx.setColor(gfx.kColorBlack)
    if look.tail ~= "bob" then
        local wag = math.sin(playdate.getCurrentTimeMilliseconds() / 120) * 3 * scale
        local tx = px - fx * (rr + 6 * scale) - fy * wag
        local ty = py - fy * (rr + 6 * scale) + fx * wag
        gfx.drawLine(px - fx * rr, py - fy * rr, tx, ty)
        if look.tail == "feather" then
            gfx.drawLine(px - fx * rr, py - fy * rr, tx - fy * 2, ty + fx * 2)
        end
    end

    local function blob(x, y, r, dark)
        if dark then
            gfx.setColor(gfx.kColorBlack)
            gfx.fillCircleAtPoint(x, y, r)
        else
            gfx.setColor(gfx.kColorWhite)
            gfx.fillCircleAtPoint(x, y, r)
            gfx.setColor(gfx.kColorBlack)
            gfx.drawCircleAtPoint(x, y, r)
        end
    end
    blob(px, py, rr, look.dark or look.patch)
    blob(cxp, cyp, cr, look.dark)
    blob(hx, hy, hr, look.dark)
    if look.shaggy then
        for i = 0, 5 do
            local a = i * 1.05 + (px + py) * 0.1
            gfx.drawPixel(px + math.cos(a) * (rr + 1.5), py + math.sin(a) * (rr + 1.5))
            gfx.drawPixel(cxp + math.cos(a + 0.5) * (cr + 1.5), cyp + math.sin(a + 0.5) * (cr + 1.5))
        end
    end
    local es = (look.ears == "bigprick" and 5 or 3.5) * scale
    local e1x, e1y = hx - fy * hr * 0.8, hy + fx * hr * 0.8
    local e2x, e2y = hx + fy * hr * 0.8, hy - fx * hr * 0.8
    if look.ears == "drop" then
        gfx.drawLine(e1x, e1y, e1x - fx * es, e1y - fy * es + es)
        gfx.drawLine(e2x, e2y, e2x - fx * es, e2y - fy * es + es)
    else
        gfx.drawLine(e1x, e1y, e1x - fx * es - fy * es * 0.5, e1y - fy * es + fx * es * 0.5)
        gfx.drawLine(e2x, e2y, e2x + fy * es * 0.5 - fx * es * 0.2, e2y - fx * es * 0.5 - fy * es * 0.2)
    end
    gfx.fillCircleAtPoint(hx + fx * (hr + 1), hy + fy * (hr + 1), math.max(1, 1.2 * scale))

    if barkT and barkT > 0 then
        local br_ = ((0.3 - barkT) * 90 + 8) * scale
        gfx.drawArc(hx + fx * 4, hy + fy * 4, br_, heading - 40, heading + 40)
    end
end

-- ------------------------------------------------------------- HUD

local function fmtTime(t)
    t = math.max(0, math.ceil(t))
    return string.format("%d:%02d", math.floor(t / 60), t % 60)
end

local function drawHud()
    local lvl = Levels[G.levelIdx]
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, 0, 400, C.HUD_H)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawLine(0, C.HUD_H, 400, C.HUD_H)
    gfx.drawText(G.levelIdx .. " " .. lvl.name, 4, 1)
    gfx.drawTextAligned("PEN " .. G.penned .. "/" .. G.need, 230, 1, kTextAlignment.center)
    gfx.drawTextAligned(fmtTime(G.timeLeft), 320, 1, kTextAlignment.center)
    local p = G.player
    if p.barkCd <= 0 then
        gfx.fillCircleAtPoint(390, C.HUD_H / 2, 4)
    else
        gfx.drawCircleAtPoint(390, C.HUD_H / 2, 4)
    end
end

local function drawMinimap()
    local f = G.field
    if f.W <= 400 and f.H <= 240 - C.HUD_H then return end
    local mw, mh = 56, 36
    local mx, my = 400 - mw - 4, C.HUD_H + 4
    local s = math.min(mw / f.W, mh / f.H)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(mx, my, f.W * s + 2, f.H * s + 2)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRect(mx, my, f.W * s + 2, f.H * s + 2)
    local pen = f.pen
    gfx.drawRect(mx + pen.x * s, my + pen.y * s, math.max(2, pen.w * s), math.max(2, pen.h * s))
    for _, a in ipairs(G.animals) do
        if not a.penned then
            gfx.drawPixel(mx + 1 + a.x * s, my + 1 + a.y * s)
        end
    end
    local p = G.player
    gfx.drawLine(mx + p.x * s - 1, my + p.y * s, mx + p.x * s + 3, my + p.y * s)
    gfx.drawLine(mx + 1 + p.x * s, my + p.y * s - 2, mx + 1 + p.x * s, my + p.y * s + 2)
end

-- ------------------------------------------------------------- frames

function Draw.play()
    gfx.clear(gfx.kColorWhite)
    drawGround()
    drawBorder()
    drawField()
    for _, a in ipairs(G.animals) do
        drawAnimal(a)
    end
    local p = G.player
    Draw.dog(Draw.wx(p.x), Draw.wy(p.y), p.heading, Dogs[G.dogIdx], p.creep, p.barkT, G.cam.s)
    Fx.draw()
    drawHud()
    drawMinimap()
end

function Draw.overlayBox(w, h)
    local x, y = (400 - w) / 2, (240 - h) / 2
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(x, y, w, h)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRect(x, y, w, h)
    gfx.drawRect(x + 2, y + 2, w - 4, h - 4)
    return x, y
end
