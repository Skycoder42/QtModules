TRANSLATIONS += $$PWD/%{QtModuleNameLower}_template.ts

OTHER_FILES += $$TRANSLATIONS

releaseTarget.target = lrelease
releaseTarget.commands = lrelease -compress -nounfinished "$$_PRO_FILE_"
QMAKE_EXTRA_TARGETS += releaseTarget

trInstall.path = $$[QT_INSTALL_TRANSLATIONS]
trInstall.files = $$PWD/%{QtModuleNameLower}_template.qm \\
	$$PWD/%{QtModuleNameLower}_template.ts
trInstall.CONFIG += no_check_exist
trInstall.depends = releaseTarget
INSTALLS += trInstall
