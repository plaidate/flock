-- Flock - you are a sheepdog. Gather sheep, goats, ducks and geese and
-- drive them through the gate before the clock runs out. Crank steers,
-- up runs, down brakes, B creeps, A barks. Fields grow from one screen
-- into scrolling pastures across a 12-level trial ladder.

import "CoreLibs/graphics"

import "config"
import "util"
import "harness"
import "breeds"
import "dogs"
import "levels"
import "save"
import "sfx"
import "fx"
import "field"
import "flock"
import "player"
import "input"
import "draw"

local gfx = playdate.graphics

G = {
    state = "title",
    t = 0, st = 0,
    dogIdx = 1,
    levelIdx = 1,
    sel = 1,
    penned = 0, need = 0,
    timeLeft = 0,
    result = nil,
}

Save.load()
math.randomseed(SMOKE_BUILD and (SMOKE_SEED or 1) or playdate.getSecondsSinceEpoch())
playdate.display.setRefreshRate(SMOKE_BUILD and 0 or 30)
Harness.shotPath = "build/flock-shot.png"
Harness.shotSeq = true
G.dogIdx = Util.clamp(Save.data.lastDog, 1, #Dogs)

local function setState(s)
    G.state = s
    G.st = 0
end

local function startLevel(idx)
    local lvl = Levels[idx]
    G.levelIdx = idx
    Field.build(lvl)
    Flock.spawn(lvl)
    Player.reset()
    Fx.reset()
    Input.resetBot()
    G.penned = 0
    G.need = lvl.need
    G.timeLeft = lvl.time
    G.closeT = nil
    Draw.resetCam()
    Sfx.whistleStart()
    Harness.set("level", idx)
    setState("play")
end

local function finishLevel(won)
    if won then
        local score = G.penned * 100 + math.floor(G.timeLeft) * 10
        local best = Save.recordWin(G.levelIdx, score, Dogs[G.dogIdx].key)
        G.result = { won = true, score = score, best = best }
        Sfx.whistleDone()
        Harness.count("cleared")
    else
        G.result = { won = false }
        Sfx.fail()
        Harness.count("fails")
    end
    setState("result")
end

-- ------------------------------------------------------------- states

local function updatePlay(dt)
    local inp = Input.gather()
    Player.update(inp, dt)
    Flock.update(dt)
    Fx.update(dt)
    Draw.updateCam(dt)
    G.timeLeft = G.timeLeft - dt
    if G.closeT then
        -- the shepherd is swinging the gate shut
        G.closeT = G.closeT - dt
        if G.closeT <= 0 then
            finishLevel(true)
        end
    elseif G.penned >= G.need then
        G.closeT = 0.9
        Sfx.gateClose()
    elseif G.timeLeft <= 0 then
        finishLevel(false)
    end
    Draw.play()
end

local function updateTitle()
    -- a little parade drifting under the logo
    gfx.clear(gfx.kColorWhite)
    Util.bigText("FLOCK", 200, 48, 3)
    gfx.drawTextAligned("a sheepdog trial", 200, 100, kTextAlignment.center)
    gfx.drawTextAligned("Crank steers - Up runs - Down brakes", 200, 170, kTextAlignment.center)
    gfx.drawTextAligned("B creep - A bark", 200, 188, kTextAlignment.center)
    gfx.drawTextAligned("press A", 200, 214, kTextAlignment.center)
    local px = (G.t * 40) % 480 - 40
    Draw.dog(px, 140, 0, Dogs[1], false, 0)
    for i = 1, 4 do
        gfx.setColor(gfx.kColorWhite)
        gfx.fillEllipseInRect(px + 30 + i * 24 + math.sin(G.t * 3 + i) * 3, 134, 16, 12)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawEllipseInRect(px + 30 + i * 24 + math.sin(G.t * 3 + i) * 3, 134, 16, 12)
    end
    if Input.confirm() then
        Sfx.uiOk()
        G.sel = G.dogIdx
        setState("dogsel")
    end
end

local function statPips(n)
    local s = ""
    for i = 1, 4 do
        s = s .. (i <= n and "*" or "-")
    end
    return s
end

local function updateDogsel()
    gfx.clear(gfx.kColorWhite)
    gfx.drawTextAligned("CHOOSE YOUR DOG", 200, 8, kTextAlignment.center)
    if Harness.enabled then
        G.sel = ((SMOKE_SEED or 1) % #Dogs) + 1
    else
        local dx = select(1, Input.menuDelta())
        if dx ~= 0 then
            Sfx.uiMove()
            G.sel = ((G.sel - 1 + dx) % #Dogs) + 1
        end
    end
    local d = Dogs[G.sel]
    Draw.dog(200, 80, 315 + math.sin(G.t) * 10, d, false, 0, 2.4)
    Util.bigText(d.name, 200, 110, 2)
    gfx.drawTextAligned(d.breed, 200, 146, kTextAlignment.center)
    gfx.drawTextAligned(d.blurb, 200, 164, kTextAlignment.center)
    gfx.drawText("SPEED " .. statPips(d.stats.spd), 20, 200)
    gfx.drawTextAligned("BARK " .. statPips(d.stats.bark), 200, 200, kTextAlignment.center)
    gfx.drawTextAligned("EYE " .. statPips(d.stats.eye), 380, 200, kTextAlignment.right)
    gfx.drawTextAligned("< > choose   A pick", 200, 222, kTextAlignment.center)
    if Input.confirm() then
        Sfx.uiOk()
        G.dogIdx = G.sel
        Save.data.lastDog = G.sel
        Save.write()
        G.sel = Util.clamp(Save.data.unlocked, 1, #Levels)
        setState("levelsel")
    end
end

local function updateLevelsel()
    gfx.clear(gfx.kColorWhite)
    gfx.drawTextAligned("TRIALS", 200, 6, kTextAlignment.center)
    local unlocked = Save.data.unlocked
    if Harness.enabled then
        G.sel = Util.clamp(unlocked, 1, #Levels)
    else
        local dx, dy = Input.menuDelta()
        local col = (G.sel - 1) // 6
        local row = (G.sel - 1) % 6
        col = Util.clamp(col + dx, 0, 1)
        row = Util.clamp(row + dy, 0, 5)
        local newSel = col * 6 + row + 1
        if newSel ~= G.sel and newSel <= #Levels then
            Sfx.uiMove()
            G.sel = newSel
        end
        if playdate.buttonJustPressed(playdate.kButtonB) then
            setState("dogsel")
            return
        end
    end
    for i, lvl in ipairs(Levels) do
        local col = (i - 1) // 6
        local row = (i - 1) % 6
        local x = 16 + col * 192
        local y = 26 + row * 30
        local locked = i > unlocked
        if i == G.sel then
            gfx.fillRect(x - 6, y + 4, 4, 8)
        end
        if locked then
            gfx.drawText("#" .. i .. " ----------", x, y)
        else
            gfx.drawText("#" .. i .. " " .. lvl.name, x, y)
            local b = Save.data.best[tostring(i)]
            if b then
                gfx.drawText(tostring(b.score), x + 130, y)
            end
        end
    end
    gfx.drawTextAligned("A start   B dogs", 200, 222, kTextAlignment.center)
    if Input.confirm() and G.sel <= unlocked then
        Sfx.uiOk()
        startLevel(G.sel)
    end
end

local function updateResult(dt)
    -- keep the world alive behind the card
    Fx.update(dt)
    Draw.play()
    local x, y = Draw.overlayBox(240, 120)
    local r = G.result
    if r.won then
        gfx.drawTextAligned("THAT'LL DO!", 200, y + 12, kTextAlignment.center)
        gfx.drawTextAligned("penned " .. G.penned .. " of " .. #G.animals, 200, y + 38, kTextAlignment.center)
        gfx.drawTextAligned("score " .. r.score .. (r.best and "  * BEST *" or ""), 200, y + 58, kTextAlignment.center)
        gfx.drawTextAligned("A onward", 200, y + 92, kTextAlignment.center)
    else
        gfx.drawTextAligned("TIME'S UP", 200, y + 12, kTextAlignment.center)
        gfx.drawTextAligned("the flock scattered...", 200, y + 38, kTextAlignment.center)
        gfx.drawTextAligned("penned " .. G.penned .. " of " .. G.need .. " needed", 200, y + 58, kTextAlignment.center)
        gfx.drawTextAligned("A try again", 200, y + 92, kTextAlignment.center)
    end
    local go = Harness.enabled and G.st > 1.2 or
        (not Harness.enabled and playdate.buttonJustPressed(playdate.kButtonA))
    if go then
        if r.won then
            if G.levelIdx < #Levels then
                startLevel(G.levelIdx + 1)
            else
                setState("levelsel")
            end
        else
            startLevel(G.levelIdx)
        end
    end
end

-- ------------------------------------------------------------- loop

Harness.extra = function(t)
    t.state = G.state
    t.penned = G.penned
    t.need = G.need
    t.timeLeft = math.floor(G.timeLeft)
    t.unlocked = Save.data.unlocked
    if G.state == "play" and G.player then
        t.dogx = math.floor(G.player.x)
        t.dogy = math.floor(G.player.y)
        local cx, cy, cr = Flock.centroid()
        if cx then
            t.ccx, t.ccy, t.crad = math.floor(cx), math.floor(cy), math.floor(cr)
        end
    end
end

local frame = 0

local function doUpdate()
    local dt = C.DT
    G.t = G.t + dt
    G.st = G.st + dt
    Util.update(dt)
    Sfx.update(dt)
    if G.state == "title" then
        updateTitle()
    elseif G.state == "dogsel" then
        updateDogsel()
    elseif G.state == "levelsel" then
        updateLevelsel()
    elseif G.state == "play" then
        updatePlay(dt)
    elseif G.state == "result" then
        updateResult(dt)
    end
end

function playdate.update()
    frame = frame + 1
    Harness.frame(frame, doUpdate)
end
