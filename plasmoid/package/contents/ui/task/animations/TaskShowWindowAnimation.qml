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

import org.kde.plasma.plasmoid 2.0

import org.kde.latte 0.1 as Latte

///item's added Animation
SequentialAnimation{
    id:showWindowAnimation
    property int speed: Latte.WindowSystem.compositingActive ? root.durationTime* (1.2*units.longDuration) : 0
    property bool animationSent: false

    //Ghost animation that acts as a delayer, in order to fix #342
    PropertyAnimation {
        target: wrapper
        property: "opacity"
        to: 0
        //it is not depend to durationTime when animations are active
        duration: root.durationTime > 0 ? 750 : 0
        easing.type: Easing.InQuad
    }
    //end of ghost animation

    ScriptAction{
        script:{
            if (!showWindowAnimation.animationSent) {
                showWindowAnimation.animationSent = true;
                root.signalAnimationsNeedLength(1);
            }
        }
    }

    PropertyAnimation {
        target: wrapper
        property: (icList.orientation == Qt.Vertical) ? "tempScaleHeight" : "tempScaleWidth"
        to: 1
        duration: showWindowAnimation.speed
        easing.type: Easing.OutQuad
    }

    ParallelAnimation{

        PropertyAnimation {
            target: wrapper
            property: (icList.orientation == Qt.Vertical) ? "tempScaleWidth" : "tempScaleHeight"
            to: 1
            duration: showWindowAnimation.speed
            easing.type: Easing.OutQuad
        }


        PropertyAnimation {
            target: wrapper
            property: "opacity"
            from: 0
            to: 1
            duration: showWindowAnimation.speed
            easing.type: Easing.OutQuad
        }
    }

    onStopped: {
        mainItemContainer.inAddRemoveAnimation = false;

        if(mainItemContainer.isWindow || mainItemContainer.isStartup){
            taskInitComponent.createObject(wrapper);
            if (mainItemContainer.isDemandingAttention){
                mainItemContainer.groupWindowAdded();
            }
        }
        mainItemContainer.inAnimation = false;

        if (showWindowAnimation.animationSent) {
            root.signalAnimationsNeedLength(-1);
            showWindowAnimation.animationSent = false;
        }
    }

    function execute(){
        //Animation Add/Remove (2) - when is window with no launcher, animations enabled
        //Animation Add/Remove (3) - when is launcher with no window, animations enabled
        var animation2 = ((((tasksModel.launcherPosition(mainItemContainer.launcherUrl) == -1)
                            && (tasksModel.launcherPosition(mainItemContainer.launcherUrlWithIcon) == -1) )
                           || !launcherIsPresent(mainItemContainer.launcherUrl))
                          && mainItemContainer.isWindow);

        var animation3 = ((!root.taskExists(mainItemContainer.launcherUrl) && mainItemContainer.isLauncher));

        //startup without launcher, animation should be blocked
        var hideStartup =  ((((tasksModel.launcherPosition(mainItemContainer.launcherUrl) == -1)
                              && (tasksModel.launcherPosition(mainItemContainer.launcherUrlWithIcon) == -1) )
                             || !launcherIsPresent(mainItemContainer.launcherUrl))
                            && mainItemContainer.isStartup);

        if (( animation2 || animation3) && (root.durationTime !== 0)){
            wrapper.tempScaleWidth = 0;
            wrapper.tempScaleHeight = 0;
            start();
        } else if (hideStartup) {
            mainItemContainer.visible = false;
            wrapper.tempScaleWidth = 0;
            wrapper.tempScaleHeight = 0;
            wrapper.opacity = 0;
            mainItemContainer.inAnimation = false;
        } else {
            wrapper.tempScaleWidth = 1;
            wrapper.tempScaleHeight = 1;
            wrapper.opacity = 1;
            mainItemContainer.inAnimation = false;
        }
    }

    function showWindow(){
        execute();
    }

    Component.onDestruction: {
        if (animationSent){
            //console.log("SAFETY REMOVAL 2: animation removing ended");
            animationSent = false;
            root.signalAnimationsNeedLength(-1);
        }
    }
}
