import org.kde.breeze.components

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2

import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.kirigami 2.20 as Kirigami

SessionManagementScreen {
    id: root
    property Item mainPasswordBox: passwordBox

    property bool showUsernamePrompt: !showUserList

    property string lastUserName
    property bool loginScreenUiVisible: false

    // The login button must remain above the on-screen keyboard.
    property int visibleBoundary: mapFromItem(loginButton, 0, 0).y
    onHeightChanged: visibleBoundary = mapFromItem(loginButton, 0, 0).y + loginButton.height + Kirigami.Units.smallSpacing

    property real fontSize: Kirigami.Theme.defaultFont.pointSize

    signal loginRequest(string username, string password)

    onShowUsernamePromptChanged: {
        if (!showUsernamePrompt) {
            lastUserName = ""
        }
    }

    onUserSelected: {
        // Escape also emits this signal and must not trigger a login.
        passwordBox.clear()
        focusFirstVisibleFormControl();
    }

    QQC2.StackView.onActivating: {
        // Wait until the controls are visible before assigning focus.
        Qt.callLater(focusFirstVisibleFormControl);
    }

    function focusFirstVisibleFormControl() {
        const nextControl = (userNameInput.visible
            ? userNameInput
            : (passwordBox.visible
                ? passwordBox
                : loginButton));
        // TabFocusReason gives the login button a visible focus indicator.
        nextControl.forceActiveFocus(Qt.TabFocusReason);
    }

    function startLogin() {
        const username = showUsernamePrompt ? userNameInput.text : userList.selectedUser
        const password = passwordBox.text

        footer.enabled = false
        mainStack.enabled = false
        userListComponent.userList.opacity = 0.75

        // Move focus off the text field before closing to avoid QTBUG-55460.
        // https://bugreports.qt.io/browse/QTBUG-55460
        loginButton.forceActiveFocus();
        loginRequest(username, password);
    }

    PlasmaComponents3.TextField {
        id: userNameInput
        font.pointSize: fontSize + 1
        Layout.fillWidth: true

        text: lastUserName
        visible: showUsernamePrompt
        focus: showUsernamePrompt && !lastUserName
        placeholderText: i18nd("plasma-desktop-sddm-theme", "Username")

        onAccepted: {
            if (root.loginScreenUiVisible) {
                passwordBox.forceActiveFocus()
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true

        PlasmaExtras.PasswordField {
            id: passwordBox
            font.pointSize: fontSize + 1
            Layout.fillWidth: true

            placeholderText: i18nd("plasma-desktop-sddm-theme", "Password")
            focus: !showUsernamePrompt || lastUserName

            // SDDM does not load the Breeze icon set needed by the reveal action.
            rightActions: []

            onAccepted: {
                if (root.loginScreenUiVisible) {
                    startLogin();
                }
            }

            visible: root.showUsernamePrompt || userList.currentItem.needsPassword

            Keys.onEscapePressed: {
                mainStack.currentItem.forceActiveFocus();
            }

            // Handle arrow keys here so they can also reach the password field.
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Left && !text) {
                    userList.decrementCurrentIndex();
                    event.accepted = true
                }
                if (event.key === Qt.Key_Right && !text) {
                    userList.incrementCurrentIndex();
                    event.accepted = true
                }
            }

            Connections {
                target: sddm
                function onLoginFailed() {
                    passwordBox.selectAll()
                    passwordBox.forceActiveFocus()
                }
            }
        }

        PlasmaComponents3.Button {
            id: loginButton
            Accessible.name: i18nd("plasma-desktop-sddm-theme", "Log In")
            Layout.preferredHeight: passwordBox.implicitHeight
            Layout.preferredWidth: text.length === 0 ? loginButton.Layout.preferredHeight : -1

            icon.name: text.length === 0 ? (root.LayoutMirroring.enabled ? "go-previous" : "go-next") : ""

            text: root.showUsernamePrompt || userList.currentItem.needsPassword ? "" : i18n("Log In")
            onClicked: startLogin()
            Keys.onEnterPressed: clicked()
            Keys.onReturnPressed: clicked()
        }
    }
}
