-- Tunables shared across modules.

C = {
    DT = 1 / 30,

    SCREEN_W = 400,
    SCREEN_H = 240,
    HUD_H = 18,

    -- dog handling
    CRANK_GAIN = 1.0,   -- degrees of heading per degree of crank
    DOCK_TURN = 170,    -- deg/s from d-pad left/right when crank is docked
    ACCEL = 6,          -- speed lerp rate per second
    BRAKE = 9,
    POND_SLOW = 0.55,

    -- herding pressure
    NEIGHBOR_R = 70,    -- boid neighbourhood radius
    SEP_PAD = 6,        -- extra spacing beyond touching
    PANIC_AT = 75,      -- agitation level that counts as panicked
    BARK_OBEY = 5,      -- seconds stubborn/aggressive animals behave after a bark

    -- pen
    PEN_WALL = 5,
    PEN_GAP = 40,

    CAM_LEAD = 0.30,    -- camera looks from dog toward flock centroid
    CAM_RATE = 4,
}
