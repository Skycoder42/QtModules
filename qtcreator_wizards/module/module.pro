load(qt_parts)

@if '%{UseQDoc}' === ''
SUBDIRS += doc

docTarget.target = doxygen
docTarget.CONFIG += recursive
docTarget.recurse_target = doxygen
QMAKE_EXTRA_TARGETS += docTarget
@endif
