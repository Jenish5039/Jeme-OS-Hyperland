-- -----------------------------------------------------
-- Input
-- -----------------------------------------------------

hl.config({
    input = {
        kb_layout    = "us",
        kb_variant   = "",
        kb_model     = "",
        kb_options   = "",
        kb_rules     = "",

        follow_mouse = 1,

        sensitivity  = 0.0,
        accel_profile = "flat",
        force_no_accel = true,
        scroll_factor = 0.4,

        touchpad     = {
            natural_scroll = true,
            disable_while_typing = true,
            clickfinger_behavior = true,
        },
    },
    cursor = {
        no_hardware_cursors = false,
        no_warps = true,
        enable_hyprcursor = true,
        sync_gsettings_theme = true,
    },
})
