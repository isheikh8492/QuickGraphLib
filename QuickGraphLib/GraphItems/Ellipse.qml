// SPDX-FileCopyrightText: Copyright (c) 2024 Refeyn Ltd and other QuickGraphLib contributors
// SPDX-License-Identifier: MIT

import QtQuick
import QtQuick.Shapes as QQS
import QuickGraphLib as QuickGraphLib

/*!
    \qmltype Ellipse
    \inqmlmodule QuickGraphLib.GraphItems
    \inherits QtQuick::Shapes::ShapePath
    \brief Displays an ellipse in data coordinates.

    Draws an ellipse from a bounding Qt rect in data coordinates. The style can be adjusted using the
    \l {ShapePath::fillColor} {fillColor}, \l {ShapePath::strokeColor} {strokeColor} and
    \l {ShapePath::strokeWidth} {strokeWidth} properties.
*/

QQS.ShapePath {
    id: root

    readonly property rect _mappedRect: dataTransform.mapRect(_normalizedDataRect)
    readonly property rect _normalizedDataRect: QuickGraphLib.Helpers.normalizedRect(dataRect)
    readonly property real dataBottom: _normalizedDataRect.bottom
    readonly property point dataCenter: Qt.point((_normalizedDataRect.left + _normalizedDataRect.right) / 2, (_normalizedDataRect.top + _normalizedDataRect.bottom) / 2)
    readonly property real dataLeft: _normalizedDataRect.left
    /*!
        The ellipse bounding rectangle in data coordinates.
    */
    required property rect dataRect
    readonly property real dataRight: _normalizedDataRect.right
    readonly property point dataRightCenter: Qt.point(dataRight, dataCenter.y)
    readonly property real dataTop: _normalizedDataRect.top
    readonly property point dataTopCenter: Qt.point(dataCenter.x, dataTop)

    /*!
        Must be assigned the data transform of the graph area this ellipse is paired to.

        \sa GraphArea::dataTransform
    */
    required property matrix4x4 dataTransform
    readonly property point mappedCenter: dataTransform.map(dataCenter)
    readonly property point mappedRightCenter: dataTransform.map(dataRightCenter)
    readonly property point mappedTopCenter: dataTransform.map(dataTopCenter)
    readonly property real radiusX: _mappedRect.width / 2
    readonly property real radiusY: _mappedRect.height / 2

    fillColor: "transparent"
    pathHints: QQS.ShapePath.PathConvex | QQS.ShapePath.PathSolid

    PathAngleArc {
        centerX: root.mappedCenter.x
        centerY: root.mappedCenter.y
        radiusX: root.radiusX
        radiusY: root.radiusY
        startAngle: 0
        sweepAngle: 360
    }
}
