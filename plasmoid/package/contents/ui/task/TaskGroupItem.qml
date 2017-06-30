/*
*  Copyright 2016  Smith AR <audoban@openmailbox.org>
*                  Michail Vourlakos <mvourlakos@gmail.com>
*
*  This file is part of Latte-Dock
*
*  Latte-Dock is free software; you can redistribute it and/or
*  modify it under the terms of the GNU General Public License as
*  published by the Free Software Foundation; either version 2 of
*  the License, or (at your option) any later version.
*
*  Latte-Dock is distributed in the hope that it will be useful,
*  but WITHOUT ANY WARRANTY; without even the implied warranty of
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*  GNU General Public License for more details.
*
*  You should have received a copy of the GNU General Public License
*  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

import QtQuick 2.0
import QtQuick.Layouts 1.1
import QtGraphicalEffects 1.0

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents

Item{
    id:glowFrame
    width: ( icList.orientation === Qt.Horizontal ) ? wrapper.regulatorWidth : size
    height: ( icList.orientation === Qt.Vertical ) ? wrapper.regulatorHeight : size

    //property int size: Math.ceil( root.iconSize/13 ) //5
    property int size: root.statesLineSize

    //SystemPalette { id: myPalette; colorGroup: SystemPalette.Active }
    property color isActiveColor: theme.buttonFocusColor
    //property color isShownColor: plasmoid.configuration.threeColorsWindows ? root.shownDotColor : isActiveColor
    //property color isShownColor: isActiveColor
    property color minimizedColor: root.threeColorsWindows ? root.minimizedDotColor : isActiveColor
    property color notActiveColor: mainItemContainer.hasMinimized ? minimizedColor : isActiveColor

    /*Rectangle{
        anchors.fill: parent
        border.width: 1
        border.color: "yellow"
        color: "transparent"
        opacity:0.6
    }*/
    Item{
        anchors.centerIn: parent

        width: flowItem.width
        height: flowItem.height

        Flow{
            id: flowItem
            flow: ( icList.orientation === Qt.Vertical ) ? Flow.TopToBottom : Flow.LeftToRight

            GlowPoint{
                id:firstPoint
                visible: ( !IsLauncher ) ? true: false

                basicColor: IsActive===true || (mainItemContainer.isGroupParent && mainItemContainer.hasShown)?
                                glowFrame.isActiveColor : glowFrame.notActiveColor

                roundCorners: true
                showAttention: mainItemContainer.isDemandingAttention && plasmoid.status === PlasmaCore.Types.RequiresAttentionStatus ?
                                   true : false

                opacity: (!mainItemContainer.hasActive && root.showPreviews
                          && windowsPreviewDlg.activeItem && (windowsPreviewDlg.activeItem === mainItemContainer)) ? 0.4 : 1

                property int stateWidth: mainItemContainer.isGroupParent ? (wrapper.regulatorWidth - secondPoint.width) : wrapper.regulatorWidth - spacer.width
                property int stateHeight: mainItemContainer.isGroupParent ? wrapper.regulatorHeight - secondPoint.height : wrapper.regulatorHeight - spacer.height

                property int animationTime: root.durationTime* (0.7*units.longDuration)

                property bool isActive: mainItemContainer.hasActive
                                        || (root.showPreviews && windowsPreviewDlg.activeItem && (windowsPreviewDlg.activeItem === mainItemContainer))

                property bool vertical: root.vertical

                property real scaleFactor: wrapper.mScale

                function updateInitialSizes(){
                    if(glowFrame){
                        if(vertical)
                            width = glowFrame.size;
                        else
                            height = glowFrame.size;

                        if(vertical && isActive)
                            height = stateHeight;
                        else
                            height = glowFrame.size;

                        if(!vertical && isActive)
                            width = stateWidth;
                        else
                            width = glowFrame.size;
                    }
                }


                onIsActiveChanged: {
                   // if(mainItemContainer.hasActive || windowsPreviewDlg.visible)
                        activeAndReverseAnimation.start();
                }

                onScaleFactorChanged: {
                    if(!activeAndReverseAnimation.running && !root.vertical && isActive){
                        width = stateWidth;
                    }
                    else if (!activeAndReverseAnimation.running && root.vertical && isActive){
                        height = stateHeight;
                    }
                }

                onStateWidthChanged:{
                    if(!activeAndReverseAnimation.running && !vertical && isActive)
                        width = stateWidth;
                }

                onStateHeightChanged:{
                    if(!activeAndReverseAnimation.running && vertical && isActive)
                        height = stateHeight;
                }

                onVerticalChanged: updateInitialSizes();

                Component.onCompleted: {
                    updateInitialSizes();

                    root.onIconSizeChanged.connect(updateInitialSizes);
                }

                NumberAnimation{
                    id: activeAndReverseAnimation
                    target: firstPoint
                    property: root.vertical ? "height" : "width"
                    to: mainItemContainer.hasActive
                        || (root.showPreviews && windowsPreviewDlg.activeItem && (windowsPreviewDlg.activeItem === mainItemContainer))
                        ? (root.vertical ? firstPoint.stateHeight : firstPoint.stateWidth) : glowFrame.size
                    duration: firstPoint.animationTime
                    easing.type: Easing.InQuad

                    onStopped: firstPoint.updateInitialSizes()
                }
            }

            Item{
                id:spacer
                width: mainItemContainer.isGroupParent ? 0.5*glowFrame.size : 0
                height: mainItemContainer.isGroupParent ? 0.5*glowFrame.size : 0
            }

            GlowPoint{
                id:secondPoint
                width: visible ? glowFrame.size : 0
                height: width

                basicColor: state2Color //mainItemContainer.hasActive ? state2Color : state1Color
                roundCorners: true
                visible:  ( mainItemContainer.isGroupParent && root.dotsOnActive )
                          || (mainItemContainer.isGroupParent && !mainItemContainer.hasActive)? true: false

                //when there is no active window
                property color state1Color: mainItemContainer.hasShown ? glowFrame.isActiveColor : glowFrame.minimizedColor
                //when there is active window
                property color state2Color: mainItemContainer.hasMinimized ? glowFrame.minimizedColor : glowFrame.isActiveColor
            }
        }
    }
}// number of windows indicator

