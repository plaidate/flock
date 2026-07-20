-- Sheepdog personas. Feel comes from speed, turn rate, presence (how far
-- the flock feels you), spookMod (how much your pressure agitates),
-- creepPressure (how much reach the creep keeps - the "strong eye"),
-- bark shape and calmAura (how fast animals settle around you).

Dogs = {
    {
        key = "gwen", name = "Gwen", breed = "Border Collie",
        blurb = "The steady eye. Creeps without\nspooking; every move exact.",
        run = 135, trot = 72, creep = 36, turn = 1.0,
        presence = 1.0, spookMod = 1.0, creepPressure = 1.0,
        barkR = 95, barkSpook = 26, barkPush = 55, barkCd = 1.2,
        barkFreq = 400, calmAura = 1.0,
        stats = { spd = 3, bark = 2, eye = 4 },
        look = { size = 1.0, ears = "prick", tail = "feather", shaggy = false, patch = true },
    },
    {
        key = "bramble", name = "Bramble", breed = "Bearded Collie",
        blurb = "A big voice. Her bark gathers\nstrays from half the field.",
        run = 125, trot = 70, creep = 34, turn = 0.85,
        presence = 0.95, spookMod = 1.05, creepPressure = 0.55,
        barkR = 135, barkSpook = 30, barkPush = 70, barkCd = 0.9,
        barkFreq = 180, calmAura = 1.0,
        stats = { spd = 3, bark = 4, eye = 2 },
        look = { size = 1.05, ears = "drop", tail = "feather", shaggy = true, patch = false },
    },
    {
        key = "pip", name = "Pip", breed = "Corgi",
        blurb = "Small, sharp, unhurried.\nAnimals barely startle at Pip.",
        run = 112, trot = 64, creep = 32, turn = 1.25,
        presence = 0.78, spookMod = 0.7, creepPressure = 0.75,
        barkR = 72, barkSpook = 20, barkPush = 45, barkCd = 1.1,
        barkFreq = 700, calmAura = 1.5,
        stats = { spd = 2, bark = 1, eye = 3 },
        look = { size = 0.8, ears = "bigprick", tail = "bob", shaggy = false, patch = false },
    },
    {
        key = "flint", name = "Flint", breed = "Kelpie",
        blurb = "All engine. Fastest paws in\nthe yard - the flock feels it.",
        run = 150, trot = 82, creep = 38, turn = 0.9,
        presence = 1.15, spookMod = 1.35, creepPressure = 0.45,
        barkR = 105, barkSpook = 30, barkPush = 75, barkCd = 1.3,
        barkFreq = 300, calmAura = 0.8,
        stats = { spd = 4, bark = 3, eye = 1 },
        look = { size = 0.95, ears = "prick", tail = "straight", shaggy = false, patch = false, dark = true },
    },
}
