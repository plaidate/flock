-- The trial ladder. Fields grow from a single screen (400x240) into
-- scrolling pastures; each level introduces a breed or obstacle idea.
--   W,H     field size in px
--   time    seconds on the clock
--   need    animals that must be penned to pass (of the total)
--   pen     {x, y, w, h, gate="left"|"right"|"top"|"bottom"}
--   groups  {species, breed, n, sx, sy} spawn clusters
--   obs     {type="rock"|"tree"|"pond"|"wall", ...}

Levels = {
    {
        name = "First Gather", W = 400, H = 240, time = 120, need = 5,
        pen = { x = 306, y = 82, w = 76, h = 76, gate = "left" },
        groups = { { species = "sheep", breed = "merino", n = 6, sx = 115, sy = 120 } },
        obs = {},
    },
    {
        name = "Two Rocks", W = 480, H = 280, time = 130, need = 6,
        pen = { x = 384, y = 100, w = 76, h = 76, gate = "left" },
        groups = { { species = "sheep", breed = "merino", n = 7, sx = 115, sy = 140 } },
        obs = {
            { type = "rock", x = 240, y = 90, r = 16 },
            { type = "rock", x = 210, y = 200, r = 13 },
        },
    },
    {
        name = "Strays", W = 520, H = 300, time = 140, need = 6,
        pen = { x = 420, y = 110, w = 76, h = 76, gate = "left" },
        groups = { { species = "sheep", breed = "blackface", n = 7, sx = 112, sy = 150 } },
        obs = {
            { type = "rock", x = 250, y = 80, r = 14 },
            { type = "tree", x = 280, y = 220, r = 18 },
            { type = "rock", x = 150, y = 60, r = 11 },
        },
    },
    {
        name = "Stubborn Company", W = 520, H = 320, time = 120, need = 6,
        pen = { x = 420, y = 120, w = 76, h = 76, gate = "left" },
        groups = { { species = "goat", breed = "boer", n = 7, sx = 112, sy = 160 } },
        obs = {
            { type = "wall", x = 250, y = 70, w = 8, h = 110 },
            { type = "tree", x = 170, y = 250, r = 16 },
        },
    },
    {
        name = "Rocky Tops", W = 560, H = 340, time = 120, need = 7,
        pen = { x = 458, y = 130, w = 76, h = 76, gate = "left" },
        groups = { { species = "goat", breed = "alpine", n = 8, sx = 112, sy = 170 } },
        obs = {
            { type = "rock", x = 200, y = 90, r = 16 },
            { type = "rock", x = 320, y = 250, r = 18 },
            { type = "rock", x = 260, y = 170, r = 12 },
            { type = "rock", x = 420, y = 60, r = 13 },
        },
    },
    {
        name = "Duck Duck Run", W = 560, H = 300, time = 110, need = 8,
        pen = { x = 458, y = 110, w = 76, h = 76, gate = "left" },
        groups = { { species = "duck", breed = "runner", n = 9, sx = 112, sy = 150 } },
        obs = {
            { type = "pond", x = 220, y = 160, r = 34 },
            { type = "wall", x = 380, y = 60, w = 8, h = 70 },
            { type = "wall", x = 380, y = 200, w = 8, h = 70 },
        },
    },
    {
        name = "Puddle Trouble", W = 600, H = 360, time = 130, need = 7,
        pen = { x = 498, y = 140, w = 76, h = 76, gate = "left" },
        groups = { { species = "duck", breed = "mallard", n = 9, sx = 112, sy = 180 } },
        obs = {
            { type = "pond", x = 200, y = 110, r = 36 },
            { type = "pond", x = 330, y = 270, r = 30 },
            { type = "tree", x = 300, y = 80, r = 15 },
        },
    },
    {
        name = "Follow the Leader", W = 640, H = 360, time = 120, need = 8,
        pen = { x = 538, y = 140, w = 76, h = 76, gate = "left" },
        groups = { { species = "goose", breed = "greylag", n = 9, sx = 112, sy = 180 } },
        obs = {
            { type = "tree", x = 260, y = 100, r = 16 },
            { type = "tree", x = 300, y = 180, r = 16 },
            { type = "tree", x = 260, y = 260, r = 16 },
        },
    },
    {
        name = "Honk of War", W = 640, H = 380, time = 130, need = 7,
        pen = { x = 538, y = 150, w = 76, h = 76, gate = "left" },
        groups = { { species = "goose", breed = "canada", n = 8, sx = 112, sy = 190 } },
        obs = {
            { type = "rock", x = 280, y = 110, r = 15 },
            { type = "rock", x = 240, y = 280, r = 14 },
            { type = "pond", x = 400, y = 90, r = 32 },
        },
    },
    {
        name = "Mixed Mob", W = 700, H = 420, time = 150, need = 9,
        pen = { x = 596, y = 170, w = 80, h = 80, gate = "left" },
        groups = {
            { species = "sheep", breed = "merino", n = 6, sx = 112, sy = 140 },
            { species = "goat", breed = "boer", n = 5, sx = 118, sy = 300 },
        },
        obs = {
            { type = "wall", x = 340, y = 100, w = 8, h = 130 },
            { type = "rock", x = 250, y = 300, r = 16 },
            { type = "tree", x = 470, y = 320, r = 18 },
        },
    },
    {
        name = "Water Meadow", W = 760, H = 440, time = 160, need = 10,
        pen = { x = 656, y = 180, w = 80, h = 80, gate = "left" },
        groups = {
            { species = "duck", breed = "mallard", n = 6, sx = 112, sy = 150 },
            { species = "goose", breed = "greylag", n = 6, sx = 118, sy = 320 },
        },
        obs = {
            { type = "pond", x = 260, y = 130, r = 38 },
            { type = "pond", x = 380, y = 330, r = 34 },
            { type = "wall", x = 540, y = 120, w = 8, h = 90 },
            { type = "wall", x = 540, y = 300, w = 8, h = 90 },
            { type = "tree", x = 300, y = 240, r = 16 },
        },
    },
    {
        name = "The Grand Trial", W = 880, H = 520, time = 200, need = 14,
        pen = { x = 772, y = 220, w = 84, h = 84, gate = "left" },
        groups = {
            { species = "sheep", breed = "blackface", n = 4, sx = 112, sy = 130 },
            { species = "goat", breed = "alpine", n = 4, sx = 118, sy = 400 },
            { species = "duck", breed = "runner", n = 4, sx = 200, sy = 260 },
            { species = "goose", breed = "canada", n = 4, sx = 320, sy = 130 },
        },
        obs = {
            { type = "pond", x = 430, y = 380, r = 40 },
            { type = "rock", x = 300, y = 330, r = 17 },
            { type = "rock", x = 520, y = 120, r = 15 },
            { type = "tree", x = 560, y = 300, r = 18 },
            { type = "tree", x = 380, y = 60, r = 15 },
            { type = "wall", x = 660, y = 150, w = 8, h = 100 },
            { type = "wall", x = 660, y = 370, w = 8, h = 100 },
        },
    },
}
