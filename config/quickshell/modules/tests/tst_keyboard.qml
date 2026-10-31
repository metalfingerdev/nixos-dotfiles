// Run: QT_QPA_PLATFORM=offscreen qmltestrunner -input modules/tests/tst_keyboard.qml
// Drives ViewLoader's default keyboard and Pill with real key events (no Quickshell needed).
import QtQuick
import QtTest
import "../island"
import "../components"

Item {
    id: harness
    width: 400
    height: 200

    property int escapes: 0
    property int backs: 0
    property int activity: 0
    property var pressed: []

    ViewLoader {
        id: slot
        anchors.fill: parent
        onCancel: harness.escapes++
        onBack: harness.backs++
        onActivity: harness.activity++
    }

    // a view with no keyboard code at all
    Component {
        id: plain
        Item {
            property alias a: a
            property alias b: b
            property alias c: c
            Row {
                Pill { id: a; text: "a"; onClicked: x => harness.pressed.push(["a", x]) }
                Pill { id: b; text: "b"; onClicked: x => harness.pressed.push(["b", x]) }
                Pill { id: c; text: "c"; onClicked: x => harness.pressed.push(["c", x]) }
            }
        }
    }

    // a view with its own rules (shaped like the launcher)
    Component {
        id: custom
        Item {
            id: v
            property alias field: field
            property int ups: 0
            TextInput { id: field; width: 100; height: 20; focus: true; Keys.onUpPressed: v.ups++ }
            Pill { y: 30; text: "row"; activeFocusOnTab: false; keyboardSelected: false }
        }
    }

    Component { id: empty; Item {} }

    // a 2 x 2 grid: arrows should move like on a grid, not along the Tab order
    Component {
        id: grid
        Item {
            property alias a: a
            property alias b: b
            property alias c: c
            property alias d: d
            Grid {
                columns: 2
                spacing: 8
                Pill { id: a; text: "a" }
                Pill { id: b; text: "b" }
                Pill { id: c; text: "c" }
                Pill { id: d; text: "d" }
            }
        }
    }

    // shortcuts: a typed key presses the control that has it
    Component {
        id: keyed
        Item {
            property alias plain: plainPill
            Row {
                Pill { id: plainPill; text: "plain"; onClicked: x => harness.pressed.push(["plain", x]) }
                Pill { text: "mute"; shortcut: "m"; onClicked: x => harness.pressed.push(["m", x]) }
                Pill { text: "hidden"; shortcut: "h"; visible: false; onClicked: x => harness.pressed.push(["h", x]) }
                Pill { text: "plus"; shortcut: "+"; onClicked: x => harness.pressed.push(["+", x]) }
            }
        }
    }

    // controls that act on a key: each must still report it, or the countdown runs out under the user
    Component {
        id: controls
        Column {
            property alias pill: pill
            property alias tile: tile
            property alias toggle: toggle
            property alias slider: slider
            property alias seek: seek
            Pill { id: pill; text: "pill"; onClicked: x => harness.pressed.push("pill") }
            QuickTile { id: tile; more: true; onClicked: x => harness.pressed.push("open"); onToggled: harness.pressed.push("flip") }
            Toggle { id: toggle; onToggled: on => harness.pressed.push("toggle") }
            Slider { id: slider; iconClickable: true; onIconClicked: harness.pressed.push("icon"); onMoved: v => value = v }
            Progress { id: seek; width: 100; seekable: true; onSeek: f => fraction = f }
        }
    }

    TestCase {
        name: "keyboard"
        when: windowShown

        function load(c) {
            slot.sourceComponent = null
            slot.sourceComponent = c
            harness.escapes = 0
            harness.backs = 0
            harness.activity = 0
            harness.pressed = []
            wait(0)
        }

        function test_first_item_gets_focus() {
            load(plain)
            verify(slot.item.a.activeFocus)
            verify(slot.item.a.keyboardSelected, "keyboardSelected follows focus by default")
            verify(!slot.item.b.keyboardSelected)
        }

        function test_tab_and_arrows_move_and_wrap() {
            load(plain)
            const v = slot.item
            keyClick(Qt.Key_Tab);     verify(v.b.activeFocus, "Tab")
            keyClick(Qt.Key_Right);   verify(v.c.activeFocus, "Right")
            keyClick(Qt.Key_Down);    verify(v.a.activeFocus, "Down wraps")
            keyClick(Qt.Key_Backtab); verify(v.c.activeFocus, "Backtab wraps")
            keyClick(Qt.Key_Left);    verify(v.b.activeFocus, "Left")
            keyClick(Qt.Key_Up);      verify(v.a.activeFocus, "Up")
        }

        function test_enter_and_space_press_the_focused_pill() {
            load(plain)
            keyClick(Qt.Key_Return)
            keyClick(Qt.Key_Tab)
            keyClick(Qt.Key_Space)
            keyClick(Qt.Key_Tab)
            keyClick(Qt.Key_Enter)
            compare(harness.pressed.map(p => p[0]).join(""), "abc")
            compare(harness.pressed.map(p => p[1]), [-1, -1, -1], "the keyboard sends no x: centred")
        }

        function test_only_a_mouse_click_sends_x() {
            load(plain)
            const b = slot.item.b
            mouseClick(b, 5, 5)
            compare(harness.pressed.length, 1)
            fuzzyCompare(harness.pressed[0][1], b.mapToItem(null, 5, 5).x, 1, "the click's scene x")   // mouseClick rounds to whole pixels
        }

        function test_escape() {
            load(plain)
            keyClick(Qt.Key_Escape)
            compare(harness.escapes, 1)
        }

        function test_view_rules_first_defaults_for_the_rest() {
            load(custom)
            const v = slot.item
            verify(v.field.activeFocus, "the view's own focus: true wins")
            keyClick(Qt.Key_Up)
            compare(v.ups, 1)
            verify(v.field.activeFocus, "Up was the view's, focus did not move")
            keyClick(Qt.Key_Tab)
            verify(v.field.activeFocus, "nothing else focusable: focus stays in the view")
            keyClick(Qt.Key_Escape)
            compare(harness.escapes, 1, "unhandled Escape still reaches the default")
        }

        function test_every_key_that_reaches_the_loader_is_activity() {
            load(plain)
            for (const k of [Qt.Key_Tab, Qt.Key_Right, Qt.Key_X, Qt.Key_Escape]) {
                const before = harness.activity
                keyClick(k)
                verify(harness.activity > before, "key " + k)
            }
            verify(slot.item.c.activeFocus, "reporting activity doesn't swallow the defaults")
        }

        function test_arrows_follow_the_grid() {
            load(grid)
            const v = slot.item
            verify(v.a.activeFocus)
            keyClick(Qt.Key_Down);  verify(v.c.activeFocus, "Down: the one below, not the next in Tab order")
            keyClick(Qt.Key_Right); verify(v.d.activeFocus, "Right")
            keyClick(Qt.Key_Up);    verify(v.b.activeFocus, "Up")
            keyClick(Qt.Key_Left);  verify(v.a.activeFocus, "Left")
            keyClick(Qt.Key_Left);  verify(v.d.activeFocus, "nothing to the left: the previous one, wrapping")
        }

        function test_shortcuts_press_their_control() {
            load(keyed)
            keyClick(Qt.Key_M)
            keyClick(Qt.Key_H)                       // hidden: ignored
            keyClick(Qt.Key_Plus)
            keyClick(Qt.Key_Q)                       // nobody's: ignored
            compare(harness.pressed.map(p => p[0]).join(""), "m+")
            keyClick(Qt.Key_M, Qt.ControlModifier)   // with a modifier: not a shortcut
            compare(harness.pressed.length, 2)
        }

        function test_backspace_goes_back_escape_closes() {
            load(plain)
            keyClick(Qt.Key_Backspace)
            compare(harness.backs, 1, "Backspace: back")
            compare(harness.escapes, 0)
            keyClick(Qt.Key_Escape)
            compare(harness.escapes, 1, "Escape: close")
            compare(harness.backs, 1)
        }

        function test_keys_a_control_acts_on_count_as_activity() {
            load(controls)
            const v = slot.item
            for (const [item, key, wanted] of [[v.pill, Qt.Key_Return, "pill"], [v.pill, Qt.Key_Space, "pill"],
                                               [v.tile, Qt.Key_Return, "open"], [v.tile, Qt.Key_Space, "flip"],
                                               [v.toggle, Qt.Key_Enter, "toggle"], [v.slider, Qt.Key_Space, "icon"]]) {
                item.forceActiveFocus()
                harness.pressed = []
                const before = harness.activity
                keyClick(key)
                compare(harness.pressed, [wanted], wanted)
                verify(harness.activity > before, wanted + " is activity")
            }
        }

        function test_left_and_right_step_a_control_and_keep_its_focus() {
            load(controls)
            const v = slot.item
            for (const [item, get] of [[v.slider, () => v.slider.value], [v.seek, () => v.seek.fraction]]) {
                item.forceActiveFocus()
                const before = harness.activity
                keyClick(Qt.Key_Right)
                verify(get() > 0, "stepped")
                verify(item.activeFocus, "kept focus")
                verify(harness.activity > before, "is activity")
                keyClick(Qt.Key_Left)
                compare(get(), 0)
            }
        }

        function test_view_without_focusable_items() {
            load(empty)
            keyClick(Qt.Key_Tab)
            keyClick(Qt.Key_Escape)
            compare(harness.escapes, 1)
        }
    }
}
