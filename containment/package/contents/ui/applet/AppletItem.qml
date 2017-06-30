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

import QtQuick 2.1
import QtQuick.Layouts 1.1
import QtGraphicalEffects 1.0

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.kquickcontrolsaddons 2.0

import org.kde.latte 0.1 as Latte

import "../../code/AppletIdentifier.js" as AppletIndetifier

Item {
    id: container

    visible: false
    width: isInternalViewSplitter && !root.editMode ? 0 : (root.isHorizontal ? computeWidth : computeWidth + shownAppletMargin)
    height: isInternalViewSplitter && !root.editMode ? 0 : (root.isVertical ?  computeHeight : computeHeight + shownAppletMargin)

    property bool animationsEnabled: true
    property bool animationWasSent: false  //protection flag for animation broadcasting
    property bool canBeHovered: true
    property bool inFillCalculations: false //temp record, is used in calculations for fillWidth,fillHeight applets
    property bool needsFillSpace: { //fill flag, it is used in calculations for fillWidth,fillHeight applets
        if (!applet || !applet.Layout ||  (applet && applet.pluginName === "org.kde.plasma.panelspacer"))
            return false;

        if (((root.isHorizontal && applet.Layout.fillWidth===true)
             || (root.isVertical && applet.Layout.fillHeight===true))
                && (applet.status !== PlasmaCore.Types.HiddenStatus))
            return true;
        else
            return false;
    }
    property bool showZoomed: false
    property bool lockZoom: false
    property bool isHidden: applet && applet.status === PlasmaCore.Types.HiddenStatus ? true : false
    property bool isInternalViewSplitter: (internalSplitterId > 0)
    property bool isZoomed: false
    property bool isSeparator: applet && applet.pluginName === "audoban.applet.separator"

    //applet is in starting edge
    /*property bool startEdge: index < layoutsContainer.endLayout.beginIndex ? (index === 0)&&(layoutsContainer.mainLayout.count > 1) :
                                                               (index === layoutsContainer.endLayout.beginIndex)&&(layoutsContainer.endLayout.count > 1)*/
    property bool startEdge: (index === layoutsContainer.startLayout.beginIndex) || (index === layoutsContainer.mainLayout.beginIndex) || (index === layoutsContainer.endLayout.beginIndex)
    //applet is in ending edge
    property bool endEdge: plasmoid.configuration.panelPosition !== Latte.Dock.Justify ? (index === layoutsContainer.mainLayout.beginIndex + layoutsContainer.mainLayout.count - 1)&&(layoutsContainer.mainLayout.count>1) :
                                                                                         (((index === layoutsContainer.startLayout.beginIndex+layoutsContainer.startLayout.count-2)&&(layoutsContainer.startLayout.count>2))
                                                                                          ||((index === layoutsContainer.mainLayout.beginIndex+layoutsContainer.mainLayout.count-2)&&(layoutsContainer.mainLayout.count>2))
                                                                                          ||((index === layoutsContainer.endLayout.beginIndex+layoutsContainer.endLayout.count-1)&&(layoutsContainer.endLayout.count>1)))



    property int animationTime: root.durationTime* (1.2 *units.shortDuration) // 70
    property int hoveredIndex: layoutsContainer.hoveredIndex
    property int index: -1
    property int appletMargin: (applet && (applet.pluginName === root.plasmoidName))
                               || isInternalViewSplitter
                               || root.reverseLinesPosition ? 0 : root.statesLineSize
    property int maxWidth: root.isHorizontal ? root.height : root.width
    property int maxHeight: root.isHorizontal ? root.height : root.width
    property int shownAppletMargin: applet && (applet.pluginName === "org.kde.plasma.systemtray") ? 0 : appletMargin
    property int internalSplitterId: 0
    property int previousIndex: -1
    property int sizeForFill: -1 //it is used in calculations for fillWidth,fillHeight applets
    property int spacersMaxSize: Math.max(0,Math.ceil(0.5*root.iconSize) - root.iconMargin)
    property int status: applet ? applet.status : -1

    property real animationStep: Math.min(3, root.iconSize / 8)
    property real computeWidth: root.isVertical ? wrapper.width :
                                                  hiddenSpacerLeft.width+wrapper.width+hiddenSpacerRight.width

    property real computeHeight: root.isVertical ? hiddenSpacerLeft.height + wrapper.height + hiddenSpacerRight.height :
                                                   wrapper.height

    property string title: isInternalViewSplitter ? "Now Dock Splitter" : ""

    property Item applet: null
    property Item latteApplet: applet && (applet.pluginName === root.plasmoidName) ?
                                   (applet.children[0] ? applet.children[0] : null) : null
    property Item appletWrapper: applet &&
                                 ((applet.pluginName === root.plasmoidName) ||
                                  (applet.pluginName === "org.kde.plasma.systemtray")) ? wrapper : wrapper.wrapperContainer
    property Item appletIconItem; //first applet's IconItem, to be activated onExit signal
    property Item appletImageItem;

    //this is used for folderView and icon widgets to fake their visual
    property bool fakeIconItem: applet && appletIconItem //(applet.pluginName === "org.kde.plasma.folder" || applet.pluginName === "org.kde.plasma.icon")

    property alias containsMouse: appletMouseArea.containsMouse
    property alias pressed: appletMouseArea.pressed

    /*onComputeHeightChanged: {
        if(index==0)
            console.log(computeHeight);
    }*/

    //a timer that is used in  order to init the fake applets on startup
    Timer {
        id: fakeInitTimer
        interval: 4000
        onTriggered: AppletIndetifier.reconsiderAppletIconItem();
    }

    //set up the fake containers and properties for when a fakeIconItem must be presented to the user
    //because the plasma widgets specific implementation breaks the Latte experience
    onFakeIconItemChanged: {
        if (fakeIconItem) {
            applet.opacity = 0;

            if (applet.pluginName === "org.kde.plasma.folder") {
                applet.parent =  wrapper.fakeIconItemContainer;
                applet.anchors.fill = wrapper.fakeIconItemContainer;
            }

            wrapper.disableScaleWidth = false;
            wrapper.disableScaleHeight = false;

            wrapper.updateLayoutWidth();
            wrapper.updateLayoutHeight();
        }
    }

    /// BEGIN functions
    function checkIndex(){
        index = -1;

        for(var i=0; i<layoutsContainer.startLayout.count; ++i){
            if(layoutsContainer.startLayout.children[i] === container){
                index = layoutsContainer.startLayout.beginIndex + i;
                break;
            }
        }

        for(var i=0; i<layoutsContainer.mainLayout.count; ++i){
            if(layoutsContainer.mainLayout.children[i] === container){
                index = layoutsContainer.mainLayout.beginIndex + i;
                break;
            }
        }

        for(var i=0; i<layoutsContainer.endLayout.count; ++i){
            if(layoutsContainer.endLayout.children[i] === container){
                //create a very high index in order to not need to exchange hovering messages
                //between layoutsContainer.mainLayout and layoutsContainer.endLayout
                index = layoutsContainer.endLayout.beginIndex + i;
                break;
            }
        }


        if(container.latteApplet){
            if(index===layoutsContainer.startLayout.beginIndex || index===layoutsContainer.mainLayout.beginIndex || index===layoutsContainer.endLayout.beginIndex)
                latteApplet.disableLeftSpacer = false;
            else
                latteApplet.disableLeftSpacer = true;

            if( index === layoutsContainer.startLayout.beginIndex + layoutsContainer.startLayout.count - 1
                    || index===layoutsContainer.mainLayout.beginIndex + layoutsContainer.mainLayout.count - 1
                    || index === layoutsContainer.endLayout.beginIndex + layoutsContainer.endLayout.count - 1)
                latteApplet.disableRightSpacer = false;
            else
                latteApplet.disableRightSpacer = true;
        }
    }

    //this functions gets the signal from the plasmoid, it can be used for signal items
    //outside the LatteApplet Plasmoid
    //property int debCounter: 0;
    function clearZoom(){
        if (root.globalDirectRender){
            wrapper.zoomScale = 1;
        } else {
            restoreAnimation.start();
        }

        //if (restoreAnimation)
        //    restoreAnimation.start();
        // if(wrapper)
        //     wrapper.zoomScale = 1;
    }

    function checkCanBeHovered(){
        if ( (((applet && (applet.Layout.minimumWidth > root.iconSize) && root.isHorizontal) ||
               (applet && (applet.Layout.minimumHeight > root.iconSize) && root.isVertical))
              && (applet && applet.pluginName !== "org.kde.plasma.panelspacer")
              && !container.fakeIconItem)
                || (container.needsFillSpace)){
            canBeHovered = false;
        }
        else{
            canBeHovered = true;
        }
    }

    //! pos in global root positioning
    function containsPos(pos) {
        var relPos = root.mapToItem(container,pos.x, pos.y);

        if (relPos.x>=0 && relPos.x<=width && relPos.y>=0 && relPos.y<=height)
            return true;

        return false;
    }

    function reconsiderAppletIconItem() {
        AppletIndetifier.reconsiderAppletIconItem();
    }

    ///END functions

    //BEGIN connections
    onAppletChanged: {
        if (!applet) {
            destroy();
        } else {
            AppletIndetifier.reconsiderAppletIconItem();
            fakeInitTimer.start();
        }
    }

    onHoveredIndexChanged:{
        if ( (Math.abs(hoveredIndex-index) > 1) && (hoveredIndex !== -1) ) {
            wrapper.zoomScale = 1;
        }

        if (Math.abs(hoveredIndex-index) >= 1) {
            hiddenSpacerLeft.nScale = 0;
            hiddenSpacerRight.nScale = 0;
        }
    }

    onIndexChanged: {
        if (container.latteApplet) {
            root.latteAppletPos = index;
        }

        if (isHidden) {
            parabolicManager.setHidden(previousIndex, index);
        }

        if (isSeparator) {
            parabolicManager.setSeparator(previousIndex, index);
        }

        if (index>-1) {
            previousIndex = index;
        }
    }

    onIsHiddenChanged: {
        if (isHidden) {
            parabolicManager.setHidden(-1, index);
        } else {
            parabolicManager.setHidden(index, -1);
        }
    }

    onIsSeparatorChanged: {
        if (isSeparator) {
            parabolicManager.setSeparator(-1, index);
        } else {
            parabolicManager.setSeparator(index, -1);
        }

    }

    onLatteAppletChanged: {
        if(container.latteApplet){
            root.latteApplet = container.latteApplet;
            root.latteAppletContainer = container;
            root.latteAppletPos = index;
            latteApplet.latteDock = root;
            latteApplet.forceHidePanel = true;
        }
    }

    onNeedsFillSpaceChanged: checkCanBeHovered();

    onShowZoomedChanged: {
        if(showZoomed){
            //var newZ = container.maxHeight / root.iconSize;
            //wrapper.zoomScale = newZ;
            wrapper.zoomScale = 1;
        }
        else{
            wrapper.zoomScale = 1;
        }
    }

    Component.onCompleted: {
        checkIndex();
        root.updateIndexes.connect(checkIndex);
        root.clearZoomSignal.connect(clearZoom);
    }

    Component.onDestruction: {
        if (isSeparator){
            parabolicManager.setSeparator(previousIndex, -1);
        }

        if (isHidden)
            parabolicManager.setHidden(previousIndex, -1);

        root.updateIndexes.disconnect(checkIndex);
        root.clearZoomSignal.disconnect(clearZoom);
    }


    Connections{
        target: root
        onLatteAppletHoveredIndexChanged: {
            if ( (root.zoomFactor>1) && (root.latteAppletHoveredIndex >= 0) ){
                var distance = 2;
                //for Tasks plasmoid distance of 2 is not always safe there are
                //cases that needs to be 3, when an internal separator there is
                //between the hovered task and the current applet
                if (root.latteInternalSeparatorPos>=0) {
                    if ((index < root.latteAppletPos && root.latteInternalSeparatorPos < root.latteAppletHoveredIndex)
                            || (index > root.latteAppletPos && root.latteInternalSeparatorPos > root.latteAppletHoveredIndex)) {
                        distance = 3;
                    }
                }

                if(Math.abs(index-root.latteAppletPos+root.latteAppletHoveredIndex)>=distance) {
                    container.clearZoom();
                }
            }
        }
    }

    Connections{
        target: layoutsContainer
        onHoveredIndexChanged:{
            //for applets it is safe to consider that a distance of 2
            //is enough to clearZoom
            if ( (root.zoomFactor>1) && (layoutsContainer.hoveredIndex>=0)
                    && (Math.abs(index-layoutsContainer.hoveredIndex)>=2))
                container.clearZoom();
        }
    }

    ///END connections

    PlasmaComponents.BusyIndicator {
        z: 1000
        visible: applet && applet.busy
        running: visible
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height)
        height: width
    }

    /*  Rectangle{
        anchors.fill: parent
        color: "transparent"
        border.color: "green"
        border.width: 1
    }*/

    Flow{
        id: appletFlow
        width: container.computeWidth
        height: container.computeHeight

        anchors.rightMargin: (latteApplet || (showZoomed && root.editMode)) ||
                             (plasmoid.location !== PlasmaCore.Types.RightEdge) ? 0 : shownAppletMargin
        anchors.leftMargin: (latteApplet || (showZoomed && root.editMode)) ||
                            (plasmoid.location !== PlasmaCore.Types.LeftEdge) ? 0 : shownAppletMargin
        anchors.topMargin: (latteApplet || (showZoomed && root.editMode)) ||
                           (plasmoid.location !== PlasmaCore.Types.TopEdge)? 0 : shownAppletMargin
        anchors.bottomMargin: (latteApplet || (showZoomed && root.editMode)) ||
                              (plasmoid.location !== PlasmaCore.Types.BottomEdge) ? 0 : shownAppletMargin


        // a hidden spacer for the first element to add stability
        // IMPORTANT: hidden spacers must be tested on vertical !!!
        Item{
            id: hiddenSpacerLeft
            //we add one missing pixel from calculations
            width: root.isHorizontal ? nHiddenSize : wrapper.width
            height: root.isHorizontal ? wrapper.height : nHiddenSize

            ///check also if this is the first plasmoid in anylayout
            visible: container.startEdge || separatorSpace>0

            property bool neighbourSeparator: false;

            //in case there is a neighbour internal separator
            property int separatorSpace: ((root.latteApplet && root.latteApplet.hasInternalSeparator
                                          && (root.latteApplet.internalSeparatorPos === root.tasksCount-1) && index===root.latteAppletPos+1)
                                         || neighbourSeparator) && !container.isSeparator && !container.latteApplet ? (2+root.iconMargin/2) : 0
            property real nHiddenSize: (nScale > 0) ? (container.spacersMaxSize * nScale) + separatorSpace : separatorSpace

            property real nScale: 0

            Behavior on nScale {
                enabled: !root.globalDirectRender
                NumberAnimation { duration: 3*container.animationTime }
            }

            Behavior on nScale {
                enabled: root.globalDirectRender
                NumberAnimation { duration: root.directRenderAnimationTime }
            }

            Connections{
                target: root
                onSeparatorsUpdated: {
                    hiddenSpacerLeft.neighbourSeparator = parabolicManager.isSeparator(index-1);
                }
            }

            Loader{
                width: !root.isVertical ? parent.width : 1
                height: !root.isVertical ? 1 : parent.height
                x: root.isVertical ? parent.width /2 : 0
                y: !root.isVertical ? parent.height /2 : 0

                active: root.debugMode

                sourceComponent: Rectangle{
                    border.width: 1
                    border.color: "red"
                    color: "transparent"
                }
            }
        }

        AppletItemWrapper{ id: wrapper }


        // a hidden spacer on the right for the last item to add stability
        Item{
            id: hiddenSpacerRight
            //we add one missing pixel from calculations
            width: root.isHorizontal ? nHiddenSize : wrapper.width
            height: root.isHorizontal ? wrapper.height : nHiddenSize

            //check if this last plasmoid in any layout
            visible: container.endEdge || separatorSpace>0

            property bool neighbourSeparator: false;
            //in case there is a neighbour internal separator
            property int separatorSpace: ((root.latteApplet &&  root.latteApplet.hasInternalSeparator
                                          && root.latteApplet.internalSeparatorPos === 0 && index===root.latteAppletPos-1)
                                         || neighbourSeparator) && !container.isSeparator && !container.latteApplet ? (2+root.iconMargin/2) : 0
            property real nHiddenSize: (nScale > 0) ? (container.spacersMaxSize * nScale) + separatorSpace : separatorSpace

            property real nScale: 0

            Behavior on nScale {
                enabled: !root.globalDirectRender
                NumberAnimation { duration: 3*container.animationTime }
            }

            Behavior on nScale {
                enabled: root.globalDirectRender
                NumberAnimation { duration: root.directRenderAnimationTime }
            }

            Connections{
                target: root
                onSeparatorsUpdated: {
                    hiddenSpacerRight.neighbourSeparator = parabolicManager.isSeparator(index+1);
                }
            }

            Loader{
                width: !root.isVertical ? parent.width : 1
                height: !root.isVertical ? 1 : parent.height
                x: root.isVertical ? parent.width /2 : 0
                y: !root.isVertical ? parent.height /2 : 0

                active: root.debugMode

                sourceComponent: Rectangle{
                    border.width: 1
                    border.color: "red"
                    color: "transparent"
                }
            }
        }

    }// Flow with hidden spacers inside

    //! The Launchers Area Indicator
    Rectangle{
        anchors.fill: parent
        radius: root.iconSize/10

        property color tempColor: "#aa222222"
        color: tempColor
        border.width: 1
        border.color: "#ff656565"

        opacity: latteApplet && root.addLaunchersMessage ? 1 : 0

        Behavior on opacity{
            NumberAnimation { duration: 2*root.durationTime*container.animationTime }
        }

        PlasmaExtras.Heading {
            width: parent.width
            height: parent.height

            text: i18n("Launchers Area")
            level: 3
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
            elide: Text.ElideRight

            rotation: {
                if (root.isHorizontal)
                    return 0;
                else if (plasmoid.location === PlasmaCore.Types.LeftEdge)
                    return -90;
                else if (plasmoid.location === PlasmaCore.Types.RightEdge)
                    return 90;
            }
        }
    }


    MouseArea{
        id: appletMouseArea

        anchors.fill: parent
        enabled: (!latteApplet)&&(canBeHovered)&&(!root.editMode)//&&(!lockZoom)
        hoverEnabled: !root.editMode && (!latteApplet) ? true : false
        propagateComposedEvents: true

        //! a way must be found in order for this be enabled
        //! only to support springloading for plasma 5.10
        //! also on this is based the tooltips behavior by enabling it
        //! plasma tooltips are disabled
        visible: !container.latteApplet && !lockZoom && canBeHovered && !(container.isSeparator && !root.editMode)  //&& (root.zoomFactor>1)

        property bool pressed: false

        onClicked: {
            pressed = false;
            mouse.accepted = false;
        }

        onEntered: {
            //AppletIndetifier.reconsiderAppletIconItem();

            if (lockZoom || !canBeHovered) {
                return;
            }

            layoutsContainer.hoveredIndex = index;

            if (root.isHorizontal){
                layoutsContainer.currentSpot = mouseX;
                wrapper.calculateScales(mouseX);
            }
            else{
                layoutsContainer.currentSpot = mouseY;
                wrapper.calculateScales(mouseY);
            }
        }

        onExited:{
            if (appletIconItem && appletIconItem.visible)
                appletIconItem.active = false;

            if (root.zoomFactor>1){
                checkRestoreZoom.start();
            }
        }

        onPositionChanged: {
            //  if(!pressed){
            if (lockZoom || !canBeHovered) {
                mouse.accepted = false;
                return;
            }

            if (root.isHorizontal){
                var step = Math.abs(layoutsContainer.currentSpot-mouse.x);
                if (step >= container.animationStep){
                    layoutsContainer.hoveredIndex = index;
                    layoutsContainer.currentSpot = mouse.x;

                    wrapper.calculateScales(mouse.x);
                }
            }
            else{
                var step = Math.abs(layoutsContainer.currentSpot-mouse.y);
                if (step >= container.animationStep){
                    layoutsContainer.hoveredIndex = index;
                    layoutsContainer.currentSpot = mouse.y;

                    wrapper.calculateScales(mouse.y);
                }
            }
            //  }
            mouse.accepted = false;
        }

        onPressed: {
            pressed = true;
            mouse.accepted = false;
        }

        onReleased: {
            pressed = false;
        }
    }

    //BEGIN states
    states: [
        State {
            name: "left"
            when: (plasmoid.location === PlasmaCore.Types.LeftEdge)

            AnchorChanges {
                target: appletFlow
                anchors{ top:undefined; bottom:undefined; left:parent.left; right:undefined;}
            }
        },
        State {
            name: "right"
            when: (plasmoid.location === PlasmaCore.Types.RightEdge)

            AnchorChanges {
                target: appletFlow
                anchors{ top:undefined; bottom:undefined; left:undefined; right:parent.right;}
            }
        },
        State {
            name: "bottom"
            when: (plasmoid.location === PlasmaCore.Types.BottomEdge)

            AnchorChanges {
                target: appletFlow
                anchors{ top:undefined; bottom:parent.bottom; left:undefined; right:undefined;}
            }
        },
        State {
            name: "top"
            when: (plasmoid.location === PlasmaCore.Types.TopEdge)

            AnchorChanges {
                target: appletFlow
                anchors{ top:parent.top; bottom:undefined; left:undefined; right:undefined;}
            }
        }
    ]
    //END states


    //BEGIN animations
    ///////Restore Zoom Animation/////
    ParallelAnimation{
        id: restoreAnimation

        PropertyAnimation {
            target: wrapper
            property: "zoomScale"
            to: 1
            duration: 3 * container.animationTime
            easing.type: Easing.Linear
        }

        PropertyAnimation {
            target: hiddenSpacerLeft
            property: "nScale"
            to: 0
            duration: 3 * container.animationTime
            easing.type: Easing.Linear
        }

        PropertyAnimation {
            target: hiddenSpacerRight
            property: "nScale"
            to: 0
            duration: 3 * container.animationTime
            easing.type: Easing.Linear
        }
    }


    /////Clicked Animation/////
    SequentialAnimation{
        id: clickedAnimation
        alwaysRunToEnd: true
        running: appletMouseArea.pressed && (root.durationTime > 0)

        onStopped: appletMouseArea.pressed = false;

        ParallelAnimation{
            PropertyAnimation {
                target: wrapper.clickedEffect
                property: "brightness"
                to: -0.35
                duration: units.longDuration
                easing.type: Easing.OutQuad
            }
        }
        ParallelAnimation{
            PropertyAnimation {
                target: wrapper.clickedEffect
                property: "brightness"
                to: 0
                duration: units.longDuration
                easing.type: Easing.OutQuad
            }
        }
    }
    //END animations
}
