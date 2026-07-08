// SPDX-FileCopyrightText: Copyright (c) 2024 Refeyn Ltd and other QuickGraphLib contributors
// SPDX-License-Identifier: MIT

import QtQuick
import QuickGraphLib as QuickGraphLib

/*!
    \qmltype EllipseHandles
    \inqmlmodule QuickGraphLib.GraphItems
    \inherits QtQuick::Item
    \brief Interaction overlay for an elliptical region of interest.

    EllipseHandles provides selection, body dragging and optional cardinal resize handles for an
    ellipse. It does not own the ellipse data; instead it emits movement and resize signals so
    applications can update their own model.
*/

BaseHandles {
    id: root

    enum HandleMode {
        NoHandles,
        Cardinal,
        CardinalAndCenter
    }

    property bool _bodyDragging: false
    property bool _bodyHovered: false
    property point _lastDragPoint: Qt.point(0, 0)
    /*!
        A direct reference to the bottom resize handle.
    */
    readonly property alias bottomHandle: bottomGraphHandle
    readonly property point bottomHandlePoint: Qt.point(centerPoint.x, dataBottom)
    /*!
        Optional visual delegate used for cardinal resize handles.

        The delegate can read the handle state through \c parent.handle.
    */
    property Component cardinalHandleDelegate: null
    /*!
        The default shape used for cardinal resize handles.
    */
    property int cardinalHandleShape: GraphHandle.Square
    /*!
        Whether cardinal resize handles can resize the ellipse.
    */
    property bool cardinalHandlesMovable: true
    /*!
        A direct reference to the optional center move handle.
    */
    readonly property alias centerHandle: centerGraphHandle
    /*!
        Optional visual delegate used for the center move handle.

        The delegate can read the handle state through \c parent.handle.
    */
    property Component centerHandleDelegate: null
    /*!
        The default shape used for the center move handle.
    */
    property int centerHandleShape: GraphHandle.Circle
    /*!
        The visual size and hit target size of the center handle.
    */
    property real centerHandleSize: handleSize
    readonly property point centerPoint: Qt.point((dataLeft + dataRight) / 2, (dataTop + dataBottom) / 2)
    readonly property real dataBottom: Math.max(dataRect.y, dataRect.y + dataRect.height)
    readonly property real dataLeft: Math.min(dataRect.x, dataRect.x + dataRect.width)
    /*!
        The ellipse bounding rectangle in data coordinates.
    */
    required property rect dataRect
    readonly property real dataRight: Math.max(dataRect.x, dataRect.x + dataRect.width)
    readonly property real dataTop: Math.min(dataRect.y, dataRect.y + dataRect.height)

    /*!
        Which built-in handles should be shown.
    */
    property int handleMode: EllipseHandles.Cardinal
    /*!
        The visual size and hit target size of cardinal resize handles.
    */
    property real handleSize: 8
    readonly property var handles: [leftGraphHandle, rightGraphHandle, topGraphHandle, bottomGraphHandle, centerGraphHandle]

    /*!
        A direct reference to the left resize handle.
    */
    readonly property alias leftHandle: leftGraphHandle
    readonly property point leftHandlePoint: Qt.point(dataLeft, centerPoint.y)
    readonly property point mappedBottomHandle: dataTransform.map(bottomHandlePoint)
    readonly property point mappedCenter: dataTransform.map(centerPoint)
    readonly property point mappedLeftHandle: dataTransform.map(leftHandlePoint)
    readonly property point mappedRightHandle: dataTransform.map(rightHandlePoint)
    readonly property point mappedTopHandle: dataTransform.map(topHandlePoint)
    /*!
        The minimum height emitted when resize handles are dragged toward the opposite edge.
    */
    property real minimumDataHeight: 0
    /*!
        The minimum width emitted when resize handles are dragged toward the opposite edge.
    */
    property real minimumDataWidth: 0
    /*!
        Whether dragging the ellipse body should emit movement signals.
    */
    property bool movable: true
    /*!
        A direct reference to the right resize handle.
    */
    readonly property alias rightHandle: rightGraphHandle
    readonly property point rightHandlePoint: Qt.point(dataRight, centerPoint.y)
    /*!
        A direct reference to the top resize handle.
    */
    readonly property alias topHandle: topGraphHandle
    readonly property point topHandlePoint: Qt.point(centerPoint.x, dataTop)

    /*!
        Emitted when the ellipse body has moved by \a delta in data coordinates.
    */
    signal moved(point delta)
    /*!
        Emitted when a handle has resized the ellipse to \a dataRect.
    */
    signal resized(rect dataRect)

    function bodyScenePoint(localPoint) {
        return root.mapFromItem(bodyMouseArea, localPoint);
    }
    function containsBodyPoint(localPoint) {
        return containsBodyScenePoint(bodyScenePoint(localPoint));
    }
    function containsBodyScenePoint(scenePoint) {
        let radiusX = Math.abs(root.mappedRightHandle.x - root.mappedCenter.x);
        let radiusY = Math.abs(root.mappedTopHandle.y - root.mappedCenter.y);
        return QuickGraphLib.Helpers.isInsideEllipse(scenePoint, root.mappedCenter, radiusX, radiusY);
    }
    function normalizedRect(left, top, right, bottom) {
        let normalizedLeft = Math.min(left, right);
        let normalizedRight = Math.max(left, right);
        let normalizedTop = Math.min(top, bottom);
        let normalizedBottom = Math.max(top, bottom);
        return Qt.rect(normalizedLeft, normalizedTop, normalizedRight - normalizedLeft, normalizedBottom - normalizedTop);
    }
    function resizedFromHandle(handle, position) {
        let minimumWidth = Math.max(0, root.minimumDataWidth);
        let minimumHeight = Math.max(0, root.minimumDataHeight);
        if (handle.name === "left") {
            return normalizedRect(Math.min(position.x, root.dataRight - minimumWidth), root.dataTop, root.dataRight, root.dataBottom);
        }
        if (handle.name === "right") {
            return normalizedRect(root.dataLeft, root.dataTop, Math.max(position.x, root.dataLeft + minimumWidth), root.dataBottom);
        }
        if (handle.name === "top") {
            return normalizedRect(root.dataLeft, Math.min(position.y, root.dataBottom - minimumHeight), root.dataRight, root.dataBottom);
        }
        if (handle.name === "bottom") {
            return normalizedRect(root.dataLeft, root.dataTop, root.dataRight, Math.max(position.y, root.dataTop + minimumHeight));
        }
        return root.dataRect;
    }

    height: parent ? parent.height : 0
    width: parent ? parent.width : 0
    x: 0
    y: 0

    MouseArea {
        id: bodyMouseArea

        property real bodyBottom: Math.max(root.mappedTopHandle.y, root.mappedBottomHandle.y)
        property real bodyLeft: Math.min(root.mappedLeftHandle.x, root.mappedRightHandle.x)
        property real bodyRight: Math.max(root.mappedLeftHandle.x, root.mappedRightHandle.x)
        property real bodyTop: Math.min(root.mappedTopHandle.y, root.mappedBottomHandle.y)

        cursorShape: root.movable && (root._bodyHovered || root._bodyDragging) ? Qt.SizeAllCursor : Qt.ArrowCursor
        enabled: root.clickable || root.movable
        height: bodyBottom - bodyTop
        hoverEnabled: true
        width: bodyRight - bodyLeft
        x: bodyLeft
        y: bodyTop

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
            if (root.clickable)
                root.clicked();
            root._lastDragPoint = root.dataTransform.inverted().map(root.mapFromItem(bodyMouseArea, Qt.point(event.x, event.y)));
        }
        onReleased: {
            root._bodyDragging = false;
        }
    }
    GraphHandle {
        id: leftGraphHandle

        clickable: root.clickable
        cursorShape: Qt.SizeHorCursor
        dataTransform: root.dataTransform
        delegate: root.cardinalHandleDelegate
        fillColor: root.handleFillColor
        hoverFillColor: root.handleHoverFillColor
        movable: root.cardinalHandlesMovable
        name: "left"
        position: root.leftHandlePoint
        role: GraphHandle.Resize
        selected: root.selected
        selectedFillColor: root.handleSelectedFillColor
        shape: root.cardinalHandleShape
        size: root.handleSize
        strokeColor: root.handleStrokeColor
        strokeWidth: root.handleStrokeWidth
        visible: root.handlesVisible && root.handleMode !== EllipseHandles.NoHandles
        z: 10

        onClicked: root.clicked()
        onMoved: position => {
            root.handleMoved(leftGraphHandle, position);
            root.resized(root.resizedFromHandle(leftGraphHandle, position));
        }
    }
    GraphHandle {
        id: rightGraphHandle

        clickable: root.clickable
        cursorShape: Qt.SizeHorCursor
        dataTransform: root.dataTransform
        delegate: root.cardinalHandleDelegate
        fillColor: root.handleFillColor
        hoverFillColor: root.handleHoverFillColor
        movable: root.cardinalHandlesMovable
        name: "right"
        position: root.rightHandlePoint
        role: GraphHandle.Resize
        selected: root.selected
        selectedFillColor: root.handleSelectedFillColor
        shape: root.cardinalHandleShape
        size: root.handleSize
        strokeColor: root.handleStrokeColor
        strokeWidth: root.handleStrokeWidth
        visible: root.handlesVisible && root.handleMode !== EllipseHandles.NoHandles
        z: 10

        onClicked: root.clicked()
        onMoved: position => {
            root.handleMoved(rightGraphHandle, position);
            root.resized(root.resizedFromHandle(rightGraphHandle, position));
        }
    }
    GraphHandle {
        id: topGraphHandle

        clickable: root.clickable
        cursorShape: Qt.SizeVerCursor
        dataTransform: root.dataTransform
        delegate: root.cardinalHandleDelegate
        fillColor: root.handleFillColor
        hoverFillColor: root.handleHoverFillColor
        movable: root.cardinalHandlesMovable
        name: "top"
        position: root.topHandlePoint
        role: GraphHandle.Resize
        selected: root.selected
        selectedFillColor: root.handleSelectedFillColor
        shape: root.cardinalHandleShape
        size: root.handleSize
        strokeColor: root.handleStrokeColor
        strokeWidth: root.handleStrokeWidth
        visible: root.handlesVisible && root.handleMode !== EllipseHandles.NoHandles
        z: 10

        onClicked: root.clicked()
        onMoved: position => {
            root.handleMoved(topGraphHandle, position);
            root.resized(root.resizedFromHandle(topGraphHandle, position));
        }
    }
    GraphHandle {
        id: bottomGraphHandle

        clickable: root.clickable
        cursorShape: Qt.SizeVerCursor
        dataTransform: root.dataTransform
        delegate: root.cardinalHandleDelegate
        fillColor: root.handleFillColor
        hoverFillColor: root.handleHoverFillColor
        movable: root.cardinalHandlesMovable
        name: "bottom"
        position: root.bottomHandlePoint
        role: GraphHandle.Resize
        selected: root.selected
        selectedFillColor: root.handleSelectedFillColor
        shape: root.cardinalHandleShape
        size: root.handleSize
        strokeColor: root.handleStrokeColor
        strokeWidth: root.handleStrokeWidth
        visible: root.handlesVisible && root.handleMode !== EllipseHandles.NoHandles
        z: 10

        onClicked: root.clicked()
        onMoved: position => {
            root.handleMoved(bottomGraphHandle, position);
            root.resized(root.resizedFromHandle(bottomGraphHandle, position));
        }
    }
    GraphHandle {
        id: centerGraphHandle

        clickable: root.clickable
        cursorShape: Qt.SizeAllCursor
        dataTransform: root.dataTransform
        delegate: root.centerHandleDelegate
        fillColor: root.handleFillColor
        hoverFillColor: root.handleHoverFillColor
        movable: root.movable
        name: "center"
        position: root.centerPoint
        role: GraphHandle.Move
        selected: root.selected
        selectedFillColor: root.handleSelectedFillColor
        shape: root.centerHandleShape
        size: root.centerHandleSize
        strokeColor: root.handleStrokeColor
        strokeWidth: root.handleStrokeWidth
        visible: root.handlesVisible && root.handleMode === EllipseHandles.CardinalAndCenter
        z: 10

        onClicked: root.clicked()
        onMoved: position => {
            root.handleMoved(centerGraphHandle, position);
            root.moved(Qt.point(position.x - centerGraphHandle.position.x, position.y - centerGraphHandle.position.y));
        }
    }
}
