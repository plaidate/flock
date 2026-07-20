-- Progress: highest unlocked level + best score per level (with the dog
-- that set it), and the last persona picked.

Save = { data = nil }

function Save.load()
    Save.data = playdate.datastore.read("save") or {}
    Save.data.unlocked = Save.data.unlocked or 1
    Save.data.best = Save.data.best or {}
    Save.data.lastDog = Save.data.lastDog or 1
end

function Save.write()
    playdate.datastore.write(Save.data, "save")
end

function Save.recordWin(levelIdx, score, dogKey)
    local d = Save.data
    if levelIdx >= d.unlocked and levelIdx < #Levels then
        d.unlocked = levelIdx + 1
    end
    local k = tostring(levelIdx)
    local prev = d.best[k]
    local isBest = (not prev) or score > prev.score
    if isBest then
        d.best[k] = { score = score, dog = dogKey }
    end
    Save.write()
    return isBest
end
