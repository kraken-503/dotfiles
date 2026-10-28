#!/usr/bin/env python3
"""One-time setup for the app exporters (Obsidian, OBS Studio, AyuGram, Brave).
  python3 setup_apps.py            OBS: turn on theme auto-reload and select the Quickshell theme (close OBS first)
  python3 setup_apps.py --brave    Brave: install a tiny root helper + sudoers rule (asks for your sudo password)
Run `qs -c bar ipc call bar exportTheme` first so the generated files exist.
"""
import os, pathlib, re, shutil, subprocess, sys, tempfile

H = pathlib.Path.home()
done, todo = [], []

def get_ini(p, section, key):
    sec = None
    for ln in p.read_text(encoding="utf8").splitlines() if p.exists() else []:
        m = re.match(r"\s*\[(.+?)\]\s*$", ln)
        if m: sec = m.group(1); continue
        if sec == section:
            m = re.match(rf"\s*{re.escape(key)}\s*=\s*(.*)$", ln)
            if m: return m.group(1).strip()
    return None

def set_ini(p, section, key, value):
    lines = p.read_text(encoding="utf8").splitlines() if p.exists() else []
    if p.exists() and not p.with_name(p.name + ".qs-backup").exists():
        shutil.copy2(p, p.with_name(p.name + ".qs-backup"))
    out, sec, placed = [], None, False
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
        if not any(l.strip() == f"[{section}]" for l in lines):
            out += ([""] if out else []) + [f"[{section}]"]
            out.append(f"{key}={value}")
        else:   # section exists and was the last one
            i = max(i for i, l in enumerate(out) if l.strip() == f"[{section}]")
            out.insert(i + 1, f"{key}={value}")
    p.write_text("\n".join(out) + "\n", encoding="utf8")

# ── OBS ────────────────────────────────────────────────────────────────
def setup_obs():
    base = H / ".config" / "obs-studio"
    if not base.is_dir():
        todo.append("OBS: ~/.config/obs-studio not found (start OBS once, then re-run)"); return
    if subprocess.run(["pgrep", "-x", "obs"], capture_output=True).returncode == 0:
        todo.append("OBS is running: close it first (it rewrites user.ini on exit), then re-run"); return
    ini = base / "user.ini"
    set_ini(ini, "Appearance", "AutoReload", "true")
    done.append("OBS: [Appearance] AutoReload=true in user.ini (OBS reloads the active theme when its file changes)")
    if (base / "themes" / "Yami_Quickshell.ovt").exists():
        set_ini(ini, "Appearance", "Theme", "com.quickshell.Yami")
        done.append("OBS: selected the Quickshell theme (Yami variant)")
    else:
        todo.append("OBS: run `qs -c bar ipc call bar exportTheme`, then re-run this script to select the theme")

# ── Brave ──────────────────────────────────────────────────────────────
HELPER = r'''#!/bin/bash
# Installed by Quickshell setup. Writes ONE managed policy for Brave: BrowserThemeColor.
set -eu
[[ "${1:-}" =~ ^[0-9a-fA-F]{6}$ ]] || { echo "usage: qs-brave-policy RRGGBB" >&2; exit 2; }
dir=/etc/brave/policies/managed
mkdir -p "$dir"
tmp=$(mktemp "$dir/.qs-XXXXXX")
printf '{\n  "BrowserThemeColor": "#%s"\n}\n' "${1,,}" > "$tmp"
chmod 644 "$tmp"
mv -f "$tmp" "$dir/qs-theme.json"
'''

def setup_brave():
    user = os.environ.get("USER") or pathlib.Path.home().name
    rule = f"{user} ALL=(root) NOPASSWD: /usr/local/bin/qs-brave-policy " + "[0-9a-f]" * 6 + "\n"
    print("This will, with sudo:\n"
          "  1. install /usr/local/bin/qs-brave-policy (root-owned; it only accepts 6 hex digits and writes\n"
          "     /etc/brave/policies/managed/qs-theme.json containing one policy: BrowserThemeColor)\n"
          f"  2. add /etc/sudoers.d/qs-brave-policy so '{user}' can run ONLY that command with a 6-hex-digit argument\n"
          "Side effect: Brave will show 'Managed by your organization' and ignores manual theme-color changes.\n")
    if input("Continue? [y/N] ").strip().lower() != "y":
        todo.append("Brave: skipped"); return
    with tempfile.TemporaryDirectory() as d:
        h, r = pathlib.Path(d, "helper"), pathlib.Path(d, "rule")
        h.write_text(HELPER); r.write_text(rule)
        if subprocess.run(["sudo", "visudo", "-cf", str(r)]).returncode != 0:
            todo.append("Brave: sudoers rule failed validation, nothing installed"); return
        for cmd in (["sudo", "install", "-m", "755", "-o", "root", "-g", "root", str(h), "/usr/local/bin/qs-brave-policy"],
                    ["sudo", "install", "-m", "440", "-o", "root", "-g", "root", str(r), "/etc/sudoers.d/qs-brave-policy"]):
            if subprocess.run(cmd).returncode != 0:
                todo.append("Brave: install step failed: " + " ".join(cmd)); return
    done.append("Brave: helper + sudoers rule installed")
    subprocess.run(["qs", "-c", "bar", "ipc", "call", "bar", "exportTheme"], capture_output=True)

if "--brave" in sys.argv:
    setup_brave()
else:
    setup_obs()
    todo.append("Obsidian: open Settings > Appearance > CSS snippets and switch on `qs-theme` once per vault")
    todo.append("AyuGram: load ~/.local/share/quickshell-bar/telegram.tdesktop-theme once with Telegram's 'Choose from file'")
    todo.append("Brave: run `python3 setup_apps.py --brave` (needs sudo)")

print("\nDone:");        [print("  -", d) for d in done]
print("\nStill to do:"); [print("  -", t) for t in todo]
