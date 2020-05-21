
-- add modes: debug and release
add_rules("mode.debug", "mode.release")

-- add target
target("qt_demo")

    -- add rules
    add_rules("qt.widgetapp")
    add_frameworks("QtCore", "QtGui", "QtWidgets", "QtQuick", "QtQuickPrivate", "QtQml", "QtQmlPrivate", "QtCorePrivate", "QtGuiPrivate")

    -- add headers
    add_headerfiles("src/*.h")

    -- add files
    add_files("src/*.cpp")
    add_files("src/mainwindow.ui")

    -- add files with Q_OBJECT meta (only for qt.moc)
    add_files("src/mainwindow.h")


