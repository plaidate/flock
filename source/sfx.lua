-- Synth sound effects: a farmyard kit built from raw waves - reasonable
-- facsimiles rather than samples. Bleats are wobbled saws, quacks are
-- pitch-dropped squares, honks are two-tone squares, barks are noise+saw
-- thumps. Animal calls are rate-limited so a big flock doesn't become a
-- wall of noise.

local snd <const> = playdate.sound

Sfx = { gateT = 0 }

local tri = snd.synth.new(snd.kWaveTriangle)
local tri2 = snd.synth.new(snd.kWaveTriangle)
local sq = snd.synth.new(snd.kWaveSquare)
local sq2 = snd.synth.new(snd.kWaveSquare)
local saw = snd.synth.new(snd.kWaveSawtooth)
local saw2 = snd.synth.new(snd.kWaveSawtooth)
local noise = snd.synth.new(snd.kWaveNoise)

function Sfx.update(dt)
    Sfx.gateT = math.max(0, Sfx.gateT - dt)
end

-- one animal voice at a time, minimum gap between calls
local function gated()
    if Sfx.gateT > 0 then return false end
    Sfx.gateT = 0.28
    return true
end

function Sfx.blip(f)
    tri:playNote(f or 660, 0.25, 0.05)
end

-- "b-a-a-a": wobble a saw around the root
function Sfx.bleat(root)
    if not gated() then return end
    root = root or Util.rnd(300, 380)
    for i = 0, 4 do
        local f = root * (i % 2 == 0 and 1 or 0.94)
        Util.after(i * 0.055, function() saw:playNote(f, 0.16, 0.06) end)
    end
end

-- shorter, harsher "mehh"
function Sfx.mehh(root)
    if not gated() then return end
    root = root or Util.rnd(420, 520)
    for i = 0, 2 do
        local f = root * (i % 2 == 0 and 1 or 0.9)
        Util.after(i * 0.05, function() saw2:playNote(f, 0.18, 0.05) end)
    end
    Util.after(0.16, function() saw2:playNote(root * 0.8, 0.14, 0.09) end)
end

-- flat little quack, sometimes doubled
function Sfx.quack(n)
    if not gated() then return end
    n = n or (math.random(2) == 1 and 2 or 1)
    for i = 0, n - 1 do
        Util.after(i * 0.13, function()
            sq:playNote(Util.rnd(280, 330), 0.16, 0.04)
            Util.after(0.035, function() sq:playNote(200, 0.12, 0.05) end)
        end)
    end
end

-- two-tone goose honk
function Sfx.honk(angry)
    if not gated() and not angry then return end
    local root = angry and 330 or Util.rnd(240, 280)
    sq2:playNote(root, 0.2, 0.09)
    Util.after(0.09, function() sq2:playNote(root * 0.68, 0.18, 0.14) end)
    if angry then
        Util.after(0.2, function() sq2:playNote(root * 1.1, 0.2, 0.08) end)
    end
end

function Sfx.call(species)
    if species == "sheep" then Sfx.bleat()
    elseif species == "goat" then Sfx.mehh()
    elseif species == "duck" then Sfx.quack()
    else Sfx.honk(false) end
end

-- persona-pitched "ruff!"
function Sfx.bark(freq)
    noise:playNote(500, 0.4, 0.05)
    saw:playNote(freq or 320, 0.35, 0.07)
    Util.after(0.06, function() saw:playNote((freq or 320) * 0.62, 0.3, 0.09) end)
end

-- creak of the swinging gate leaf, then the wooden clunk of the latch
function Sfx.gateClose()
    saw2:playNote(280, 0.2, 0.35)
    Util.after(0.18, function() saw2:playNote(210, 0.18, 0.3) end)
    Util.after(0.75, function()
        sq:playNote(95, 0.4, 0.09)
        noise:playNote(240, 0.35, 0.06)
    end)
end

function Sfx.penned()
    tri2:playNote(660, 0.25, 0.05)
    Util.after(0.06, function() tri2:playNote(880, 0.25, 0.07) end)
end

function Sfx.goosed()
    sq2:playNote(360, 0.28, 0.07)
    noise:playNote(700, 0.3, 0.06)
    Util.after(0.08, function() sq2:playNote(250, 0.22, 0.1) end)
end

-- shepherd's whistle: level start ("away!") sweeps up
function Sfx.whistleStart()
    for i = 0, 5 do
        Util.after(i * 0.04, function() tri:playNote(900 + i * 130, 0.22, 0.045) end)
    end
end

-- "that'll do" - three falling notes
function Sfx.whistleDone()
    local seq = { 1400, 1150, 900 }
    for i, f in ipairs(seq) do
        Util.after((i - 1) * 0.12, function() tri:playNote(f, 0.25, 0.1) end)
    end
end

function Sfx.fail()
    local seq = { 400, 340, 260, 180 }
    for i, f in ipairs(seq) do
        Util.after((i - 1) * 0.14, function() saw:playNote(f, 0.22, 0.12) end)
    end
end

function Sfx.uiMove()
    tri:playNote(520, 0.18, 0.03)
end

function Sfx.uiOk()
    tri:playNote(660, 0.22, 0.04)
    Util.after(0.05, function() tri:playNote(990, 0.22, 0.06) end)
end
