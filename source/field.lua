-- Field geometry: builds walls/obstacles/pen from a level def and resolves
-- circle collisions against them. The pen is three solid walls plus a
-- gated side split into two rects, so the gap is the only way in.

Field = {}

local function penWalls(p)
    local th, gap = C.PEN_WALL, C.PEN_GAP
    local rects = {}
    local function solid(x, y, w, h) rects[#rects + 1] = { x = x, y = y, w = w, h = h } end
    -- each side is either solid or split around a centered gap
    local sides = {
        left   = { x = p.x, y = p.y, w = th, h = p.h, vert = true },
        right  = { x = p.x + p.w - th, y = p.y, w = th, h = p.h, vert = true },
        top    = { x = p.x, y = p.y, w = p.w, h = th, vert = false },
        bottom = { x = p.x, y = p.y + p.h - th, w = p.w, h = th, vert = false },
    }
    for side, s in pairs(sides) do
        if side == p.gate then
            if s.vert then
                local seg = (s.h - gap) / 2
                solid(s.x, s.y, s.w, seg)
                solid(s.x, s.y + s.h - seg, s.w, seg)
            else
                local seg = (s.w - gap) / 2
                solid(s.x, s.y, seg, s.h)
                solid(s.x + s.w - seg, s.y, seg, s.h)
            end
        else
            solid(s.x, s.y, s.w, s.h)
        end
    end
    -- funnel wings: a flared "race" outside the opening, stepped from
    -- axis-aligned stubs, so the flee-spread of a pushed mob gets caught
    -- and channelled through the gap
    local gapA, gapB
    if p.gate == "left" or p.gate == "right" then
        gapA = p.y + (p.h - gap) / 2
        gapB = p.y + (p.h + gap) / 2
        local x0 = (p.gate == "left") and p.x - 18 or p.x + p.w
        local x1 = (p.gate == "left") and p.x - 34 or p.x + p.w + 16
        local x2 = (p.gate == "left") and p.x - 50 or p.x + p.w + 32
        solid(x0, gapA - 6, 18, 5)
        solid(x1, gapA - 14, 18, 5)
        solid(x2, gapA - 22, 18, 5)
        solid(x0, gapB + 1, 18, 5)
        solid(x1, gapB + 9, 18, 5)
        solid(x2, gapB + 17, 18, 5)
    else
        gapA = p.x + (p.w - gap) / 2
        gapB = p.x + (p.w + gap) / 2
        local y0 = (p.gate == "top") and p.y - 18 or p.y + p.h
        local y1 = (p.gate == "top") and p.y - 34 or p.y + p.h + 16
        local y2 = (p.gate == "top") and p.y - 50 or p.y + p.h + 32
        solid(gapA - 6, y0, 5, 18)
        solid(gapA - 14, y1, 5, 18)
        solid(gapA - 22, y2, 5, 18)
        solid(gapB + 1, y0, 5, 18)
        solid(gapB + 9, y1, 5, 18)
        solid(gapB + 17, y2, 5, 18)
    end

    -- the gate leaf, pinned back open against the lower/right wing; the
    -- shepherd swings it shut once enough of the flock is inside
    local leaf = { len = gap + 4 }
    if p.gate == "left" then
        leaf.x, leaf.y, leaf.open, leaf.closed = p.x + 2, gapB, 150, 270
    elseif p.gate == "right" then
        leaf.x, leaf.y, leaf.open, leaf.closed = p.x + p.w - 2, gapB, 30, 270
    elseif p.gate == "top" then
        leaf.x, leaf.y, leaf.open, leaf.closed = gapB, p.y + 2, 300, 180
    else
        leaf.x, leaf.y, leaf.open, leaf.closed = gapB, p.y + p.h - 2, 60, 180
    end
    p.leaf = leaf

    -- gate centre, just outside the opening (where the drive aims)
    local gx, gy = p.x + p.w / 2, p.y + p.h / 2
    if p.gate == "left" then gx = p.x - 6
    elseif p.gate == "right" then gx = p.x + p.w + 6
    elseif p.gate == "top" then gy = p.y - 6
    else gy = p.y + p.h + 6 end
    return rects, gx, gy
end

function Field.build(lvl)
    local f = {
        W = lvl.W, H = lvl.H,
        rects = {}, circles = {}, ponds = {}, trees = {},
    }
    local pen = { x = lvl.pen.x, y = lvl.pen.y, w = lvl.pen.w, h = lvl.pen.h, gate = lvl.pen.gate }
    local walls, gx, gy = penWalls(pen)
    for _, r in ipairs(walls) do f.rects[#f.rects + 1] = r end
    pen.gx, pen.gy = gx, gy
    local pad = C.PEN_WALL + 3
    pen.inner = { x = pen.x + pad, y = pen.y + pad, w = pen.w - 2 * pad, h = pen.h - 2 * pad }
    f.pen = pen

    for _, o in ipairs(lvl.obs) do
        if o.type == "rock" then
            f.circles[#f.circles + 1] = { x = o.x, y = o.y, r = o.r, kind = "rock" }
        elseif o.type == "tree" then
            f.circles[#f.circles + 1] = { x = o.x, y = o.y, r = o.r, kind = "tree" }
        elseif o.type == "pond" then
            f.ponds[#f.ponds + 1] = { x = o.x, y = o.y, r = o.r }
        elseif o.type == "wall" then
            f.rects[#f.rects + 1] = { x = o.x, y = o.y, w = o.w, h = o.h }
        end
    end
    G.field = f
end

-- push a circle out of walls/rocks/bounds; returns corrected x,y
function Field.resolveCircle(x, y, r)
    local f = G.field
    x = Util.clamp(x, r, f.W - r)
    y = Util.clamp(y, r, f.H - r)
    for _, c in ipairs(f.circles) do
        local dx, dy = x - c.x, y - c.y
        local d = math.sqrt(dx * dx + dy * dy)
        local min = c.r + r
        if d < min then
            if d < 0.001 then dx, dy, d = 1, 0, 1 end
            x = c.x + dx / d * min
            y = c.y + dy / d * min
        end
    end
    for _, rc in ipairs(f.rects) do
        local nx = Util.clamp(x, rc.x, rc.x + rc.w)
        local ny = Util.clamp(y, rc.y, rc.y + rc.h)
        local dx, dy = x - nx, y - ny
        local d2 = dx * dx + dy * dy
        if d2 < r * r then
            if d2 > 0.0001 then
                local d = math.sqrt(d2)
                x = nx + dx / d * r
                y = ny + dy / d * r
            else
                -- centre inside the wall: eject along the shallowest axis
                local lx = (x - rc.x) < (rc.x + rc.w - x) and (rc.x - r) or (rc.x + rc.w + r)
                local ly = (y - rc.y) < (rc.y + rc.h - y) and (rc.y - r) or (rc.y + rc.h + r)
                if math.abs(lx - x) < math.abs(ly - y) then x = lx else y = ly end
            end
        end
    end
    return x, y
end

function Field.inPen(x, y, pad)
    local p = G.field.pen.inner
    pad = pad or 0
    return x > p.x + pad and x < p.x + p.w - pad and y > p.y + pad and y < p.y + p.h - pad
end

function Field.inPond(x, y)
    for _, p in ipairs(G.field.ponds) do
        if Util.dist(x, y, p.x, p.y) < p.r then return p end
    end
    return nil
end

function Field.nearest(list, x, y, maxD)
    local best, bd
    for _, c in ipairs(list) do
        local d = Util.dist(x, y, c.x, c.y)
        if d < (maxD or 1e9) and (not bd or d < bd) then best, bd = c, d end
    end
    return best, bd
end
