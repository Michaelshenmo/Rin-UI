import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import "../themes"
import "../components"
import "../windows"

FluentWindowBase {
    id: window
    visible: true
    title: qsTr("Fluent Window")
    width: 900
    height: 600
    minimumWidth: 400
    minimumHeight: 300
    titleEnabled: false

    // 外观 / Appearance //
    property bool appLayerEnabled: true  // 应用层背景


    property alias navItems: navigationBar.navModel
    property alias navCurrentIndex: navigationBar.currentIndex
    property int lastIndex: 0  // 上个页面索引
    property var pageCache: ({})

    // 本来想做成这样的，突然发现fluent的动画好像不是这样的（）
    // property int pushEnterFromY: navigationBar.lastIndex > window.navCurrentIndex ? height : -height
    // property int pushOutFromY: navigationBar.lastIndex < window.navCurrentIndex ? height : -height
    property int pushEnterFromY: height

    RowLayout {
        id: rowLayout
        anchors.fill: parent

        NavigationBar {
            id: navigationBar
            windowTitle: window.title
            windowIcon: window.icon
            stackView: stackView
            Layout.fillHeight: true
        }

        // 主体内容区域
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            // clip: true

            Rectangle {
                id: appLayer
                width: parent.width + Utils.windowDragArea + radius
                height: parent.height + Utils.windowDragArea + radius
                color: Theme.currentTheme.colors.layerColor
                border.color: Theme.currentTheme.colors.cardBorderColor
                border.width: 1
                opacity: window.appLayerEnabled
                radius: Theme.currentTheme.appearance.windowRadius
            }


            StackView {
                id: stackView
                anchors.fill: parent
                anchors.leftMargin: 1
                anchors.topMargin: 1


                // 切换动画 / Page Transition //
                pushEnter : Transition {
                    PropertyAnimation {
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: Utils.animationSpeed
                        easing.type: Easing.InOutQuad
                    }

                    PropertyAnimation {
                        property: "y"
                        from: pushEnterFromY
                        to: 0
                        duration: Utils.animationSpeedMiddle
                        easing.type: Easing.OutQuint
                    }
                }

                pushExit : Transition {
                    PropertyAnimation {
                        property: "opacity"
                        from: 1
                        to: 0
                        duration: Utils.animationSpeed
                        easing.type: Easing.InOutQuad
                    }
                }

                popExit : Transition {
                    PropertyAnimation {
                        property: "opacity"
                        from: 1
                        to: 0
                        duration: Utils.animationSpeed
                        easing.type: Easing.InOutQuad
                    }

                    PropertyAnimation {
                        property: "y"
                        from: 0
                        to: pushEnterFromY
                        duration: Utils.animationSpeedMiddle
                        easing.type: Easing.InOutQuint
                    }
                }

                popEnter : Transition {
                    SequentialAnimation {
                        PauseAnimation {  // 延时 200ms
                            duration: animationSpeed
                        }
                        PropertyAnimation {
                            property: "opacity"
                            from: 0
                            to: 1
                            duration: Utils.appearanceSpeed
                            easing.type: Easing.InOutQuad
                        }
                    }
                }

                initialItem: Item {}

                function safePop() {
                    console.log("Popping Page; Depth:", stackView.depth, navigationBar.lastIndex)
                    if (stackView.depth > 2) {
                        stackView.pop()
                        navigationBar.currentIndex = navigationBar.lastIndex[stackView.depth - 2]
                        navigationBar.lastIndex.pop()
                    } else {
                        console.log("Can't pop: only root page left")
                    }
                }
            }

                // 导航切换逻辑
                Connections {
                    target: navigationBar
                    function onCurrentIndexChanged() {
                        let index = navigationBar.currentIndex
                        let page = navItems.get(index).page
                        console.log("Pushing Page:", page, "Index:", index)
                        if (stackView.depth === 0 || stackView.currentItem.objectName !== page) {
                            checkPage(page)
                        }
                    }
                }



                Connections {
                    target: navItems
                    function onCountChanged() {
                        if (navItems.count > 0 && navigationBar.currentIndex === -1) {
                            navigationBar.currentIndex = 0;
                        }
                    }
                }
            }
        }

    // 页面确认
    function checkPage(page) {
        // 重复检测
        if (String(stackView.currentItem.objectName) === String(page)) {
            console.log("Page already loaded:", page)
            return
        }

        let component = Qt.createComponent(page)  // 页面转控件

        if (component.status === Component.Ready) {
             console.log("Depth:", stackView.depth)
            stackView.push(page, {objectName: page})


        } else if (component.status === Component.Error) {
            console.error("Failed to load:", page, component.errorString())
            stackView.push("ErrorPage.qml", {
                errorMessage: component.errorString(),  // 传参
                page: page,
                objectName: page
            })
        }
    }
}