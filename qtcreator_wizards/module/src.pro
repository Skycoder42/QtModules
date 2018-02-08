TEMPLATE = subdirs
CONFIG += ordered

SUBDIRS += %{ModuleBase}

@if '%{Translations}' !== ''
prepareRecursiveTarget(lrelease)
QMAKE_EXTRA_TARGETS += lrelease
@endif
