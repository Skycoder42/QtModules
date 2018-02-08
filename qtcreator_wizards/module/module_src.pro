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
TRANSLATIONS += \\
	translations/%{QtModuleNameLower}_template.ts

DISTFILES += $$TRANSLATIONS

qpmx_ts_target.path = $$[QT_INSTALL_TRANSLATIONS]
qpmx_ts_target.depends += lrelease
INSTALLS += qpmx_ts_target

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

!ReleaseBuild:!DebugBuild:!system(qpmx -d $$shell_quote($$_PRO_FILE_PWD_) --qmake-run init $$QPMX_EXTRA_OPTIONS $$shell_quote($$QMAKE_QMAKE) $$shell_quote($$OUT_PWD)): error(qpmx initialization failed. Check the compilation log for details.)
else: include($$OUT_PWD/qpmx_generated.pri)

@if '%{Translations}' !== ''
qpmx_ts_target.files -= $$OUT_PWD/$$QPMX_WORKINGDIR/%{QtModuleNameLower}_template.qm
qpmx_ts_target.files += translations/%{QtModuleNameLower}_template.ts

@endif
