#!/usr/bin/env python3
# pyright: reportAny=false, reportExplicitAny=false

# Refer to https://nikitabobko.github.io/AeroSpace/commands

import json
import subprocess
import sys
from typing import Any, TypeAlias, TypedDict, cast

WMStateJSON: TypeAlias = list[dict[str, Any]]

WindowInfo = TypedDict(
    "WindowInfo",
    {
        "window-id": int,
        "window-title": str,
        "window-is-fullscreen": bool,
        "window-layout": str,
        "window-parent-container-layout": str,
        "app-bundle-id": str,
        "app-name": str,
        "app-pid": int,
        "app-exec-path": str,
        "app-bundle-path": str,
        "workspace": str,
        "workspace-is-focused": bool,
        "workspace-is-visible": bool,
        "workspace-root-container-layout": str,
        "monitor-id": int,
        "monitor-appkit-nsscreen-screens-id": int,
        "monitor-name": str,
        "monitor-is-main": bool,
        "focused": bool,
        "monitor-has-mouse": bool,
    },
)

WorkspaceInfo = TypedDict(
    "WorkspaceInfo",
    {
        "workspace": str,
        "workspace-is-focused": bool,
        "workspace-is-visible": bool,
        "workspace-root-container-layout": str,
        "monitor-id": int,
        "monitor-appkit-nsscreen-screens-id": int,
        "monitor-name": str,
        "monitor-is-main": bool,
        "workspace-name": str,
        "windows": dict[int, WindowInfo],
        "monitor-has-mouse": bool,
    },
)

MonitorInfo = TypedDict(
    "MonitorInfo",
    {
        "monitor-id": int,
        "monitor-appkit-nsscreen-screens-id": int,
        "monitor-name": str,
        "monitor-is-main": bool,
        "workspaces": dict[str, WorkspaceInfo],
        "windows": dict[int, WindowInfo],
        "monitor-has-mouse": bool,
    },
)

AppInfo = TypedDict(
    "AppInfo",
    {
        "app-bundle-id": str,
        "app-name": str,
        "app-pid": int,
        "app-exec-path": str,
        "app-bundle-path": str,
        "windows": dict[int, WindowInfo],
    },
)

WindowsById: TypeAlias = dict[int, WindowInfo]
WorkspacesByName: TypeAlias = dict[str, WorkspaceInfo]
MonitorsById: TypeAlias = dict[int, MonitorInfo]
AppsByBundleId: TypeAlias = dict[str, AppInfo]


