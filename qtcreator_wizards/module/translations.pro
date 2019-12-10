TEMPLATE = aux

QDEP_LUPDATE_INPUTS += $$PWD/../%{ModuleBase}

TRANSLATIONS += \\
	%{QtModuleNameLower}_template.ts

CONFIG += lrelease
QM_FILES_INSTALL_PATH = $$[QT_INSTALL_TRANSLATIONS]

QDEP_DEPENDS += 

!load(qdep):error("Failed to load qdep feature! Run 'qdep prfgen --qmake $$QMAKE_QMAKE' to create it.")

#replace template qm by ts
QM_FILES -= $$__qdep_lrelease_real_dir/%{QtModuleNameLower}r_template.qm
QM_FILES += %{QtModuleNameLower}_template.ts

HEADERS =
SOURCES =
GENERATED_SOURCES =
OBJECTIVE_SOURCES =
RESOURCES =
