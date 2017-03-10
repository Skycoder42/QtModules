TEMPLATE = aux

OTHER_FILES += Doxyfile \\
	makedoc.sh \\
	doxme.py \\
	../README.md \\
	*.dox \\
	snippets/*.cpp \\
	images/*

docTarget.target = doxygen
docTarget.commands = $$PWD/makedoc.sh "$$PWD" "$$MODULE_VERSION" "$$[QT_INSTALL_BINS]" "$$[QT_INSTALL_HEADERS]" "$$[QT_INSTALL_DOCS]"
QMAKE_EXTRA_TARGETS += docTarget

docInst1.path = $$[QT_INSTALL_DOCS]
docInst1.files = $$OUT_PWD/%{QtModuleNameLower}.qch
docInst2.path = $$[QT_INSTALL_DOCS]/%{QtModuleNameLower}
docInst2.files = $$OUT_PWD/%{QtModuleNameLower}/*
INSTALLS += docInst1 docInst2
