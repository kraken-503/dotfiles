#!/usr/bin/env python3
"""One-time setup so kitty, GTK and Qt follow the Quickshell theme switcher.
Safe to run more than once. Makes a one-time backup (name.qs-backup) before touching any existing file.
Usage: python3 setup_global_theme.py
"""
import os, pathlib, re, shutil, subprocess

H = pathlib.Path.home()
C = H / ".config"
done, todo = [], []

def backup(p):
    b = p.with_name(p.name + ".qs-backup")
    if p.exists() and not b.exists():
        shutil.copy2(p, b)

def touch(p):
    p.parent.mkdir(parents=True, exist_ok=True)
    if not os.path.lexists(p):
        p.write_text("", encoding="utf8")

def append_line(p, line, marker):
    touch(p)
    s = p.read_text(encoding="utf8")
    if marker in s:
        return False
    backup(p)
    p.write_text(s.rstrip("\n") + ("\n\n" if s.strip() else "") + line + "\n", encoding="utf8")
    return True

def prepend_line(p, line, marker):          # CSS @import must come first
    touch(p)
    s = p.read_text(encoding="utf8")
    if marker in s:
        return False
    backup(p)
    p.write_text(line + "\n" + s, encoding="utf8")
    return True

def gtk_css(p):
    """Make gtk.css import qs-colors.css without writing through a symlink into a theme."""
    p.parent.mkdir(parents=True, exist_ok=True)
    imp = '@import url("qs-colors.css");'
    if os.path.islink(p):
        target = os.path.realpath(p)
        alive = os.path.exists(p)
        bk = p.with_name(p.name + ".qs-backup")
        if not os.path.lexists(bk):
            os.symlink(os.readlink(p), bk)          # keep the original link as a backup
        os.unlink(p)
        body = (f'@import url("file://{target}");\n' if alive else "") + imp + "\n"
        p.write_text(body, encoding="utf8")
        return ("gtk.css was a symlink to %s: replaced it with a real file that imports the original, then qs-colors.css" % target) if alive \
            else ("gtk.css was a BROKEN symlink (-> %s): replaced it with a real file" % os.readlink(bk))
    return "gtk.css now imports qs-colors.css" if prepend_line(p, imp, "qs-colors.css") else None

def get_ini(p, section, key):
    if not p.exists():
        return None
    sec = None
    for ln in p.read_text(encoding="utf8").splitlines():
        m = re.match(r"\s*\[(.+?)\]\s*$", ln)
        if m:
            sec = m.group(1); continue
        if sec == section:
            m = re.match(rf"\s*{re.escape(key)}\s*=\s*(.*)$", ln)
            if m:
                return m.group(1).strip()
    return None

def set_ini(p, section, key, value):
    p.parent.mkdir(parents=True, exist_ok=True)
    lines = p.read_text(encoding="utf8").splitlines() if p.exists() else []
    if p.exists():
        backup(p)
    out, sec, found, placed = [], None, False, False
    for ln in lines:
        m = re.match(r"\s*\[(.+?)\]\s*$", ln)
        if m:
            if sec == section and not placed:
                out.append(f"{key}={value}"); placed = True
            sec = m.group(1)
        elif sec == section and re.match(rf"\s*{re.escape(key)}\s*=", ln):
            ln = f"{key}={value}"; placed = True
        out.append(ln)
    if not placed:
        if section not in [re.sub(r"[\[\]\s]", "", l) for l in lines if l.strip().startswith("[")]:
            out += ([""] if out else []) + [f"[{section}]"]
        out.append(f"{key}={value}")
    p.write_text("\n".join(out) + "\n", encoding="utf8")

# ── kitty ──────────────────────────────────────────────────────────────
try:
    touch(C / "kitty" / "qs-colors.conf")
    if append_line(C / "kitty" / "kitty.conf", "# Quickshell theme (generated)\ninclude qs-colors.conf", "qs-colors.conf"):
        done.append("kitty: added `include qs-colors.conf` at the end of kitty.conf (so it overrides older colors)")
except Exception as e:
    todo.append(f"kitty step failed ({e}). Check: ls -l ~/.config/kitty/")

# ── GTK 3 / 4 ──────────────────────────────────────────────────────────
for v in ("3.0", "4.0"):
    try:
        touch(C / f"gtk-{v}" / "qs-colors.css")
        msg = gtk_css(C / f"gtk-{v}" / "gtk.css")
        if msg:
            done.append(f"gtk-{v}: {msg}")
    except Exception as e:
        todo.append(f"gtk-{v} step failed ({e}). Check: ls -l ~/.config/gtk-{v}/")

def gsettings(*a):
    try:
        return subprocess.run(["gsettings", *a], capture_output=True, text=True, timeout=5).stdout.strip()
    except Exception:
        return ""

if shutil.which("gsettings"):
    gsettings("set", "org.gnome.desktop.interface", "color-scheme", "prefer-dark")
    cur = gsettings("get", "org.gnome.desktop.interface", "gtk-theme").strip("'")
    has_adw3 = any(pathlib.Path(d, "adw-gtk3-dark").exists()
                   for d in ("/usr/share/themes", str(H / ".local/share/themes"), str(H / ".themes")))
    if has_adw3 and not cur.startswith("adw-gtk3"):
        gsettings("set", "org.gnome.desktop.interface", "gtk-theme", "adw-gtk3-dark")
        done.append("gtk-theme set to adw-gtk3-dark (was: %s)" % (cur or "unset"))
    elif not has_adw3:
        todo.append("GTK3 apps follow the colors best with adw-gtk3:  sudo pacman -S adw-gtk-theme   (then re-run this script)")

# ── Qt (qt6ct / qt5ct) ────────────────────────────────────────────────
for v in ("6", "5"):
    d = C / f"qt{v}ct"
    if v == "5" and not d.exists():
        continue
    try:
        (d / "colors").mkdir(parents=True, exist_ok=True)
        touch(d / "colors" / "qs-theme.conf")
        conf = d / f"qt{v}ct.conf"
        set_ini(conf, "Appearance", "custom_palette", "true")
        set_ini(conf, "Appearance", "color_scheme_path", str(d / "colors" / "qs-theme.conf"))
        style = get_ini(conf, "Appearance", "style")
        if not style:
            set_ini(conf, "Appearance", "style", "Fusion")
        elif "kvantum" in style.lower():
            todo.append(f"qt{v}ct uses Kvantum, which ignores the palette. Set style=Fusion in qt{v}ct, or theme Kvantum separately.")
        done.append(f"qt{v}ct: palette file registered in qt{v}ct.conf")
    except Exception as e:
        todo.append(f"qt{v}ct step failed ({e}). Check: ls -l ~/.config/qt{v}ct/")
    if not shutil.which(f"qt{v}ct"):
        todo.append(f"install qt{v}ct:  sudo pacman -S qt{v}ct")

todo.append('hyprland.lua needs:  hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")   (Qt5 apps need qt5ct instead; one value per session)')

# ── write the colors now, if Quickshell is running ─────────────────────
try:
    r = subprocess.run(["qs", "-c", "bar", "ipc", "call", "bar", "exportTheme"], capture_output=True, text=True, timeout=10)
    done.append("exported the current theme" if r.returncode == 0 else "could not reach Quickshell: start `qs -c bar`, then run: qs -c bar ipc call bar exportTheme")
except Exception:
    done.append("Quickshell not running: start `qs -c bar`, then run: qs -c bar ipc call bar exportTheme")

print("\nDone:")
for d in done: print("  -", d)
print("\nStill to do:")
for t in todo: print("  -", t)
