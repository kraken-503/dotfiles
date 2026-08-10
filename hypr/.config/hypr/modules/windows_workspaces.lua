--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

local suppressMaximizeRule = hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- Hyprland-run windowrule
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move  = "20 monitor_h-120",
    float = true,
})

--Amberol float
hl.window_rule({
  name = "Amberol",
  match = {class = "io.bassi.Amberol" },
  float = true,
  size = {642,788},
  animation = "popin",
})

--Matuwall blur
hl.layer_rule({ match = { namespace = "matuwall" }, blur = true, ignore_alpha = 0.5, })

--file picker centering float
hl.window_rule({
  name      = "file-picker",
  match     = { class = "xdg-desktop-portal-gtk" },
  move      = {504, 239},
  size      = {946,593},
  animation = "popin",
})


--hl.on("window.floating", function(event)
 -- if event.floating == true and event.window.class == "mpv" then
 --   hl.dispatch("resizewindowpixel", "exact 1280 720, address:" .. event.window.address)
--    hl.dispatch("centerwindow", "address:" .. event.window.address)
--  end
--end)

