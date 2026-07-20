-- Species and breeds. Every animal is a boid; a breed is a parameter set:
--   coh/ali/sep  boids weights (cohesion, alignment, separation)
--   walk/flee    speed range in px/s, blended by agitation
--   fearR        base radius the dog's pressure reaches (scaled by persona
--                presence and dog speed)
--   fearGain     how hard they push away inside that radius
--   spook        agitation gained per second under pressure
--   calm         agitation shed per second
--   wayward      random-wander weight (stragglers come from this)
--   panic        "clump" (threat -> huddle) or "scatter" (threat -> explode)
-- flags: stubborn (ignores quiet pressure until barked at), challenge
-- (turns on the dog - Canada geese), water (pond-loving), rockLove
-- (drifts to rocks), leaderFollow (tails the flock leader).

Breeds = {
    sheep = {
        merino = {
            label = "Merino", coh = 1.4, ali = 0.8, sep = 1.0,
            walk = 14, flee = 95, fearR = 80, fearGain = 1.2,
            spook = 26, calm = 9, wayward = 0.4, panic = "clump", r = 8,
        },
        blackface = {
            label = "Blackface", coh = 0.55, ali = 0.4, sep = 1.3,
            walk = 18, flee = 105, fearR = 70, fearGain = 1.0,
            spook = 30, calm = 7, wayward = 1.5, panic = "scatter", r = 8,
            darkHead = true,
        },
    },
    goat = {
        boer = {
            label = "Boer", coh = 0.7, ali = 0.35, sep = 1.2,
            walk = 16, flee = 100, fearR = 62, fearGain = 0.85,
            spook = 18, calm = 12, wayward = 1.1, panic = "scatter", r = 8,
            stubborn = true, horns = true, darkHead = true,
        },
        alpine = {
            label = "Alpine", coh = 0.6, ali = 0.4, sep = 1.2,
            walk = 20, flee = 115, fearR = 66, fearGain = 1.0,
            spook = 22, calm = 10, wayward = 1.6, panic = "scatter", r = 8,
            rockLove = true, horns = true,
        },
    },
    duck = {
        runner = {
            label = "Runner", coh = 1.0, ali = 1.7, sep = 0.7,
            walk = 22, flee = 85, fearR = 85, fearGain = 1.3,
            spook = 24, calm = 10, wayward = 0.5, panic = "clump", r = 6,
            water = 0.25, upright = true,
        },
        mallard = {
            label = "Mallard", coh = 0.8, ali = 0.6, sep = 0.9,
            walk = 12, flee = 75, fearR = 75, fearGain = 1.1,
            spook = 34, calm = 8, wayward = 1.0, panic = "scatter", r = 6,
            water = 1.0, darkHead = true,
        },
    },
    goose = {
        greylag = {
            label = "Greylag", coh = 0.7, ali = 0.9, sep = 0.9,
            walk = 16, flee = 90, fearR = 75, fearGain = 1.1,
            spook = 22, calm = 10, wayward = 0.6, panic = "clump", r = 7,
            water = 0.5, longNeck = true, leaderFollow = true,
        },
        canada = {
            label = "Canada", coh = 0.75, ali = 0.7, sep = 1.0,
            walk = 15, flee = 95, fearR = 66, fearGain = 0.95,
            spook = 18, calm = 12, wayward = 0.8, panic = "scatter", r = 7,
            water = 0.5, longNeck = true, darkHead = true, challenge = true,
        },
    },
}
