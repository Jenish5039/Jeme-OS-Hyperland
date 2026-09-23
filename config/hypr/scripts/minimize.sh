#!/usr/bin/env python3
"""
Jeme OS - Hyprland Window Minimize & Restore Manager
Manages window minimize (SUPER+X) to special:minimized and restore/cycle via Jeme Dock.
Preserves original workspaces, layout tiling, floating status, and auxiliary/browser windows.
"""

import sys
import os
import json
import time
import subprocess
import glob

STATE_DIR = "/tmp/hypr_minimized"

def run_hyprctl(cmd_list):
    try:
        res = subprocess.run(["hyprctl"] + cmd_list, capture_output=True, text=True, check=True)
        return res.stdout
    except Exception:
        return ""

def hypr_eval(lua_code):
    try:
        res = subprocess.run(["hyprctl", "eval", lua_code], capture_output=True, text=True)
        return res.stdout
    except Exception:
        return ""

def get_clients():
    try:
        out = run_hyprctl(["clients", "-j"])
        return json.loads(out) if out.strip() else []
    except Exception:
        return []

def get_active_window():
    try:
        out = run_hyprctl(["activewindow", "-j"])
        return json.loads(out) if out.strip() else None
    except Exception:
        return None

def get_active_workspace():
    try:
        out = run_hyprctl(["activeworkspace", "-j"])
        return json.loads(out) if out.strip() else None
    except Exception:
        return None

def ensure_state_dir():
    os.makedirs(STATE_DIR, exist_ok=True)

def cleanup_stale_states(clients):
    try:
        valid_addresses = {c.get("address") for c in clients if c.get("address")}
        for filepath in glob.glob(os.path.join(STATE_DIR, "*.json")):
            addr = os.path.basename(filepath).replace(".json", "")
            if addr not in valid_addresses:
                try:
                    os.remove(filepath)
                except OSError:
                    pass
    except Exception:
        pass

def resolve_client_app(client, all_clients=None):
    """
    Resolves the authoritative application identifier for a client,
    even for auxiliary windows, browser popups, and utility dialogs with empty class.
    """
    cls = (client.get("class") or client.get("initialClass") or "").strip()
    if cls:
        return cls
        
    pid = client.get("pid")
    if pid and pid > 0:
        # Check other clients with the same PID
        if all_clients:
            for other in all_clients:
                if other.get("pid") == pid and other.get("address") != client.get("address"):
                    other_cls = (other.get("class") or other.get("initialClass") or "").strip()
                    if other_cls:
                        return other_cls
                        
        # Read from /proc/<pid>/
        try:
            exe = os.path.realpath(f"/proc/{pid}/exe")
            bin_name = os.path.basename(exe)
            if bin_name == "brave":
                return "brave-browser"
            if bin_name:
                return bin_name
        except Exception:
            pass
            
        try:
            comm = open(f"/proc/{pid}/comm").read().strip()
            if comm == "brave":
                return "brave-browser"
            if comm:
                return comm
        except Exception:
            pass

    # Heuristics based on window title
    title = (client.get("title") or client.get("initialTitle") or "").lower()
    if "meet.google.com" in title or "brave" in title:
        return "brave-browser"
    if "telegram" in title:
        return "org.telegram.desktop"
        
    return ""

def save_window_state(win, all_clients=None):
    ensure_state_dir()
    addr = win.get("address")
    if not addr:
        return
    ws = win.get("workspace", {})
    resolved = resolve_client_app(win, all_clients)
    state = {
        "address": addr,
        "workspace_id": ws.get("id", 1),
        "workspace_name": ws.get("name", "1"),
        "class": win.get("class", ""),
        "initialClass": win.get("initialClass", ""),
        "resolved_app": resolved,
        "title": win.get("title", ""),
        "initialTitle": win.get("initialTitle", ""),
        "pid": win.get("pid", 0),
        "floating": win.get("floating", False),
        "time": time.time()
    }
    state_file = os.path.join(STATE_DIR, f"{addr}.json")
    try:
        with open(state_file, "w") as f:
            json.dump(state, f)
    except Exception:
        pass

def get_saved_state(addr):
    state_file = os.path.join(STATE_DIR, f"{addr}.json")
    if os.path.exists(state_file):
        try:
            with open(state_file, "r") as f:
                return json.load(f)
        except Exception:
            pass
    return None

def remove_saved_state(addr):
    state_file = os.path.join(STATE_DIR, f"{addr}.json")
    if os.path.exists(state_file):
        try:
            os.remove(state_file)
        except OSError:
            pass

def close_special_minimized():
    try:
        monitors = json.loads(run_hyprctl(["monitors", "-j"]))
        for m in monitors:
            sw = m.get("specialWorkspace", {})
            if sw.get("name") == "special:minimized" or sw.get("id", 0) != 0:
                hypr_eval('hl.dispatch(hl.dsp.workspace.toggle_special("minimized"))')
    except Exception:
        pass

def minimize_active():
    clients = get_clients()
    cleanup_stale_states(clients)
    
    active = get_active_window()
    if not active or not active.get("address"):
        return
    
    ws = active.get("workspace", {})
    ws_id = ws.get("id", 1)
    ws_name = ws.get("name", "")
    
    # Do not minimize if already on a special workspace
    if ws_id < 0 or ws_name.startswith("special:"):
        return
        
    addr = active.get("address")
    save_window_state(active, clients)
    
    # If window is fullscreen, unfullscreen first
    if active.get("fullscreen", 0) != 0:
        hypr_eval("hl.dispatch(hl.dsp.window.fullscreen({ mode = 'fullscreen', action = 'off' }))")
        
    # Dispatch move to special:minimized
    lua = f"hl.dispatch(hl.dsp.window.move({{ workspace = 'special:minimized', window = 'address:{addr}' }}))"
    hypr_eval(lua)
    
    # Immediately close special:minimized on monitor so the window disappears
    close_special_minimized()

