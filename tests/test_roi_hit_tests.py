# SPDX-FileCopyrightText: Copyright (c) 2024 Refeyn Ltd and other QuickGraphLib contributors
# SPDX-License-Identifier: MIT

from pathlib import Path

from PySide6 import QtCore, QtGui, QtQml, QtQuick, QtTest

import QuickGraphLib


_QML_TEST_DIR = Path(__file__).with_name("qml")


def _run_qml_test(filename: str, interaction=None) -> None:
    QtQuick.QQuickWindow.setGraphicsApi(
        QtQuick.QSGRendererInterface.GraphicsApi.Software
    )
    app = QtGui.QGuiApplication.instance() or QtGui.QGuiApplication(
        ["", "-platform", "offscreen"]
    )
    engine = QtQml.QQmlEngine()
    engine.addImportPath(QuickGraphLib.QML_IMPORT_PATH)

    component = QtQml.QQmlComponent(
        engine, QtCore.QUrl.fromLocalFile(_QML_TEST_DIR / filename)
    )
    item = component.create()
    assert item is not None, [error.toString() for error in component.errors()]

    try:
        app.processEvents()
        if interaction is not None:
            interaction(item, app)
        assert item.property("completedSuccessfully"), item.property("failureMessage")
    finally:
        item.deleteLater()
        app.processEvents()


def test_non_rectangular_roi_body_hit_tests() -> None:
    _run_qml_test("RoiBodyHitTests.qml")


def test_axis_aligned_roi_resize_handles_clamp_at_opposite_anchor() -> None:
    _run_qml_test("RoiResizeHandleTests.qml")


def test_roi_handles_expose_role_specific_cursors() -> None:
    _run_qml_test("RoiHandleCursorTests.qml")


def test_graph_handle_stacking_default_and_override() -> None:
    def click_overlapping_handle(item, app) -> None:
        window = QtQuick.QQuickWindow()
        window.resize(100, 100)
        item.setParentItem(window.contentItem())
        window.show()
        app.processEvents()

        try:
            QtTest.QTest.mouseClick(
                window,
                QtCore.Qt.MouseButton.LeftButton,
                QtCore.Qt.KeyboardModifier.NoModifier,
                QtCore.QPoint(25, 25),
            )
            app.processEvents()
            assert item.property("handleClickCount") == 1
            assert item.property("bodyPressCount") == 0
        finally:
            item.setParentItem(None)
            window.close()

    _run_qml_test("GraphHandleStackingTests.qml", click_overlapping_handle)


def test_ellipse_geometry_across_data_rects_and_transforms() -> None:
    _run_qml_test("EllipseGeometryTests.qml")
