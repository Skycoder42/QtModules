TARGET = %{QtModuleName}

QT = core

@if '%{UseQDoc}' !== ''
QMAKE_DOCS = $$PWD/doc/%{QtModuleNameLower}.qdocconf
OTHER_FILES += doc/src/*.qdoc   # show .qdoc files in Qt Creator
OTHER_FILES += doc/%{QtModuleNameLower}.qdocconf
@else
OTHER_FILES += doc/Doxyfile
OTHER_FILES += doc/makedoc.sh
OTHER_FILES += doc/*.dox
@endif
OTHER_FILES += doc/snippets/*.cpp

PUBLIC_HEADERS += \\
	%{GlobalHeaderName}

PRIVATE_HEADERS +=

SOURCES +=

HEADERS += $$PUBLIC_HEADERS $$PRIVATE_HEADERS

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

@if '%{UseQDoc}' === ''
docTarget.target = doxygen
docTarget.commands = chmod u+x $$PWD/doc/makedoc.sh && $$PWD/doc/makedoc.sh "$$PWD" "$$VERSION" "$$[QT_INSTALL_BINS]" "$$[QT_INSTALL_HEADERS]" "$$[QT_INSTALL_DOCS]"
QMAKE_EXTRA_TARGETS += docTarget
@endif
