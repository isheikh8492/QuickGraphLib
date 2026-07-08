// SPDX-FileCopyrightText: Copyright (c) 2024 Refeyn Ltd and other QuickGraphLib contributors
// SPDX-License-Identifier: MIT

import QtQuick
import "RoiHitTest.js" as RoiHitTest

/*!
    \qmltype RectangleHandles
    \inqmlmodule QuickGraphLib.GraphItems
    \inherits QtQuick::Item
    \brief Interaction overlay for a rectangular region of interest.

    RectangleHandles provides selection, body dragging and optional corner handles for a rectangle.
    It does not own the rectangle data; instead it emits movement and resize signals so
    applications can update their own model.
*/

BaseHandles {
    id: root

    enum HandleMode {
        NoHandles,
        Corners,
        CornersAndCenter
    }

    property point _lastDragPoint: Qt.point(0, 0)
    /*!
        A direct reference to the bottom-left corner resize handle.
    */
    readonly property alias bottomLeftHandle: bottomLeftGraphHandle
    readonly property point bottomLeftPoint: Qt.point(dataLeft, dataBottom)
    /*!
        A direct reference to the bottom-right corner resize handle.
    */
    readonly property alias bottomRightHandle: bottomRightGraphHandle
    readonly property point bottomRightPoint: Qt.point(dataRight, dataBottom)
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
    /*!
        Optional visual delegate used for corner resize handles.

        The delegate can read the handle state through \c parent.handle.
    */
    property Component cornerHandleDelegate: null
    /*!
        The default shape used for corner resize handles.
    */
    property int cornerHandleShape: GraphHandle.Square
    /*!
        Whether corner handles can resize the rectangle.
    */
    property bool cornerHandlesMovable: true
    readonly property real dataBottom: Math.max(dataRect.y, dataRect.y + dataRect.height)
    readonly property real dataLeft: Math.min(dataRect.x, dataRect.x + dataRect.width)
    /*!
        The rectangle in data coordinates.
    */
    required property rect dataRect
    readonly property real dataRight: Math.max(dataRect.x, dataRect.x + dataRect.width)
    readonly property real dataTop: Math.min(dataRect.y, dataRect.y + dataRect.height)

    /*!
        Which handles should be shown.
    */
    property int handleMode: RectangleHandles.Corners
    /*!
        The visual size and hit target size of corner handles.
    */
    property real handleSize: 8
    readonly property var handles: [topLeftGraphHandle, topRightGraphHandle, bottomLeftGraphHandle, bottomRightGraphHandle, centerGraphHandle]
    readonly property point mappedBottomLeft: dataTransform.map(bottomLeftPoint)
    readonly property point mappedBottomRight: dataTransform.map(bottomRightPoint)
    readonly property point mappedTopLeft: dataTransform.map(topLeftPoint)
    readonly property point mappedTopRight: dataTransform.map(topRightPoint)
    /*!
        The minimum height emitted when resize handles are dragged toward the opposite anchor.
    */
    property real minimumDataHeight: 0
    /*!
        The minimum width emitted when resize handles are dragged toward the opposite anchor.
    */
    property real minimumDataWidth: 0
    /*!
        Whether dragging the rectangle body should emit movement signals.
    */
    property bool movable: true
    /*!
        A direct reference to the top-left corner resize handle.
    */
    readonly property alias topLeftHandle: topLeftGraphHandle
    readonly property point topLeftPoint: Qt.point(dataLeft, dataTop)
    /*!
        A direct reference to the top-right corner resize handle.
    */
    readonly property alias topRightHandle: topRightGraphHandle
    readonly property point topRightPoint: Qt.point(dataRight, dataTop)

    /*!
        Emitted when the rectangle body has moved by \a delta in data coordinates.
    */
    signal moved(point delta)
    /*!
        Emitted when a corner handle has resized the rectangle to \a dataRect.
    */
    signal resized(rect dataRect)

    function bodyScenePoint(localPoint) {
        return root.mapFromItem(bodyMouseArea, localPoint);
    }
    function clampedResizePoint(position, anchor, xSign, ySign) {
        let minimumWidth = Math.max(0, root.minimumDataWidth);
        let minimumHeight = Math.max(0, root.minimumDataHeight);
        return Qt.point(xSign < 0 ? Math.min(position.x, anchor.x - minimumWidth) : Math.max(position.x, anchor.x + minimumWidth), ySign < 0 ? Math.min(position.y, anchor.y - minimumHeight) : Math.max(position.y, anchor.y + minimumHeight));
    }
    function containsBodyPoint(localPoint) {
        return containsBodyScenePoint(bodyScenePoint(localPoint));
    }
    function containsBodyScenePoint(scenePoint) {
        return RoiHitTest.isInsidePolygon(scenePoint, [mappedTopLeft, mappedTopRight, mappedBottomRight, mappedBottomLeft]);
    }
    function normalizedRect(point1, point2) {
        let left = Math.min(point1.x, point2.x);
        let right = Math.max(point1.x, point2.x);
        let top = Math.min(point1.y, point2.y);
        let bottom = Math.max(point1.y, point2.y);
        return Qt.rect(left, top, right - left, bottom - top);
    }
    function resizedFromHandle(handle, position) {
        if (handle.name === "topLeft") {
            return root.normalizedRect(root.clampedResizePoint(position, root.bottomRightPoint, -1, -1), root.bottomRightPoint);
        }
        if (handle.name === "topRight") {
            return root.normalizedRect(root.clampedResizePoint(position, root.bottomLeftPoint, 1, -1), root.bottomLeftPoint);
        }
        if (handle.name === "bottomLeft") {
            return root.normalizedRect(root.clampedResizePoint(position, root.topRightPoint, -1, 1), root.topRightPoint);
        }
        if (handle.name === "bottomRight") {
            return root.normalizedRect(root.clampedResizePoint(position, root.topLeftPoint, 1, 1), root.topLeftPoint);
        }
        return root.dataRect;
    }

    height: parent ? parent.height : 0
    width: parent ? parent.width : 0
    x: 0
    y: 0

    MouseArea {
        id: bodyMouseArea

        property real bodyBottom: Math.max(root.mappedTopLeft.y, root.mappedTopRight.y, root.mappedBottomLeft.y, root.mappedBottomRight.y)
        property real bodyLeft: Math.min(root.mappedTopLeft.x, root.mappedTopRight.x, root.mappedBottomLeft.x, root.mappedBottomRight.x)
        property real bodyRight: Math.max(root.mappedTopLeft.x, root.mappedTopRight.x, root.mappedBottomLeft.x, root.mappedBottomRight.x)
        property real bodyTop: Math.min(root.mappedTopLeft.y, root.mappedTopRight.y, root.mappedBottomLeft.y, root.mappedBottomRight.y)

        cursorShape: root.movable ? Qt.SizeAllCursor : Qt.ArrowCursor
        enabled: root.clickable || root.movable
        height: bodyBottom - bodyTop
        hoverEnabled: true
        width: bodyRight - bodyLeft
        x: bodyLeft
        y: bodyTop

        onPositionChanged: event => {
            if (!pressed || !root.movable)
                return;
            let currentPoint = root.dataTransform.inverted().map(root.mapFromItem(bodyMouseArea, Qt.point(event.x, event.y)));
            let delta = Qt.point(currentPoint.x - root._lastDragPoint.x, currentPoint.y - root._lastDragPoint.y);
            root._lastDragPoint = currentPoint;
            root.moved(delta);
        }
        onPressed: event => {
            if (root.clickable)
                root.clicked();
            root._lastDragPoint = root.dataTransform.inverted().map(root.mapFromItem(bodyMouseArea, Qt.point(event.x, event.y)));
        }
    }
    GraphHandle {
        id: topLeftGraphHandle

        clickable: root.clickable
        cursorShape: Qt.SizeBDiagCursor
        dataTransform: root.dataTransform
        delegate: root.cornerHandleDelegate
        fillColor: root.handleFillColor
        hoverFillColor: root.handleHoverFillColor
        movable: root.cornerHandlesMovable
        name: "topLeft"
        position: root.topLeftPoint
        role: GraphHandle.Resize
        selected: root.selected
        selectedFillColor: root.handleSelectedFillColor
        shape: root.cornerHandleShape
        size: root.handleSize
        strokeColor: root.handleStrokeColor
        strokeWidth: root.handleStrokeWidth
        visible: root.handlesVisible && root.handleMode !== RectangleHandles.NoHandles
        z: 10

        onClicked: root.clicked()
        onMoved: position => {
            root.handleMoved(topLeftGraphHandle, position);
            root.resized(root.resizedFromHandle(topLeftGraphHandle, position));
        }
    }
    GraphHandle {
        id: topRightGraphHandle

        clickable: root.clickable
        cursorShape: Qt.SizeFDiagCursor
        dataTransform: root.dataTransform
        delegate: root.cornerHandleDelegate
        fillColor: root.handleFillColor
        hoverFillColor: root.handleHoverFillColor
        movable: root.cornerHandlesMovable
        name: "topRight"
        position: root.topRightPoint
        role: GraphHandle.Resize
        selected: root.selected
        selectedFillColor: root.handleSelectedFillColor
        shape: root.cornerHandleShape
        size: root.handleSize
        strokeColor: root.handleStrokeColor
        strokeWidth: root.handleStrokeWidth
        visible: root.handlesVisible && root.handleMode !== RectangleHandles.NoHandles
        z: 10

        onClicked: root.clicked()
        onMoved: position => {
            root.handleMoved(topRightGraphHandle, position);
            root.resized(root.resizedFromHandle(topRightGraphHandle, position));
        }
    }
    GraphHandle {
        id: bottomLeftGraphHandle

        clickable: root.clickable
        cursorShape: Qt.SizeFDiagCursor
        dataTransform: root.dataTransform
        delegate: root.cornerHandleDelegate
        fillColor: root.handleFillColor
        hoverFillColor: root.handleHoverFillColor
        movable: root.cornerHandlesMovable
        name: "bottomLeft"
        position: root.bottomLeftPoint
        role: GraphHandle.Resize
        selected: root.selected
        selectedFillColor: root.handleSelectedFillColor
        shape: root.cornerHandleShape
        size: root.handleSize
        strokeColor: root.handleStrokeColor
        strokeWidth: root.handleStrokeWidth
        visible: root.handlesVisible && root.handleMode !== RectangleHandles.NoHandles
        z: 10

        onClicked: root.clicked()
        onMoved: position => {
            root.handleMoved(bottomLeftGraphHandle, position);
            root.resized(root.resizedFromHandle(bottomLeftGraphHandle, position));
        }
    }
    GraphHandle {
        id: bottomRightGraphHandle

        clickable: root.clickable
        cursorShape: Qt.SizeBDiagCursor
        dataTransform: root.dataTransform
        delegate: root.cornerHandleDelegate
        fillColor: root.handleFillColor
        hoverFillColor: root.handleHoverFillColor
        movable: root.cornerHandlesMovable
        name: "bottomRight"
        position: root.bottomRightPoint
        role: GraphHandle.Resize
        selected: root.selected
        selectedFillColor: root.handleSelectedFillColor
        shape: root.cornerHandleShape
        size: root.handleSize
        strokeColor: root.handleStrokeColor
        strokeWidth: root.handleStrokeWidth
        visible: root.handlesVisible && root.handleMode !== RectangleHandles.NoHandles
        z: 10

        onClicked: root.clicked()
        onMoved: position => {
            root.handleMoved(bottomRightGraphHandle, position);
            root.resized(root.resizedFromHandle(bottomRightGraphHandle, position));
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
        visible: root.handlesVisible && root.handleMode === RectangleHandles.CornersAndCenter
        z: 10

        onClicked: root.clicked()
        onMoved: position => {
            root.handleMoved(centerGraphHandle, position);
            root.moved(Qt.point(position.x - centerGraphHandle.position.x, position.y - centerGraphHandle.position.y));
        }
    }
}
