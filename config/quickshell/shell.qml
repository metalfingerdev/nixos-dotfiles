//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

import QtQuick
import Quickshell
import "modules/dynamicGlacier" as Island

ShellRoot {
    id: root

    Island.DynamicGlacier {
    }

}
