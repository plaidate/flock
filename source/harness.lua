-- Smoke-test harness. The Makefile stages smokeflag.lua: SMOKE_BUILD false
-- for release (no-op), true for `make smoke` (pcall-wrapped update writing
-- errors to the "err" datastore, a 90-frame heartbeat to "smoke", periodic
-- screenshots, and an autopilot the input module consults).

import "smokeflag"

Harness = {
    enabled = SMOKE_BUILD,
    counters = {},
    autopilot = nil,
    extra = nil,
    shotPath = nil,
}

function Harness.count(key, n)
    if not Harness.enabled then return end
    Harness.counters[key] = (Harness.counters[key] or 0) + (n or 1)
end

function Harness.set(key, val)
    if not Harness.enabled then return end
    Harness.counters[key] = val
end

function Harness.frame(frame, updateFn)
    if not Harness.enabled then
        updateFn()
        return
    end
    local ok, err = pcall(updateFn)
    if not ok then
        playdate.datastore.write({ err = tostring(err) }, "err")
    end
    if frame % 90 == 0 then
        local t = {}
        for k, v in pairs(Harness.counters) do t[k] = v end
        t.frame = frame
        if Harness.extra then pcall(Harness.extra, t) end
        playdate.datastore.write(t, "smoke")
    end
    if Harness.shotPath and frame % 150 == 0 and playdate.simulator then
        local p = Harness.shotPath
        if Harness.shotSeq then
            p = string.gsub(p, "%.png$", string.format("-%02d.png", math.floor(frame / 150) % 24))
        end
        playdate.simulator.writeToFile(playdate.graphics.getDisplayImage(), p)
    end
end
