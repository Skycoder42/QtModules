TARGET = %{QtModuleName}

QT = core

PUBLIC_HEADERS += \
	%{GlobalHeaderName}

PRIVATE_HEADERS += 

SOURCES += 

HEADERS += $$PUBLIC_HEADERS $$PRIVATE_HEADERS

load(qt_module)
