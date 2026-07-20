-- The animals: boids plus a herding-pressure model. Each frame every
-- unpenned animal blends cohesion / alignment / separation with wander,
-- fear of the dog, breed attractions (ponds, rocks, a leader) and obstacle
-- avoidance into a desired velocity. Agitation (0-100) rises under
-- pressure and barks, decays over time, and drives speed and panic
-- behaviour: "clump" breeds huddle when panicked, "scatter" breeds explode.

Flock = {}

function Flock.spawn(lvl)
    G.animals = {}
    for gi, grp in ipairs(lvl.groups) do
        local br = Breeds[grp.species][grp.breed]
        local leaderIdx = nil
        for i = 1, grp.n do
            local a = {
                x = grp.sx + Util.rnd(-35, 35),
                y = grp.sy + Util.rnd(-35, 35),
                vx = 0, vy = 0,
                fx = 1, fy = 0,
                species = grp.species, breed = br,
                r = br.r,
                agit = 0, obeyT = 0,
                penned = false,
                wanderT = Util.rnd(0.5, 2), wx = 0, wy = 0,
                grazeOff = Util.rnd(0, 6.28),
                callT = Util.rnd(3, 12),
                millT = 0, mx = 0, my = 0,
                group = gi,
            }
            a.x, a.y = Field.resolveCircle(a.x, a.y, a.r)
            if br.leaderFollow and i == 1 then
                a.leader = true
                leaderIdx = #G.animals + 1
            end
            G.animals[#G.animals + 1] = a
        end
        if leaderIdx then
            for _, a in ipairs(G.animals) do
                if a.group == gi and not a.leader then a.leaderRef = G.animals[leaderIdx] end
            end
        end
    end
end

-- centroid + spread of unpenned animals (for camera, autopilot, bark recall)
function Flock.centroid()
    local cx, cy, n = 0, 0, 0
    for _, a in ipairs(G.animals) do
        if not a.penned then cx, cy, n = cx + a.x, cy + a.y, n + 1 end
    end
    if n == 0 then return nil end
    cx, cy = cx / n, cy / n
    local rad = 0
    for _, a in ipairs(G.animals) do
        if not a.penned then
            local d = Util.dist(a.x, a.y, cx, cy)
            if d > rad then rad = d end
        end
    end
    return cx, cy, rad, n
end

-- the dog barked: spike agitation, force obedience, and shove animals -
-- strays and clumping breeds toward the flock, scatter breeds away from
-- the dog.
function Flock.bark(px, py, persona)
    local ccx, ccy = Flock.centroid()
    for _, a in ipairs(G.animals) do
        if not a.penned then
            local d = Util.dist(a.x, a.y, px, py)
            if d < persona.barkR then
                a.agit = math.min(100, a.agit + persona.barkSpook)
                a.obeyT = C.BARK_OBEY
                local dcx = ccx and Util.dist(a.x, a.y, ccx, ccy) or 0
                local dirx, diry
                if ccx and (a.breed.panic == "clump" or dcx > 80) then
                    dirx, diry = Util.norm(ccx - a.x, ccy - a.y)
                else
                    dirx, diry = Util.norm(a.x - px, a.y - py)
                end
                a.vx = a.vx + dirx * persona.barkPush
                a.vy = a.vy + diry * persona.barkPush
            end
        end
    end
end

local function updatePenned(a, dt)
    -- mill gently around the pen
    a.millT = a.millT - dt
    if a.millT <= 0 then
        local inn = G.field.pen.inner
        a.mx = inn.x + Util.rnd(6, inn.w - 6)
        a.my = inn.y + Util.rnd(6, inn.h - 6)
        a.millT = Util.rnd(2, 5)
    end
    local dx, dy, d = Util.norm(a.mx - a.x, a.my - a.y)
    local sp = d > 4 and 12 or 0
    a.vx, a.vy = dx * sp, dy * sp
    a.x = a.x + a.vx * dt
    a.y = a.y + a.vy * dt
    local inn = G.field.pen.inner
    a.x = Util.clamp(a.x, inn.x + 2, inn.x + inn.w - 2)
    a.y = Util.clamp(a.y, inn.y + 2, inn.y + inn.h - 2)
    if sp > 2 then a.fx, a.fy = dx, dy end
    a.callT = a.callT - dt
    if a.callT <= 0 then
        Sfx.call(a.species)
        a.callT = Util.rnd(14, 30)
    end
end

function Flock.update(dt)
    local p = G.player
    local persona = Dogs[G.dogIdx]
    local animals = G.animals

    for _, a in ipairs(animals) do
        if a.penned then
            updatePenned(a, dt)
            goto continue
        end
        local br = a.breed
        local panicked = a.agit > C.PANIC_AT
        local cohMul, aliMul, wanderMul = 1, 1, 1
        if panicked then
            if br.panic == "clump" then cohMul = 2.2
            else cohMul, aliMul, wanderMul = 0.2, 0.3, 2.2 end
        end

        -- neighbours
        local cx, cy, cn = 0, 0, 0
        local avx, avy = 0, 0
        local sx, sy = 0, 0
        for _, b in ipairs(animals) do
            if b ~= a and not b.penned then
                local d = Util.dist(a.x, a.y, b.x, b.y)
                if d < C.NEIGHBOR_R then
                    local w = (b.species == a.species) and 1 or 0.35
                    cx, cy, cn = cx + b.x * w, cy + b.y * w, cn + w
                    avx, avy = avx + b.vx * w, avy + b.vy * w
                end
                local minD = a.r + b.r + C.SEP_PAD
                if d < minD and d > 0.001 then
                    local push = (1 - d / minD)
                    sx = sx + (a.x - b.x) / d * push
                    sy = sy + (a.y - b.y) / d * push
                end
            end
        end

        local SX, SY = 0, 0
        if cn > 0 then
            local mx, my = cx / cn, cy / cn
            local dx, dy, d = Util.norm(mx - a.x, my - a.y)
            if d > 22 then
                SX = SX + dx * br.coh * cohMul
                SY = SY + dy * br.coh * cohMul
            end
            local ax, ay, al = Util.norm(avx, avy)
            if al > 1 then
                SX = SX + ax * br.ali * 0.6 * aliMul
                SY = SY + ay * br.ali * 0.6 * aliMul
            end
        end
        SX = SX + sx * br.sep * 1.6
        SY = SY + sy * br.sep * 1.6

        -- wander
        a.wanderT = a.wanderT - dt
        if a.wanderT <= 0 then
            local ang = Util.rnd(0, 6.283)
            a.wx, a.wy = math.cos(ang), math.sin(ang)
            a.wanderT = Util.rnd(0.8, 2.5)
        end
        SX = SX + a.wx * br.wayward * 0.5 * wanderMul
        SY = SY + a.wy * br.wayward * 0.5 * wanderMul

        -- dog pressure
        local fleeing, challenging = false, false
        local dgd = Util.dist(a.x, a.y, p.x, p.y)
        local fearR = br.fearR * persona.presence * p.pmod
        local prox = 0
        if dgd < fearR then
            prox = 1 - dgd / fearR
            if br.challenge and a.obeyT <= 0 and a.agit < 45 and dgd < 75 then
                -- turn and face the dog down
                local dx, dy = Util.norm(p.x - a.x, p.y - a.y)
                SX = SX + dx * 0.9
                SY = SY + dy * 0.9
                challenging = true
            else
                local fw = br.fearGain * (0.7 + prox * 1.6)
                if br.stubborn and a.obeyT <= 0 then fw = fw * 0.25 end
                local dx, dy = Util.norm(a.x - p.x, a.y - p.y)
                SX = SX + dx * fw
                SY = SY + dy * fw
                fleeing = true
            end
            local spookScale = p.creep and 0.15 or 1
            a.agit = math.min(100, a.agit + prox * br.spook * persona.spookMod * dt * spookScale)
        end

        -- hay smell: an animal that has entered the race in front of the
        -- gate gets drawn the last stretch into the pen
        do
            local pen = G.field.pen
            local inRace = false
            if pen.gate == "left" then
                inRace = a.x > pen.x - 58 and a.x < pen.x + 8
                    and a.y > pen.y + 8 and a.y < pen.y + pen.h - 8
            elseif pen.gate == "right" then
                inRace = a.x < pen.x + pen.w + 58 and a.x > pen.x + pen.w - 8
                    and a.y > pen.y + 8 and a.y < pen.y + pen.h - 8
            elseif pen.gate == "top" then
                inRace = a.y > pen.y - 58 and a.y < pen.y + 8
                    and a.x > pen.x + 8 and a.x < pen.x + pen.w - 8
            else
                inRace = a.y < pen.y + pen.h + 58 and a.y > pen.y + pen.h - 8
                    and a.x > pen.x + 8 and a.x < pen.x + pen.w - 8
            end
            if inRace then
                if not a.raceSeen then
                    a.raceSeen = true
                    Harness.count("raceIn")
                end
                local ix, iy = pen.x + pen.w / 2, pen.y + pen.h / 2
                local dx, dy = Util.norm(ix - a.x, iy - a.y)
                SX = SX + dx * 0.7
                SY = SY + dy * 0.7
            end
        end

        -- calm animals graze away from the fences (and out of corners)
        if a.agit < 40 then
            local f = G.field
            if a.x < 26 then SX = SX + 0.3 end
            if a.x > f.W - 26 then SX = SX - 0.3 end
            if a.y < 26 then SY = SY + 0.3 end
            if a.y > f.H - 26 then SY = SY - 0.3 end
        end

        -- breed attractions (only when settled)
        if not fleeing and not challenging and a.agit < 45 then
            if br.water and br.water > 0 then
                local pond, pd = Field.nearest(G.field.ponds, a.x, a.y, 150)
                if pond and pd > 8 then
                    local dx, dy = Util.norm(pond.x - a.x, pond.y - a.y)
                    SX = SX + dx * 0.35 * br.water
                    SY = SY + dy * 0.35 * br.water
                end
            end
            if br.rockLove then
                local rock, bd
                for _, c in ipairs(G.field.circles) do
                    if c.kind == "rock" then
                        local d = Util.dist(a.x, a.y, c.x, c.y)
                        if d < 130 and (not bd or d < bd) then rock, bd = c, d end
                    end
                end
                if rock and bd > rock.r + a.r + 4 then
                    local dx, dy = Util.norm(rock.x - a.x, rock.y - a.y)
                    SX = SX + dx * 0.3
                    SY = SY + dy * 0.3
                end
            end
        end

        -- follow the lead goose (or the gate it went through, once penned)
        if br.leaderFollow and not a.leader and a.leaderRef then
            local L = a.leaderRef
            local tx, ty = L.x, L.y
            if L.penned then tx, ty = G.field.pen.gx, G.field.pen.gy end
            local dx, dy, d = Util.norm(tx - a.x, ty - a.y)
            if d > 30 then
                SX = SX + dx * 1.1
                SY = SY + dy * 1.1
            end
        end

        -- soft obstacle avoidance (hard resolve happens after integration)
        for _, c in ipairs(G.field.circles) do
            local d = Util.dist(a.x, a.y, c.x, c.y)
            local pad = c.r + a.r + 16
            if d < pad and d > 0.001 then
                local w = 1.8 * (1 - d / pad)
                SX = SX + (a.x - c.x) / d * w
                SY = SY + (a.y - c.y) / d * w
            end
        end

        -- desired velocity
        local targetSpeed = Util.lerp(br.walk, br.flee, a.agit / 100)
        if fleeing then
            targetSpeed = math.max(targetSpeed, br.flee * (0.5 + 0.5 * prox))
        elseif challenging then
            targetSpeed = 32
        elseif a.agit < 25 then
            -- grazing: drift, pause, nibble
            if math.sin(G.t * 0.35 + a.grazeOff) > 0.25 then
                targetSpeed = 0
            else
                targetSpeed = targetSpeed * 0.4
            end
        end
        if Field.inPond(a.x, a.y) then
            targetSpeed = targetSpeed * ((br.water and br.water > 0.5) and 0.85 or 0.6)
        end

        local nx, ny, sl = Util.norm(SX, SY)
        local dvx, dvy = 0, 0
        if sl > 0.01 then
            dvx, dvy = nx * targetSpeed, ny * targetSpeed
        end
        local rate = fleeing and 5 or 3
        local k = math.min(1, rate * dt)
        a.vx = a.vx + (dvx - a.vx) * k
        a.vy = a.vy + (dvy - a.vy) * k
        local spd = math.sqrt(a.vx * a.vx + a.vy * a.vy)
        local cap = br.flee * 1.15
        if spd > cap then
            a.vx, a.vy = a.vx / spd * cap, a.vy / spd * cap
        end
        a.x = a.x + a.vx * dt
        a.y = a.y + a.vy * dt
        local rx, ry = Field.resolveCircle(a.x, a.y, a.r)
        if rx ~= a.x or ry ~= a.y then
            -- slide along the obstacle instead of pinning against it
            local nx2, ny2 = Util.norm(rx - a.x, ry - a.y)
            local dot = a.vx * nx2 + a.vy * ny2
            if dot < 0 then
                a.vx = a.vx - nx2 * dot
                a.vy = a.vy - ny2 * dot
            end
        end
        a.x, a.y = rx, ry
        if spd > 4 then
            a.fx, a.fy = Util.norm(a.vx, a.vy)
        end
        a.phase = (a.phase or 0) + spd * dt * 0.25

        -- Canada goose lands a peck
        if challenging and dgd < a.r + p.r + 3 and p.stunT <= 0 then
            Player.stun(0.7)
            local dx, dy = Util.norm(a.x - p.x, a.y - p.y)
            a.vx, a.vy = dx * 120, dy * 120
            a.agit = math.min(100, a.agit + 25)
            Sfx.goosed()
            Fx.text(p.x, p.y - 14, "HONK!")
            Harness.count("goosed")
        end

        -- through the gate and settled in
        if Field.inPen(a.x, a.y, 2) then
            a.penned = true
            a.agit = 0
            G.penned = G.penned + 1
            Sfx.penned()
            Fx.ring(a.x, a.y)
            Fx.text(a.x, a.y - 14, "+100")
            Harness.count("pennedN")
        end

        -- settle down
        a.agit = math.max(0, a.agit - br.calm * persona.calmAura * dt)
        a.obeyT = math.max(0, a.obeyT - dt)

        -- ambient calls
        a.callT = a.callT - dt
        if a.callT <= 0 then
            Sfx.call(a.species)
            a.callT = Util.rnd(6, 16)
        end
        ::continue::
    end

    -- keep bodies apart (single relaxation pass)
    for i = 1, #animals do
        local a = animals[i]
        for j = i + 1, #animals do
            local b = animals[j]
            if a.penned == b.penned then
                local dx, dy = b.x - a.x, b.y - a.y
                local d = math.sqrt(dx * dx + dy * dy)
                local minD = a.r + b.r
                if d < minD and d > 0.001 then
                    local push = (minD - d) / 2
                    dx, dy = dx / d, dy / d
                    a.x, a.y = a.x - dx * push, a.y - dy * push
                    b.x, b.y = b.x + dx * push, b.y + dy * push
                end
            end
        end
    end
end
