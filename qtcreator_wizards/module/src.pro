TEMPLATE = subdirs
CONFIG += ordered

SUBDIRS += %{ModuleBase}

@if '%{UseQDoc}' === ''
docTarget.target = doxygen
docTarget.CONFIG += recursive
docTarget.recurse_target = doxygen
QMAKE_EXTRA_TARGETS += docTarget
@endif
