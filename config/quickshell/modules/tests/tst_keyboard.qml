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
    property int activity: 0
    property var pressed: []

    ViewLoader {
        id: slot
        anchors.fill: parent
        onCancel: harness.escapes++
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

    TestCase {
        name: "keyboard"
        when: windowShown

        function load(c) {
            slot.sourceComponent = null
            slot.sourceComponent = c
            harness.escapes = 0
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

        function test_view_without_focusable_items() {
            load(empty)
            keyClick(Qt.Key_Tab)
            keyClick(Qt.Key_Escape)
            compare(harness.escapes, 1)
        }
    }
}
