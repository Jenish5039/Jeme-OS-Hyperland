-- -----------------------------------------------------
-- Window and Layer Rules
-- -----------------------------------------------------

-- Layer rules for screenshot and selection overlays
-- Disables slide/in/out animations for region selection to prevent visual screen jump/flicker
hl.layer_rule({
    name = "no-anim-selection",
    match = { namespace = "^selection$" },
    no_anim = true,
})

hl.layer_rule({
    name = "no-anim-hyprpicker",
    match = { namespace = "^hyprpicker$" },
    no_anim = true,
})



-- Google Meet auxiliary/picture-in-picture floating popup layout constraints
hl.window_rule({
    name = "google-meet-pip-layout",
    match = {
        title = [=[^(Meet [–-]|meet\.google\.com)]=],
    },
    float = true,
    min_size = { 460, 360 },
    size = { 500, 420 },
})

-- Steam update dialog and helper popups
hl.window_rule({
    name = "steam-updater-dialogs",
    match = {
        class = [=[^([Ss]team)$]=],
        title = [=[^(Steam - Self Updater|Updating Steam.*|Steam Settings|Friends List.*)$]=],
    },
    float = true,
    center = true,
})