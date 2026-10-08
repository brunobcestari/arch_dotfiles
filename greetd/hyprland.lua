-- Minimal Hyprland session used only to host the ReGreet greeter.
-- Hyprland exits as soon as ReGreet closes, handing control back to greetd.
hl.on("hyprland.start", function()
    hl.exec_cmd("regreet --style /etc/greetd/regreet.css; hyprctl dispatch 'hl.dsp.exit()'")
end)

hl.config({
    misc = {
        disable_hyprland_logo            = true,
        disable_splash_rendering         = true,
        disable_hyprland_guiutils_check  = true,
    },
})
