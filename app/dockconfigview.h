/*
*  Copyright 2016  Smith AR <audoban@openmailbox.org>
*
*  This file is part of Candil-Dock
*
*  Candil-Dock is free software; you can redistribute it and/or
*  modify it under the terms of the GNU General Public License as
*  published by the Free Software Foundation; either version 3 of
*  the License, or (at your option) any later version.
*
*  Candil-Dock is distributed in the hope that it will be useful,
*  but WITHOUT ANY WARRANTY; without even the implied warranty of
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*  GNU General Public License for more details.
*
*  You should have received a copy of the GNU General Public License
*  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#ifndef NOWDOCKCONFIGVIEW_H
#define NOWDOCKCONFIGVIEW_H

#include "plasmaquick/configview.h"
#include <plasma/package.h>

#include <QObject>
#include <QWindow>
#include <QPointer>
#include <QTimer>

namespace Plasma {
class Applet;
class Containment;
class Types;
}

namespace Latte {

class DockView;

class DockConfigView : public PlasmaQuick::ConfigView {
    Q_OBJECT
    
public:
    DockConfigView(Plasma::Containment *containment, DockView *dockView, QWindow *parent = nullptr);
    ~DockConfigView() override;
    
    void init() override;
    Qt::WindowFlags wFlags() const;
    
protected:
    void showEvent(QShowEvent *ev) override;
    void hideEvent(QHideEvent *ev) override;
    void focusOutEvent(QFocusEvent *ev) override;
    
    void syncGeometry();
    void syncSlideEffect();
    
private slots:
    void immutabilityChanged(Plasma::Types::ImmutabilityType type);
    void configurationShown(PlasmaQuick::ConfigView *configView);
    
private:
    Plasma::Containment *m_containment{nullptr};
    QPointer<DockView> m_dockView;
    QTimer m_deleterTimer;
    QTimer m_screenSyncTimer;
    
};

}
#endif //DOCKCONFIGVIEW_H
// kate: indent-mode cstyle; indent-width 4; replace-tabs on;