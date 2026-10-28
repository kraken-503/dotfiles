#!/usr/bin/env python3

import json
import os
import subprocess
import urllib.request

import gi

gi.require_version("Gtk", "3.0")

from gi.repository import Gtk, GLib, Gdk


# ============================================================
# Helpers
# ============================================================

def playerctl(*args):
    try:
        return subprocess.check_output(
            ["playerctl", *args],
            stderr=subprocess.DEVNULL,
            text=True
        ).strip()
    except Exception:
        return ""


def run_playerctl(*args):
    try:
        subprocess.Popen(
            ["playerctl", *args],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
    except Exception:
        pass


# ============================================================
# CSS
# ============================================================

CSS = """
window#music-popup {
    background-color: #11111b;
    border: 1px solid #313244;
    border-radius: 16px;
}

#album-art {
    background-color: #181825;
    border-radius: 12px;
}

#music-title {
    color: #cba6f7;
    font-size: 15px;
    font-weight: bold;
}

#music-artist {
    color: #a6adc8;
    font-size: 11px;
}

#music-album {
    color: #6c7086;
    font-size: 9px;
}

#progress {
    min-height: 4px;
}

#progress trough {
    background-color: #313244;
    border-radius: 4px;
}

#progress progress {
    background-color: #cba6f7;
    border-radius: 4px;
}

button {
    background-color: #181825;
    color: #cdd6f4;
    border: none;
    border-radius: 18px;
    min-width: 34px;
    min-height: 34px;
    padding: 0;
}

button:hover {
    background-color: #313244;
    color: #cba6f7;
}

#play-button {
    background-color: #cba6f7;
    color: #11111b;
    min-width: 42px;
    min-height: 42px;
}

#visualizer {
    color: #89b4fa;
    font-family: monospace;
    font-size: 12px;
    letter-spacing: 2px;
}

#status {
    color: #6c7086;
    font-size: 9px;
}
"""


# ============================================================
# Music Window
# ============================================================

class MusicWindow(Gtk.Window):

    def __init__(self):

        Gtk.Window.__init__(
            self,
            type=Gtk.WindowType.TOPLEVEL
        )

        self.set_title(
            "Music Popup"
        )

        self.set_name(
            "music-popup"
        )

        self.set_decorated(
            False
        )

        self.set_resizable(
            False
        )

        self.set_keep_above(
            True
        )

        self.set_skip_taskbar_hint(
            True
        )

        self.set_skip_pager_hint(
            True
        )

        self.set_type_hint(
            Gdk.WindowTypeHint.UTILITY
        )

        self.connect(
            "destroy",
            Gtk.main_quit
        )


        # ----------------------------------------------------
        # Main container
        # ----------------------------------------------------

        root = Gtk.Box(
            orientation=Gtk.Orientation.VERTICAL,
            spacing=6
        )

        root.set_margin_top(
            12
        )

        root.set_margin_bottom(
            12
        )

        root.set_margin_start(
            14
        )

        root.set_margin_end(
            14
        )

        self.add(
            root
        )


        # ----------------------------------------------------
        # Album art
        # ----------------------------------------------------

        self.art = Gtk.Image()

        self.art.set_name(
            "album-art"
        )

        self.art.set_size_request(
            160,
            160
        )

        root.pack_start(
            self.art,
            False,
            False,
            0
        )


        # ----------------------------------------------------
        # Title
        # ----------------------------------------------------

        self.title = Gtk.Label()

        self.title.set_name(
            "music-title"
        )

        self.title.set_xalign(
            0.5
        )

        self.title.set_ellipsize(
            3
        )

        self.title.set_max_width_chars(
            32
        )

        root.pack_start(
            self.title,
            False,
            False,
            0
        )


        # ----------------------------------------------------
        # Artist
        # ----------------------------------------------------

        self.artist = Gtk.Label()

        self.artist.set_name(
            "music-artist"
        )

        self.artist.set_xalign(
            0.5
        )

        self.artist.set_ellipsize(
            3
        )

        self.artist.set_max_width_chars(
            38
        )

        root.pack_start(
            self.artist,
            False,
            False,
            0
        )


        # ----------------------------------------------------
        # Album
        # ----------------------------------------------------

        self.album = Gtk.Label()

        self.album.set_name(
            "music-album"
        )

        self.album.set_xalign(
            0.5
        )

        self.album.set_ellipsize(
            3
        )

        self.album.set_max_width_chars(
            38
        )

        root.pack_start(
            self.album,
            False,
            False,
            0
        )


        # ----------------------------------------------------
        # Progress
        # ----------------------------------------------------

        self.progress = Gtk.ProgressBar()

        self.progress.set_name(
            "progress"
        )

        root.pack_start(
            self.progress,
            False,
            False,
            3
        )


        # ----------------------------------------------------
        # Controls
        # ----------------------------------------------------

        controls = Gtk.Box(
            orientation=Gtk.Orientation.HORIZONTAL,
            spacing=8
        )

        controls.set_halign(
            Gtk.Align.CENTER
        )

        root.pack_start(
            controls,
            False,
            False,
            0
        )


        # Previous
        previous = Gtk.Button(
            label="󰒮"
        )

        previous.connect(
            "clicked",
            lambda _: run_playerctl(
                "previous"
            )
        )

        controls.pack_start(
            previous,
            False,
            False,
            0
        )


        # Play/Pause
        self.play = Gtk.Button(
            label="󰐊"
        )

        self.play.set_name(
            "play-button"
        )

        self.play.connect(
            "clicked",
            lambda _: run_playerctl(
                "play-pause"
            )
        )

        controls.pack_start(
            self.play,
            False,
            False,
            0
        )


        # Next
        next_button = Gtk.Button(
            label="󰒭"
        )

        next_button.connect(
            "clicked",
            lambda _: run_playerctl(
                "next"
            )
        )

        controls.pack_start(
            next_button,
            False,
            False,
            0
        )


        # ----------------------------------------------------
        # Visualizer
        # ----------------------------------------------------

        self.visualizer = Gtk.Label()

        self.visualizer.set_name(
            "visualizer"
        )

        self.visualizer.set_xalign(
            0.5
        )

        root.pack_start(
            self.visualizer,
            False,
            False,
            0
        )


        # ----------------------------------------------------
        # Status
        # ----------------------------------------------------

        self.status = Gtk.Label()

        self.status.set_name(
            "status"
        )

        root.pack_start(
            self.status,
            False,
            False,
            0
        )


        # ----------------------------------------------------
        # Update
        # ----------------------------------------------------

        self.update()

        GLib.timeout_add(
            500,
            self.update
        )


        # ----------------------------------------------------
        # Show
        # ----------------------------------------------------

        self.show_all()

        GLib.idle_add(
            self.position_popup
        )


    # ========================================================
    # Position popup
    # ========================================================

    def position_popup(self):

        width = 330
        height = 330

        try:

            output = subprocess.check_output(
                [
                    "hyprctl",
                    "-j",
                    "monitors"
                ],
                stderr=subprocess.DEVNULL,
                text=True
            )

            monitors = json.loads(
                output
            )

            cursor_output = subprocess.check_output(
                [
                    "hyprctl",
                    "-j",
                    "cursorpos"
                ],
                stderr=subprocess.DEVNULL,
                text=True
            )

            cursor = json.loads(
                cursor_output
            )

            cursor_x = cursor["x"]
            cursor_y = cursor["y"]

            selected = None

            for monitor in monitors:

                mx = monitor["x"]
                my = monitor["y"]
                mw = monitor["width"]
                mh = monitor["height"]

                if (
                    mx <= cursor_x < mx + mw
                    and
                    my <= cursor_y < my + mh
                ):

                    selected = monitor
                    break

            if selected is None:
                selected = monitors[0]

            mx = selected["x"]
            my = selected["y"]
            mw = selected["width"]
            mh = selected["height"]

            # Center horizontally.
            x = mx + (mw - width) // 2

            # Keep below the top bar.
            y = my + 45

            # Prevent going below screen.
            if y + height > my + mh:
                y = my + mh - height - 10

            # Prevent going off left/right.
            if x < mx:
                x = mx + 10

            if x + width > mx + mw:
                x = mx + mw - width - 10

            self.move(
                int(x),
                int(y)
            )

        except Exception:

            self.move(
                10,
                45
            )

        return False


    # ========================================================
    # Album art
    # ========================================================

    def update_art(self):

        art_url = playerctl(
            "metadata",
            "mpris:artUrl"
        )

        if not art_url:

            self.art.clear()

            return


        try:

            if art_url.startswith(
                "file://"
            ):

                path = art_url[7:]

                if os.path.exists(
                    path
                ):

                    self.art.set_from_file(
                        path
                    )

                    return


            if (
                art_url.startswith("http://")
                or
                art_url.startswith("https://")
            ):

                cache = (
                    "/tmp/waybar-album-art"
                )

                urllib.request.urlretrieve(
                    art_url,
                    cache
                )

                self.art.set_from_file(
                    cache
                )

        except Exception:

            pass


    # ========================================================
    # Update
    # ========================================================

    def update(self):

        title = playerctl(
            "metadata",
            "--format",
            "{{ title }}"
        )

        artist = playerctl(
            "metadata",
            "--format",
            "{{ artist }}"
        )

        album = playerctl(
            "metadata",
            "--format",
            "{{ album }}"
        )

        status = playerctl(
            "status"
        )

        position = playerctl(
            "position"
        )

        length = playerctl(
            "metadata",
            "--format",
            "{{ mpris:length }}"
        )


        # ----------------------------------------------------
        # Nothing playing
        # ----------------------------------------------------

        if not title:

            self.title.set_text(
                "Nothing playing"
            )

            self.artist.set_text(
                ""
            )

            self.album.set_text(
                ""
            )

            self.status.set_text(
                "No active player"
            )

            self.visualizer.set_text(
                "▁▁▁▁▁▁▁▁▁▁"
            )

            self.progress.set_fraction(
                0
            )

            self.art.clear()

            return True


        # ----------------------------------------------------
        # Metadata
        # ----------------------------------------------------

        self.title.set_text(
            title
        )

        self.artist.set_text(
            artist
        )

        self.album.set_text(
            album
        )


        # ----------------------------------------------------
        # Play button
        # ----------------------------------------------------

        if status == "Playing":

            self.play.set_label(
                "󰏤"
            )

        else:

            self.play.set_label(
                "󰐊"
            )


        self.status.set_text(
            status
        )


        # ----------------------------------------------------
        # Progress
        # ----------------------------------------------------

        try:

            pos = float(
                position
            )

            duration = (
                float(length)
                / 1000000
            )

            if duration > 0:

                fraction = pos / duration

                fraction = min(
                    max(
                        fraction,
                        0
                    ),
                    1
                )

                self.progress.set_fraction(
                    fraction
                )

            else:

                self.progress.set_fraction(
                    0
                )

        except (
            ValueError,
            TypeError
        ):

            self.progress.set_fraction(
                0
            )


        # ----------------------------------------------------
        # Visualizer
        # ----------------------------------------------------

        if status == "Playing":

            self.visualizer.set_text(
                "▁▂▃▅▇▅▃▂▁▂▄▇▆▃"
            )

        else:

            self.visualizer.set_text(
                "▁▁▁▁▁▁▁▁▁▁▁▁▁"
            )


        self.update_art()

        return True


# ============================================================
# GTK setup
# ============================================================

Gtk.init()

css = Gtk.CssProvider()

css.load_from_data(
    CSS.encode()
)

Gtk.StyleContext.add_provider_for_screen(
    Gdk.Screen.get_default(),
    css,
    Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
)


# ============================================================
# Start
# ============================================================

window = MusicWindow()

Gtk.main()
