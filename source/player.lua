-- The dog. Crank turns the heading 1:1 (d-pad left/right when docked),
-- up/down pick run/brake around a default trot, B creeps (slow stalk that
-- keeps pressure without spooking - how much depends on the persona's
-- "eye"), A barks. pmod scales how far the flock feels the dog: fast
-- approach looms large, a creep stays quiet.

Player = {}

function Player.reset()
    local pen = G.field.pen
    G.player = {
        x = Util.clamp(pen.gx - 40, 20, G.field.W - 20),
        y = Util.clamp(pen.gy + 60, 20, G.field.H - 20),
        heading = 180,
        speed = 0,
        r = 7,
        barkCd = 0, barkT = 0, stunT = 0,
        creep = false,
        pmod = 0.55,
        bob = 0,
    }
end

function Player.stun(t)
    G.player.stunT = math.max(G.player.stunT, t)
end

function Player.update(inp, dt)
    local p = G.player
    local persona = Dogs[G.dogIdx]

    p.barkCd = math.max(0, p.barkCd - dt)
    p.barkT = math.max(0, p.barkT - dt)
    p.stunT = math.max(0, p.stunT - dt)
    p.creep = inp.creep and p.stunT <= 0

    -- steering
    p.heading = p.heading + inp.crank * C.CRANK_GAIN * persona.turn
    p.heading = p.heading + inp.turn * C.DOCK_TURN * persona.turn * dt
    p.heading = p.heading % 360

    -- speed
    local target
    if p.stunT > 0 then
        target = 0
    elseif inp.up then
        target = persona.run
    elseif inp.down then
        target = 0
    else
        target = persona.trot
    end
    if p.creep then
        target = math.min(target, persona.creep)
    end
    if Field.inPond(p.x, p.y) then
        target = target * C.POND_SLOW
    end
    local rate = (target < p.speed) and C.BRAKE or C.ACCEL
    p.speed = p.speed + (target - p.speed) * math.min(1, rate * dt)

    local rad = math.rad(p.heading)
    p.x = p.x + math.cos(rad) * p.speed * dt
    p.y = p.y + math.sin(rad) * p.speed * dt
    p.x, p.y = Field.resolveCircle(p.x, p.y, p.r)
    p.bob = p.bob + p.speed * dt * 0.2

    -- how loud the dog's presence is right now
    if p.creep then
        p.pmod = 0.25 + 0.6 * persona.creepPressure
    else
        p.pmod = 0.55 + 0.65 * (p.speed / persona.run)
    end

    -- bark
    if inp.bark and p.barkCd <= 0 and p.stunT <= 0 then
        p.barkT = 0.3
        p.barkCd = persona.barkCd
        Sfx.bark(persona.barkFreq)
        Flock.bark(p.x, p.y, persona)
        Fx.ring(p.x, p.y)
        Fx.ring(p.x, p.y, 10)
        Harness.count("barks")
    end
    if p.creep then
        Harness.count("creepT", dt)
    end
end
