TEMPLATE = subdirs

SUBDIRS = %{ModuleBase}

@if '%{UseQDoc}' === ''
docTarget.target = doxygen
QMAKE_EXTRA_TARGETS += docTarget
@endif