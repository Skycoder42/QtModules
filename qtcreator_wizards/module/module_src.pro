TARGET = %{QtModuleName}

QT = core

@if '%{UseQDoc}' !== ''
QMAKE_DOCS = $$PWD/doc/%{QtModuleNameLower}.qdocconf
OTHER_FILES += doc/src/*.qdoc   # show .qdoc files in Qt Creator
OTHER_FILES += doc/%{QtModuleNameLower}.qdocconf
OTHER_FILES += doc/snippets/*.cpp

@endif
HEADERS += \\
	%{GlobalHeaderName}

SOURCES +=

@if '%{Translations}' !== ''
include(./translations/translations.pri)

@endif
load(qt_module)

win32 {
	QMAKE_TARGET_PRODUCT = "%{QtModuleName}"
@if '%{CompanyName}' !== ''
	QMAKE_TARGET_COMPANY = "%{CompanyName}"
@endif
@if '%{Copyright}' !== ''
	QMAKE_TARGET_COPYRIGHT = "%{Copyright}"
@endif
} else:mac {
	QMAKE_TARGET_BUNDLE_PREFIX = "%{BundlePrefix}."
}
