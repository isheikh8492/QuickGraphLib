// SPDX-FileCopyrightText: Copyright (c) 2024 Refeyn Ltd and other QuickGraphLib contributors
// SPDX-License-Identifier: MIT

import QtQuick
import QuickGraphLib as QuickGraphLib

/*!
    \qmltype PolygonHandles
    \inqmlmodule QuickGraphLib.GraphItems
    \inherits QtQuick::Item
    \brief Interaction overlay for a polygon region of interest.

    PolygonHandles provides selection, body dragging and vertex handles for a closed list of points. It
    does not own the point data; instead it emits movement signals so applications can update their
    own model.
*/

BaseHandles {
    id: root

    property bool _bodyDragging: false
    property bool _bodyHovered: false
    property point _lastDragPoint: Qt.point(0, 0)
    readonly property rect _mappedRect: QuickGraphLib.Helpers.boundingRect(mappedPoints)
    /*!
        The mouse hit target size of vertex handles.
    */
    property real handleHitSize: 24
    /*!
        The visual size of vertex handles.
    */
    property real handleSize: 8
    /*!
        GraphHandle objects rendered by this item.
    */
    readonly property var handles: vertexHandleRepeater.items
    /*!
        The body hit target padding in pixels.
    */
    property real hitPadding: 8
    readonly property real mappedBottom: _mappedRect.bottom
    readonly property real mappedLeft: _mappedRect.left
    readonly property var mappedPoints: QuickGraphLib.Helpers.mapPoints(points, root.dataTransform)
    readonly property real mappedRight: _mappedRect.right
    readonly property real mappedTop: _mappedRect.top
    /*!
        Whether dragging the polygon body should emit movement signals.
    */
    property bool movable: true
    /*!
        Polygon vertices in data coordinates.
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
        Emitted when the polygon body has moved by \a delta in data coordinates.
    */
    signal moved(point delta)
    /*!
        Emitted when point \a index has moved to \a position in data coordinates.
    */
    signal pointMoved(int index, point position)

    function bodyScenePoint(localPoint) {
        return root.mapFromItem(bodyMouseArea, localPoint);
    }
    function containsBodyPoint(localPoint) {
        return containsBodyScenePoint(bodyScenePoint(localPoint));
    }
    function containsBodyScenePoint(scenePoint) {
        return QuickGraphLib.Helpers.isInsidePolygon(scenePoint, mappedPoints) || QuickGraphLib.Helpers.isNearPolyline(scenePoint, mappedPoints, hitPadding * 2, true);
    }
    function handleIndex(handle) {
        return parseInt(handle.objectName.slice(5));
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

            cursorShape: Qt.PointingHandCursor
            dataTransform: root.dataTransform
            delegate: root.vertexHandleDelegate
            fillColor: root.handleFillColor
            hitSize: root.handleHitSize
            hoverFillColor: root.handleHoverFillColor
            movable: root.vertexHandlesMovable
            objectName: "point" + index
            position: root.points[index]
            role: GraphHandle.Resize
            selected: root.selected
            selectedFillColor: root.handleSelectedFillColor
            shape: root.vertexHandleShape
            size: root.handleSize
            strokeColor: root.handleStrokeColor
            strokeWidth: root.handleStrokeWidth
            visible: root.handlesVisible

            onClicked: root.handleClicked(root.roi, root.shape, vertexGraphHandle)
            onMoved: position => {
                root.handleMoved(vertexGraphHandle, position);
                root.pointMoved(index, position);
            }
        }
    }
    MouseArea {
        id: bodyMouseArea

        cursorShape: root.movable && (root._bodyHovered || root._bodyDragging) ? Qt.SizeAllCursor : Qt.ArrowCursor
        enabled: root.points.length > 0 && root.enabled
        height: Math.max(root.mappedBottom - root.mappedTop + root.hitPadding * 2, root.hitPadding * 2)
        hoverEnabled: true
        width: Math.max(root.mappedRight - root.mappedLeft + root.hitPadding * 2, root.hitPadding * 2)
        x: root.mappedLeft - root.hitPadding
        y: root.mappedTop - root.hitPadding

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
            let currentPoint = root.dataTransform.inverted().map(root.mapFromItem(bodyMouseArea, Qt.point(event.x, event.y)));
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
            root.bodyClicked(root.roi, root.shape);
            root._lastDragPoint = root.dataTransform.inverted().map(root.mapFromItem(bodyMouseArea, Qt.point(event.x, event.y)));
        }
        onReleased: {
            root._bodyDragging = false;
        }
    }
}
