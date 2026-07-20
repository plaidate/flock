-- Controls: crank = heading (left/right d-pad when docked), up = run,
-- down = brake, B held = creep, A = bark. The smoke autopilot is a
-- herding bot: outrun to the far side of the flock, drive it at the gate,
-- bark stragglers back, bark down charging geese - and once, deliberately
-- idle a level away to exercise the fail path.

Input = {}

-- returns { crank, turn (-1/0/1), up, down, creep, bark }
function Input.gather()
    if Harness.enabled and Harness.autopilot then
        return Harness.autopilot()
    end
    local turn = 0
    if playdate.buttonIsPressed(playdate.kButtonLeft) then turn = -1 end
    if playdate.buttonIsPressed(playdate.kButtonRight) then turn = 1 end
    return {
        crank = playdate.isCrankDocked() and 0 or playdate.getCrankChange(),
        turn = turn,
        up = playdate.buttonIsPressed(playdate.kButtonUp),
        down = playdate.buttonIsPressed(playdate.kButtonDown),
        creep = playdate.buttonIsPressed(playdate.kButtonB),
        bark = playdate.buttonJustPressed(playdate.kButtonA),
    }
end

-- menu confirmation, autopilot-aware
function Input.confirm()
    if Harness.enabled then return G.st > 0.7 end
    return playdate.buttonJustPressed(playdate.kButtonA)
end

function Input.menuDelta()
    local dx, dy = 0, 0
    if playdate.buttonJustPressed(playdate.kButtonLeft) then dx = -1 end
    if playdate.buttonJustPressed(playdate.kButtonRight) then dx = 1 end
    if playdate.buttonJustPressed(playdate.kButtonUp) then dy = -1 end
    if playdate.buttonJustPressed(playdate.kButtonDown) then dy = 1 end
    return dx, dy
end

-- ---------------------------------------------------------------- autopilot

local bot = { lastPenned = 0, lastPennedT = 0, lastBark = -10 }

-- bot self-discipline: barking is a tool, not a metronome
local function wantBark(inp, gap)
    if G.t - bot.lastBark > gap then
        inp.bark = true
        bot.lastBark = G.t
    end
end

-- steer the dog toward tx,ty: set crank toward the desired heading and
-- pick a gait by distance/alignment
local function steerTo(inp, tx, ty, fast)
    local p = G.player
    -- dodge solid circles sitting on the direct line
    local dx, dy, d = Util.norm(tx - p.x, ty - p.y)
    for _, c in ipairs(G.field.circles) do
        local ox, oy = c.x - p.x, c.y - p.y
        local along = ox * dx + oy * dy
        if along > 0 and along < math.min(d, 70) then
            local px, py = ox - dx * along, oy - dy * along
            local off = math.sqrt(px * px + py * py)
            if off < c.r + 16 then
                -- veer around: aim past the side with more clearance
                local side = (px * dy - py * dx) > 0 and 1 or -1
                tx = c.x + (-dy) * side * (c.r + 26)
                ty = c.y + dx * side * (c.r + 26)
                break
            end
        end
    end
    local desired = math.deg(math.atan(ty - p.y, tx - p.x))
    local diff = Util.angdiff(p.heading, desired)
    inp.crank = Util.clamp(diff, -16, 16)
    local dist = Util.dist(p.x, p.y, tx, ty)
    if fast and dist > 90 and math.abs(diff) < 60 then
        inp.up = true
    elseif dist < 20 then
        inp.down = true
    end
    return inp
end

