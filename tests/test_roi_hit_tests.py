# SPDX-FileCopyrightText: Copyright (c) 2024 Refeyn Ltd and other QuickGraphLib contributors
# SPDX-License-Identifier: MIT

from pathlib import Path

from PySide6 import QtCore, QtGui, QtQml, QtQuick

import QuickGraphLib


_QML_TEST_DIR = Path(__file__).with_name("qml")


def _run_qml_test(filename: str) -> None:
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
