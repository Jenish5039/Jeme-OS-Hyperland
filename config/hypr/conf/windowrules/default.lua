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

-- Layer rules for Rofi launcher
hl.layer_rule({
    name = "rofi-blur",
    match = { namespace = "^rofi$" },
    blur = true,
    ignore_alpha = 0.5,
    no_anim = true,
})