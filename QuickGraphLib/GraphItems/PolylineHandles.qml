// SPDX-FileCopyrightText: Copyright (c) 2024 Refeyn Ltd and other QuickGraphLib contributors
// SPDX-License-Identifier: MIT

import QtQuick
import "RoiHitTest.js" as RoiHitTest

/*!
    \qmltype PolylineHandles
    \inqmlmodule QuickGraphLib.GraphItems
    \inherits QtQuick::Item
    \brief Interaction overlay for an open polyline region of interest.

    PolylineHandles provides selection, body dragging and vertex handles for a list of points. It does
    not own the point data; instead it emits movement signals so applications can update their own
    model.
*/

BaseHandles {
    id: root

    property bool _bodyDragging: false
    property bool _bodyHovered: false
    property point _lastDragPoint: Qt.point(0, 0)
    /*!
        The mouse hit target size of vertex handles.
    */
    property real handleHitSize: 24
    /*!
        The visual size and hit target size of vertex handles.
    */
    property real handleSize: 8
    /*!
        GraphHandle objects rendered by this item.
    */
    readonly property var handles: vertexHandleRepeater.items
    /*!
        The body hit target width in pixels.
    */
    property real hitWidth: 18
    readonly property real mappedBottom: mappedPoints.length === 0 ? 0 : Math.max(...mappedPoints.map(point => point.y))
    readonly property real mappedLeft: mappedPoints.length === 0 ? 0 : Math.min(...mappedPoints.map(point => point.x))
    readonly property var mappedPoints: points.map(point => dataTransform.map(point))
    readonly property real mappedRight: mappedPoints.length === 0 ? 0 : Math.max(...mappedPoints.map(point => point.x))
    readonly property real mappedTop: mappedPoints.length === 0 ? 0 : Math.min(...mappedPoints.map(point => point.y))
    /*!
        Whether dragging the polyline body should emit movement signals.
    */
    property bool movable: true
    /*!
        Points in data coordinates.
    */
    required property var points
    /*!
        Optional visual delegate used for vertex handles.

        The delegate can read the handle state through \c parent.handle.
    */
    property Component vertexHandleDelegate: null
    /*!
        The default shape used for vertex resize handles.
    */
    property int vertexHandleShape: GraphHandle.Circle
    /*!
        Whether vertex handles can move individual points.
    */
    property bool vertexHandlesMovable: true

    /*!
        Emitted when the polyline body has moved by \a delta in data coordinates.
    */
    signal moved(point delta)
    /*!
        Emitted when point \a index has moved to \a position in data coordinates.
    */
    signal pointMoved(int index, point position)

    function bodyScenePoint(localPoint) {
        return Qt.point(bodyMouseArea.x + localPoint.x, bodyMouseArea.y + localPoint.y);
    }
    function containsBodyPoint(localPoint) {
        return containsBodyScenePoint(bodyScenePoint(localPoint));
    }
    function containsBodyScenePoint(scenePoint) {
        return RoiHitTest.isNearPolyline(scenePoint, mappedPoints, hitWidth, false);
    }
    function handleIndex(handle) {
        return parseInt(handle.name.slice(5));
    }

    height: parent ? parent.height : 0
    width: parent ? parent.width : 0
    x: 0
    y: 0

    Repeater {
        id: vertexHandleRepeater

        readonly property var items: Array.from({
            length: count
        }, (_, index) => itemAt(index))

        model: root.points.length

        GraphHandle {
            id: vertexGraphHandle

            required property int index

            clickable: root.clickable
            cursorShape: Qt.PointingHandCursor
            dataTransform: root.dataTransform
            delegate: root.vertexHandleDelegate
            fillColor: root.handleFillColor
            hitSize: root.handleHitSize
            hoverFillColor: root.handleHoverFillColor
            movable: root.vertexHandlesMovable
            name: "point" + index
            position: root.points[index]
            role: GraphHandle.Resize
            selected: root.selected
            selectedFillColor: root.handleSelectedFillColor
            shape: root.vertexHandleShape
            size: root.handleSize
            strokeColor: root.handleStrokeColor
            strokeWidth: root.handleStrokeWidth
            visible: root.handlesVisible
            z: 10

            onClicked: root.clicked()
            onMoved: position => {
                root.handleMoved(vertexGraphHandle, position);
                root.pointMoved(index, position);
            }
        }
    }
    MouseArea {
        id: bodyMouseArea

        cursorShape: root.movable && (root._bodyHovered || root._bodyDragging) ? Qt.SizeAllCursor : Qt.ArrowCursor
        enabled: root.points.length > 0 && (root.clickable || root.movable)
        height: Math.max(root.mappedBottom - root.mappedTop, root.hitWidth)
        hoverEnabled: true
        width: Math.max(root.mappedRight - root.mappedLeft, root.hitWidth)
        x: root.mappedLeft - (width - (root.mappedRight - root.mappedLeft)) / 2
        y: root.mappedTop - (height - (root.mappedBottom - root.mappedTop)) / 2

        onCanceled: {
            root._bodyDragging = false;
        }
        onExited: {
            root._bodyHovered = false;
        }
        onPositionChanged: event => {
            root._bodyHovered = root.containsBodyPoint(Qt.point(event.x, event.y));
            if (!root._bodyDragging || !root.movable)
                return;
            let currentPoint = root.dataTransform.inverted().map(Qt.point(bodyMouseArea.x + event.x, bodyMouseArea.y + event.y));
            let delta = Qt.point(currentPoint.x - root._lastDragPoint.x, currentPoint.y - root._lastDragPoint.y);
            root._lastDragPoint = currentPoint;
            root.moved(delta);
        }
        onPressed: event => {
            if (!root.containsBodyPoint(Qt.point(event.x, event.y))) {
                root._bodyDragging = false;
                event.accepted = false;
                return;
            }
            root._bodyDragging = true;
            if (root.clickable)
                root.clicked();
            root._lastDragPoint = root.dataTransform.inverted().map(Qt.point(bodyMouseArea.x + event.x, bodyMouseArea.y + event.y));
        }
        onReleased: {
            root._bodyDragging = false;
        }
    }
}
