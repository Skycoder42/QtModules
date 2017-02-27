load(qt_parts)

@if '%{UseQDoc}' === ''
docTarget.target = doxygen
docTarget.CONFIG += recursive
docTarget.recurse_target = doxygen
QMAKE_EXTRA_TARGETS += docTarget
@endif