class WMState(object):
    def __init__(self):
        self.__monitors_json: WMStateJSON = self.__fetch_monitors()
        self.__mouse_monitor_json: WMStateJSON = self.__fetch_monitors(mouse=True)
        self.__workspaces_json: WMStateJSON = self.__fetch_workspaces()
        self.__windows_json: WMStateJSON = self.__fetch_windows()
        self.__focused_window_json: WMStateJSON = self.__fetch_windows(focused=True)
        self.__apps_json: WMStateJSON = self.__fetch_apps()

        self.__focused_window_id: int | None = None
        self.__visible_workspaces_ids: list[str] = []

        # Build windows dict, add "focused" attribute to each window, set
        # __focused_window_id and monitor-has-mouse
        self.__windows: WindowsById = {}
        for window_json in self.__windows_json:
            window = cast(WindowInfo, cast(object, window_json))
            window_id = window["window-id"]
            monitor_id = window["monitor-id"]
            self.__windows[window_id] = window
            if (
                len(self.__focused_window_json) > 0
                and window_id == self.__focused_window_json[0]["window-id"]
            ):
                self.__windows[window_id]["focused"] = True
                self.__focused_window_id = window_id
            else:
                self.__windows[window_id]["focused"] = False
            if monitor_id == self.__mouse_monitor_json[0]["monitor-id"]:
                self.__windows[window_id]["monitor-has-mouse"] = True
            else:
                self.__windows[window_id]["monitor-has-mouse"] = False

        # Build workspaces dict and add "windows" attribute to each workspace
        self.__workspaces: WorkspacesByName = {}
        for workspace_json in self.__workspaces_json:
            workspace = cast(WorkspaceInfo, cast(object, workspace_json))
            workspace_name = workspace["workspace"]
            monitor_id = workspace["monitor-id"]
            self.__workspaces[workspace_name] = workspace
            self.__workspaces[workspace_name]["workspace-name"] = workspace_name
            self.__workspaces[workspace_name].update({"windows": {}})
            if workspace["workspace-is-focused"]:
                self.__focused_workspace_name = workspace_name
            if workspace["workspace-is-visible"]:
                self.__visible_workspaces_ids.append(workspace_name)
            if monitor_id == self.__mouse_monitor_json[0]["monitor-id"]:
                self.__workspaces[workspace_name]["monitor-has-mouse"] = True
            else:
                self.__workspaces[workspace_name]["monitor-has-mouse"] = False

        # Build monitors dict and add "workspaces" and "windows" attributes to each
        # monitor
        self.__monitors: MonitorsById = {}
        for monitor_json in self.__monitors_json:
            monitor = cast(MonitorInfo, cast(object, monitor_json))
            monitor_id = monitor["monitor-id"]
            self.__monitors[monitor_id] = monitor
            self.__monitors[monitor_id].update({"workspaces": {}, "windows": {}})
            if monitor["monitor-is-main"] is True:
                self.__main_monitor_id: int = monitor_id
            if monitor_id == self.__mouse_monitor_json[0]["monitor-id"]:
                self.__monitors[monitor_id]["monitor-has-mouse"] = True
                self.__mouse_monitor_id = monitor_id
            else:
                self.__monitors[monitor_id]["monitor-has-mouse"] = False

        # Build apps dict and add "windows" attribute to each app
        # WARN: Multiple instances of an app *can* be open (e.g. multiple Firefox
        # profiles) but is rare. In these cases, use app-pid.
        self.__apps: AppsByBundleId = {}
        for app_json in self.__apps_json:
            app = cast(AppInfo, cast(object, app_json))
            app_bundle_id = app["app-bundle-id"]
            self.__apps[app_bundle_id] = app
            self.__apps[app_bundle_id].update({"windows": {}})

        # Iterate over windows and add them to workspaces, monitors and apps
        for window in self.__windows.values():
            window_id = window["window-id"]
            workspace_name = window["workspace"]
            monitor_id = window["monitor-id"]
            app_bundle_id = window["app-bundle-id"]
            self.__workspaces[workspace_name]["windows"].update({window_id: window})
            self.__monitors[monitor_id]["windows"].update({window_id: window})
            self.__apps[app_bundle_id]["windows"].update({window_id: window})

        # Iterate over workspaces and add them to monitors
        for workspace in self.__workspaces.values():
            workspace_name = workspace["workspace"]
            monitor_id = workspace["monitor-id"]
            self.__monitors[monitor_id]["workspaces"].update(
                {workspace_name: workspace}
            )

    def __import_json(self, cmd: list[str], error_message: str) -> WMStateJSON:
        try:
            output = subprocess.run(cmd, check=True, capture_output=True, text=True)
        except subprocess.CalledProcessError as e:
            stderr = e.stderr.strip() if e.stderr else str(e)
            if stderr == "No window is focused":
                return []
            else:
                sys.exit(f"{error_message}: {stderr}")
        return json.loads(output.stdout)

    def __run(self, cmd: list[str], error_message: str):
        try:
            _ = subprocess.run(cmd, check=True, capture_output=True, text=True)
        except subprocess.CalledProcessError as e:
            stderr = e.stderr.strip() if e.stderr else str(e)
            sys.exit(f"{error_message}: {stderr}")

    def __fetch_monitors(self, mouse: bool = False):
        fields = [
            "%{monitor-id}",
            "%{monitor-appkit-nsscreen-screens-id}",
            "%{monitor-name}",
            "%{monitor-is-main}",
        ]
        cmd = [
            "aerospace",
            "list-monitors",
            "--format",
            " ".join(fields),
            "--json",
        ]
        if mouse is True:
            cmd.append("--mouse")
        return self.__import_json(cmd, "Failed to fetch monitors")

    def __fetch_windows(self, focused: bool = False):
        fields = [
            "%{window-id}",
            "%{window-title}",
            "%{window-is-fullscreen}",
            "%{window-layout}",
            "%{window-parent-container-layout}",
            "%{app-bundle-id}",
            "%{app-name}",
            "%{app-pid}",
            "%{app-exec-path}",
            "%{app-bundle-path}",
            "%{workspace}",
            "%{workspace-is-focused}",
            "%{workspace-is-visible}",
            "%{workspace-root-container-layout}",
            "%{monitor-id}",
            "%{monitor-appkit-nsscreen-screens-id}",
            "%{monitor-name}",
            "%{monitor-is-main}",
        ]
        cmd = [
            "aerospace",
            "list-windows",
            "--format",
            " ".join(fields),
            "--json",
        ]
        if focused is True:
            cmd.append("--focused")
        else:
            cmd.extend(["--monitor", "all"])
        return self.__import_json(cmd, "Failed to fetch windows")

    def __fetch_workspaces(self):
        fields = [
            "%{workspace}",
            "%{workspace-is-focused}",
            "%{workspace-is-visible}",
            "%{workspace-root-container-layout}",
            "%{monitor-id}",
            "%{monitor-appkit-nsscreen-screens-id}",
            "%{monitor-name}",
            "%{monitor-is-main}",
        ]
        cmd = [
            "aerospace",
            "list-workspaces",
            "--monitor",
            "all",
            "--format",
            " ".join(fields),
            "--json",
        ]
        return self.__import_json(cmd, "Failed to fetch workspaces")

    def __fetch_apps(self, macos_native_hidden: bool = False):
        fields = [
            "%{app-bundle-id}",
            "%{app-name}",
            "%{app-pid}",
            "%{app-exec-path}",
            "%{app-bundle-path}",
        ]
        cmd = [
            "aerospace",
            "list-apps",
            "--format",
            " ".join(fields),
            "--json",
        ]
        if macos_native_hidden is True:
            cmd.append("--macos_native_hidden")
        return self.__import_json(cmd, "Failed to fetch apps")

    # Core properties
    @property
    def monitors(self) -> MonitorsById:
        return self.__monitors

    @property
    def windows(self) -> WindowsById:
        return self.__windows

    @property
    def workspaces(self) -> WorkspacesByName:
        return self.__workspaces

    @property
    def apps(self) -> AppsByBundleId:
        return self.__apps

    # Focus properties
    @property
    def focused_window_id(self) -> int | None:
        return self.__focused_window_id

    @property
    def focused_workspace_name(self) -> str:
        return self.__focused_workspace_name

    @property
    def mouse_monitor_id(self) -> int:
        return self.__mouse_monitor_id

    @property
    def main_monitor_id(self) -> int:
        return self.__main_monitor_id

    @property
    def visible_workspaces_ids(self) -> list[str]:
        return self.__visible_workspaces_ids

    # Not an official property but one that we can consistently infer
    @property
    def focused_monitor_id(self) -> int:
        return self.__workspaces[self.__focused_workspace_name]["monitor-id"]

    # Command functions
    def balance_sizes(self, workspace: str | None = None):
        cmd: list[str] = ["aerospace", "balance-sizes"]
        if workspace is not None:
            cmd.extend(["--workspace", workspace])
        self.__run(cmd, "Failed to balance sizes")

    def close(
        self,
        quit_if_last_window: bool = False,
        window_id: int | None = None,
    ):
        cmd: list[str] = ["aerospace", "close"]
        if quit_if_last_window is True:
            cmd.append("--quit-if-last-window")
        if window_id is not None:
            cmd.extend(["--window-id", str(window_id)])
        self.__run(cmd, "Failed to close window")

    def close_all_windows_but_current(self, quit_if_last_window: bool = False):
        cmd: list[str] = ["aerospace", "close-all-windows-but-current"]
        if quit_if_last_window is True:
            cmd.append("--quit-if-last-window")
        self.__run(cmd, "Failed to close all windows but current")

    def enable(self, state: str, fail_if_noop: bool = False):
        cmd: list[str] = ["aerospace", "enable"]
        if fail_if_noop is True:
            cmd.append("--fail-if-noop")
        cmd.append(state)
        self.__run(cmd, "Failed to set enable state")

    def flatten_workspace_tree(self, workspace: str | None = None):
        cmd: list[str] = ["aerospace", "flatten-workspace-tree"]
        if workspace is not None:
            cmd.extend(["--workspace", workspace])
        self.__run(cmd, "Failed to flatten workspace tree")

    def focus(
        self,
        direction_or_nextprev: str | None = None,
        window_id: int | None = None,
        dfs_index: int | None = None,
        ignore_floating: bool = False,
        boundaries: str | None = None,
        boundaries_action: str | None = None,
    ):
        cmd: list[str] = ["aerospace", "focus"]
        if ignore_floating is True:
            cmd.append("--ignore-floating")
        if boundaries is not None:
            cmd.extend(["--boundaries", boundaries])
        if boundaries_action is not None:
            cmd.extend(["--boundaries-action", boundaries_action])
        if window_id is not None:
            cmd.extend(["--window-id", str(window_id)])
        if dfs_index is not None:
            cmd.extend(["--dfs-index", str(dfs_index)])
        if direction_or_nextprev is not None:
            cmd.append(direction_or_nextprev)
        self.__run(cmd, "Failed to focus")

    def focus_back_and_forth(self):
        cmd: list[str] = ["aerospace", "focus-back-and-forth"]
        self.__run(cmd, "Failed to focus back and forth")

    def focus_monitor(
        self,
        monitor_pattern: str | list[str],
        wrap_around: bool = False,
    ):
        cmd: list[str] = ["aerospace", "focus-monitor"]
        if wrap_around is True:
            cmd.append("--wrap-around")
        if isinstance(monitor_pattern, str):
            cmd.append(monitor_pattern)
        else:
            cmd.extend(monitor_pattern)
        self.__run(cmd, "Failed to focus monitor")

    def fullscreen(
        self,
        state: str | None = None,
        window_id: int | None = None,
        no_outer_gaps: bool = False,
        fail_if_noop: bool = False,
    ):
        cmd: list[str] = ["aerospace", "fullscreen"]
        if window_id is not None:
            cmd.extend(["--window-id", str(window_id)])
        if no_outer_gaps is True:
            cmd.append("--no-outer-gaps")
        if fail_if_noop is True:
            cmd.append("--fail-if-noop")
        if state is not None:
            cmd.append(state)
        self.__run(cmd, "Failed to set fullscreen")

    def join_with(self, direction: str, window_id: int | None = None):
        cmd: list[str] = ["aerospace", "join-with"]
        if window_id is not None:
            cmd.extend(["--window-id", str(window_id)])
        cmd.append(direction)
        self.__run(cmd, "Failed to join with")

    def layout(self, layout: str | list[str], window_id: int | None = None):
        cmd: list[str] = ["aerospace", "layout"]
        if window_id is not None:
            cmd.extend(["--window-id", str(window_id)])
        if isinstance(layout, str):
            cmd.append(layout)
        else:
            cmd.extend(layout)
        self.__run(cmd, "Failed to set layout")

    def macos_native_fullscreen(
        self,
        state: str | None = None,
        window_id: int | None = None,
        fail_if_noop: bool = False,
    ):
        cmd: list[str] = ["aerospace", "macos-native-fullscreen"]
        if window_id is not None:
            cmd.extend(["--window-id", str(window_id)])
        if fail_if_noop is True:
            cmd.append("--fail-if-noop")
        if state is not None:
            cmd.append(state)
        self.__run(cmd, "Failed to set macOS native fullscreen")

    def macos_native_minimize(self, window_id: int | None = None):
        cmd: list[str] = ["aerospace", "macos-native-minimize"]
        if window_id is not None:
            cmd.extend(["--window-id", str(window_id)])
        self.__run(cmd, "Failed to minimize window")

    def mode(self, binding_mode: str):
        cmd: list[str] = ["aerospace", "mode"]
        cmd.append(binding_mode)
        self.__run(cmd, "Failed to set mode")

    def move(
        self,
        direction: str,
        window_id: int | None = None,
        boundaries: str | None = None,
        boundaries_action: str | None = None,
    ):
        cmd: list[str] = ["aerospace", "move"]
        if boundaries is not None:
            cmd.extend(["--boundaries", boundaries])
        if boundaries_action is not None:
            cmd.extend(["--boundaries-action", boundaries_action])
        if window_id is not None:
            cmd.extend(["--window-id", str(window_id)])
        cmd.append(direction)
        self.__run(cmd, "Failed to move window")

    def move_mouse(self, mouse_position: str, fail_if_noop: bool = False):
        cmd: list[str] = ["aerospace", "move-mouse"]
        if fail_if_noop is True:
            cmd.append("--fail-if-noop")
        cmd.append(mouse_position)
        self.__run(cmd, "Failed to move mouse")

    def move_node_to_monitor(
        self,
        monitor_pattern: str | int,
        window_id: int | None = None,
        focus_follows_window: bool = False,
        wrap_around: bool = False,
        fail_if_noop: bool = False,
    ):
        cmd: list[str] = ["aerospace", "move-node-to-monitor"]
        if focus_follows_window is True:
            cmd.append("--focus-follows-window")
        if wrap_around is True:
            cmd.append("--wrap-around")
        if fail_if_noop is True:
            cmd.append("--fail-if-noop")
        if window_id is not None:
            cmd.extend(["--window-id", str(window_id)])
        cmd.append(str(monitor_pattern))
        self.__run(cmd, "Failed to move node to monitor")

    def move_node_to_workspace(
        self,
        workspace_name: str,
        window_id: int | None = None,
        focus_follows_window: bool = False,
        wrap_around: bool = False,
        fail_if_noop: bool = False,
    ):
        cmd: list[str] = ["aerospace", "move-node-to-workspace"]
        if focus_follows_window is True:
            cmd.append("--focus-follows-window")
        if wrap_around is True:
            cmd.append("--wrap-around")
        if fail_if_noop is True:
            cmd.append("--fail-if-noop")
        if window_id is not None:
            cmd.extend(["--window-id", str(window_id)])
        cmd.append(workspace_name)
        self.__run(cmd, "Failed to move node to workspace")

    def move_workspace_to_monitor(
        self,
        monitor_pattern: str | int,
        workspace: str | None = None,
        wrap_around: bool = False,
    ):
        cmd: list[str] = ["aerospace", "move-workspace-to-monitor"]
        if workspace is not None:
            cmd.extend(["--workspace", workspace])
        if wrap_around is True:
            cmd.append("--wrap-around")
        cmd.append(str(monitor_pattern))
        self.__run(cmd, "Failed to move workspace to monitor")

    def reload_config(self, no_gui: bool = False, dry_run: bool = False):
        cmd: list[str] = ["aerospace", "reload-config"]
        if no_gui is True:
            cmd.append("--no-gui")
        if dry_run is True:
            cmd.append("--dry-run")
        self.__run(cmd, "Failed to reload config")

    def resize(
        self,
        dimension: str,
        amount: str | int,
        window_id: int | None = None,
    ):
        cmd: list[str] = ["aerospace", "resize"]
        if window_id is not None:
            cmd.extend(["--window-id", str(window_id)])
        cmd.append(dimension)
        cmd.append(str(amount))
        self.__run(cmd, "Failed to resize window")

    def split(self, orientation: str, window_id: int | None = None):
        cmd: list[str] = ["aerospace", "split"]
        if window_id is not None:
            cmd.extend(["--window-id", str(window_id)])
        cmd.append(orientation)
        self.__run(cmd, "Failed to split")

    def swap(
        self,
        direction_or_nextprev: str,
        window_id: int | None = None,
        swap_focus: bool = False,
        wrap_around: bool = False,
    ):
        cmd: list[str] = ["aerospace", "swap"]
        if window_id is not None:
            cmd.extend(["--window-id", str(window_id)])
        if swap_focus is True:
            cmd.append("--swap-focus")
        if wrap_around is True:
            cmd.append("--wrap-around")
        cmd.append(direction_or_nextprev)
        self.__run(cmd, "Failed to swap")

    def summon_workspace(self, workspace: str, fail_if_noop: bool = False):
        cmd: list[str] = ["aerospace", "summon-workspace"]
        if fail_if_noop is True:
            cmd.append("--fail-if-noop")
        cmd.append(workspace)
        self.__run(cmd, "Failed to summon workspace")

    def trigger_binding(self, binding: str, mode_id: str):
        cmd: list[str] = ["aerospace", "trigger-binding"]
        cmd.append(binding)
        cmd.extend(["--mode", mode_id])
        self.__run(cmd, "Failed to trigger binding")

    def volume(
        self,
        action: str | int,
        no_gui: bool = False,
    ):
        cmd: list[str] = ["aerospace", "volume"]
        if no_gui is True:
            cmd.append("--no-gui")
        if isinstance(action, int):
            cmd.extend(["set", str(action)])
        else:
            cmd.append(action)
        self.__run(cmd, "Failed to set volume")

    def workspace(
        self,
        workspace_name: str,
        auto_back_and_forth: bool = False,
        fail_if_noop: bool = False,
        wrap_around: bool = False,
    ):
        cmd: list[str] = ["aerospace", "workspace"]
        if auto_back_and_forth is True:
            cmd.append("--auto-back-and-forth")
        if fail_if_noop is True:
            cmd.append("--fail-if-noop")
        if wrap_around is True:
            cmd.append("--wrap-around")
        cmd.append(workspace_name)
        self.__run(cmd, "Failed to set workspace")

    def workspace_back_and_forth(self):
        cmd: list[str] = ["aerospace", "workspace-back-and-forth"]
        self.__run(cmd, "Failed to switch workspace back and forth")
