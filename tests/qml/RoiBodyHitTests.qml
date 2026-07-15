// SPDX-FileCopyrightText: Copyright (c) 2024 Refeyn Ltd and other QuickGraphLib contributors
// SPDX-License-Identifier: MIT

import QtQuick
import QuickGraphLib.GraphItems as QGLGraphItems
import QuickGraphLib.PreFabs as QGLPreFabs

QGLPreFabs.XYAxes {
    id: axes

    property bool completedSuccessfully: false
    property string failureMessage: ""

    height: 600
    viewRect: Qt.rect(0, 0, 10, 10)
    width: 800

    Component.onCompleted: {
        function assertPointClose(actual, expected, message) {
            if (Math.abs(actual.x - expected.x) > 0.001 || Math.abs(actual.y - expected.y) > 0.001) {
                throw new Error(message + ": expected " + expected + ", got " + actual);
            }
        }
        function assertBodyOrigin(roi, expected, message) {
            assertPointClose(roi.bodyScenePoint(Qt.point(0, 0)), expected, message);
        }
        function assertBodyLocalHit(roi, scenePoint, expected, message) {
            let origin = roi.bodyScenePoint(Qt.point(0, 0));
            let localPoint = Qt.point(scenePoint.x - origin.x, scenePoint.y - origin.y);
            if (roi.containsBodyPoint(localPoint) !== expected) {
                throw new Error(message);
            }
        }
        function assertBounds(roi, left, top, right, bottom, message) {
            if (roi.mappedLeft !== left || roi.mappedTop !== top || roi.mappedRight !== right || roi.mappedBottom !== bottom) {
                throw new Error(message);
            }
        }

        try {
            let lineDx = Math.abs(lineRoi.mappedPoint2.x - lineRoi.mappedPoint1.x);
            let lineDy = Math.abs(lineRoi.mappedPoint2.y - lineRoi.mappedPoint1.y);
            assertBodyOrigin(lineRoi, Qt.point(Math.min(lineRoi.mappedPoint1.x, lineRoi.mappedPoint2.x) - (Math.max(lineDx, lineRoi.hitWidth) - lineDx) / 2, Math.min(lineRoi.mappedPoint1.y, lineRoi.mappedPoint2.y) - (Math.max(lineDy, lineRoi.hitWidth) - lineDy) / 2), "line body local origin mismatch");
            assertBodyOrigin(polylineRoi, Qt.point(polylineRoi.mappedLeft - (Math.max(polylineRoi.mappedRight - polylineRoi.mappedLeft, polylineRoi.hitWidth) - (polylineRoi.mappedRight - polylineRoi.mappedLeft)) / 2, polylineRoi.mappedTop - (Math.max(polylineRoi.mappedBottom - polylineRoi.mappedTop, polylineRoi.hitWidth) - (polylineRoi.mappedBottom - polylineRoi.mappedTop)) / 2), "polyline body local origin mismatch");
            assertBodyOrigin(polygonRoi, Qt.point(polygonRoi.mappedLeft - polygonRoi.hitPadding, polygonRoi.mappedTop - polygonRoi.hitPadding), "polygon body local origin mismatch");
            assertBodyOrigin(ellipseRoi, Qt.point(Math.min(ellipseRoi.mappedLeftHandle.x, ellipseRoi.mappedRightHandle.x), Math.min(ellipseRoi.mappedTopHandle.y, ellipseRoi.mappedBottomHandle.y)), "ellipse body local origin mismatch");
            assertBodyOrigin(rectangleRoi, Qt.point(Math.min(rectangleRoi.mappedTopLeft.x, rectangleRoi.mappedTopRight.x, rectangleRoi.mappedBottomLeft.x, rectangleRoi.mappedBottomRight.x), Math.min(rectangleRoi.mappedTopLeft.y, rectangleRoi.mappedTopRight.y, rectangleRoi.mappedBottomLeft.y, rectangleRoi.mappedBottomRight.y)), "rectangle body local origin mismatch");

            let expectedPolygonPoints = polygonRoi.points.map(point => axes.dataTransform.map(point));
            if (polygonRoi.mappedPoints.length !== expectedPolygonPoints.length) {
                throw new Error("polygon mapped point count mismatch");
            }
            for (let index = 0; index < expectedPolygonPoints.length; ++index) {
                assertPointClose(polygonRoi.mappedPoints[index], expectedPolygonPoints[index], "polygon mapped point mismatch at index " + index);
                assertPointClose(polygonRoi.handles[index].mappedPosition, expectedPolygonPoints[index], "polygon handle position mismatch at index " + index);
            }
            let polygonMappedXs = polygonRoi.mappedPoints.map(point => point.x);
            let polygonMappedYs = polygonRoi.mappedPoints.map(point => point.y);
            if (polygonRoi.mappedLeft !== Math.min(...polygonMappedXs) || polygonRoi.mappedRight !== Math.max(...polygonMappedXs) || polygonRoi.mappedTop !== Math.min(...polygonMappedYs) || polygonRoi.mappedBottom !== Math.max(...polygonMappedYs)) {
                throw new Error("polygon mapped bounds mismatch");
            }
            assertBounds(emptyPolygonRoi, 0, 0, 0, 0, "empty polygon mapped bounds mismatch");
            let singleMappedPoint = axes.dataTransform.map(singlePointPolygonRoi.points[0]);
            assertBounds(singlePointPolygonRoi, singleMappedPoint.x, singleMappedPoint.y, singleMappedPoint.x, singleMappedPoint.y, "single-point polygon mapped bounds mismatch");
            assertPointClose(singlePointPolygonRoi.handles[0].mappedPosition, singleMappedPoint, "single-point polygon handle position mismatch");

            if (!lineRoi.containsBodyScenePoint(axes.dataTransform.map(Qt.point(5, 5)))) {
                throw new Error("line inside point missed");
            }
            if (lineRoi.containsBodyScenePoint(axes.dataTransform.map(Qt.point(2, 8)))) {
                throw new Error("line bounding-box point outside segment hit");
            }
            assertBodyLocalHit(lineRoi, axes.dataTransform.map(Qt.point(5, 5)), true, "line local inside point missed");
            assertBodyLocalHit(lineRoi, axes.dataTransform.map(Qt.point(2, 8)), false, "line local outside point hit");

            if (!polylineRoi.containsBodyScenePoint(axes.dataTransform.map(Qt.point(5, 5)))) {
                throw new Error("polyline inside point missed");
            }
            if (polylineRoi.containsBodyScenePoint(axes.dataTransform.map(Qt.point(5, 2)))) {
                throw new Error("polyline bounding-box point outside segments hit");
            }
            assertBodyLocalHit(polylineRoi, axes.dataTransform.map(Qt.point(5, 5)), true, "polyline local inside point missed");
            assertBodyLocalHit(polylineRoi, axes.dataTransform.map(Qt.point(5, 2)), false, "polyline local outside point hit");

            if (!polygonRoi.containsBodyScenePoint(axes.dataTransform.map(Qt.point(5, 3)))) {
                throw new Error("polygon inside point missed");
            }
            if (polygonRoi.containsBodyScenePoint(axes.dataTransform.map(Qt.point(5, 0.5)))) {
                throw new Error("polygon bounding-box point outside polygon hit");
            }
            assertBodyLocalHit(polygonRoi, axes.dataTransform.map(Qt.point(5, 3)), true, "polygon local inside point missed");
            assertBodyLocalHit(polygonRoi, axes.dataTransform.map(Qt.point(5, 0.5)), false, "polygon local outside point hit");

            if (!ellipseRoi.containsBodyScenePoint(axes.dataTransform.map(Qt.point(5, 4)))) {
                throw new Error("ellipse inside point missed");
            }
            if (ellipseRoi.containsBodyScenePoint(axes.dataTransform.map(Qt.point(2.2, 2.2)))) {
                throw new Error("ellipse bounding-box corner outside ellipse hit");
            }
            assertBodyLocalHit(ellipseRoi, axes.dataTransform.map(Qt.point(5, 4)), true, "ellipse local inside point missed");
            assertBodyLocalHit(ellipseRoi, axes.dataTransform.map(Qt.point(2.2, 2.2)), false, "ellipse local outside point hit");

            if (!rectangleRoi.containsBodyScenePoint(axes.dataTransform.map(Qt.point(5, 4)))) {
                throw new Error("rectangle inside point missed");
            }
            if (rectangleRoi.containsBodyScenePoint(axes.dataTransform.map(Qt.point(1, 4)))) {
                throw new Error("rectangle outside point hit");
            }
            assertBodyLocalHit(rectangleRoi, axes.dataTransform.map(Qt.point(5, 4)), true, "rectangle local inside point missed");
            assertBodyLocalHit(rectangleRoi, axes.dataTransform.map(Qt.point(1, 4)), false, "rectangle local outside point hit");
            completedSuccessfully = true;
        } catch (error) {
            failureMessage = error.toString();
        }
    }

    QGLGraphItems.LineSegmentHandles {
        id: lineRoi

        dataTransform: axes.dataTransform
        point1: Qt.point(1, 1)
        point2: Qt.point(9, 9)
        selected: true
    }
    QGLGraphItems.PolylineHandles {
        id: polylineRoi

        dataTransform: axes.dataTransform
        points: [Qt.point(1, 1), Qt.point(5, 5), Qt.point(9, 1)]
        selected: true
    }
    QGLGraphItems.PolygonHandles {
        id: polygonRoi

        dataTransform: axes.dataTransform
        points: [Qt.point(1, 1), Qt.point(5, 5), Qt.point(9, 1)]
        selected: true
    }
    QGLGraphItems.PolygonHandles {
        id: emptyPolygonRoi

        dataTransform: axes.dataTransform
        points: []
        selected: true
    }
    QGLGraphItems.PolygonHandles {
        id: singlePointPolygonRoi

        dataTransform: axes.dataTransform
        points: [Qt.point(3, 7)]
        selected: true
    }
    QGLGraphItems.EllipseHandles {
        id: ellipseRoi

        dataRect: Qt.rect(2, 2, 6, 4)
        dataTransform: axes.dataTransform
        selected: true
    }
    QGLGraphItems.RectangleHandles {
        id: rectangleRoi

        dataRect: Qt.rect(2, 2, 6, 4)
        dataTransform: axes.dataTransform
        selected: true
    }
}
