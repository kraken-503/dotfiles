---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = false,
        },
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})

-- 3 finger gesture for screenshot

hl.gesture({
  fingers = 3,
  direction = "down",
  action = function()
    hl.exec_cmd("hyprshot -m output -m eDP-1 -o ~/Pictures/Screenshots/")
  end
})

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/ for more
--hl.device({
--    name        = "epic-mouse-v1",
--    sensitivity = -0.5,
--})
