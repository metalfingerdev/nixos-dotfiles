import Quickshell.Io

// Strings exist only here. Unknown names are rejected, never silently defaulted.
//   qs ipc call island open media
//   qs ipc call island alert notify "hello"
//   qs ipc call island close
//   qs ipc call island status
IpcHandler {
    target: "island"

    function open(name: string): void {
        const e = Registry.byName(name)
        if (e) IslandState.send(IslandState.Event.Open, e.view)
    }

    function alert(name: string): void {
        const e = Registry.byName(name)
        if (e) IslandState.send(IslandState.Event.Alert, e.view)
    }

    function close(): void { IslandState.send(IslandState.Event.Close) }
    function back(): void  { IslandState.send(IslandState.Event.Back) }

    // settings: plain setters, never go through send(), never change the phase
    function space(on: bool): void { IslandState.space = on }

    function mode(name: string): void {
        if (name === "pill")     IslandState.mode = IslandState.Mode.Pill
        else if (name === "notch") IslandState.mode = IslandState.Mode.Notch
    }

    function compact(name: string): void {
        if (name === "clock")     IslandState.compactWidget = IslandState.Widget.Clock
        else if (name === "date") IslandState.compactWidget = IslandState.Widget.Date
    }

    function status(): string {
        return IslandState.phaseNames[IslandState.phase] + " / " + Registry.get(IslandState.view).name
    }
}