def restore_window(addr, target_workspace=None):
    if not addr:
        return
    
    saved = get_saved_state(addr)
    ws_id = None
    if target_workspace is not None:
        ws_id = target_workspace
    elif saved and "workspace_id" in saved and saved["workspace_id"] > 0:
        ws_id = saved["workspace_id"]
    else:
        # Fallback to active workspace
        act_ws = get_active_workspace()
        ws_id = act_ws.get("id", 1) if act_ws else 1
        
    # Move to original workspace and focus
    lua = f"hl.dispatch(hl.dsp.window.move({{ workspace = {ws_id}, window = 'address:{addr}' }})); hl.dispatch(hl.dsp.focus({{ window = 'address:{addr}' }}))"
    hypr_eval(lua)
    
    # Ensure special workspace is closed
    close_special_minimized()
    
    remove_saved_state(addr)

def matches_app(client, app_id, key="", app_name="", all_clients=None):
    targets = {t.lower().strip() for t in [app_id, key, app_name] if t and t.strip()}
    cleaned_targets = set()
    for t in targets:
        cleaned_targets.add(t)
        if t.endswith(".desktop"):
            cleaned_targets.add(t[:-8])
        parts = t.split(".")
        if len(parts) > 1:
            cleaned_targets.add(parts[-1])
            
    c_class = client.get("class", "").lower()
    c_init_class = client.get("initialClass", "").lower()
    resolved = resolve_client_app(client, all_clients).lower()
    
    # Also check saved state
    saved = get_saved_state(client.get("address", ""))
    saved_resolved = (saved.get("resolved_app", "") or saved.get("class", "")).lower() if saved else ""
    
    for t in cleaned_targets:
        if t in (c_class, c_init_class, resolved, saved_resolved):
            return True
        if c_class.endswith(t) or c_init_class.endswith(t) or resolved.endswith(t) or saved_resolved.endswith(t):
            return True
        if (t and t in c_class) or (t and t in c_init_class) or (t and t in resolved) or (t and t in saved_resolved):
            return True
            
    return False

def dock_activate(app_id, key="", app_name=""):
    clients = get_clients()
    cleanup_stale_states(clients)
    
    matching_clients = [c for c in clients if matches_app(c, app_id, key, app_name, clients)]
    
    if not matching_clients:
        # App not found in running clients, try to launch it
        target_launch = key if key else app_id
        if target_launch:
            subprocess.Popen(["gtk-launch", target_launch], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return
        
    # Split matching clients into visible and minimized
    visible = []
    minimized = []
    for c in matching_clients:
        ws = c.get("workspace", {})
        ws_id = ws.get("id", 1)
        ws_name = ws.get("name", "")
        if ws_id < 0 or ws_name.startswith("special:minimized"):
            minimized.append(c)
        else:
            visible.append(c)
            
    active = get_active_window()
    active_addr = active.get("address") if active else None
    
    # Sort minimized windows: most recently minimized first
    def get_min_time(c):
        saved = get_saved_state(c.get("address", ""))
        return saved.get("time", 0) if saved else 0
    minimized.sort(key=get_min_time, reverse=True)
    
    # If there is only 1 window
    if len(matching_clients) == 1:
        win = matching_clients[0]
        if win in minimized:
            restore_window(win.get("address"))
        else:
            # Window is visible
            addr = win.get("address")
            hypr_eval(f"hl.dispatch(hl.dsp.focus({{ window = 'address:{addr}' }}))")
        return
        
    # Multiple windows: build a cycle list [visible..., minimized...]
    # If the active window is one of the visible windows, cycle to the next
    is_active_in_app = any(c.get("address") == active_addr for c in matching_clients)
    
    cycle_list = visible + minimized
    if is_active_in_app:
        # Find active index in cycle_list
        active_idx = 0
        for i, c in enumerate(cycle_list):
            if c.get("address") == active_addr:
                active_idx = i
                break
        next_win = cycle_list[(active_idx + 1) % len(cycle_list)]
        if next_win in minimized:
            restore_window(next_win.get("address"))
        else:
            addr = next_win.get("address")
            hypr_eval(f"hl.dispatch(hl.dsp.focus({{ window = 'address:{addr}' }}))")
    else:
        # None of this app's windows are currently active
        if visible:
            # Focus the first visible window
            addr = visible[0].get("address")
            hypr_eval(f"hl.dispatch(hl.dsp.focus({{ window = 'address:{addr}' }}))")
        elif minimized:
            # All windows are minimized, restore the most recent
            restore_window(minimized[0].get("address"))

def main():
    if len(sys.argv) == 1 or sys.argv[1] in ("--minimize", "-m"):
        minimize_active()
    elif sys.argv[1] in ("--restore", "-r"):
        addr = sys.argv[2] if len(sys.argv) > 2 else None
        restore_window(addr)
    elif sys.argv[1] == "--dock-activate":
        app_id = sys.argv[2] if len(sys.argv) > 2 else ""
        key = sys.argv[3] if len(sys.argv) > 3 else ""
        app_name = sys.argv[4] if len(sys.argv) > 4 else ""
        dock_activate(app_id, key, app_name)
    else:
        # Default minimize
        minimize_active()

if __name__ == "__main__":
    main()