Harness.autopilot = function()
    local inp = { crank = 0, turn = 0, up = false, down = false, creep = false, bark = false }
    if G.state ~= "play" then return inp end
    local p = G.player
    local cnt = Harness.counters
    local persona = Dogs[G.dogIdx]

    -- staged failure: on the first visit to level 2, amble to a corner and
    -- let the clock run out so the fail path gets exercised
    if G.levelIdx == 2 and (cnt.fails or 0) == 0 then
        return steerTo(inp, 40, 40, false)
    end

    local ccx, ccy, crad = Flock.centroid()
    if not ccx then return inp end
    local pen = G.field.pen

    -- gate facing (points OUT of the pen)
    local fvx, fvy = 0, 0
    if pen.gate == "left" then fvx = -1
    elseif pen.gate == "right" then fvx = 1
    elseif pen.gate == "top" then fvy = -1
    else fvy = 1 end
    -- stage the flock in front of the opening, then push through it:
    -- drive at the staging point until the mob is parked there, only then
    -- aim through the gap at the pen interior
    local gx, gy = pen.gx + fvx * 55, pen.gy + fvy * 55

    if G.penned > bot.lastPenned then
        bot.lastPenned = G.penned
        bot.lastPennedT = G.t
    end

    -- bark down a charging goose
    for _, a in ipairs(G.animals) do
        if not a.penned and a.breed.challenge and a.obeyT <= 0 then
            if Util.dist(a.x, a.y, p.x, p.y) < 55 then
                wantBark(inp, 2)
            end
        end
    end

    -- farthest straggler from the flock centre picks the mode
    local far, farD = nil, 0
    local unpennedN = 0
    for _, a in ipairs(G.animals) do
        if not a.penned then
            unpennedN = unpennedN + 1
            local d = Util.dist(a.x, a.y, ccx, ccy)
            if d > farD then far, farD = a, d end
        end
    end

    local kx, ky, krad   -- what we push
    local tx, ty         -- where we push it to
    if far and farD > 90 and unpennedN > 1 then
        -- GATHER: get behind the straggler and squeeze it back to the mob
        kx, ky, krad = far.x, far.y, 0
        tx, ty = ccx, ccy
        if Util.dist(far.x, far.y, p.x, p.y) < persona.barkR * 0.9 then
            wantBark(inp, 5)
        end
    else
        -- DRIVE: whole flock to the staging point, then through the gate
        kx, ky, krad = ccx, ccy, crad
        tx, ty = gx, gy
        if Util.dist(ccx, ccy, gx, gy) < 90 then
            tx, ty = pen.gx - fvx * 25, pen.gy - fvy * 25
        end
        if G.t - bot.lastPennedT > 12 and Util.dist(p.x, p.y, kx, ky) < krad + 70 then
            wantBark(inp, 5)
            if inp.bark then bot.lastPennedT = G.t - 6 end
        end
    end

    -- drive point: behind what we push, opposite the target. If that spot
    -- clamps into the mob (flock against a wall/corner), sweep the approach
    -- angle a step at a time until a spot fits inside the field, so the
    -- push direction stays as close to on-target as the fences allow.
    -- prefer a small rotation at a shorter reach over a big rotation:
    -- a close-in push on target beats a wide push into a corner
    local ang0 = math.atan(ky - ty, kx - tx)
    local dpx, dpy
    local bestX, bestY, bestD
    for _, dAng in ipairs({ 0, 0.35, -0.35, 0.7, -0.7, 1.05, -1.05, 1.4, -1.4 }) do
        for _, so in ipairs({ krad + 42, krad + 26, krad + 12 }) do
            local a = ang0 + dAng
            local x = Util.clamp(kx + math.cos(a) * so, 14, G.field.W - 14)
            local y = Util.clamp(ky + math.sin(a) * so, 14, G.field.H - 14)
            local d = Util.dist(x, y, kx, ky)
            if not bestD or d > bestD then bestX, bestY, bestD = x, y, d end
            if d > so - 8 then
                dpx, dpy = x, y
                break
            end
        end
        if dpx then break end
    end
    if not dpx then
        -- cornered mob with nowhere to stand behind: first get off the
        -- sheep (release the pressure, let them calm), and if they still
        -- will not drift off the wall, wedge into the corner nook and
        -- shove - the wall-slide walks them out along the fence
        if not bot.relT then bot.relT = G.t end
        -- a lone straggler or pair doesn't need gentleness: wedge at once
        if G.t - bot.relT < ((unpennedN <= 2) and 0.5 or 6) then
            local tdx2, tdy2 = Util.norm(tx - kx, ty - ky)
            dpx = Util.clamp(kx + tdx2 * 120, 14, G.field.W - 14)
            dpy = Util.clamp(ky + tdy2 * 120, 14, G.field.H - 14)
        else
            dpx, dpy = bestX, bestY
        end
    else
        bot.relT = nil
    end
    bot.mode = (krad == 0) and "gather" or "drive"

    if Util.dist(p.x, p.y, dpx, dpy) > 30 then
        -- flank: swing wide if the straight line runs through the cluster;
        -- stick to one side for a few seconds so we don't orbit-dither
        local dx, dy, d = Util.norm(dpx - p.x, dpy - p.y)
        local ox, oy = kx - p.x, ky - p.y
        local along = ox * dx + oy * dy
        if along > 0 and along < d then
            local px_, py_ = ox - dx * along, oy - dy * along
            local off = math.sqrt(px_ * px_ + py_ * py_)
            if off < krad + 70 then
                -- bulge the detour AWAY from the mob: waypoint goes on the
                -- opposite side of the path from the cluster
                if G.t - (bot.sideT or -9) > 4 then
                    bot.side = (px_ * dy - py_ * dx) > 0 and 1 or -1
                    bot.sideT = G.t
                end
                local side = bot.side or 1
                dpx = Util.clamp(kx + (-dy) * side * (krad + 110), 14, G.field.W - 14)
                dpy = Util.clamp(ky + dx * side * (krad + 110), 14, G.field.H - 14)
            end
        end
        -- sprinting right past the mob spooks it: only run when clear.
        -- Exception: one or two stragglers left - a fleeing single outruns
        -- a trotting dog forever, so sprint the outrun and get behind it
        local fast = Util.dist(p.x, p.y, kx, ky) > krad + 130
        if unpennedN <= 2 and Util.dist(p.x, p.y, dpx, dpy) > 35 then
            fast = true
        end
        steerTo(inp, dpx, dpy, fast)
    else
        -- push: trail the mob continuously from behind - brake only when
        -- about to wade in, creep through the last stretch
        steerTo(inp, kx, ky, false)
        local dk = Util.dist(p.x, p.y, kx, ky)
        if dk < krad + 10 then
            inp.down = true
            inp.creep = false
        elseif dk < krad + 34 then
            inp.creep = true
        end
    end
    return inp
end

function Input.resetBot()
    bot.lastPenned = 0
    bot.lastPennedT = 0
end
