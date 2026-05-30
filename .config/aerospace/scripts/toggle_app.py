#!/usr/bin/env python3
# pyright: reportImplicitRelativeImport=false

import subprocess
import sys
from typing import cast

from WMState import WMState


def run_app(app: str):
    cmd = ["open", "-b", app]
    try:
        _ = subprocess.run(cmd, check=True, capture_output=True, text=True)
    except subprocess.CalledProcessError as e:
        error_message: str = "Failed to open" + app
        stderr = cast(str | None, e.stderr)
        stderr_text = stderr.strip() if stderr else str(e)
        sys.exit(f"{error_message}: {stderr_text}")


def main():
    app: str = sys.argv[1]

    wm = WMState()

    floating_app_windows: list[int] = []
    tiled_app_windows: list[int] = []
    if app in wm.apps.keys():
        for key, value in wm.apps[app]["windows"].items():
            if value["window-layout"] == "floating":
                floating_app_windows.append(key)
            else:
                tiled_app_windows.append(key)

    # Open app if no windows
    if len(floating_app_windows) == 0 and len(tiled_app_windows) == 0:
        run_app(app)
        sys.exit()

    # Get last non-"Toggled" workspace
    try:
        with open("/tmp/workspace", "r") as f:
            last_workspace = f.read().strip()
    except FileNotFoundError:
        last_workspace: str | None = None

    # Get app's last floating window ID
    try:
        with open("/tmp/" + app + "_last_floating_window_id", "r") as f:
            app_last_floating_window_id = int(f.read())
    except FileNotFoundError:
        app_last_floating_window_id: int | None = None

    # Get app's last tiled window ID
    try:
        with open("/tmp/" + app + "_last_tiled_window_id", "r") as f:
            app_last_tiled_window_id = int(f.read())
    except FileNotFoundError:
        app_last_tiled_window_id: int | None = None

    # Set main workspace, i.e. visible and on main monitor
    for workspace_id in wm.visible_workspaces_ids:
        main_workspaces = wm.monitors[wm.main_monitor_id]["workspaces"]
        if workspace_id in main_workspaces.keys():
            main_workspace_id: str = workspace_id
            break

    # Sort lists (assume that lower numbers are more likely to be main windows)
    floating_app_windows.sort()
    tiled_app_windows.sort()

    # If floating windows
    if len(floating_app_windows) > 0:
        # If focused
        if (
            wm.focused_window_id is not None
            and wm.windows[wm.focused_window_id]["app-bundle-id"] == app
            and wm.focused_window_id in floating_app_windows
        ):
            # Save currently focused window
            with open("/tmp/" + app + "_last_floating_window_id", "w") as f:
                _ = f.write(str(wm.focused_window_id))

            # If in Toggled workspace, switch to last workspace
            if wm.focused_workspace_name == "Toggled":
                if last_workspace is None:
                    # Move back and forth
                    try:
                        wm.focus_back_and_forth()
                    except:
                        wm.workspace_back_and_forth()
                else:
                    wm.workspace(last_workspace)
            else:
                # Move all floating windows to Toggled
                for window_id in floating_app_windows:
                    wm.move_node_to_workspace("Toggled", window_id=window_id)

        # If not focused
        else:
            # Move all floating windows to main workspace
            for window_id in floating_app_windows:
                # The pyright comment is because main_workspace_id will always be set,
                # as there will always be a main monitor and it will always have
                # workspaces
                wm.move_node_to_workspace(main_workspace_id, window_id=window_id)  # pyright: ignore[reportPossiblyUnboundVariable]
            # Focus on previous floating window or first
            if app_last_floating_window_id is None:
                wm.focus(window_id=floating_app_windows[0])
                # Save newly focused window
                with open("/tmp/" + app + "_last_floating_window_id", "w") as f:
                    _ = f.write(str(floating_app_windows[0]))
            else:
                wm.focus(window_id=app_last_floating_window_id)

    # If no floating windows
    else:
        # If focused
        if (
            wm.focused_window_id is not None
            and wm.windows[wm.focused_window_id]["app-bundle-id"] == app
        ):
            # Save currently focused window
            with open("/tmp/" + app + "_last_tiled_window_id", "w") as f:
                _ = f.write(str(wm.focused_window_id))
            # Move back and forth
            try:
                wm.focus_back_and_forth()
            except:
                wm.workspace_back_and_forth()

        # If not focused
        else:
            # Focus on previous tiled window or first
            if app_last_tiled_window_id is None:
                wm.focus(window_id=tiled_app_windows[0])
                # Save newly focused window
                with open("/tmp/" + app + "_last_tiled_window_id", "w") as f:
                    _ = f.write(str(tiled_app_windows[0]))
            else:
                wm.focus(window_id=app_last_tiled_window_id)


if __name__ == "__main__":
    main()
